g_gizmo_state: TG_GizmoApplicationState;
g_gizmo_context: *TG_GizmoContext_t;

#scope_file 

// Helper function to get a ray from mouse position
get_ray_from_mouse :: (mouse_x: float, mouse_y: float) -> Ray {
    result: Ray;
    
    // Normalize device coordinates
    ndc_x := (2.0 * mouse_x) / g_current_window_width - 1.0;
    ndc_y := 1.0 - (2.0 * mouse_y) / g_current_window_height;  // Flip Y
    
    // Create clip space position
    clip := Vector4.{ndc_x, ndc_y, -1.0, 1.0};
    
    // Convert to view space
    view_matrix_inv := inverse(g_camera.projection_matrix);
    eye_coords := view_matrix_inv * clip;
    eye_coords.z = -1.0;
    eye_coords.w = 0.0;
    
    // Convert to world space
    world_coords := inverse(g_camera.view_matrix) * eye_coords;
    result.direction = normalize(Vector3.{world_coords.x, world_coords.y, world_coords.z});
    
    // Ray origin is camera position
    result.origin = g_camera.position;
    
    return result;
}

Ray :: struct {
    origin: Vector3;
    direction: Vector3;
}

#scope_export

gizmo_update_state :: () {
    // Set up the gizmo application state based on current input state
    g_gizmo_state.viewport_size = .{xx g_current_window_width, xx g_current_window_height};
    g_gizmo_state.mouse_left = is_key_down(.MOUSE_BUTTON_LEFT);

    if is_key_down(.CTRL) {
        g_gizmo_state.hotkey_ctrl = true;
    } else {
        g_gizmo_state.hotkey_ctrl = false;
    }

    // TODO(Oskar): Improve this
    if is_key_pressed(xx #char "T") {
        g_gizmo_state.hotkey_translate = !g_gizmo_state.hotkey_translate;
    }

    if is_key_pressed(xx #char "S") {
        g_gizmo_state.hotkey_scale = !g_gizmo_state.hotkey_scale;
    }

    if is_key_pressed(xx #char "L") {
        g_gizmo_state.hotkey_local = !g_gizmo_state.hotkey_local;
    }

    if is_key_pressed(xx #char "R") {
        g_gizmo_state.hotkey_rotate = !g_gizmo_state.hotkey_rotate;
    }

    // Set camera parameters for the gizmo
    g_gizmo_state.cam.yfov = g_camera.fov;
    g_gizmo_state.cam.near_clip = 0.1;
    g_gizmo_state.cam.far_clip = 1000.0;
    g_gizmo_state.cam.position = .{g_camera.position.x, g_camera.position.y, g_camera.position.z};
    
    // Convert quaternion orientation to the format gizmo expects
    orientation := g_camera.rotation;
    g_gizmo_state.cam.orientation = .{orientation.x, orientation.y, orientation.z, orientation.w};
    
    // Set up ray for gizmo interaction
    mouse_pos_x, mouse_pos_y := get_mouse_pointer_position();
    ray := get_ray_from_mouse(xx mouse_pos_x, xx mouse_pos_y);
    g_gizmo_state.ray_origin = .{ray.origin.x, ray.origin.y, ray.origin.z};
    g_gizmo_state.ray_direction = .{ray.direction.x, ray.direction.y, ray.direction.z};
    
    // Update gizmo context with the current state
    TG_UpdateGizmoContext(g_gizmo_context, *g_gizmo_state);
}

gizmo_render :: () {
    // Create a rigid transform for the light position
    light_transform := TG_CreateRigidTransform();
    defer TG_DestroyRigidTransform(light_transform);
    
    // Set the position of the transform to match our light
    position := TG_Float3.{light_pos.x, light_pos.y, light_pos.z};
    TG_SetRigidTransformPosition(light_transform, *position);
    
    // Make the gizmo manipulate the transform
    if TG_TransformGizmo(g_gizmo_context, "light-position", light_transform) {
        // If the transform was manipulated, update our light position
        TG_GetRigidTransformPosition(light_transform, *position);
        light_pos.x = position.x;
        light_pos.y = position.y;
        light_pos.z = position.z;
    }
    
    // Draw the gizmo
    TG_DrawGizmoContext(g_gizmo_context);
}