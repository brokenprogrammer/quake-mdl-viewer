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
    images: []PCXImage;
}

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

    return triangles;
}

load_md2_frames :: (file: File, md2_header: MD2Header)  -> []MD2Frame {
    // TODO(Oskar): Seek to triangles offset.

    frames := NewArray(md2_header.frame_count, MD2Frame);

    for frame: 0..md2_header.frame_count - 1 {
        md2_frame: MD2Frame;
        md2_frame.vertices = NewArray(md2_header.vertex_count, MD2Vertex);
        file_read(file, *md2_frame.scale, size_of(Vector3_Float32));
        file_read(file, *md2_frame.translate, size_of(Vector3_Float32));
        file_read(file, *md2_frame.name, size_of(u8) * md2_frame.name.count);
        file_read(file, md2_frame.vertices.data, size_of(MD2Vertex) * md2_header.vertex_count);

        frames[frame] = md2_frame;
    }

    return frames;
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

// TODO(Oskar): Result error handling, return false if fail to load.
load_md2 :: (file: File, md2_file: PakFile, pak_files: []PakFile) -> MD2Model {
    md2_model: MD2Model;

    // NOTE(Oskar): Assume that file offset is in right location if this succeeds.
    md2_header_success, md2_header := load_md2_header(file, md2_file);
    if !md2_header_success {
        print("Failed to read md2_header!");
        return md2_model;
    }

    md2_model.skin_width = md2_header.texture_width;
    md2_model.skin_height = md2_header.texture_height;
    
    md2_model.skins = load_md2_skins(file, md2_header);
    md2_model.texcoords = load_md2_texcoords(file, md2_header);
    md2_model.triangles = load_md2_triangles(file, md2_header);
    md2_model.frames = load_md2_frames(file, md2_header);

    md2_model.images = NewArray(md2_model.skins.count, PCXImage);
    for skin_index: 0..md2_model.skins.count - 1 {
        for pak_files {
            file_name := to_string(it.name.data);
            if (contains(file_name, to_string(md2_model.skins[skin_index].name.data))) {
                seek_success := file_seek(file, it.offset, .START);
                if !seek_success {
                    print("Failed to seek to md2 header offset\n");
                    return md2_model;
                }

                image, suck := pcx_load(file, it.offset, it.size);
                md2_model.images[skin_index] = image;
                break;
            }
        }
    }

    return md2_model;
}