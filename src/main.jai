find_current_jai_path :: () -> string {
    Compiler :: #import "Compiler";
    options := Compiler.get_build_options();
    for options.import_path {
        if find_index_from_left(it, "jai/modules") != -1 {
            modules_path := remove_trailing_slash(it);
            base_path := remove_trailing_slash(path_strip_filename(modules_path));
            log("% -> %", modules_path, base_path);
            return base_path;
        }
    }

    return "";

    remove_trailing_slash :: (path: string) -> string {
        result := path;
        if path[path.count - 1] == #char "/" result.count -= 1;
        return result;
    }
}

JAI_PATH :: #run find_current_jai_path();
JAI_MODULES_PATH :: #run tprint("%/modules", JAI_PATH);

pool: Pool;

output_file_to_json :: (file_path: string, nodes: []*Node) {
    json_builder: String_Builder;

    append(*json_builder, "[");
    first := true;
    for nodes {
        if first {
            first = false;
        } else {
            append(*json_builder, ",");
        }

        append(*json_builder, to_json(it));
    }
    append(*json_builder, "]");


    out_filename := path_filename(file_path);

    File_Module.write_entire_file(tprint("./out/%.json", out_filename), builder_to_string(*json_builder));
}

main :: () {
    files: Table(string, []*Node);

    cmd_arguments := get_command_line_arguments();
    if cmd_arguments.count < 2 {
        print("You dont provide any file to parse.\n");
        return;
    }
    
    set_allocators(*pool);
    push_allocator(pool_allocator_proc, *pool);

    parse_file(*files, cmd_arguments[1]);

    // for nodes, file: files output_file_to_json(file, nodes);

    release(*pool);

    print("All done!\n");
}

#load "iterator.jai";
#load "tokenizer.jai";
#load "parser.jai";
#load "json_export.jai";

File_Module :: #import "File";
#import "File_Utilities";
#import "Basic";
#import "Hash_Table";
#import "String";
#import "Pool";