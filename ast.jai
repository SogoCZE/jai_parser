Node_Kind :: enum {
    STRUCT_DECLARATION;
    ENUM_DECLARATION;
    PROCEDURE_DECLARATION;
    CONSTANT_DECLARATION;
    DIRECTIVE;
    STRING;
    NUMBER;
    UNDEFINED;
}

Node :: struct {
    kind: Node_Kind; 
    union {
        struct_declaration: Struct_Declaration;
        constant_declaration: Constant_Declaration;
        directive: Directive;
        value: string;
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

Enum_Declaration :: struct {
    name: string;
    children: []Node;
}

Struct_Member :: struct {
    name: string;
    type: string;
}

Directive :: struct {
    name: string;
}

next_node :: (tokenizer: *Tokenizer) -> Node {
    token := next_token(tokenizer);

    if token.kind == .STRING {
        node: Node;
        node.kind = .STRING;
        node.value = token.value;
        return node;
    }

    if token.kind == .NUMBER {
        node: Node;
        node.kind = .NUMBER;
        node.value = token.value;
        return node;
    }
    
    if is_directive(tokenizer) {
        return parse_directive(tokenizer);
    }

    if is_declaration(tokenizer) {
        return parse_declaration(tokenizer);
    }

    return .{kind=.UNDEFINED};
}

next_node_while :: (tokenizer: *Tokenizer, predicate: (token: Token) -> bool) -> []Node {
    nodes: [..]Node;

    while !end(tokenizer) && predicate(peek_token(tokenizer)) {
        array_add(*nodes, next_node(tokenizer));
    }

    pop(*nodes); // Nechceme last one

    return nodes;
}

is_declaration :: (tokenizer: *Tokenizer) -> bool {
    if peek_token(tokenizer).kind != .IDENTIFIER return false;
    if peek_token(tokenizer, 1).char != #char ":" return false;
    if peek_token(tokenizer, 2).char != #char ":" return false;
    return true;
}

is_directive :: (tokenizer: *Tokenizer) -> bool {
    if peek_token(tokenizer).char != #char "#" return false;
    if peek_token(tokenizer, 1).kind != .IDENTIFIER return false;
    return true;
}

parse_directive :: (tokenizer: *Tokenizer) -> Node {
    node: Node;
    node.kind = .DIRECTIVE;
    node.directive.name = next_token(tokenizer).value;

    return node;
}

parse_declaration :: (tokenizer: *Tokenizer) -> Node {
    node: Node;
    
    name := peek_token(tokenizer);
    next_token(tokenizer); // :
    next_token(tokenizer); // :

    content := peek_token(tokenizer, 1);

    // Procedure
    if content.kind == .PUNCTUATION {
        return .{};
    }
  
    // Struct, Enum, Union
    if content.kind == .KEYWORD {
        
 
        return .{};
    }

    // Constant
    constant: Constant_Declaration;
    constant.name = name.value;
    constant.children = next_node_while(tokenizer, (token) => token.char != #char ";");

    node.kind = .CONSTANT_DECLARATION;
    node.constant_declaration = constant;

    return node;
}