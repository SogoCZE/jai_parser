get_process_result :: (process: *Process, timeout_ms := -1) -> success: bool, Process_Result {
    return true, .{type=.UNSTARTED};
}