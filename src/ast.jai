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

next_node :: (tokenizer: *Tokenizer) -> *Node {
    token := next_token(tokenizer);

    // if is_directive(tokenizer) {
    //     return parse_directive(tokenizer);
    // }

    if is_start_block(tokenizer) {
        return parse_block(tokenizer);
    }

    if is_type_inst(tokenizer) {
        return parse_type_type_inst(tokenizer);
    }

    if is_declaration(tokenizer) {
        return parse_declaration(tokenizer);
    }

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

is_start_block :: (tokenizer: *Tokenizer, $count := 0) -> bool {
    if peek_token(tokenizer, count).char != #char "{" return false;
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

parse_declaration :: (tokenizer: *Tokenizer) -> *Declaration {
    decl := New(Declaration);
    
    decl.name = peek_token(tokenizer).value;
    next_token(tokenizer); // :
    next_token(tokenizer); // :

    expression := next_token(tokenizer);

    // Procedure
    if is_procedure(tokenizer) {
        decl.expression = parse_procedure(tokenizer);
        return decl;
    }
  
    if is_keyword(tokenizer, .STRUCT) {
        decl.expression = parse_struct(tokenizer);
        return decl;
    }

    if is_keyword(tokenizer, .ENUM) {
        decl.expression = parse_enum(tokenizer);
        return decl;
    }

    if is_literal(tokenizer) {
        print("literal!\n");
    }

    return decl;
}

parse_procedure :: (tokenizer: *Tokenizer) -> *Procedure {
    procedure := New(Procedure);

    procedure.arguments = next_node_while(tokenizer, (token) => token.char != #char ")");
    
    // TODO: returns!
    // TODO: direktivy za procedurou

    if is_start_block(tokenizer, 1) {
        procedure.body = parse_block(tokenizer);
    } else {
        print("Error expected proceudre body!\n", to_standard_error = true);
    }

    return procedure;
}

parse_struct :: (tokenizer: *Tokenizer) -> *Struct {
    _struct := New(Struct);

    if is_start_block(tokenizer, 1) {
        _struct.block = parse_block(tokenizer);
    } else {
        print("Error expected struct body!\n", to_standard_error = true);
    }

    return _struct;
}

parse_enum :: (tokenizer: *Tokenizer) -> *Enum {
    _enum := New(Enum);

    if is_start_block(tokenizer, 1) {
        _enum.block = parse_block(tokenizer);
    } else {
        print("Error expected enum body!\n", to_standard_error = true);
    }

    return _enum;
}

parse_block :: (tokenizer: *Tokenizer) -> *Block {
    block := New(Block);
    block.members = next_node_while(tokenizer, (token) => token.char != #char "}");
    return block;
}

parse_type_type_inst :: (tokenizer: *Tokenizer) -> *Type_Instantiation {
    type_inst := New(Type_Instantiation);

    return type_inst;
}