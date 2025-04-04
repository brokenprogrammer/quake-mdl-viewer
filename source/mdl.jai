MAX_TRIANGLE_COUNT :: 2048;
MAX_VERTEX_COUNT :: 1024;

MDLHeader :: struct {
    id: [4]u8;
    version: s32;
    
    scale: Vector3_Float32;
    translate: Vector3_Float32;
    bounding_radius: float32;
    eye_position: Vector3_Float32;
    
    tex_count: u32;
    tex_width: u32;
    tex_height: u32;

    vertex_count: u32;
    triangle_count: u32;
    frame_count: u32;
    
    sync: s32;
    flags: s32;
    size: float32;
};

MDLTexcoord :: struct {
    seam: u32;
    s: u32;
    t: u32;
};

MDLTriangle :: struct {
    frontface: u32;
    vertex: Vector3_U32;
};

MDLVertex :: struct {
    pos: Vector3_U8;
    normal_index: u8;
};

MDLFrame :: struct {
    bbmin: MDLVertex;
    bbmax: MDLVertex;
    name: [16]u8;
};

MDLFrameAndVertices :: struct {
    frame: MDLFrame;
    vertices: []MDLVertex;
};

MDLImage :: struct {
    data: []u8;
    width: int;
    height: int;
};

MDLModel :: struct {
    images: []MDLImage;

    scale: Vector3_Float32;
    translate: Vector3_Float32;

    texcoords: []MDLTexcoord;
    triangles: []MDLTriangle;
    frames: []MDLFrameAndVertices;
};

// MDLModelAnimation :: struct {
//     name: string;
//     frames: [..]MDLModelFrame;
// };

// MDLModelFrame :: struct {
//     vertices: []Vector3_GLfloat;
//     normals: []Vector3_GLfloat;
// };

// MDLModel :: struct {
//     texture_width: u32;
//     texture_height: u32;
//     texture_data: []u8;

//     texture_coordinates: []Vector2_GLfloat;
//     indices: []Vector3_GLuint;              // Known as triangles before, vertex indices that forms triangles.
//     vertex_count: u32;
//     animations: [..]MDLModelAnimation;
// };

// mdl_get_animation_names :: (mdl_model: MDLModel) -> []string {
//     names: [..]string;
//     array_reserve(*names, mdl_model.animations.count);

//     for 0..mdl_model.animations.count - 1 {
//         array_add(*names, mdl_model.animations[it].name);
//     }

//     return names;
// }

load_mdl_colorpalette :: (file: File, pak_files: []PakFile) -> []Vector3_U8 {
    for pak_files {
        if to_string(it.name.data) == "gfx/palette.lmp" {
            seek_success := file_seek(file, it.offset, .START);
            if !seek_success {
                print("Failed to seek to palette offset\n");
            }        

            color_palette := NewArray(256, Vector3_U8);
            success := file_read(file, color_palette.data, size_of(Vector3_U8) * 256);
            if !success {
                print("Failed to read palette!\n");
            }

            return color_palette;
        }
    }

    return .[];
}

load_mdl_header :: (file: File, pak_file: PakFile) -> bool, MDLHeader {
    mdl_header: MDLHeader;

    seek_success := file_seek(file, pak_file.offset, .START);
    if !seek_success {
        print("Failed to seek to mdl header offset\n");
        return false, mdl_header;
    }

    read_success := file_read(file, *mdl_header, size_of(MDLHeader));
    if !read_success {
        print("Failed to read mdl header!\n");
        return false, mdl_header;
    }

    id_string: string;
    id_string.data = mdl_header.id.data;
    id_string.count = 4; 
    if id_string != "IDPO" {
        print("Bad MDL header id!\n");
        return false, mdl_header;
    }

    if mdl_header.version != 6 {
        print("Bad MDL version\n");
        return false, mdl_header;
    } 

    return true, mdl_header;
}

