Command_Info :: struct {
    name: string;
    proc: (arguments: []string) -> ();
    arg_count_min: int;
    arg_count_max: int;
}

commands: [..]Command_Info;
commands_init :: () {
    command_add("ls", command_ls, 0, 1);
    command_add("add", command_add_ints, 2, 2);
}

command_run :: (line: string) {
    print("Run command: %\n", line);

    remaining := line;
    arguments: [..]string;
    defer array_free(arguments);

    while remaining {
        remaining = eat_spaces(remaining);
        if !remaining break;

        until_space, found := find_character_from_left(remaining, #char " ");
        if found {
            assert(until_space.count > 0);

            advance(*remaining, until_space.count);
            array_add(*arguments, until_space);
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
                it.proc(non_command_arguments);
                found = true;
                break;
            } else {
                print("Command % has no registered procedure!\n", command_name);
            }
        }
    }

    if !found {
        // Leak
        command_output("%s: Command not known.", command_name);
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

#scope_file

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

command_ls :: (arguments: []string) {
    print("We called ls.\n");
    if arguments.count > 1 {
        command_output("Command takes 0 or 1 arguments."); // Move to metaprogram.
    }
}

command_add_ints :: (arguments: []string) {
    if arguments.count != 2 {
        command_output("Error: 'add' requries exactly two arguments.");
        return;
    }

    i0, success := to_integer(arguments[0]);
    i1 := to_integer(arguments[1]);

    if !success {
        command_output("Error: 'add' requries numeric arguments.");
    }

    result := i0 + i1;
    command_output("% + % = %", i0, i1, result);
}