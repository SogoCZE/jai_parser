#import "Basic";
#import "File";

#load "character_iterator.jai";
#load "tokenizer.jai";
// #load "ast.jai";

main :: () {
    cmd_arguments := get_command_line_arguments();
    if cmd_arguments.count < 2 {
        print("You dont provide any file to parse.\n");
        return;
    }

    print("Parsing %...\n", cmd_arguments[1]);

    character_iterator := create_character_iterator(read_entire_file(cmd_arguments[1]), cmd_arguments[1]);

    while !end(*character_iterator) {
        token := next_token(*character_iterator);
        print_token(token);
    }
}