load_mdl_texture_data :: (file: File, mdl_header: MDLHeader, color_palette: []Vector3_U8) -> []MDLImage {
    images := NewArray(mdl_header.tex_count, MDLImage);

    for imade_index: 0..mdl_header.tex_count - 1 {
        group: u32;
        file_read(file, *group, size_of(u32));

        texture_number_of_channels := 3;
        texture_data_size := mdl_header.tex_width * mdl_header.tex_height; 
        texture_buffer := cast(*u8) alloc(texture_data_size);
        defer free(texture_buffer);
        file_read(file, texture_buffer, texture_data_size);

        // // TODO(Oskar): Cleanup on model unload.
        images[imade_index].data = NewArray(texture_data_size * texture_number_of_channels, u8);
        for 0..texture_data_size - 1 {
            palette_index := texture_buffer[it];
            
            images[imade_index].data[texture_number_of_channels * it + 0] = color_palette[palette_index].x;
            images[imade_index].data[texture_number_of_channels * it + 1] = color_palette[palette_index].y;
            images[imade_index].data[texture_number_of_channels * it + 2] = color_palette[palette_index].z;
        }

        images[imade_index].width = mdl_header.tex_width;
        images[imade_index].height = mdl_header.tex_height;
    }

    return images;
}

load_mdl_texcoords :: (file: File, mdl_header: MDLHeader) -> []MDLTexcoord {
    // mdl_texcoord: [MAX_VERTEX_COUNT]MDLTexcoord;
    texcoords := NewArray(mdl_header.vertex_count, MDLTexcoord);
    file_read(file, texcoords.data, size_of(MDLTexcoord) * mdl_header.vertex_count);

    return texcoords;

    // TODO(Oskar): Move this code into model_create_from_mdl

    // TODO(Oskar): Cleanup on model unload.
    // mdl_model.texture_coordinates = NewArray(mdl_header.vertex_count * 2, Vector2_GLfloat);
    // for 0..mdl_header.vertex_count - 1 {
    //     s := mdl_texcoord[it].s + 0.5;
    //     t := mdl_texcoord[it].t + 0.5;
        
    //     mdl_model.texture_coordinates[it].x = s / mdl_header.tex_width;
    //     mdl_model.texture_coordinates[it].y = t / mdl_header.tex_height;

    //     a := ifx mdl_texcoord[it].seam 0.5 else 0.0;
    //     mdl_model.texture_coordinates[it + mdl_header.vertex_count].x = (s + mdl_header.tex_width * (a)) / mdl_header.tex_width;
    //     mdl_model.texture_coordinates[it + mdl_header.vertex_count].y = t / mdl_header.tex_height;        
    // }
}

load_mdl_triangles :: (file: File, mdl_header: MDLHeader) -> []MDLTriangle {
    // mdl_triangles: [MAX_TRIANGLE_COUNT]MDLTriangle;
    triangles := NewArray(mdl_header.triangle_count, MDLTriangle);
    file_read(file, triangles.data, size_of(MDLTriangle)*mdl_header.triangle_count);
    
    return triangles;

    // TODO(Oskar): Cleanup on model unload.
    // mdl_model.indices = NewArray(mdl_header.triangle_count, Vector3_GLuint);
    // for 0..mdl_header.triangle_count - 1 {
    //     mdl_model.indices[it].x = mdl_triangles[it].vertex.x + (ifx mdl_triangles[it].frontface 0 else mdl_header.vertex_count);
    //     mdl_model.indices[it].y = mdl_triangles[it].vertex.y + (ifx mdl_triangles[it].frontface 0 else mdl_header.vertex_count);
    //     mdl_model.indices[it].z = mdl_triangles[it].vertex.z + (ifx mdl_triangles[it].frontface 0 else mdl_header.vertex_count);
    // }

}

