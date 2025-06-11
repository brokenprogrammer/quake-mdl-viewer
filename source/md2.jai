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

MD2Model :: struct {
    skin_width: s32;
    skin_height: s32;
    
    skins: []MD2Skin;
    texcoords: []MD2TexCoord;
    triangles: []MD2Triangle;
    frames: []MD2Frame;
    images: []PCXImage; // TODO(Oskar): Rename to texture
}

load_md2_header :: (md2_file: File) -> MD2Header, bool {
    mdl_header: MD2Header;

    read_success := file_read(md2_file, *mdl_header, size_of(MD2Header));
    if !read_success {
        log("Failed to read header from file.", flags=.ERROR);
        return mdl_header, false;
    }

    id_string: string;
    id_string.data = mdl_header.id.data;
    id_string.count = 4; 
    if id_string != "IDP2" {
        log("Invalid header.", flags=.ERROR);
        return mdl_header, false;
    }

    if mdl_header.version != 8 {
        log("Unsupported file version.", flags=.ERROR);
        return mdl_header, false;
    }

    return mdl_header, true;
}

load_md2_header :: (pak_file: PakFile) -> MD2Header, bool {
    seek_success := file_seek(pak_file.file, pak_file.offset, .START);
    if !seek_success {
        log("Failed to seek to header offset.", flags=.ERROR);
        return .{}, false;
    }

    md2_header, load_header_result := load_md2_header(pak_file.file);
    return md2_header, load_header_result;
}

load_md2_skins :: (md2_file: File, md2_header: MD2Header) -> []MD2Skin, bool {
    file_offset := xx md2_header.skin_offset;
    seek_result := file_seek(md2_file, file_offset, .START);
    if !seek_result {
        log("Failed to seek to skins section.", flags=.ERROR);
        return .[], false;
    }

    skins := NewArray(md2_header.skin_count, MD2Skin);
    read_result := file_read(md2_file, skins.data, size_of(MD2Skin) * md2_header.skin_count);
    if !read_result {
        log("Failed to read skins section.", flags=.ERROR);
        array_free(skins);
        return .[], false;
    }

    return skins, true;
}

load_md2_skins :: (pak_file: PakFile, md2_header: MD2Header) -> []MD2Skin, bool {
    file_offset := xx pak_file.offset + md2_header.skin_offset;
    seek_result := file_seek(pak_file.file, file_offset, .START);
    if !seek_result {
        log("Failed to seek to skins section.", flags=.ERROR);
        return .[], false;
    }

    skins := NewArray(md2_header.skin_count, MD2Skin);
    read_result := file_read(pak_file.file, skins.data, size_of(MD2Skin) * md2_header.skin_count);
    if !read_result {
        log("Failed to read skins section.", flags=.ERROR);
        array_free(skins);
        return .[], false;
    }

    return skins, true;
}

load_md2_texcoords :: (md2_file: File, md2_header: MD2Header) -> []MD2TexCoord, bool {
    file_offset := xx md2_header.texture_coordinate_offset;
    seek_result := file_seek(md2_file, file_offset, .START);
    if !seek_result {
        log("Failed to seek to texcoords section.", flags=.ERROR);
        return .[], false;
    }

    texcoords := NewArray(md2_header.texture_coordinate_count, MD2TexCoord);
    read_result := file_read(md2_file, texcoords.data, size_of(MD2TexCoord) * md2_header.texture_coordinate_count);
    if !read_result {
        log("Failed to read texcoords section.", flags=.ERROR);
        array_free(texcoords);
        return .[], false;
    }

    return texcoords, true;
}

load_md2_texcoords :: (pak_file: PakFile, md2_header: MD2Header) -> []MD2TexCoord, bool {
    file_offset := xx pak_file.offset + md2_header.texture_coordinate_offset;
    seek_result := file_seek(pak_file.file, file_offset, .START);
    if !seek_result {
        log("Failed to seek to texcoords section.", flags=.ERROR);
        return .[], false;
    }

    texcoords := NewArray(md2_header.texture_coordinate_count, MD2TexCoord);
    read_result := file_read(pak_file.file, texcoords.data, size_of(MD2TexCoord) * md2_header.texture_coordinate_count);
    if !read_result {
        log("Failed to read texcoords section.", flags=.ERROR);
        array_free(texcoords);
        return .[], false;
    }

    return texcoords, true;
}

