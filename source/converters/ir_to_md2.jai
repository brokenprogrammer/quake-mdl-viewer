// IR to MD2 conversion function
convert_ir_to_md2 :: (scene: Scene, output_file: string) -> bool {
    if scene.meshes.count == 0 {
        log("No meshes found in scene", flags=.ERROR);
        return false;
    }

    mesh := scene.meshes[0];
    if mesh.primitives.count == 0 {
        log("No primitives found in mesh", flags=.ERROR);
        return false;
    }

    primitive := mesh.primitives[0];
    
    position_attr := find_attribute(primitive, .POSITION);
    normal_attr := find_attribute(primitive, .NORMAL);
    texcoord_attr := find_attribute(primitive, .TEXCOORD_0);
    
    if !position_attr {
        log("No position attribute found", flags=.ERROR);
        return false;
    }

    vertex_count := position_attr.data.count;
    triangle_count := primitive.indices.count / 3;

    md2_model: MD2Model;

    // Set texture dimensions
    if scene.textures.count > 0 {
        first_texture := scene.textures[0];
        md2_model.skin_width = first_texture.width;
        md2_model.skin_height = first_texture.height;
    } else {
        md2_model.skin_width = 256;
        md2_model.skin_height = 256;
    }

    // Convert skins
    md2_model.skins = NewArray(max(1, scene.textures.count), MD2Skin);
    if scene.textures.count > 0 {
        for texture, i: scene.textures {
            if i >= md2_model.skins.count break;
            name_length := min(texture.name.count, 63);
            memcpy(md2_model.skins[i].name.data, texture.name.data, name_length);
            md2_model.skins[i].name[name_length] = 0;
        }
    } else {
        default_name := "default.pcx";
        memcpy(md2_model.skins[0].name.data, default_name.data, default_name.count);
        md2_model.skins[0].name[default_name.count] = 0;
    }

    // Convert texture coordinates - Direct mapping, no seam re-processing
    md2_model.texcoords = NewArray(vertex_count, MD2TexCoord);
    if texcoord_attr {
        for i: 0..vertex_count-1 {
            uv := texcoord_attr.data[i].vec2_value;
            
            // Convert to MD2 format without additional seam processing
            // The seams have already been handled in the MD2->IR conversion
            md2_model.texcoords[i].s = cast(s16)(uv.x * cast(float32)md2_model.skin_width);
            md2_model.texcoords[i].t = cast(s16)(uv.y * cast(float32)md2_model.skin_height);
        }
    } else {
        for i: 0..vertex_count-1 {
            md2_model.texcoords[i].s = 0;
            md2_model.texcoords[i].t = 0;
        }
    }

    // Convert triangles - Simple 1:1 mapping since we've already expanded vertices
    md2_model.triangles = NewArray(triangle_count, MD2Triangle);
    for i: 0..triangle_count-1 {
        base_index := i * 3;
        
        // Both vertex and texture coordinate indices are the same
        // since we expanded vertices to handle seams
        md2_model.triangles[i].vertex[0] = cast(u16)primitive.indices[base_index];
        md2_model.triangles[i].vertex[1] = cast(u16)primitive.indices[base_index + 1];
        md2_model.triangles[i].vertex[2] = cast(u16)primitive.indices[base_index + 2];
        
        md2_model.triangles[i].texcoord_indice[0] = cast(u16)primitive.indices[base_index];
        md2_model.triangles[i].texcoord_indice[1] = cast(u16)primitive.indices[base_index + 1];
        md2_model.triangles[i].texcoord_indice[2] = cast(u16)primitive.indices[base_index + 2];
    }

    // Convert frames - base frame + morph targets
    total_frames := 1 + mesh.morph_targets.count;
    md2_model.frames = NewArray(total_frames, MD2Frame);
    
    // Convert base frame (frame 0)
    success := convert_frame_to_md2(*md2_model.frames[0], position_attr, normal_attr, vertex_count, "base");
    if !success {
        cleanup_md2_model(*md2_model);
        return false;
    }

    // Convert morph target frames
    for morph_target, morph_index: mesh.morph_targets {
        frame_index := morph_index + 1; // Morph targets start from frame 1
        
        // Find position and normal attributes in morph target
        morph_position_attr := find_morph_attribute(morph_target, .POSITION);
        morph_normal_attr := find_morph_attribute(morph_target, .NORMAL);
        
        if !morph_position_attr {
            log("Morph target % missing position attribute", morph_index, flags=.ERROR);
            cleanup_md2_model(*md2_model);
            return false;
        }
        
        // Use morph target name or generate one
        frame_name := ifx morph_target.name.count > 0 then morph_target.name else tprint("frame_%", frame_index);
        
        success = convert_frame_to_md2(*md2_model.frames[frame_index], morph_position_attr, morph_normal_attr, vertex_count, frame_name);
        if !success {
            cleanup_md2_model(*md2_model);
            return false;
        }
    }

    // Write MD2 file
    success = write_md2_file(md2_model, output_file);
    
    cleanup_md2_model(*md2_model);
    return success;
}

