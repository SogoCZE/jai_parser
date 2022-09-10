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

next_node :: (iterator: *Iterator) -> Node {
    token := next_token(iterator);

    if token.kind == .IDENTIFIER return parse_declaration(iterator);

    print_token(token);
    return .{};
}

parse_declaration :: (iterator: *Iterator) -> Node {
    

    return .{};
}