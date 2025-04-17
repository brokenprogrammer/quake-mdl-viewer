OUTPUT_EXECUTABLE_NAME := "quake_mdl_viewer";
OUTPUT_DIRECTORY_NAME := "build";
RESOURCE_OUTPUT_DIRECTORY_NAME := "build";

#run {
    make_directory_if_it_does_not_exist(OUTPUT_DIRECTORY_NAME, recursive = true);

    #import "Compiler";

    w := compiler_create_workspace("Target Program");
    if !w {
        print("Workspace creation failed.\n");
        return;
    }

    options := get_build_options(w);
    options.output_executable_name = OUTPUT_EXECUTABLE_NAME;
    options.output_path = OUTPUT_DIRECTORY_NAME;
    options.output_type            = .EXECUTABLE;
    options.arithmetic_overflow_check = .FATAL;
    options.null_pointer_check = .ON;
    options.array_bounds_check = .ALWAYS;
    set_optimization(*options, .DEBUG);
    set_build_options(options, w);

    compiler_begin_intercept(w);
    add_build_file("source/main.jai", w);
    compiler_message_loop(w);
    compiler_end_intercept(w);

    set_build_options_dc(.{do_output=false});
    
    copy_directory("data/", tprint("%/data/", RESOURCE_OUTPUT_DIRECTORY_NAME));
}

did_register_commands := false;
commands_to_register: [..]Code_Procedure_Header;

compiler_message_loop :: (w: Workspace) {
    while true {
        message := compiler_wait_for_message();
        if message.kind == .COMPLETE {
            break;
        }
        if message.kind == .TYPECHECKED {
            tc := cast(*Message_Typechecked) message;
            for tc.procedure_headers  {
                decl := it.expression;

                for decl.notes {
                    if it.text == "RegisterCommand" {
                        array_add(*commands_to_register, decl);
                    }
                }
            }
        } else if message.kind == .PHASE {
            phase := cast(*Message_Phase) message;
            if phase.phase == .TYPECHECKED_ALL_WE_CAN  {

                if did_register_commands == false {
                    generate_code_for_commands(w);
                    did_register_commands = true;
                }
            }
        }
    }
}

Command_Info :: struct {
    decl: Code_Procedure_Header;
    min_args: int;
    max_args: int;
}

generate_code_for_commands :: (w: Workspace) {
    lines: String_Builder;

    // NOTE(Oskar): First we register register commands. 
    append(*lines, "register_commands :: () {\n");
    
    command_infos: [..]Command_Info;
    to_chop := "command_";
    for commands_to_register {
        min_args := it.arguments.count;
        max_args := it.arguments.count;

        for it.arguments {
            // Check if have default argument or not. If expression has a value it has default argument.
            if (it.expression) {
                min_args -= 1;
                print("Default argument: %: %\n", it.name, it.type_inst.result.type);
            } else {
                print("Non default argument: %: %\n", it.name, it.type_inst.result.type);
            }
        }

        command_name := it.name;
        if starts_with(command_name, to_chop) {
            advance(*command_name, to_chop.count);
        }

        print_to_builder(*lines, "command_add(\"%\", front_%, %, %);\n",
                        command_name, it.name, min_args, max_args);

        info: Command_Info;
        info.decl = it;
        info.min_args = min_args;
        info.max_args = max_args;
        array_add(*command_infos, info);
    }

    append(*lines, "}\n\n");

    // NOTE(Oskar): Generate front functions for each command used to validate arguments.
    for info: command_infos {
        decl := info.decl;

        // Header
        print_to_builder(*lines, "\nfront_% :: (arguments: []string) {\n", decl.name);
        
        // Typechecking
        {
            // Declare the variables.
            for i: 0..info.max_args - 1 {
                arg_type := decl.arguments[i].type_inst.result.type;

                if arg_type == .INTEGER {
                    // TODO(Oskar): error handling.
                    print_to_builder(*lines, "    i% : int = ---;\n", i);
                } else if arg_type == .STRING {
                    print_to_builder(*lines, "    i% : string = ---;\n", i);
                } else {
                    location := make_location(decl.arguments[i]);
                    error_message := sprint("Error: Procedure argument % is of a type that is not handled yet by command registration.", i);
                    compiler_report(location.fully_pathed_filename, location.line_number, location.character_number, error_message);
                }
            }

            // Assign the variables.
            for i: 0..info.max_args - 1 {
                arg_type := decl.arguments[i].type_inst.result.type;

                inner: string;
                if arg_type == .INTEGER {
                    // TODO(Oskar): error handling.
                    inner = sprint("to_integer(arguments[%])", i);
                } else if arg_type == .STRING {
                    inner = sprint("arguments[%]", i);
                }

                if i >= info.min_args {
                    print_to_builder(*lines, "    if arguments.count > % { i% = %; }\n", i, i, inner);
                } else {
                    print_to_builder(*lines, "    i% = %;\n", i, inner);
                }
            }
        }

        append(*lines, "\n");

        // Call the non-front proc
        {
            get_proc_call_string :: (args: int) -> string {
                arg_strings: [..]string;
                for i: 0..args - 1 {
                    // We xx all arguments so we can pass int to u8. Just lazy way to do it, later we should detect oveflows etc.
                    array_add(*arg_strings, sprint("xx i%", i));
                    if i != args - 1 array_add(*arg_strings, ", ");
                }

                // arg_string := ..arg_strings;
                return join(..arg_strings);
            }

            if info.min_args == info.max_args {
                arg_string := get_proc_call_string(info.max_args);
                print_to_builder(*lines, "    %(%);\n", decl.name, arg_string);
            } else {
                for i: info.min_args..info.max_args {
                    arg_string := get_proc_call_string(i);
                    line := sprint("    if arguments.count == % { %(%); }\n", i, decl.name, arg_string);
                    append(*lines, line);
                }
            }
        }

        // Tail
        append(*lines, "}\n\n");
    }

    result := builder_to_string(*lines);
    print(result);

    add_build_string(result, w);
}

#import "Basic";
#import "File";
#import "File_Utilities";
#import "String";