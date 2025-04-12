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
    compiler_message_loop();
    compiler_end_intercept(w);

    set_build_options_dc(.{do_output=false});
    
    copy_directory("data/", tprint("%/data/", RESOURCE_OUTPUT_DIRECTORY_NAME));
}

commands_to_register: [..]string;
compiler_message_loop :: () {
    while true {
        message := compiler_wait_for_message();
        if message.kind == .COMPLETE {
            break;
        }
        if message.kind == .TYPECHECKED {
            tc := cast(*Message_Typechecked) message;
            for tc.declarations {
                decl := it.expression;

                for decl.notes {
                    if it.text == "RegisterCommand" {
                        array_add(*commands_to_register, decl.name);
                    }
                }
            }
        } else if message.kind == .PHASE {
            phase := cast(*Message_Phase) message;
            if phase.phase == .TYPECHECKED_ALL_WE_CAN  {
                print("Number of commands: %\n", commands_to_register.count);
                for commands_to_register {
                    print("Register command: '%'\n", it);
                }
            }
        }
    }
}

#import "Basic";
#import "File";
#import "File_Utilities";