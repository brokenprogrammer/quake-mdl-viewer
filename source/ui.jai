Interpolation_Mode :: enum s32 {
	NEAREST :: 0;
	LINEAR  :: 1;
	LINEAR_SLERP :: 2;
}

Shading_Mode :: enum s32 {
	COLOR :: 0;
	TEXTURE :: 1;
	NORMAL :: 2;
}

g_params : struct {
	theme: getrect.Overall_Theme;
	controls_subwindow: getrect.Subwindow_Info;
	details_subwindow: getrect.Subwindow_Info;
	directional_light_ambient_subwindow: getrect.Subwindow_Info;
	directional_light_diffuse_subwindow: getrect.Subwindow_Info;
	directional_light_specular_subwindow: getrect.Subwindow_Info;
	subwindows_initialized := false;
	controls_scroll_value: float;
    mdl_names: []string;
    mdl_index: s32;
	mdl_index_last_frame: s32;
	mdl_scroll_value: float;
	animation_names: []string;
	animation_index: s32;
	skin_names: []string;
	skin_index: s32;
	animation_time := 0.0;
	animation_speed_in_fps := 10.0;
	show_animation := true;
	show_normals := false;
	show_skybox := true;
	show_gizmos := true;
	interpolation_mode := Interpolation_Mode.LINEAR; // TODO(Oskar): Implement this later.
	shading_mode := Shading_Mode.TEXTURE;

	// Light
	directional_light_direction := Vector3.{-0.2, -1.0, -0.3};
	directional_light_ambient_color := Vector3.{0.05, 0.05, 0.05};
	directional_light_diffuse_color := Vector3.{0.4, 0.4, 0.4};
	directional_light_specular_color := Vector3.{0.5, 0.5, 0.5};
};

update_ui :: (delta_time: float) {
    using g_params;

	theme_proc := getrect.default_theme_procs[xx getrect.Default_Themes.Bentonite];
	theme = theme_proc();
	getrect.set_default_theme(theme);

    glDisable (GL_DEPTH_TEST);
	glDepthMask (GL_FALSE);

    simp.set_shader_for_color ();
	current_time := to_float64_seconds (current_time_monotonic ());
    w, h := simp.get_render_dimensions (g_window);
	getrect.ui_per_frame_update (g_window, w, h, current_time);

	subwindow_theme := theme.subwindow_theme;
	
    k := g_current_window_height / 45.0;
	pad := cast (float) g_font.character_height * 1.6;

	if !subwindows_initialized {
		r := getrect.get_rect(pad*2, pad*2, w/3.0, h*0.8);
		controls_subwindow.rect 				= r;
		controls_subwindow.draw                 = draw_controls_subwindow;
		controls_subwindow.title_text           = "Controls";

		r2 := getrect.get_rect(w/2.0, pad*2, w/3.0, h*0.8);
		details_subwindow.rect 				= r2;
		details_subwindow.draw              = draw_details_subwindow;
		details_subwindow.title_text        = "Details";
		details_subwindow.open = false;

		// Directional light ambient color picker window
		{
			k := g_current_window_height * .1;
			aspect := getrect.get_desired_aspect_ratio(*theme.color_picker_theme);
			r = getrect.get_rect(6.5*k, 3*k, 3*k, 3*k/aspect);
			directional_light_ambient_subwindow.rect = r;
			directional_light_ambient_subwindow.draw = draw_directional_light_ambient_subwindow;
			directional_light_ambient_subwindow.title_text = "Directional Ambient Color";
			directional_light_ambient_subwindow.fixed_aspect_ratio = aspect;
			directional_light_ambient_subwindow.open = false;
		}

		// Directional light diffuse color picker window
		{
			k := g_current_window_height * .1;
			aspect := getrect.get_desired_aspect_ratio(*theme.color_picker_theme);
			r = getrect.get_rect(6.5*k, 3*k, 3*k, 3*k/aspect);
			directional_light_diffuse_subwindow.rect = r;
			directional_light_diffuse_subwindow.draw = draw_directional_light_diffuse_subwindow;
			directional_light_diffuse_subwindow.title_text = "Directional Diffuse Color";
			directional_light_diffuse_subwindow.fixed_aspect_ratio = aspect;
			directional_light_diffuse_subwindow.open = false;
		}

		// Directional light specular color picker window
		{
			k := g_current_window_height * .1;
			aspect := getrect.get_desired_aspect_ratio(*theme.color_picker_theme);
			r = getrect.get_rect(6.5*k, 3*k, 3*k, 3*k/aspect);
			directional_light_specular_subwindow.rect = r;
			directional_light_specular_subwindow.draw = draw_directional_light_specular_subwindow;
			directional_light_specular_subwindow.title_text = "Directional Specular Color";
			directional_light_specular_subwindow.fixed_aspect_ratio = aspect;
			directional_light_specular_subwindow.open = false;
		}

		subwindows_initialized = true;
	}

	if controls_subwindow.open {
		subwindow_state := getrect.add_subwindow(*controls_subwindow, *subwindow_theme);
	}

	if details_subwindow.open {
		subwindow_state := getrect.add_subwindow(*details_subwindow, *subwindow_theme);
	}

	if directional_light_ambient_subwindow.open {
		subwindow_state := getrect.add_subwindow(*directional_light_ambient_subwindow, *subwindow_theme);
	}

	if directional_light_diffuse_subwindow.open {
		subwindow_state := getrect.add_subwindow(*directional_light_diffuse_subwindow, *subwindow_theme);
	}

	if directional_light_specular_subwindow.open {
		subwindow_state := getrect.add_subwindow(*directional_light_specular_subwindow, *subwindow_theme);
	}
}

