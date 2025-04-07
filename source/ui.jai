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
	rotate := false;
	show_animation := true;
	show_normals := false;
	interpolation_mode := Interpolation_Mode.LINEAR; // TODO(Oskar): Implement this later.
	shading_mode := Shading_Mode.TEXTURE;
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

    k := g_current_window_height / 45.0;
	pad := cast (float) g_font.character_height * 1.6;
	dropdown_offset := w * 0.15;
	dropdown_width  := w * 0.2;
	r := getrect.get_rect (
		k, h - k * 2,
		k, xx g_font.character_height
	);

    // Model selection
	{
		r.w = xx simp.prepare_text (g_font, "Model: ");
		getrect.label (r, "Model: ", *label_theme);
		r.x += dropdown_offset;
		defer r.x -= dropdown_offset;
		r.w = dropdown_width;
		getrect.scrollable_dropdown (
			r,
			mdl_names,
			*mdl_index,
			*mdl_scroll_value,
			*dropdown_theme
		);
	}
	r.y -= pad;
	// Animation selection
	{
		r.w = xx simp.prepare_text (g_font, "Animation: ");
		getrect.label (r, "Animation: ", *label_theme);
		r.x += dropdown_offset;
		defer r.x -= dropdown_offset;
		r.w = dropdown_width;
		getrect.dropdown (
			r,
			animation_names,
			*animation_index,
			*dropdown_theme
		);
	}
	r.y -= pad;
	// Skin selection
	{
		r.w = xx simp.prepare_text (g_font, "Skin: ");
		getrect.label (r, "Skin: ", *label_theme);
		r.x += dropdown_offset;
		defer r.x -= dropdown_offset;
		r.w = dropdown_width;
		getrect.dropdown (
			r,
			skin_names,
			*skin_index,
			*dropdown_theme
		);
	}
	r.y -= pad;
	// Animation speed slider
	{
		r.w = w * 0.1 + xx simp.prepare_text (g_slider_font, "Animation Speed: 120.00 FPS");
		getrect.slider (r, *animation_speed_in_fps, 0.0, 120.0, 1.0, *slider_theme, "Animation Speed: ", "FPS");
	}
	r.y -= pad;

	if g_model.animations.count > 0 &&
		g_model.animations[animation_index].frames.count > 1 {
		// Animation time slider
		{
			sample_count := g_model.animations[animation_index].frames.count / 1.0;
			text := tprint ("Animation Time: %.00", sample_count);
			r.w = w * 0.1 + xx simp.prepare_text (g_slider_font, text);
			getrect.slider (r, *animation_time, 0.0, xx sample_count, 1.0, *slider_theme, "Animation Time: ", "");
		}
		r.y -= pad;
	}

	// Perform Rotation checkbox
	{
		r.w = r.h + xx simp.prepare_text (g_checkbox_font, "Rotate");
		pressed := getrect.base_checkbox (r, "Rotate", rotate, *checkbox_theme);
		rotate ^= pressed;
	}
	r.y -= pad;
	// Show Normals checkbox
	{
		r.w = r.h + xx simp.prepare_text (g_checkbox_font, "Show Normals");
		pressed := getrect.base_checkbox (r, "Show Normals", show_normals, *checkbox_theme);
		show_normals ^= pressed;
	}
	r.y -= pad;
	// Shading mode
	{
		r.w = xx simp.prepare_text (g_font, "Shading Mode: ");
		getrect.label (r, "Shading Mode: ", *label_theme);
		r.x += dropdown_offset;
		defer r.x -= dropdown_offset;
		r.w = dropdown_width;
		getrect.dropdown (
			r,
			string.[ "Color", "Texture", "Normal" ],
			cast (*s32) *shading_mode,
			*dropdown_theme
		);
	}

    getrect.draw_popups ();
}