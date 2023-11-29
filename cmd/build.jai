TRACY_PROFILE :: false;

// Basic build file
#run {
    w := compiler_create_workspace("Target Program");
    if !w {
        print("Workspace creation failed.\n");
        return;
    }


    options := get_build_options(w);
    options.output_executable_name = "jai_parser";
    options.output_path = "./bin";   
    options.use_natvis_compatible_types = true;   

    // set_optimization(*options, .OPTIMIZED);

    tracy: *Metaprogram_Plugin;
    #if TRACY_PROFILE {
        log("Adding tracy plugin");
        Tracy :: #import "tracy";
        tracy = Tracy.get_plugin();
        tracy.workspace = w;

        assert(tracy.handle_one_option != null);
        tracy.handle_one_option(tracy, .["-modules"], 0);
        tracy.handle_one_option(tracy, .["-min_size", "0"], 0);
    }

    import_path: [..]string;
    for options.import_path array_add(*import_path, it);
    array_add(*import_path, "./modules");
    options.import_path = import_path;

    set_build_options(options, w);

	make_directory_if_it_does_not_exist("./bin/");

    flags: Intercept_Flags;
    if tracy && tracy.before_intercept tracy.before_intercept(tracy, *flags);

    compiler_begin_intercept(w);

    if tracy && tracy.add_source tracy.add_source(tracy);
    add_build_file("./src/main.jai", w); 

    message_loop(w, tracy);

    compiler_end_intercept(w);

    if tracy && tracy.finish tracy.finish(tracy);
    if tracy && tracy.shutdown tracy.shutdown(tracy);

    set_build_options_dc(.{do_output=false});
}

message_loop :: (w: Workspace, tracy: *Metaprogram_Plugin) {
    while true {
        message := compiler_wait_for_message();
        if tracy && tracy.message tracy.message(tracy, message);
        if message.kind != .COMPLETE continue;

        complete := cast(*Message_Complete) message;
        if complete.error_code != .NONE {
            return;
        }

        break;
    }
}

#import "Basic";
#import "Compiler";
#import "File";
#import "String";
#import "Process";