load_md2_triangles :: (md2_file: File, md2_header: MD2Header) -> []MD2Triangle, bool {
    file_offset := xx md2_header.triangle_offset;
    seek_result := file_seek(md2_file, file_offset, .START);
    if !seek_result {
        log("Failed to seek to triangles section.", flags=.ERROR);
        return .[], false;
    }

    triangles := NewArray(md2_header.triangle_count, MD2Triangle);
    read_result := file_read(md2_file, triangles.data, size_of(MD2Triangle) * md2_header.triangle_count);
    if !read_result {
        log("Failed to read triangles section.", flags=.ERROR);
        array_free(triangles);
        return .[], false;
    }

    return triangles, true;
}

load_md2_triangles :: (pak_file: PakFile, md2_header: MD2Header) -> []MD2Triangle, bool {
    file_offset := xx pak_file.offset + md2_header.triangle_offset;
    seek_result := file_seek(pak_file.file, file_offset, .START);
    if !seek_result {
        log("Failed to seek to triangles section.", flags=.ERROR);
        return .[], false;
    }

    triangles := NewArray(md2_header.triangle_count, MD2Triangle);
    read_result := file_read(pak_file.file, triangles.data, size_of(MD2Triangle) * md2_header.triangle_count);
    if !read_result {
        log("Failed to read triangles section.", flags=.ERROR);
        array_free(triangles);
        return .[], false;
    }

    return triangles, true;
}

load_md2_frames :: (md2_file: File, md2_header: MD2Header)  -> []MD2Frame, bool {
    file_offset := xx md2_header.frame_offset;
    seek_result := file_seek(md2_file, file_offset, .START);
    if !seek_result {
        log("Error seeking to frames section.", flags=.ERROR);
        return .[], false;
    }

    frames := NewArray(md2_header.frame_count, MD2Frame);

    for frame: 0..md2_header.frame_count - 1 {
        md2_frame: MD2Frame;
        md2_frame.vertices = NewArray(md2_header.vertex_count, MD2Vertex);

        read_result := file_read(md2_file, *md2_frame.scale, size_of(Vector3_Float32));
        if !read_result {
            log("Failed to read frame scale in frames section.", flags=.ERROR);
            array_free(md2_frame.vertices);
            return .[], false;
        }

        read_result = file_read(md2_file, *md2_frame.translate, size_of(Vector3_Float32));
        if !read_result {
            log("Failed to read frame translate in frames section.", flags=.ERROR);
            array_free(md2_frame.vertices);
            return .[], false;
        }

        read_result = file_read(md2_file, *md2_frame.name, size_of(u8) * md2_frame.name.count);
        if !read_result {
            log("Failed to read frame name in frames section.", flags=.ERROR);
            array_free(md2_frame.vertices);
            return .[], false;
        }

        read_result = file_read(md2_file, md2_frame.vertices.data, size_of(MD2Vertex) * md2_header.vertex_count);
        if !read_result {
            log("Failed to read frame vertices in frames section.", flags=.ERROR);
            array_free(md2_frame.vertices);
            return .[], false;
        }

        frames[frame] = md2_frame;
    }

    return frames, true;
}

load_md2_frames :: (pak_file: PakFile, md2_header: MD2Header)  -> []MD2Frame, bool {
    file_offset := xx pak_file.offset + md2_header.frame_offset;
    seek_result := file_seek(pak_file.file, file_offset, .START);
    if !seek_result {
        log("Error seeking to frames section.", flags=.ERROR);
        return .[], false;
    }

    frames := NewArray(md2_header.frame_count, MD2Frame);

    for frame: 0..md2_header.frame_count - 1 {
        md2_frame: MD2Frame;
        md2_frame.vertices = NewArray(md2_header.vertex_count, MD2Vertex);

        read_result := file_read(pak_file.file, *md2_frame.scale, size_of(Vector3_Float32));
        if !read_result {
            log("Failed to read frame scale in frames section.", flags=.ERROR);
            array_free(md2_frame.vertices);
            return .[], false;
        }

        read_result = file_read(pak_file.file, *md2_frame.translate, size_of(Vector3_Float32));
        if !read_result {
            log("Failed to read frame translate in frames section.", flags=.ERROR);
            array_free(md2_frame.vertices);
            return .[], false;
        }

        read_result = file_read(pak_file.file, *md2_frame.name, size_of(u8) * md2_frame.name.count);
        if !read_result {
            log("Failed to read frame name in frames section.", flags=.ERROR);
            array_free(md2_frame.vertices);
            return .[], false;
        }

        read_result = file_read(pak_file.file, md2_frame.vertices.data, size_of(MD2Vertex) * md2_header.vertex_count);
        if !read_result {
            log("Failed to read frame vertices in frames section.", flags=.ERROR);
            array_free(md2_frame.vertices);
            return .[], false;
        }

        frames[frame] = md2_frame;
    }

    return frames, true;
}

