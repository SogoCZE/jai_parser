Node_Kind :: enum {
    STRUCT_DECLARATION;
    ENUM_DECLARATION;
    PROCEDURE_DECLARATION;
    CONSTANT_DECLARATION;
    DIRECTIVE;
    STRING;
    NUMBER;
    TOKEN;
}

Node :: struct {
    kind: Node_Kind; 
    union {
        struct_declaration: Struct_Declaration;
        enum_declaration: Enum_Declaration;
        constant_declaration: Constant_Declaration;
        directive: Directive;
        value: string;
        token: Token;
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

    if is_directive(tokenizer) {
        return parse_directive(tokenizer);
    }

    if is_declaration(tokenizer) {
        return parse_declaration(tokenizer);
    }

    if is_variable_declaration(tokenizer) {
        return parse_variable_declaration(tokenizer);
    }

    node: Node;
    node.kind = .TOKEN;
    node.token = token;

    return node;
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

is_variable_declaration :: (tokenizer: *Tokenizer) -> bool {
    if peek_token(tokenizer).kind != .IDENTIFIER return false;
    if peek_token(tokenizer, 1).char != #char ":" return false;
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
        

        return .{kind=.PROCEDURE_DECLARATION};
    }
  
    // Struct, Enum, Union
    if content.kind == .KEYWORD {
        if content.keyword == .STRUCT {
            _struct: Struct_Declaration;
            _struct.name = name.value;
            _struct.children = next_node_while(tokenizer, (token) => token.char != #char "}");

            //print("Children: %\n", _struct.children);

            node.kind = .STRUCT_DECLARATION;
            node.struct_declaration = _struct;
        }

        if content.keyword == .ENUM {
            _enum: Enum_Declaration;
            _enum.name = name.value;
            _enum.children = next_node_while(tokenizer, (token) => token.char != #char "}");


            node.kind = .ENUM_DECLARATION;
            node.enum_declaration = _enum;
        }

        return node;
    }

    // Constant
    constant: Constant_Declaration;
    constant.name = name.value;
    constant.children = next_node_while(tokenizer, (token) => token.char != #char ";");

    node.kind = .CONSTANT_DECLARATION;
    node.constant_declaration = constant;

    return node;
}

parse_variable_declaration :: (tokenizer: *Tokenizer) -> Node {
    name := peek_token(tokenizer);  
    next_token(tokenizer); // :

    children := next_node_while(tokenizer, (token) => token.char != #char ";");
    //print("Variable: %\n", children);
}