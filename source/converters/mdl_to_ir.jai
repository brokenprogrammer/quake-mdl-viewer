#scope_file 
// Track unique vertex combinations (position + UV + normal)
VertexKey :: struct {
    vertex_index: u32;
    texcoord_index: u32;
    is_seam_vertex: bool;
    is_back_face: bool;
}

vertexkey_compare :: (a: VertexKey, b: VertexKey) -> bool {
    return a.vertex_index == b.vertex_index && 
           a.texcoord_index == b.texcoord_index && 
           a.is_seam_vertex == b.is_seam_vertex && 
           a.is_back_face == b.is_back_face;
}

vertexkey_get_hash :: (key: VertexKey) -> u32 {
    hash: u32 = 0;
    hash = hash * 31 + key.vertex_index;
    hash = hash * 31 + key.texcoord_index;
    hash = hash * 31 + cast(u32)key.is_seam_vertex;
    hash = hash * 31 + cast(u32)key.is_back_face;
    return hash;
}

#scope_export

// MDL to IR conversion function
convert_mdl_to_ir :: (mdl_model: MDLModel) -> Scene {
    scene: Scene;
    scene.name = "MDL Model";
    scene.metadata.generator = "MDL Converter";
    scene.metadata.up_axis = .Z_UP;
    scene.metadata.handedness = .LEFT_HANDED;
    
    // Create textures and materials (same as before)
    for mdl_image, image_index: mdl_model.images {
        texture := New(Texture);
        texture.name = mdl_image.name;
        texture.embedded_data = array_copy(mdl_image.data);
        texture.width = xx mdl_image.width;
        texture.height = xx mdl_image.height;
        array_add(*scene.textures, texture);
    }
    
    for texture, texture_index: scene.textures {
        material := New(Material);
        material.name = tprint("Material_%", texture_index);
        material.diffuse_texture = texture;
        material.base_color_texture = texture;
        material.ambient_color = .{0.3, 0.3, 0.3};
        material.diffuse_color = .{0.8, 0.8, 0.8};
        material.specular_color = .{0.1, 0.1, 0.1};
        material.shininess = 8.0;
        array_add(*scene.materials, material);
    }
    
    // Create mesh with proper seam handling
    mesh := New(Mesh);
    mesh.name = "MDL Mesh";
    
    // Process first frame to establish vertex structure
    frame_data := mdl_model.frames[0];
    
    vertex_map: Table(VertexKey, u32, vertexkey_get_hash, vertexkey_compare);
    defer deinit(*vertex_map);
    
    expanded_vertices: [..]Vector3_Float32;
    expanded_normals: [..]Vector3_Float32;
    expanded_texcoords: [..]Vector2;
    triangle_indices: [..]u32;
    
    current_vertex_index: u32 = 0;
    
    // Process each triangle and handle seams
    for triangle, tri_idx: mdl_model.triangles {
        is_back_face := triangle.frontface == 0;
        
        triangle_vertex_indices: [3]u32;
        
        triangle_vertices := u32.[triangle.vertex.x, triangle.vertex.y, triangle.vertex.z];

        for corner: 0..2 {
            mdl_vertex_idx := triangle_vertices[corner];
            
            // Check if this vertex has a seam
            has_seam := mdl_model.texcoords[mdl_vertex_idx].seam != 0;
            needs_seam_offset := is_back_face && has_seam;
            
            vertex_key: VertexKey;
            vertex_key.vertex_index = mdl_vertex_idx;
            vertex_key.texcoord_index = mdl_vertex_idx;
            vertex_key.is_seam_vertex = has_seam;
            vertex_key.is_back_face = is_back_face;
            
            // Check if we already have this vertex combination
            existing_index, found := table_find(*vertex_map, vertex_key);
            
            if found {
                triangle_vertex_indices[corner] = existing_index;
            } else {
                // Create new vertex
                mdl_vertex := frame_data.vertices[mdl_vertex_idx];
                
                // Transform position
                pos: Vector3_Float32;
                pos.x = cast(float32)mdl_vertex.pos.x * mdl_model.scale.x + mdl_model.translate.x;
                pos.y = cast(float32)mdl_vertex.pos.y * mdl_model.scale.y + mdl_model.translate.y;
                pos.z = cast(float32)mdl_vertex.pos.z * mdl_model.scale.z + mdl_model.translate.z;
                
                // Get normal
                normal_index := mdl_vertex.normal_index;
                normal: Vector3_Float32;
                if normal_index < anorms_table.count {
                    normal = anorms_table[normal_index];
                } else {
                    normal = .{0, 0, 1};
                }
                
                // Get texture coordinates with seam handling
                texcoord := mdl_model.texcoords[mdl_vertex_idx];
                tex_width := cast(float32)mdl_model.images[0].width;
                tex_height := cast(float32)mdl_model.images[0].height;
                
                u := cast(float32)(texcoord.s + 0.5) / tex_width;
                v := cast(float32)(texcoord.t + 0.5) / tex_height;
                
                // Apply seam offset if needed
                if needs_seam_offset {
                    u += 0.5;
                    if u > 1.0 u -= 1.0; // Wrap around
                }
                
                array_add(*expanded_vertices, pos);
                array_add(*expanded_normals, normal);
                array_add(*expanded_texcoords, Vector2.{u, v});
                
                table_set(*vertex_map, vertex_key, current_vertex_index);
                triangle_vertex_indices[corner] = current_vertex_index;
                current_vertex_index += 1;
            }
        }
        
        // Add triangle indices
        array_add(*triangle_indices, triangle_vertex_indices[0]);
        array_add(*triangle_indices, triangle_vertex_indices[1]);
        array_add(*triangle_indices, triangle_vertex_indices[2]);
    }
    
    // Create primitive with processed data
    primitive: Primitive;
    primitive.topology = .TRIANGLES;
    
    // Create vertex attributes
    position_attr := create_vertex_attribute(.POSITION);
    normal_attr := create_vertex_attribute(.NORMAL);
    texcoord_attr := create_vertex_attribute(.TEXCOORD_0);
    
    for i: 0..expanded_vertices.count-1 {
        add_vec3_to_attribute(*position_attr, expanded_vertices[i]);
        add_vec3_to_attribute(*normal_attr, expanded_normals[i]);
        add_vec2_to_attribute(*texcoord_attr, expanded_texcoords[i]);
    }
    
    array_add(*primitive.attributes, position_attr);
    array_add(*primitive.attributes, normal_attr);
    array_add(*primitive.attributes, texcoord_attr);
    
    primitive.indices = triangle_indices;
    
    if scene.materials.count > 0 {
        primitive.material = scene.materials[0];
    }
    
    array_add(*mesh.primitives, primitive);
    array_add(*scene.meshes, mesh);
    
    // Create root node
    root_node := New(Node);
    root_node.name = "MDL Root";
    root_node.mesh = mesh;
    array_add(*scene.root_nodes, root_node);
    
    // Clean up temporary arrays
    array_free(expanded_vertices);
    array_free(expanded_normals);
    array_free(expanded_texcoords);
    
    return scene;
}

