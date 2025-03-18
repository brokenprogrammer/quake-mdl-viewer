#import "Basic";
#import "String";
#import "Window_Creation";
#import "Input";
#import "GL";
#import "Math";

simp :: #import "Simp";
getrect :: #import "GetRect";

#load "mdl.jai";
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

Vector2_GLfloat :: struct {
    x, y: GLfloat;
}

Vector3_GLfloat :: struct {
    x, y, z: GLfloat;
}

Vector3_GLuint :: struct {
	x, y, z: GLuint;
}

Vector3_Float32 :: struct {
    x, y, z: float32;
};

Vector3_U32 :: struct {
    x, y, z: u32;
};

Vector3_U8 :: struct {
    x, y, z: u8;
}

gl_texture: GLuint;
gl_vertices: [MAX_FRAME_COUNT][2*MAX_VERTEX_COUNT][3]GLfloat;   // Vertices
gl_normals: [MAX_FRAME_COUNT][2*MAX_VERTEX_COUNT][3]GLfloat;   // Normals
gl_texcoords: [2*MAX_VERTEX_COUNT][2]GLfloat;                   // Tex coords
gl_triangles: [MAX_TRIANGLE_COUNT][3]GLuint;                    // Index buffer
gl_triangle_count: GLsizei;
gl_vertex_count: GLsizei;
gl_frame_count: GLsizei;

anim_name: [MAX_FRAME_COUNT][16]u8;

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

    color_palette := load_mdl_colorpalette(file, pak_files);
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

        anim: float = g_params.animation_time;//time * ANIMATION_FRAMES_PER_SECOND;
        anim_lerp: float = fmod_cycling(anim, 1.0);
        frame: int = cast(int)anim % gl_frame_count;
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
        // Did not update mesh index
    } else {
        // Did update mesh index.
        for pak_files {
            if contains(to_string(it.name.data), g_params.mdl_names[g_params.mdl_index]) {
                load_mdl(file, it, color_palette);
                update_buffers(gl_texcoords, gl_triangles);
                break;
            }    
        }
    }

    g_params.animation_time += delta_time * g_params.animation_speed_in_fps;
    g_params.animation_time = fmod_cycling(g_params.animation_time, xx gl_frame_count);
}