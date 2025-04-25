#include "tinygizmo_c.h"
#include "tiny-gizmo.hpp"

#include <string>
#include <memory>
#include <utility>
#include <unordered_map>

/**
 * Wrapper implementation structures
 */
struct TG_RigidTransform_t {
    tinygizmo::rigid_transform transform;
};

struct TG_GeometryMesh_t {
    tinygizmo::geometry_mesh mesh;
};

struct TG_GizmoContext_t {
    tinygizmo::gizmo_context context;
    TG_RenderCallback callback;
    void* user_data;
    std::unordered_map<std::string, bool> gizmo_states;
    
    // Store the last geometry mesh that was rendered
    std::unique_ptr<TG_GeometryMesh_t> last_mesh;
};

/**
 * Helper conversion functions
 */
inline minalg::float2 convert(const TG_Float2& f) {
    return minalg::float2{f.x, f.y};
}

inline minalg::float3 convert(const TG_Float3& f) {
    return minalg::float3{f.x, f.y, f.z};
}

inline minalg::float4 convert(const TG_Float4& f) {
    return minalg::float4{f.x, f.y, f.z, f.w};
}

inline TG_Float2 convert(const minalg::float2& f) {
    return TG_Float2{f.x, f.y};
}

inline TG_Float3 convert(const minalg::float3& f) {
    return TG_Float3{f.x, f.y, f.z};
}

inline TG_Float4 convert(const minalg::float4& f) {
    return TG_Float4{f.x, f.y, f.z, f.w};
}

inline tinygizmo::camera_parameters convert(const TG_CameraParameters& c) {
    tinygizmo::camera_parameters params;
    params.yfov = c.yfov;
    params.near_clip = c.near_clip;
    params.far_clip = c.far_clip;
    params.position = convert(c.position);
    params.orientation = convert(c.orientation);
    return params;
}

inline tinygizmo::gizmo_application_state convert(const TG_GizmoApplicationState& s) {
    tinygizmo::gizmo_application_state state;
    state.mouse_left = s.mouse_left;
    state.hotkey_translate = s.hotkey_translate;
    state.hotkey_rotate = s.hotkey_rotate;
    state.hotkey_scale = s.hotkey_scale;
    state.hotkey_local = s.hotkey_local;
    state.hotkey_ctrl = s.hotkey_ctrl;
    state.screenspace_scale = s.screenspace_scale;
    state.snap_translation = s.snap_translation;
    state.snap_scale = s.snap_scale;
    state.snap_rotation = s.snap_rotation;
    state.viewport_size = convert(s.viewport_size);
    state.ray_origin = convert(s.ray_origin);
    state.ray_direction = convert(s.ray_direction);
    state.cam = convert(s.cam);
    return state;
}

inline TG_TransformMode convert(tinygizmo::transform_mode mode) {
    switch (mode) {
    case tinygizmo::transform_mode::translate:
        return TG_TRANSFORM_MODE_TRANSLATE;
    case tinygizmo::transform_mode::rotate:
        return TG_TRANSFORM_MODE_ROTATE;
    case tinygizmo::transform_mode::scale:
        return TG_TRANSFORM_MODE_SCALE;
    default:
        return TG_TRANSFORM_MODE_TRANSLATE; // Shouldn't reach here
    }
}

/**
 * Implementation of the C API functions
 */

// Context creation/destruction
TG_GizmoContext TG_CreateGizmoContext(void) {
    TG_GizmoContext ctx = new TG_GizmoContext_t();
    
    // Set up the render callback
    ctx->context.render = [ctx](const tinygizmo::geometry_mesh& mesh) {
        if (!ctx->callback) {
            return;
        }
        
        ctx->last_mesh = std::make_unique<TG_GeometryMesh_t>();
        ctx->last_mesh->mesh = mesh;
        
        ctx->callback(ctx->last_mesh.get(), ctx->user_data);
    };
    
    return ctx;
}

void TG_DestroyGizmoContext(TG_GizmoContext ctx) {
    delete ctx;
}

// Context operations
void TG_UpdateGizmoContext(TG_GizmoContext ctx, const TG_GizmoApplicationState* state) {
    ctx->context.update(convert(*state));
}