draw_details_subwindow :: (state: *getrect.Subwindow_State, window_rect: getrect.Rect, data: *void) {
	using g_params;

	theme_proc := getrect.default_theme_procs[xx getrect.Default_Themes.Bentonite];
	theme = theme_proc();
	getrect.set_default_theme(theme);

	// Init themes
	label_theme := theme.label_theme;
	label_theme.font = g_font;
	checkbox_theme := theme.checkbox_theme;
	checkbox_theme.font = g_checkbox_font;
	slider_theme := theme.slider_theme;
	slider_theme.foreground.font = g_slider_font;

	dropdown_theme := theme.dropdown_theme;
	dropdown_theme.theme_for_current_value.font = g_dropdown_font;
	dropdown_theme.theme_for_each_choice.font = g_dropdown_font;
	dropdown_theme.theme_for_current_choice.font = g_dropdown_font;

	w := window_rect.w;
	h := window_rect.h;

	k := g_current_window_height / 45.0;
	pad := cast (float) g_font.character_height * 1.0;

	dropdown_offset := window_rect.w * 0.15;
	dropdown_width  := window_rect.w * 0.2;
	
	r := window_rect;
	r.h = g_font.character_height * 1.1;
    r.y = window_rect.y + window_rect.h - r.h - pad;

	longest_label_width := simp.prepare_text (g_font, "Triangle Count:");

	// TODO(Oskar): Add something inside model to indicate initiation or not.
	if !(g_model.animations.count > 0) {
		r.x = window_rect.x + pad;
		label_width := simp.prepare_text (g_font, "No model loaded.");
		r.w = xx label_width;
		getrect.label (r, "No model loaded.", *label_theme);
		return;
	}

	// Model Name
	{
		r.x = window_rect.x + pad;
		label_width := simp.prepare_text (g_font, "Model:");
		r.w = xx label_width;
		getrect.label (r, "Model:", *label_theme);

		r.x += longest_label_width;
		defer r.x -= longest_label_width;

		r.w = window_rect.w - longest_label_width - pad * 2;
		s := tprint("%", mdl_names[mdl_index]);
		getrect.label (r, s, *label_theme);
	}
	r.y -= r.h + pad;

	// Model Vertex Count
	{
		r.x = window_rect.x + pad;
		label_width := simp.prepare_text (g_font, "Vertex Count:");
		r.w = xx label_width;
		getrect.label (r, "Vertex Count:", *label_theme);

		r.x += longest_label_width;
		defer r.x -= longest_label_width;

		vertex_count := g_model.animations[0].frames[0].vertices.count * 3;

		r.w = window_rect.w - longest_label_width - pad * 2;
		s := tprint("%", vertex_count);
		getrect.label (r, s, *label_theme);
	}
	r.y -= r.h + pad;

	// Model Triangle Count
	{
		r.x = window_rect.x + pad;
		label_width := simp.prepare_text (g_font, "Triangle Count:");
		r.w = xx label_width;
		getrect.label (r, "Triangle Count:", *label_theme);

		r.x += longest_label_width;
		defer r.x -= longest_label_width;

		triangle_count := g_model.animations[0].frames[0].vertices.count;

		r.w = window_rect.w - longest_label_width - pad * 2;
		s := tprint("%", triangle_count);
		getrect.label (r, s, *label_theme);
	}
	r.y -= r.h + pad;

	// Model Number of Frames
	{
		r.x = window_rect.x + pad;
		label_width := simp.prepare_text (g_font, "Frame Count: ");
		r.w = xx label_width;
		getrect.label (r, "Frame Count:", *label_theme);

		r.x += longest_label_width;
		defer r.x -= longest_label_width;

		number_of_frames := 0;
		for g_model.animations {
			number_of_frames += it.frames.count;
		}

		r.w = window_rect.w - longest_label_width - pad * 2;
		s := tprint("%", number_of_frames);
		getrect.label (r, s, *label_theme);
	}
	r.y -= r.h + pad;

	// Model Number of Skins
	{
		r.x = window_rect.x + pad;
		label_width := simp.prepare_text (g_font, "Skin Count:");
		r.w = xx label_width;
		getrect.label (r, "Skin Count:", *label_theme);

		r.x += longest_label_width;
		defer r.x -= longest_label_width;

		r.w = window_rect.w - longest_label_width - pad * 2;
		s := tprint("%", g_model.skins.count);
		getrect.label (r, s, *label_theme);
	}
	r.y -= r.h + pad;

	// Model Position
	{
		r.x = window_rect.x + pad;
		label_width := simp.prepare_text (g_font, "Position:");
		r.w = xx label_width;
		getrect.label (r, "Position:", *label_theme);

		r.x += longest_label_width;
		defer r.x -= longest_label_width;

		position: TG_Float3;
		TG_GetRigidTransformPosition(g_model.transform, *position);

		r.w = window_rect.w - longest_label_width - pad * 2;
		s := tprint("%, %, %", position.x, position.y, position.z);
		getrect.label (r, s, *label_theme);
	}
	r.y -= r.h + pad;

	// Model Rotation
	{
		r.x = window_rect.x + pad;
		label_width := simp.prepare_text (g_font, "Rotation:");
		r.w = xx label_width;
		getrect.label (r, "Rotation:", *label_theme);

		r.x += longest_label_width;
		defer r.x -= longest_label_width;

		rotation: TG_Float4;
		TG_GetRigidTransformOrientation(g_model.transform, *rotation);

		r.w = window_rect.w - longest_label_width - pad * 2;
		s := tprint("%, %, %", rotation.x, rotation.y, rotation.z);
		getrect.label (r, s, *label_theme);
	}
	r.y -= r.h + pad;

	// Model Scale
	{
		r.x = window_rect.x + pad;
		label_width := simp.prepare_text (g_font, "Scale:");
		r.w = xx label_width;
		getrect.label (r, "Scale:", *label_theme);

		r.x += longest_label_width;
		defer r.x -= longest_label_width;

		scale: TG_Float3;
		TG_GetRigidTransformScale(g_model.transform, *scale);

		r.w = window_rect.w - longest_label_width - pad * 2;
		s := tprint("%, %, %", scale.x, scale.y, scale.z);
		getrect.label (r, s, *label_theme);
	}
}

