#scope_file

console_input_state: *getrect.Text_Input_State;

console_scroll_value: float = 0.0;
console_input_string: string;

History_Line :: struct {
    Line_Flags :: enum {
        NO_FLAGS    :: 0x0;
        FROM_USER   :: 0x1;
        FROM_LOGGER :: 0x2;
    };

    text: string;
    continued := false;
    flags: Line_Flags;
};
console_history: [..]History_Line;

console_open_t_target := 0.0;

modify_string :: (ps: *string, new_value: string) {
    free(ps.*);
    ps.* = copy_string(new_value);
}

console_get_bottom :: (height: float) -> float {
    l := lerp(1.0, console_y_b, open_t);
    return l * (height); 
}

console_update_openness :: (delta_time: float) {
    dopen := delta_time * dopen_dt;

    if open_t < console_open_t_target {
        open_t += dopen;
        if open_t > console_open_t_target open_t = console_open_t_target;
    } else if open_t > console_open_t_target {
        open_t -= dopen;
        if open_t < 0 open_t = 0;
    }
}

get_m_width :: (font: *simp.Dynamic_Font) -> int {
    m := "M";
    M_width := cast(int) simp.prepare_text(g_font, m);
    return M_width;
}

#scope_export
using History_Line.Line_Flags;
console_initialized := false;

Console_Visuals :: struct {
    dopen_dt := 7.0;
    open_t := 0.0;
    
    console_x0 := 0.0;
    console_x1 := 1.0;
    console_y_b := 0.7;
};

using console_visuals: Console_Visuals;

Console_Open_State :: enum {
    CLOSED;
    OPEN_SMALL;
    OPEN_BIG;
};

console_is_open :: () -> bool {
    return console_open_t_target > 0.0;
} 

console_open_or_close :: (extent: Console_Open_State) {
    if extent == .CLOSED {
        console_open_t_target = 0;

        // NOTE(Oskar): Deactivate widget
        if console_input_state && console_input_state.active {
            getrect.active_widget_remove(console_input_state);
        }

    } else if extent == .OPEN_SMALL {
        console_open_t_target = 1;
        
        // NOTE(Oskar): Give text_input focus
        if console_input_state && !console_input_state.active {
            getrect.activate(console_input_state);
        }

    } else if extent == .OPEN_BIG {
        console_open_t_target = 3;
        
        // NOTE(Oskar): Give text input focus
        if console_input_state && !console_input_state.active {
            getrect.activate(console_input_state);
        }

    } else {
        // Should not hit here.
        console_open_t_target = 1;
    }

    // NOTE(Oskar): So that if we open the console and start typing during the same frame there won't be 1 frame of lag.
    console_update_openness(0.01667);
}

console_initialize :: () {
    console_initialized = true;
}

console_add_to_history :: (_s: string, flags := NO_FLAGS) {
    s := _s;
    w, h := simp.get_render_dimensions (g_window);

    x1 := console_x1 * w;
    x0 := console_x0 * w;

    // TODO(Oskar): This should be moved out to state
    theme_proc := getrect.default_theme_procs[xx getrect.Default_Themes.Bentonite];
	theme := theme_proc();
    scrollable_region_theme := theme.scrollable_region_theme;
    scrollbar_size := floor(scrollable_region_theme.scrollbar_size * w + 0.5) * 2.5;
    margin_x := floor(scrollable_region_theme.horizontal_margin_size * w + .5) * 2;

    M_width := get_m_width(g_font);

    continued := false;
    while s {
        text_width := cast(float) simp.prepare_text(g_font, s);
        console_width := x1 - x0;
        console_width -= scrollbar_size;
        console_width -= margin_x;
        
        // NOTE(Oskar): Make room to indent.
        if continued console_width -= M_width;

        if text_width <= console_width {
            console_add_single_line_to_history(s, flags, continued);
            break;
        }

        subtext := s;
        found := false;
        for 0..s.count {
            subtext.count = it;
            text_width := cast(float) simp.prepare_text(g_font, subtext);

            if text_width > console_width {
                found = true;
                break;
            }
        }

        assert(found);
        subtext.count -= 1;
        console_add_single_line_to_history(subtext, flags, continued);
        advance(*s, subtext.count);
        continued = true;
    }
}

