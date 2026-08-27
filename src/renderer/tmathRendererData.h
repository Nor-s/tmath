#ifndef _TMATH_RENDERER_DATA_H_
#define _TMATH_RENDERER_DATA_H_

#include <new>

#include "tmath.h"

namespace tmath
{

struct LayoutReport::Impl
{
    LayoutScene* scenes = nullptr;
    LayoutObject* objects = nullptr;
    LayoutCollision* collisions = nullptr;
    LayoutContainment* containments = nullptr;
    uint32_t sceneCnt = 0;
    uint32_t sceneCap = 0;
    uint32_t objectCnt = 0;
    uint32_t objectCap = 0;
    uint32_t collisionCnt = 0;
    uint32_t collisionCap = 0;
    uint32_t containmentCnt = 0;
    uint32_t containmentCap = 0;
    float sampleTime = 0.0f;
    float samplePadding = 0.0f;

    ~Impl()
    {
        reset();
        delete[] scenes;
        delete[] objects;
        delete[] collisions;
        delete[] containments;
    }

    void reset()
    {
        for (auto i = 0u; i < sceneCnt; i++)
            delete[] scenes[i].path;
        sceneCnt = 0;
        objectCnt = 0;
        collisionCnt = 0;
        containmentCnt = 0;
        sampleTime = 0.0f;
        samplePadding = 0.0f;
    }

    template<typename T>
    static bool grow(T*& values, uint32_t& capacity, uint32_t count)
    {
        if (count <= capacity) return true;
        auto next = capacity ? capacity * 2u : 16u;
        if (next < capacity || next < count) next = count;
        auto grown = new (std::nothrow) T[next];
        if (!grown) return false;
        for (auto i = 0u; i < capacity; i++)
            grown[i] = values[i];
        delete[] values;
        values = grown;
        capacity = next;
        return true;
    }

    bool add(const LayoutScene& value)
    {
        if (!grow(scenes, sceneCap, sceneCnt + 1u)) return false;
        scenes[sceneCnt++] = value;
        return true;
    }

    bool add(const LayoutObject& value)
    {
        if (!grow(objects, objectCap, objectCnt + 1u)) return false;
        objects[objectCnt++] = value;
        return true;
    }

    bool add(const LayoutCollision& value)
    {
        if (!grow(collisions, collisionCap, collisionCnt + 1u)) return false;
        collisions[collisionCnt++] = value;
        return true;
    }

    bool add(const LayoutContainment& value)
    {
        if (!grow(containments, containmentCap, containmentCnt + 1u)) return false;
        containments[containmentCnt++] = value;
        return true;
    }
};

}  // namespace tmath

#endif
