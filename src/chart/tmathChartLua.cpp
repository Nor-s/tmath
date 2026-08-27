#include <cmath>
#include <cstring>
#include <new>

extern "C" {
#include <lua.h>
#include <lauxlib.h>
}

#include "tmath_chart.h"
#include "tmathChartLuaExtension.h"

namespace tmath::chart
{

namespace
{

static constexpr const char* CHART_METATABLE = "tmath.chart.Chart";
static constexpr const char* SERIES_METATABLE = "tmath.chart.Series";
static constexpr const char* BUILT_METATABLE = "tmath.chart.Built";

struct LuaChart
{
    Chart* chart = nullptr;
    Scene* scene = nullptr;
    bool built = false;
};

struct LuaSeries
{
    LuaChart* owner = nullptr;
    Series series;
};

struct LuaBuilt
{
    Built* built = nullptr;
    LuaChart* owner = nullptr;
    Group* root = nullptr;
};

static bool _has(lua_State* lua, int index, const char* name)
{
    index = lua_absindex(lua, index);
    lua_getfield(lua, index, name);
    auto found = !lua_isnil(lua, -1);
    lua_pop(lua, 1);
    return found;
}

static void _options(lua_State* lua, int index, const char* kind,
                     const char* const* names)
{
    index = lua_absindex(lua, index);
    lua_pushnil(lua);
    while (lua_next(lua, index)) {
        if (lua_type(lua, -2) != LUA_TSTRING) {
            luaL_error(lua, "%s keys must be strings", kind);
        }
        auto key = lua_tostring(lua, -2);
        auto known = false;
        for (auto cursor = names; *cursor; cursor++) {
            if (std::strcmp(key, *cursor) == 0) {
                known = true;
                break;
            }
        }
        if (!known) luaL_error(lua, "unknown %s field '%s'", kind, key);
        lua_pop(lua, 1);
    }
}

static float _number(lua_State* lua, int index, const char* name)
{
    auto value = static_cast<float>(luaL_checknumber(lua, index));
    if (!std::isfinite(value)) luaL_error(lua, "%s must be finite", name);
    return value;
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

static uint32_t _fieldCount(lua_State* lua, int index, const char* name,
                            uint32_t fallback)
{
    index = lua_absindex(lua, index);
    lua_getfield(lua, index, name);
    if (lua_isnil(lua, -1)) {
        lua_pop(lua, 1);
        return fallback;
    }
    auto value = luaL_checkinteger(lua, -1);
    lua_pop(lua, 1);
    if (value < 0 || static_cast<uint64_t>(value) > UINT32_MAX) {
        luaL_error(lua, "%s is out of range", name);
    }
    return static_cast<uint32_t>(value);
}

static int32_t _fieldIndex(lua_State* lua, int index, const char* name,
                           int32_t fallback)
{
    index = lua_absindex(lua, index);
    lua_getfield(lua, index, name);
    if (lua_isnil(lua, -1)) {
        lua_pop(lua, 1);
        return fallback;
    }
    auto value = luaL_checkinteger(lua, -1);
    lua_pop(lua, 1);
    if (value < INT32_MIN || value > INT32_MAX) luaL_error(lua, "%s is out of range", name);
    return static_cast<int32_t>(value);
}

static bool _fieldBool(lua_State* lua, int index, const char* name, bool fallback)
{
    index = lua_absindex(lua, index);
    lua_getfield(lua, index, name);
    if (lua_isnil(lua, -1)) {
        lua_pop(lua, 1);
        return fallback;
    }
    if (!lua_isboolean(lua, -1)) luaL_error(lua, "%s must be boolean", name);
    auto value = lua_toboolean(lua, -1) != 0;
    lua_pop(lua, 1);
    return value;
}

static const char* _fieldString(lua_State* lua, int index, const char* name,
                                bool required = false)
{
    index = lua_absindex(lua, index);
    lua_getfield(lua, index, name);
    if (lua_isnil(lua, -1)) {
        lua_pop(lua, 1);
        if (required) luaL_error(lua, "missing field '%s'", name);
        return nullptr;
    }
    size_t size = 0u;
    auto value = luaL_checklstring(lua, -1, &size);
    if (!size || std::memchr(value, '\0', size)) luaL_error(lua, "%s must be non-empty text", name);
    lua_pop(lua, 1);
    return value;
}

static Vec2 _vec2(lua_State* lua, int index, const char* name)
{
    luaL_checktype(lua, index, LUA_TTABLE);
    index = lua_absindex(lua, index);
    Vec2 value;
    auto keyed = _has(lua, index, "x") || _has(lua, index, "y");
    if (keyed) {
        static const char* const options[] = {"x", "y", nullptr};
        _options(lua, index, name, options);
        if (!_has(lua, index, "x") || !_has(lua, index, "y")) {
            luaL_error(lua, "%s requires x and y", name);
        }
        lua_getfield(lua, index, "x");
        value.x = _number(lua, -1, name);
        lua_pop(lua, 1);
        lua_getfield(lua, index, "y");
        value.y = _number(lua, -1, name);
        lua_pop(lua, 1);
        return value;
    }
    if (lua_rawlen(lua, index) != 2u) luaL_error(lua, "%s requires two numbers", name);
    lua_rawgeti(lua, index, 1);
    value.x = _number(lua, -1, name);
    lua_pop(lua, 1);
    lua_rawgeti(lua, index, 2);
    value.y = _number(lua, -1, name);
    lua_pop(lua, 1);
    return value;
}

static Vec2 _fieldVec2(lua_State* lua, int index, const char* name,
                       const Vec2& fallback)
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

static Range _range(lua_State* lua, int index, const char* name)
{
    luaL_checktype(lua, index, LUA_TTABLE);
    index = lua_absindex(lua, index);
    Range value;
    auto keyed = _has(lua, index, "min") || _has(lua, index, "max")
                 || _has(lua, index, "step");
    if (keyed) {
        static const char* const options[] = {"min", "max", "step", nullptr};
        _options(lua, index, name, options);
        if (!_has(lua, index, "min") || !_has(lua, index, "max")) {
            luaL_error(lua, "%s requires min and max", name);
        }
        value.min = _fieldNumber(lua, index, "min", 0.0f);
        value.max = _fieldNumber(lua, index, "max", 0.0f);
        value.step = _fieldNumber(lua, index, "step", 1.0f);
    } else {
        auto count = lua_rawlen(lua, index);
        if (count < 2u || count > 3u) luaL_error(lua, "%s requires two or three numbers", name);
        lua_rawgeti(lua, index, 1);
        value.min = _number(lua, -1, name);
        lua_pop(lua, 1);
        lua_rawgeti(lua, index, 2);
        value.max = _number(lua, -1, name);
        lua_pop(lua, 1);
        value.step = 1.0f;
        if (count == 3u) {
            lua_rawgeti(lua, index, 3);
            value.step = _number(lua, -1, name);
            lua_pop(lua, 1);
        }
    }
    if (value.min >= value.max || value.step <= 0.0f) luaL_error(lua, "%s is invalid", name);
    return value;
}

static Range _fieldRange(lua_State* lua, int index, const char* name,
                         const Range& fallback)
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

static Frame _fieldFrame(lua_State* lua, int index)
{
    index = lua_absindex(lua, index);
    lua_getfield(lua, index, "frame");
    luaL_checktype(lua, -1, LUA_TTABLE);
    auto frameIndex = lua_absindex(lua, -1);
    static const char* const options[] = {"center", "size", nullptr};
    _options(lua, frameIndex, "chart frame", options);
    Frame frame;
    frame.center = _fieldVec2(lua, frameIndex, "center", {});
    lua_getfield(lua, frameIndex, "size");
    if (lua_isnil(lua, -1)) luaL_error(lua, "chart frame requires size");
    frame.size = _vec2(lua, -1, "chart frame size");
    lua_pop(lua, 2);
    return frame;
}

static LuaChart* _chart(lua_State* lua, int index = 1)
{
    auto handle = static_cast<LuaChart*>(luaL_checkudata(lua, index, CHART_METATABLE));
    if (!handle->chart) luaL_error(lua, "chart is no longer available");
    if (!detail::luaAuthoring(lua)) {
        luaL_error(lua, "chart authoring is unavailable after loading");
    }
    return handle;
}

static LuaSeries* _series(lua_State* lua, int index, LuaChart* owner)
{
    auto handle = static_cast<LuaSeries*>(luaL_checkudata(lua, index, SERIES_METATABLE));
    if (!handle->owner || handle->owner != owner || !static_cast<bool>(handle->series)) {
        luaL_error(lua, "series belongs to another chart");
    }
    return handle;
}

static LuaBuilt* _built(lua_State* lua)
{
    auto handle = static_cast<LuaBuilt*>(luaL_checkudata(lua, 1, BUILT_METATABLE));
    if (!handle->built || !handle->owner) luaL_error(lua, "built chart is no longer available");
    return handle;
}

static int _chartGc(lua_State* lua)
{
    auto handle = static_cast<LuaChart*>(luaL_checkudata(lua, 1, CHART_METATABLE));
    delete handle->chart;
    handle->chart = nullptr;
    handle->scene = nullptr;
    return 0;
}

static int _builtGc(lua_State* lua)
{
    auto handle = static_cast<LuaBuilt*>(luaL_checkudata(lua, 1, BUILT_METATABLE));
    delete handle->built;
    handle->built = nullptr;
    handle->owner = nullptr;
    handle->root = nullptr;
    return 0;
}

static int _newChart(lua_State* lua)
{
    auto scene = detail::luaScene(lua, 1);
    luaL_checktype(lua, 2, LUA_TTABLE);
    static const char* const options[] = {
        "id", "frame", "x", "y", "x_ticks", "y_ticks", "axes", "grid",
        "ticks", "legend", "padding", "line_width", "bar_gap", nullptr,
    };
    _options(lua, 2, "chart config", options);
    Config config;
    if (_has(lua, 2, "id")) config.id = _fieldString(lua, 2, "id", true);
    if (_has(lua, 2, "frame")) config.frame = _fieldFrame(lua, 2);
    config.x = _fieldRange(lua, 2, "x", config.x);
    config.y = _fieldRange(lua, 2, "y", config.y);
    config.xTicks = _fieldCount(lua, 2, "x_ticks", config.xTicks);
    config.yTicks = _fieldCount(lua, 2, "y_ticks", config.yTicks);
    config.axes = _fieldBool(lua, 2, "axes", config.axes);
    config.grid = _fieldBool(lua, 2, "grid", config.grid);
    config.ticks = _fieldBool(lua, 2, "ticks", config.ticks);
    config.legend = _fieldBool(lua, 2, "legend", config.legend);
    config.padding = _fieldNumber(lua, 2, "padding", config.padding);
    config.lineWidth = _fieldNumber(lua, 2, "line_width", config.lineWidth);
    config.barGap = _fieldNumber(lua, 2, "bar_gap", config.barGap);
    auto chart = Chart::gen(config);
    if (!chart) return luaL_error(lua, "could not create chart: invalid config or out of memory");
    auto handle = new (lua_newuserdatauv(lua, sizeof(LuaChart), 1)) LuaChart;
    handle->chart = chart;
    handle->scene = scene;
    luaL_setmetatable(lua, CHART_METATABLE);
    lua_pushvalue(lua, 1);
    lua_setiuservalue(lua, -2, 1);
    return 1;
}

static int _addSeries(lua_State* lua)
{
    auto owner = _chart(lua);
    if (owner->built) return luaL_error(lua, "chart is already built");
    luaL_checktype(lua, 2, LUA_TTABLE);
    static const char* const options[] = {
        "id", "label", "mark", "data", "color_index", nullptr,
    };
    _options(lua, 2, "chart series", options);
    SeriesSpec spec;
    spec.id = _fieldString(lua, 2, "id", true);
    spec.label = _fieldString(lua, 2, "label");
    spec.colorIndex = _fieldIndex(lua, 2, "color_index", -1);
    if (_has(lua, 2, "mark")) {
        lua_getfield(lua, 2, "mark");
        auto value = luaL_checkstring(lua, -1);
        if (std::strcmp(value, "line") == 0) spec.mark = Mark::Line;
        else if (std::strcmp(value, "bar") == 0) spec.mark = Mark::Bar;
        else return luaL_error(lua, "chart mark must be 'line' or 'bar'");
        lua_pop(lua, 1);
    }
    lua_getfield(lua, 2, "data");
    luaL_checktype(lua, -1, LUA_TTABLE);
    auto dataIndex = lua_absindex(lua, -1);
    auto count = lua_rawlen(lua, dataIndex);
    if (!count || count > Chart::PointLimit) {
        return luaL_error(lua, "chart data must contain between 1 and %u points",
                          Chart::PointLimit);
    }
    auto points = static_cast<Point*>(lua_newuserdatauv(lua, sizeof(Point) * count, 0));
    for (auto i = 0u; i < count; i++) {
        lua_rawgeti(lua, dataIndex, i + 1u);
        auto value = _vec2(lua, -1, "chart point");
        points[i] = {value.x, value.y};
        lua_pop(lua, 1);
    }
    spec.data = points;
    spec.count = static_cast<uint32_t>(count);
    Series series;
    auto result = owner->chart->add(spec, series);
    if (result != Result::Success) {
        return luaL_error(lua, "could not add chart series: %s", tmath::result(result));
    }
    auto handle = static_cast<LuaSeries*>(lua_newuserdatauv(lua, sizeof(LuaSeries), 1));
    handle->owner = owner;
    handle->series = series;
    luaL_setmetatable(lua, SERIES_METATABLE);
    lua_pushvalue(lua, 1);
    lua_setiuservalue(lua, -2, 1);
    return 1;
}

static void _releaseBuilt(void* data) noexcept
{
    static_cast<Built*>(data)->release();
}

static int _build(lua_State* lua)
{
    auto owner = _chart(lua);
    if (owner->built) return luaL_error(lua, "chart is already built");
    Built* built = nullptr;
    auto result = owner->chart->build(owner->scene->theme(), built);
    if (result != Result::Success || !built) {
        delete built;
        return luaL_error(lua, "could not build chart: %s", tmath::result(result));
    }
    auto handle = static_cast<LuaBuilt*>(lua_newuserdatauv(lua, sizeof(LuaBuilt), 2));
    handle->built = built;
    handle->owner = owner;
    handle->root = built->root();
    luaL_setmetatable(lua, BUILT_METATABLE);
    lua_getiuservalue(lua, 1, 1);
    lua_setiuservalue(lua, -2, 1);
    lua_pushvalue(lua, 1);
    lua_setiuservalue(lua, -2, 2);
    auto builtIndex = lua_absindex(lua, -1);
    lua_getiuservalue(lua, builtIndex, 1);
    auto sceneIndex = lua_absindex(lua, -1);
    detail::luaAdoptObject(lua, sceneIndex, handle->root, "chart tree",
                           _releaseBuilt, built);
    owner->built = true;
    lua_settop(lua, builtIndex);
    return 1;
}

static int _push(lua_State* lua, LuaBuilt* handle, Object* object,
                 bool optional = false)
{
    if (!object) {
        if (!optional) return luaL_error(lua, "chart object is unavailable");
        lua_pushnil(lua);
        return 1;
    }
    lua_getiuservalue(lua, 1, 1);
    auto sceneIndex = lua_absindex(lua, -1);
    detail::luaPushObject(lua, sceneIndex, object);
    lua_remove(lua, sceneIndex);
    (void) handle;
    return 1;
}

static int _root(lua_State* lua) { auto value = _built(lua); return _push(lua, value, value->root); }
static int _axes(lua_State* lua) { auto value = _built(lua); return _push(lua, value, value->built->axes()); }
static int _grid(lua_State* lua) { auto value = _built(lua); return _push(lua, value, value->built->grid()); }
static int _labels(lua_State* lua) { auto value = _built(lua); return _push(lua, value, value->built->labels()); }

static int _builtSeries(lua_State* lua)
{
    auto value = _built(lua);
    auto series = _series(lua, 2, value->owner);
    return _push(lua, value, value->built->series(series->series));
}

static int _markCount(lua_State* lua)
{
    auto value = _built(lua);
    auto series = _series(lua, 2, value->owner);
    lua_pushinteger(lua, value->built->markCount(series->series));
    return 1;
}

static int _mark(lua_State* lua)
{
    auto value = _built(lua);
    auto series = _series(lua, 2, value->owner);
    auto index = luaL_checkinteger(lua, 3);
    if (index < 1 || static_cast<uint64_t>(index) > UINT32_MAX) {
        return luaL_error(lua, "chart mark index is out of range");
    }
    return _push(lua, value,
                 value->built->mark(series->series, static_cast<uint32_t>(index - 1)));
}

static int _legend(lua_State* lua)
{
    auto value = _built(lua);
    auto series = _series(lua, 2, value->owner);
    return _push(lua, value, value->built->legend(series->series), true);
}

static int _tickCount(lua_State* lua, bool x)
{
    auto value = _built(lua);
    lua_pushinteger(lua, x ? value->built->xTickCount() : value->built->yTickCount());
    return 1;
}

static int _xTickCount(lua_State* lua) { return _tickCount(lua, true); }
static int _yTickCount(lua_State* lua) { return _tickCount(lua, false); }

static int _tick(lua_State* lua, bool x)
{
    auto value = _built(lua);
    auto index = luaL_checkinteger(lua, 2);
    if (index < 1 || static_cast<uint64_t>(index) > UINT32_MAX) {
        return luaL_error(lua, "chart tick index is out of range");
    }
    auto tick = x ? value->built->xTick(static_cast<uint32_t>(index - 1))
                  : value->built->yTick(static_cast<uint32_t>(index - 1));
    return _push(lua, value, tick);
}

static int _xTick(lua_State* lua) { return _tick(lua, true); }
static int _yTick(lua_State* lua) { return _tick(lua, false); }

static int _open(lua_State* lua, void*)
{
    static const luaL_Reg chartMethods[] = {
        {"series", _addSeries}, {"build", _build}, {nullptr, nullptr},
    };
    static const luaL_Reg builtMethods[] = {
        {"root", _root}, {"axes", _axes}, {"grid", _grid}, {"labels", _labels},
        {"series", _builtSeries}, {"mark_count", _markCount}, {"mark", _mark},
        {"legend", _legend}, {"x_tick_count", _xTickCount},
        {"x_tick", _xTick}, {"y_tick_count", _yTickCount}, {"y_tick", _yTick},
        {nullptr, nullptr},
    };
    luaL_newmetatable(lua, CHART_METATABLE);
    lua_pushcfunction(lua, _chartGc);
    lua_setfield(lua, -2, "__gc");
    lua_pushliteral(lua, "tmath.chart.Chart");
    lua_setfield(lua, -2, "__name");
    lua_pushliteral(lua, "protected");
    lua_setfield(lua, -2, "__metatable");
    lua_newtable(lua);
    luaL_setfuncs(lua, chartMethods, 0);
    lua_setfield(lua, -2, "__index");
    lua_pop(lua, 1);

    luaL_newmetatable(lua, SERIES_METATABLE);
    lua_pushliteral(lua, "tmath.chart.Series");
    lua_setfield(lua, -2, "__name");
    lua_pushliteral(lua, "protected");
    lua_setfield(lua, -2, "__metatable");
    lua_pop(lua, 1);

    luaL_newmetatable(lua, BUILT_METATABLE);
    lua_pushcfunction(lua, _builtGc);
    lua_setfield(lua, -2, "__gc");
    lua_pushliteral(lua, "tmath.chart.Built");
    lua_setfield(lua, -2, "__name");
    lua_pushliteral(lua, "protected");
    lua_setfield(lua, -2, "__metatable");
    lua_newtable(lua);
    luaL_setfuncs(lua, builtMethods, 0);
    lua_setfield(lua, -2, "__index");
    lua_pop(lua, 1);

    lua_getglobal(lua, "tmath");
    lua_pushcfunction(lua, _newChart);
    lua_setfield(lua, -2, "chart");
    lua_pop(lua, 1);
    return 0;
}

}  // namespace

Result Lua::load(const char* source, uint32_t size, const char* name, Scene** scene,
                 char* error, uint32_t errorSize, tmath::Lua::AssetResolver resolver,
                 void* resolverData, const Theme* adaptiveTheme,
                 bool* adaptiveThemeUsed) noexcept
{
    auto hook = lua_extension::luaHooks();
    detail::LuaHookSpan hooks = {&hook, 1u};
    return detail::luaLoad(source, size, name, scene, error, errorSize, resolver,
                           resolverData, nullptr, 0u, adaptiveTheme,
                           adaptiveThemeUsed, hooks);
}

tmath::detail::LuaHooks lua_extension::luaHooks() noexcept
{
    return {_open, nullptr, nullptr};
}

}  // namespace tmath::chart
