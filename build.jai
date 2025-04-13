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

generate_code_for_commands :: (w: Workspace) {
    lines: String_Builder;
    append(*lines, "register_commands :: () {\n");
    
    to_chop := "command_";
    for commands_to_register {

        for it.arguments {
            print("%: %\n", it.name, it.type_inst.result.type);
        }

        min_args := it.arguments.count;
        max_args := it.arguments.count;
        command_name := it.name;
        if starts_with(command_name, to_chop) {
            advance(*command_name, to_chop.count);
        }

        print_to_builder(*lines, "command_add(\"%\", front_%, %, %);\n",
                        command_name, it.name, min_args, max_args);
    }

    append(*lines, "}\n");

    result := builder_to_string(*lines);
    print(result);

    add_build_string(result, w);
}

#import "Basic";
#import "File";
#import "File_Utilities";
#import "String";