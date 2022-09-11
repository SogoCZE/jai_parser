Node_Kind :: enum {
    STRUCT_DECLARATION;
    ENUM_DECLARATION;
    PROCEDURE_DECLARATION;
}

Node :: struct {
    kind: Node_Kind; 
    union {
        struct_declaration: Struct_Declaration;
    }
}

Struct_Declaration :: struct {
    name: string;
    members: []Struct_Member;
}

Struct_Member :: struct {
    name: string;
    type: string;
}

next_node :: (tokenizer: *Tokenizer) -> Node {
    token := next_token(tokenizer);
    print_token(token);
}

parse_declaration :: (tokenizer: *Tokenizer) -> Node {
    name := peek_token(tokenizer);

    print("Ident: %\n", name);
    

    return .{};
}