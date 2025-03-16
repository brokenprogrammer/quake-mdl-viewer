#load "source/main.jai";

OUTPUT_EXECUTABLE_NAME := "quake_mdl_viewer";
OUTPUT_DIRECTORY_NAME := "build";
RESOURCE_OUTPUT_DIRECTORY_NAME := "build";


#run {
    make_directory_if_it_does_not_exist(OUTPUT_DIRECTORY_NAME, recursive = true);

    Compiler :: #import "Compiler";
    Compiler.set_build_options_dc(.{output_path="build", output_executable_name=OUTPUT_EXECUTABLE_NAME});

    copy_directory("data/", tprint("%/data/", RESOURCE_OUTPUT_DIRECTORY_NAME));
}

#import "Basic";
#import "File";
#import "File_Utilities";