console_add_single_line_to_history :: (s: string, flags: History_Line.Line_Flags , continued := false) {
    line : History_Line;
    line.flags = flags;
    line.text = copy_string(s);
    line.continued = continued;
    array_add(*console_history, line);
}

update_console :: (delta_time: float) {
    console_update_openness(delta_time);

    theme_proc := getrect.default_theme_procs[xx getrect.Default_Themes.Bentonite];
	theme := theme_proc();
	getrect.set_default_theme(theme);

    simp.set_shader_for_color ();

    w, h := simp.get_render_dimensions (g_window);

    pad := cast (float) g_font.character_height * 1.6;

    x0 := console_x0 * w;
    x1 := console_x1 * w;

    y0 := console_get_bottom(xx h);
    y1 := cast(float) h - y0;

    r := getrect.get_rect(x0, y0, x1, y1);

    // Scrollable console history view.
    {
        scrollable_region_theme := theme.scrollable_region_theme;
        scrollable_region_theme.region_background.shape.roundedness = 0;
        scrollable_region_theme.horizontal_margin_size = 0.0;
        scrollable_region_theme.vertical_margin_size = 0.0;

        user_label_theme := theme.label_theme;
        user_label_theme.text_color = user_label_theme.text_color;
        user_label_theme.alignment = getrect.Text_Alignment.Left;

        non_user_label_theme := theme.label_theme;
        non_user_label_theme.text_color = Vector4.{255.0/255, 255.0/255, 0.0, 1.0};
        non_user_label_theme.alignment = getrect.Text_Alignment.Left;

        logger_label_theme := theme.label_theme;
        logger_label_theme.text_color = Vector4.{64.0/255, 224.0/255, 208.0/255, 1.0};
        logger_label_theme.alignment = getrect.Text_Alignment.Left;

        // NOTE(Oskar): To also hide the text input
        r.y += pad;

        region, inside := getrect.begin_scrollable_region(r, *scrollable_region_theme);
        {
            s := inside;
            s.x = 0.0;
            s.h = pad;
            s.y -= console_scroll_value;

            top_y := s.y;
            bottom_y := s.y;
            M_width := get_m_width(g_font);
            
            if open_t > 0.0
            {
                for #v2 < 0..console_history.count - 1 {
                    x_offset := 0.0;
                    if console_history[it].continued  {
                        x_offset = xx M_width;
                    }

                    label_rect := s;
                    label_rect.x += x_offset;
                    
                    if ((console_history[it].flags & FROM_USER)) {
                        getrect.label(label_rect, console_history[it].text, *user_label_theme);
                    } else if (console_history[it].flags & FROM_LOGGER) {
                        getrect.label(label_rect, console_history[it].text, *logger_label_theme);
                    } else {
                        getrect.label(label_rect, console_history[it].text, *non_user_label_theme);
                    }
                    bottom_y = s.y;
                    s.y += pad;
                }
            }
            
            s.h = top_y - bottom_y;
            getrect.end_scrollable_region(region, s.x + s.w, -s.y, *console_scroll_value);
        }
    }

    r.y -= pad;

    // Input
    {
        text_input_theme := theme.text_input_theme;
        text_input_theme.deactivate_on_enter = false;
        text_input_theme.button_theme.rectangle_shape.roundedness = 0;

        r.h = pad;

        text_input_action, text_input_text, text_input_state := getrect.text_input(r, console_input_string, *text_input_theme);
        console_input_state = text_input_state;

        if text_input_action & .ENTERED {
            console_add_to_history(text_input_text, FROM_USER);
            commands_run(text_input_text);

            getrect.clear_text(text_input_state);
        }
    }
}