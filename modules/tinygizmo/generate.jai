AT_COMPILE_TIME :: true;

SOURCE_PATH :: "source";
LIB_BASE_NAME :: "tinygizmo";

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
    target_x64     := true;//array_find(args, "-x64");
    target_arm     := array_find(args, "-arm64");
    compile        := true; //array_find(args, "-compile");
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

    // if compile {
    //     source_file: [..]string;
    //     array_add(*source_file, tprint("%/tiny-gizmo.cpp", SOURCE_PATH));
    //     array_add(*source_file, tprint("%/tinygizmo_c.cpp", SOURCE_PATH));

    //     make_directory_if_it_does_not_exist(lib_directory, recursive = true);
    //     lib_path := tprint("%/%", lib_directory, LIB_BASE_NAME);
    //     success := true;
    //     if os_target == .MACOS {
    //         lib_path_x64   := tprint("%_x64", lib_path);
    //         lib_path_arm64 := tprint("%_arm64", lib_path);
    //         macos_x64_version_arg   := "-mmacos-version-min=10.13"; // Our current x64 min version
    //         macos_arm64_version_arg := "-mmacos-version-min=11.0";  // Earliest version that supports arm64
    //         // x64 variant
    //         success &&= build_cpp_dynamic_lib(lib_path_x64,   ..source_file, extra = .["-arch", "x86_64", macos_x64_version_arg],   debug=compile_debug);
    //         success &&= build_cpp_static_lib( lib_path_x64,   ..source_file, extra = .["-arch", "x86_64", macos_x64_version_arg],   debug=compile_debug);
    //         // arm64 variant
    //         success &&= build_cpp_dynamic_lib(lib_path_arm64, ..source_file, extra = .["-arch", "arm64",  macos_arm64_version_arg], debug=compile_debug);
    //         success &&= build_cpp_static_lib( lib_path_arm64, ..source_file, extra = .["-arch", "arm64",  macos_arm64_version_arg], debug=compile_debug);
    //         // create universal binaries
    //         run_result := run_command("lipo", "-create", tprint("%.dylib", lib_path_x64), tprint("%.dylib", lib_path_arm64), "-output", tprint("%.dylib", lib_path));
    //         success &&= (run_result.exit_code == 0);
    //         run_result  = run_command("lipo", "-create", tprint("%.a",     lib_path_x64), tprint("%.a",     lib_path_arm64), "-output", tprint("%.a",     lib_path));
    //         success &&= (run_result.exit_code == 0);
    //     } else {
    //         extra: [..] string;
    //         if os_target == .ANDROID {
    //             _, target_triple_with_sdk := get_android_target_triple(cpu_target);
    //             array_add(*extra, "-target", target_triple_with_sdk);
    //         }
    //         if os_target != .WINDOWS {
    //             array_add(*extra, "-fPIC");
    //         }

    //         if os_target != .PS5 {
    //             success &&= build_cpp_dynamic_lib(lib_path, ..source_file, target = os_target, debug = compile_debug, extra = extra);
    //         }
    //         success &&= build_cpp_static_lib(lib_path, ..source_file, target = os_target, debug = compile_debug, extra = extra);
    //     }

    //     if !success     return false;
    // }

    options: Generate_Bindings_Options;
    options.os = os_target;
    options.cpu = cpu_target;
    {
        using options;

        array_add(*libpaths, lib_directory);
        array_add(*libnames, LIB_BASE_NAME);
        array_add(*source_files, tprint("%/tinygizmo_c.h", SOURCE_PATH));
        array_add(*typedef_prefixes_to_unwrap, "TG_");
        array_add(*extra_clang_arguments, "-x", "c++", "-fms-compatibility", "-fms-extensions");


        generate_library_declarations = false;
        footer = tprint(FOOTER_TEMPLATE, LIB_BASE_NAME);

        auto_detect_enum_prefixes = true;
        log_stripped_declarations = true;
        generate_compile_time_struct_checks = false;
    }

    output_filename := "bindings.jai";
    return generate_bindings(options, output_filename);
}

FOOTER_TEMPLATE :: #string END

#if OS == .WINDOWS {
    %1 :: #library "windows/%1";
} else #if OS == .LINUX {
    %1 :: #library "linux/%1";
} else #if OS == .MACOS {
    %1 :: #library "macos/%1";
} else #if OS == .ANDROID {
    #if CPU == .X64 {
        %1 :: #library "android/x64/%1";
    } else #if CPU == .ARM64 {
        %1 :: #library "android/arm64/%1";
    }
} else #if OS == .PS5 {
    %1 :: #library "ps5/%1";
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