#import "Basic";
File_Module :: #import "File";
#import "Hash_Table";
#import "String";

#load "iterator.jai";
#load "tokenizer.jai";
#load "parser.jai";
#load "json_export.jai";

output_file_to_json :: (file: File) {
    json_builder: String_Builder;

    append(*json_builder, "[");
    first := true;
    for file.nodes {
        if first {
            first = false;
        } else {
            append(*json_builder, ",");
        }

        append(*json_builder, to_json(it));
    }
    append(*json_builder, "]");


    out_filename := path_filename(file.path);

    File_Module.write_entire_file(tprint("./out/%.json", out_filename), builder_to_string(*json_builder));
}

main :: () {
    files: Table(string, File);
    init(*files);

    cmd_arguments := get_command_line_arguments();
    if cmd_arguments.count < 2 {
        print("You dont provide any file to parse.\n");
        return;
    }
    
    table_set(*files, cmd_arguments[1], parse_file(cmd_arguments[1]));

    for file: files {
        output_file_to_json(file);
    }

    print("All done!\n");
}