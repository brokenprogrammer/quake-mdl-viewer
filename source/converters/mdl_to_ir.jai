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