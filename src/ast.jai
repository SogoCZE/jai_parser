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
    using #as node: Node;
    kind = .BLOCK;

    members: []*Node;
}

Type_Instantiation :: struct {

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

next_node :: (tokenizer: *Tokenizer) -> *Node {
    token := next_token(tokenizer);

    // if is_directive(tokenizer) {
    //     return parse_directive(tokenizer);
    // }

    if is_start_block(tokenizer) {
        return parse_block(tokenizer);
    }

    if is_type_inst(tokenizer) {
        name := peek_token(tokenizer);
        print("Type inst: %\n", name.value);
        return null;
    }

    if is_declaration(tokenizer) {
        return parse_declaration(tokenizer);
    }

    // if is_variable_declaration(tokenizer) {
    //     return parse_variable_declaration(tokenizer);
    // }

    return null;
}

next_node_while :: (tokenizer: *Tokenizer, predicate: (token: Token) -> bool) -> []*Node {
    nodes: [..]*Node;

    while !end(tokenizer) && predicate(peek_token(tokenizer)) {
        node := next_node(tokenizer);
        if !node continue;
        array_add(*nodes, node);
    }

    if nodes.count > 1 pop(*nodes); // Nechceme last one

    

    return nodes;
}

is_start_block :: (tokenizer: *Tokenizer) -> bool {
    if peek_token(tokenizer, 1).char != #char "{" return false;
    return true;
}

is_end_block :: (tokenizer: *Tokenizer) -> bool {
    if peek_token(tokenizer).char != #char "}" return false;
    return true;
}

is_type_inst :: (tokenizer: *Tokenizer) -> bool {
    if peek_token(tokenizer).kind != .IDENTIFIER return false;
    if peek_token(tokenizer, 1).char != #char ":" return false;
    if peek_token(tokenizer, 2).char == #char ":" return false;
    return true;
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

parse_directive :: (tokenizer: *Tokenizer) -> Directive {
    directive: Directive;
    directive.name = next_token(tokenizer).value;

    return directive;
}

parse_declaration :: (tokenizer: *Tokenizer) -> *Declaration {
    decl := New(Declaration);
    
    decl.name = peek_token(tokenizer).value;
    next_token(tokenizer); // :
    next_token(tokenizer); // :

    expression := next_token(tokenizer);

    // Procedure
    if expression.kind == .PUNCTUATION || expression.kind == .KEYWORD && expression.keyword == .INLINE {
        return decl;
    }
  
    // Struct, Enum, Union
    if expression.kind == .KEYWORD {
        if expression.keyword == .STRUCT {
            _struct: Struct;
            //_struct.name = name.value;
        }

        if expression.keyword == .ENUM {
            _enum: Enum;
            //_enum.name = name.value;

            if is_start_block(tokenizer) {
                parse_block(tokenizer);
            }
        }

    }

    // Constant
    // constant.children = next_node_while(tokenizer, (token) => token.char != #char ";");

    return decl;
}

parse_block :: (tokenizer: *Tokenizer) -> *Block {
    block := New(Block);
    block.members = next_node_while(tokenizer, (token) => token.char != #char "}");
    return block;
}