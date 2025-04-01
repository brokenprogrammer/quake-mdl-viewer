MD2Header :: struct {
    id: [4]u8;
    version: s32;
    
    texture_width: s32;
    texture_height: s32;

    frame_size: s32;

    skin_count: s32;
    vertex_count: s32;
    texture_coordinate_count: s32;
    triangle_count: s32;
    gl_commands_count: s32;
    frame_count: s32;

    skin_offset: s32;
    texture_coordinate_offset: s32;
    triangle_offset: s32;
    frame_offset: s32;
    gl_commands_offset: s32;
    eof_offset: s32;
};

MD2Skin :: struct {
    name: [64]u8;
};

MD2TexCoord :: struct {
    s: s16;
    t: s16;
}

MD2Triangle :: struct {
    vertex: [3]u16;
    texcoord_indice: [3]u16;;
};

MD2Vertex :: struct {
    pos: Vector3_U8;
    normal_index: u8;
}

MD2Frame :: struct {
    scale: Vector3_Float32;
    translate: Vector3_Float32;
    name: [16]u8;
    vertices: []MD2Vertex;
};

// MD2ModelAnimation :: struct {
//     name: string;
//     frames: [..]MD2ModelFrame;
// };

// MD2ModelFrame :: struct {
//     vertices: []Vector3_GLfloat;
//     normals: []Vector3_GLfloat;
// };

// MD2Model :: struct {
//     texture_width: u32;
//     texture_height: u32;
//     texture_data: []u8;

//     texture_coordinates: []Vector2_GLfloat;
//     indices: []Vector3_GLuint;
//     vertex_count: u32;
//     animations: [..]MD2ModelAnimation;
// };

load_md2_header :: (file: File, pak_file: PakFile) -> bool, MD2Header {
    mdl_header: MD2Header;

    seek_success := file_seek(file, pak_file.offset, .START);
    if !seek_success {
        print("Failed to seek to md2 header offset\n");
        return false, mdl_header;
    }

    read_success := file_read(file, *mdl_header, size_of(MD2Header));
    if !read_success {
        print("Failed to read md2 header!\n");
        return false, mdl_header;
    }

    id_string: string;
    id_string.data = mdl_header.id.data;
    id_string.count = 4; 
    if id_string != "IDP2" {
        print("Bad MD2 header id!\n");
        return false, mdl_header;
    }

    if mdl_header.version != 8 {
        print("Bad MD2 version\n");
        return false, mdl_header;
    } 

    return true, mdl_header;
}

load_md2_skins :: (file: File, md2_header: MD2Header) -> []MD2Skin {
    // TODO(Oskar): Seek to skin offset. 

    skins := NewArray(md2_header.skin_count, MD2Skin);
    file_read(file, skins.data, size_of(MD2Skin) * md2_header.skin_count);

    return skins;
}

load_md2_texcoords :: (file: File, md2_header: MD2Header) -> []MD2TexCoord {
    // TODO(Oskar): Seek to texcoords offset. 

    texcoords := NewArray(md2_header.texture_coordinate_count, MD2TexCoord);
    //defer array_free(texcoords);
    file_read(file, texcoords.data, size_of(MD2TexCoord) * md2_header.texture_coordinate_count);

    return texcoords;
}

