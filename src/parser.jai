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
    using #as node: Node;
    kind = .TYPE_INSTANTIATION;

    result: string; 
}

Procedure :: struct {
    using #as node: Node;
    kind = .PROCEDURE;

    arguments: []*Node;
    body: Block; // Body asi budemem uset defernout!
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

Literal :: struct {
    using #as node: Node; 
    kind = .LITERAL;
}


delimeted :: (tokenizer: *Tokenizer, open: u8, close: u8) -> []*Node {
    nodes: [..]*Node;

    eat_punction(tokenizer, open);

    while !end(tokenizer) {
        if is_punctuation(tokenizer, close) break;

        node := parse(tokenizer);
        if node == null continue;
        array_add(*nodes, node);
        
        if is_punctuation(tokenizer, close) break;
    }

    eat_punction(tokenizer, close);

    print_token(peek_token(tokenizer));

    return nodes;
}


delimeted :: (tokenizer: *Tokenizer, open: u8, close: u8, seperator: u8) -> []*Node {
    nodes: [..]*Node;

    eat_punction(tokenizer, open);

    while !end(tokenizer) {
        if is_punctuation(tokenizer, close) break;

        if is_punctuation(tokenizer, seperator) {
            eat_token(tokenizer);
            continue;
        }

        node := parse(tokenizer);
        if node == null continue;
        array_add(*nodes, node);

        if is_punctuation(tokenizer, close) break;
    }

    eat_punction(tokenizer, close);

    return nodes;
}

parse :: (tokenizer: *Tokenizer) -> *Node {

    if is_identifier(tokenizer) {
        ident := eat_identifier(tokenizer);

        // Declaration
        // Statement
        if is_punctuation(tokenizer, #char "(") {
            print("procedure call!\n");
        }

        if is_punctuation(tokenizer, #char ":") {
            return parse_declaration(ident.value, tokenizer);
        }

    }

    if is_punctuation(tokenizer, #char "(") { 
        return parse_procedure(tokenizer);
    }

    eat_token(tokenizer);

    return null;
}

parse_declaration :: (name: string, tokenizer: *Tokenizer) -> *Declaration {
    decl := New(Declaration);

    decl.name = name;

    eat_punction(tokenizer, #char ":"); 

    if is_punctuation(tokenizer, #char ":") {
        eat_punction(tokenizer, #char ":");
        print("% :: exp\n", decl.name);
        decl.expression = parse(tokenizer);
    }

    if is_operator(tokenizer, #char "=") {
        print("% := exp\n", decl.name);
    }

    if is_identifier(tokenizer) {
        print("%: type_inst\n", decl.name);
    }

    return decl;
}

parse_procedure :: (tokenizer: *Tokenizer) -> *Procedure {
    proc := New(Procedure);

    proc.arguments = delimeted(tokenizer, #char "(", #char ")", #char ",");

    print("Argument count: %\n", proc.arguments.count);

    if is_punctuation(tokenizer, #char "{") {
        proc.body = parse_block(tokenizer);
    } else {
        print("Exprected procedure body! Got:");
        print_token(peek_token(tokenizer));
    }

    return proc;
}

parse_block :: (tokenizer: *Tokenizer) -> *Block {
    block := New(Block);
    
    block.members = delimeted(tokenizer, #char "{", #char "}");

    return block;
}
 