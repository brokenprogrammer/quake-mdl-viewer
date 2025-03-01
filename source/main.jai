#import "Basic";
#import "String";
#import "SDL";
#import "GL";

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

load_pak :: (fileName: string) -> [] PakFile {
    file, file_success := file_open(fileName);
    if !file_success {
        print("Could not open pak file!\n");
        return .[];
    }

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

        print("#% File Name: %\n", it, to_string(pak_file.name.data));

        array_add(*pak_files, pak_file);
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

    pak_files := load_pak("C:/Program Files (x86)/Steam/steamapps/common/Quake/id1/PAK0.PAK");

    exit := false;
    while !exit {
        event : SDL_Event;
        while SDL_PollEvent(*event) {
            if event.type == {
                case SDL_QUIT;
                    exit = true;
                case SDL_KEYUP;
                    if event.key.keysym.sym == SDLK_ESCAPE exit = true;
                case SDL_WINDOWEVENT;
                    if event.window.event == SDL_WINDOWEVENT_SIZE_CHANGED {
                        w = event.window.data1;
                        h = event.window.data2;
                    }
            }
        }

        glViewport(0, 0, xx w, xx h);
        glClear(GL_COLOR_BUFFER_BIT);

        SDL_GL_SwapWindow(window);
    }


    SDL_DestroyWindow(window);
    SDL_Quit();
}