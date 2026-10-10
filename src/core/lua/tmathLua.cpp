#include <cfloat>
#include <cmath>
#include <cstdio>
#include <cstdlib>
#include <cstring>
#include <initializer_list>
#include <locale.h>
#include <limits>
#include <new>

extern "C" {
#include <lua.h>
#include <lauxlib.h>
#include <lualib.h>
}

#include "tmath.h"
#include "tmathLuaExtension.h"

namespace tmath
{

static constexpr size_t LUA_MEMORY_LIMIT = 64u * 1024u * 1024u;
static constexpr size_t LUA_NATIVE_MEMORY_LIMIT = 64u * 1024u * 1024u;
static constexpr int LUA_INSTRUCTION_LIMIT = 5000000;
static constexpr uint32_t LUA_OBJECT_LIMIT = 4096;
static constexpr uint32_t LUA_CLIP_LIMIT = 65536;
static constexpr uint32_t LUA_GROUP_LIMIT = 1024;
static constexpr uint32_t LUA_POINT_LIMIT = 1000000;
static constexpr uint32_t LUA_PATH_SAMPLE_LIMIT = 1024;
static constexpr uint64_t LUA_SAMPLE_WORK_LIMIT = 4000000;
static constexpr size_t LUA_TEXT_LIMIT = 1024u * 1024u;
static constexpr size_t LUA_PATH_LIMIT = 4096;
static constexpr size_t LUA_ID_LIMIT = 256;
static constexpr uint32_t LUA_PIXEL_LIMIT = 67108864;
static constexpr uint32_t LUA_VIEWPORT_LIMIT = 64;
static constexpr uint32_t LUA_SCENE_LIMIT = LUA_VIEWPORT_LIMIT + 1u;
static constexpr size_t LUA_SCENE_CHARGE = 512u;
static constexpr size_t LUA_VIEWPORT_CHARGE = 64u;
static constexpr size_t LUA_TRANSITION_CHARGE = 64u;
static constexpr size_t LUA_CLIP_CHARGE = 512u;
static constexpr const char* SCENE_METATABLE = "tmath.Scene";
static constexpr const char* OBJECT_METATABLE = "tmath.Object";
static constexpr const char* SPACE_METATABLE = "tmath.Space";
static constexpr const char* GROUP_METATABLE = "tmath.Group";

class NumericLocale
{
public:
    NumericLocale() noexcept
    {
#if defined(__EMSCRIPTEN__)
        ready = true;
#elif defined(_WIN32)
        mode = _configthreadlocale(_ENABLE_PER_THREAD_LOCALE);
        if (mode == -1) return;
        auto current = setlocale(LC_NUMERIC, nullptr);
        if (!current || std::strlen(current) >= sizeof(previous)) {
            _configthreadlocale(mode);
            return;
        }
        std::memcpy(previous, current, std::strlen(current) + 1);
        if (!setlocale(LC_NUMERIC, "C")) {
            _configthreadlocale(mode);
            return;
        }
        ready = true;
#else
        numeric = newlocale(LC_NUMERIC_MASK, "C", nullptr);
        if (!numeric) return;
        previous = uselocale(numeric);
        if (!previous) {
            freelocale(numeric);
            numeric = nullptr;
            return;
        }
        ready = true;
#endif
    }

    ~NumericLocale()
    {
#if defined(_WIN32) && !defined(__EMSCRIPTEN__)
        if (ready) setlocale(LC_NUMERIC, previous);
        if (mode != -1) _configthreadlocale(mode);
#elif !defined(__EMSCRIPTEN__)
        if (ready) uselocale(previous);
        if (numeric) freelocale(numeric);
#endif
    }