// Alternative version that creates morph targets for animation frames
convert_mdl_to_ir_with_morph_targets :: (mdl_model: MDLModel) -> Scene {
    scene: Scene;
    scene.name = "MDL Model";
    scene.metadata.generator = "MDL Converter with Morph Targets";
    scene.metadata.up_axis = .Z_UP;
    scene.metadata.handedness = .LEFT_HANDED;
    
    // Create textures and materials (same as basic version)
    for mdl_image, image_index: mdl_model.images {
        texture := New(Texture);
        texture.name = mdl_image.name;
        texture.embedded_data = array_copy(mdl_image.data);
        texture.width = xx mdl_image.width;
        texture.height = xx mdl_image.height;
        array_add(*scene.textures, texture);
    }
    
    for texture, texture_index: scene.textures {
        material := New(Material);
        material.name = tprint("Material_%", texture_index);
        material.diffuse_texture = texture;
        material.base_color_texture = texture;
        material.ambient_color = .{0.3, 0.3, 0.3};
        material.diffuse_color = .{0.8, 0.8, 0.8};
        material.specular_color = .{0.1, 0.1, 0.1};
        material.shininess = 8.0;
        array_add(*scene.materials, material);
    }
    
    // Create mesh with morph targets
    mesh := New(Mesh);
    mesh.name = "MDL Mesh with Morph Targets";
    
    if mdl_model.frames.count == 0 {
        array_add(*scene.meshes, mesh);
        return scene;
    }
    
    // Build vertex expansion mapping once - this is crucial!
    vertex_map: Table(VertexKey, u32, vertexkey_get_hash, vertexkey_compare);
    defer deinit(*vertex_map);
    
    // Store the vertex expansion order for morph targets
    vertex_expansion_order: [..]VertexKey;
    defer array_free(vertex_expansion_order);
    
    expanded_vertices: [..]Vector3_Float32;
    expanded_normals: [..]Vector3_Float32;
    expanded_texcoords: [..]Vector2;
    triangle_indices: [..]u32;
    
    current_vertex_index: u32 = 0;
    
    // Process first frame to establish vertex structure
    first_frame_data := mdl_model.frames[0];
    
    // Process each triangle and handle seams - build expansion mapping
    for triangle, tri_idx: mdl_model.triangles {
        is_back_face := triangle.frontface == 0;
        
        triangle_vertex_indices: [3]u32;
        triangle_vertices := u32.[triangle.vertex.x, triangle.vertex.y, triangle.vertex.z];

        for corner: 0..2 {
            mdl_vertex_idx := triangle_vertices[corner];
            
            // Check if this vertex has a seam
            has_seam := mdl_model.texcoords[mdl_vertex_idx].seam != 0;
            needs_seam_offset := is_back_face && has_seam;
            
            vertex_key: VertexKey;
            vertex_key.vertex_index = mdl_vertex_idx;
            vertex_key.texcoord_index = mdl_vertex_idx;
            vertex_key.is_seam_vertex = has_seam;
            vertex_key.is_back_face = is_back_face;
            
            // Check if we already have this vertex combination
            existing_index, found := table_find(*vertex_map, vertex_key);
            
            if found {
                triangle_vertex_indices[corner] = existing_index;
            } else {
                // Store the expansion order for morph targets
                array_add(*vertex_expansion_order, vertex_key);
                
                // Create new vertex from first frame
                mdl_vertex := first_frame_data.vertices[mdl_vertex_idx];
                
                // Transform position
                pos: Vector3_Float32;
                pos.x = cast(float32)mdl_vertex.pos.x * mdl_model.scale.x + mdl_model.translate.x;
                pos.y = cast(float32)mdl_vertex.pos.y * mdl_model.scale.y + mdl_model.translate.y;
                pos.z = cast(float32)mdl_vertex.pos.z * mdl_model.scale.z + mdl_model.translate.z;
                
                // Get normal
                normal_index := mdl_vertex.normal_index;
                normal: Vector3_Float32;
                if normal_index < anorms_table.count {
                    normal = anorms_table[normal_index];
                } else {
                    normal = .{0, 0, 1};
                }
                
                // Get texture coordinates with seam handling
                texcoord := mdl_model.texcoords[mdl_vertex_idx];
                tex_width := cast(float32)mdl_model.images[0].width;
                tex_height := cast(float32)mdl_model.images[0].height;
                
                u := cast(float32)(texcoord.s + 0.5) / tex_width;
                v := cast(float32)(texcoord.t + 0.5) / tex_height;
                
                // Apply seam offset if needed
                if needs_seam_offset {
                    u += 0.5;
                    if u > 1.0 u -= 1.0; // Wrap around
                }
                
                array_add(*expanded_vertices, pos);
                array_add(*expanded_normals, normal);
                array_add(*expanded_texcoords, Vector2.{u, v});
                
                table_set(*vertex_map, vertex_key, current_vertex_index);
                triangle_vertex_indices[corner] = current_vertex_index;
                current_vertex_index += 1;
            }
        }
        
        // Add triangle indices
        array_add(*triangle_indices, triangle_vertex_indices[0]);
        array_add(*triangle_indices, triangle_vertex_indices[1]);
        array_add(*triangle_indices, triangle_vertex_indices[2]);
    }
    
    // Create base primitive
    primitive: Primitive;
    primitive.topology = .TRIANGLES;
    
    // Create vertex attributes
    position_attr := create_vertex_attribute(.POSITION);
    normal_attr := create_vertex_attribute(.NORMAL);
    texcoord_attr := create_vertex_attribute(.TEXCOORD_0);
    
    for i: 0..expanded_vertices.count-1 {
        add_vec3_to_attribute(*position_attr, expanded_vertices[i]);
        add_vec3_to_attribute(*normal_attr, expanded_normals[i]);
        add_vec2_to_attribute(*texcoord_attr, expanded_texcoords[i]);
    }
    
    array_add(*primitive.attributes, position_attr);
    array_add(*primitive.attributes, normal_attr);
    array_add(*primitive.attributes, texcoord_attr);
    
    primitive.indices = triangle_indices;
    
    if scene.materials.count > 0 {
        primitive.material = scene.materials[0];
    }
    
    // Create morph targets for additional frames using the same vertex expansion order
    for frame_data, frame_index: mdl_model.frames {
        if frame_index == 0 continue; // Skip first frame (it's the base)
        
        morph_target: MorphTarget;
        frame_name := to_string(frame_data.frame.name.data);
        morph_target.name = ifx frame_name.count > 0 then frame_name else tprint("Frame_%", frame_index);
        
        // Create position and normal attributes for this morph target
        morph_position_attr := create_vertex_attribute(.POSITION);
        morph_normal_attr := create_vertex_attribute(.NORMAL);
        
        // Use the SAME expansion order as the base mesh
        for expansion_key: vertex_expansion_order {
            mdl_vertex_idx := expansion_key.vertex_index;
            mdl_vertex := frame_data.vertices[mdl_vertex_idx];
            
            // Transform position for this frame
            pos: Vector3_Float32;
            pos.x = cast(float32)mdl_vertex.pos.x * mdl_model.scale.x + mdl_model.translate.x;
            pos.y = cast(float32)mdl_vertex.pos.y * mdl_model.scale.y + mdl_model.translate.y;
            pos.z = cast(float32)mdl_vertex.pos.z * mdl_model.scale.z + mdl_model.translate.z;
            
            // Get normal for this frame
            normal_index := mdl_vertex.normal_index;
            normal: Vector3_Float32;
            if normal_index < anorms_table.count {
                normal = anorms_table[normal_index];
            } else {
                normal = .{0, 0, 1};
            }
            
            add_vec3_to_attribute(*morph_position_attr, pos);
            add_vec3_to_attribute(*morph_normal_attr, normal);
        }
        
        array_add(*morph_target.attributes, morph_position_attr);
        array_add(*morph_target.attributes, morph_normal_attr);
        array_add(*mesh.morph_targets, morph_target);
    }
    
    array_add(*mesh.primitives, primitive);
    array_add(*scene.meshes, mesh);
    
    // Create animation data for morph target weights
    if mdl_model.frames.count > 1 {
        animation := New(Animation);
        animation.name = "MDL Morph Animation";
        animation.duration = cast(float32)(mdl_model.frames.count - 1);
        animation.ticks_per_second = 10.0; // Standard MDL animation speed
        animation.looping = true;
        
        // Create weight channels for each morph target
        for morph_target, target_index: mesh.morph_targets {
            channel: AnimationChannel;
            channel.target_type = .WEIGHTS;
            channel.target_index = cast(s32)target_index;
            channel.custom_target_name = morph_target.name;
            
            // Create keyframes - simple on/off animation
            for frame_idx: 0..mdl_model.frames.count-1 {
                keyframe: Keyframe_Float;
                keyframe.time = cast(float32)frame_idx;
                
                // Weight is 1.0 when this is the active frame, 0.0 otherwise
                if frame_idx == target_index + 1 { // +1 because morph targets start from frame 1
                    keyframe.value = 1.0;
                } else {
                    keyframe.value = 0.0;
                }
                
                keyframe.interpolation = .STEP; // Sharp transitions between frames
                array_add(*channel.float_keyframes, keyframe);
            }
            
            array_add(*animation.channels, channel);
        }
        
        array_add(*scene.animations, animation);
    }
    
    // Create root node
    root_node := New(Node);
    root_node.name = "MDL Root with Morph Targets";
    root_node.mesh = mesh;
    array_add(*scene.root_nodes, root_node);
    
    // Clean up temporary arrays
    array_free(expanded_vertices);
    array_free(expanded_normals);
    array_free(expanded_texcoords);
    
    return scene;
}