#import "Basic";
#import "File";

#load "iterator.jai";
#load "tokenizer.jai";
#load "parser.jai";
#load "print.jai";
#load "json_export.jai";

main :: () {
    cmd_arguments := get_command_line_arguments();
    if cmd_arguments.count < 2 {
        print("You dont provide any file to parse.\n");
        return;
    }

    print("Parsing %...\n", cmd_arguments[1]);

    iterator := create_iterator(read_entire_file(cmd_arguments[1]), cmd_arguments[1]);
    tokenizer := create_tokenizer(*iterator);

    nodes: [..]*Node;

    while !end(*tokenizer) {
        node := parse(*tokenizer);
        if !node continue;
        array_add(*nodes, node);
    }

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

    write_entire_file("out.json", builder_to_string(*json_builder));

    print("Written AST to out.json\n");
}

