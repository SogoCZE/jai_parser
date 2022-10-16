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
    children: []Node;
}

Struct_Declaration :: struct {
    name: string;
    children: []Node;
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

    if is_directive(tokenizer) {
        print("Directive!\n");
    }
}

is_declaration :: (tokenizer: *Tokenizer) -> bool {
    if peek_token(tokenizer).kind != .IDENTIFIER return false;
    if peek_token(tokenizer, 1).char != #char ":" return false;
    if peek_token(tokenizer, 2).char != #char ":" return false;
    return true;
}

is_directive :: (tokenizer: *Tokenizer) -> bool {
    if peek_token(tokenizer).char != #char "#" return false;
    if peek_token(tokenizer).kind != .IDENTIFIER return false;
    return true;
 }

parse_declaration :: (tokenizer: *Tokenizer) -> Node {
    node: Node;
    
    name := peek_token(tokenizer);
    next_token(tokenizer); // :
    next_token(tokenizer); // :
    
    content := next_token(tokenizer);

    if content.kind == .NUMBER || content.kind == .STRING {


        print("% :: %;\n", name.value, content.value);
        
        return node;
    } 

    if content.kind == .PUNCTUATION {
        print("% :: procedure;\n", name.value);
    }
  
    if content.kind == .KEYWORD {
        print("% :: %;\n", name.value, content.keyword);
    }

    return .{};
}