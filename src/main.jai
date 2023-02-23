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

            if !decl.expression continue;

            print("expression kind = %\n", decl.expression.kind);

            if decl.expression.kind == {
                case .PROCEDURE;
                    proc := cast(*Procedure) decl.expression;

                    print("Proc: %\n", decl.name);
                    for argument: proc.arguments {
                        print("Argument: %\n", argument.kind);
                    }
            }
        } else {
            print("Kind: %\n", node.kind);
        }
        
    }
}

