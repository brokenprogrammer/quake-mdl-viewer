#scope_file
// Track unique vertex combinations (position + UV + normal)
VertexKey :: struct {
    vertex_index: u32;
    texcoord_index: u32;
}

vertexkey_compare :: (a: VertexKey, b: VertexKey) -> bool {
    return a.vertex_index == b.vertex_index && a.texcoord_index == b.texcoord_index;
}

vertexkey_get_hash :: (key: VertexKey) -> u32 {
    hash: u32 = 0;
    hash = hash * 31 + key.vertex_index;
    hash = hash * 31 + key.texcoord_index;
    return hash;
}

#scope_export

// MD2 to IR conversion function
convert_md2_to_ir :: (md2_model: MD2Model) -> Scene {
    scene: Scene;
    scene.name = "MD2 Model";
    scene.metadata.generator = "MD2 Converter";
    scene.metadata.up_axis = .Z_UP;
    scene.metadata.handedness = .LEFT_HANDED;
    
    // Create textures from skins
    for skin, skin_index: md2_model.skins {
        texture := New(Texture);
        skin_name := strip_extension(strip_path(to_string(skin.name.data)));
        texture.name = skin_name;
        texture.width = md2_model.skin_width;
        texture.height = md2_model.skin_height;
        
        // If we have PCX images loaded, use their data
        if skin_index < md2_model.images.count {
            pcx_image := md2_model.images[skin_index];
            // texture.embedded_data = array_copy(pcx_image.data);
            texture.width = xx pcx_image.width;
            texture.height = xx pcx_image.height;
        }
        
        array_add(*scene.textures, texture);
    }
    
    // Create materials for each texture
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
    
    // Create mesh from first frame
    mesh := New(Mesh);
    mesh.name = "MD2 Mesh";
    
    if md2_model.frames.count == 0 {
        log("No frames in MD2 model", flags=.WARNING);
        array_add(*scene.meshes, mesh);
        return scene;
    }
    
    vertex_map: Table(VertexKey, u32, vertexkey_get_hash, vertexkey_compare);
    defer deinit(*vertex_map);
    
    expanded_positions: [..]Vector3_Float32;
    expanded_normals: [..]Vector3_Float32;
    expanded_texcoords: [..]Vector2;
    triangle_indices: [..]u32;
    
    current_vertex_index: u32 = 0;
    first_frame := md2_model.frames[0];
    
    // Process each triangle properly
    for triangle: md2_model.triangles {
        for corner: 0..2 {
            vertex_idx := triangle.vertex[corner];
            texcoord_idx := triangle.texcoord_indice[corner];
            
            key: VertexKey;
            key.vertex_index = cast(u32)vertex_idx;
            key.texcoord_index = cast(u32)texcoord_idx;
            
            // Check if we already have this vertex+texcoord combination
            existing_index, found := table_find(*vertex_map, key);
            
            if found {
                array_add(*triangle_indices, existing_index);
            } else {
                // Create new expanded vertex
                md2_vertex := first_frame.vertices[vertex_idx];
                
                // Decompress position
                pos: Vector3_Float32;
                pos.x = cast(float32)md2_vertex.pos.x * first_frame.scale.x + first_frame.translate.x;
                pos.y = cast(float32)md2_vertex.pos.y * first_frame.scale.y + first_frame.translate.y;
                pos.z = cast(float32)md2_vertex.pos.z * first_frame.scale.z + first_frame.translate.z;
                
                // Get normal
                normal: Vector3_Float32;
                if md2_vertex.normal_index < anorms_table.count {
                    normal = anorms_table[md2_vertex.normal_index];
                } else {
                    normal = .{0, 0, 1};
                }
                
                // Get texture coordinates using the correct index
                texcoord := md2_model.texcoords[texcoord_idx];
                u := cast(float32)texcoord.s / cast(float32)md2_model.skin_width;
                v := cast(float32)texcoord.t / cast(float32)md2_model.skin_height;
                
                array_add(*expanded_positions, pos);
                array_add(*expanded_normals, normal);
                array_add(*expanded_texcoords, Vector2.{u, v});
                
                table_set(*vertex_map, key, current_vertex_index);
                array_add(*triangle_indices, current_vertex_index);
                current_vertex_index += 1;
            }
        }
    }
    
    // Create primitive with expanded data
    primitive: Primitive;
    primitive.topology = .TRIANGLES;
    
    position_attr := create_vertex_attribute(.POSITION);
    normal_attr := create_vertex_attribute(.NORMAL);
    texcoord_attr := create_vertex_attribute(.TEXCOORD_0);
    
    for i: 0..expanded_positions.count-1 {
        add_vec3_to_attribute(*position_attr, expanded_positions[i]);
        add_vec3_to_attribute(*normal_attr, expanded_normals[i]);
        add_vec2_to_attribute(*texcoord_attr, expanded_texcoords[i]);
    }
    
    array_add(*primitive.attributes, position_attr);
    array_add(*primitive.attributes, normal_attr);
    array_add(*primitive.attributes, texcoord_attr);
    
    primitive.indices = triangle_indices;
    
    // Assign material if available
    if scene.materials.count > 0 {
        primitive.material = scene.materials[0];
    }
    
    array_add(*mesh.primitives, primitive);
    array_add(*scene.meshes, mesh);
    
    // Create root node
    root_node := New(Node);
    root_node.name = "MD2 Root";
    root_node.mesh = mesh;
    array_add(*scene.root_nodes, root_node);
    
    return scene;
}

