/**
 * tiny-gizmo-c.h - C API for tinygizmo
 *
 * This file provides a C-compatible API for the tinygizmo library,
 * which allows it to be used from other languages through FFI.
 */

 #ifndef TINYGIZMO_C_H
 #define TINYGIZMO_C_H
 
 #ifdef __cplusplus
 extern "C" {
 #endif
 
 #ifdef _MSC_VER
 #define DLL_API __declspec(dllexport)
 #else
 #define DLL_API 
 #endif
 
 #include <stdbool.h>
 #include <stdint.h>
 
     /**
      * Opaque handle types
      */
     typedef struct TG_GizmoContext_t* TG_GizmoContext;
     typedef struct TG_RigidTransform_t* TG_RigidTransform;
     typedef struct TG_GeometryMesh_t* TG_GeometryMesh;
 
     /**
      * Transform mode enum
      */
     typedef enum {
         TG_TRANSFORM_MODE_TRANSLATE = 0,
         TG_TRANSFORM_MODE_ROTATE = 1,
         TG_TRANSFORM_MODE_SCALE = 2
     } TG_TransformMode;
 
     /**
      * Vector types
      */
     typedef struct {
         float x, y;
     } TG_Float2;
 
     typedef struct {
         float x, y, z;
     } TG_Float3;
 
     typedef struct {
         float x, y, z, w;
     } TG_Float4;
 
     typedef struct {
         uint32_t x, y, z;
     } TG_UInt3;
 
     /**
      * Camera parameters
      */
     typedef struct {
         float yfov, near_clip, far_clip;
         TG_Float3 position;
         TG_Float4 orientation;
     } TG_CameraParameters;
 
     /**
      * Gizmo application state
      */
     typedef struct {
         bool mouse_left;
         bool hotkey_translate;
         bool hotkey_rotate;
         bool hotkey_scale;
         bool hotkey_local;
         bool hotkey_ctrl;
         float screenspace_scale;  // If > 0.f, the gizmos are drawn scale-invariant with a screenspace value defined here
         float snap_translation;   // World-scale units used for snapping translation
         float snap_scale;         // World-scale units used for snapping scale
         float snap_rotation;      // Radians used for snapping rotation quaternions (i.e. PI/8 or PI/16)
         TG_Float2 viewport_size;  // 3d viewport used to render the view
         TG_Float3 ray_origin;     // world-space ray origin (i.e. the camera position)
         TG_Float3 ray_direction;  // world-space ray direction
         TG_CameraParameters cam;  // Used for constructing inverse view projection for raycasting onto gizmo geometry
     } TG_GizmoApplicationState;
 
     /**
      * Geometry vertex structure
      */
     typedef struct {
         TG_Float3 position;
         TG_Float3 normal;
         TG_Float4 color;
     } TG_GeometryVertex;
 
     /**
      * Callback type for rendering geometry
      */
     typedef void (*TG_RenderCallback)(TG_GeometryMesh mesh, void* user_data);
 
     /**
      * Context creation/destruction
      */
     DLL_API TG_GizmoContext TG_CreateGizmoContext(void);
     DLL_API void TG_DestroyGizmoContext(TG_GizmoContext ctx);
 
     /**
      * Context operations
      */
     DLL_API void TG_UpdateGizmoContext(TG_GizmoContext ctx, const TG_GizmoApplicationState* state);
     DLL_API void TG_DrawGizmoContext(TG_GizmoContext ctx);
     DLL_API TG_TransformMode TG_GetGizmoContextMode(TG_GizmoContext ctx);
     DLL_API void TG_SetGizmoContextRenderCallback(TG_GizmoContext ctx, TG_RenderCallback callback, void* user_data);
 
     /**
      * Rigid transform creation/destruction
      */
     DLL_API TG_RigidTransform TG_CreateRigidTransform(void);
     DLL_API TG_RigidTransform TG_CreateRigidTransformWithParams(const TG_Float4* orientation,
         const TG_Float3* position,
         const TG_Float3* scale);
     DLL_API void TG_DestroyRigidTransform(TG_RigidTransform transform);
 
     /**
      * Rigid transform getters/setters
      */
     DLL_API void TG_GetRigidTransformPosition(TG_RigidTransform transform, TG_Float3* position);
     DLL_API void TG_SetRigidTransformPosition(TG_RigidTransform transform, const TG_Float3* position);
 
     DLL_API void TG_GetRigidTransformOrientation(TG_RigidTransform transform, TG_Float4* orientation);
     DLL_API void TG_SetRigidTransformOrientation(TG_RigidTransform transform, const TG_Float4* orientation);
 
     DLL_API void TG_GetRigidTransformScale(TG_RigidTransform transform, TG_Float3* scale);
     DLL_API void TG_SetRigidTransformScale(TG_RigidTransform transform, const TG_Float3* scale);
     DLL_API void TG_SetRigidTransformUniformScale(TG_RigidTransform transform, float scale);
 
     /**
      * Transform gizmo manipulation
      */
     DLL_API bool TG_TransformGizmo(TG_GizmoContext ctx, const char* name, TG_RigidTransform transform);
 
     /**
      * Geometry mesh access
      */
     DLL_API uint32_t TG_GetGeometryMeshVertexCount(TG_GeometryMesh mesh);
     DLL_API uint32_t TG_GetGeometryMeshTriangleCount(TG_GeometryMesh mesh);
 
     DLL_API TG_GeometryVertex* TG_GetGeometryMeshVertices(TG_GeometryMesh mesh);
     DLL_API TG_UInt3* TG_GetGeometryMeshTriangles(TG_GeometryMesh mesh);
 
 #ifdef __cplusplus
 }  // extern "C"
 #endif
 
 #endif  // TINYGIZMO_C_H