draw_controls_subwindow :: (state: *getrect.Subwindow_State, window_rect: getrect.Rect, data: *void) {
	using g_params;

	theme_proc := getrect.default_theme_procs[xx getrect.Default_Themes.Bentonite];
	theme = theme_proc();
	getrect.set_default_theme(theme);

	// Init themes
	label_theme := theme.label_theme;
	label_theme.font = g_font;
	button_theme := theme.button_theme;
	button_theme.font = g_font;
	checkbox_theme := theme.checkbox_theme;
	checkbox_theme.font = g_checkbox_font;
	slider_theme := theme.slider_theme;
	slider_theme.foreground.font = g_slider_font;

	scrollable_region_theme := theme.scrollable_region_theme;
	scrollable_region_theme.region_background.shape.rounding_flags = 0;

	dropdown_theme := theme.dropdown_theme;
	dropdown_theme.theme_for_current_value.font = g_dropdown_font;
	dropdown_theme.theme_for_each_choice.font = g_dropdown_font;
	dropdown_theme.theme_for_current_choice.font = g_dropdown_font;

	w := window_rect.w;
	h := window_rect.h;

	k := g_current_window_height / 45.0;
	pad := cast (float) g_font.character_height * 1.0;

	dropdown_offset := window_rect.w * 0.15;
	dropdown_width  := window_rect.w * 0.2;
	
	// r := window_rect;
	region, inside := getrect.begin_scrollable_region(window_rect, *scrollable_region_theme);

	r := inside;
	r.h = g_font.character_height * 1.1;
    r.y = window_rect.y + window_rect.h - r.h - pad;
	r.y += controls_scroll_value;

	// Model and animation controls
	{
		r.x = window_rect.x + pad;
		label_width := simp.prepare_text (g_font, "Model & Animation Controls");
		r.w = xx label_width;
		getrect.label (r, "Model & Animation Controls", *label_theme);
		
		r.x += label_width;
		defer r.x -= label_width;
	}
	r.y -= r.h + pad;

    // Model selection
	{
		r.x = window_rect.x + pad;
		label_width := simp.prepare_text (g_font, "Model: ");
		r.w = xx label_width;
		getrect.label (r, "Model: ", *label_theme);

		r.x += label_width;
		defer r.x -= label_width;

		r.w = window_rect.w - label_width - pad * 2;
		getrect.scrollable_dropdown (
			r,
			mdl_names,
			*mdl_index,
			*mdl_scroll_value,
			*dropdown_theme
		);
	}
	r.y -= r.h + pad; // Move down to the next control position

	// Animation selection
	{
		r.x = window_rect.x + pad;
		label_width := simp.prepare_text (g_font, "Animation: ");
		r.w = xx label_width;
		getrect.label (r, "Animation: ", *label_theme);
		
		r.x += label_width;
		defer r.x -= label_width;
		
		r.w = window_rect.w - label_width - pad * 2;
		getrect.dropdown (
			r,
			animation_names,
			*animation_index,
			*dropdown_theme
		);
	}
	r.y -= r.h + pad; // Move down to the next control position
	
	// Skin selection
	{
		r.x = window_rect.x + pad;
		label_width := simp.prepare_text (g_font, "Skin: ");
		r.w = xx label_width;
		getrect.label (r, "Skin: ", *label_theme);
		
		r.x += label_width;
		defer r.x -= label_width;
		
		r.w = window_rect.w - label_width - pad * 2;
		getrect.dropdown (
			r,
			skin_names,
			*skin_index,
			*dropdown_theme
		);
	}
	r.y -= r.h + pad; // Move down to the next control position

	// Animation speed slider
	{
		r.x = window_rect.x + pad;
		r.w = w * 0.1 + xx simp.prepare_text (g_slider_font, "Animation Speed: 120.00 FPS");
		getrect.slider (r, *animation_speed_in_fps, 0.0, 120.0, 1.0, *slider_theme, "Animation Speed: ", "FPS");
	}
	r.y -= r.h + pad;

	if g_model.animations.count > 0 &&
		g_model.animations[animation_index].frames.count > 1 {
		// Animation time slider
		{
			r.x = window_rect.x + pad;
			sample_count := g_model.animations[animation_index].frames.count / 1.0;
			text := tprint ("Animation Time: %.00", sample_count);
			r.w = w * 0.1 + xx simp.prepare_text (g_slider_font, text);
			getrect.slider (r, *animation_time, 0.0, xx sample_count, 1.0, *slider_theme, "Animation Time: ", "");
		}
		r.y -= r.h + pad;
	}
	
	// Show Normals checkbox
	{
		r.x = window_rect.x + pad;
		r.w = r.h + xx simp.prepare_text (g_checkbox_font, "Show Normals");
		pressed := getrect.base_checkbox (r, "Show Normals", show_normals, *checkbox_theme);
		show_normals ^= pressed;
	}
	r.y -= r.h + pad;

	// Show Skybox checkbox
	{
		r.x = window_rect.x + pad;
		r.w = r.h + xx simp.prepare_text (g_checkbox_font, "Show Skybox");
		pressed := getrect.base_checkbox (r, "Show Skybox", show_skybox, *checkbox_theme);
		show_skybox ^= pressed;
	}
	r.y -= r.h + pad;

	// Show Gizmo checkbox
	{
		r.x = window_rect.x + pad;
		r.w = r.h + xx simp.prepare_text (g_checkbox_font, "Show Gizmos");
		pressed := getrect.base_checkbox (r, "Show Gizmos", show_gizmos, *checkbox_theme);
		show_gizmos ^= pressed;
	}
	r.y -= r.h + pad;

	// Shading mode
	{
		r.x = window_rect.x + pad;
		label_width := simp.prepare_text (g_font, "Shading Mode: ");
		r.w = xx label_width;
		getrect.label (r, "Shading Mode: ", *label_theme);
		
		r.x += label_width;
		defer r.x -= label_width;
		
		r.w = window_rect.w - label_width - pad * 2;
		getrect.dropdown (
			r,
			string.[ "Color", "Texture", "Normal" ],
			cast (*s32) *shading_mode,
			*dropdown_theme
		);
	}
	r.y -= r.h + pad;

	// Directional light header
	{
		r.x = window_rect.x + pad;
		label_width := simp.prepare_text (g_font, "Directional Light Controls");
		r.w = xx label_width;
		getrect.label (r, "Directional Light Controls", *label_theme);
		
		r.x += label_width;
		defer r.x -= label_width;
	}
	r.y -= r.h + pad;

	// Directional light direction
	{
		// TODO(Oskar): Sliders can take up full width just as dropdowns..
		r.x = window_rect.x + pad;
		r.w = w * 0.1 + xx simp.prepare_text(g_slider_font, " Direction X: 10.000 ");
		getrect.slider(r, *directional_light_direction.x, -1.0, 1.0, directional_light_direction.x, *slider_theme, "Direction X: ", "");
		r.y -= r.h + pad;
		getrect.slider(r, *directional_light_direction.y, -1.0, 1.0, directional_light_direction.y, *slider_theme, "Direction Y: ", "");
		r.y -= r.h + pad;
		getrect.slider(r, *directional_light_direction.z, -1.0, 1.0, directional_light_direction.z, *slider_theme, "Direction Z: ", "");
	}
	r.y -= r.h + pad;

	
	// TODO(Oskar): Make the button open color selection windows
	// hook up colors to be used in the renderer.

	// Directional light ambient color
	{
		r.x = window_rect.x + pad;
		label_width := simp.prepare_text (g_font, "Ambient Color: ");
		r.w = xx label_width;
		getrect.label (r, "Ambient Color: ", *label_theme);
		
		r.x += label_width;
		defer r.x -= label_width;

		r.w = window_rect.w - label_width - pad * 2;
		pressed := getrect.button(r, "Open", *button_theme);

		if pressed {
			directional_light_ambient_subwindow.open = !directional_light_ambient_subwindow.open;
		}
	}
	r.y -= r.h + pad;

	// Directional light diffuse color
	{
		r.x = window_rect.x + pad;
		label_width := simp.prepare_text (g_font, "Diffuse Color: ");
		r.w = xx label_width;
		getrect.label (r, "Diffuse Color: ", *label_theme);
		
		r.x += label_width;
		defer r.x -= label_width;

		r.w = window_rect.w - label_width - pad * 2;
		pressed := getrect.button(r, "Open", *button_theme);

		if pressed {
			directional_light_diffuse_subwindow.open = !directional_light_diffuse_subwindow.open;
		}
	}
	r.y -= r.h + pad;

	// Directional light specular color
	{
		r.x = window_rect.x + pad;
		label_width := simp.prepare_text (g_font, "Specular Color: ");
		r.w = xx label_width;
		getrect.label (r, "Specular Color: ", *label_theme);
		
		r.x += label_width;
		defer r.x -= label_width;

		r.w = window_rect.w - label_width - pad * 2;
		pressed := getrect.button(r, "Open", *button_theme);

		if pressed {
			directional_light_specular_subwindow.open = !directional_light_specular_subwindow.open;
		}
	}
	r.y -= r.h + pad;

	getrect.end_scrollable_region(region, inside.w, r.y, *controls_scroll_value);
}

