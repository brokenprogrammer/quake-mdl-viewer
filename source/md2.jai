MD2Header :: struct {
    id: [4]u8;
    version: s32;
    
    skin_width: s32;
    skin_height: s32;

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

MD2Model :: struct {
    vertex_count: u32;
};

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

load_md2_skins :: (file: File, md2_header: MD2Header, md2_model: *MD2Model) -> []MD2Skin {
    skins := NewArray(md2_header.skin_count, MD2Skin);
    file_read(file, skins.data, size_of(MD2Skin) * md2_header.skin_count);

    return skins;
}

// TODO(Oskar): Result error handling, return false if fail to load.
load_md2 :: (file: File, pak_file: PakFile) -> MD2Model {
    md2_model : MD2Model;

    // NOTE(Oskar): Assume that file offset is in right location if this succeeds.
    md2_header_success, md2_header := load_md2_header(file, pak_file);
    if !md2_header_success {
        print("Failed to read md2_header!");
        return md2_model;
    }

    md2_model.vertex_count = xx (md2_header.vertex_count * 2);

    load_md2_skins(file, md2_header, *md2_model);

    return md2_model;
}