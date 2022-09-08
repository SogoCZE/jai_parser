AST_Node :: enum {
    STRUCT;
}

AST_Struct :: struct {
    using #as kind: AST_Node; 
    name: string;
    members: []AST_Struct_Member;
}

AST_Struct_Member :: struct {
    name: string;
    type: string;
}

parse_struct_declaration :: (cursor: *int, tokens: []Token) {
    print("%\n", tokens[<<cursor]);
}

parse_declaration :: (nodes: *[..]AST_Node, cursor: *int, tokens: []Token) {
    declaration_tokens, cursor_advanced_by := get_next_tokens(cursor, tokens, 4);

    name := declaration_tokens[0];

    if name.kind != .IDENT {
        <<cursor -= cursor_advanced_by;
        return;
    }

    if declaration_tokens[1].kind != .COLON || declaration_tokens[2].kind != .COLON {
        <<cursor -= cursor_advanced_by;
        return;
    }

    if declaration_tokens[3].kind == .IDENT {

        if declaration_tokens[3].value == "struct" {
            parse_struct_declaration(cursor, tokens);
            print("Struct -> %\n", name.value);
        }

        if declaration_tokens[3].value == "enum" {
            print("Enum -> %\n", name.value);
        }

    }

    // print("Declaration -> Name: %, Type: %\n", declaration_tokens[0].value, declaration_tokens[3].value);

}   

make_ast_tree :: (tokens: []Token) -> []AST_Node {
    cursor := 0;
    nodes: [..]AST_Node;

    while cursor < tokens.count {
        token := tokens[cursor];
        parse_declaration(*nodes, *cursor, tokens);
        cursor += 1;
    }

    return nodes;
}