load_mdl_vertices :: (file: File, mdl_header: MDLHeader) ->[]MDLFrameAndVertices {
    // model_frames : [..]MDLModelFrame;
    // model_names : [..]string;

    frames := NewArray(mdl_header.frame_count, MDLFrameAndVertices);
    for frame: 0..mdl_header.frame_count - 1 {
        // mdl_model_frame : MDLModelFrame;
        // // TODO(Oskar): Cleanup on model unload.
        // mdl_model_frame.vertices = NewArray(mdl_header.vertex_count * 2, Vector3_GLfloat);
        // mdl_model_frame.normals = NewArray(mdl_header.vertex_count * 2, Vector3_GLfloat);
        
        group: u32;
        file_read(file, *group, size_of(u32));

        mdl_frame: MDLFrame;
        file_read(file, *mdl_frame, size_of(MDLFrame));

        // model_frame_name := to_string(mdl_frame.name.data);
        // model_frame_name = trim_right(model_frame_name, "0123456789");

        // vertices: [MAX_VERTEX_COUNT]MDLVertex;
        vertices := NewArray(mdl_header.vertex_count, MDLVertex);
        file_read(file, vertices.data, size_of(MDLVertex)*mdl_header.vertex_count);

        frames[frame].frame = mdl_frame;
        frames[frame].vertices = vertices;

        // for k: 0..mdl_header.vertex_count - 1 {
        //     // Front
        //     mdl_model_frame.vertices[k].x = mdl_header.scale.x * vertices[k].pos.x + mdl_header.translate.x;
        //     mdl_model_frame.vertices[k].y = mdl_header.scale.y * vertices[k].pos.y + mdl_header.translate.y;
        //     mdl_model_frame.vertices[k].z = mdl_header.scale.z * vertices[k].pos.z + mdl_header.translate.z;

        //     // Back
        //     mdl_model_frame.vertices[k + mdl_header.vertex_count].x = mdl_model_frame.vertices[k].x; 
        //     mdl_model_frame.vertices[k + mdl_header.vertex_count].y = mdl_model_frame.vertices[k].y; 
        //     mdl_model_frame.vertices[k + mdl_header.vertex_count].z = mdl_model_frame.vertices[k].z; 

        //     // Front, added wraparound because some models seems to have indexes out of boudns..
        //     mdl_model_frame.normals[k].x = anorms_table[vertices[k].normal_index % 162].x;
        //     mdl_model_frame.normals[k].y = anorms_table[vertices[k].normal_index % 162].y;
        //     mdl_model_frame.normals[k].z = anorms_table[vertices[k].normal_index % 162].z;

        //     // Back
        //     mdl_model_frame.normals[k + mdl_header.vertex_count].x = mdl_model_frame.normals[k].x;
        //     mdl_model_frame.normals[k + mdl_header.vertex_count].y = mdl_model_frame.normals[k].y;
        //     mdl_model_frame.normals[k + mdl_header.vertex_count].z = mdl_model_frame.normals[k].z;
        // }

        // TODO(Oskar): Cleanup on model unload?
        // array_add(*model_frames, mdl_model_frame);
        // TODO(Oskar): can we just copy the string somehow and not use sprint?
        // array_add(*model_names, sprint("%", model_frame_name));
        // array_add(*mdl_model.frames, mdl_model_frame); // TODO(Oskar): This is to be removed.
    }

    return frames;

    // for 0..model_frames.count - 1 {
    //     name := model_names[it];

    //     animation_does_exist := false;
    //     animation_index := -1;

    //     for 0..mdl_model.animations.count - 1 {
    //         if equal(mdl_model.animations[it].name, name) {
    //             animation_does_exist = true;
    //             animation_index = it;
    //             break;
    //         }
    //     }

    //     if animation_does_exist {
    //         array_add(*mdl_model.animations[animation_index].frames, model_frames[it]);
    //     }
    // äs    else
    //     {
    //         animation: MDLModelAnimation;
    //         animation.name = name;
    //         array_add(*animation.frames, model_frames[it]);
    //         array_add(*mdl_model.animations, animation);
    //     }
    // }
}

// TODO(Oskar): result error handling, return false if failiure to load properly.
load_mdl :: (file: File, pak_file: PakFile, color_palette: []Vector3_U8) -> MDLModel {
    mdl_model : MDLModel;

    // NOTE(Oskar): Assume that file offset is in right location if this succeeds.
    mdl_header_success, mdl_header := load_mdl_header(file, pak_file);
    if !mdl_header_success {
        print("Failed to read mdl_header!");
        return mdl_model;
    }

    // mdl_model.vertex_count = mdl_header.vertex_count * 2;

    mdl_model.images = load_mdl_texture_data(file, mdl_header, color_palette);

    mdl_model.scale = mdl_header.scale;
    mdl_model.translate = mdl_header.translate;

    mdl_model.texcoords = load_mdl_texcoords(file, mdl_header);
    mdl_model.triangles = load_mdl_triangles(file, mdl_header);
    mdl_model.frames = load_mdl_vertices(file, mdl_header);

    return mdl_model;
}