#import "Basic";
File_Module :: #import "File";
#import "Hash_Table";
#import "String";

#load "iterator.jai";
#load "tokenizer.jai";
#load "parser.jai";
#load "json_export.jai";

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
    
    parse_file(*files, cmd_arguments[1]);

    for nodes, file: files output_file_to_json(file, nodes);

    print("All done!\n");
}