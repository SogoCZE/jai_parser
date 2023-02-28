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
        IMPORT_OR_LOAD;
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
    const: bool;
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

Procedure_Call :: struct {
    using #as node: Node;
    kind = .PROCEDURE_CALL;

    name: string;
    arguments: [] *Node;
}

Struct :: struct {
    using #as node: Node; 
    kind = .STRUCT;

    block: *Block;
}

Enum :: struct {
    using #as node: Node; 
    kind = .ENUM;

    block: *Block;
}

Directive :: struct {
    using #as node: Node; 
    kind = .DIRECTIVE;

    name: string;
}

Import_Or_Load :: struct {
    using #as node: Node; 
    kind = .IMPORT_OR_LOAD;

    load: bool;
    file: string;
}

Literal :: struct {
    using #as node: Node; 
    kind = .LITERAL;

    Value_Type :: enum s16 {
        UNINITIALIZED :: 0;
        NUMBER        :: 1;
        STRING        :: 2;
        TRUE          :: 4;
        FALSE         :: 5;
        ARRAY         :: 6;
        STRUCT        :: 7;
        POINTER       :: 8;
    }

    value_type: Value_Type;

    using values: union {
        _string:  string;
        _float64: float64;
        _s64:     s64;
        _u64:     u64;
        
        struct\_literal_info: *Struct\_Literal_Info;
        array\ _literal_info: *Array\ _Literal_Info;
        pointer_literal_info: *Pointer_Literal_Info;
    };
}

Struct_Literal_Info :: struct {
    type_expression: *Type_Instantiation;  // May be null if it's the unary dot version of struct literals.
    arguments: [] *Node;
}

Array_Literal_Info :: struct {
    element_type: *Type_Instantiation;
    // alignment: *Node;
    array_members: [] *Node;
}

Pointer_Literal_Info :: struct {
    // TODO: ?
}

delimeted :: (tokenizer: *Tokenizer, open: u8, close: u8, seperator: u8 = 0) -> []*Node {
    nodes: [..]*Node;

    eat_punction(tokenizer, open);

    while !end(tokenizer) {
        if is_punctuation(tokenizer, close) break;

        if seperator != 0 && is_punctuation(tokenizer, seperator) {
            eat_punction(tokenizer, seperator);
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

        if is_punctuation(tokenizer, #char "(") {
            return parse_procedure_call(ident.value, tokenizer);
        }

        if is_punctuation(tokenizer, #char ":") {
            return parse_declaration(ident.value, tokenizer);
        }

    }

    if is_punctuation(tokenizer, #char "(") { 
        return parse_procedure(tokenizer);
    }

    if is_keyword(tokenizer, .STRUCT) {
        return parse_struct(tokenizer);
    }
    
    if is_keyword(tokenizer, .ENUM) {
        return parse_enum(tokenizer);
    }

    // Directive
    if is_operator(tokenizer, #char "#") {
        return parse_directive(tokenizer);
    }

    if peek_token(tokenizer).kind == .STRING {
        return parse_literal(tokenizer, .STRING);
    }    
    
    if peek_token(tokenizer).kind == .NUMBER {
        return parse_literal(tokenizer, .NUMBER);
    }

    if is_keyword(tokenizer, .TRUE) {
        return parse_literal(tokenizer, .TRUE);
    }    
    
    if is_keyword(tokenizer, .FALSE) {
        return parse_literal(tokenizer, .FALSE);
    }



    // print("Eaten non match:\n");
    // print_token(eat_token(tokenizer));

    eat_token(tokenizer);

    return null;
}


parse_declaration :: (name: string, tokenizer: *Tokenizer) -> *Declaration {
    decl := New(Declaration);

    decl.name = name;

    eat_punction(tokenizer, #char ":"); 

    // decl :: exp;
    if is_punctuation(tokenizer, #char ":") {
        eat_punction(tokenizer, #char ":");
        decl.expression = parse(tokenizer);
        decl.const = true;

        return decl;
    }

    // decl := exp;
    if is_operator(tokenizer, #char "=") {
        eat_operator(tokenizer, #char "=");
        decl.expression = parse(tokenizer);
        decl.const = false;

        return decl;
    }

    // decl: type_inst;
    if is_identifier(tokenizer) {
        decl.type_inst = parse_type_inst(tokenizer);
        decl.const = false;

        // decl: type_inst = exp;
        if is_operator(tokenizer, #char "=") {
            eat_operator(tokenizer, #char "=");
            decl.expression = parse(tokenizer);
        }

        return decl;
    }

    return decl;
}

parse_procedure :: (tokenizer: *Tokenizer) -> *Procedure {
    proc := New(Procedure);

    proc.arguments = delimeted(tokenizer, #char "(", #char ")", #char ",");

    if is_punctuation(tokenizer, #char "{") {
        proc.body = parse_block(tokenizer);
    } else {
        print("Exprected procedure body! Got:");
        print_token(peek_token(tokenizer));
    }

    return proc;
}

parse_struct :: (tokenizer: *Tokenizer) -> *Struct {
    _struct := New(Struct);

    eat_keyword(tokenizer, .STRUCT);

    if is_punctuation(tokenizer, #char "{") {
        _struct.block = parse_block(tokenizer);
    } else {
        print("Exprected struct body! Got:");
        print_token(peek_token(tokenizer));
    }

    return _struct;
}

parse_enum :: (tokenizer: *Tokenizer) -> *Enum {
    _enum := New(Enum);

    eat_keyword(tokenizer, .ENUM);

    if is_punctuation(tokenizer, #char "{") {
        _enum.block = parse_block(tokenizer);
    } else {
        print("Exprected enum body! Got:");
        print_token(peek_token(tokenizer));
    }

    return _enum;
}

parse_block :: (tokenizer: *Tokenizer) -> *Block {
    block := New(Block);
    block.members = delimeted(tokenizer, #char "{", #char "}");
    return block;
}

parse_type_inst :: (tokenizer: *Tokenizer) -> *Type_Instantiation {
    type_inst := New(Type_Instantiation);
    type_inst.result = eat_identifier(tokenizer).value;
    return type_inst;
}
 
parse_procedure_call :: (procedure_name: string, tokenizer: *Tokenizer) -> *Procedure_Call {
    proc_call := New(Procedure_Call);
    proc_call.name = procedure_name;
    proc_call.arguments = delimeted(tokenizer, #char "(", #char ")", #char ",");
    return proc_call;
}

parse_directive :: (tokenizer: *Tokenizer) -> *Node {
    eat_operator(tokenizer, #char "#");

    if is_keyword(tokenizer, .IMPORT) {
        return parse_import_or_load(tokenizer, false);
    }

    if is_keyword(tokenizer, .LOAD) {
        return parse_import_or_load(tokenizer, true);
    }

    // TODO:

    return null;
}

parse_import_or_load :: (tokenizer: *Tokenizer, load: bool) -> *Import_Or_Load {
    import_or_load := New(Import_Or_Load);
    eat_keyword(tokenizer, ifx load then Keyword.LOAD else .IMPORT);
    import_or_load.file = eat_string(tokenizer).value;
    return import_or_load;
}

parse_literal :: (tokenizer: *Tokenizer, type: Literal.Value_Type) -> *Literal {
    literal := New(Literal);
    literal.value_type = type;

    if type == {
        case .STRING;
            literal._string = eat_string(tokenizer).value;
        case .TRUE;
            eat_keyword(tokenizer, .TRUE);       
        case .FALSE;
            eat_keyword(tokenizer, .FALSE);
        case .NUMBER;
            number := eat_number(tokenizer);
            print("%\n", number.value);
    }

    return literal;
}