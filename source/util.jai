ProjectLoggerData :: struct {
    prefix: string;
    old_context_logger: (string, *void, Log_Info);
    old_context_logger_data: *void;
}

project_logger :: (message: string, data: *void, info: Log_Info) {
    project_logger_data := cast(*ProjectLoggerData)data;
    prefixed_message := tprint("% %", project_logger_data.prefix, message);
    project_logger_data.old_context_logger(prefixed_message, project_logger_data.old_context_logger_data, info);
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