g_params : struct {
    mdl_names: []string;
    mdl_index: s32;
	animation_time := 0.0;
	animation_speed_in_fps := 30.0;
};

update_ui :: (delta_time: float) {
    using g_params;

    glDisable (GL_DEPTH_TEST);
	glDepthMask (GL_FALSE);

    simp.set_shader_for_color ();
	current_time := to_float64_seconds (current_time_monotonic ());
    w, h := simp.get_render_dimensions (g_window);
	getrect.ui_per_frame_update (g_window, w, h, current_time);

    // Init themes
	label_theme : getrect.Label_Theme;
	label_theme.font = g_font;
	checkbox_theme : getrect.Checkbox_Theme;
	checkbox_theme.font = g_checkbox_font;
	slider_theme : getrect.Slider_Theme;
	slider_theme.foreground.font = g_slider_font;
	dropdown_theme := getrect.default_overall_theme.dropdown_theme;
	dropdown_theme.theme_for_current_value.font = g_dropdown_font;
	dropdown_theme.theme_for_each_choice.font = g_dropdown_font;
	dropdown_theme.theme_for_current_choice.font = g_dropdown_font;

    k := g_current_window_height / 45.0;
	pad := cast (float) g_font.character_height * 1.6;
	dropdown_offset := w * 0.1;
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
		getrect.dropdown (
			r,
			mdl_names,
			*mdl_index,
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
	// Animation time slider
	{
		sample_count := 0;
		// if animation_index > 0
		// {
		// 	anim := table_find_pointer (*g_loaded_animations, animation_names[animation_index]);
		// 	sample_count = anim.sample_count;
		// }
		text := tprint ("Animation Time: %.00", sample_count);
		r.w = w * 0.1 + xx simp.prepare_text (g_slider_font, text);
		getrect.slider (r, *animation_time, 0.0, xx sample_count, 1.0, *slider_theme, "Animation Time: ", "");
	}

    getrect.draw_popups ();
}