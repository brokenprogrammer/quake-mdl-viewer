#import "Basic";
#import "String";
#import "Window_Creation";
#import "Input";
#import "GL";
#import "Math";

simp :: #import "Simp";
getrect :: #import "GetRect";

#load "anorms.jai";
#load "render.jai";
#load "camera.jai";
#load "ui.jai";

g_window : Window_Type;
g_current_window_width, g_current_window_height : s32;
g_running : bool;
g_camera : Camera;
g_control_camera : bool = true;

g_font: *simp.Dynamic_Font;
g_checkbox_font: *simp.Dynamic_Font;
g_slider_font: *simp.Dynamic_Font;
g_dropdown_font: *simp.Dynamic_Font;

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

gl_texture: GLuint;
gl_vertices: [MAX_FRAME_COUNT][2*MAX_VERTEX_COUNT][3]GLfloat;   // Vertices
gl_normals: [MAX_FRAME_COUNT][2*MAX_VERTEX_COUNT][3]GLfloat;   // Normals
gl_texcoords: [2*MAX_VERTEX_COUNT][2]GLfloat;                   // Tex coords
gl_triangles: [MAX_TRIANGLE_COUNT][3]GLuint;                    // Index buffer
gl_triangle_count: GLsizei;
gl_vertex_count: GLsizei;
gl_frame_count: GLsizei;

anim_name: [MAX_FRAME_COUNT][16]u8;

tex: [1024*1024]u8;
texrgb: [1024*1024*3]u8;

mdl_file_names: [..]string;

handle_window_event :: (event : Event)
{
	getrect.getrect_handle_event (event);
	if event.type ==
	{
	case .QUIT;
		g_running = false;
	case .KEYBOARD;
		if event.key_pressed
		{
			if event.key_code == .ESCAPE
				set_camera_control (!g_control_camera);
			if event.key_code == .F4 && event.alt_pressed
				g_running = false;
		}
	}
}

set_camera_control :: inline (control : bool)
{
	g_control_camera = control;
	if g_control_camera
		hide_cursor ();
	else
		show_cursor ();
}

reinit_fonts :: init_fonts;
init_fonts :: ()
{
	// I want a pixel size of 20 with a window height of 720 => 720 / 36 = 20
	pixel_height := g_current_window_height / 36;
	g_font = simp.get_font_at_size ("data/fonts", "OpenSans-Regular.ttf", pixel_height);
	assert (g_font != null);
	pixel_height = g_current_window_height / 40;
	g_checkbox_font = simp.get_font_at_size ("data/fonts", "OpenSans-Regular.ttf", pixel_height);
	assert (g_checkbox_font != null);
	pixel_height = g_current_window_height / 45;
	g_slider_font = simp.get_font_at_size ("data/fonts", "OpenSans-Italic.ttf", pixel_height);
	assert (g_slider_font != null);
	g_dropdown_font = g_slider_font;
}

is_key_down :: inline (key : Key_Code) -> bool #must
{
	return (input_button_states[cast (s64) key] & .DOWN) != 0;
}

is_key_pressed :: inline (key : Key_Code) -> bool #must
{
	return (input_button_states[cast (s64) key] & .START) != 0;
}

show_cursor :: inline ()
{
	#if OS == .WINDOWS
	{
		win32 :: #import "Windows";
		win32.ShowCursor (1);
	}
	else
	{
		// @Todo!
	}
}

hide_cursor :: inline ()
{
	#if OS == .WINDOWS
	{
		win32 :: #import "Windows";
		win32.ShowCursor (0);
	}
	else
	{
		// @Todo!
	}
}

set_mouse_pointer_position :: inline (x : int, y : int)
{
	#if OS == .WINDOWS
	{
		// Windows module does not have SetCursorPos
		// win32 :: #import "Windows";
		// win32.SetCursorPos (xx x, xx y);
		// Hugh...
		user32 :: #system_library "User32";
		SetCursorPos :: (x : s32, y : s32) -> s32 #foreign user32;
		SetCursorPos (xx x, xx y);
	}
	else
	{
		// @Todo!
	}
}

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