void TG_DrawGizmoContext(TG_GizmoContext ctx) {
    ctx->context.draw();
}

TG_TransformMode TG_GetGizmoContextMode(TG_GizmoContext ctx) {
    return convert(ctx->context.get_mode());
}

void TG_SetGizmoContextRenderCallback(TG_GizmoContext ctx, TG_RenderCallback callback, void* user_data) {
    ctx->callback = callback;
    ctx->user_data = user_data;
}

// Rigid transform creation/destruction
TG_RigidTransform TG_CreateRigidTransform(void) {
    return new TG_RigidTransform_t();
}

TG_RigidTransform TG_CreateRigidTransformWithParams(const TG_Float4* orientation,
                                                   const TG_Float3* position,
                                                   const TG_Float3* scale) {
    TG_RigidTransform transform = new TG_RigidTransform_t();
    if (orientation) {
        transform->transform.orientation = convert(*orientation);
    }
    if (position) {
        transform->transform.position = convert(*position);
    }
    if (scale) {
        transform->transform.scale = convert(*scale);
    }
    return transform;
}

void TG_DestroyRigidTransform(TG_RigidTransform transform) {
    delete transform;
}

// Rigid transform getters/setters
void TG_GetRigidTransformPosition(TG_RigidTransform transform, TG_Float3* position) {
    *position = convert(transform->transform.position);
}

void TG_SetRigidTransformPosition(TG_RigidTransform transform, const TG_Float3* position) {
    transform->transform.position = convert(*position);
}

void TG_GetRigidTransformOrientation(TG_RigidTransform transform, TG_Float4* orientation) {
    *orientation = convert(transform->transform.orientation);
}

void TG_SetRigidTransformOrientation(TG_RigidTransform transform, const TG_Float4* orientation) {
    transform->transform.orientation = convert(*orientation);
}

void TG_GetRigidTransformScale(TG_RigidTransform transform, TG_Float3* scale) {
    *scale = convert(transform->transform.scale);
}

void TG_SetRigidTransformScale(TG_RigidTransform transform, const TG_Float3* scale) {
    transform->transform.scale = convert(*scale);
}

void TG_SetRigidTransformUniformScale(TG_RigidTransform transform, float scale) {
    transform->transform.scale = minalg::float3(scale, scale, scale);
}

// Transform gizmo manipulation
bool TG_TransformGizmo(TG_GizmoContext ctx, const char* name, TG_RigidTransform transform) {
    return tinygizmo::transform_gizmo(name, ctx->context, transform->transform);
}

// Geometry mesh access
uint32_t TG_GetGeometryMeshVertexCount(TG_GeometryMesh mesh) {
    return static_cast<uint32_t>(mesh->mesh.vertices.size());
}

uint32_t TG_GetGeometryMeshTriangleCount(TG_GeometryMesh mesh) {
    return static_cast<uint32_t>(mesh->mesh.triangles.size());
}

TG_GeometryVertex* TG_GetGeometryMeshVertices(TG_GeometryMesh mesh) {
    if (mesh->mesh.vertices.empty()) {
        return nullptr;
    }
    
    // Assuming that TG_GeometryVertex has the same memory layout as tinygizmo::geometry_vertex
    // This is a bit dangerous, but necessary for an efficient implementation
    static_assert(sizeof(TG_GeometryVertex) == sizeof(tinygizmo::geometry_vertex),
                  "TG_GeometryVertex must have the same size as tinygizmo::geometry_vertex");
                  
    return reinterpret_cast<TG_GeometryVertex*>(mesh->mesh.vertices.data());
}

TG_UInt3* TG_GetGeometryMeshTriangles(TG_GeometryMesh mesh) {
    if (mesh->mesh.triangles.empty()) {
        return nullptr;
    }
    
    // Assuming that TG_UInt3 has the same memory layout as minalg::uint3
    // This is a bit dangerous, but necessary for an efficient implementation
    static_assert(sizeof(TG_UInt3) == sizeof(minalg::uint3),
                  "TG_UInt3 must have the same size as minalg::uint3");
                  
    return reinterpret_cast<TG_UInt3*>(mesh->mesh.triangles.data());
}