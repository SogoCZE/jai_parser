demo_command_line_arguments :: () {
    args := get_command_line_arguments();
    defer array_reset(*args); // get_command_line_arguments() creates a new array so we release it here. The strings themselves are not copies, however!

    print("Number of command line arguments: %\n", args.count);
    for args {
         print("Argument %: %\n", it_index+1, it);
    }
} 