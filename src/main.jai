#import "Basic";
#import "File";

#load "iterator.jai";
#load "tokenizer.jai";
#load "parser.jai";
#load "print.jai";

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

    print("\n-- AST -- \n\n");
    for nodes print_node(it);
}

