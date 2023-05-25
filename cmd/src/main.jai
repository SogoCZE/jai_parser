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

get_module_entry :: (root: string) -> string {
    uri := tprint("%/module.jai", root);
    if !file_exists(uri) {
        uri = tprint("%.jai", root);
    }

    return uri;
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

node_visit :: (node: *Node, data: Node_Visit_Data) {

    if node.kind == .DIRECTIVE_IMPORT {
        _import := cast(*Directive_Import) node;

        path: string;

        if _import.import_kind == {
            case .MODULE;
                module_path := tprint("%/%", JAI_MODULES_PATH, _import.module);
                path = get_module_entry(module_path);
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
    print("Parsing file %...\n", path);

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
    files: Table(string, []*Node);
    cmd_arguments := get_command_line_arguments();

    if cmd_arguments.count < 2 {
        print("You dont provide any file to parse.\n");
        return;
    }
    
    set_allocators(*pool);
    push_allocator(pool_allocator_proc, *pool);

    parse_file(*files, cmd_arguments[1]);

	File_Module.make_directory_if_it_does_not_exist("./out");

    for nodes, file: files output_file_to_json(file, nodes);

    release(*pool);

    print("All done!\n");
}

#load "json_export.jai";

#import,dir "../../";

File_Module :: #import "File";
#import "File_Utilities";
#import "Basic";
#import "Hash_Table";
#import "String";
#import "Pool";