    bool available() const noexcept
    {
        return ready;
    }

private:
    bool ready = false;
#if defined(_WIN32) && !defined(__EMSCRIPTEN__)
    int mode = -1;
    char previous[128] = {};
#elif !defined(__EMSCRIPTEN__)
    locale_t numeric = nullptr;
    locale_t previous = nullptr;
#endif
};

struct LuaMemory
{
    size_t used = 0;
    size_t nativeUsed = 0;
    uint32_t scenes = 0;
    uint32_t objects = 0;
    uint32_t clips = 0;
    uint32_t points = 0;
    Lua::AssetResolver resolver = nullptr;
    void* resolverData = nullptr;
    const char* sourcePath = nullptr;
    size_t sourceRoot = 0;
    Theme adaptiveTheme;
    bool hasAdaptiveTheme = false;
    bool adaptiveThemeUsed = false;
    bool authoring = true;
};

struct LuaScene
{
    Scene* scene = nullptr;
    size_t nativeUsed = 0;
    uint32_t objects = 0;
    uint32_t clips = 0;
    uint32_t points = 0;
    uint32_t scenes = 1;
    LuaMemory* memory = nullptr;
    Lua::AssetResolver resolver = nullptr;
    void* resolverData = nullptr;
    bool owner = true;
    bool sampleActive = false;
};

struct LuaObject
{
    LuaScene* scene = nullptr;
    Object* object = nullptr;
    bool owner = false;
};

static void* _allocate(void* data, void* ptr, size_t oldSize, size_t size)
{
    auto memory = static_cast<LuaMemory*>(data);
    if (!size) {
        if (ptr) memory->used -= oldSize;
        std::free(ptr);
        return nullptr;
    }

    auto previous = ptr ? oldSize : 0;
    if (size > previous && size - previous > LUA_MEMORY_LIMIT - memory->used) return nullptr;
    auto resized = std::realloc(ptr, size);
    if (!resized) return nullptr;
    if (size > previous) memory->used += size - previous;
    else memory->used -= previous - size;
    return resized;
}

static void _close(lua_State* lua, bool memoryOwned) noexcept
{
    if (!lua) return;
    void* data = nullptr;
    lua_getallocf(lua, &data);
    lua_close(lua);
    if (memoryOwned) delete static_cast<LuaMemory*>(data);
}

static void _releaseSceneBudget(LuaScene* scene)
{
    if (!scene || !scene->memory) return;
    auto memory = scene->memory;
    memory->nativeUsed -= scene->nativeUsed;
    memory->scenes -= scene->scenes;
    memory->objects -= scene->objects;
    memory->clips -= scene->clips;
    memory->points -= scene->points;
    scene->memory = nullptr;
}

static void _limit(lua_State* lua, lua_Debug* debug)
{
    if (lua_getinfo(lua, "Sl", debug)) {
        luaL_error(lua, "%s:%d: instruction limit exceeded", debug->short_src, debug->currentline);
    }
    luaL_error(lua, "instruction limit exceeded");
}

static void _message(char* error, uint32_t size, const char* message)
{
    if (!error || !size) return;
    if (!message) message = "unknown Lua error";
    auto length = std::strlen(message);
    if (length >= size) length = size - 1;
    std::memcpy(error, message, length);
    error[length] = '\0';
}

static float _number(lua_State* lua, int index, const char* name)
{
    auto value = luaL_checknumber(lua, index);
    if (!std::isfinite(value) || value < -FLT_MAX || value > FLT_MAX) {
        luaL_error(lua, "%s must be a finite number", name);
    }
    return static_cast<float>(value);
}

static float _fieldNumber(lua_State* lua, int index, const char* name, float fallback)
{
    index = lua_absindex(lua, index);
    lua_getfield(lua, index, name);
    if (lua_isnil(lua, -1)) {
        lua_pop(lua, 1);
        return fallback;
    }
    auto value = _number(lua, -1, name);
    lua_pop(lua, 1);
    return value;
}

static bool _fieldBool(lua_State* lua, int index, const char* name, bool fallback)
{
    index = lua_absindex(lua, index);
    lua_getfield(lua, index, name);
    if (lua_isnil(lua, -1)) {
        lua_pop(lua, 1);
        return fallback;
    }
    if (!lua_isboolean(lua, -1)) luaL_error(lua, "%s must be a boolean", name);
    auto value = static_cast<bool>(lua_toboolean(lua, -1));
    lua_pop(lua, 1);
    return value;
}

static lua_Integer _integer(lua_State* lua, int index, const char* name)
{
    if (!lua_isinteger(lua, index)) luaL_error(lua, "%s must be an integer", name);
    return lua_tointeger(lua, index);
}

static lua_Integer _fieldInteger(lua_State* lua, int index, const char* name, lua_Integer fallback)
{
    index = lua_absindex(lua, index);
    lua_getfield(lua, index, name);
    if (lua_isnil(lua, -1)) {
        lua_pop(lua, 1);
        return fallback;
    }
    auto value = _integer(lua, -1, name);
    lua_pop(lua, 1);
    return value;
}

static bool _has(lua_State* lua, int index, const char* name)
{
    index = lua_absindex(lua, index);
    lua_getfield(lua, index, name);
    auto found = !lua_isnil(lua, -1);
    lua_pop(lua, 1);
    return found;
}

static float _component(lua_State* lua, int index, const char* key, int item)
{
    index = lua_absindex(lua, index);
    if (key) lua_getfield(lua, index, key);
    else lua_rawgeti(lua, index, item);
    auto value = _number(lua, -1, key ? key : "vector component");
    lua_pop(lua, 1);
    return value;
}

static Vec2 _vec2(lua_State* lua, int index, const char* name)
{
    luaL_checktype(lua, index, LUA_TTABLE);
    index = lua_absindex(lua, index);
    auto keyed = _has(lua, index, "x") || _has(lua, index, "y") || _has(lua, index, "z");
    if (keyed) {
        if (!_has(lua, index, "x") || !_has(lua, index, "y") || _has(lua, index, "z")) {
            luaL_error(lua, "%s must be a 2D vector with x and y", name);
        }
        return {_component(lua, index, "x", 0), _component(lua, index, "y", 0)};
    }
    if (lua_rawlen(lua, index) != 2) luaL_error(lua, "%s must contain exactly 2 numbers", name);
    return {_component(lua, index, nullptr, 1), _component(lua, index, nullptr, 2)};
}

static Vec3 _world(lua_State* lua, int index, const char* name)
{
    luaL_checktype(lua, index, LUA_TTABLE);
    index = lua_absindex(lua, index);
    auto keyed = _has(lua, index, "x") || _has(lua, index, "y") || _has(lua, index, "z");
    if (keyed) {
        if (!_has(lua, index, "x") || !_has(lua, index, "y")) {
            luaL_error(lua, "%s must contain x and y, with optional z", name);
        }
        auto z = _has(lua, index, "z") ? _component(lua, index, "z", 0) : 0.0f;
        return {_component(lua, index, "x", 0), _component(lua, index, "y", 0), z};
    }
    auto size = lua_rawlen(lua, index);
    if (size != 2 && size != 3) luaL_error(lua, "%s must contain 2 or 3 numbers", name);
    return {_component(lua, index, nullptr, 1), _component(lua, index, nullptr, 2),
            size == 3 ? _component(lua, index, nullptr, 3) : 0.0f};
}

static Vec2 _fieldVec2(lua_State* lua, int index, const char* name, const Vec2& fallback)
{
    index = lua_absindex(lua, index);
    lua_getfield(lua, index, name);
    if (lua_isnil(lua, -1)) {
        lua_pop(lua, 1);
        return fallback;
    }
    auto value = _vec2(lua, -1, name);
    lua_pop(lua, 1);
    return value;
}

static Vec3 _fieldWorld(lua_State* lua, int index, const char* name)
{
    index = lua_absindex(lua, index);
    lua_getfield(lua, index, name);
    if (lua_isnil(lua, -1)) luaL_error(lua, "missing field '%s'", name);
    auto value = _world(lua, -1, name);
    lua_pop(lua, 1);
    return value;
}

static Vec3 _fieldWorld(lua_State* lua, int index, const char* name, const Vec3& fallback)
{
    index = lua_absindex(lua, index);
    lua_getfield(lua, index, name);
    if (lua_isnil(lua, -1)) {
        lua_pop(lua, 1);
        return fallback;
    }
    auto value = _world(lua, -1, name);
    lua_pop(lua, 1);
    return value;
}

static Range _range(lua_State* lua, int index, const char* name)
{
    luaL_checktype(lua, index, LUA_TTABLE);
    index = lua_absindex(lua, index);
    Range range;
    auto keyed = _has(lua, index, "min") || _has(lua, index, "max") || _has(lua, index, "step");
    if (keyed) {
        if (!_has(lua, index, "min") || !_has(lua, index, "max") || !_has(lua, index, "step")) {
            luaL_error(lua, "%s must have min, max and step", name);
        }
        range.min = _component(lua, index, "min", 0);
        range.max = _component(lua, index, "max", 0);
        range.step = _component(lua, index, "step", 0);
    } else {
        if (lua_rawlen(lua, index) != 3) luaL_error(lua, "%s must contain min, max and step", name);
        range.min = _component(lua, index, nullptr, 1);
        range.max = _component(lua, index, nullptr, 2);
        range.step = _component(lua, index, nullptr, 3);
    }
    if (range.min > range.max || range.step <= 0.0f) luaL_error(lua, "%s is invalid", name);
    return range;
}

static Range _fieldRange(lua_State* lua, int index, const char* name, const Range& fallback)
{
    index = lua_absindex(lua, index);
    lua_getfield(lua, index, name);
    if (lua_isnil(lua, -1)) {
        lua_pop(lua, 1);
        return fallback;
    }
    auto value = _range(lua, -1, name);
    lua_pop(lua, 1);
    return value;
}

static CellRegion _region(lua_State* lua, int index, const char* name)
{
    luaL_checktype(lua, index, LUA_TTABLE);
    index = lua_absindex(lua, index);
    auto keyed = _has(lua, index, "x") || _has(lua, index, "y") || _has(lua, index, "width") || _has(lua, index, "height");
    lua_Integer values[4];
    if (keyed) {
        const char* fields[] = {"x", "y", "width", "height"};
        for (auto i = 0u; i < 4u; i++) {
            if (!_has(lua, index, fields[i])) luaL_error(lua, "%s requires x, y, width and height", name);
            values[i] = _fieldInteger(lua, index, fields[i], 0);
        }
    } else {
        if (lua_rawlen(lua, index) != 4u) luaL_error(lua, "%s must contain x, y, width and height", name);
        for (auto i = 0u; i < 4u; i++) {
            lua_rawgeti(lua, index, i + 1u);
            values[i] = _integer(lua, -1, name);
            lua_pop(lua, 1);
        }
    }
    for (auto value : values) {
        if (value < 0 || value > UINT32_MAX) luaL_error(lua, "%s values must be unsigned 32-bit integers", name);
    }
    return {static_cast<uint32_t>(values[0]), static_cast<uint32_t>(values[1]),
            static_cast<uint32_t>(values[2]), static_cast<uint32_t>(values[3])};
}

static CellRegion _fieldRegion(lua_State* lua, int index, const char* name)
{
    index = lua_absindex(lua, index);
    lua_getfield(lua, index, name);
    if (lua_isnil(lua, -1)) {
        lua_pop(lua, 1);
        return {};
    }
    auto value = _region(lua, -1, name);
    lua_pop(lua, 1);
    return value;
}

static void _size(lua_State* lua, int index, uint32_t& columns, uint32_t& rows)
{
    luaL_checktype(lua, index, LUA_TTABLE);
    if (lua_rawlen(lua, index) != 2u) luaL_error(lua, "size must contain columns and rows");
    lua_rawgeti(lua, index, 1);
    auto width = _integer(lua, -1, "columns");
    lua_pop(lua, 1);
    lua_rawgeti(lua, index, 2);
    auto height = _integer(lua, -1, "rows");
    lua_pop(lua, 1);
    if (width <= 0 || width > UINT32_MAX || height <= 0 || height > UINT32_MAX || height > 16384 / width) {
        luaL_error(lua, "size must contain 1 to 16384 cells");
    }
    columns = static_cast<uint32_t>(width);
    rows = static_cast<uint32_t>(height);
}

static void _matrix(lua_State* lua, int index, float* values, uint32_t count, const char* name)
{
    luaL_checktype(lua, index, LUA_TTABLE);
    index = lua_absindex(lua, index);
    if (lua_rawlen(lua, index) != count) luaL_error(lua, "%s must contain exactly %u numbers", name, count);
    for (auto i = 0u; i < count; i++) {
        lua_rawgeti(lua, index, i + 1);
        values[i] = _number(lua, -1, name);
        lua_pop(lua, 1);
    }
}

static const char* _fieldString(lua_State* lua, int index, const char* name, size_t* size = nullptr)
{
    index = lua_absindex(lua, index);
    lua_getfield(lua, index, name);
    if (lua_isnil(lua, -1)) luaL_error(lua, "missing field '%s'", name);
    size_t length;
    auto value = luaL_checklstring(lua, -1, &length);
    if (std::strlen(value) != length) luaL_error(lua, "field '%s' cannot contain zero bytes", name);
    if (size) *size = length;
    return value;
}

static const char* _fieldOptionalString(lua_State* lua, int index, const char* name, const char* fallback)
{
    index = lua_absindex(lua, index);
    lua_getfield(lua, index, name);
    if (lua_isnil(lua, -1)) {
        lua_pop(lua, 1);
        lua_pushstring(lua, fallback);
        return lua_tostring(lua, -1);
    }
    size_t length;
    auto value = luaL_checklstring(lua, -1, &length);
    if (std::strlen(value) != length) luaL_error(lua, "field '%s' cannot contain zero bytes", name);
    return value;
}

static bool _option(const char* name, std::initializer_list<const char*> fields, bool style)
{
    if (style) {
        static constexpr const char* shared[] = {
            "id", "color", "stroke", "fill", "gradient", "width", "radius", "dash",
            "dash_offset", "opacity", "progress", "layer"};
        for (auto field : shared) {
            if (std::strcmp(name, field) == 0) return true;
        }
    }
    for (auto field : fields) {
        if (std::strcmp(name, field) == 0) return true;
    }
    return false;
}

static void _options(lua_State* lua, int index, std::initializer_list<const char*> fields,
                     bool style = true)
{
    index = lua_absindex(lua, index);
    lua_pushnil(lua);
    while (lua_next(lua, index)) {
        if (lua_type(lua, -2) != LUA_TSTRING) luaL_error(lua, "option names must be strings");
        auto name = lua_tostring(lua, -2);
        if (!_option(name, fields, style)) luaL_error(lua, "unknown option '%s'", name);
        lua_pop(lua, 1);
    }
}

static bool _hex(const char* value, size_t size)
{
    if (size && *value == '#') {
        value++;
        size--;
    }
    if (size != 3 && size != 4 && size != 6 && size != 8) return false;
    for (auto i = 0u; i < size; i++) {
        auto c = value[i];
        if (!((c >= '0' && c <= '9') || (c >= 'a' && c <= 'f') || (c >= 'A' && c <= 'F'))) return false;
    }
    return true;
}

static bool _themeColorRole(const char* value, size_t size, ThemeColorRole& role)
{
    struct Entry { const char* name; ThemeColorRole role; };
    static constexpr Entry entries[] = {
        {"background", ThemeColorRole::Background},
        {"foreground", ThemeColorRole::Foreground},
        {"muted", ThemeColorRole::Muted},
        {"accent", ThemeColorRole::Accent},
        {"secondary", ThemeColorRole::Secondary},
        {"success", ThemeColorRole::Success},
        {"warning", ThemeColorRole::Warning},
        {"danger", ThemeColorRole::Danger},
        {"info", ThemeColorRole::Info},
        {"surface", ThemeColorRole::Surface},
        {"border", ThemeColorRole::Border},
        {"result", ThemeColorRole::Result},
        {"focus", ThemeColorRole::Focus},
    };
    for (const auto& entry : entries) {
        if (std::strlen(entry.name) == size && std::memcmp(value, entry.name, size) == 0) {
            role = entry.role;
            return true;
        }
    }
    return false;
}

static Color _color(lua_State* lua, int index, const char* name, const Theme* theme = nullptr)
{
    size_t size;
    auto value = luaL_checklstring(lua, index, &size);
    if (_hex(value, size)) return Color::hex(value);
    ThemeColorRole role;
    if (theme && std::strlen(value) == size && _themeColorRole(value, size, role)) {
        return theme->color(role);
    }
    luaL_error(lua, "%s must be a hex color or Theme color role", name);
    return {};
}

static bool _fieldColor(lua_State* lua, int index, const char* name, Color& color,
                        const Theme* theme = nullptr)
{
    index = lua_absindex(lua, index);
    lua_getfield(lua, index, name);
    if (lua_isnil(lua, -1)) {
        lua_pop(lua, 1);
        return false;
    }
    color = _color(lua, -1, name, theme);
    lua_pop(lua, 1);
    return true;
}

static Vec3* _points(lua_State* lua, int index, uint32_t minimum, uint32_t& count)
{
    luaL_checktype(lua, index, LUA_TTABLE);
    index = lua_absindex(lua, index);
    auto size = lua_rawlen(lua, index);
    if (size < minimum) luaL_error(lua, "points must contain at least %u vectors", minimum);
    if (size > UINT32_MAX || size > LUA_MEMORY_LIMIT / sizeof(Vec3)) luaL_error(lua, "points array is too large");
    count = static_cast<uint32_t>(size);
    auto points = static_cast<Vec3*>(lua_newuserdatauv(lua, sizeof(Vec3) * size, 0));
    for (auto i = 0u; i < count; i++) {
        lua_rawgeti(lua, index, i + 1);
        auto point = _world(lua, -1, "point");
        new (points + i) Vec3(point);
        lua_pop(lua, 1);
    }
    return points;
}

static LuaScene* _scene(lua_State* lua)
{
    auto box = static_cast<LuaScene*>(luaL_checkudata(lua, 1, SCENE_METATABLE));
    if (!box->scene) luaL_error(lua, "scene is no longer available");
    if (!detail::luaAuthoring(lua)) {
        luaL_error(lua, "scene authoring is unavailable after loading");
    }
    if (!box->owner) luaL_error(lua, "scene already belongs to a viewport");
    if (box->sampleActive) luaL_error(lua, "scene authoring is unavailable inside a sampling callback");
    return box;
}

struct LuaSpace
{
    LuaScene* scene = nullptr;
    Object* parent = nullptr;
};

static LuaObject* _handle(lua_State* lua, int index)
{
    auto handle = static_cast<LuaObject*>(luaL_testudata(lua, index, OBJECT_METATABLE));
    if (!handle) handle = static_cast<LuaObject*>(luaL_testudata(lua, index, SPACE_METATABLE));
    if (!handle) handle = static_cast<LuaObject*>(luaL_testudata(lua, index, GROUP_METATABLE));
    if (!handle || !handle->scene || !handle->scene->scene || !handle->object) {
        luaL_error(lua, "object handle is no longer available");
    }
    return handle;
}

static LuaScene* _sceneHandle(lua_State* lua, int index)
{
    auto scene = static_cast<LuaScene*>(luaL_checkudata(lua, index, SCENE_METATABLE));
    if (!scene->scene) luaL_error(lua, "scene is no longer available");
    if (!detail::luaAuthoring(lua)) {
        luaL_error(lua, "scene authoring is unavailable after loading");
    }
    if (!scene->owner) luaL_error(lua, "scene already belongs to a viewport");
    if (scene->sampleActive) {
        luaL_error(lua, "scene authoring is unavailable inside a sampling callback");
    }
    return scene;
}

static LuaSpace _space(lua_State* lua)
{
    auto scene = static_cast<LuaScene*>(luaL_testudata(lua, 1, SCENE_METATABLE));
    if (scene) {
        if (!scene->scene) luaL_error(lua, "scene is no longer available");
        if (!detail::luaAuthoring(lua)) {
            luaL_error(lua, "scene authoring is unavailable after loading");
        }
        if (!scene->owner) luaL_error(lua, "scene already belongs to a viewport");
        if (scene->sampleActive) luaL_error(lua, "scene authoring is unavailable inside a sampling callback");
        return {scene, nullptr};
    }
    auto handle = _handle(lua, 1);
    if (!detail::luaAuthoring(lua)) {
        luaL_error(lua, "object authoring is unavailable after loading");
    }
    if (!handle->scene->owner) luaL_error(lua, "scene already belongs to a viewport");
    if (handle->scene->sampleActive) {
        luaL_error(lua, "scene authoring is unavailable inside a sampling callback");
    }
    return {handle->scene, handle->object};
}

static LuaObject* _objectHandle(lua_State* lua, LuaScene* scene, int sceneIndex,
                               Object* object, bool owner)
{
    sceneIndex = lua_absindex(lua, sceneIndex);
    auto handle = new (lua_newuserdatauv(lua, sizeof(LuaObject), 1)) LuaObject;
    handle->scene = scene;
    handle->object = object;
    handle->owner = owner;
    auto metatable = OBJECT_METATABLE;
    if (object && object->type() == Type::Space) metatable = SPACE_METATABLE;
    else if (object && object->type() == Type::Group) metatable = GROUP_METATABLE;
    luaL_getmetatable(lua, metatable);
    lua_setmetatable(lua, -2);
    lua_pushvalue(lua, sceneIndex);
    lua_setiuservalue(lua, -2, 1);
    return handle;
}

static LuaObject* _owner(lua_State* lua, LuaScene* scene)
{
    return _objectHandle(lua, scene, 1, nullptr, true);
}

static bool _gradientShape(Type type)
{
    return type != Type::Space && type != Type::Text && type != Type::Picture
           && type != Type::Cell && type != Type::Group;
}

static GradientType _gradientType(lua_State* lua, int index)
{
    lua_getfield(lua, index, "type");
    if (lua_type(lua, -1) != LUA_TSTRING) {
        luaL_error(lua, "gradient.type must be \"linear\", \"radial\" or \"conic\"");
    }
    auto name = lua_tostring(lua, -1);
    auto type = GradientType::None;
    if (std::strcmp(name, "linear") == 0) type = GradientType::Linear;
    else if (std::strcmp(name, "radial") == 0) type = GradientType::Radial;
    else if (std::strcmp(name, "conic") == 0) type = GradientType::Conic;
    else luaL_error(lua, "gradient.type must be \"linear\", \"radial\" or \"conic\", got '%s'", name);
    lua_pop(lua, 1);
    return type;
}

static void _gradientStops(lua_State* lua, int index, Gradient& gradient, const Theme* theme)
{
    lua_getfield(lua, index, "stops");
    if (lua_isnil(lua, -1)) {
        lua_pop(lua, 1);
        return;
    }
    if (!lua_istable(lua, -1)) luaL_error(lua, "gradient.stops must be an array of colors or {offset, color} pairs");
    auto stops = lua_absindex(lua, -1);
    auto count = lua_rawlen(lua, stops);
    lua_pushnil(lua);
    while (lua_next(lua, stops)) {
        if (!lua_isinteger(lua, -2) || lua_tointeger(lua, -2) < 1
            || static_cast<size_t>(lua_tointeger(lua, -2)) > count) {
            luaL_error(lua, "gradient.stops must be a sequence");
        }
        lua_pop(lua, 1);
    }
    if (count < 2 || count > Gradient::StopLimit) {
        luaL_error(lua, "gradient.stops must contain 2 to %d stops", static_cast<int>(Gradient::StopLimit));
    }
    auto previous = 0.0f;
    for (auto i = 1u; i <= count; i++) {
        auto& stop = gradient.stops[i - 1u];
        lua_rawgeti(lua, stops, static_cast<lua_Integer>(i));
        if (lua_type(lua, -1) == LUA_TSTRING) {
            stop.offset = static_cast<float>(i - 1u) / static_cast<float>(count - 1u);
            stop.color = _color(lua, -1, "gradient stop color", theme);
        } else if (lua_istable(lua, -1)) {
            auto pair = lua_absindex(lua, -1);
            if (lua_rawlen(lua, pair) != 2) {
                luaL_error(lua, "gradient stop %d must be a color or {offset, color}", static_cast<int>(i));
            }
            lua_rawgeti(lua, pair, 1);
            stop.offset = _number(lua, -1, "gradient stop offset");
            lua_pop(lua, 1);
            lua_rawgeti(lua, pair, 2);
            stop.color = _color(lua, -1, "gradient stop color", theme);
            lua_pop(lua, 1);
            if (stop.offset < 0.0f || stop.offset > 1.0f) {
                luaL_error(lua, "gradient stop %d offset must be within 0..1", static_cast<int>(i));
            }
            if (stop.offset < previous) {
                luaL_error(lua, "gradient stop offsets must be non-decreasing");
            }
        } else {
            luaL_error(lua, "gradient stop %d must be a color or {offset, color}", static_cast<int>(i));
        }
        previous = stop.offset;
        lua_pop(lua, 1);
    }
    gradient.stopCount = static_cast<uint8_t>(count);
    lua_pop(lua, 1);
}

static Gradient _gradient(lua_State* lua, int index, const Theme* theme)
{
    index = lua_absindex(lua, index);
    Gradient gradient;
    gradient.type = _gradientType(lua, index);
    const char* allowed[6] = {"type", "stops", nullptr, nullptr, nullptr, nullptr};
    switch (gradient.type) {
        case GradientType::Linear: allowed[2] = "from"; allowed[3] = "to"; break;
        case GradientType::Radial:
            allowed[2] = "center"; allowed[3] = "radius";
            allowed[4] = "focal"; allowed[5] = "focal_radius";
            break;
        default: allowed[2] = "center"; allowed[3] = "angle"; break;
    }
    lua_pushnil(lua);
    while (lua_next(lua, index)) {
        if (lua_type(lua, -2) != LUA_TSTRING) luaL_error(lua, "gradient option names must be strings");
        auto name = lua_tostring(lua, -2);
        auto known = false;
        for (auto field : allowed) {
            if (field && std::strcmp(name, field) == 0) known = true;
        }
        if (!known) {
            static constexpr const char* geometry[] = {"from", "to", "center", "radius",
                                                       "focal", "focal_radius", "angle"};
            for (auto field : geometry) {
                if (std::strcmp(name, field) == 0) {
                    luaL_error(lua, "gradient option '%s' is not valid for a %s gradient", name,
                               gradient.type == GradientType::Linear ? "linear"
                               : gradient.type == GradientType::Radial ? "radial" : "conic");
                }
            }
            luaL_error(lua, "unknown gradient option '%s'", name);
        }
        lua_pop(lua, 1);
    }
    _gradientStops(lua, index, gradient, theme);
    if (gradient.type == GradientType::Linear) {
        auto from = _has(lua, index, "from");
        if (from != _has(lua, index, "to")) luaL_error(lua, "linear gradient needs both from and to");
        if (from) {
            gradient.from = _fieldWorld(lua, index, "from");
            gradient.to = _fieldWorld(lua, index, "to");
            gradient.line = true;
        }
    } else {
        if (_has(lua, index, "center")) {
            gradient.center = _fieldWorld(lua, index, "center");
            gradient.centered = true;
        }
    }
    if (gradient.type == GradientType::Radial) {
        if (_has(lua, index, "radius")) {
            gradient.radius = _fieldNumber(lua, index, "radius", 0.0f);
            if (gradient.radius <= 0.0f) luaL_error(lua, "gradient.radius must be positive");
            gradient.sized = true;
        }
        if (_has(lua, index, "focal")) {
            gradient.focal = _fieldWorld(lua, index, "focal");
            gradient.focused = true;
        }
        gradient.focalRadius = _fieldNumber(lua, index, "focal_radius", 0.0f);
        if (gradient.focalRadius < 0.0f) luaL_error(lua, "gradient.focal_radius cannot be negative");
    }
    if (gradient.type == GradientType::Conic) {
        gradient.angle = _fieldNumber(lua, index, "angle", 0.0f);
    }
    return gradient;
}

static void _style(lua_State* lua, Scene* scene, Object* object, int index)
{
    index = lua_absindex(lua, index);
    lua_getfield(lua, index, "id");
    if (!lua_isnil(lua, -1)) {
        size_t size;
        auto id = luaL_checklstring(lua, -1, &size);
        if (!size || size > LUA_ID_LIMIT || std::strlen(id) != size) {
            luaL_error(lua, "id must be 1 to %zu bytes without zero bytes", LUA_ID_LIMIT);
        }
        for (auto i = 0u; i < size; i++) {
            auto c = id[i];
            auto allowed = (c >= 'a' && c <= 'z') || (c >= 'A' && c <= 'Z') || (c >= '0' && c <= '9') || c == '_' || c == '-' || c == '.' || c == '/' || c == ':';
            if (!allowed) luaL_error(lua, "id may contain only ASCII letters, digits, _, -, ., / and :");
        }
        if (scene->object(id)) luaL_error(lua, "duplicate id '%s'", id);
        object->tag(id);
        if (!object->tag()) luaL_error(lua, "out of memory while copying id");
    }
    lua_pop(lua, 1);

    Color color;
    auto& theme = scene->theme();
    if (_fieldColor(lua, index, "color", color, &theme)) {
        if (object->style.stroke.a) object->stroke(color);
        if (object->style.fill.a) object->fill(color);
    }
    if (_fieldColor(lua, index, "stroke", color, &theme)) object->stroke(color);
    if (_fieldColor(lua, index, "fill", color, &theme)) object->fill(color);

    lua_getfield(lua, index, "gradient");
    if (!lua_isnil(lua, -1)) {
        if (!_gradientShape(object->type())) {
            luaL_error(lua, "gradient is supported only by vector Shapes");
        }
        if (lua_isboolean(lua, -1)) {
            object->gradient(lua_toboolean(lua, -1));
        } else if (lua_type(lua, -1) == LUA_TSTRING) {
            object->gradient(_color(lua, -1, "gradient", &theme));
        } else if (lua_istable(lua, -1)) {
            auto gradient = _gradient(lua, -1, &theme);
            if (object->gradient(gradient) != Result::Success) {
                luaL_error(lua, "gradient is invalid");
            }
        } else {
            luaL_error(lua, "gradient must be a boolean, end-stop color or gradient table");
        }
    }
    lua_pop(lua, 1);

    if (_has(lua, index, "width")) {
        auto width = _fieldNumber(lua, index, "width", object->style.width);
        if (width < 0.0f) luaL_error(lua, "width cannot be negative");
        object->strokeWidth(width);
    }
    object->style.radius = _fieldNumber(lua, index, "radius", object->style.radius);
    auto dashOffset = _fieldNumber(lua, index, "dash_offset", 0.0f);
    lua_getfield(lua, index, "dash");
    if (lua_isnil(lua, -1)) {
        lua_pop(lua, 1);
        if (_has(lua, index, "dash_offset")) luaL_error(lua, "dash_offset requires dash");
    } else {
        luaL_checktype(lua, -1, LUA_TTABLE);
        auto count = lua_rawlen(lua, -1);
        if (!count || count > Style::DashLimit) {
            luaL_error(lua, "dash must contain 1 to %u values", Style::DashLimit);
        }
        float pattern[Style::DashLimit];
        for (size_t i = 0; i < count; i++) {
            lua_rawgeti(lua, -1, i + 1u);
            pattern[i] = _number(lua, -1, "dash value");
            lua_pop(lua, 1);
        }
        lua_pop(lua, 1);
        if (object->dash(pattern, static_cast<uint32_t>(count), dashOffset)
            != Result::Success) {
            luaL_error(lua, "dash values must be non-negative with at least one positive value");
        }
    }
    object->opacity = _fieldNumber(lua, index, "opacity", object->opacity);
    object->progress = _fieldNumber(lua, index, "progress", object->progress);
    auto layer = _fieldInteger(lua, index, "layer", object->layer);
    if (object->style.radius <= 0.0f) luaL_error(lua, "radius must be positive");
    if (object->opacity < 0.0f || object->opacity > 1.0f) luaL_error(lua, "opacity must be between 0 and 1");
    if (object->progress < 0.0f || object->progress > 1.0f) luaL_error(lua, "progress must be between 0 and 1");
    if (layer < INT32_MIN || layer > INT32_MAX) luaL_error(lua, "layer is out of range");
    object->layer = static_cast<int32_t>(layer);
}

static size_t _nativeSize(const Object* object, uint32_t& points)
{
    auto size = size_t{512};
    points = 0;
    if (object->tag()) size += std::strlen(object->tag()) + 1;
    switch (object->type()) {
        case Type::Text: {
            auto text = static_cast<const Text*>(object);
            size += std::strlen(text->text()) + 1;
            if (text->font()) size += std::strlen(text->font()) + 1;
            break;
        }
        case Type::Polygon: points = static_cast<const Polygon*>(object)->count(); break;
        case Type::Plot: points = static_cast<const Plot*>(object)->count(); break;
        case Type::Route: points = static_cast<const DirectedRoute*>(object)->count(); break;
        case Type::Path: points = static_cast<const Path*>(object)->count(); break;
        case Type::Curve: points = static_cast<const Curve*>(object)->count(); break;
        case Type::SurfaceMesh: {
            auto surface = static_cast<const SurfaceMesh*>(object);
            points = surface->columns() * surface->rows();
            break;
        }
        case Type::Picture: {
            auto picture = static_cast<const Picture*>(object);
            if (picture->encoded()) size += picture->encodedSize() + std::strlen(picture->mime()) + 1u;
            else size += static_cast<size_t>(picture->pixelWidth()) * picture->pixelHeight() * sizeof(uint32_t);
            break;
        }
        case Type::Cell: {
            auto cell = static_cast<const Cell*>(object);
            size += static_cast<size_t>(cell->columns()) * cell->rows() * sizeof(Color);
            break;
        }
        default: break;
    }
    if (points > (SIZE_MAX - size) / sizeof(Vec3)) return SIZE_MAX;
    return size + static_cast<size_t>(points) * sizeof(Vec3);
}

struct LuaTreeCharge
{
    size_t native = 0;
    uint32_t objects = 0;
    uint32_t points = 0;
};

static bool _treeCharge(const Object* object, LuaTreeCharge& charge,
                        uint32_t depth = 0u) noexcept
{
    if (!object || depth > 256u || charge.objects == UINT32_MAX) return false;
    uint32_t points = 0;
    auto native = _nativeSize(object, points);
    if (native == SIZE_MAX || native > SIZE_MAX - charge.native
        || points > UINT32_MAX - charge.points) {
        return false;
    }
    charge.native += native;
    charge.objects++;
    charge.points += points;
    for (auto i = 0u; i < object->childCount(); i++) {
        if (!_treeCharge(object->childAt(i), charge, depth + 1u)) return false;
    }
    return true;
}

int detail::luaAdoptObject(lua_State* lua, int sceneIndex, Object* root,
                           const char* kind, LuaObjectTransfer transfer,
                           void* transferData, size_t extraNativeBytes)
{
    sceneIndex = lua_absindex(lua, sceneIndex);
    auto scene = _sceneHandle(lua, sceneIndex);
    if (!root) return luaL_error(lua, "could not create %s", kind ? kind : "object tree");
    auto owner = _objectHandle(lua, scene, sceneIndex, root, true);
    if (transfer) transfer(transferData);

    LuaTreeCharge charge;
    if (!_treeCharge(root, charge) || extraNativeBytes > SIZE_MAX - charge.native) {
        return luaL_error(lua, "%s is too deep or large", kind ? kind : "object tree");
    }
    charge.native += extraNativeBytes;
    auto memory = scene->memory;
    if (charge.objects > LUA_OBJECT_LIMIT - scene->objects
        || charge.objects > LUA_OBJECT_LIMIT - memory->objects) {
        return luaL_error(lua, "scene object limit exceeded");
    }
    if (static_cast<uint64_t>(scene->objects + charge.objects) * scene->clips
        > LUA_SAMPLE_WORK_LIMIT) {
        return luaL_error(lua, "scene evaluation limit exceeded");
    }
    if (charge.points > LUA_POINT_LIMIT - scene->points
        || charge.points > LUA_POINT_LIMIT - memory->points) {
        return luaL_error(lua, "scene point limit exceeded");
    }
    if (charge.native > LUA_NATIVE_MEMORY_LIMIT - scene->nativeUsed
        || charge.native > LUA_NATIVE_MEMORY_LIMIT - memory->nativeUsed) {
        return luaL_error(lua, "scene native memory limit exceeded");
    }

    auto result = scene->scene->add(root);
    if (result != Result::Success) {
        return luaL_error(lua, "could not add %s: %s", kind ? kind : "object tree",
                          tmath::result(result));
    }
    scene->nativeUsed += charge.native;
    scene->objects += charge.objects;
    scene->points += charge.points;
    memory->nativeUsed += charge.native;
    memory->objects += charge.objects;
    memory->points += charge.points;
    owner->owner = false;
    return 1;
}

int detail::luaPushObject(lua_State* lua, int sceneIndex, Object* object)
{
    sceneIndex = lua_absindex(lua, sceneIndex);
    auto scene = _sceneHandle(lua, sceneIndex);
    if (!object || object->id() == 0u || scene->scene->object(object->id()) != object) {
        return luaL_error(lua, "object is not attached to this scene");
    }
    _objectHandle(lua, scene, sceneIndex, object, false);
    return 1;
}

static int _add(lua_State* lua, const LuaSpace& space, LuaObject* owner, Object* object,
                int index, const char* name, bool semanticLabel = false)
{
    owner->object = object;
    if (!object) return luaL_error(lua, "could not create %s: invalid options or out of memory", name);
    _style(lua, space.scene->scene, object, index);
    auto memory = space.scene->memory;
    if (space.scene->objects >= LUA_OBJECT_LIMIT || memory->objects >= LUA_OBJECT_LIMIT) {
        return luaL_error(lua, "scene object limit exceeded");
    }
    if (static_cast<uint64_t>(space.scene->objects + 1u) * space.scene->clips > LUA_SAMPLE_WORK_LIMIT) {
        return luaL_error(lua, "scene evaluation limit exceeded");
    }
    uint32_t points;
    auto bytes = _nativeSize(object, points);
    if (points > LUA_POINT_LIMIT - space.scene->points || points > LUA_POINT_LIMIT - memory->points) {
        return luaL_error(lua, "scene point limit exceeded");
    }
    if (bytes > LUA_NATIVE_MEMORY_LIMIT - space.scene->nativeUsed
        || bytes > LUA_NATIVE_MEMORY_LIMIT - memory->nativeUsed) {
        return luaL_error(lua, "scene native memory limit exceeded");
    }
    Result result;
    if (semanticLabel) {
        if (!space.parent || object->type() != Type::Text) {
            return luaL_error(lua, "a label requires an Object parent and Text child");
        }
        result = space.parent->label(static_cast<Text*>(object));
    } else {
        result = space.parent ? space.parent->add(object) : space.scene->scene->add(object);
    }
    if (result != Result::Success) return luaL_error(lua, "could not add %s: %s", name, tmath::result(result));
    space.scene->nativeUsed += bytes;
    space.scene->objects++;
    space.scene->points += points;
    memory->nativeUsed += bytes;
    memory->objects++;
    memory->points += points;
    owner->owner = false;
    if (object->type() == Type::Space) {
        luaL_getmetatable(lua, SPACE_METATABLE);
        lua_setmetatable(lua, -2);
    } else if (object->type() == Type::Group) {
        luaL_getmetatable(lua, GROUP_METATABLE);
        lua_setmetatable(lua, -2);
    }
    return 1;
}

static int _sceneGc(lua_State* lua)
{
    auto box = static_cast<LuaScene*>(luaL_checkudata(lua, 1, SCENE_METATABLE));
    if (box->owner && box->scene) {
        _releaseSceneBudget(box);
        delete box->scene;
    }
    box->scene = nullptr;
    box->owner = false;
    box->memory = nullptr;
    return 0;
}

static int _objectGc(lua_State* lua)
{
    auto owner = static_cast<LuaObject*>(lua_touserdata(lua, 1));
    if (owner->owner) delete owner->object;
    owner->object = nullptr;
    owner->scene = nullptr;
    owner->owner = false;
    return 0;
}

static int _line(lua_State* lua)
{
    auto space = _space(lua);
    luaL_checktype(lua, 2, LUA_TTABLE);
    _options(lua, 2, {"from", "to"});
    auto from = _fieldWorld(lua, 2, "from");
    auto to = _fieldWorld(lua, 2, "to");
    auto owner = _owner(lua, space.scene);
    return _add(lua, space, owner, Line::gen(from, to), 2, "line");
}

static int _arrow(lua_State* lua)
{
    auto space = _space(lua);
    luaL_checktype(lua, 2, LUA_TTABLE);
    _options(lua, 2, {"from", "to", "tail", "tip"});
    auto from = _fieldWorld(lua, 2, "from");
    auto to = _fieldWorld(lua, 2, "to");
    auto tail = _fieldNumber(lua, 2, "tail", 0.0f);
    auto tip = _fieldNumber(lua, 2, "tip", 16.0f);
    if (tail < 0.0f || tip < 0.0f) return luaL_error(lua, "tail and tip must be non-negative");
    auto owner = _owner(lua, space.scene);
    auto object = Arrow::gen(from, to);
    owner->object = object;
    if (object) {
        object->tail = tail;
        object->tip = tip;
    }
    return _add(lua, space, owner, object, 2, "arrow");
}

static int _point(lua_State* lua)
{
    auto space = _space(lua);
    luaL_checktype(lua, 2, LUA_TTABLE);
    _options(lua, 2, {"point"});
    auto point = _fieldWorld(lua, 2, "point");
    auto owner = _owner(lua, space.scene);
    return _add(lua, space, owner, Point::gen(point), 2, "point");
}

static void _text(lua_State* lua, int index, Text* object)
{
    if (!object) return;
    object->size = _fieldNumber(lua, index, "size", object->size);
    object->align = _fieldVec2(lua, index, "align", object->align);
    auto role = _fieldOptionalString(lua, index, "role", "text");
    if (std::strcmp(role, "h1") == 0) object->role = TextRole::H1;
    else if (std::strcmp(role, "h2") == 0) object->role = TextRole::H2;
    else if (std::strcmp(role, "h3") == 0) object->role = TextRole::H3;
    else if (std::strcmp(role, "text") == 0) object->role = TextRole::Text;
    else if (std::strcmp(role, "code") == 0) object->role = TextRole::Code;
    else luaL_error(lua, "text role must be 'h1', 'h2', 'h3', 'text' or 'code'");
    lua_pop(lua, 1);
    auto orientation = _fieldOptionalString(lua, index, "orientation", "billboard");
    if (std::strcmp(orientation, "billboard") == 0) {
        object->orientation = TextOrientation::Billboard;
    } else if (std::strcmp(orientation, "plane") == 0) {
        object->orientation = TextOrientation::Plane;
    } else {
        luaL_error(lua, "text orientation must be 'billboard' or 'plane'");
    }
    lua_pop(lua, 1);
    if (object->size <= 0.0f) luaL_error(lua, "size must be positive");
    lua_getfield(lua, index, "font");
    if (!lua_isnil(lua, -1)) {
        size_t size;
        auto font = luaL_checklstring(lua, -1, &size);
        if (std::strlen(font) != size) luaL_error(lua, "font cannot contain zero bytes");
        if (size > LUA_PATH_LIMIT) luaL_error(lua, "font name exceeds the 4096-byte limit");
        if (object->font(font) != Result::Success) luaL_error(lua, "out of memory while copying font");
    }
    lua_pop(lua, 1);
}

static int _textObject(lua_State* lua, bool semanticLabel)
{
    auto space = _space(lua);
    luaL_checktype(lua, 2, LUA_TTABLE);
    _options(lua, 2, {"text", "point", "size", "align", "font", "orientation", "role"});
    size_t size;
    auto value = _fieldString(lua, 2, "text", &size);
    if (size > LUA_TEXT_LIMIT) return luaL_error(lua, "text exceeds the 1 MiB limit");
    auto point = _fieldWorld(lua, 2, "point", {});
    auto owner = _owner(lua, space.scene);
    auto object = Text::gen(value, point);
    owner->object = object;
    _text(lua, 2, object);
    return _add(lua, space, owner, object, 2, semanticLabel ? "label" : "text",
                semanticLabel);
}

static int _textWorld(lua_State* lua)
{
    return _textObject(lua, false);
}

static int _label(lua_State* lua)
{
    return _textObject(lua, true);
}

static int _vector(lua_State* lua)
{
    auto space = _space(lua);
    luaL_checktype(lua, 2, LUA_TTABLE);
    _options(lua, 2, {"value", "origin", "tail", "tip"});
    auto value = _fieldWorld(lua, 2, "value");
    auto origin = _fieldWorld(lua, 2, "origin", {});
    auto tail = _fieldNumber(lua, 2, "tail", 0.0f);
    auto tip = _fieldNumber(lua, 2, "tip", 16.0f);
    if (tail < 0.0f || tip < 0.0f) return luaL_error(lua, "tail and tip must be non-negative");
    auto owner = _owner(lua, space.scene);
    auto object = Vector::gen(value, origin);
    owner->object = object;
    if (object) {
        object->tail = tail;
        object->tip = tip;
    }
    return _add(lua, space, owner, object, 2, "vector");
}

static int _groupGen(lua_State* lua)
{
    auto space = _space(lua);
    luaL_checktype(lua, 2, LUA_TTABLE);
    _options(lua, 2, {"matrix"});
    auto owner = _owner(lua, space.scene);
    auto object = Group::gen();
    owner->object = object;
    if (object && _has(lua, 2, "matrix")) {
        lua_getfield(lua, 2, "matrix");
        _matrix(lua, -1, object->model.e, 16, "matrix");
        lua_pop(lua, 1);
    }
    return _add(lua, space, owner, object, 2, "group");
}

static int _spaceGen(lua_State* lua)
{
    auto space = _space(lua);
    luaL_checktype(lua, 2, LUA_TTABLE);
    _options(lua, 2, {"x", "y", "z", "matrix", "axis_x", "axis_y", "axis_z", "numbers", "number_mode", "number_size", "number_color"});
    auto x = _fieldRange(lua, 2, "x", {});
    auto y = _fieldRange(lua, 2, "y", {});
    auto z = _fieldRange(lua, 2, "z", {});
    auto owner = _owner(lua, space.scene);
    auto object = Space::gen(x, y, z);
    owner->object = object;
    if (object) {
        if (_has(lua, 2, "matrix")) {
            lua_getfield(lua, 2, "matrix");
            _matrix(lua, -1, object->model.e, 16, "matrix");
            lua_pop(lua, 1);
        }
        Color axis;
        auto& theme = space.scene->scene->theme();
        if (_fieldColor(lua, 2, "axis_x", axis, &theme)) object->axisX = axis;
        if (_fieldColor(lua, 2, "axis_y", axis, &theme)) object->axisY = axis;
        if (_fieldColor(lua, 2, "axis_z", axis, &theme)) object->axisZ = axis;
        if (_fieldColor(lua, 2, "number_color", axis, &theme)) object->numberColor = axis;
        object->numbers = _fieldBool(lua, 2, "numbers", false);
        object->numberSize = _fieldNumber(lua, 2, "number_size", object->numberSize);
        auto mode = _fieldOptionalString(lua, 2, "number_mode", "fixed");
        if (std::strcmp(mode, "fixed") == 0) object->numberMode = NumberMode::Fixed;
        else if (std::strcmp(mode, "relative") == 0) object->numberMode = NumberMode::Relative;
        else {
            lua_pop(lua, 1);
            return luaL_error(lua, "number_mode must be 'fixed' or 'relative'");
        }
        lua_pop(lua, 1);
        if (object->numberSize <= 0.0f) return luaL_error(lua, "number_size must be positive");
    }
    return _add(lua, space, owner, object, 2, "space");
}

static int _circle(lua_State* lua)
{
    auto space = _space(lua);
    luaL_checktype(lua, 2, LUA_TTABLE);
    _options(lua, 2, {"center"});
    auto center = _fieldWorld(lua, 2, "center", {});
    auto radius = _fieldNumber(lua, 2, "radius", 1.0f);
    auto owner = _owner(lua, space.scene);
    return _add(lua, space, owner, Circle::gen(center, radius), 2, "circle");
}

static int _rectangle(lua_State* lua)
{
    auto space = _space(lua);
    luaL_checktype(lua, 2, LUA_TTABLE);
    _options(lua, 2, {"center", "size", "corner"});
    auto center = _fieldWorld(lua, 2, "center", {});
    auto size = _fieldVec2(lua, 2, "size", {1.0f, 1.0f});
    auto corner = _fieldNumber(lua, 2, "corner", 0.0f);
    auto owner = _owner(lua, space.scene);
    return _add(lua, space, owner, Rectangle::gen(center, size, corner), 2, "rectangle");
}

static int _polygon(lua_State* lua)
{
    auto space = _space(lua);
    luaL_checktype(lua, 2, LUA_TTABLE);
    _options(lua, 2, {"points"});
    lua_getfield(lua, 2, "points");
    if (lua_isnil(lua, -1)) return luaL_error(lua, "missing field 'points'");
    uint32_t count;
    auto points = _points(lua, -1, 3, count);
    if (count > LUA_POINT_LIMIT - space.scene->points) return luaL_error(lua, "scene point limit exceeded");
    if (static_cast<size_t>(count) * sizeof(Vec3) + 512u > LUA_NATIVE_MEMORY_LIMIT - space.scene->nativeUsed) {
        return luaL_error(lua, "scene native memory limit exceeded");
    }
    auto owner = _owner(lua, space.scene);
    return _add(lua, space, owner, Polygon::gen(points, count), 2, "polygon");
}

static int _plotPoints(lua_State* lua, const LuaSpace& space)
{
    uint32_t count;
    auto points = _points(lua, -1, 2, count);
    if (count > LUA_POINT_LIMIT - space.scene->points) return luaL_error(lua, "scene point limit exceeded");
    if (static_cast<size_t>(count) * sizeof(Vec3) + 512u > LUA_NATIVE_MEMORY_LIMIT - space.scene->nativeUsed) {
        return luaL_error(lua, "scene native memory limit exceeded");
    }
    auto owner = _owner(lua, space.scene);
    return _add(lua, space, owner, Plot::gen(points, count), 2, "plot");
}

static int _plotFunction(lua_State* lua, const LuaSpace& space)
{
    lua_getfield(lua, 2, "x_range");
    if (lua_isnil(lua, -1)) return luaL_error(lua, "plot fn requires x_range");
    auto range = _range(lua, -1, "x_range");
    lua_pop(lua, 1);
    auto intervals = std::floor((static_cast<double>(range.max) - range.min) / range.step);
    if (!std::isfinite(intervals) || intervals < 1.0 || intervals >= LUA_POINT_LIMIT) {
        return luaL_error(lua, "x_range produces an invalid sample count");
    }
    auto count = static_cast<uint32_t>(intervals) + 1u;
    auto upper = std::nextafter(range.max, std::numeric_limits<float>::infinity());
    auto sample = [&](uint32_t index) {
        return range.min + range.step * static_cast<float>(index);
    };
    while (count > 1u && (!std::isfinite(sample(count - 1u)) || sample(count - 1u) > upper))
        count--;
    while (count < LUA_POINT_LIMIT && std::isfinite(sample(count)) && sample(count) <= upper)
        count++;
    if (count > LUA_POINT_LIMIT - space.scene->points) return luaL_error(lua, "scene point limit exceeded");
    if (static_cast<size_t>(count) * sizeof(Vec3) + 512u > LUA_NATIVE_MEMORY_LIMIT - space.scene->nativeUsed) {
        return luaL_error(lua, "scene native memory limit exceeded");
    }
    auto points = static_cast<Vec3*>(lua_newuserdatauv(lua, sizeof(Vec3) * count, 0));
    for (auto i = 0u; i < count; i++) {
        auto x = range.min + range.step * static_cast<float>(i);
        if (x > range.max && x <= upper) x = range.max;
        lua_getfield(lua, 2, "fn");
        lua_pushnumber(lua, x);
        lua_call(lua, 1, 1);
        new (points + i) Vec3{x, _number(lua, -1, "plot fn result"), 0.0f};
        lua_pop(lua, 1);
    }
    auto owner = _owner(lua, space.scene);
    return _add(lua, space, owner, Plot::gen(points, count), 2, "plot");
}

static int _plot(lua_State* lua)
{
    auto space = _space(lua);
    luaL_checktype(lua, 2, LUA_TTABLE);
    _options(lua, 2, {"points", "fn", "x_range"});
    lua_getfield(lua, 2, "points");
    auto points = !lua_isnil(lua, -1);
    if (points && !lua_istable(lua, -1)) return luaL_error(lua, "points must be a table");
    lua_getfield(lua, 2, "fn");
    auto function = !lua_isnil(lua, -1);
    if (function && !lua_isfunction(lua, -1)) return luaL_error(lua, "fn must be a function");
    lua_pop(lua, 1);
    if (points && function) return luaL_error(lua, "plot accepts either points or fn, not both");
    if (points) return _plotPoints(lua, space);
    lua_pop(lua, 1);
    if (function) return _plotFunction(lua, space);
    return luaL_error(lua, "plot requires points or fn with x_range");
}

static int _route(lua_State* lua)
{
    auto space = _space(lua);
    luaL_checktype(lua, 2, LUA_TTABLE);
    _options(lua, 2, {"points", "tail", "tip"});
    lua_getfield(lua, 2, "points");
    if (lua_isnil(lua, -1)) return luaL_error(lua, "missing field 'points'");
    uint32_t count;
    auto points = _points(lua, -1, 2, count);
    if (count > LUA_POINT_LIMIT - space.scene->points) {
        return luaL_error(lua, "scene point limit exceeded");
    }
    if (static_cast<size_t>(count) * sizeof(Vec3) + 512u
        > LUA_NATIVE_MEMORY_LIMIT - space.scene->nativeUsed) {
        return luaL_error(lua, "scene native memory limit exceeded");
    }
    auto tail = _fieldNumber(lua, 2, "tail", 0.0f);
    auto tip = _fieldNumber(lua, 2, "tip", 16.0f);
    if (tail < 0.0f || tip < 0.0f) {
        return luaL_error(lua, "tail and tip must be non-negative");
    }
    auto owner = _owner(lua, space.scene);
    auto object = DirectedRoute::gen(points, count);
    owner->object = object;
    if (object) {
        object->tail = tail;
        object->tip = tip;
    }
    return _add(lua, space, owner, object, 2, "route");
}

static uint32_t _pathSamples(lua_State* lua, int index, uint32_t fallback)
{
    auto samples = _fieldInteger(lua, index, "samples", fallback);
    if (samples <= 0 || samples > LUA_PATH_SAMPLE_LIMIT) {
        luaL_error(lua, "samples must be an integer from 1 to %d",
                   static_cast<int>(LUA_PATH_SAMPLE_LIMIT));
    }
    return static_cast<uint32_t>(samples);
}

static int _path(lua_State* lua)
{
    auto space = _space(lua);
    luaL_checktype(lua, 2, LUA_TTABLE);
    _options(lua, 2, {"commands", "samples"});
    auto samples = _pathSamples(lua, 2, 24u);
    lua_getfield(lua, 2, "commands");
    if (lua_isnil(lua, -1)) return luaL_error(lua, "missing field 'commands'");
    luaL_checktype(lua, -1, LUA_TTABLE);
    auto table = lua_absindex(lua, -1);
    auto size = lua_rawlen(lua, table);
    if (size < 2u || size > UINT32_MAX || size > LUA_POINT_LIMIT) {
        return luaL_error(lua, "commands must contain 2 to %d entries",
                          static_cast<int>(LUA_POINT_LIMIT));
    }
    auto count = static_cast<uint32_t>(size);
    auto commands = static_cast<PathCommand*>(lua_newuserdatauv(lua, sizeof(PathCommand) * size, 0));
    auto points = uint64_t{0};
    for (auto i = 0u; i < count; i++) {
        lua_rawgeti(lua, table, i + 1u);
        luaL_checktype(lua, -1, LUA_TTABLE);
        auto item = lua_absindex(lua, -1);
        auto name = _fieldString(lua, item, "type");
        PathVerb verb;
        if (std::strcmp(name, "move") == 0) verb = PathVerb::Move;
        else if (std::strcmp(name, "line") == 0) verb = PathVerb::Line;
        else if (std::strcmp(name, "quadratic") == 0) verb = PathVerb::Quadratic;
        else if (std::strcmp(name, "cubic") == 0) verb = PathVerb::Cubic;
        else if (std::strcmp(name, "close") == 0) verb = PathVerb::Close;
        else return luaL_error(lua, "unknown path command '%s'", name);
        lua_pop(lua, 1);

        new (commands + i) PathCommand;
        commands[i].verb = verb;
        switch (verb) {
            case PathVerb::Move:
            case PathVerb::Line: {
                _options(lua, item, {"type", "to"}, false);
                commands[i].to = _fieldWorld(lua, item, "to");
                points++;
                break;
            }
            case PathVerb::Quadratic: {
                _options(lua, item, {"type", "control", "to"}, false);
                commands[i].control1 = _fieldWorld(lua, item, "control");
                commands[i].to = _fieldWorld(lua, item, "to");
                points += samples;
                break;
            }
            case PathVerb::Cubic: {
                _options(lua, item, {"type", "control1", "control2", "to"}, false);
                commands[i].control1 = _fieldWorld(lua, item, "control1");
                commands[i].control2 = _fieldWorld(lua, item, "control2");
                commands[i].to = _fieldWorld(lua, item, "to");
                points += samples;
                break;
            }
            case PathVerb::Close: {
                _options(lua, item, {"type"}, false);
                break;
            }
        }
        lua_pop(lua, 1);
        if (points > LUA_POINT_LIMIT - space.scene->points) {
            return luaL_error(lua, "scene point limit exceeded");
        }
    }
    if (commands[0].verb != PathVerb::Move) return luaL_error(lua, "path must begin with move");
    for (auto i = 1u; i < count; i++) {
        if (commands[i].verb == PathVerb::Move) return luaL_error(lua, "path supports one contour");
        if (commands[i].verb == PathVerb::Close && i + 1u != count) {
            return luaL_error(lua, "close must be the final path command");
        }
    }
    if (points * sizeof(Vec3) + 512u > LUA_NATIVE_MEMORY_LIMIT - space.scene->nativeUsed) {
        return luaL_error(lua, "scene native memory limit exceeded");
    }
    auto owner = _owner(lua, space.scene);
    return _add(lua, space, owner, Path::gen(commands, count, samples), 2, "path");
}

static int _curve(lua_State* lua)
{
    auto space = _space(lua);
    luaL_checktype(lua, 2, LUA_TTABLE);
    _options(lua, 2, {"from", "control1", "control2", "to", "samples"});
    auto samples = _pathSamples(lua, 2, 32u);
    auto points = static_cast<uint64_t>(samples) + 1u;
    if (points > LUA_POINT_LIMIT - space.scene->points) return luaL_error(lua, "scene point limit exceeded");
    if (points * sizeof(Vec3) + 512u > LUA_NATIVE_MEMORY_LIMIT - space.scene->nativeUsed) {
        return luaL_error(lua, "scene native memory limit exceeded");
    }
    auto from = _fieldWorld(lua, 2, "from");
    auto control1 = _fieldWorld(lua, 2, "control1");
    auto control2 = _fieldWorld(lua, 2, "control2");
    auto to = _fieldWorld(lua, 2, "to");
    auto owner = _owner(lua, space.scene);
    return _add(lua, space, owner, Curve::gen(from, control1, control2, to, samples), 2, "curve");
}

static int _surface(lua_State* lua)
{
    auto space = _space(lua);
    luaL_checktype(lua, 2, LUA_TTABLE);
    _options(lua, 2, {"points", "size", "mode", "shading"});
    lua_getfield(lua, 2, "size");
    if (lua_isnil(lua, -1)) return luaL_error(lua, "surface requires size");
    uint32_t columns;
    uint32_t rows;
    _size(lua, -1, columns, rows);
    lua_pop(lua, 1);
    if (columns < 2u || rows < 2u) {
        return luaL_error(lua, "surface size must be at least 2 by 2");
    }

    lua_getfield(lua, 2, "points");
    if (lua_isnil(lua, -1)) return luaL_error(lua, "surface requires points");
    luaL_checktype(lua, -1, LUA_TTABLE);
    auto table = lua_absindex(lua, -1);
    auto count = columns * rows;
    if (lua_rawlen(lua, table) != count) {
        return luaL_error(lua, "surface points must match columns times rows");
    }
    auto points = static_cast<Vec3*>(lua_newuserdatauv(lua, sizeof(Vec3) * count, 0));
    for (auto i = 0u; i < count; i++) {
        lua_rawgeti(lua, table, i + 1u);
        new (points + i) Vec3(_world(lua, -1, "surface point"));
        lua_pop(lua, 1);
    }
    lua_pop(lua, 1);

    auto modeName = _fieldOptionalString(lua, 2, "mode", "solid");
    SurfaceMode mode;
    if (std::strcmp(modeName, "solid") == 0) mode = SurfaceMode::Solid;
    else if (std::strcmp(modeName, "mesh") == 0) mode = SurfaceMode::Mesh;
    else if (std::strcmp(modeName, "solid_mesh") == 0) mode = SurfaceMode::SolidMesh;
    else return luaL_error(lua, "surface mode must be 'solid', 'mesh' or 'solid_mesh'");
    lua_pop(lua, 1);

    auto owner = _owner(lua, space.scene);
    auto object = SurfaceMesh::gen(points, columns, rows);
    owner->object = object;
    if (object) {
        object->mode = mode;
        object->shading = _fieldBool(lua, 2, "shading", true);
    }
    return _add(lua, space, owner, object, 2, "surface");
}

static Result _asset(LuaScene* scene, const char* name, const Asset*& asset, Asset*& owned)
{
    asset = scene->resolver ? scene->resolver(name, scene->resolverData) : nullptr;
    if (asset) return Result::Success;
    // Native fallback: relative names resolve against the script directory.
    auto size = std::strlen(name);
    auto memory = scene->memory;
    auto absolute = name[0] == '/' || name[0] == '\\' || (size > 2u && name[1] == ':');
    char* joined = nullptr;
    if (!absolute && memory->sourcePath && memory->sourceRoot) {
        if (memory->sourceRoot > SIZE_MAX - size - 1u) return Result::InvalidArguments;
        joined = new (std::nothrow) char[memory->sourceRoot + size + 1u];
        if (!joined) return Result::OutOfMemory;
        std::memcpy(joined, memory->sourcePath, memory->sourceRoot);
        std::memcpy(joined + memory->sourceRoot, name, size + 1u);
        name = joined;
    }
    auto result = AssetLoader::load(name, owned);
    delete[] joined;
    asset = owned;
    return result;
}

static int _picture(lua_State* lua)
{
    auto space = _space(lua);
    luaL_checktype(lua, 2, LUA_TTABLE);
    _options(lua, 2, {"asset", "pixels", "size", "center", "filter"});
    if (_has(lua, 2, "color") || _has(lua, 2, "stroke") || _has(lua, 2, "fill")
        || _has(lua, 2, "radius") || _has(lua, 2, "dash")
        || _has(lua, 2, "dash_offset")) {
        return luaL_error(lua, "picture preserves source colors; color, stroke, fill, radius, dash and dash_offset are unsupported");
    }
    auto hasAsset = _has(lua, 2, "asset");
    auto hasPixels = _has(lua, 2, "pixels");
    if (hasAsset == hasPixels) return luaL_error(lua, "picture requires exactly one of asset or pixels");
    if (hasAsset && _has(lua, 2, "size")) return luaL_error(lua, "picture size is only valid with pixels");
    auto center = _fieldWorld(lua, 2, "center", {});
    auto width = _fieldNumber(lua, 2, "width", 1.0f);
    auto filterName = _fieldOptionalString(lua, 2, "filter", "bilinear");
    ImageFilter filter;
    if (std::strcmp(filterName, "bilinear") == 0) filter = ImageFilter::Bilinear;
    else if (std::strcmp(filterName, "nearest") == 0) filter = ImageFilter::Nearest;
    else return luaL_error(lua, "picture filter must be 'bilinear' or 'nearest'");
    lua_pop(lua, 1);
    const Asset* asset = nullptr;
    Asset* owned = nullptr;
    auto status = Result::Success;
    char assetName[LUA_PATH_LIMIT + 1] = {};
    if (hasAsset) {
        size_t nameSize;
        auto name = _fieldString(lua, 2, "asset", &nameSize);
        if (!nameSize || nameSize > LUA_PATH_LIMIT) {
            return luaL_error(lua, "asset name must be 1 to 4096 bytes");
        }
        std::memcpy(assetName, name, nameSize + 1u);
        lua_pop(lua, 1);
        status = _asset(space.scene, assetName, asset, owned);
    } else {
        lua_getfield(lua, 2, "size");
        if (lua_isnil(lua, -1)) return luaL_error(lua, "picture pixels require size");
        uint32_t columns;
        uint32_t rows;
        _size(lua, -1, columns, rows);
        lua_pop(lua, 1);
        lua_getfield(lua, 2, "pixels");
        luaL_checktype(lua, -1, LUA_TTABLE);
        auto count = static_cast<size_t>(columns) * rows;
        if (lua_rawlen(lua, -1) != count) {
            return luaL_error(lua, "picture pixels must match columns times rows");
        }
        auto pixels = static_cast<uint32_t*>(lua_newuserdatauv(lua, count * sizeof(uint32_t), 0));
        for (auto i = 0u; i < count; i++) {
            lua_rawgeti(lua, -2, i + 1u);
            auto color = _color(lua, -1, "picture pixel");
            lua_pop(lua, 1);
            pixels[i] = static_cast<uint32_t>(color.a) << 24
                      | static_cast<uint32_t>(color.b) << 16
                      | static_cast<uint32_t>(color.g) << 8 | color.r;
        }
        status = AssetLoader::load(pixels, columns, rows, owned);
        asset = owned;
        lua_pop(lua, 2);
    }
    if (status != Result::Success) {
        delete owned;
        if (hasAsset) {
            return luaL_error(lua, "could not load asset '%s': %s", assetName, tmath::result(status));
        }
        return luaL_error(lua, "could not load picture pixels: %s", tmath::result(status));
    }
    auto owner = _owner(lua, space.scene);
    auto object = Picture::gen(asset, center, width);
    owner->object = object;
    delete owned;
    if (object) object->filter = filter;
    return _add(lua, space, owner, object, 2, "picture");
}

static int _cell(lua_State* lua)
{
    auto space = _space(lua);
    luaL_checktype(lua, 2, LUA_TTABLE);
    _options(lua, 2, {"origin", "size", "mode", "padding", "depth", "texture", "source", "destination", "patches"});
    if (_has(lua, 2, "stroke") || _has(lua, 2, "fill") || _has(lua, 2, "width")
        || _has(lua, 2, "radius") || _has(lua, 2, "dash")
        || _has(lua, 2, "dash_offset")) {
        return luaL_error(lua, "cell uses color, texture and patches; stroke, fill, width, radius, dash and dash_offset are unsupported");
    }
    if (!_has(lua, 2, "texture") && (_has(lua, 2, "source") || _has(lua, 2, "destination"))) {
        return luaL_error(lua, "cell source and destination require texture");
    }
    lua_getfield(lua, 2, "size");
    if (lua_isnil(lua, -1)) return luaL_error(lua, "cell requires size");
    uint32_t columns;
    uint32_t rows;
    _size(lua, -1, columns, rows);
    lua_pop(lua, 1);
    auto origin = _fieldWorld(lua, 2, "origin", {});
    auto modeName = _fieldOptionalString(lua, 2, "mode", "full");
    CellMode mode;
    if (std::strcmp(modeName, "full") == 0) mode = CellMode::Full;
    else if (std::strcmp(modeName, "padd") == 0) mode = CellMode::Padd;
    else return luaL_error(lua, "cell mode must be 'full' or 'padd'");
    lua_pop(lua, 1);
    auto padding = _fieldNumber(lua, 2, "padding", 0.05f);
    auto depth = _fieldNumber(lua, 2, "depth", 1.0f);
    Color color;
    _fieldColor(lua, 2, "color", color, &space.scene->scene->theme());
    // Texture regions and patches can raise through Lua; give the native Cell a GC owner first.
    auto owner = _owner(lua, space.scene);
    auto object = Cell::gen(origin, columns, rows, color, mode, padding);
    owner->object = object;
    if (object) object->depth = depth;
    if (object && _has(lua, 2, "texture")) {
        size_t nameSize;
        auto name = _fieldString(lua, 2, "texture", &nameSize);
        if (!nameSize || nameSize > LUA_PATH_LIMIT) {
            return luaL_error(lua, "texture name must be 1 to 4096 bytes");
        }
        char assetName[LUA_PATH_LIMIT + 1];
        std::memcpy(assetName, name, nameSize + 1u);
        lua_pop(lua, 1);
        auto source = _fieldRegion(lua, 2, "source");
        auto destination = _fieldRegion(lua, 2, "destination");
        const Asset* asset = nullptr;
        Asset* owned = nullptr;
        auto status = _asset(space.scene, assetName, asset, owned);
        if (status == Result::Success) status = object->texture(asset, source, destination);
        delete owned;
        if (status != Result::Success) {
            return luaL_error(lua, "could not apply texture '%s': %s", assetName, tmath::result(status));
        }
    }
    if (object && _has(lua, 2, "patches")) {
        lua_getfield(lua, 2, "patches");
        luaL_checktype(lua, -1, LUA_TTABLE);
        auto patches = lua_rawlen(lua, -1);
        if (patches > 16384u) {
            return luaL_error(lua, "cell patch limit exceeded");
        }
        for (auto i = 0u; i < patches; i++) {
            lua_rawgeti(lua, -1, i + 1u);
            luaL_checktype(lua, -1, LUA_TTABLE);
            _options(lua, -1, {"region", "color"}, false);
            auto region = _fieldRegion(lua, -1, "region");
            Color patchColor;
            if (!_fieldColor(lua, -1, "color", patchColor, &space.scene->scene->theme())) {
                return luaL_error(lua, "cell patch requires color");
            }
            auto status = object->fill(region, patchColor);
            lua_pop(lua, 1);
            if (status != Result::Success) {
                return luaL_error(lua, "invalid cell patch: %s", tmath::result(status));
            }
        }
        lua_pop(lua, 1);
    }
    return _add(lua, space, owner, object, 2, "cell");
}

static Object* _object(lua_State* lua, Scene* scene, int index)
{
    auto handle = _handle(lua, index);
    if (handle->scene->scene != scene || scene->object(handle->object->id()) != handle->object) {
        luaL_error(lua, "handle belongs to another scene");
    }
    return handle->object;
}

Scene* detail::luaScene(lua_State* lua, int index)
{
    return _sceneHandle(lua, index)->scene;
}

Object* detail::luaObject(lua_State* lua, Scene* scene, int index)
{
    return _object(lua, scene, index);
}

static int _connector(lua_State* lua)
{
    auto space = _space(lua);
    luaL_checktype(lua, 2, LUA_TTABLE);
    _options(lua, 2, {"from", "to", "padding", "tail", "tip"});
    lua_getfield(lua, 2, "from");
    if (lua_isnil(lua, -1)) return luaL_error(lua, "missing field 'from'");
    auto from = _object(lua, space.scene->scene, -1);
    lua_pop(lua, 1);
    lua_getfield(lua, 2, "to");
    if (lua_isnil(lua, -1)) return luaL_error(lua, "missing field 'to'");
    auto to = _object(lua, space.scene->scene, -1);
    lua_pop(lua, 1);
    auto owner = _owner(lua, space.scene);
    auto object = Connector::gen(from, to);
    owner->object = object;
    if (object) {
        object->padding = _fieldNumber(lua, 2, "padding", object->padding);
        object->tail = _fieldNumber(lua, 2, "tail", object->tail);
        object->tip = _fieldNumber(lua, 2, "tip", object->tip);
        if (object->padding < 0.0f || object->tail < 0.0f || object->tip < 0.0f) {
            return luaL_error(lua, "connector padding, tail and tip must be non-negative");
        }
    }
    return _add(lua, space, owner, object, 2, "connector");
}

static LuaObject* _layoutHandle(lua_State* lua)
{
    auto handle = _handle(lua, 1);
    if (!handle->scene->owner) luaL_error(lua, "scene already belongs to a viewport");
    if (handle->scene->sampleActive) {
        luaL_error(lua, "scene authoring is unavailable inside a sampling callback");
    }
    return handle;
}

static Result _sampleDimensions(const Space* space, uint32_t* counts, bool spatial)
{
    const Range* ranges[] = {&space->x, &space->y, &space->z};
    auto dimensions = spatial ? 3u : 2u;
    for (auto i = 0u; i < dimensions; i++) {
        auto& range = *ranges[i];
        if (!std::isfinite(range.min) || !std::isfinite(range.max)
            || !std::isfinite(range.step) || range.min > range.max || range.step <= 0.0f) {
            return Result::InvalidArguments;
        }
        auto step = static_cast<double>(range.step);
        auto start = std::ceil(static_cast<double>(range.min) / step) * step;
        auto tolerance = step * 0.001;
        if (!std::isfinite(start) || start > static_cast<double>(range.max) + tolerance) {
            return Result::InsufficientCondition;
        }
        auto samples = std::floor((static_cast<double>(range.max) + tolerance - start) / step) + 1.0;
        if (!std::isfinite(samples) || samples < 1.0 || samples > 4096.0) {
            return Result::InsufficientCondition;
        }
        counts[i] = static_cast<uint32_t>(samples);
    }
    if (!spatial) counts[2] = 1u;
    auto slice = static_cast<uint64_t>(counts[0]) * counts[1];
    if (slice > 16384u || slice * counts[2] > 65536u) {
        return Result::InsufficientCondition;
    }
    return Result::Success;
}

static Result _sampleFrames(const SampleTime& time, uint64_t volume,
                            uint32_t& frames)
{
    static constexpr uint64_t MaxColors = 262144u;
    if (!std::isfinite(time.duration) || time.duration < 0.0f || !time.fps) {
        return Result::InvalidArguments;
    }
    if (time.duration == 0.0f) {
        frames = 1u;
    } else {
        auto intervals = std::ceil(static_cast<double>(time.duration) * time.fps);
        if (!std::isfinite(intervals) || intervals < 1.0 || intervals > 4095.0) {
            return Result::InsufficientCondition;
        }
        frames = static_cast<uint32_t>(intervals) + 1u;
    }
    if (volume > MaxColors / frames) return Result::InsufficientCondition;
    return Result::Success;
}

struct LuaSample
{
    lua_State* lua = nullptr;
    int callback = 0;
    const char* name = nullptr;
    bool failed = false;
};

static bool _sample(float x, float y, float z, float time, Color& color,
                    void* data, bool spatial) noexcept
{
    auto context = static_cast<LuaSample*>(data);
    auto lua = context->lua;
    lua_pushvalue(lua, context->callback);
    lua_pushnumber(lua, x);
    lua_pushnumber(lua, y);
    if (spatial) lua_pushnumber(lua, z);
    lua_pushnumber(lua, time);
    if (lua_pcall(lua, spatial ? 4 : 3, 1, 0) != LUA_OK) {
        context->failed = true;
        return false;
    }
    if (lua_type(lua, -1) != LUA_TSTRING) {
        lua_pop(lua, 1);
        lua_pushfstring(lua, "%s callback must return a color string", context->name);
        context->failed = true;
        return false;
    }
    size_t size;
    auto value = lua_tolstring(lua, -1, &size);
    if (!_hex(value, size)) {
        lua_pop(lua, 1);
        lua_pushfstring(lua, "%s callback must return a #rgb, #rgba, #rrggbb or #rrggbbaa color",
                        context->name);
        context->failed = true;
        return false;
    }
    color = Color::hex(value);
    lua_pop(lua, 1);
    return true;
}

static bool _sampleCell(float x, float y, float time, Color& color, void* data) noexcept
{
    return _sample(x, y, 0.0f, time, color, data, false);
}

static bool _sampleVoxel(float x, float y, float z, float time, Color& color,
                         void* data) noexcept
{
    return _sample(x, y, z, time, color, data, true);
}

static int _sampleGen(lua_State* lua, bool spatial)
{
    auto name = spatial ? "voxel" : "cell";
    auto handle = _layoutHandle(lua);
    auto object = _object(lua, handle->scene->scene, 1);
    if (object->type() != Type::Space) return luaL_error(lua, "%s requires a Space", name);
    luaL_checktype(lua, 2, LUA_TFUNCTION);
    auto mode = CellMode::Padd;
    auto padding = 0.05f;
    SampleTime time;
    if (!lua_isnoneornil(lua, 3)) {
        luaL_checktype(lua, 3, LUA_TTABLE);
        _options(lua, 3, {"mode", "padding", "duration", "fps"}, false);
        auto modeName = _fieldOptionalString(lua, 3, "mode", "padd");
        if (std::strcmp(modeName, "full") == 0) mode = CellMode::Full;
        else if (std::strcmp(modeName, "padd") != 0) {
            return luaL_error(lua, "%s mode must be 'full' or 'padd'", name);
        }
        lua_pop(lua, 1);
        padding = _fieldNumber(lua, 3, "padding", padding);
        time.duration = _fieldNumber(lua, 3, "duration", time.duration);
        auto fps = _fieldInteger(lua, 3, "fps", time.fps);
        if (fps <= 0 || static_cast<uint64_t>(fps) > std::numeric_limits<uint32_t>::max()) {
            return luaL_error(lua, "%s fps must be a positive 32-bit integer", name);
        }
        time.fps = static_cast<uint32_t>(fps);
    }

    auto space = static_cast<Space*>(object);
    uint32_t counts[3];
    auto status = _sampleDimensions(space, counts, spatial);
    if (status != Result::Success) {
        return luaL_error(lua, "could not sample %s: %s", name, tmath::result(status));
    }
    auto volume = static_cast<uint64_t>(counts[0]) * counts[1] * counts[2];
    uint32_t frames;
    status = _sampleFrames(time, volume, frames);
    if (status != Result::Success) {
        return luaL_error(lua, "could not sample %s over time: %s", name,
                          tmath::result(status));
    }
    auto generated = counts[2] + 1u;
    auto scene = handle->scene;
    auto memory = scene->memory;
    if (generated > LUA_OBJECT_LIMIT - scene->objects
        || generated > LUA_OBJECT_LIMIT - memory->objects) {
        return luaL_error(lua, "scene object limit exceeded");
    }
    if (static_cast<uint64_t>(scene->objects + generated) * scene->clips
        > LUA_SAMPLE_WORK_LIMIT) {
        return luaL_error(lua, "scene evaluation limit exceeded");
    }
    auto bytes = size_t{512} + static_cast<size_t>(counts[2]) * 512u
               + static_cast<size_t>(volume) * frames * sizeof(Color);
    if (bytes > LUA_NATIVE_MEMORY_LIMIT - scene->nativeUsed
        || bytes > LUA_NATIVE_MEMORY_LIMIT - memory->nativeUsed) {
        return luaL_error(lua, "scene native memory limit exceeded");
    }

    auto context = LuaSample{lua, lua_absindex(lua, 2), name, false};
    Group* field = nullptr;
    scene->sampleActive = true;
    if (spatial) {
        status = space->voxel(_sampleVoxel, field, &context, mode, padding, time);
    } else {
        status = space->cell(_sampleCell, field, &context, mode, padding, time);
    }
    scene->sampleActive = false;
    if (context.failed) {
        auto message = lua_tostring(lua, -1);
        return luaL_error(lua, "%s", message ? message : "sampling callback failed");
    }
    if (status != Result::Success || !field) {
        return luaL_error(lua, "could not create %s field: %s", name, tmath::result(status));
    }

    auto owner = _owner(lua, scene);
    owner->object = field;
    owner->owner = false;
    luaL_getmetatable(lua, GROUP_METATABLE);
    lua_setmetatable(lua, -2);
    scene->nativeUsed += bytes;
    scene->objects += generated;
    memory->nativeUsed += bytes;
    memory->objects += generated;
    return 1;
}

static int _cellMethod(lua_State* lua)
{
    if (lua_type(lua, 2) == LUA_TFUNCTION) return _sampleGen(lua, false);
    return _cell(lua);
}

static int _voxel(lua_State* lua)
{
    return _sampleGen(lua, true);
}

static int _moveTo(lua_State* lua)
{
    auto handle = _layoutHandle(lua);
    auto result = handle->object->moveTo(_world(lua, 2, "point"));
    if (result != Result::Success) return luaL_error(lua, "could not move object: %s", tmath::result(result));
    return 0;
}

static int _nextTo(lua_State* lua)
{
    auto handle = _layoutHandle(lua);
    auto target = _object(lua, handle->scene->scene, 2);
    auto direction = _world(lua, 3, "direction");
    auto gap = lua_isnoneornil(lua, 4) ? 0.25f : _number(lua, 4, "gap");
    auto result = handle->object->nextTo(target, direction, gap);
    if (result != Result::Success) return luaL_error(lua, "could not place object: %s", tmath::result(result));
    return 0;
}

static int _alignTo(lua_State* lua)
{
    auto handle = _layoutHandle(lua);
    auto target = _object(lua, handle->scene->scene, 2);
    auto result = handle->object->alignTo(target, _world(lua, 3, "direction"));
    if (result != Result::Success) return luaL_error(lua, "could not align object: %s", tmath::result(result));
    return 0;
}

static int _arrange(lua_State* lua)
{
    auto handle = _layoutHandle(lua);
    if (handle->object->type() != Type::Group) return luaL_error(lua, "arrange requires a group");
    auto direction = lua_isnoneornil(lua, 2) ? Vec3{1.0f, 0.0f, 0.0f} : _world(lua, 2, "direction");
    auto gap = lua_isnoneornil(lua, 3) ? 0.25f : _number(lua, 3, "gap");
    auto result = static_cast<Group*>(handle->object)->arrange(direction, gap);
    if (result != Result::Success) return luaL_error(lua, "could not arrange group: %s", tmath::result(result));
    return 0;
}

static int _arrangeGrid(lua_State* lua)
{
    auto handle = _layoutHandle(lua);
    if (handle->object->type() != Type::Group) return luaL_error(lua, "arrange_grid requires a group");
    auto columns = _integer(lua, 2, "columns");
    if (columns <= 0 || columns > UINT32_MAX) return luaL_error(lua, "columns must be a positive 32-bit integer");
    auto columnGap = lua_isnoneornil(lua, 3) ? 0.25f : _number(lua, 3, "column gap");
    auto rowGap = lua_isnoneornil(lua, 4) ? 0.25f : _number(lua, 4, "row gap");
    auto result = static_cast<Group*>(handle->object)->arrangeGrid(static_cast<uint32_t>(columns), columnGap, rowGap);
    if (result != Result::Success) return luaL_error(lua, "could not arrange group: %s", tmath::result(result));
    return 0;
}

static AnimCurvePreset _curvePreset(lua_State* lua, const char* value, size_t size)
{
    auto matches = [value, size](const char* name) {
        auto length = std::strlen(name);
        return size == length && std::memcmp(value, name, length) == 0;
    };
    if (matches("linear")) return AnimCurvePreset::Linear;
    if (matches("smooth")) return AnimCurvePreset::Smooth;
    if (matches("ease_in")) return AnimCurvePreset::EaseIn;
    if (matches("ease_out")) return AnimCurvePreset::EaseOut;
    if (matches("ease_in_out")) return AnimCurvePreset::EaseInOut;
    if (matches("gentle")) return AnimCurvePreset::Gentle;
    if (matches("snappy")) return AnimCurvePreset::Snappy;
    if (matches("back")) return AnimCurvePreset::Back;
    if (matches("bounce")) return AnimCurvePreset::Bounce;
    if (matches("elastic")) return AnimCurvePreset::Elastic;
    luaL_error(lua, "unknown animation curve preset");
    return AnimCurvePreset::Smooth;
}

static AnimCurve _curve(lua_State* lua, int index)
{
    if (lua_isnoneornil(lua, index)) return AnimCurve::preset(AnimCurvePreset::Smooth);
    if (lua_isstring(lua, index)) {
        size_t size;
        auto value = lua_tolstring(lua, index, &size);
        return AnimCurve::preset(_curvePreset(lua, value, size));
    }
    luaL_checktype(lua, index, LUA_TTABLE);
    index = lua_absindex(lua, index);
    _options(lua, index, {"preset", "bezier", "strength", "reverse"}, false);
    auto hasPreset = _has(lua, index, "preset");
    auto hasBezier = _has(lua, index, "bezier");
    if (hasPreset == hasBezier) {
        luaL_error(lua, "animation curve requires exactly one of 'preset' or 'bezier'");
    }
    auto strength = _fieldNumber(lua, index, "strength", 1.0f);
    if (strength < 0.0f || strength > 2.0f) {
        luaL_error(lua, "animation curve strength must be between 0 and 2");
    }
    AnimCurve curve;
    if (hasPreset) {
        lua_getfield(lua, index, "preset");
        size_t size;
        auto value = luaL_checklstring(lua, -1, &size);
        curve = AnimCurve::preset(_curvePreset(lua, value, size), strength);
        lua_pop(lua, 1);
    } else {
        float bezier[4];
        lua_getfield(lua, index, "bezier");
        _matrix(lua, -1, bezier, 4, "animation curve bezier");
        lua_pop(lua, 1);
        curve = AnimCurve::cubicBezier({bezier[0], bezier[1]}, {bezier[2], bezier[3]}, strength);
    }
    curve.reverse = _fieldBool(lua, index, "reverse", false);
    if (!curve.valid()) {
        luaL_error(lua, "animation curve requires x controls in [0, 1] and y controls in [-2, 2]");
    }
    return curve;
}

AnimCurve detail::luaAnimCurve(lua_State* lua, int index)
{
    return _curve(lua, index);
}

static AnimCurve _fieldCurve(lua_State* lua, int index, const char* name)
{
    index = lua_absindex(lua, index);
    lua_getfield(lua, index, name);
    auto curve = _curve(lua, -1);
    lua_pop(lua, 1);
    return curve;
}

static AnimCurve _fieldEffectCurve(lua_State* lua, int index)
{
    auto hasEasing = _has(lua, index, "easing");
    auto hasCurve = _has(lua, index, "curve");
    if (hasEasing && hasCurve) luaL_error(lua, "use either 'easing' or 'curve', not both");
    if (hasCurve) return _fieldCurve(lua, index, "curve");
    if (hasEasing) return _fieldCurve(lua, index, "easing");
    return AnimCurve::preset(AnimCurvePreset::Smooth);
}

static float _duration(lua_State* lua, int index, float fallback, bool zero = false)
{
    if (lua_isnoneornil(lua, index)) return fallback;
    auto duration = _number(lua, index, "duration");
    if (duration < 0.0f || (!zero && duration == 0.0f)) luaL_error(lua, "duration must be %s", zero ? "non-negative" : "positive");
    return duration;
}

static float _fieldDuration(lua_State* lua, int index, const char* name, float fallback)
{
    auto duration = _fieldNumber(lua, index, name, fallback);
    if (duration <= 0.0f) luaL_error(lua, "%s must be positive", name);
    return duration;
}

static DrawDirection _direction(lua_State* lua, int index)
{
    if (lua_isnoneornil(lua, index)) return DrawDirection::Forward;
    size_t size;
    auto value = luaL_checklstring(lua, index, &size);
    if (size == 7u && std::memcmp(value, "forward", size) == 0) return DrawDirection::Forward;
    if (size == 7u && std::memcmp(value, "reverse", size) == 0) return DrawDirection::Reverse;
    if (size == 9u && std::memcmp(value, "clockwise", size) == 0) return DrawDirection::Clockwise;
    if (size == 16u && std::memcmp(value, "counterclockwise", size) == 0) {
        return DrawDirection::CounterClockwise;
    }
    return static_cast<DrawDirection>(luaL_error(
        lua, "direction must be 'forward', 'reverse', 'clockwise' or 'counterclockwise'"));
}

static GrowthEdge _growthEdge(lua_State* lua, int index)
{
    size_t size;
    auto value = luaL_checklstring(lua, index, &size);
    if (size == 4u && std::memcmp(value, "left", size) == 0) return GrowthEdge::Left;
    if (size == 5u && std::memcmp(value, "right", size) == 0) return GrowthEdge::Right;
    if (size == 6u && std::memcmp(value, "bottom", size) == 0) return GrowthEdge::Bottom;
    if (size == 3u && std::memcmp(value, "top", size) == 0) return GrowthEdge::Top;
    return static_cast<GrowthEdge>(luaL_error(
        lua, "growth edge must be 'left', 'right', 'bottom' or 'top'"));
}

static int _play(lua_State* lua, LuaScene* box, const Animation* animations, uint32_t count,
                 float duration, const AnimCurve& curve, float lag = 0.0f)
{
    auto memory = box->memory;
    if (count > LUA_GROUP_LIMIT) return luaL_error(lua, "animation group limit exceeded");
    if (count > LUA_CLIP_LIMIT - box->clips || count > LUA_CLIP_LIMIT - memory->clips) {
        return luaL_error(lua, "scene animation limit exceeded");
    }
    if (static_cast<uint64_t>(box->objects) * (box->clips + count) > LUA_SAMPLE_WORK_LIMIT) {
        return luaL_error(lua, "scene evaluation limit exceeded");
    }
    if (count > (LUA_NATIVE_MEMORY_LIMIT - box->nativeUsed) / LUA_CLIP_CHARGE
        || count > (LUA_NATIVE_MEMORY_LIMIT - memory->nativeUsed) / LUA_CLIP_CHARGE) {
        return luaL_error(lua, "scene native memory limit exceeded");
    }
    auto result = box->scene->play(animations, count, duration, curve, lag);
    if (result != Result::Success) return luaL_error(lua, "could not play animation: %s", tmath::result(result));
    auto bytes = static_cast<size_t>(count) * LUA_CLIP_CHARGE;
    box->nativeUsed += bytes;
    box->clips += count;
    memory->nativeUsed += bytes;
    memory->clips += count;
    return 0;
}

static int _play(lua_State* lua, LuaScene* box, const AnimationTarget* targets, uint32_t count,
                 float duration, const AnimCurve& curve, float lag)
{
    auto memory = box->memory;
    if (count > LUA_GROUP_LIMIT) return luaL_error(lua, "animation group limit exceeded");
    if (count > LUA_CLIP_LIMIT - box->clips || count > LUA_CLIP_LIMIT - memory->clips) {
        return luaL_error(lua, "scene animation limit exceeded");
    }
    if (static_cast<uint64_t>(box->objects) * (box->clips + count) > LUA_SAMPLE_WORK_LIMIT) {
        return luaL_error(lua, "scene evaluation limit exceeded");
    }
    if (count > (LUA_NATIVE_MEMORY_LIMIT - box->nativeUsed) / LUA_CLIP_CHARGE
        || count > (LUA_NATIVE_MEMORY_LIMIT - memory->nativeUsed) / LUA_CLIP_CHARGE) {
        return luaL_error(lua, "scene native memory limit exceeded");
    }
    auto result = box->scene->play(targets, count, duration, curve, lag);
    if (result != Result::Success) return luaL_error(lua, "could not play animation: %s", tmath::result(result));
    auto bytes = static_cast<size_t>(count) * LUA_CLIP_CHARGE;
    box->nativeUsed += bytes;
    box->clips += count;
    memory->nativeUsed += bytes;
    memory->clips += count;
    return 0;
}

static AnimationTarget _animationTarget(lua_State* lua, LuaScene* box, int index, Object*& object)
{
    luaL_checktype(lua, index, LUA_TTABLE);
    index = lua_absindex(lua, index);
    _options(lua, index,
             {"target", "shift", "transform", "opacity", "stroke", "fill",
              "dash_offset", "tail", "tip"},
             false);
    lua_getfield(lua, index, "target");
    if (lua_isnil(lua, -1)) luaL_error(lua, "animation descriptor requires a target");
    object = _object(lua, box->scene, -1);
    lua_pop(lua, 1);
    auto target = AnimationTarget::from(object);
    auto changed = false;
    auto shift = _has(lua, index, "shift");
    auto transform = _has(lua, index, "transform");
    if (shift && transform) luaL_error(lua, "animation descriptor cannot contain both shift and transform");
    if (shift) {
        lua_getfield(lua, index, "shift");
        target.shift(_world(lua, -1, "shift"));
        lua_pop(lua, 1);
        changed = true;
    }
    if (transform) {
        Mat4 matrix;
        lua_getfield(lua, index, "transform");
        _matrix(lua, -1, matrix.e, 16, "transform");
        lua_pop(lua, 1);
        target.transform(matrix);
        changed = true;
    }
    if (_has(lua, index, "opacity")) {
        auto opacity = _fieldNumber(lua, index, "opacity", 1.0f);
        if (opacity < 0.0f || opacity > 1.0f) luaL_error(lua, "opacity must be between 0 and 1");
        target.opacity(opacity);
        changed = true;
    }
    Color color;
    if (_fieldColor(lua, index, "stroke", color, &box->scene->theme())) {
        target.stroke(color);
        changed = true;
    }
    if (_fieldColor(lua, index, "fill", color, &box->scene->theme())) {
        target.fill(color);
        changed = true;
    }
    if (_has(lua, index, "dash_offset")) {
        target.dashOffset(_fieldNumber(lua, index, "dash_offset", 0.0f));
        changed = true;
    }
    if (_has(lua, index, "tail")) {
        auto tail = _fieldNumber(lua, index, "tail", 0.0f);
        if (tail < 0.0f) luaL_error(lua, "tail cannot be negative");
        target.tail(tail);
        changed = true;
    }
    if (_has(lua, index, "tip")) {
        auto tip = _fieldNumber(lua, index, "tip", 0.0f);
        if (tip < 0.0f) luaL_error(lua, "tip cannot be negative");
        target.tip(tip);
        changed = true;
    }
    if (!changed) luaL_error(lua, "animation descriptor requires at least one property");
    return target;
}

static int _playTargets(lua_State* lua)
{
    auto box = _scene(lua);
    luaL_checktype(lua, 2, LUA_TTABLE);
    auto duration = _duration(lua, 3, 1.0f);
    auto curve = _curve(lua, 4);
    auto lag = lua_isnoneornil(lua, 5) ? 0.0f : _number(lua, 5, "lag");
    if (lag < 0.0f) return luaL_error(lua, "lag cannot be negative");
    auto single = _has(lua, 2, "target");
    auto size = single ? size_t{1} : lua_rawlen(lua, 2);
    if (!size) return luaL_error(lua, "animation descriptor array cannot be empty");
    if (size > UINT32_MAX || size > LUA_MEMORY_LIMIT / sizeof(AnimationTarget)
        || size > LUA_MEMORY_LIMIT / sizeof(Object*)) {
        return luaL_error(lua, "animation descriptor array is too large");
    }
    auto targets = static_cast<AnimationTarget*>(lua_newuserdatauv(lua, sizeof(AnimationTarget) * size, 0));
    auto objects = static_cast<Object**>(lua_newuserdatauv(lua, sizeof(Object*) * size, 0));
    for (auto i = 0u; i < size; i++) {
        if (!single) lua_rawgeti(lua, 2, i + 1u);
        auto index = single ? 2 : -1;
        auto target = _animationTarget(lua, box, index, objects[i]);
        for (auto j = 0u; j < i; j++) {
            if (objects[j] == objects[i]) return luaL_error(lua, "animation targets must be distinct");
        }
        new (targets + i) AnimationTarget(target);
        if (!single) lua_pop(lua, 1);
    }
    return _play(lua, box, targets, static_cast<uint32_t>(size), duration, curve, lag);
}

static Animation _revealAnimation(Object* object, AnimationKind kind,
                                  DrawDirection direction)
{
    if (kind == AnimationKind::Create) return Animation::create(object, direction);
    if (kind == AnimationKind::Uncreate) return Animation::uncreate(object, direction);
    if (kind == AnimationKind::DrawBorderThenFill) {
        return Animation::drawBorderThenFill(object, direction);
    }
    if (kind == AnimationKind::Write) return Animation::write(object, direction);
    return Animation::fillReveal(object);
}

static int _reveal(lua_State* lua, AnimationKind kind)
{
    auto box = _scene(lua);
    auto scene = box->scene;
    auto duration = _duration(lua, 3, 1.0f);
    auto curve = _curve(lua, 4);
    auto lag = lua_isnoneornil(lua, 5) ? 0.0f : _number(lua, 5, "lag");
    auto directional = kind != AnimationKind::FillReveal;
    auto direction = directional ? _direction(lua, 6) : DrawDirection::Forward;
    if (lag < 0.0f) return luaL_error(lua, "lag cannot be negative");
    if (!lua_istable(lua, 2)) {
        auto object = _object(lua, scene, 2);
        auto animation = _revealAnimation(object, kind, direction);
        return _play(lua, box, &animation, 1, duration, curve, lag);
    }

    auto size = lua_rawlen(lua, 2);
    if (!size) return luaL_error(lua, "handle array cannot be empty");
    if (size > UINT32_MAX || size > LUA_MEMORY_LIMIT / sizeof(Animation)) {
        return luaL_error(lua, "handle array is too large");
    }
    auto animations = static_cast<Animation*>(lua_newuserdatauv(lua, sizeof(Animation) * size, 0));
    for (auto i = 0u; i < size; i++) {
        lua_rawgeti(lua, 2, i + 1);
        auto object = _object(lua, scene, -1);
        new (animations + i) Animation(_revealAnimation(object, kind, direction));
        lua_pop(lua, 1);
    }
    return _play(lua, box, animations, static_cast<uint32_t>(size), duration, curve, lag);
}

static int _create(lua_State* lua)
{
    return _reveal(lua, AnimationKind::Create);
}

static int _uncreate(lua_State* lua)
{
    return _reveal(lua, AnimationKind::Uncreate);
}

static int _fillReveal(lua_State* lua)
{
    return _reveal(lua, AnimationKind::FillReveal);
}

static int _drawBorderThenFill(lua_State* lua)
{
    return _reveal(lua, AnimationKind::DrawBorderThenFill);
}

static int _write(lua_State* lua)
{
    return _reveal(lua, AnimationKind::Write);
}

static int _shift(lua_State* lua)
{
    auto box = _scene(lua);
    auto scene = box->scene;
    auto object = _object(lua, scene, 2);
    auto duration = _duration(lua, 4, 1.0f);
    auto curve = _curve(lua, 5);
    auto animation = Animation::shift(object, _world(lua, 3, "shift"));
    return _play(lua, box, &animation, 1, duration, curve);
}

static int _transform(lua_State* lua)
{
    auto box = _scene(lua);
    auto scene = box->scene;
    auto object = _object(lua, scene, 2);
    Mat4 matrix;
    _matrix(lua, 3, matrix.e, 16, "matrix");
    auto animation = Animation::transform(object, matrix);
    return _play(lua, box, &animation, 1, _duration(lua, 4, 1.0f), _curve(lua, 5));
}

static int _fade(lua_State* lua)
{
    auto box = _scene(lua);
    auto scene = box->scene;
    auto object = _object(lua, scene, 2);
    auto opacity = _number(lua, 3, "opacity");
    if (opacity < 0.0f || opacity > 1.0f) return luaL_error(lua, "opacity must be between 0 and 1");
    auto animation = Animation::fade(object, opacity);
    return _play(lua, box, &animation, 1, _duration(lua, 4, 1.0f), _curve(lua, 5));
}

struct FadeOptions
{
    Vec3 shift;
    float scale = 1.0f;
    float duration = 1.0f;
    AnimCurve curve = AnimCurve::preset(AnimCurvePreset::Smooth);
};

static FadeOptions _fadeOptions(lua_State* lua, int index)
{
    FadeOptions options;
    if (lua_isnoneornil(lua, index)) return options;
    luaL_checktype(lua, index, LUA_TTABLE);
    index = lua_absindex(lua, index);
    _options(lua, index, {"shift", "scale", "duration", "easing", "curve"}, false);
    options.shift = _fieldWorld(lua, index, "shift", {});
    options.scale = _fieldNumber(lua, index, "scale", options.scale);
    if (options.scale <= 0.0f) luaL_error(lua, "scale must be positive");
    options.duration = _fieldDuration(lua, index, "duration", options.duration);
    options.curve = _fieldEffectCurve(lua, index);
    return options;
}

static int _fadeEffect(lua_State* lua, bool fadeIn)
{
    auto box = _scene(lua);
    auto object = _object(lua, box->scene, 2);
    auto options = _fadeOptions(lua, 3);
    auto animation = fadeIn ? Animation::fadeIn(object, options.shift, options.scale)
                            : Animation::fadeOut(object, options.shift, options.scale);
    return _play(lua, box, &animation, 1, options.duration, options.curve);
}

static int _fadeIn(lua_State* lua)
{
    return _fadeEffect(lua, true);
}

static int _fadeOut(lua_State* lua)
{
    return _fadeEffect(lua, false);
}

static int _growFromCenter(lua_State* lua)
{
    auto box = _scene(lua);
    auto animation = Animation::growFromCenter(_object(lua, box->scene, 2));
    return _play(lua, box, &animation, 1, _duration(lua, 3, 1.0f), _curve(lua, 4));
}

static int _growFromEdge(lua_State* lua)
{
    auto box = _scene(lua);
    auto animation = Animation::growFromEdge(_object(lua, box->scene, 2),
                                             _growthEdge(lua, 3));
    return _play(lua, box, &animation, 1, _duration(lua, 4, 1.0f), _curve(lua, 5));
}

static int _shrinkToCenter(lua_State* lua)
{
    auto box = _scene(lua);
    auto animation = Animation::shrinkToCenter(_object(lua, box->scene, 2));
    return _play(lua, box, &animation, 1, _duration(lua, 3, 1.0f), _curve(lua, 4));
}

static int _indicate(lua_State* lua)
{
    auto box = _scene(lua);
    auto object = _object(lua, box->scene, 2);
    auto color = box->scene->theme().colors.focus;
    auto scale = 1.2f;
    auto duration = 1.0f;
    auto curve = AnimCurve::preset(AnimCurvePreset::Smooth);
    if (!lua_isnoneornil(lua, 3)) {
        luaL_checktype(lua, 3, LUA_TTABLE);
        _options(lua, 3, {"color", "scale", "duration", "easing", "curve"}, false);
        _fieldColor(lua, 3, "color", color, &box->scene->theme());
        scale = _fieldNumber(lua, 3, "scale", scale);
        if (scale <= 1.0f) return luaL_error(lua, "indicate scale must be greater than 1");
        duration = _fieldDuration(lua, 3, "duration", duration);
        curve = _fieldEffectCurve(lua, 3);
    }
    auto animation = Animation::indicate(object, color, scale);
    return _play(lua, box, &animation, 1, duration, curve);
}

static int _morphEffect(lua_State* lua, bool replacement)
{
    auto box = _scene(lua);
    auto sourceArray = lua_istable(lua, 2);
    auto targetArray = lua_istable(lua, 3);
    if (sourceArray != targetArray) {
        return luaL_error(lua, "morph source and target must both be handles or arrays");
    }

    auto duration = _duration(lua, 4, 1.0f);
    auto curve = _curve(lua, 5);
    auto lag = lua_isnoneornil(lua, 6) ? 0.0f : _number(lua, 6, "lag");
    if (lag < 0.0f) return luaL_error(lua, "lag cannot be negative");

    if (!sourceArray) {
        auto source = _object(lua, box->scene, 2);
        auto target = _object(lua, box->scene, 3);
        auto animation = replacement ? Animation::replacementTransform(source, target)
                                     : Animation::morph(source, target);
        return _play(lua, box, &animation, 1, duration, curve, lag);
    }

    auto size = lua_rawlen(lua, 2);
    if (!size || size != lua_rawlen(lua, 3)) {
        return luaL_error(lua, "morph arrays must be non-empty and equally sized");
    }
    if (size > UINT32_MAX || size > LUA_MEMORY_LIMIT / sizeof(Animation)) {
        return luaL_error(lua, "morph arrays are too large");
    }
    auto animations = static_cast<Animation*>(lua_newuserdatauv(lua, sizeof(Animation) * size, 0));
    for (auto i = 0u; i < size; i++) {
        lua_rawgeti(lua, 2, i + 1u);
        auto source = _object(lua, box->scene, -1);
        lua_pop(lua, 1);
        lua_rawgeti(lua, 3, i + 1u);
        auto target = _object(lua, box->scene, -1);
        lua_pop(lua, 1);
        auto animation = replacement ? Animation::replacementTransform(source, target)
                                     : Animation::morph(source, target);
        new (animations + i) Animation(animation);
    }
    return _play(lua, box, animations, static_cast<uint32_t>(size), duration, curve, lag);
}

static int _morph(lua_State* lua)
{
    return _morphEffect(lua, false);
}

static int _replacementTransform(lua_State* lua)
{
    return _morphEffect(lua, true);
}

static int _fadeTransform(lua_State* lua)
{
    auto box = _scene(lua);
    auto source = _object(lua, box->scene, 2);
    auto target = _object(lua, box->scene, 3);
    constexpr auto count = 2u;
    auto memory = box->memory;
    if (count > LUA_CLIP_LIMIT - box->clips || count > LUA_CLIP_LIMIT - memory->clips) {
        return luaL_error(lua, "scene animation limit exceeded");
    }
    if (static_cast<uint64_t>(box->objects) * (box->clips + count) > LUA_SAMPLE_WORK_LIMIT) {
        return luaL_error(lua, "scene evaluation limit exceeded");
    }
    if (count > (LUA_NATIVE_MEMORY_LIMIT - box->nativeUsed) / LUA_CLIP_CHARGE
        || count > (LUA_NATIVE_MEMORY_LIMIT - memory->nativeUsed) / LUA_CLIP_CHARGE) {
        return luaL_error(lua, "scene native memory limit exceeded");
    }
    auto result = box->scene->fadeTransform(source, target, _duration(lua, 4, 1.0f),
                                            _curve(lua, 5));
    if (result != Result::Success) {
        return luaL_error(lua, "could not fade transform: %s", tmath::result(result));
    }
    auto bytes = static_cast<size_t>(count) * LUA_CLIP_CHARGE;
    box->nativeUsed += bytes;
    box->clips += count;
    memory->nativeUsed += bytes;
    memory->clips += count;
    return 0;
}

static size_t _groupSize(lua_State* lua, int index)
{
    if (!lua_istable(lua, index)) return 1;
    auto size = lua_rawlen(lua, index);
    if (!size) luaL_error(lua, "handle array cannot be empty");
    return size;
}

static Animation _transitionFade(lua_State* lua, Scene* scene, int index, float opacity)
{
    auto object = _object(lua, scene, index);
    if (opacity > 0.0f && object->opacity != 0.0f) luaL_error(lua, "incoming transition objects must have opacity 0");
    return Animation::fade(object, opacity);
}

static void _fadeGroup(lua_State* lua, Scene* scene, int index, Animation* animations, float opacity)
{
    if (!lua_istable(lua, index)) {
        new (animations) Animation(_transitionFade(lua, scene, index, opacity));
        return;
    }
    auto size = lua_rawlen(lua, index);
    for (auto i = 0u; i < size; i++) {
        lua_rawgeti(lua, index, i + 1);
        new (animations + i) Animation(_transitionFade(lua, scene, -1, opacity));
        lua_pop(lua, 1);
    }
}

static int _transition(lua_State* lua)
{
    auto box = _scene(lua);
    auto fromCnt = _groupSize(lua, 2);
    auto toCnt = _groupSize(lua, 3);
    if (fromCnt > SIZE_MAX - toCnt || fromCnt + toCnt > LUA_MEMORY_LIMIT / sizeof(Animation)) {
        return luaL_error(lua, "transition groups are too large");
    }
    auto count = fromCnt + toCnt;
    auto animations = static_cast<Animation*>(lua_newuserdatauv(lua, sizeof(Animation) * count, 0));
    _fadeGroup(lua, box->scene, 2, animations, 0.0f);
    _fadeGroup(lua, box->scene, 3, animations + fromCnt, 1.0f);
    return _play(lua, box, animations, static_cast<uint32_t>(count), _duration(lua, 4, 1.0f), _curve(lua, 5));
}

static int _stroke(lua_State* lua)
{
    auto box = _scene(lua);
    auto scene = box->scene;
    auto animation = Animation::stroke(_object(lua, scene, 2),
                                       _color(lua, 3, "stroke", &scene->theme()));
    return _play(lua, box, &animation, 1, _duration(lua, 4, 1.0f), _curve(lua, 5));
}

static int _fill(lua_State* lua)
{
    auto box = _scene(lua);
    auto scene = box->scene;
    auto animation = Animation::fill(_object(lua, scene, 2),
                                     _color(lua, 3, "fill", &scene->theme()));
    return _play(lua, box, &animation, 1, _duration(lua, 4, 1.0f), _curve(lua, 5));
}

static int _look(lua_State* lua)
{
    auto box = _scene(lua);
    luaL_checktype(lua, 2, LUA_TTABLE);
    _options(lua, 2, {"view", "eye", "target", "up", "height", "projection", "fov", "near", "far"}, false);
    auto camera = box->scene->config().camera;
    auto view = box->scene->config().cameraView;
    camera.eye = _fieldWorld(lua, 2, "eye", camera.eye);
    camera.target = _fieldWorld(lua, 2, "target", camera.target);
    camera.up = _fieldWorld(lua, 2, "up", camera.up);
    camera.orthoHeight = _fieldNumber(lua, 2, "height", camera.orthoHeight);
    camera.fov = _fieldNumber(lua, 2, "fov", camera.fov);
    camera.near = _fieldNumber(lua, 2, "near", camera.near);
    camera.far = _fieldNumber(lua, 2, "far", camera.far);
    lua_getfield(lua, 2, "view");
    if (!lua_isnil(lua, -1)) {
        auto value = luaL_checkstring(lua, -1);
        if (std::strcmp(value, "2d") == 0) view = CameraView::TwoD;
        else if (std::strcmp(value, "3d") == 0) view = CameraView::ThreeD;
        else return luaL_error(lua, "camera view must be '2d' or '3d'");
    }
    lua_pop(lua, 1);
    lua_getfield(lua, 2, "projection");
    if (!lua_isnil(lua, -1)) {
        auto value = luaL_checkstring(lua, -1);
        if (std::strcmp(value, "perspective") == 0) camera.projection = Projection::Perspective;
        else if (std::strcmp(value, "orthographic") == 0) camera.projection = Projection::Orthographic;
        else return luaL_error(lua, "projection must be 'perspective' or 'orthographic'");
    }
    lua_pop(lua, 1);
    auto memory = box->memory;
    if (box->clips >= LUA_CLIP_LIMIT || memory->clips >= LUA_CLIP_LIMIT) {
        return luaL_error(lua, "scene animation limit exceeded");
    }
    if (static_cast<uint64_t>(box->objects) * (box->clips + 1u) > LUA_SAMPLE_WORK_LIMIT) {
        return luaL_error(lua, "scene evaluation limit exceeded");
    }
    if (box->nativeUsed > LUA_NATIVE_MEMORY_LIMIT - LUA_CLIP_CHARGE
        || memory->nativeUsed > LUA_NATIVE_MEMORY_LIMIT - LUA_CLIP_CHARGE) {
        return luaL_error(lua, "scene native memory limit exceeded");
    }
    auto result = box->scene->look(camera, view, _duration(lua, 3, 1.0f), _curve(lua, 4));
    if (result != Result::Success) return luaL_error(lua, "could not animate camera: %s", tmath::result(result));
    box->nativeUsed += LUA_CLIP_CHARGE;
    box->clips++;
    memory->nativeUsed += LUA_CLIP_CHARGE;
    memory->clips++;
    return 0;
}

static int _wait(lua_State* lua)
{
    auto scene = _scene(lua)->scene;
    auto result = scene->wait(_duration(lua, 2, 1.0f, true));
    if (result != Result::Success) return luaL_error(lua, "could not wait: %s", tmath::result(result));
    return 0;
}

static int _remove(lua_State* lua)
{
    auto scene = _scene(lua)->scene;
    auto result = scene->remove(_object(lua, scene, 2));
    if (result != Result::Success) return luaL_error(lua, "could not remove object: %s", tmath::result(result));
    return 0;
}

static Viewport _viewportValue(lua_State* lua, int index)
{
    luaL_checktype(lua, index, LUA_TTABLE);
    _options(lua, index, {"x", "y", "width", "height"}, false);
    Viewport viewport;
    viewport.x = _fieldNumber(lua, index, "x", viewport.x);
    viewport.y = _fieldNumber(lua, index, "y", viewport.y);
    viewport.width = _fieldNumber(lua, index, "width", viewport.width);
    viewport.height = _fieldNumber(lua, index, "height", viewport.height);
    return viewport;
}

static int _viewport(lua_State* lua)
{
    auto parent = _scene(lua);
    auto child = static_cast<LuaScene*>(luaL_checkudata(lua, 2, SCENE_METATABLE));
    if (!child->scene) return luaL_error(lua, "viewport scene is no longer available");
    if (!child->owner) return luaL_error(lua, "viewport scene already has an owner");
    if (child == parent) return luaL_error(lua, "scene cannot contain itself as a viewport");
    auto viewport = _viewportValue(lua, 3);
    if (child->scenes > LUA_SCENE_LIMIT - parent->scenes) {
        return luaL_error(lua, "scene viewport limit exceeded");
    }
    auto memory = parent->memory;
    if (child->nativeUsed > LUA_NATIVE_MEMORY_LIMIT - LUA_VIEWPORT_CHARGE
        || child->nativeUsed + LUA_VIEWPORT_CHARGE > LUA_NATIVE_MEMORY_LIMIT - parent->nativeUsed
        || memory->nativeUsed > LUA_NATIVE_MEMORY_LIMIT - LUA_VIEWPORT_CHARGE) {
        return luaL_error(lua, "scene native memory limit exceeded");
    }
    if (child->points > LUA_POINT_LIMIT - parent->points) return luaL_error(lua, "scene point limit exceeded");
    if (child->clips > LUA_CLIP_LIMIT - parent->clips) return luaL_error(lua, "scene clip limit exceeded");
    if (child->objects > LUA_OBJECT_LIMIT - parent->objects) return luaL_error(lua, "scene object limit exceeded");
    if (static_cast<uint64_t>(parent->objects + child->objects) * (parent->clips + child->clips)
        > LUA_SAMPLE_WORK_LIMIT) {
        return luaL_error(lua, "scene evaluation limit exceeded");
    }
    auto result = parent->scene->viewport(child->scene, viewport);
    if (result != Result::Success) return luaL_error(lua, "could not add viewport: %s", tmath::result(result));
    parent->nativeUsed += child->nativeUsed + LUA_VIEWPORT_CHARGE;
    parent->objects += child->objects;
    parent->points += child->points;
    parent->clips += child->clips;
    parent->scenes += child->scenes;
    memory->nativeUsed += LUA_VIEWPORT_CHARGE;
    child->owner = false;
    child->scene = nullptr;
    child->memory = nullptr;
    return 0;
}

static int _sceneTransition(lua_State* lua)
{
    auto parent = _scene(lua);
    luaL_checktype(lua, 2, LUA_TTABLE);
    auto size = lua_rawlen(lua, 2);
    if (size < 2u || size > LUA_VIEWPORT_LIMIT) {
        return luaL_error(lua, "scene transition requires 2 to %d stages",
                          static_cast<int>(LUA_VIEWPORT_LIMIT));
    }
    if (lua_isnoneornil(lua, 3)) lua_newtable(lua);
    else luaL_checktype(lua, 3, LUA_TTABLE);
    auto options = lua_absindex(lua, 3);
    _options(lua, options, {"duration", "hold", "easing", "curve", "viewport"}, false);
    auto duration = _fieldDuration(lua, options, "duration", 1.0f);
    auto hold = _fieldNumber(lua, options, "hold", 0.0f);
    if (hold < 0.0f) return luaL_error(lua, "hold must be non-negative");
    auto curve = _fieldEffectCurve(lua, options);
    Viewport viewport;
    lua_getfield(lua, options, "viewport");
    if (!lua_isnil(lua, -1)) viewport = _viewportValue(lua, -1);
    lua_pop(lua, 1);

    auto scenes = static_cast<Scene**>(lua_newuserdatauv(lua, sizeof(Scene*) * size, 0));
    auto boxes = static_cast<LuaScene**>(lua_newuserdatauv(lua, sizeof(LuaScene*) * size, 0));
    auto totalNative = LUA_TRANSITION_CHARGE * (size + 1u);
    auto totalObjects = 0u;
    auto totalPoints = 0u;
    auto totalClips = 0u;
    auto totalScenes = 0u;
    for (auto i = 0u; i < size; i++) {
        lua_rawgeti(lua, 2, i + 1u);
        auto child = static_cast<LuaScene*>(luaL_checkudata(lua, -1, SCENE_METATABLE));
        lua_pop(lua, 1);
        if (!child->scene) return luaL_error(lua, "scene transition stage is no longer available");
        if (!child->owner) return luaL_error(lua, "scene transition stage already has an owner");
        if (child == parent) return luaL_error(lua, "scene cannot transition to itself");
        for (auto j = 0u; j < i; j++) {
            if (boxes[j] == child) return luaL_error(lua, "scene transition stages must be unique");
        }
        if (i + 1u < size) {
            auto matchBytes = static_cast<size_t>(child->objects) * sizeof(uint32_t);
            if (matchBytes > LUA_NATIVE_MEMORY_LIMIT - totalNative) {
                return luaL_error(lua, "scene native memory limit exceeded");
            }
            totalNative += matchBytes;
        }
        if (child->nativeUsed > LUA_NATIVE_MEMORY_LIMIT - totalNative) {
            return luaL_error(lua, "scene native memory limit exceeded");
        }
        totalNative += child->nativeUsed;
        if (child->objects > LUA_OBJECT_LIMIT - totalObjects) return luaL_error(lua, "scene object limit exceeded");
        if (child->points > LUA_POINT_LIMIT - totalPoints) return luaL_error(lua, "scene point limit exceeded");
        if (child->clips > LUA_CLIP_LIMIT - totalClips) return luaL_error(lua, "scene clip limit exceeded");
        if (child->scenes > LUA_SCENE_LIMIT - totalScenes) return luaL_error(lua, "scene transition limit exceeded");
        totalObjects += child->objects;
        totalPoints += child->points;
        totalClips += child->clips;
        totalScenes += child->scenes;
        scenes[i] = child->scene;
        boxes[i] = child;
    }
    if (totalScenes > LUA_SCENE_LIMIT - parent->scenes) return luaL_error(lua, "scene transition limit exceeded");
    if (totalObjects > LUA_OBJECT_LIMIT - parent->objects) return luaL_error(lua, "scene object limit exceeded");
    if (totalPoints > LUA_POINT_LIMIT - parent->points) return luaL_error(lua, "scene point limit exceeded");
    if (totalClips > LUA_CLIP_LIMIT - parent->clips) return luaL_error(lua, "scene clip limit exceeded");
    if (totalNative > LUA_NATIVE_MEMORY_LIMIT - parent->nativeUsed) {
        return luaL_error(lua, "scene native memory limit exceeded");
    }
    auto transitionNative = LUA_TRANSITION_CHARGE * (size + 1u);
    for (auto i = 0u; i + 1u < size; i++) {
        transitionNative += static_cast<size_t>(boxes[i]->objects) * sizeof(uint32_t);
    }
    auto memory = parent->memory;
    if (memory->nativeUsed > LUA_NATIVE_MEMORY_LIMIT - transitionNative) {
        return luaL_error(lua, "scene native memory limit exceeded");
    }
    if (static_cast<uint64_t>(parent->objects + totalObjects)
        * (parent->clips + totalClips) > LUA_SAMPLE_WORK_LIMIT) {
        return luaL_error(lua, "scene evaluation limit exceeded");
    }
    auto result = parent->scene->transition(scenes, static_cast<uint32_t>(size), viewport,
                                            duration, hold, curve);
    if (result != Result::Success) {
        return luaL_error(lua, "could not add scene transition: %s", tmath::result(result));
    }
    parent->nativeUsed += totalNative;
    parent->objects += totalObjects;
    parent->points += totalPoints;
    parent->clips += totalClips;
    parent->scenes += totalScenes;
    memory->nativeUsed += transitionNative;
    for (auto i = 0u; i < size; i++) {
        boxes[i]->owner = false;
        boxes[i]->scene = nullptr;
        boxes[i]->memory = nullptr;
    }
    return 0;
}

static int _sceneDuration(lua_State* lua)
{
    lua_pushnumber(lua, _scene(lua)->scene->duration());
    return 1;
}

static ThemePreset _themePreset(lua_State* lua, int index)
{
    size_t size;
    auto value = luaL_checklstring(lua, index, &size);
    if (std::strlen(value) != size) luaL_error(lua, "theme preset cannot contain zero bytes");
    if (std::strcmp(value, "3_blue_1_eyes") == 0) return ThemePreset::ThreeBlueOneEyes;
    if (std::strcmp(value, "pro_white") == 0 || std::strcmp(value, "pro") == 0) {
        return ThemePreset::ProWhite;
    }
    if (std::strcmp(value, "pro_black") == 0) return ThemePreset::ProBlack;
    if (std::strcmp(value, "adaptive_vscode") == 0) return ThemePreset::AdaptiveVscode;
    luaL_error(lua, "theme preset must be '3_blue_1_eyes', 'pro_white', 'pro_black' or 'adaptive_vscode'");
    return ThemePreset::ProWhite;
}

static Theme _themePresetValue(lua_State* lua, int index)
{
    auto preset = _themePreset(lua, index);
    if (preset != ThemePreset::AdaptiveVscode) return Theme::preset(preset);
    void* memoryData = nullptr;
    lua_getallocf(lua, &memoryData);
    auto memory = static_cast<LuaMemory*>(memoryData);
    memory->adaptiveThemeUsed = true;
    return memory->hasAdaptiveTheme ? memory->adaptiveTheme : Theme::preset(preset);
}

static void _themeText(lua_State* lua, int index, const char* name, TextTheme& text)
{
    index = lua_absindex(lua, index);
    lua_getfield(lua, index, name);
    if (lua_isnil(lua, -1)) {
        lua_pop(lua, 1);
        return;
    }
    luaL_checktype(lua, -1, LUA_TTABLE);
    auto style = lua_absindex(lua, -1);
    _options(lua, style, {"font", "size", "color"}, false);
    lua_getfield(lua, style, "font");
    if (!lua_isnil(lua, -1)) {
        size_t size;
        auto font = luaL_checklstring(lua, -1, &size);
        if (!size || size > LUA_PATH_LIMIT || std::strlen(font) != size) {
            luaL_error(lua, "theme font must be 1 to 4096 bytes without zero bytes");
        }
        text.font = font;
    }
    lua_pop(lua, 1);
    text.size = _fieldNumber(lua, style, "size", text.size);
    _fieldColor(lua, style, "color", text.color);
    if (text.size <= 0.0f) luaL_error(lua, "theme text size must be positive");
    lua_pop(lua, 1);
}

static Theme _theme(lua_State* lua, int index)
{
    if (lua_type(lua, index) == LUA_TSTRING) {
        return _themePresetValue(lua, index);
    }
    luaL_checktype(lua, index, LUA_TTABLE);
    index = lua_absindex(lua, index);
    _options(lua, index,
             {"preset", "background", "text", "objects", "object_width", "gradient",
              "end_gradient_stop", "axis", "colors"}, false);

    auto theme = Theme::preset(ThemePreset::ProWhite);
    lua_getfield(lua, index, "preset");
    if (!lua_isnil(lua, -1)) theme = _themePresetValue(lua, -1);
    lua_pop(lua, 1);
    _fieldColor(lua, index, "background", theme.background);
    theme.gradient = _fieldBool(lua, index, "gradient", theme.gradient);
    _fieldColor(lua, index, "end_gradient_stop", theme.endGradientStop);

    lua_getfield(lua, index, "text");
    if (!lua_isnil(lua, -1)) {
        luaL_checktype(lua, -1, LUA_TTABLE);
        auto text = lua_absindex(lua, -1);
        _options(lua, text, {"h1", "h2", "h3", "text", "code"}, false);
        _themeText(lua, text, "h1", theme.h1);
        _themeText(lua, text, "h2", theme.h2);
        _themeText(lua, text, "h3", theme.h3);
        _themeText(lua, text, "text", theme.text);
        _themeText(lua, text, "code", theme.code);
    }
    lua_pop(lua, 1);

    lua_getfield(lua, index, "colors");
    if (!lua_isnil(lua, -1)) {
        luaL_checktype(lua, -1, LUA_TTABLE);
        auto colors = lua_absindex(lua, -1);
        _options(lua, colors,
                 {"foreground", "muted", "accent", "secondary", "success", "warning",
                  "danger", "info", "surface", "border", "result", "focus"}, false);
        _fieldColor(lua, colors, "foreground", theme.colors.foreground);
        _fieldColor(lua, colors, "muted", theme.colors.muted);
        _fieldColor(lua, colors, "accent", theme.colors.accent);
        _fieldColor(lua, colors, "secondary", theme.colors.secondary);
        _fieldColor(lua, colors, "success", theme.colors.success);
        _fieldColor(lua, colors, "warning", theme.colors.warning);
        _fieldColor(lua, colors, "danger", theme.colors.danger);
        _fieldColor(lua, colors, "info", theme.colors.info);
        _fieldColor(lua, colors, "surface", theme.colors.surface);
        _fieldColor(lua, colors, "border", theme.colors.border);
        _fieldColor(lua, colors, "result", theme.colors.result);
        _fieldColor(lua, colors, "focus", theme.colors.focus);
    }
    lua_pop(lua, 1);

    lua_getfield(lua, index, "objects");
    if (!lua_isnil(lua, -1)) {
        luaL_checktype(lua, -1, LUA_TTABLE);
        auto objects = lua_absindex(lua, -1);
        auto count = lua_rawlen(lua, objects);
        if (!count || count > Theme::ColorLimit) {
            luaL_error(lua, "theme objects must contain 1 to %d colors",
                       static_cast<int>(Theme::ColorLimit));
        }
        lua_pushnil(lua);
        while (lua_next(lua, objects)) {
            if (!lua_isinteger(lua, -2)) luaL_error(lua, "theme object colors must use array indices");
            auto key = lua_tointeger(lua, -2);
            if (key < 1 || static_cast<size_t>(key) > count) {
                luaL_error(lua, "theme object colors must be a dense array");
            }
            lua_pop(lua, 1);
        }
        for (auto i = 0u; i < count; i++) {
            lua_rawgeti(lua, objects, i + 1u);
            theme.objects[i] = _color(lua, -1, "theme object color");
            lua_pop(lua, 1);
        }
        theme.objectCount = static_cast<uint32_t>(count);
    }
    lua_pop(lua, 1);

    theme.objectWidth = _fieldNumber(lua, index, "object_width", theme.objectWidth);
    if (theme.objectWidth <= 0.0f) luaL_error(lua, "theme object_width must be positive");

    lua_getfield(lua, index, "axis");
    if (!lua_isnil(lua, -1)) {
        luaL_checktype(lua, -1, LUA_TTABLE);
        auto axis = lua_absindex(lua, -1);
        _options(lua, axis, {"x", "y", "z", "grid", "label"}, false);
        _fieldColor(lua, axis, "x", theme.axis.x);
        _fieldColor(lua, axis, "y", theme.axis.y);
        _fieldColor(lua, axis, "z", theme.axis.z);
        _fieldColor(lua, axis, "grid", theme.axis.grid);
        _fieldColor(lua, axis, "label", theme.axis.label);
    }
    lua_pop(lua, 1);
    return theme;
}

static int _sceneGen(lua_State* lua)
{
    if (!detail::luaAuthoring(lua)) {
        return luaL_error(lua, "scene authoring is unavailable after loading");
    }
    luaL_checktype(lua, 1, LUA_TTABLE);
    _options(lua, 1, {"width", "height", "fps", "background", "camera", "antialiasing", "loop", "theme"}, false);
    Config config;
    auto width = _fieldInteger(lua, 1, "width", config.width);
    auto height = _fieldInteger(lua, 1, "height", config.height);
    auto fps = _fieldInteger(lua, 1, "fps", config.fps);
    if (width <= 0 || width > UINT32_MAX || height <= 0 || height > UINT32_MAX || fps <= 0 || fps > UINT32_MAX) {
        return luaL_error(lua, "width, height and fps must be positive 32-bit integers");
    }
    config.width = static_cast<uint32_t>(width);
    config.height = static_cast<uint32_t>(height);
    config.fps = static_cast<uint32_t>(fps);
    lua_getfield(lua, 1, "antialiasing");
    if (!lua_isnil(lua, -1)) {
        if (!lua_isboolean(lua, -1)) return luaL_error(lua, "antialiasing must be a boolean");
        config.antialiasing = lua_toboolean(lua, -1);
    }
    lua_pop(lua, 1);
    lua_getfield(lua, 1, "loop");
    if (!lua_isnil(lua, -1)) {
        if (!lua_isboolean(lua, -1)) return luaL_error(lua, "loop must be a boolean");
        config.loop = lua_toboolean(lua, -1);
    }
    lua_pop(lua, 1);
    if (config.height > LUA_PIXEL_LIMIT / config.width) return luaL_error(lua, "scene pixel limit exceeded");
    auto backgroundAuthored = _fieldColor(lua, 1, "background", config.background);
    auto hasTheme = _has(lua, 1, "theme");
    Theme theme;
    if (hasTheme) {
        lua_getfield(lua, 1, "theme");
        theme = _theme(lua, -1);
        lua_pop(lua, 1);
    }

    if (_has(lua, 1, "camera")) {
        lua_getfield(lua, 1, "camera");
        luaL_checktype(lua, -1, LUA_TTABLE);
        auto index = lua_absindex(lua, -1);
        _options(lua, index,
                 {"mode", "view", "target", "eye", "up", "height", "projection", "fov", "near", "far"},
                 false);
        auto mode = _fieldOptionalString(lua, index, "mode", "fixed");
        if (std::strcmp(mode, "fixed") == 0) config.cameraMode = CameraMode::Fixed;
        else if (std::strcmp(mode, "interactive") == 0) config.cameraMode = CameraMode::Interactive;
        else return luaL_error(lua, "camera mode must be 'fixed' or 'interactive'");

        auto view = _fieldOptionalString(lua, index, "view", "2d");
        if (std::strcmp(view, "2d") == 0) {
            config.cameraView = CameraView::TwoD;
            auto target = _fieldWorld(lua, index, "target", {});
            auto viewHeight = _fieldNumber(lua, index, "height", config.camera.orthoHeight);
            config.camera.target = target;
            config.camera.eye = target + Vec3{0.0f, 0.0f, 10.0f};
            config.camera.up = {0.0f, 1.0f, 0.0f};
            config.camera.projection = Projection::Orthographic;
            config.camera.orthoHeight = viewHeight;
        } else if (std::strcmp(view, "3d") == 0) {
            config.cameraView = CameraView::ThreeD;
            config.camera.eye = _fieldWorld(lua, index, "eye", {6.0f, 4.0f, 6.0f});
            config.camera.target = _fieldWorld(lua, index, "target", config.camera.target);
            config.camera.up = _fieldWorld(lua, index, "up", config.camera.up);
            config.camera.fov = _fieldNumber(lua, index, "fov", config.camera.fov);
            config.camera.orthoHeight = _fieldNumber(lua, index, "height", config.camera.orthoHeight);
            config.camera.near = _fieldNumber(lua, index, "near", config.camera.near);
            config.camera.far = _fieldNumber(lua, index, "far", config.camera.far);
            config.camera.projection = Projection::Perspective;
            lua_getfield(lua, index, "projection");
            if (!lua_isnil(lua, -1)) {
                auto projection = luaL_checkstring(lua, -1);
                if (std::strcmp(projection, "perspective") == 0) config.camera.projection = Projection::Perspective;
                else if (std::strcmp(projection, "orthographic") == 0) config.camera.projection = Projection::Orthographic;
                else return luaL_error(lua, "projection must be 'perspective' or 'orthographic'");
            }
            lua_pop(lua, 1);
        } else {
            return luaL_error(lua, "camera view must be '2d' or '3d'");
        }
        lua_pop(lua, 1);
    }

    if (config.camera.near <= 0.0f || config.camera.far <= config.camera.near) {
        return luaL_error(lua, "camera requires 0 < near < far");
    }
    if (config.camera.fov <= 0.0f || config.camera.fov >= 3.14159265359f) {
        return luaL_error(lua, "camera fov must be in radians between 0 and pi");
    }
    if (config.camera.orthoHeight <= 0.0f) return luaL_error(lua, "camera height must be positive");

    void* memoryData = nullptr;
    lua_getallocf(lua, &memoryData);
    auto memory = static_cast<LuaMemory*>(memoryData);
    if (memory->scenes >= LUA_SCENE_LIMIT) return luaL_error(lua, "scene limit exceeded");
    if (memory->nativeUsed > LUA_NATIVE_MEMORY_LIMIT - LUA_SCENE_CHARGE) {
        return luaL_error(lua, "scene native memory limit exceeded");
    }
    auto box = new (lua_newuserdatauv(lua, sizeof(LuaScene), 0)) LuaScene;
    luaL_getmetatable(lua, SCENE_METATABLE);
    lua_setmetatable(lua, -2);
    box->scene = Scene::gen(config);
    if (!box->scene) return luaL_error(lua, "could not create scene: invalid configuration or out of memory");
    if (hasTheme) {
        auto result = box->scene->theme(theme);
        if (result != Result::Success) {
            return luaL_error(lua, "could not apply scene theme: %s", tmath::result(result));
        }
        if (backgroundAuthored) box->scene->config().background = config.background;
    }
    box->nativeUsed = LUA_SCENE_CHARGE;
    box->memory = memory;
    box->resolver = memory->resolver;
    box->resolverData = memory->resolverData;
    memory->nativeUsed += LUA_SCENE_CHARGE;
    memory->scenes++;
    return 1;
}

static const luaL_Reg SCENE_METHODS[] = {
    {"group", _groupGen},
    {"space", _spaceGen},
    {"point", _point},
    {"line", _line},
    {"arrow", _arrow},
    {"vector", _vector},
    {"circle", _circle},
    {"rectangle", _rectangle},
    {"polygon", _polygon},
    {"plot", _plot},
    {"route", _route},
    {"path", _path},
    {"curve", _curve},
    {"surface", _surface},
    {"text", _textWorld},
    {"picture", _picture},
    {"cell", _cell},
    {"connector", _connector},
    {"viewport", _viewport},
    {"scene_transition", _sceneTransition},
    {"play", _playTargets},
    {"create", _create},
    {"uncreate", _uncreate},
    {"fill_reveal", _fillReveal},
    {"draw_border_then_fill", _drawBorderThenFill},
    {"write", _write},
    {"shift", _shift},
    {"transform", _transform},
    {"fade", _fade},
    {"fade_in", _fadeIn},
    {"fade_out", _fadeOut},
    {"grow_from_center", _growFromCenter},
    {"grow_from_edge", _growFromEdge},
    {"shrink_to_center", _shrinkToCenter},
    {"indicate", _indicate},
    {"morph", _morph},
    {"replacement_transform", _replacementTransform},
    {"fade_transform", _fadeTransform},
    {"transition", _transition},
    {"stroke", _stroke},
    {"fill", _fill},
    {"look", _look},
    {"wait", _wait},
    {"remove", _remove},
    {"duration", _sceneDuration},
    {nullptr, nullptr}};

static const luaL_Reg OBJECT_METHODS[] = {
    {"group", _groupGen},
    {"space", _spaceGen},
    {"point", _point},
    {"line", _line},
    {"arrow", _arrow},
    {"vector", _vector},
    {"circle", _circle},
    {"rectangle", _rectangle},
    {"polygon", _polygon},
    {"plot", _plot},
    {"route", _route},
    {"path", _path},
    {"curve", _curve},
    {"surface", _surface},
    {"text", _textWorld},
    {"label", _label},
    {"picture", _picture},
    {"cell", _cell},
    {"connector", _connector},
    {"move_to", _moveTo},
    {"next_to", _nextTo},
    {"align_to", _alignTo},
    {"arrange", _arrange},
    {"arrange_grid", _arrangeGrid},
    {nullptr, nullptr}};

static void _library(lua_State* lua, const char* name, lua_CFunction open)
{
    luaL_requiref(lua, name, open, 1);
    lua_pop(lua, 1);
}

static int _toString(lua_State* lua)
{
    switch (lua_type(lua, 1)) {
        case LUA_TNIL: lua_pushliteral(lua, "nil"); break;
        case LUA_TBOOLEAN: lua_pushstring(lua, lua_toboolean(lua, 1) ? "true" : "false"); break;
        case LUA_TNUMBER:
        case LUA_TSTRING: luaL_tolstring(lua, 1, nullptr); break;
        default: return luaL_error(lua, "tostring accepts only nil, booleans, numbers and strings");
    }
    return 1;
}

static int _format(lua_State* lua)
{
    size_t size;
    auto format = luaL_checklstring(lua, 1, &size);
    static constexpr auto conversions = "cdiuoxXaAfFeEgGpsq";
    for (auto i = 0u; i < size; i++) {
        if (format[i] != '%') continue;
        if (++i < size && format[i] == '%') continue;
        while (i < size && !std::strchr(conversions, format[i]))
            i++;
        if (i < size && format[i] == 'p') return luaL_error(lua, "string.format %%p is unavailable");
    }
    auto count = lua_gettop(lua);
    for (auto i = 2; i <= count; i++) {
        auto type = lua_type(lua, i);
        if (type != LUA_TNIL && type != LUA_TBOOLEAN && type != LUA_TNUMBER && type != LUA_TSTRING) {
            return luaL_argerror(lua, i, "format values must be nil, booleans, numbers or strings");
        }
    }
    lua_pushvalue(lua, lua_upvalueindex(1));
    lua_insert(lua, 1);
    lua_call(lua, count, LUA_MULTRET);
    return lua_gettop(lua);
}

static int _open(lua_State* lua)
{
    _library(lua, LUA_GNAME, luaopen_base);
    _library(lua, LUA_TABLIBNAME, luaopen_table);
    _library(lua, LUA_STRLIBNAME, luaopen_string);
    _library(lua, LUA_MATHLIBNAME, luaopen_math);
    _library(lua, LUA_UTF8LIBNAME, luaopen_utf8);

    lua_getglobal(lua, LUA_MATHLIBNAME);
    lua_getfield(lua, -1, "randomseed");
    lua_pushinteger(lua, 0);
    lua_call(lua, 1, 0);
    lua_pushnil(lua);
    lua_setfield(lua, -2, "randomseed");
    lua_pop(lua, 1);

    lua_pushcfunction(lua, _toString);
    lua_setglobal(lua, "tostring");
    lua_getglobal(lua, LUA_STRLIBNAME);
    lua_getfield(lua, -1, "format");
    lua_pushcclosure(lua, _format, 1);
    lua_setfield(lua, -2, "format");
    const char* blockedPatterns[] = {"find", "match", "gmatch", "gsub", nullptr};
    for (auto name = blockedPatterns; *name; name++) {
        lua_pushnil(lua);
        lua_setfield(lua, -2, *name);
    }
    lua_pop(lua, 1);

    const char* blocked[] = {"io", "os", "package", "debug", "dofile", "loadfile", "load", "pairs", "next", "pcall", "xpcall", "print", "warn", "collectgarbage", "getmetatable", "setmetatable", nullptr};
    for (auto name = blocked; *name; name++) {
        lua_pushnil(lua);
        lua_setglobal(lua, *name);
    }

    luaL_newmetatable(lua, OBJECT_METATABLE);
    lua_pushcfunction(lua, _objectGc);
    lua_setfield(lua, -2, "__gc");
    lua_pushliteral(lua, "protected");
    lua_setfield(lua, -2, "__metatable");
    lua_newtable(lua);
    luaL_setfuncs(lua, OBJECT_METHODS, 0);
    lua_setfield(lua, -2, "__index");
    lua_pop(lua, 1);

    luaL_newmetatable(lua, SPACE_METATABLE);
    lua_pushcfunction(lua, _objectGc);
    lua_setfield(lua, -2, "__gc");
    lua_pushliteral(lua, "tmath.Space");
    lua_setfield(lua, -2, "__name");
    lua_pushliteral(lua, "protected");
    lua_setfield(lua, -2, "__metatable");
    lua_newtable(lua);
    luaL_setfuncs(lua, OBJECT_METHODS, 0);
    lua_pushcfunction(lua, _cellMethod);
    lua_setfield(lua, -2, "cell");
    lua_pushcfunction(lua, _voxel);
    lua_setfield(lua, -2, "voxel");
    lua_setfield(lua, -2, "__index");
    lua_pop(lua, 1);

    luaL_newmetatable(lua, GROUP_METATABLE);
    lua_pushcfunction(lua, _objectGc);
    lua_setfield(lua, -2, "__gc");
    lua_pushliteral(lua, "tmath.Group");
    lua_setfield(lua, -2, "__name");
    lua_pushliteral(lua, "protected");
    lua_setfield(lua, -2, "__metatable");
    lua_newtable(lua);
    luaL_setfuncs(lua, OBJECT_METHODS, 0);
    lua_setfield(lua, -2, "__index");
    lua_pop(lua, 1);

    luaL_newmetatable(lua, SCENE_METATABLE);
    lua_pushcfunction(lua, _sceneGc);
    lua_setfield(lua, -2, "__gc");
    lua_pushliteral(lua, "tmath.Scene");
    lua_setfield(lua, -2, "__name");
    lua_pushliteral(lua, "protected");
    lua_setfield(lua, -2, "__metatable");
    lua_newtable(lua);
    luaL_setfuncs(lua, SCENE_METHODS, 0);
    lua_setfield(lua, -2, "__index");
    lua_pop(lua, 1);

    lua_newtable(lua);
    lua_pushcfunction(lua, _sceneGen);
    lua_setfield(lua, -2, "scene");
    lua_setglobal(lua, "tmath");
    return 0;
}

bool detail::luaAuthoring(lua_State* lua) noexcept
{
    if (!lua) return false;
    void* data = nullptr;
    lua_getallocf(lua, &data);
    auto memory = static_cast<LuaMemory*>(data);
    return memory && memory->authoring;
}

void detail::luaClose(lua_State* lua) noexcept
{
    _close(lua, true);
}

Result detail::luaLoad(const char* source, uint32_t size, const char* name, Scene** output,
                       char* error, uint32_t errorSize, Lua::AssetResolver resolver,
                       void* resolverData, const char* sourcePath, size_t sourceRoot,
                       const Theme* adaptiveTheme, bool* adaptiveThemeUsed,
                       const LuaHookSpan& hooks, lua_State** retained) noexcept
{
    if (output) *output = nullptr;
    if (retained) *retained = nullptr;
    if (adaptiveThemeUsed) *adaptiveThemeUsed = false;
    if (error && errorSize) error[0] = '\0';
    if (!source || !output || (hooks.count && !hooks.data)) {
        _message(error, errorSize, "invalid Lua load arguments");
        return Result::InvalidArguments;
    }
    if (size > LUA_MEMORY_LIMIT) {
        _message(error, errorSize, "Lua source exceeds the 64 MiB limit");
        return Result::ScriptError;
    }

    NumericLocale locale;
    if (!locale.available()) {
        _message(error, errorSize, "could not activate the deterministic numeric locale");
        return Result::NonSupport;
    }

    LuaMemory localMemory;
    auto memory = retained ? new (std::nothrow) LuaMemory : &localMemory;
    if (!memory) {
        _message(error, errorSize, "could not allocate retained Lua memory state");
        return Result::OutOfMemory;
    }
    memory->resolver = resolver;
    memory->resolverData = resolverData;
    memory->sourcePath = sourcePath;
    memory->sourceRoot = sourceRoot;
    if (adaptiveTheme) {
        memory->adaptiveTheme = *adaptiveTheme;
        memory->hasAdaptiveTheme = true;
    }
    auto lua = lua_newstate(_allocate, memory);
    if (!lua) {
        if (retained) delete memory;
        _message(error, errorSize, "could not create Lua state");
        return Result::OutOfMemory;
    }

    lua_pushcfunction(lua, _open);
    if (lua_pcall(lua, 0, 0, 0) != LUA_OK) {
        _message(error, errorSize, lua_tostring(lua, -1));
        _close(lua, retained != nullptr);
        return Result::ScriptError;
    }
    for (auto i = 0u; i < hooks.count; i++) {
        auto hook = hooks.data + i;
        if (!hook->open) continue;
        lua_pushlightuserdata(lua, const_cast<LuaHooks*>(hook));
        lua_pushcclosure(lua, [](lua_State* state) -> int {
            auto active = static_cast<LuaHooks*>(lua_touserdata(state, lua_upvalueindex(1)));
            return active->open(state, active->data);
        }, 1);
        if (lua_pcall(lua, 0, 0, 0) != LUA_OK) {
            _message(error, errorSize, lua_tostring(lua, -1));
            _close(lua, retained != nullptr);
            return Result::ScriptError;
        }
    }

    auto chunk = name && *name ? name : "tmath";
    char* ownedName = nullptr;
    if (*chunk != '@' && *chunk != '=') {
        auto length = std::strlen(chunk);
        ownedName = new (std::nothrow) char[length + 2];
        if (!ownedName) {
            _message(error, errorSize, "out of memory while copying script name");
            _close(lua, retained != nullptr);
            return Result::OutOfMemory;
        }
        ownedName[0] = '@';
        std::memcpy(ownedName + 1, chunk, length + 1);
        chunk = ownedName;
    }

    auto status = luaL_loadbufferx(lua, source, size, chunk, "t");
    delete[] ownedName;
    if (status != LUA_OK) {
        _message(error, errorSize, lua_tostring(lua, -1));
        _close(lua, retained != nullptr);
        return Result::ScriptError;
    }

    lua_sethook(lua, _limit, LUA_MASKCOUNT, LUA_INSTRUCTION_LIMIT);
    status = lua_pcall(lua, 0, 1, 0);
    if (status != LUA_OK) {
        _message(error, errorSize, lua_tostring(lua, -1));
        _close(lua, retained != nullptr);
        return Result::ScriptError;
    }

    auto box = static_cast<LuaScene*>(luaL_testudata(lua, -1, SCENE_METATABLE));
    if (!box || !box->scene || !box->owner) {
        char message[512];
        std::snprintf(message, sizeof(message), "%s: script must return an owning root tmath scene",
                      name && name[0] ? name : "tmath");
        _message(error, errorSize, message);
        _close(lua, retained != nullptr);
        return Result::ScriptError;
    }
    for (auto i = 0u; i < hooks.count; i++) {
        auto hook = hooks.data + i;
        if (!hook->loaded) continue;
        auto result = hook->loaded(lua, box->scene, hook->data);
        if (result != Result::Success) {
            _message(error, errorSize, tmath::result(result));
            _close(lua, retained != nullptr);
            return result;
        }
    }
    *output = box->scene;
    if (adaptiveThemeUsed) *adaptiveThemeUsed = memory->adaptiveThemeUsed;
    _releaseSceneBudget(box);
    box->owner = false;
    if (retained) {
        memory->resolver = nullptr;
        memory->resolverData = nullptr;
        memory->sourcePath = nullptr;
        memory->sourceRoot = 0u;
        memory->authoring = false;
        box->resolver = nullptr;
        box->resolverData = nullptr;
        *retained = lua;
        return Result::Success;
    }
    box->scene = nullptr;
    _close(lua, false);
    return Result::Success;
}

struct FileAssets
{
    const char* path = nullptr;
    size_t root = 0;
    Asset* asset = nullptr;
};

static const Asset* _fileAsset(const char* name, void* data)
{
    auto files = static_cast<FileAssets*>(data);
    delete files->asset;
    files->asset = nullptr;
    auto absolute = name[0] == '/' || name[0] == '\\' || (std::strlen(name) > 2u && name[1] == ':');
    if (absolute || !files->root) {
        AssetLoader::load(name, files->asset);
        return files->asset;
    }
    auto nameSize = std::strlen(name);
    if (files->root > SIZE_MAX - nameSize - 1u) return nullptr;
    auto joined = new (std::nothrow) char[files->root + nameSize + 1u];
    if (!joined) return nullptr;
    std::memcpy(joined, files->path, files->root);
    std::memcpy(joined + files->root, name, nameSize + 1u);
    AssetLoader::load(joined, files->asset);
    delete[] joined;
    return files->asset;
}

Result detail::luaLoadFile(const char* path, Scene** scene, char* error,
                           uint32_t errorSize, const LuaHookSpan& hooks,
                           lua_State** retained) noexcept
{
    if (scene) *scene = nullptr;
    if (error && errorSize) error[0] = '\0';
    if (!path || !scene) {
        _message(error, errorSize, "invalid Lua file arguments");
        return Result::InvalidArguments;
    }

    auto file = std::fopen(path, "rb");
    if (!file) {
        _message(error, errorSize, "could not open Lua file");
        return Result::IoError;
    }
    if (std::fseek(file, 0, SEEK_END) != 0) {
        std::fclose(file);
        _message(error, errorSize, "could not seek Lua file");
        return Result::IoError;
    }
    auto length = std::ftell(file);
    if (length < 0 || static_cast<unsigned long>(length) > LUA_MEMORY_LIMIT || std::fseek(file, 0, SEEK_SET) != 0) {
        std::fclose(file);
        _message(error, errorSize, "Lua file is too large or cannot be read");
        return Result::IoError;
    }

    auto data = new (std::nothrow) char[length ? static_cast<size_t>(length) : 1u];
    if (!data) {
        std::fclose(file);
        _message(error, errorSize, "could not allocate Lua file buffer");
        return Result::OutOfMemory;
    }
    auto read = std::fread(data, 1, static_cast<size_t>(length), file);
    auto close = std::fclose(file);
    if (read != static_cast<size_t>(length) || close != 0) {
        delete[] data;
        _message(error, errorSize, "could not read Lua file");
        return Result::IoError;
    }
    FileAssets assets;
    assets.path = path;
    auto slash = std::strrchr(path, '/');
    auto backslash = std::strrchr(path, '\\');
    if (!slash || (backslash && backslash > slash)) slash = backslash;
    if (slash) assets.root = static_cast<size_t>(slash - path) + 1u;
    auto result = detail::luaLoad(data, static_cast<uint32_t>(length), path, scene,
                                  error, errorSize, _fileAsset, &assets, path,
                                  assets.root, nullptr, nullptr, hooks, retained);
    delete assets.asset;
    delete[] data;
    return result;
}

Result Lua::load(const char* path, Scene** scene, char* error, uint32_t errorSize) noexcept
{
    return detail::luaLoadFile(path, scene, error, errorSize);
}

Result Lua::load(const char* source, uint32_t size, const char* name, Scene** scene,
                 char* error, uint32_t errorSize, AssetResolver resolver,
                 void* resolverData, const Theme* adaptiveTheme,
                 bool* adaptiveThemeUsed) noexcept
{
    return detail::luaLoad(source, size, name, scene, error, errorSize, resolver,
                           resolverData, nullptr, 0, adaptiveTheme,
                           adaptiveThemeUsed);
}

}  // namespace tmath
