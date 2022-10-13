Node_Kind :: enum {
    STRUCT_DECLARATION;
    ENUM_DECLARATION;
    PROCEDURE_DECLARATION;
    CONSTANT_DECLARATION;
}

Node :: struct {
    kind: Node_Kind; 
    union {
        struct_declaration: Struct_Declaration;
        constant_declaration: Constant_Declaration;
    }
}

Constant_Declaration :: struct {
    name: string;
    value: string;
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

    if is_declaration(tokenizer) {
        parse_declaration(tokenizer);
    }
}

is_declaration :: (tokenizer: *Tokenizer) -> bool {
    if peek_token(tokenizer).kind != .IDENTIFIER return false;
    if peek_token(tokenizer, 1).char != #char ":" return false;
    if peek_token(tokenizer, 2).char != #char ":" return false;
    return true;
}

parse_declaration :: (tokenizer: *Tokenizer) -> Node {
    node: Node;
    
    name := peek_token(tokenizer);
    next_token(tokenizer); // :
    next_token(tokenizer); // :
    
    content := next_token(tokenizer);

    if content.kind == .NUMBER || content.kind == .STRING {
        // constant_declaration: Constant_Declaration;
        // constant_declaration.name = name.value;
        // constant_declaration.value = content.value;
        
        // node.kind = .CONSTANT_DECLARATION;
        // node.constant_declaration = constant_declaration;
        
        // return node;
        print("% :: %;\n", name.value, content.value);
    } 

    if content.kind == .PUNCTUATION {
        print("% :: procedure;\n", name.value);
    }
  
    if content.kind == .KEYWORD {
        print("% :: %;\n", name.value, content.keyword);
    }

    return .{};
}