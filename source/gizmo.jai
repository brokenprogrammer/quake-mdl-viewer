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

gizmo_init :: () {
    g_gizmo_context = TG_CreateGizmoContext();
    TG_SetGizmoContextRenderCallback(g_gizmo_context, gizmo_render_callback, null);
}

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
    if is_key_down(xx #char "T") {
        g_gizmo_state.hotkey_translate = true;
    } else {
        g_gizmo_state.hotkey_translate = false;
    }

    if is_key_down(xx #char "S") {
        g_gizmo_state.hotkey_scale = true;
    } else {
        g_gizmo_state.hotkey_scale = false;
    }

    if is_key_down(xx #char "L") {
        g_gizmo_state.hotkey_local = true;
    } else {
        g_gizmo_state.hotkey_local = false;
    }

    if is_key_down(xx #char "R") {
        g_gizmo_state.hotkey_rotate = true;
    } else {
        g_gizmo_state.hotkey_rotate = false;
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

gizmo_render :: (model: Model) {
    // Create a rigid transform for the light position
    // light_transform := TG_CreateRigidTransform();
    // defer TG_DestroyRigidTransform(light_transform);
    
    // Set the position of the transform to match our light
    // position := TG_Float3.{light_pos.x, light_pos.y, light_pos.z};
    // TG_SetRigidTransformPosition(light_transform, *position);
    
    // Make the gizmo manipulate the transform
    if TG_TransformGizmo(g_gizmo_context, "light-position", light_transform) {
        // If the transform was manipulated, update our light position
        // TG_GetRigidTransformPosition(light_transform, *position);
        // light_pos.x = position.x;
        // light_pos.y = position.y;
        // light_pos.z = position.z;
    }

    if model.animations.count > 0 {
        if TG_TransformGizmo(g_gizmo_context, "model-gizmo", model.transform) {
            // TG_GetRigidTransformPosition(model.transform, *position);

            // print("x: %, y: %, z: %\n", position.x, position.y, position.z);
        }
    }
    
    // Draw the gizmo
    TG_DrawGizmoContext(g_gizmo_context);
}

gizmo_render_callback :: (mesh: *TG_GeometryMesh_t, user_data: *void) -> void #c_call {
    if !mesh {
        return;
    }

    vertexCount := TG_GetGeometryMeshVertexCount(mesh);
    triangleCount := TG_GetGeometryMeshTriangleCount(mesh);

    mesh_vertices := TG_GetGeometryMeshVertices(mesh);
    mesh_triangles := TG_GetGeometryMeshTriangles(mesh);

    // Not using instanced rendering here so we need to multiply by 3.
    total_vertices := triangleCount * 3;

    push_context {
        triangle_vertices := cast(*TG_GeometryVertex) alloc(total_vertices * size_of(TG_GeometryVertex));
        defer free(triangle_vertices);

        for 0..triangleCount - 1 {
            triangle := mesh_triangles[it];

            triangle_vertices[it * 3 + 0] = mesh_vertices[triangle.x];
            triangle_vertices[it * 3 + 1] = mesh_vertices[triangle.y];
            triangle_vertices[it * 3 + 2] = mesh_vertices[triangle.z];
        }

        glUseProgram(g_gizmo_shader);

        glBindVertexArray(g_gizmo_vao);
        glBindBuffer (GL_ARRAY_BUFFER, g_gizmo_vbo);
        glBufferData (GL_ARRAY_BUFFER, total_vertices * size_of(TG_GeometryVertex), triangle_vertices, GL_DYNAMIC_DRAW);

        model_matrix := Matrix4_Identity;

        glUniformMatrix4fv(glGetUniformLocation(g_gizmo_shader, "u_View_Projection_Matrix"), 
                          1, GL_TRUE, *g_camera.view_projection_matrix.coef[0][0]);
        glUniformMatrix4fv(glGetUniformLocation(g_gizmo_shader, "u_Model_Matrix"), 
                          1, GL_TRUE, *model_matrix.coef[0][0]);
        camera_position := float32.[g_camera.position.x, g_camera.position.y, g_camera.position.z];
        glUniform3fv(glGetUniformLocation(g_gizmo_shader, "u_eye"), 1, camera_position.data);

        glDrawArrays(GL_TRIANGLES, 0, cast(GLsizei) total_vertices);
        glBindVertexArray(0);
    }  

    // Create temporary buffer for the mesh vertices and triangles
    // push_context {
    //     vertices := cast(*TG_GeometryVertex)alloc(size_of(TG_GeometryVertex) * vertexCount);
    //     defer free(vertices);
    //     triangles := cast(*TG_UInt3)alloc(size_of(TG_UInt3) * triangleCount);
    //     defer free(triangles);
        
    //     // Get vertex and triangle data from the mesh
    //     if vertexCount > 0 {
    //         mesh_vertices := TG_GetGeometryMeshVertices(mesh);
    //         memcpy(vertices, mesh_vertices, vertexCount * size_of(TG_GeometryVertex));
    //     }
        
    //     if triangleCount > 0 {
    //         mesh_triangles := TG_GetGeometryMeshTriangles(mesh);
    //         memcpy(triangles, mesh_triangles, triangleCount * size_of(TG_UInt3));
    //     }
        
    //     // Render the gizmo mesh using lines for simplicity
    //     for 0..triangleCount {
    //         triangle := triangles[it];
    //         v1 := vertices[triangle.x].position;
    //         v2 := vertices[triangle.y].position;
    //         v3 := vertices[triangle.z].position;
            
    //         c1 := vertices[triangle.x].color;
    //         c2 := vertices[triangle.y].color;
    //         c3 := vertices[triangle.z].color;
            
    //         // Convert to Vector3/Vector4 for draw_line
    //         pos1 := Vector3.{v1.x, v1.y, v1.z};
    //         pos2 := Vector3.{v2.x, v2.y, v2.z};
    //         pos3 := Vector3.{v3.x, v3.y, v3.z};
            
    //         color1 := Vector4.{c1.x, c1.y, c1.z, c1.w};
    //         color2 := Vector4.{c2.x, c2.y, c2.z, c2.w};
    //         color3 := Vector4.{c3.x, c3.y, c3.z, c3.w};
            
    //         // Draw the triangle as three lines
    //         draw_line(pos1, pos2, color1, color2);
    //         draw_line(pos2, pos3, color2, color3);
    //         draw_line(pos3, pos1, color3, color1);
    //     }
    // }
}