load_md2_triangles :: (file: File, md2_header: MD2Header) -> []MD2Triangle{
    // TODO(Oskar): Seek to triangles offset. 

    triangles := NewArray(md2_header.triangle_count, MD2Triangle);
    // defer array_free(triangles);
    file_read(file, triangles.data, size_of(MD2Triangle) * md2_header.triangle_count);

    // md2_model.indices = NewArray(md2_header.triangle_count, Vector3_GLuint);
    // md2_model.texture_coordinates = NewArray(md2_header.triangle_count * 3, Vector2_GLfloat);
    // for 0..md2_header.triangle_count - 1 {
    //     md2_model.indices[it].x = triangles[it].vertex.x;
    //     md2_model.indices[it].y = triangles[it].vertex.y;
    //     md2_model.indices[it].z = triangles[it].vertex.z;

    //     // NOTE(Oskar): Loading texture coordinates by index
    //     for j: 0..2 {
    //         tex_idx := triangles[it].texcoord_indice[j];

    //         s := md2_texcoords[tex_idx].s;
    //         t := md2_texcoords[tex_idx].t;

    //         md2_model.texture_coordinates[it * 3 + j].x = cast(GLfloat) s / md2_header.texture_width;
    //         md2_model.texture_coordinates[it * 3 + j].y = cast(GLfloat) t / md2_header.texture_height;
    //     }
    // }

    return triangles;
}

load_md2_vertices :: (file: File, md2_header: MD2Header)  -> []MD2Frame {
    // model_frames : [..]MD2ModelFrame;
    // model_names : [..]string;
    // TODO(Oskar): Seek to triangles offset.

    frames := NewArray(md2_header.frame_count, MD2Frame);

    for frame: 0..md2_header.frame_count - 1 {
        // md2_model_frame: MD2ModelFrame;
        // // TODO(Oskar): Cleanup on model unload.
        // md2_model_frame.vertices = NewArray(md2_header.vertex_count, Vector3_GLfloat);
        // md2_model_frame.normals = NewArray(md2_header.vertex_count, Vector3_GLfloat);

        md2_frame: MD2Frame;
        md2_frame.vertices = NewArray(md2_header.vertex_count, MD2Vertex);
        // defer array_free(md2_frame.vertices);

        file_read(file, *md2_frame.scale, size_of(Vector3_Float32));
        file_read(file, *md2_frame.translate, size_of(Vector3_Float32));
        // TODO(Oskar): Can I get this size from somewhere?
        file_read(file, *md2_frame.name, size_of(u8) * 16);
        file_read(file, md2_frame.vertices.data, size_of(MD2Vertex) * md2_header.vertex_count);

        frames[frame] = md2_frame;

        // model_frame_name := to_string(md2_frame.name.data);
        // model_frame_name = trim_right(model_frame_name, "0123456789");

        // for k: 0..md2_header.vertex_count - 1 {
        //     x := (md2_frame.scale.x * md2_frame.vertices[k].pos.x) + md2_frame.translate.x;
        //     y := (md2_frame.scale.y * md2_frame.vertices[k].pos.y) + md2_frame.translate.y;
        //     z := (md2_frame.scale.z * md2_frame.vertices[k].pos.z) + md2_frame.translate.z;

        //     // md2_model_frame.vertices[k + md2_header.vertex_count].x = md2_model_frame.vertices[k].x;
        //     // md2_model_frame.vertices[k + md2_header.vertex_count].y = md2_model_frame.vertices[k].y;
        //     // md2_model_frame.vertices[k + md2_header.vertex_count].z = md2_model_frame.vertices[k].z;

        //     nx := anorms_table[md2_frame.vertices[k].normal_index].x;
        //     ny := anorms_table[md2_frame.vertices[k].normal_index].y;
        //     nz := anorms_table[md2_frame.vertices[k].normal_index].z;

        //     // md2_model_frame.normals[k + md2_header.vertex_count].x = md2_model_frame.normals[k].x;
        //     // md2_model_frame.normals[k + md2_header.vertex_count].y = md2_model_frame.normals[k].y;
        //     // md2_model_frame.normals[k + md2_header.vertex_count].z = md2_model_frame.normals[k].z;
        // }

        // // TODO(Oskar): Cleanup on model unload?
        // array_add(*model_frames, md2_model_frame);
        // // TODO(Oskar): can we just copy the string somehow and not use sprint?
        // array_add(*model_names, sprint("%", model_frame_name));
    }

    // for 0..model_frames.count - 1 {
    //     name := model_names[it];

    //     animation_does_exist := false;
    //     animation_index := -1;

    //     for 0..md2_model.animations.count - 1 {
    //         if equal(md2_model.animations[it].name, name) {
    //             animation_does_exist = true;
    //             animation_index = it;
    //             break;
    //         }
    //     }

    //     if animation_does_exist {
    //         array_add(*md2_model.animations[animation_index].frames, model_frames[it]);
    //     }
    //     else
    //     {
    //         animation: MD2ModelAnimation;
    //         animation.name = name;
    //         array_add(*animation.frames, model_frames[it]);
    //         array_add(*md2_model.animations, animation);
    //     }
    // }

    return frames;
}

