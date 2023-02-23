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

next_node :: (tokenizer: *Tokenizer) -> *Node {
    token := next_token(tokenizer);

    if is_procedure(tokenizer) {
        return parse_procedure(tokenizer);
    }

    if is_keyword(tokenizer, .STRUCT) {
        return parse_struct(tokenizer);
    }    
    
    if is_keyword(tokenizer, .ENUM) {
        return parse_struct(tokenizer);
    }

    if is_block(tokenizer) {
        return parse_block(tokenizer);
    }

    if is_declaration(tokenizer) {
        return parse_declaration(tokenizer);
    }

    // print("Skipped:");
    // print_token(token);

    return null;
}

next_node_while :: (tokenizer: *Tokenizer, predicate: (token: Token) -> bool) -> []*Node {
    nodes: [..]*Node;

    while !end(tokenizer) && predicate(peek_token(tokenizer)) {
        node := next_node(tokenizer);
        if !node continue;
        array_add(*nodes, node);
    }

    while_skipped := next_token(tokenizer); // Skip end token

    print("next_node_while skipped:");
    if while_skipped {
        print_token(while_skipped);
    }

    return nodes;
}

is_block :: (tokenizer: *Tokenizer) -> bool {
    if peek_token(tokenizer).char != #char "{" return false;
    return true;
}

is_declaration :: (tokenizer: *Tokenizer) -> bool {
    if peek_token(tokenizer).kind != .IDENTIFIER return false;
    if peek_token(tokenizer, 1).char != #char ":" return false;
    return true;
}

is_directive :: (tokenizer: *Tokenizer) -> bool {
    if peek_token(tokenizer).char != #char "#" return false;
    if peek_token(tokenizer, 1).kind != .IDENTIFIER return false;
    return true;
}

is_keyword :: (tokenizer: *Tokenizer, keyword: Keyword) -> bool {
    current_token := peek_token(tokenizer);
    if current_token.kind != .KEYWORD || current_token.keyword != keyword return false;
    return true;
}

// TODO: inlined
is_procedure :: (tokenizer: *Tokenizer) -> bool {
    current_token := peek_token(tokenizer);
    if current_token.kind != .PUNCTUATION || current_token.char != #char "(" return false;
    return true; 
}

is_literal :: (tokenizer: *Tokenizer) -> bool {
    current_token := peek_token(tokenizer);

    // "string", 10, 30
    if current_token.kind == .STRING || current_token.kind == .NUMBER return true;

    // true, false
    if current_token.kind == .KEYWORD && (current_token.keyword == .FALSE || current_token.keyword == .TRUE) return true; 

    // .{}, .[], 
    if current_token.kind == .PUNCTUATION && current_token.char == #char "." {
        next_token := peek_token(tokenizer, 1);
        if next_token.kind == .PUNCTUATION && (next_token.char == #char "{" || next_token.char == #char "[") return true;    
    }

    // Person.{}, Person.[]
    if current_token.kind == .IDENTIFIER {
        next_token := peek_token(tokenizer, 1);
        if next_token.kind != .PUNCTUATION || next_token.char != #char "." return false;

        next_token = peek_token(tokenizer, 2);
        if next_token.kind == .PUNCTUATION && (next_token.char == #char "{" || next_token.char == #char "[") return true;    
    }

    return false;
}

parse_directive :: (tokenizer: *Tokenizer) -> Directive {
    directive: Directive;
    directive.name = next_token(tokenizer).value;
    return directive;
}


// Decl :: expression
// Decl: type_inst;
// Decl := expression;
// Decl: type_inst = expression;
parse_declaration :: (tokenizer: *Tokenizer) -> *Declaration {
    decl := New(Declaration);

    decl.name = peek_token(tokenizer).value;

    print("Decl %\n", decl.name);

    next_token(tokenizer); // skip :

    token := peek_token(tokenizer, 1);

    // Decl :: expression, Decl := expression
    if token.kind == .PUNCTUATION && (token.char == #char ":" || token.char == #char "=") {
        next_token(tokenizer); // skip :,=
        decl.expression = next_node(tokenizer);
        return decl;
    } 

    decl.type_inst = parse_type_inst(tokenizer);

    // Decl: type_inst;
    token = peek_token(tokenizer, 1);

    // Decl: type_inst = expression;
    if token.kind == .PUNCTUATION && token.char == #char "=" {
        next_token(tokenizer); // =
        decl.expression = next_node(tokenizer);
    } 

    // TODO: řešit středník na konci?

    return decl;
}

parse_procedure :: (tokenizer: *Tokenizer) -> *Procedure {
    procedure := New(Procedure);

    // next_token(tokenizer); // (

    procedure.arguments = next_node_while(tokenizer, token => token.char != #char ")");

    print("Children (%): ", procedure.arguments.count);

    for procedure.arguments {
        print("%, ", it.kind);
    }

    print("\n");

    // TODO: returns!
    // TODO: direktivy za procedurou

    if is_block(tokenizer) {
        procedure.body = parse_block(tokenizer);
    } else {
        print("Error expected procedure body!\n", to_standard_error = true);
    }

    return procedure;
}

parse_struct :: (tokenizer: *Tokenizer) -> *Struct {
    _struct := New(Struct);

    if is_block(tokenizer) {
        _struct.block = parse_block(tokenizer);
    } else {
        print("Error expected struct body!\n", to_standard_error = true);
    }

    return _struct;
}

parse_enum :: (tokenizer: *Tokenizer) -> *Enum {
    _enum := New(Enum);

    if is_block(tokenizer) {
        _enum.block = parse_block(tokenizer);
    } else {
        print("Error expected enum body!\n", to_standard_error = true);
    }

    return _enum;
}

parse_block :: (tokenizer: *Tokenizer) -> *Block {
    //next_token(tokenizer);

    block := New(Block);
    block.members = next_node_while(tokenizer, token => token.char != #char "}");
    print_token(peek_token(tokenizer));
    return block;
}

parse_type_inst :: (tokenizer: *Tokenizer) -> *Type_Instantiation {
    type_inst := New(Type_Instantiation);


    token := next_token(tokenizer);

    if token.kind == .IDENTIFIER {
        type_inst.result = token.value;
        // return type_inst;
    } 

    print("Type inst! (%)\n", type_inst.result);

    return type_inst;
}

parse_literal :: (tokenizer: *Tokenizer) -> *Literal {
    literal := New(Literal);

    return literal;
}