// Helper function to cleanup MD2Model
cleanup_md2_model :: (md2_model: *MD2Model) {
    array_free(md2_model.skins);
    array_free(md2_model.texcoords);
    array_free(md2_model.triangles);
    
    for *frame: md2_model.frames {
        array_free(frame.vertices);
    }
    array_free(md2_model.frames);
}

// Helper function to convert a frame's vertex data to MD2 format
convert_frame_to_md2 :: (frame: *MD2Frame, position_attr: *VertexAttribute, normal_attr: *VertexAttribute, vertex_count: int, frame_name: string) -> bool {
    if position_attr.data.count != vertex_count {
        log("Position attribute vertex count mismatch: expected %, got %", vertex_count, position_attr.data.count, flags=.ERROR);
        return false;
    }

    // Calculate bounding box for scale and translate
    min_pos := Vector3_Float32.{9999.0, 9999.0, 9999.0};
    max_pos := Vector3_Float32.{-9999.0, -9999.0, -9999.0};

    for i: 0..vertex_count-1 {
        pos := position_attr.data[i].vec3_value;
        min_pos.x = min(min_pos.x, pos.x);
        min_pos.y = min(min_pos.y, pos.y);
        min_pos.z = min(min_pos.z, pos.z);
        max_pos.x = max(max_pos.x, pos.x);
        max_pos.y = max(max_pos.y, pos.y);
        max_pos.z = max(max_pos.z, pos.z);
    }

    vec_minus :: (a: Vector3_Float32, b: Vector3_Float32) -> Vector3_Float32 {
        result: Vector3_Float32;
        result.x = a.x - b.x;
        result.y = a.y - b.y;
        result.z = a.z - b.z;
        return result;
    }

    // Calculate scale and translate for compression
    range := vec_minus(max_pos, min_pos);
    frame.scale.x = range.x / 255.0;
    frame.scale.y = range.y / 255.0;
    frame.scale.z = range.z / 255.0;
    frame.translate = min_pos;

    // Handle zero scale (when all vertices have same coordinate)
    if frame.scale.x == 0.0 frame.scale.x = 1.0;
    if frame.scale.y == 0.0 frame.scale.y = 1.0;
    if frame.scale.z == 0.0 frame.scale.z = 1.0;

    // Set frame name
    name_length := min(frame_name.count, 15);
    memcpy(frame.name.data, frame_name.data, name_length);
    frame.name[name_length] = 0; // Null terminate

    // Convert vertices
    frame.vertices = NewArray(vertex_count, MD2Vertex);
    for i: 0..vertex_count-1 {
        pos := position_attr.data[i].vec3_value;
        
        // Compress position to u8 range
        compressed_pos: Vector3_U8;
        compressed_pos.x = cast(u8)((pos.x - frame.translate.x) / frame.scale.x);
        compressed_pos.y = cast(u8)((pos.y - frame.translate.y) / frame.scale.y);
        compressed_pos.z = cast(u8)((pos.z - frame.translate.z) / frame.scale.z);
        
        frame.vertices[i].pos = compressed_pos;
        
        if normal_attr && i < normal_attr.data.count {
            normal_vec := normal_attr.data[i].vec3_value;
            // Find closest normal in MD2 normal table
            frame.vertices[i].normal_index = find_closest_normal_index(normal_vec);
        } else {
            // Default normal index (pointing up)
            frame.vertices[i].normal_index = 0;
        }
    }

    return true;
}

