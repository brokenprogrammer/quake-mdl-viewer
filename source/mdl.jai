#scope_file

#load "mdl_color_palette.jai";
mdl_color_palette: []Vector3_U8;
mdl_color_palette_initialized := false;

TEXTURE_TYPE_SINGLE :: 0;
FRAME_TYPE_SIMPLE :: 0;

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
    name: string;
    data: []u8;
    width: int;
    height: int;
};

mdl_cleanup_textures :: (textures: []MDLImage) {
    for textures {
        array_free(it.data);
    }

    array_free(textures);
}

mdl_cleanup_frames_and_vertices :: (frames_and_vertices: []MDLFrameAndVertices) {
    for frames_and_vertices {
        array_free(it.vertices);
    }

    array_free(frames_and_vertices);
}

load_mdl_colorpalette :: (pak_files: []PakFile) -> []Vector3_U8 {
    for pak_files {
        if to_string(it.name.data) == "gfx/palette.lmp" {
            seek_success := file_seek(it.file, it.offset, .START);
            if !seek_success {
                log("Failed to seek to palette offset.", flags=.WARNING);
                return default_mdl_color_palette;
            }        

            color_palette := NewArray(256, Vector3_U8);
            read_success := file_read(it.file, color_palette.data, size_of(Vector3_U8) * 256);
            if !read_success {
                log("Failed to read palette data.", flags=.WARNING);
                return default_mdl_color_palette;
            }

            return color_palette;
        }
    }

    return default_mdl_color_palette;
}

load_mdl_header :: (mdl_file: File) -> MDLHeader, bool {
    mdl_header: MDLHeader;

    read_success := file_read(mdl_file, *mdl_header, size_of(MDLHeader));
    if !read_success {
        log("Failed to read header from file.", flags=.ERROR);
        return .{}, false;
    }

    id_string: string;
    id_string.data = mdl_header.id.data;
    id_string.count = 4; 
    if id_string != "IDPO" {
        log("Invalid header.", flags=.ERROR);
        return .{}, false;
    }

    if mdl_header.version != 6 {
        log("Unsupported file version.", flags=.ERROR);
        return .{}, false;
    } 

    return mdl_header, true;
}

load_mdl_header :: (pak_file: PakFile) -> MDLHeader, bool {
    seek_success := file_seek(pak_file.file, pak_file.offset, .START);
    if !seek_success {
        log("Failed to seek to header offset.", flags=.ERROR);
        return .{}, false;
    }

    mdl_header, load_header_result := load_mdl_header(pak_file.file);
    return mdl_header, load_header_result;
}

load_mdl_texture_data :: (mdl_file: File, mdl_header: MDLHeader, color_palette: []Vector3_U8) -> []MDLImage, bool {
    images := NewArray(mdl_header.tex_count, MDLImage);

    for imade_index: 0..mdl_header.tex_count - 1 {
        group: u32;
        read_result := file_read(mdl_file, *group, size_of(u32));
        if !read_result {
            log("Failed to read texture group value.", flags=.ERROR);
            mdl_cleanup_textures(images);
            return images, false;
        }

        if group != TEXTURE_TYPE_SINGLE {
            log("Unsupported texture group type, this application currently only supports single textures.", flags=.ERROR);
            mdl_cleanup_textures(images);
            return images, false;
        }

        texture_number_of_channels := 3;
        texture_data_size := mdl_header.tex_width * mdl_header.tex_height; 
        texture_buffer := cast(*u8) alloc(texture_data_size);
        defer free(texture_buffer);
        
        read_result = file_read(mdl_file, texture_buffer, texture_data_size);
        if !read_result {
            log("Failed to read texture data.", flags=.ERROR);
            mdl_cleanup_textures(images);
            return images, false;
        }

        // TODO(Oskar): Cleanup on model unload.
        images[imade_index].data = NewArray(texture_data_size * texture_number_of_channels, u8);
        for 0..texture_data_size - 1 {
            palette_index := texture_buffer[it];
            
            images[imade_index].data[texture_number_of_channels * it + 0] = color_palette[palette_index].x;
            images[imade_index].data[texture_number_of_channels * it + 1] = color_palette[palette_index].y;
            images[imade_index].data[texture_number_of_channels * it + 2] = color_palette[palette_index].z;
        }

        images[imade_index].name = tprint("Skin %", imade_index);
        images[imade_index].width = mdl_header.tex_width;
        images[imade_index].height = mdl_header.tex_height;
    }

    return images, true;
}

