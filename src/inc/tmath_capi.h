#ifndef _TMATH_CAPI_H_
#define _TMATH_CAPI_H_

#include <stdint.h>

#if defined(__GNUC__) && !defined(_WIN32)
#define TMATH_API __attribute__((visibility("default")))
#else
#define TMATH_API
#endif

#ifdef __cplusplus
extern "C" {
#endif

typedef void* TMathEngine;
typedef int32_t TMathResult;

enum
{
    TMATH_RESULT_SUCCESS = 0,
    TMATH_RESULT_INVALID_ARGUMENTS = 1,
    TMATH_RESULT_INSUFFICIENT_CONDITION = 2,
    TMATH_RESULT_NON_SUPPORT = 3,
    TMATH_RESULT_OUT_OF_MEMORY = 4,
    TMATH_RESULT_IO_ERROR = 5,
    TMATH_RESULT_SCRIPT_ERROR = 6,
    TMATH_RESULT_UNKNOWN = 7
};

typedef enum TMathRenderEngine
{
    TMATH_RENDER_ENGINE_CPU = 0,
    TMATH_RENDER_ENGINE_GL = 1
} TMathRenderEngine;

typedef enum TMathCameraMode
{
    TMATH_CAMERA_FIXED = 0,
    TMATH_CAMERA_INTERACTIVE = 1
} TMathCameraMode;

typedef enum TMathCameraView
{
    TMATH_CAMERA_VIEW_2D = 0,
    TMATH_CAMERA_VIEW_3D = 1
} TMathCameraView;

typedef enum TMathCameraAction
{
    TMATH_CAMERA_PAN = 0,
    TMATH_CAMERA_ORBIT = 1,
    TMATH_CAMERA_ZOOM = 2,
    TMATH_CAMERA_RESET = 3,
    TMATH_CAMERA_SET_2D = 4,
    TMATH_CAMERA_SET_3D = 5
} TMathCameraAction;

typedef struct TMathBBox
{
    float x;
    float y;
    float width;
    float height;
} TMathBBox;

typedef struct TMathGlTarget
{
    void* display;
    void* surface;
    void* context;
    int32_t id;
    uint32_t width;
    uint32_t height;
} TMathGlTarget;

TMATH_API TMathEngine tmath_create(void);
TMATH_API TMathEngine tmath_create_with_engine(TMathRenderEngine render_engine);
TMATH_API TMathResult tmath_default_render_engine_set(TMathRenderEngine render_engine);
TMATH_API TMathRenderEngine tmath_default_render_engine(void);
TMATH_API uint8_t tmath_render_engine_enabled(TMathRenderEngine render_engine);
TMATH_API TMathRenderEngine tmath_render_engine(TMathEngine engine);
TMATH_API void tmath_destroy(TMathEngine engine);
TMATH_API TMathResult tmath_load_lua(TMathEngine engine, const char* source, uint32_t size, const char* name);
TMATH_API TMathResult tmath_load_font(TMathEngine engine, const char* name, const uint8_t* data, uint32_t size,
                                      const char* mime);
TMATH_API TMathResult tmath_load_asset(TMathEngine engine, const char* name, const uint8_t* data, uint32_t size,
                                       const char* mime);
TMATH_API TMathResult tmath_render(TMathEngine engine, float time);
TMATH_API TMathResult tmath_render_scaled(TMathEngine engine, float time, uint32_t pixel_ratio);
TMATH_API TMathResult tmath_render_gl(TMathEngine engine, float time, const TMathGlTarget* target);
TMATH_API TMathResult tmath_bounds(TMathEngine engine, const char* object, float time, TMathBBox* output);
TMATH_API TMathResult tmath_intersects(TMathEngine engine, const char* first, const char* second, float time,
                                       float padding, uint8_t* output);
TMATH_API TMathResult tmath_layout_report(TMathEngine engine, float time, float padding);
TMATH_API const uint8_t* tmath_layout_report_data(TMathEngine engine);
TMATH_API uint32_t tmath_layout_report_size(TMathEngine engine);
TMATH_API TMathResult tmath_resize(TMathEngine engine, uint32_t width, uint32_t height);
TMATH_API TMathResult tmath_camera(TMathEngine engine, TMathCameraAction action, float x, float y);
TMATH_API TMathCameraMode tmath_camera_mode(TMathEngine engine);
TMATH_API TMathCameraView tmath_camera_view(TMathEngine engine);
TMATH_API const uint8_t* tmath_pixels(TMathEngine engine);
TMATH_API uint32_t tmath_pixels_size(TMathEngine engine);
TMATH_API uint32_t tmath_width(TMathEngine engine);
TMATH_API uint32_t tmath_height(TMathEngine engine);
TMATH_API float tmath_duration(TMathEngine engine);
TMATH_API uint8_t tmath_loop(TMathEngine engine);
TMATH_API const char* tmath_last_error(TMathEngine engine);

#ifdef __cplusplus
}
#endif

#endif