// Helper function to write MD2 file
write_md2_file :: (md2_model: MD2Model, filename: string) -> bool {
    file, success := file_open(filename, true);
    if !success {
        log("Failed to open output file: %", filename, flags=.ERROR);
        return false;
    }
    defer file_close(*file);

    // Calculate header values
    header: MD2Header;
    header.id = .[#char "I", #char "D", #char "P", #char "2"];
    header.version = 8;
    header.texture_width = md2_model.skin_width;
    header.texture_height = md2_model.skin_height;
    header.skin_count = cast(s32)md2_model.skins.count;
    header.vertex_count = cast(s32)md2_model.frames[0].vertices.count;
    header.texture_coordinate_count = cast(s32)md2_model.texcoords.count;
    header.triangle_count = cast(s32)md2_model.triangles.count;
    header.frame_count = cast(s32)md2_model.frames.count; // Now includes all frames!
    header.gl_commands_count = 0; // Not implementing GL commands

    // Calculate frame size
    header.frame_size = cast(s32)(size_of(Vector3_Float32) * 2 + 16 + size_of(MD2Vertex) * header.vertex_count);

    // Calculate offsets
    current_offset := size_of(MD2Header);
    
    header.skin_offset = cast(s32)current_offset;
    current_offset += size_of(MD2Skin) * header.skin_count;
    
    header.texture_coordinate_offset = cast(s32)current_offset;
    current_offset += size_of(MD2TexCoord) * header.texture_coordinate_count;
    
    header.triangle_offset = cast(s32)current_offset;
    current_offset += size_of(MD2Triangle) * header.triangle_count;
    
    header.frame_offset = cast(s32)current_offset;
    current_offset += header.frame_size * header.frame_count;
    
    header.gl_commands_offset = cast(s32)current_offset;
    header.eof_offset = cast(s32)current_offset;

    // Write header
    write_success := file_write(*file, *header, size_of(MD2Header));
    if !write_success {
        log("Failed to write header", flags=.ERROR);
        return false;
    }

    // Write skins
    write_success = file_write(*file, md2_model.skins.data, size_of(MD2Skin) * md2_model.skins.count);
    if !write_success {
        log("Failed to write skins", flags=.ERROR);
        return false;
    }

    // Write texture coordinates
    write_success = file_write(*file, md2_model.texcoords.data, size_of(MD2TexCoord) * md2_model.texcoords.count);
    if !write_success {
        log("Failed to write texture coordinates", flags=.ERROR);
        return false;
    }

    // Write triangles
    write_success = file_write(*file, md2_model.triangles.data, size_of(MD2Triangle) * md2_model.triangles.count);
    if !write_success {
        log("Failed to write triangles", flags=.ERROR);
        return false;
    }

    // Write all frames (base + morph targets)
    for frame: md2_model.frames {
        // Write frame header (scale, translate, name)
        write_success = file_write(*file, *frame.scale, size_of(Vector3_Float32));
        if !write_success {
            log("Failed to write frame scale", flags=.ERROR);
            return false;
        }

        write_success = file_write(*file, *frame.translate, size_of(Vector3_Float32));
        if !write_success {
            log("Failed to write frame translate", flags=.ERROR);
            return false;
        }

        write_success = file_write(*file, frame.name.data, 16);
        if !write_success {
            log("Failed to write frame name", flags=.ERROR);
            return false;
        }

        // Write frame vertices
        write_success = file_write(*file, frame.vertices.data, size_of(MD2Vertex) * frame.vertices.count);
        if !write_success {
            log("Failed to write frame vertices", flags=.ERROR);
            return false;
        }
    }

    log("Successfully wrote MD2 file with % frames", md2_model.frames.count);
    return true;
}