load_mdl_texture_data :: (pak_file: PakFile, mdl_header: MDLHeader, color_palette: []Vector3_U8) -> []MDLImage, bool {
    images, load_textures_result := load_mdl_texture_data(pak_file.file, mdl_header, color_palette);
    return images, load_textures_result;
}

load_mdl_texcoords :: (mdl_file: File, mdl_header: MDLHeader) -> []MDLTexcoord, bool {
    texcoords := NewArray(mdl_header.vertex_count, MDLTexcoord);
    
    read_result := file_read(mdl_file, texcoords.data, size_of(MDLTexcoord) * mdl_header.vertex_count);
    if !read_result {
        log("Failed to read texcoords.", flags=.ERROR);
        array_free(texcoords);
        return .[], false;
    }

    return texcoords, true;
}

load_mdl_texcoords :: (pak_file: PakFile, mdl_header: MDLHeader) -> []MDLTexcoord, bool {
    texcoords, load_texcoords_result := load_mdl_texcoords(pak_file.file, mdl_header);
    return texcoords, load_texcoords_result;
}

load_mdl_triangles :: (mdl_file: File, mdl_header: MDLHeader) -> []MDLTriangle, bool {
    triangles := NewArray(mdl_header.triangle_count, MDLTriangle);
    
    read_result := file_read(mdl_file, triangles.data, size_of(MDLTriangle)*mdl_header.triangle_count);
    if !read_result {
        log("Failed to read triangles.", flags=.ERROR);
        array_free(triangles);
        return .[], false;
    }

    return triangles, true;
}

load_mdl_triangles :: (pak_file: PakFile, mdl_header: MDLHeader) -> []MDLTriangle, bool {
    triangles, load_triangles_result := load_mdl_triangles(pak_file.file, mdl_header);
    return triangles, load_triangles_result;
}

load_mdl_frames :: (mdl_file: File, mdl_header: MDLHeader) ->[]MDLFrameAndVertices, bool {
    frames := NewArray(mdl_header.frame_count, MDLFrameAndVertices);
    for frame: 0..mdl_header.frame_count - 1 {
        group: u32;
        read_result := file_read(mdl_file, *group, size_of(u32));
        if !read_result {
            log("Failed to read group type.", flags=.ERROR);
            mdl_cleanup_frames_and_vertices(frames);
            return .[], false;
        }

        if group != FRAME_TYPE_SIMPLE {
            log("Unsupported frame group type, this application currently only supports simple frames.", flags=.ERROR);
            mdl_cleanup_frames_and_vertices(frames);
            return .[], false;
        }

        mdl_frame: MDLFrame;
        read_result = file_read(mdl_file, *mdl_frame, size_of(MDLFrame));
        if !read_result {
            log("Failed to read frame data.", flags=.ERROR);
            mdl_cleanup_frames_and_vertices(frames);
            return .[], false;
        }

        vertices := NewArray(mdl_header.vertex_count, MDLVertex);
        read_result = file_read(mdl_file, vertices.data, size_of(MDLVertex)*mdl_header.vertex_count);
        if !read_result {
            log("Failed to read frame vertices.", flags=.ERROR);
            mdl_cleanup_frames_and_vertices(frames);
            return .[], false;
        }

        frames[frame].frame = mdl_frame;
        frames[frame].vertices = vertices;
    }

    return frames, true;
}

load_mdl_frames :: (pak_file: PakFile, mdl_header: MDLHeader) ->[]MDLFrameAndVertices, bool {
    frames, load_frames_result := load_mdl_frames(pak_file.file, mdl_header);
    return frames, load_frames_result;
}

