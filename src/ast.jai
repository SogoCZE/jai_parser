Node :: struct {

    Kind :: enum {
        UNINITIALIZATED;
        DECLARATION;
        BLOCK;
        STRUCT;
        ENUM;
        PROCEDURE;
        PROCEDURE_CALL;
        TYPE_INSTANTIATION;
        EXPRESSION;
        DIRECTIVE;
        LITERAL;

        // TOKEN;
    }

    Location :: struct {
        l0,l1,c0,c1: u32;
        file: string;
    }

    location: Location;
    kind: Kind;
    // serial: s64;
}

Declaration :: struct {
    using #as node: Node;
    kind = .DECLARATION;

    name: string;

    type_inst: *Type_Instantiation;
    expression: *Node;
}

Block :: struct {

}

Type_Instantiation :: struct {

}

Expression :: struct {
    using #as node: Node;
    kind = .EXPRESSION;
    
    name: string;
}

Struct :: struct {
    using #as node: Node; 
    kind = .STRUCT;

    block: *Block;
    name: string;
}

Enum :: struct {
    using #as node: Node; 
    kind = .ENUM;

    block: *Block;
    name: string;
}

Directive :: struct {
    using #as node: Node; 
    kind = .DIRECTIVE;

    name: string;
}

next_node :: (tokenizer: *Tokenizer) -> Node {
    token := next_token(tokenizer);

    // if is_directive(tokenizer) {
    //     return parse_directive(tokenizer);
    // }

    if is_declaration(tokenizer) {
        return parse_declaration(tokenizer);
    }

    // if is_variable_declaration(tokenizer) {
    //     return parse_variable_declaration(tokenizer);
    // }

    return .{};
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

parse_directive :: (tokenizer: *Tokenizer) -> Directive {
    directive: Directive;
    directive.name = next_token(tokenizer).value;

    return directive;
}

parse_declaration :: (tokenizer: *Tokenizer) -> *Declaration {
    decl := New(Declaration);
    
    name := peek_token(tokenizer);
    next_token(tokenizer); // :
    next_token(tokenizer); // :

    content := peek_token(tokenizer, 1);

    // Procedure
    if content.kind == .PUNCTUATION || content.kind == .KEYWORD && content.keyword == .INLINE {


        return .{kind=.PROCEDURE};
    }
  
    // Struct, Enum, Union
    if content.kind == .KEYWORD {
        if content.keyword == .STRUCT {
            _struct: Struct;
            _struct.name = name.value;
        }

        if content.keyword == .ENUM {
            _enum: Enum;
            _enum.name = name.value;
        }

        return node;
    }

    // Constant
    expression: Expression;
    expression.name = name.value;
    // constant.children = next_node_while(tokenizer, (token) => token.char != #char ";");

    return node;
}

parse_variable_declaration :: (tokenizer: *Tokenizer) -> Node {
    name := peek_token(tokenizer);  
    next_token(tokenizer); // :

    children := next_node_while(tokenizer, (token) => token.char != #char ";");
    //print("Variable: %\n", children);
} 