md2_model_cleanup :: (md2_model: MD2Model) {
    array_free(md2_model.skins);
    array_free(md2_model.texcoords);
    array_free(md2_model.triangles);

    for md2_model.frames {
        array_free(it.vertices);
    }
    array_free(md2_model.frames);
    array_free(md2_model.images);
}  

load_md2 :: (md2_file: File) -> MD2Model, bool {
    md2_logger_data := project_setup_logger("[MD2 Loader]");
    defer project_cleanup_logger(md2_logger_data);    

    // NOTE(Oskar): Assume that file offset is in right location if this succeeds.
    md2_header, md2_header_success := load_md2_header(md2_file);
    if !md2_header_success {
        return .{}, false;
    }

    md2_model: MD2Model;
    md2_model.skin_width = md2_header.texture_width;
    md2_model.skin_height = md2_header.texture_height;

    load_skins_success: bool;
    md2_model.skins, load_skins_success = load_md2_skins(md2_file, md2_header);
    if !load_skins_success {
        return .{}, false;
    }

    load_texcoords_success: bool;
    md2_model.texcoords, load_texcoords_success = load_md2_texcoords(md2_file, md2_header);
    if !load_texcoords_success {
        array_free(md2_model.skins);
        return .{}, false;
    }

    load_triangles_success: bool;
    md2_model.triangles, load_triangles_success = load_md2_triangles(md2_file, md2_header);
    if !load_triangles_success {
        array_free(md2_model.skins);
        array_free(md2_model.texcoords);
        return .{}, false;
    }

    // TODO(Oskar): if this fails in the middle of frames loading we can leak here..
    load_frames_success: bool;
    md2_model.frames, load_frames_success = load_md2_frames(md2_file, md2_header);
    if !load_frames_success {
        array_free(md2_model.skins);
        array_free(md2_model.texcoords);
        array_free(md2_model.triangles);
        return .{}, false;
    }

    // TODO(Oskar): Move this to its own function.
    md2_model.images = NewArray(md2_model.skins.count, PCXImage);
    for skin_index: 0..md2_model.skins.count - 1 {
        file_name := tprint("%.pcx", to_string(md2_model.skins[skin_index].name.data));

        file, file_success := file_open(file_name);
        if !file_success {
            log("Failed to open PCX image: %", file_name);
            continue;
        }

        file_size := file_length(file);
        
        image, suck := pcx_load(file, 0, file_size);
        md2_model.images[skin_index] = image;
    }

    return md2_model, true;
}

load_md2 :: (pak_file: PakFile, pak_files: []PakFile) -> MD2Model, bool {
    md2_logger_data := project_setup_logger("[MD2 Loader]");
    defer project_cleanup_logger(md2_logger_data);    

    // NOTE(Oskar): Assume that file offset is in right location if this succeeds.
    md2_header, md2_header_success := load_md2_header(pak_file);
    if !md2_header_success {
        return .{}, false;
    }

    md2_model: MD2Model;
    md2_model.skin_width = md2_header.texture_width;
    md2_model.skin_height = md2_header.texture_height;
    
    load_skins_success: bool;
    md2_model.skins, load_skins_success = load_md2_skins(pak_file, md2_header);
    if !load_skins_success {
        return .{}, false;
    }

    load_texcoords_success: bool;
    md2_model.texcoords, load_texcoords_success = load_md2_texcoords(pak_file, md2_header);
    if !load_texcoords_success {
        array_free(md2_model.skins);
        return .{}, false;
    }

    load_triangles_success: bool;
    md2_model.triangles, load_triangles_success = load_md2_triangles(pak_file, md2_header);
    if !load_triangles_success {
        array_free(md2_model.skins);
        array_free(md2_model.texcoords);
        return .{}, false;
    }

    // TODO(Oskar): if this fails in the middle of frames loading we can leak here..
    load_frames_success: bool;
    md2_model.frames, load_frames_success = load_md2_frames(pak_file, md2_header);
    if !load_frames_success {
        array_free(md2_model.skins);
        array_free(md2_model.texcoords);
        array_free(md2_model.triangles);
        return .{}, false;
    }

    // TODO(Oskar): Move this to its own function.
    md2_model.images = NewArray(md2_model.skins.count, PCXImage);
    for skin_index: 0..md2_model.skins.count - 1 {
        for pak_files {
            file_name := to_string(it.name.data);
            if (contains(file_name, to_string(md2_model.skins[skin_index].name.data))) {
                seek_success := file_seek(pak_file.file, it.offset, .START);
                if !seek_success {
                    print("Failed to seek to md2 header offset\n");
                    return md2_model, false;
                }

                image, suck := pcx_load(pak_file.file, it.offset, it.size);
                md2_model.images[skin_index] = image;
                break;
            }
        }
    }

    return md2_model, true;
}