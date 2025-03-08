#import "Basic";
#import "String";
#import "SDL";
#import "GL"(DUMP_GL_ERRORS = true,ENABLE_ALL_EXTENSIONS=true);
#import "Math";

glu_lib :: #system_library "glu32";
gluPerspective :: (fovy: GLdouble, aspect: GLdouble, zNear: GLdouble, zFar: GLdouble) #foreign glu_lib;

#load "render.jai";

Vector3_Float32 :: struct {
    x, y, z: float32;
};

Vector3_U32 :: struct {
    x, y, z: u32;
};

Vector3_U8 :: struct {
    x, y, z: u8;
}

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

MAX_FILE_COUNT :: 1024;
MAX_TRIANGLE_COUNT :: 2048;
MAX_VERTEX_COUNT :: 1024;
MAX_FRAME_COUNT :: 256;
ANIMATION_FRAMES_PER_SECOND :: 10;

gl_vertices: [MAX_FRAME_COUNT][2*MAX_VERTEX_COUNT][3]GLfloat;   // Vertices
gl_texcoords: [2*MAX_VERTEX_COUNT][2]GLfloat;                   // Tex coords
gl_triangles: [MAX_TRIANGLE_COUNT][3]GLuint;                    // Index buffer
gl_triangle_count: GLsizei;
gl_vertex_count: GLsizei;
gl_frame_count: GLsizei;

anim_name: [MAX_FRAME_COUNT][16]u8;

tex: [1024*1024]u8;
texrgb: [1024*1024*3]u8;

mdl_files: [..]string;

load_colorpalette :: (file: File, pak_files: []PakFile) -> []Vector3_U8 {
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
            array_add(*mdl_files, copy_string(to_string(pak_file.name.data)));
        }

        array_add(*pak_files, pak_file.*);
        free(buffer);
    }

    print("Pak file successfully loaded.\n");
    
    return pak_files;
}