// TODO(Oskar): Result error handling, return false if fail to load.
load_md2 :: (file: File, md2_file: PakFile, pak_files: [] PakFile) -> Model {
    model : Model;

    // NOTE(Oskar): Assume that file offset is in right location if this succeeds.
    md2_header_success, md2_header := load_md2_header(file, md2_file);
    if !md2_header_success {
        print("Failed to read md2_header!");
        return model;
    }


    skins := load_md2_skins(file, md2_header);
    md2_texcoords := load_md2_texcoords(file, md2_header);
    md2_triangles := load_md2_triangles(file, md2_header);
    md2_frames := load_md2_vertices(file, md2_header);

    model.vertex_count = xx (md2_header.triangle_count * 3);
    model.skins = NewArray(md2_header.skin_count, Skin);

    animation_frame: AnimationFrame;
    animation_frame.vertices = NewArray(model.vertex_count, Vector3_GLfloat);
    animation_frame.normals = NewArray(model.vertex_count, Vector3_GLfloat);
    animation_frame.texcoords = NewArray(model.vertex_count, Vector2_GLfloat);

    data_pointer_index := 0;
    for tri: md2_triangles {
        frame := md2_frames[0];
        
        for 0..2 {
            vert0 := frame.scale.x * frame.vertices[tri.vertex[it]].pos.x + frame.translate.x;
            vert1 := frame.scale.y * frame.vertices[tri.vertex[it]].pos.y + frame.translate.y;
            vert2 := frame.scale.z * frame.vertices[tri.vertex[it]].pos.z + frame.translate.z;

            norm0 := anorms_table[frame.vertices[tri.vertex[it]].normal_index % 162].x;
            norm1 := anorms_table[frame.vertices[tri.vertex[it]].normal_index % 162].y;
            norm2 := anorms_table[frame.vertices[tri.vertex[it]].normal_index % 162].z;

            tex0 := cast(GLfloat) md2_texcoords[tri.texcoord_indice[it]].s / md2_header.texture_width;
            tex1 := cast(GLfloat) md2_texcoords[tri.texcoord_indice[it]].t / md2_header.texture_height;
            
            animation_frame.vertices[data_pointer_index + it] = Vector3_GLfloat.{ vert0, vert1, vert2 };
            animation_frame.normals[data_pointer_index + it] = Vector3_GLfloat.{ norm0, norm1, norm2 };
            animation_frame.texcoords[data_pointer_index + it] = Vector2_GLfloat.{ tex0, tex1 };
        }
        data_pointer_index += 3;
    }

    animation: Animation;
    animation.name = "Test";
    array_add(*animation.frames, animation_frame);
    array_add(*model.animations, animation);

    for pak_files {
        file_name := to_string(it.name.data);
        if (contains(file_name, to_string(skins[0].name.data))) {
            seek_success := file_seek(file, it.offset, .START);
            if !seek_success {
                print("Failed to seek to md2 header offset\n");
                return model;
            }

            //TODO(Oskar): Something crazy going on here that makes us crash on some models..
            image, suck := load_pcx(file, it.offset, it.size);
            model.skins[0].skin_width = xx image.width;
            model.skins[0].skin_height = xx image.height;
            model.skins[0].skin_data.data = image.data;
            model.skins[0].skin_data.count = xx image.data_count;

            break;
        }
    }

    return model;
}