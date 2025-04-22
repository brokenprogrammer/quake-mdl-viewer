Command_Info :: struct {
    name: string;
    proc: (arguments: []string) -> ();
    arg_count_min: int;
    arg_count_max: int;
}

commands: [..]Command_Info;
commands_init :: () {
    register_commands();
}

command_run :: (info: Command_Info, arguments: []string) {

    argument_string :: (x: int) -> string {
        if x == 1 return "";
        return "s";
    }

    if info.arg_count_min != -1 {
        count := arguments.count;
        if count < info.arg_count_min {
            if info.arg_count_min == info.arg_count_max {
                command_output("Error: '%' requries exactly % argument%.", info.name, info.arg_count_min, argument_string(info.arg_count_min));
                return;
            } else {
                command_output("Error: '%' requries at least % argument%.", info.name, info.arg_count_min, argument_string(info.arg_count_min));
                return;
            }
        } else if count > info.arg_count_max {
            if info.arg_count_min == info.arg_count_max {
                command_output("Error: '%' requries exactly % argument%.", info.name, info.arg_count_max, argument_string(info.arg_count_max));
                return;
            } else {
                command_output("Error: '%' requries at most % argument%.", info.name, info.arg_count_max, argument_string(info.arg_count_max));
                return;
            }
        }
    }

    info.proc(arguments);

}

commands_run :: (line: string) {
    print("Run command: %\n", line);

    remaining := line;
    arguments: [..]string;
    defer array_free(arguments);

    while remaining {
        remaining = eat_spaces(remaining);
        if !remaining break;

        until_next_command: string;
        found: bool;
        was_quote := false;
        if remaining[0] == #char "\"" {
            was_quote = true;
            advance(*remaining, 1);
            until_next_command, found = find_character_from_left(remaining, #char "\"");
        } else {
            until_next_command, found = find_character_from_left(remaining, #char " ");
        }

        if found {
            assert(until_next_command.count > 0);

            advance(*remaining, until_next_command.count);
            array_add(*arguments, until_next_command);
            if was_quote {
                advance(*remaining, 1);
            }
        } else {
            array_add(*arguments, remaining);
            break;
        }
    }

    if !arguments.count return;

    command_name := arguments[0];
    non_command_arguments : []string;

    if arguments.count > 1 {
        non_command_arguments.data = *arguments[1];
        non_command_arguments.count = arguments.count - 1;
    }

    found := false;
    for commands {
        if command_name == it.name {
            if it.proc {
                command_run(it, non_command_arguments);
                found = true;
                break;
            } else {
                print("Command % has no registered procedure!\n", command_name);
            }
        }
    }

    if !found {
        command_output("%: Command not known.", command_name);
    }

    print("Arguments: \n");
    for arguments {
        print("    [%] '%'\n", it_index, it);
    }
}

find_character_from_right :: (s: string, c: int) -> string, bool {
    cursor := s.count - 1;
    while cursor >= 0 {
        if s[cursor] == c return slice(s, cursor, s.count - cursor), true;
        cursor -= 1;
    }
    
    return "", false;
}

find_character_from_left :: (s: string, c :int) -> string, bool {
    cursor := 0;
    while cursor < s.count {
        if s[cursor] == c return slice(s, 0, cursor), true;
        cursor += 1;
    }

    return "", false;
}

command_add :: (name: string, proc: (args: [] string) -> (), 
                arg_count_min: int, arg_count_max: int) {
    info: Command_Info;
    info.name = name;
    info.proc = proc;
    info.arg_count_min = arg_count_min;
    info.arg_count_max = arg_count_max;
    array_add(*commands, info);
}

command_output :: (format: string, args: ..Any) {
    s:= sprint(format, ..args);
    defer free(s);

    console_add_to_history(s);
}

command_help :: () {
    command_output("Here are the available commands: ");
    for commands {
        command_output(it.name);
    }
} @RegisterCommand

command_ls :: (arg: string = "") {
    print("We called ls.\n");
} @RegisterCommand

command_add :: (i0: int, i1: int) {
    result := i0 + i1;
    command_output("% + % = %", i0, i1, result);
} @RegisterCommand

command_quit :: () {
    g_running = false;
} @RegisterCommand

command_load_pak :: (path: string) {
    if contains(path, ".pak") || contains(path, ".PAK") {
        file, file_success := file_open(path);
        if !file_success {
            log("Failed to open pak file.", flags=.ERROR);
            return;
        }

        new_pak_files := load_pak(file);
        for new_pak_files {
            array_add(*g_pak_files, it);
        }

        // TODO(Oskar): g_model_file_names.count is incremented on every load so the number will not be accurate.
        command_output("Loaded pak file containing % files where % are models.", new_pak_files.count, g_model_file_names.count);

        g_params.mdl_names = g_model_file_names;
        array_free(new_pak_files);
    }
    else {
        command_output("Error: Expected a .pak file.");
        return;
    }
} @RegisterCommand

command_list_models :: () {
    command_output("Here are the loaded models that is available for viewing: ");
    for g_model_file_names {
        command_output(it);
    }
} @RegisterCommand

// TODO(Oskar): Split out into general function that can be used by main as well.
command_load_model :: (name: string) {
    for g_pak_files {
        file_name := to_string(it.name.data);
        if contains(file_name, name) {
            if ends_with(file_name, "mdl") {
                // if !g_color_palette_initialized {
                //     g_color_palette = load_mdl_colorpalette(g_pak_files);
                // }

                // TODO(Oskar): There is no cleanup for mdl_model here..
                mdl_model := load_mdl(it, g_pak_files); 
                g_model = model_create_from_mdl(mdl_model);

                array_free(g_params.animation_names);
                g_params.animation_names = model_get_animation_names(g_model);
                g_params.animation_index = 0;

                array_free(g_params.skin_names);
                g_params.skin_names = model_get_skin_names(g_model);
                g_params.skin_index = 0;

                g_params.mdl_index_last_frame = g_params.mdl_index;

                update_buffers(g_model);

                found, mdl_file_index := array_find(g_model_file_names, name);
                if found {
                    g_params.mdl_index = xx mdl_file_index;
	                g_params.mdl_index_last_frame = g_params.mdl_index;
                }
                break;
            } else if ends_with(file_name, "md2") {
                md2_model := load_md2(it, g_pak_files);
                g_model = model_create_from_md2(md2_model);
                md2_model_cleanup(md2_model);

                array_free(g_params.animation_names);
                g_params.animation_names = model_get_animation_names(g_model);
                g_params.animation_index = 0;

                array_free(g_params.skin_names);
                g_params.skin_names = model_get_skin_names(g_model);
                g_params.skin_index = 0;

                g_params.mdl_index_last_frame = g_params.mdl_index;

                update_buffers(g_model);
                
                found, mdl_file_index := array_find(g_model_file_names, name);
                if found {
                    g_params.mdl_index = xx mdl_file_index;
	                g_params.mdl_index_last_frame = g_params.mdl_index;
                }
                break;
            }
        }
    }
} @RegisterCommand