//
// This file was auto-generated using the following command:
//
// jai generate.jai
//



TG_GizmoContext_t :: struct {}
TG_RigidTransform_t :: struct {}
TG_GeometryMesh_t :: struct {}

/**
* Transform mode enum
*/
TG_TransformMode :: enum s32 {
    TRANSLATE :: 0;
    ROTATE    :: 1;
    SCALE     :: 2;

    TG_TRANSFORM_MODE_TRANSLATE :: TRANSLATE;
    TG_TRANSFORM_MODE_ROTATE    :: ROTATE;
    TG_TRANSFORM_MODE_SCALE     :: SCALE;
}

/**
* Vector types
*/
TG_Float2 :: struct {
    x: float;
    y: float;
}

TG_Float3 :: struct {
    x: float;
    y: float;
    z: float;
}

TG_Float4 :: struct {
    x: float;
    y: float;
    z: float;
    w: float;
}

TG_UInt3 :: struct {
    x: u32;
    y: u32;
    z: u32;
}

/**
* Camera parameters
*/
TG_CameraParameters :: struct {
    yfov:        float;
    near_clip:   float;
    far_clip:    float;
    position:    TG_Float3;
    orientation: TG_Float4;
}

/**
* Gizmo application state
*/
TG_GizmoApplicationState :: struct {
    mouse_left:        bool;
    hotkey_translate:  bool;
    hotkey_rotate:     bool;
    hotkey_scale:      bool;
    hotkey_local:      bool;
    hotkey_ctrl:       bool;
    screenspace_scale: float; // If > 0.f, the gizmos are drawn scale-invariant with a screenspace value defined here
    snap_translation:  float; // World-scale units used for snapping translation
    snap_scale:        float; // World-scale units used for snapping scale
    snap_rotation:     float; // Radians used for snapping rotation quaternions (i.e. PI/8 or PI/16)
    viewport_size:     TG_Float2; // 3d viewport used to render the view
    ray_origin:        TG_Float3; // world-space ray origin (i.e. the camera position)
    ray_direction:     TG_Float3; // world-space ray direction
    cam:               TG_CameraParameters; // Used for constructing inverse view projection for raycasting onto gizmo geometry
}

/**
* Geometry vertex structure
*/
TG_GeometryVertex :: struct {
    position: TG_Float3;
    normal:   TG_Float3;
    color:    TG_Float4;
}

/**
* Context creation/destruction
*/
TG_CreateGizmoContext :: () -> *TG_GizmoContext_t #foreign tiny_gizmo;
TG_DestroyGizmoContext :: (ctx: *TG_GizmoContext_t) -> void #foreign tiny_gizmo;

/**
* Context operations
*/
TG_UpdateGizmoContext :: (ctx: *TG_GizmoContext_t, state: *TG_GizmoApplicationState) -> void #foreign tiny_gizmo;
TG_DrawGizmoContext :: (ctx: *TG_GizmoContext_t) -> void #foreign tiny_gizmo;
TG_GetGizmoContextMode :: (ctx: *TG_GizmoContext_t) -> TG_TransformMode #foreign tiny_gizmo;
TG_SetGizmoContextRenderCallback :: (ctx: *TG_GizmoContext_t, callback: #type (mesh: *TG_GeometryMesh_t, user_data: *void) -> void #c_call, user_data: *void) -> void #foreign tiny_gizmo;

/**
* Rigid transform creation/destruction
*/
TG_CreateRigidTransform :: () -> *TG_RigidTransform_t #foreign tiny_gizmo;
TG_CreateRigidTransformWithParams :: (orientation: *TG_Float4, position: *TG_Float3, scale: *TG_Float3) -> *TG_RigidTransform_t #foreign tiny_gizmo;

TG_DestroyRigidTransform :: (transform: *TG_RigidTransform_t) -> void #foreign tiny_gizmo;

/**
* Rigid transform getters/setters
*/
TG_GetRigidTransformPosition :: (transform: *TG_RigidTransform_t, position: *TG_Float3) -> void #foreign tiny_gizmo;
TG_SetRigidTransformPosition :: (transform: *TG_RigidTransform_t, position: *TG_Float3) -> void #foreign tiny_gizmo;

TG_GetRigidTransformOrientation :: (transform: *TG_RigidTransform_t, orientation: *TG_Float4) -> void #foreign tiny_gizmo;
TG_SetRigidTransformOrientation :: (transform: *TG_RigidTransform_t, orientation: *TG_Float4) -> void #foreign tiny_gizmo;

TG_GetRigidTransformScale :: (transform: *TG_RigidTransform_t, scale: *TG_Float3) -> void #foreign tiny_gizmo;
TG_SetRigidTransformScale :: (transform: *TG_RigidTransform_t, scale: *TG_Float3) -> void #foreign tiny_gizmo;
TG_SetRigidTransformUniformScale :: (transform: *TG_RigidTransform_t, scale: float) -> void #foreign tiny_gizmo;

/**
* Transform gizmo manipulation
*/
TG_TransformGizmo :: (ctx: *TG_GizmoContext_t, name: *u8, transform: *TG_RigidTransform_t) -> bool #foreign tiny_gizmo;

/**
* Geometry mesh access
*/
TG_GetGeometryMeshVertexCount :: (mesh: *TG_GeometryMesh_t) -> u32 #foreign tiny_gizmo;
TG_GetGeometryMeshTriangleCount :: (mesh: *TG_GeometryMesh_t) -> u32 #foreign tiny_gizmo;

TG_GetGeometryMeshVertices :: (mesh: *TG_GeometryMesh_t) -> *TG_GeometryVertex #foreign tiny_gizmo;
TG_GetGeometryMeshTriangles :: (mesh: *TG_GeometryMesh_t) -> *TG_UInt3 #foreign tiny_gizmo;

#scope_file


#if OS == .WINDOWS {
    tiny_gizmo :: #library "windows/tiny-gizmo";
} else #if OS == .LINUX {
    tiny_gizmo :: #library "linux/tiny-gizmo";
} else #if OS == .MACOS {
    tiny_gizmo :: #library "macos/tiny-gizmo";
} else #if OS == .ANDROID {
    #if CPU == .X64 {
        tiny_gizmo :: #library "android/x64/tiny-gizmo";
    } else #if CPU == .ARM64 {
        tiny_gizmo :: #library "android/arm64/tiny-gizmo";
    }
} else #if OS == .PS5 {
    tiny_gizmo :: #library "ps5/tiny-gizmo";
} else {
    #assert false;
}

