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

        if node.kind == .STRUCT_DECLARATION {
            print("Struct: %\n", node.struct_declaration);
        } else {
            print("Node: %\n", node);
        }

    }
}

// Build
#run {
    #import "Compiler";
    #import "File_Utilities";
    #import "String";

	make_directory_if_it_does_not_exist("./bin/");	

    set_build_options_dc (.{ 
        output_executable_name = "jai_lsp",
		output_path = "./bin/"
	});
}