// Alternative version that creates morph targets for animation frames
convert_md2_to_ir_with_morph_targets :: (md2_model: MD2Model) -> Scene {
    scene: Scene;
    scene.name = "MD2 Model";
    scene.metadata.generator = "MD2 Converter with Morph Targets";
    scene.metadata.up_axis = .Z_UP;
    scene.metadata.handedness = .LEFT_HANDED;
    
    // Create textures and materials (same as basic version)
    for skin, skin_index: md2_model.skins {
        texture := New(Texture);
        skin_name := strip_extension(strip_path(to_string(skin.name.data)));
        texture.name = skin_name;
        texture.width = md2_model.skin_width;
        texture.height = md2_model.skin_height;
        
        if skin_index < md2_model.images.count {
            pcx_image := md2_model.images[skin_index];
            texture.width = xx pcx_image.width;
            texture.height = xx pcx_image.height;
        }
        
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
    mesh.name = "MD2 Mesh with Morph Targets";
    
    if md2_model.frames.count == 0 {
        array_add(*scene.meshes, mesh);
        return scene;
    }
    
    // Build vertex expansion mapping once - this is crucial!
    vertex_map: Table(VertexKey, u32, vertexkey_get_hash, vertexkey_compare);
    defer deinit(*vertex_map);
    
    // Store the vertex expansion order for morph targets
    vertex_expansion_order: [..]VertexKey;
    defer array_free(vertex_expansion_order);
    
    expanded_positions: [..]Vector3_Float32;
    expanded_normals: [..]Vector3_Float32;
    expanded_texcoords: [..]Vector2;
    triangle_indices: [..]u32;
    
    current_vertex_index: u32 = 0;
    first_frame := md2_model.frames[0];
    
    // Process triangles and build expansion mapping
    for triangle: md2_model.triangles {
        for corner: 0..2 {
            vertex_idx := triangle.vertex[corner];
            texcoord_idx := triangle.texcoord_indice[corner];
            
            key: VertexKey;
            key.vertex_index = cast(u32)vertex_idx;
            key.texcoord_index = cast(u32)texcoord_idx;
            
            existing_index, found := table_find(*vertex_map, key);
            
            if found {
                array_add(*triangle_indices, existing_index);
            } else {
                // Store the expansion order for morph targets
                array_add(*vertex_expansion_order, key);
                
                md2_vertex := first_frame.vertices[vertex_idx];
                
                // Decompress position
                pos: Vector3_Float32;
                pos.x = cast(float32)md2_vertex.pos.x * first_frame.scale.x + first_frame.translate.x;
                pos.y = cast(float32)md2_vertex.pos.y * first_frame.scale.y + first_frame.translate.y;
                pos.z = cast(float32)md2_vertex.pos.z * first_frame.scale.z + first_frame.translate.z;
                
                // Get normal
                normal: Vector3_Float32;
                if md2_vertex.normal_index < anorms_table.count {
                    normal = anorms_table[md2_vertex.normal_index];
                } else {
                    normal = .{0, 0, 1};
                }
                
                // Get texture coordinates
                texcoord := md2_model.texcoords[texcoord_idx];
                u := cast(float32)texcoord.s / cast(float32)md2_model.skin_width;
                v := cast(float32)texcoord.t / cast(float32)md2_model.skin_height;
                
                array_add(*expanded_positions, pos);
                array_add(*expanded_normals, normal);
                array_add(*expanded_texcoords, Vector2.{u, v});
                
                table_set(*vertex_map, key, current_vertex_index);
                array_add(*triangle_indices, current_vertex_index);
                current_vertex_index += 1;
            }
        }
    }
    
    // Create base primitive
    primitive: Primitive;
    primitive.topology = .TRIANGLES;
    
    position_attr := create_vertex_attribute(.POSITION);
    normal_attr := create_vertex_attribute(.NORMAL);
    texcoord_attr := create_vertex_attribute(.TEXCOORD_0);
    
    for i: 0..expanded_positions.count-1 {
        add_vec3_to_attribute(*position_attr, expanded_positions[i]);
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
    for frame, frame_index: md2_model.frames {
        if frame_index == 0 continue; // Skip first frame (it's the base)
        
        morph_target: MorphTarget;
        frame_name := to_string(frame.name.data);
        morph_target.name = ifx frame_name.count > 0 then frame_name else tprint("Frame_%", frame_index);
        
        // Create position and normal attributes for this morph target
        morph_position_attr := create_vertex_attribute(.POSITION);
        morph_normal_attr := create_vertex_attribute(.NORMAL);
        
        // Use the SAME expansion order as the base mesh
        for expansion_key: vertex_expansion_order {
            vertex_idx := expansion_key.vertex_index;
            md2_vertex := frame.vertices[vertex_idx];
            
            // Decompress position for this frame
            pos: Vector3_Float32;
            pos.x = cast(float32)md2_vertex.pos.x * frame.scale.x + frame.translate.x;
            pos.y = cast(float32)md2_vertex.pos.y * frame.scale.y + frame.translate.y;
            pos.z = cast(float32)md2_vertex.pos.z * frame.scale.z + frame.translate.z;
            
            // Get normal for this frame
            normal: Vector3_Float32;
            if md2_vertex.normal_index < anorms_table.count {
                normal = anorms_table[md2_vertex.normal_index];
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
    if md2_model.frames.count > 1 {
        animation := New(Animation);
        animation.name = "MD2 Morph Animation";
        animation.duration = cast(float32)(md2_model.frames.count - 1);
        animation.ticks_per_second = 10.0; // Standard MD2 animation speed
        animation.looping = true;
        
        // Create weight channels for each morph target
        for morph_target, target_index: mesh.morph_targets {
            channel: AnimationChannel;
            channel.target_type = .WEIGHTS;
            channel.target_index = cast(s32)target_index;
            channel.custom_target_name = morph_target.name;
            
            // Create keyframes - simple on/off animation
            for frame_idx: 0..md2_model.frames.count-1 {
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
    root_node.name = "MD2 Root with Morph Targets";
    root_node.mesh = mesh;
    array_add(*scene.root_nodes, root_node);
    
    return scene;
}