draw_directional_light_ambient_subwindow :: (state: *getrect.Subwindow_State, window_rect: getrect.Rect, data: *void) {
	using g_params;

	theme_proc := getrect.default_theme_procs[xx getrect.Default_Themes.Bentonite];
	theme = theme_proc();
	getrect.set_default_theme(theme);

	color_picker_theme := *theme.color_picker_theme;
	applied := getrect.color_picker(window_rect, *directional_light_ambient_color, color_picker_theme);
}

draw_directional_light_diffuse_subwindow :: (state: *getrect.Subwindow_State, window_rect: getrect.Rect, data: *void) {
	using g_params;

	theme_proc := getrect.default_theme_procs[xx getrect.Default_Themes.Bentonite];
	theme = theme_proc();
	getrect.set_default_theme(theme);

	color_picker_theme := *theme.color_picker_theme;
	applied := getrect.color_picker(window_rect, *directional_light_diffuse_color, color_picker_theme);
}

draw_directional_light_specular_subwindow :: (state: *getrect.Subwindow_State, window_rect: getrect.Rect, data: *void) {
	using g_params;

	theme_proc := getrect.default_theme_procs[xx getrect.Default_Themes.Bentonite];
	theme = theme_proc();
	getrect.set_default_theme(theme);

	color_picker_theme := *theme.color_picker_theme;
	applied := getrect.color_picker(window_rect, *directional_light_specular_color, color_picker_theme);
}