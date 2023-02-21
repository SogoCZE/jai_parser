#import "Basic";
#import "File";

#load "iterator.jai";
#load "tokenizer.jai";
#load "ast.jai";

main :: () {
    cmd_arguments := get_command_line_arguments();
    if cmd_arguments.count < 2 {
        print("You dont provide any file to parse.\n");
        return;
    }

    print("Parsing %...\n", cmd_arguments[1]);

    iterator := create_iterator(read_entire_file(cmd_arguments[1]), cmd_arguments[1]);
    tokenizer := create_tokenizer(*iterator);

    while !end(*tokenizer) {
        node := next_node(*tokenizer);
        if !node continue;

        if node.kind == .DECLARATION {
            decl := cast(*Declaration) node;
            print("Decl: %\n", decl.name);
        } else {
            print("Kind: %\n", node.kind);
        }
        
    }
}

