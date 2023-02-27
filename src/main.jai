#import "Basic";
#import "File";

#load "iterator.jai";
#load "tokenizer.jai";
#load "parser.jai";

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
        node := parse(*tokenizer);
        if !node continue;

        if node.kind == .DECLARATION {
            decl := cast(*Declaration) node;

            if decl.expression && !decl.type_inst {
                print("% :: exp\n", decl.name);
                continue;
            }

            if !decl.expression && decl.type_inst {
                print("%: type_inst;\n", decl.name);
                continue;
            }

            print("%: type_inst = exp;\n", decl.name);            

        }

    }
}