scroll_value: float = 0.0;
string_a: string;
console_messages: [..]string;

openness_max := 0.7;

open_t := 0.0;
open_t_target := 0.0;
dopen_dt := 7.0;

console_x0 := 0.0;
console_x1 := 1.0;
console_y_b := 0.7;

Console_Open_State :: enum {
    CLOSED;
    OPEN_SMALL;
    OPEN_BIG;
};

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

    if open_t < open_t_target {
        open_t += dopen;
        if open_t > open_t_target open_t = open_t_target;
    } else if open_t > open_t_target {
        open_t -= dopen;
        if open_t < 0 open_t = 0;
    }
}

console_is_open :: () -> bool {
    return open_t_target > 0.0;
} 

console_open_or_close :: (extent: Console_Open_State) {
    if extent == .CLOSED {
        open_t_target = 0;
    } else if extent == .OPEN_SMALL {
        open_t_target = 1;
    } else if extent == .OPEN_BIG {
        open_t_target = 3;
    } else {
        // Should not hit here.
        open_t_target = 1;
    }

    // NOTE(Oskar): So that if we open the console and start typing during the same frame there won't be 1 frame of lag.
    console_update_openness(0.01667);
}

console_add_to_history :: (s: string) {
    array_add(*console_messages, copy_string(s));
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
        
        // NOTE(Oskar): To also hide the text input
        r.y += pad;
    
        region, inside := getrect.begin_scrollable_region(r, *scrollable_region_theme);
        {
            s := inside;
            s.x = 0.0;
            s.h = pad;
            s.y -= scroll_value;

            top_y := s.y;
            bottom_y := s.y;
            
            if open_t > 0.0
            {
                for #v2 < 0..console_messages.count - 1 {
                    getrect.label(s, console_messages[it], *theme.label_theme);
                    bottom_y = s.y;
                    s.y += pad;
                }
            }
            
            s.h = top_y - bottom_y;
            getrect.end_scrollable_region(region, s.x + s.w, -s.y, *scroll_value);
        }
    }

    r.y -= pad;

    // Input
    {
        text_input_theme := theme.text_input_theme;
        text_input_theme.deactivate_on_enter = false;
        text_input_theme.button_theme.rectangle_shape.roundedness = 0;

        r.h = pad;
        action_a, new_text_a, text_input_state := getrect.text_input(r, string_a, *text_input_theme);
         if action_a & .ENTERED {
            s := copy_string(new_text_a);
            array_add(*console_messages, s);
            getrect.clear_text(text_input_state);

            commands_run(s);
        }
    }
}