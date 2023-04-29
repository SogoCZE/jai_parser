#import "Basic";
#import "Compiler";
#import "File";
#import "String";
#import "Process";

// Základní build file
#run {
    w := compiler_create_workspace("Target Program");
    if !w {
        print("Workspace creation failed.\n");
        return;
    }

    options := get_build_options(w);
    options.output_executable_name = "jai_parser";
    options.output_path = "./bin";   
    
    import_path: [..]string;
    for options.import_path array_add(*import_path, it);
    array_add(*import_path, "./modules");
    options.import_path = import_path;

    set_build_options(options, w);

	make_directory_if_it_does_not_exist("./bin/");

    // compiler_begin_intercept(w);

    add_build_file("./src/main.jai", w); 

    // compiler_end_intercept(w);

    set_build_options_dc(.{do_output=false});
}