main :: () {
    #if OS == .WINDOWS
	{
		win32 :: #import "Windows";
		win32.SetProcessDPIAware ();
	}
    
    g_current_window_width = 1280;
    g_current_window_height = 720;
	g_window = create_window (g_current_window_width, g_current_window_height, "quake-mdl-viewer");
    simp.set_render_target (g_window);

    print ("GL Vendor = %\n", to_string(glGetString(GL_VENDOR)));
    print ("GL Version = %\n", to_string(glGetString(GL_VERSION)));
    
    getrect.ui_init ();
	init_fonts ();

    glGenTextures(1, *gl_texture);
    glBindTexture(GL_TEXTURE_2D, gl_texture);
    glTexParameteri(GL_TEXTURE_2D, GL_TEXTURE_MIN_FILTER, GL_LINEAR);
    glTexParameteri(GL_TEXTURE_2D, GL_TEXTURE_MAG_FILTER, GL_LINEAR);
    glTexParameteri(GL_TEXTURE_2D, GL_TEXTURE_WRAP_S, GL_CLAMP_TO_EDGE);
    glTexParameteri(GL_TEXTURE_2D, GL_TEXTURE_WRAP_T, GL_CLAMP_TO_EDGE);
    glPixelStorei(GL_UNPACK_ALIGNMENT, 1);
    glPixelStorei(GL_UNPACK_ROW_LENGTH, 0);

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
        if contains(to_string(it.name.data), mdl_file_names[mdl_file_index]) {
            load_mdl(file, it, color_palette);
            break;
        }    
    }
    g_params.mdl_names = mdl_file_names;
    g_params.mdl_index = xx mdl_file_index;

    init_buffers(gl_texcoords, gl_triangles);

    g_camera.position = xyz (1, 1.3, 2.3);
	g_camera.euler_angles.x = -20 * PI / 180.0;
	g_camera.euler_angles.y = 10 * PI / 180.0;
	g_running = true;
	delta_time := 0.01667;
    running_time := 0.0;
    while g_running {
        frame_start := current_time_monotonic();
        reset_temporary_storage();
        update_window_events ();
        for get_window_resizes () {
			if it.window == g_window
			&& ((g_current_window_width != it.width) || (g_current_window_height != it.height)) {
				g_current_window_width = it.width;
				g_current_window_height = it.height;
                reinit_fonts ();
			}
		}

        for events_this_frame {
			handle_window_event (it);
        }

        update_frame(delta_time, file, pak_files, color_palette);

        if is_key_pressed(xx #char "F") {
            mdl_file_index = (mdl_file_index + 1) % mdl_file_names.count;
            for pak_files {
                if contains(to_string(it.name.data), mdl_file_names[mdl_file_index]) {
                    load_mdl(file, it, color_palette);
                    update_buffers(gl_texcoords, gl_triangles);
                    break;
                }    
            }
        }

        time: float = running_time;//cast(float) SDL_GetTicks() / 1000;
        angle: float = fmod_cycling(-180 + time * 360 / 5, 360);

        anim: float = 0;//time * ANIMATION_FRAMES_PER_SECOND;
        anim_lerp: float = 0;//fmod_cycling(anim, 1.0);
        frame: int = 0;//cast(int)anim % gl_frame_count;
        frame_next: int = (frame + 1) % gl_frame_count;

        // curr_anim: [16]u8; 
        // memcpy(curr_anim.data, *anim_name[frame], 16);
        // title := sprint("q1 - %", to_string(curr_anim.data));
        // SDL_SetWindowTitle(window, title.data);

        glViewport(0, 0, xx g_current_window_width, xx g_current_window_height);

        aspect: float = cast(float) g_current_window_width / g_current_window_height;
        
        glDepthMask (GL_TRUE);
		glEnable (GL_DEPTH_TEST);
        simp.update_window (g_window);
		simp.clear_render_target (0.1, 0.1, 0.1, 1);
        glClear (GL_DEPTH_BUFFER_BIT);

        // Draw coordinate axes
		draw_line (.{}, .{x=1}, .{x=1, w=1});
		draw_line (.{}, .{y=1}, .{y=1, w=1});
		draw_line (.{}, .{z=1}, .{z=1, w=1});

		// Draw grid
		for i : -25..25 {
			draw_line (xyz (xx i, 0, -25), xyz (xx i, 0, 25), .{0.4, 0.4, 0.4, 1});
        }
		for i : -25..25 {
			draw_line (xyz (-25, 0, xx i), xyz (25, 0, xx i), .{0.4, 0.4, 0.4, 1});
        }

        render(gl_vertices, gl_vertex_count, frame, frame_next, anim_lerp, aspect, gl_texture, angle);
        
        update_ui (delta_time);

        simp.swap_buffers (g_window);

        frame_end := current_time_monotonic();
		delta_time = cast (float) to_float64_seconds(frame_end - frame_start);
        running_time += delta_time;
    }
}

update_frame :: (delta_time : float, file: File, pak_files: []PakFile, color_palette: []Vector3_U8)
{
	if !input_application_has_focus && g_control_camera {
		set_camera_control (false);
    }

	// Lock the cursor in the middle of the screen when controlling the camera
	if g_control_camera {
		x, y, w, h := get_dimensions (g_window, false);
		set_mouse_pointer_position (w / 2, h / 2);
	}

	update_flying_camera (*g_camera, delta_time);

    if g_params.mdl_index == 0 {
        print("DID NOT UPDATE MESH INDEX");

    } else {
        print("DID UPDATE!!!!!!");
        for pak_files {
            if contains(to_string(it.name.data), g_params.mdl_names[g_params.mdl_index]) {
                load_mdl(file, it, color_palette);
                update_buffers(gl_texcoords, gl_triangles);
                break;
            }    
        }
    }

    
}