#scope_export

MDLModel :: struct {
    images: []MDLImage;

    scale: Vector3_Float32;
    translate: Vector3_Float32;

    texcoords: []MDLTexcoord;
    triangles: []MDLTriangle;
    frames: []MDLFrameAndVertices;
};

load_mdl :: (mdl_file: File) -> MDLModel, bool {
    md2_logger_data := project_setup_logger("[MDL Loader]");
    defer project_cleanup_logger(md2_logger_data);

    mdl_header, mdl_header_success := load_mdl_header(mdl_file);
    if !mdl_header_success {
        return .{}, false;
    }

    color_palette := default_mdl_color_palette;
    if mdl_color_palette_initialized {
        color_palette = mdl_color_palette;
    }

    mdl_model : MDLModel;
    mdl_model.scale = mdl_header.scale;
    mdl_model.translate = mdl_header.translate;

    // TODO(Oskar): Rename images to textures
    load_textures_success: bool;
    mdl_model.images, load_textures_success  = load_mdl_texture_data(mdl_file, mdl_header, color_palette);
    if !load_textures_success {
        return .{}, false;
    }

    load_texcoords_success: bool;
    mdl_model.texcoords, load_texcoords_success = load_mdl_texcoords(mdl_file, mdl_header);
    if !load_texcoords_success {
        mdl_cleanup_textures(mdl_model.images);
        return .{}, false;
    }

    load_triangles_success: bool;
    mdl_model.triangles, load_triangles_success = load_mdl_triangles(mdl_file, mdl_header);
    if !load_triangles_success {
        mdl_cleanup_textures(mdl_model.images);
        array_free(mdl_model.texcoords);
        return .{}, false;
    }

    load_frames_success: bool;
    mdl_model.frames, load_frames_success = load_mdl_frames(mdl_file, mdl_header);
    if !load_frames_success {
        mdl_cleanup_textures(mdl_model.images);
        array_free(mdl_model.texcoords);
        array_free(mdl_model.triangles);
        return .{}, false;
    }

    return mdl_model, true;
}

load_mdl :: (pak_file: PakFile, pak_files: []PakFile) -> MDLModel, bool {
    md2_logger_data := project_setup_logger("[MDL Loader]");
    defer project_cleanup_logger(md2_logger_data);    

    // NOTE(Oskar): Assume that file offset is in right location if this succeeds.
    mdl_header, mdl_header_success := load_mdl_header(pak_file);
    if !mdl_header_success {
        return .{}, false;
    }

    if !mdl_color_palette_initialized {
        mdl_color_palette_initialized = true;
        mdl_color_palette = load_mdl_colorpalette(pak_files);
    }

    mdl_model : MDLModel;
    mdl_model.scale = mdl_header.scale;
    mdl_model.translate = mdl_header.translate;

    // TODO(Oskar): Rename images to textures
    load_textures_success: bool;
    mdl_model.images, load_textures_success  = load_mdl_texture_data(pak_file, mdl_header, mdl_color_palette);
    if !load_textures_success {
        return .{}, false;
    }

    load_texcoords_success: bool;
    mdl_model.texcoords, load_texcoords_success = load_mdl_texcoords(pak_file, mdl_header);
    if !load_texcoords_success {
        mdl_cleanup_textures(mdl_model.images);
        return .{}, false;
    }

    load_triangles_success: bool;
    mdl_model.triangles, load_triangles_success = load_mdl_triangles(pak_file, mdl_header);
    if !load_triangles_success {
        mdl_cleanup_textures(mdl_model.images);
        array_free(mdl_model.texcoords);
        return .{}, false;
    }

    load_frames_success: bool;
    mdl_model.frames, load_frames_success = load_mdl_frames(pak_file, mdl_header);
    if !load_frames_success {
        mdl_cleanup_textures(mdl_model.images);
        array_free(mdl_model.texcoords);
        array_free(mdl_model.triangles);
        return .{}, false;
    }

    return mdl_model, true;
}