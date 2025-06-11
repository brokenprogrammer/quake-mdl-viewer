ProjectLoggerData :: struct {
    prefix: string;
    old_context_logger: (string, *void, Log_Info);
    old_context_logger_data: *void;
}

project_logger :: (message: string, data: *void, info: Log_Info) {
    project_logger_data := cast(*ProjectLoggerData)data;
    prefixed_message := tprint("% %", project_logger_data.prefix, message);

    if console_initialized {
        sanitized_message := getrect.sanitize(prefixed_message);
        defer free(sanitized_message);
        console_add_to_history(sanitized_message, FROM_LOGGER);
    }

    runtime_support_default_logger(prefixed_message, project_logger_data.old_context_logger_data, info);
}

project_setup_logger :: (prefix: string) -> *ProjectLoggerData {
    project_logger_data := New(ProjectLoggerData);
    project_logger_data.prefix = prefix;
    project_logger_data.old_context_logger = context.logger;
    project_logger_data.old_context_logger_data = context.logger_data;

    context.logger = project_logger;
    context.logger_data = project_logger_data;

    return project_logger_data;
}

project_cleanup_logger :: (project_logger_data: *ProjectLoggerData) {
    context.logger      = project_logger_data.old_context_logger;
    context.logger_data = project_logger_data.old_context_logger_data;
    free(project_logger_data);
}

// Strip directory path from filename, keeping only the filename portion
// Handles both forward slashes and backslashes
strip_path :: (path: string) -> string {
    if path.count == 0 return path;
    
    // Find the last occurrence of either separator
    found_forward, left_forward, filename_forward := split_from_right(path, "/");
    found_back, left_back, filename_back := split_from_right(path, "\\");
    
    // Use whichever separator was found last (rightmost)
    if found_forward && found_back {
        // Both found, use the one that occurs later in the string
        if left_forward.count > left_back.count {
            return filename_forward;
        } else {
            return filename_back;
        }
    } else if found_forward {
        return filename_forward;
    } else if found_back {
        return filename_back;
    }
    
    // No separators found, return original string
    return path;
}

// Strip file extension from filename, keeping only the name portion
// Examples: "texture.pcx" -> "texture", "model.md2" -> "model"
strip_extension :: (filename: string) -> string {
    if filename.count == 0 return filename;
    
    // Find the last dot in the filename
    found, left, right := split_from_right(filename, ".");
    
    if found {
        return left;
    }
    
    // No extension found, return original string
    return filename;
}