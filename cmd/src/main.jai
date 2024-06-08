get_import_paths :: () -> []string {
    Compiler :: #import "Compiler";
    options := Compiler.get_build_options();

    paths: [..]string;

    for options.import_path
        array_add(*paths, trim_right(it, "/"));

    print("Import path is: %", paths);

    return paths;
}

IMPORT_PATHS :: #run get_import_paths();

get_module_entry :: (root: string) -> string {
    for IMPORT_PATHS{
        uri := tprint("%/%/module.jai", it, root);
        
        if file_exists(uri)
            return uri;

        uri = tprint("%/%.jai", it, root);
        
        if file_exists (uri)
            return uri;
    }

    return root;
}

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

Files :: Table(string, []*Node);

Node_Visit_Data :: struct {
    path_without_filename: string;
    files: *Files;
}

// @TODO: remove this
total_nodes: int;

node_visit :: (node: *Node, data: Node_Visit_Data) {

    // @TODO: remove this
    total_nodes += 1;

    if node.kind == .DIRECTIVE_IMPORT {
        _import := cast(*Directive_Import) node;

        path: string;

        if _import.import_kind == {
            case .MODULE;
                path = get_module_entry(_import.module);
            case .FILE;
                path = tprint("%/%", data.path_without_filename, _import.module); 
            case .DIR;
                path = tprint("%/%", data.path_without_filename, get_module_entry(_import.module)); 
            case .STRING;
                // @TODO: Do we wanna parse the string here?
        }

        parse_file(data.files, path); // @TODO: Run this in another thread?
    }

    if node.kind == .DIRECTIVE_LOAD {
        _load := cast(*Directive_Load) node;
        load_relative_path := tprint("%/%", data.path_without_filename, _load.file);
        parse_file(data.files, load_relative_path); // @TODO: Run this in another thread?
    }
}

parse_file :: (files: *Files, path: string) {
    if table_contains(files, path) {
        log("Skipping % because it already exists", path);
        return;
    }

    path_without_filename := trim_right(path_strip_filename(path), "/");

    parser: Parser(Node_Visit_Data);
    parser.user_data = .{
        files=files,
        path_without_filename=path_without_filename,
    };
    parser.node_visit = node_visit;
    parser.lexer = *create_lexer(File_Module.read_entire_file(path), path);

    nodes: [..]*Node;

    table_set(files, path, nodes);

    while !end(parser.lexer) {
        node := parse(*parser, null);
        if !node continue;
        array_add(*nodes, node);
    }

    table_set(files, path, nodes);
}

main :: () {
    start := current_time_consensus();

    files: Table(string, []*Node);
    cmd_arguments := get_command_line_arguments();

    if cmd_arguments.count < 2 {
        print("You dont provide any file to parse.\n");
        return;
    }

    set_allocators(*pool);
    push_allocator(pool_allocator_proc, *pool);

    parse_file(*files, cmd_arguments[1]);


    end := current_time_consensus();
    duration_ms := to_milliseconds(end - start);

    print("Parsed % files (total nodes: %, total tokens: %) in %ms\n", files.count, total_nodes, total_tokens, duration_ms);

	File_Module.make_directory_if_it_does_not_exist("./out");

    for nodes, file: files output_file_to_json(file, nodes);

    print("All done!\n");

    release(*pool);
 
}

#load "json_export.jai";

#import,dir "../../../jai_parser";

File_Module :: #import "File";
#import "File_Utilities";
#import "Basic";
#import "Hash_Table";
#import "String";
#import "Pool";