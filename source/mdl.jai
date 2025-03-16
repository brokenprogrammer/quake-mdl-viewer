MAX_FILE_COUNT :: 1024;
MAX_TRIANGLE_COUNT :: 2048;
MAX_VERTEX_COUNT :: 1024;
MAX_FRAME_COUNT :: 256;
ANIMATION_FRAMES_PER_SECOND :: 10;

PakHeader :: struct {
    id: [4]u8;
    offset: u32;
    size: u32;
};

PakFile :: struct {
    name: [56]u8;
    offset: u32;
    size: u32;
};

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

MDLModel :: struct {
};

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

    return true, mdl_header;
}

load_mdl_texture_data :: (file: File, mdl_header: MDLHeader, color_palette: []Vector3_U8) {
    for 0..mdl_header.tex_count - 1 {
        group: u32;
        file_read(file, *group, size_of(u32));
        file_read(file, *tex, mdl_header.tex_width * mdl_header.tex_height);

        for 0..mdl_header.tex_width * mdl_header.tex_height - 1 {
            texrgb[3 * it + 0] = color_palette[tex[it]].x;
            texrgb[3 * it + 1] = color_palette[tex[it]].y;
            texrgb[3 * it + 2] = color_palette[tex[it]].z;
        }

        glBindTexture(GL_TEXTURE_2D, gl_texture);
        glPixelStorei(GL_UNPACK_ALIGNMENT, 1);
        glPixelStorei(GL_UNPACK_ROW_LENGTH, 0);
        glTexImage2D(GL_TEXTURE_2D, 0, GL_RGB8, mdl_header.tex_width, mdl_header.tex_height, 0, GL_RGB, GL_UNSIGNED_BYTE, *texrgb);
    }
}

load_mdl_texcoords :: (file: File, mdl_header: MDLHeader) {
    mdl_texcoord: [MAX_VERTEX_COUNT]MDLTexcoord;
    file_read(file, *mdl_texcoord, size_of(MDLTexcoord)*mdl_header.vertex_count);

    for 0..mdl_header.vertex_count - 1 {
        s := mdl_texcoord[it].s + 0.5;
        t := mdl_texcoord[it].t + 0.5;
        
        gl_texcoords[it][0] = s / mdl_header.tex_width;
        gl_texcoords[it][1] = t / mdl_header.tex_height;
        a := ifx mdl_texcoord[it].seam 0.5 else 0.0;
        gl_texcoords[it + mdl_header.vertex_count][0] = (s + mdl_header.tex_width * (a)) / mdl_header.tex_width;
        gl_texcoords[it + mdl_header.vertex_count][1] = t / mdl_header.tex_height;
    }
}

load_mdl_triangles :: (file: File, mdl_header: MDLHeader) {
    mdl_triangles: [MAX_TRIANGLE_COUNT]MDLTriangle;
    file_read(file, *mdl_triangles, size_of(MDLTriangle)*mdl_header.triangle_count);
    
    for 0..mdl_header.triangle_count - 1 {
        gl_triangles[it][0] = mdl_triangles[it].vertex.x + (ifx mdl_triangles[it].frontface 0 else mdl_header.vertex_count);
        gl_triangles[it][1] = mdl_triangles[it].vertex.y + (ifx mdl_triangles[it].frontface 0 else mdl_header.vertex_count);
        gl_triangles[it][2] = mdl_triangles[it].vertex.z + (ifx mdl_triangles[it].frontface 0 else mdl_header.vertex_count);
    }
    gl_triangle_count = mdl_header.triangle_count;
}

