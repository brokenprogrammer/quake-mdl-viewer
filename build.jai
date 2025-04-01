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

    set_build_options_dc(.{do_output=false});

    add_build_file("source/main.jai", w);

    copy_directory("data/", tprint("%/data/", RESOURCE_OUTPUT_DIRECTORY_NAME));
}

#import "Basic";
#import "File";
#import "File_Utilities";