#import "Basic";
#import "String";
#import "Window_Creation";
#import "Input";
#import "GL";
#import "Math";
#import "stb_image";

simp :: #import "Simp";
getrect :: #import "GetRect";

#load "pak.jai";
#load "mdl.jai";
#load "md2.jai";
#load "pcx.jai";
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

g_model: MD2Model;

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

Vector3_U16 :: struct {
    x, y, z: u16;
}

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
	case .DRAG_AND_DROP_FILES;
		// TODO(Oskar): add additional files to our list of loadable files.
		// for g_params.dropped_files free(it);
		// array_reset(*g_params.dropped_files);
		// for event.files array_add(*g_params.dropped_files, copy_string(it));
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
		win32.SetProcessDPIAware();

		// Windows is very bad at thread-switching by default unless you do this. Sad.
        win32.timeBeginPeriod(1);
	}
    
    g_current_window_width = 1280;
    g_current_window_height = 720;
	g_window = create_window (g_current_window_width, g_current_window_height, "quake-mdl-viewer");
	#if OS == .WINDOWS {
		win32.DragAcceptFiles(g_window, cast(win32.BOOL) true);
	} else #if OS == .LINUX {
        X11 :: #import "X11";
        typelist := string.["url/url", "text/uri-list", "text/plain", "application/octet-stream"];
        X11.enable_drag_and_drop(my_window, typelist);
    } else #if OS == .MACOS {
        #import "Objective_C";
        #import "Objective_C/AppKit";
        types := NSArray(NSPasteboardType).arrayWithObject(NSPasteboardTypeFileURL);
        NSView.registerForDraggedTypes(my_window, types);
    }


    simp.set_render_target (g_window);

    print ("GL Vendor = %\n", to_string(glGetString(GL_VENDOR)));
    print ("GL Version = %\n", to_string(glGetString(GL_VERSION)));
    
    getrect.ui_init ();
	init_fonts ();

    // file, file_success := file_open("C:/Program Files (x86)/Steam/steamapps/common/Quake/id1/PAK0.PAK");
	file, file_success := file_open("C:\\Program Files (x86)\\Steam\\steamapps\\common\\Quake 2\\baseq2\\pak0.pak");
    if !file_success {
        print("Could not open pak file!\n");
        return;
    }
    pak_files := load_pak(file);

    color_palette := load_mdl_colorpalette(file, pak_files);
    defer free(color_palette.data);

    mdl_file_index := 0;

    for pak_files {
		file_name := to_string(it.name.data);
        if contains(file_name, mdl_file_names[mdl_file_index]) {
			if (ends_with(file_name, "mdl")) {
            	//g_model = load_mdl(file, it, color_palette);
			} else if ends_with(file_name, "md2") {
				g_model = load_md2(file, it, pak_files);
			}
            break;
        }    
    }
    g_params.mdl_names = mdl_file_names;
    g_params.mdl_index = xx mdl_file_index;
	g_params.mdl_index_last_frame = g_params.mdl_index;

	//g_params.frame_names = mdl_get_animation_names(g_model);
	//g_params.frame_index = 0;

    init_buffers(g_model);

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

        time: float = running_time;//cast(float) SDL_GetTicks() / 1000;
        angle: float = fmod_cycling(-180 + time * 360 / 5, 360);

        anim: float = g_params.animation_time;
        anim_lerp: float = fmod_cycling(anim, 1.0);
        frame: int = cast(int)anim % g_model.animations[g_params.frame_index].frames.count;
        frame_next: int = (frame + 1) % g_model.animations[g_params.frame_index].frames.count;

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

        render(g_model, frame, frame_next, anim_lerp, aspect, g_params.rotate, angle, g_params.frame_index, cast(s32)g_params.shading_mode, g_params.show_normals);
        
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

    if g_params.mdl_index == g_params.mdl_index_last_frame {
        // Did not update mesh index
    } else {
        // Did update mesh index.
        for pak_files {
			file_name := to_string(it.name.data);
            if contains(file_name, g_params.mdl_names[g_params.mdl_index]) {
				if ends_with(file_name, "mdl") {
                	//g_model = load_mdl(file, it, color_palette);
				} else if ends_with(file_name, "md2") {
					g_model = load_md2(file, it, pak_files);
				}

				array_free(g_params.frame_names);
				// g_params.frame_names = mdl_get_animation_names(g_model);
				// g_params.frame_index = 0;

				g_params.mdl_index_last_frame = g_params.mdl_index;

                update_buffers(g_model);
                break;
            }    
        }
    }

    g_params.animation_time += delta_time * g_params.animation_speed_in_fps;
    g_params.animation_time = fmod_cycling(g_params.animation_time, xx g_model.animations[g_params.frame_index].frames.count);
}