load_mdl_vertices :: (file: File, mdl_header: MDLHeader) {
    for frame: 0..mdl_header.frame_count - 1 {
        group: u32;
        file_read(file, *group, size_of(u32));

        mdl_frame: MDLFrame;
        file_read(file, *mdl_frame, size_of(MDLFrame));

        memcpy(*anim_name[frame], mdl_frame.name.data, mdl_frame.name.count);

        vertices: [MAX_VERTEX_COUNT]MDLVertex;
        file_read(file, *vertices, size_of(MDLVertex)*mdl_header.vertex_count);

        for k: 0..mdl_header.vertex_count - 1 {
            // Front
            gl_vertices[frame][k][0] = mdl_header.scale.x * vertices[k].pos.x + mdl_header.translate.x;
            gl_vertices[frame][k][1] = mdl_header.scale.y * vertices[k].pos.y + mdl_header.translate.y;
            gl_vertices[frame][k][2] = mdl_header.scale.z * vertices[k].pos.z + mdl_header.translate.z;

            // Back
            gl_vertices[frame][k + mdl_header.vertex_count][0] = gl_vertices[frame][k][0];
            gl_vertices[frame][k + mdl_header.vertex_count][1] = gl_vertices[frame][k][1];
            gl_vertices[frame][k + mdl_header.vertex_count][2] = gl_vertices[frame][k][2];


            // Front, added wraparound because some models seems to have indexes out of boudns..
            gl_normals[frame][k][0] = anorms_table[vertices[k].normal_index % 162].x;
            gl_normals[frame][k][1] = anorms_table[vertices[k].normal_index % 162].y;
            gl_normals[frame][k][2] = anorms_table[vertices[k].normal_index % 162].z;

            // Back
            gl_normals[frame][k + mdl_header.vertex_count][0] = gl_normals[frame][k][0];
            gl_normals[frame][k + mdl_header.vertex_count][1] = gl_normals[frame][k][1];
            gl_normals[frame][k + mdl_header.vertex_count][2] = gl_normals[frame][k][2];
        }
    }
}

load_mdl :: (file: File, pak_file: PakFile, color_palette: []Vector3_U8) {
    // NOTE(Oskar): Assume that file offset is in right location if this succeeds.
    mdl_header_success, mdl_header := load_mdl_header(file, pak_file);
    if !mdl_header_success {
        print("Failed to read mdl_header!");
        return;
    }

    gl_vertex_count = mdl_header.vertex_count;
    gl_triangle_count = mdl_header.triangle_count;
    gl_frame_count = mdl_header.frame_count;

    load_mdl_texture_data(file, mdl_header, color_palette);
    load_mdl_texcoords(file, mdl_header);
    load_mdl_triangles(file, mdl_header);
    load_mdl_vertices(file, mdl_header);

    return;
}

load_pak :: (file: File) -> [] PakFile {
    // NOTE(Oskar): Read file header.
    header: PakHeader;
    success, bytes := file_read(file, *header, size_of(PakHeader));
    if (!success) || (bytes < size_of(PakHeader)) {
        print("Could not read pak header!\n");
        return .[];
    }

    id_string: string;
    id_string.data = header.id.data;
    id_string.count = 4; 
    print("Pak header content: %\n", id_string);

    header_success := id_string == "PACK";
    if !header_success {
        print("Bad pak header id.\n");
        return .[];
    }

    pak_file_count := header.size / size_of(PakFile);
    print("Number of files: %\n", pak_file_count);

    
    seek_success := file_seek(file, header.offset, .START);
    if !seek_success {
        print("Unable to read full pak file.\n");
        return .[];
    }
    
    pak_files: [..]PakFile;
    for 0..pak_file_count - 1 {
        buffer := cast(*u8) alloc(size_of(PakFile));
        success, bytes := file_read(file, buffer, size_of(PakFile));
        if !success {
            print("Failed to read pak file!\n");
            return .[];
        }

        pak_file := cast(*PakFile)buffer;
        if contains(to_string(pak_file.name.data), ".mdl") {
            array_add(*mdl_file_names, copy_string(to_string(pak_file.name.data)));
        }

        array_add(*pak_files, pak_file.*);
        free(buffer);
    }

    print("Pak file successfully loaded.\n");
    
    return pak_files;
}