main :: () {
    SDL_Init(SDL_INIT_VIDEO);

    w := 640;
    h := 480;
    window := SDL_CreateWindow("An SDL2 window", SDL_WINDOWPOS_UNDEFINED, SDL_WINDOWPOS_UNDEFINED, xx w, xx h, SDL_WINDOW_OPENGL|SDL_WINDOW_RESIZABLE);

    // Check that the window was successfully created
    if window == null {
        // In the case that the window could not be made...
        print("Could not create window: %\n", to_string(SDL_GetError()));
        return;
    }

    SDL_GL_SetAttribute(SDL_GL_CONTEXT_PROFILE_MASK, xx SDL_GL_CONTEXT_PROFILE_CORE);

    gl_context := SDL_GL_CreateContext(window);
    if !gl_context {
        print( "Could not create OpenGL context: %\n", to_string(SDL_GetError()));
        return;
    }  

    gl_load(*gl, SDL_GL_GetProcAddress);
    using gl;

    print ("GL Vendor = %\n", to_string(glGetString(GL_VENDOR)));
    print ("GL Version = %\n", to_string(glGetString(GL_VERSION)));
    
    texture :GLuint;
    glGenTextures(1, *texture);
    glBindTexture(GL_TEXTURE_2D, texture);
    glTexParameteri(GL_TEXTURE_2D, GL_TEXTURE_MIN_FILTER, GL_LINEAR);
    glTexParameteri(GL_TEXTURE_2D, GL_TEXTURE_MAG_FILTER, GL_LINEAR);
    glTexParameteri(GL_TEXTURE_2D, GL_TEXTURE_WRAP_S, GL_CLAMP_TO_EDGE);
    glTexParameteri(GL_TEXTURE_2D, GL_TEXTURE_WRAP_T, GL_CLAMP_TO_EDGE);
    glPixelStorei(GL_UNPACK_ALIGNMENT, 1);

    glEnableClientState(GL_TEXTURE_COORD_ARRAY);
    glEnableClientState(GL_VERTEX_ARRAY);

    glEnable(GL_TEXTURE_2D);
    glEnable(GL_DEPTH_TEST);
    glClearColor(0.2, 0.2, 0.2, 1.0);

    file, file_success := file_open("C:/Program Files (x86)/Steam/steamapps/common/Quake/id1/PAK0.PAK");
    if !file_success {
        print("Could not open pak file!\n");
        return;
    }
    pak_files := load_pak(file);

    color_palette := load_colorpalette(file, pak_files);
    defer free(color_palette.data);

    mdl_file_index := 0;

    for pak_files {
        if contains(to_string(it.name.data), mdl_files[mdl_file_index]) {
            load_mdl(file, it, color_palette);
            break;
        }    
    }

    init_buffers(gl_texcoords, gl_triangles);

    exit := false;
    while !exit {
        event : SDL_Event;
        while SDL_PollEvent(*event) {
            if event.type == {
                case SDL_QUIT;
                    exit = true;
                case SDL_KEYUP;
                    if event.key.keysym.sym == SDLK_ESCAPE {
                        exit = true;
                    }
                    else if event.key.keysym.sym == SDLK_RIGHT {
                        // mdl_file_index = (mdl_file_index + 1) % mdl_files.count;

                        // for pak_files {
                        //     if contains(to_string(it.name.data), mdl_files[mdl_file_index]) {
                        //         load_mdl(file, it, color_palette);
                        //         break;
                        //     }    
                        // }
                    }
                case SDL_WINDOWEVENT;
                    if event.window.event == SDL_WINDOWEVENT_SIZE_CHANGED {
                        w = event.window.data1;
                        h = event.window.data2;
                    }
            }
        }

        time: float = cast(float) SDL_GetTicks() / 1000;
        angle: float = fmod_cycling(-180 + time * 360 / 5, 360);

        anim: float = time * ANIMATION_FRAMES_PER_SECOND;
        anim_lerp: float = fmod_cycling(anim, 1.0);
        frame: int = cast(int)anim % gl_frame_count;
        frame_next: int = (frame + 1) % gl_frame_count;

        curr_anim: [16]u8; 
        memcpy(curr_anim.data, *anim_name[frame], 16);
        title := sprint("q1 - %", to_string(curr_anim.data));
        SDL_SetWindowTitle(window, title.data);

        glClear(GL_COLOR_BUFFER_BIT | GL_DEPTH_BUFFER_BIT);
        glViewport(0, 0, xx w, xx h);
        // glMatrixMode(GL_PROJECTION);
        // glLoadIdentity();

        aspect: float = cast(float) w / h;
        // gluPerspective(60.0, aspect, 0.1, 1000.0);

        // glMatrixMode(GL_MODELVIEW);
        // glLoadIdentity();


        // glTranslated(0, 0, -90);
        // glRotated(angle, 0, 1, 0);
        // glRotated(-90, 1, 0, 0);
        // glTranslated(0, 0, -10.0);

        // glClear(GL_COLOR_BUFFER_BIT | GL_DEPTH_BUFFER_BIT);
        // glTexCoordPointer(2, GL_FLOAT, size_of(GLfloat)*2, *gl_texcoords);

        // vertices: [2 * MAX_VERTEX_COUNT * 3]GLfloat;
        // for 0..(2 * gl_vertex_count) - 1 {
        //     vertices[3 * it + 0] = gl_vertices[frame][it][0] * (1.0 - anim_lerp) + gl_vertices[frame_next][it][0] * anim_lerp;
        //     vertices[3 * it + 1] = gl_vertices[frame][it][1] * (1.0 - anim_lerp) + gl_vertices[frame_next][it][1] * anim_lerp;
        //     vertices[3 * it + 2] = gl_vertices[frame][it][2] * (1.0 - anim_lerp) + gl_vertices[frame_next][it][2] * anim_lerp;
        // }

        // glVertexPointer(3, GL_FLOAT, size_of(GLfloat) * 3, *vertices);
        // glDrawElements(GL_TRIANGLES, gl_triangle_count * 3, GL_UNSIGNED_INT, *gl_triangles);

        // glTranslatef(0, 0, -90);
        // glRotatef(angle, 0, 1, 0);
        // glRotatef(-90, 1, 0, 0);
        // glTranslatef(0, 0, -10.0);

        // glBegin(GL_TRIANGLES);
        // for i: 0..gl_triangle_count - 1 {
        //     for j: 0..2 {
        //         index : = gl_triangles[i][j];
        //         glTexCoord2f(gl_texcoords[index][0], gl_texcoords[index][1]);
        //         v: [3]GLfloat;
        //         v[0] = gl_vertices[frame][index][0] * (1.0 - anim_lerp) + gl_vertices[frame_next][index][0] * anim_lerp;
        //         v[1] = gl_vertices[frame][index][1] * (1.0 - anim_lerp) + gl_vertices[frame_next][index][1] * anim_lerp;
        //         v[2] = gl_vertices[frame][index][2] * (1.0 - anim_lerp) + gl_vertices[frame_next][index][2] * anim_lerp;

        //         glVertex3fv(v.data);
        //     }
        // }
        // glEnd();

        render(gl_vertices, gl_vertex_count, frame, frame_next, anim_lerp, aspect, texture, angle);

        SDL_GL_SwapWindow(window);
    }


    SDL_DestroyWindow(window);
    SDL_Quit();
}