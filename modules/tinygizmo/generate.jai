AT_COMPILE_TIME :: true;

SOURCE_PATH :: "source";
MODULE_NAME :: "tiny_gizmo";
LIB_BASE_NAME :: "tiny-gizmo";

#if AT_COMPILE_TIME {
    #run,stallable {
        set_build_options_dc(.{do_output=false});
        options := get_build_options();
        args := options.compile_time_command_line;
        if !generate_bindings(args, options.minimum_os_version) {
            compiler_set_workspace_status(.FAILED);
        }
    }
} else {
    #import "System";

    main :: () {
        set_working_directory(path_strip_filename(get_path_of_running_executable()));
        if !generate_bindings(get_command_line_arguments(), #run get_build_options().minimum_os_version) {
            exit(1);
        }
    }
}

generate_bindings :: (args: [] string, minimum_os_version: type_of(Build_Options.minimum_os_version)) -> bool {
    target_android := array_find(args, "-android");
    target_x64     := array_find(args, "-x64");
    target_arm     := array_find(args, "-arm64");
    compile        := array_find(args, "-compile");
    compile_debug  := array_find(args, "-debug");

    os_target  := OS;
    cpu_target := CPU;
    if target_android os_target  = .ANDROID;
    if target_x64     cpu_target = .X64;
    if target_arm     cpu_target = .ARM64;

    lib_directory: string;
    if os_target == {
        case .WINDOWS;
            lib_directory = "windows";
        case .LINUX;
            lib_directory = "linux";
        case .MACOS;
            lib_directory = "macos";
        case .ANDROID;
            lib_directory = ifx cpu_target == .X64 then "android/x64" else "android/arm64";
        case .PS5;
            lib_directory = "ps5";
        case;
            assert(false);
    }

    options: Generate_Bindings_Options;
    options.os = os_target;
    options.cpu = cpu_target;
    {
        using options;

        array_add(*libpaths, lib_directory);
        array_add(*libnames, LIB_BASE_NAME);
        array_add(*source_files, tprint("%/tiny-gizmo-c.h", SOURCE_PATH));
        array_add(*typedef_prefixes_to_unwrap, "TG_");

        generate_library_declarations = false;
        footer = tprint(FOOTER_TEMPLATE, MODULE_NAME, LIB_BASE_NAME);

        auto_detect_enum_prefixes = true;
        log_stripped_declarations = true;
        generate_compile_time_struct_checks = false;
    }

    output_filename := "bindings.jai";
    return generate_bindings(options, output_filename);
}

FOOTER_TEMPLATE :: #string END

#if OS == .WINDOWS {
    %1 :: #library "windows/%2";
} else #if OS == .LINUX {
    %1 :: #library "linux/%2";
} else #if OS == .MACOS {
    %1 :: #library "macos/%2";
} else #if OS == .ANDROID {
    #if CPU == .X64 {
        %1 :: #library "android/x64/%2";
    } else #if CPU == .ARM64 {
        %1 :: #library "android/arm64/%2";
    }
} else #if OS == .PS5 {
    %1 :: #library "ps5/%2";
} else {
    #assert false;
}

END

#import "Basic";
#import "Bindings_Generator";
#import "BuildCpp";
#import "Compiler";
#import "File";
#import "Process";
#import "Toolchains/Android";