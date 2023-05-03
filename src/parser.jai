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
        IDENTIFIER;
        DIRECTIVE;
        LITERAL;
        BINARY_OPERATION;
        IMPORT_OR_LOAD;
        RETURN;
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
    type_inst: *Node;
    expression: *Node;
}

Block :: struct {
    using #as node: Node;
    kind = .BLOCK;

    members: []*Node;
}

Identifier :: struct {
    using #as node: Node;
    kind = .IDENTIFIER;

    name: string;
}

Return :: struct {
    using #as node: Node;
    kind = .RETURN;

    returns: []*Node;
}

Type_Instantiation :: struct {
    using #as node: Node;
    kind = .TYPE_INSTANTIATION;

    result: string; 
}

Procedure :: struct {
    using #as node: Node;
    kind = .PROCEDURE;

    Flags :: enum_flags u32 {
        ELSEWHERE                          :: 0x1;
        COMPILE_TIME                       :: 0x2;
        POLYMORPHIC                        :: 0x4;
        COMPILER_GENERATED                 :: 0x8;
        DEBUG_DUMP                         :: 0x10;
        C_CALL                             :: 0x20;
        TYPE_ONLY                          :: 0x40;
        INTRINSIC                          :: 0x80;
        DEPRECATED                         :: 0x100;
        SYNTACTICALLY_MARKED_AS_NO_CONTEXT :: 0x200;  // This means it has #no_context written in the declaration. There are other ways for a procedure to have no context, though (for example, being #c_call).
        QUICK                              :: 0x400;
        CPP_METHOD                         :: 0x800;
        NO_CALL                            :: 0x1000;
        MACRO                              :: 0x2000;
        NO_DEBUG                           :: 0x4000;
    }

    flags: Flags;
    arguments: []*Node;
    returns: []*Node;
    body: *Block; // Body asi budemem uset defernout!
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

    type: string;
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
        
        struct_literal_info : *Struct_Literal_Info;
        array_literal_info  : *Array_Literal_Info;
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

Binary_Operation :: struct {
    using #as node: Node; 
    kind = .BINARY_OPERATION;

    // @TODO: is this complete?
    Operation :: enum {
        ADDITION; // +
        SUBTRACTION; // -
        MULTIPLICATION; // *
        DIVISION; // /
        MODULO; // %

        IS_EQUAL; // ==
        IS_NOT_EQUAL; // !=
        
        LESS; // >
        GREATER; // <
        
        LESS_EQUEAL; // <=
        GREATER_EQUEAL; // >=

        ASSING; // =
    }

    left: *Node;
    operation: Operation;
    right: *Node;
}

delimeted :: (tokenizer: *Tokenizer, open: Token_Kind, close: Token_Kind, seperator: Token_Kind = 0) -> []*Node {
    nodes: [..]*Node;

    eat_token(tokenizer, open); 

    while !end(tokenizer) {
        if is_token(tokenizer, close) break;

        if seperator != 0 && is_token(tokenizer, seperator) {
            eat_token(tokenizer, seperator);
            continue;
        }

        node := parse(tokenizer);
        if node == null continue;
        array_add(*nodes, node);

        if is_token(tokenizer, close) break;
    }

    eat_token(tokenizer, close);

    return nodes;
}

eat_until :: (tokenizer: *Tokenizer, stop: (token: *Token) -> bool, seperator: Token_Kind = 0) -> []*Node {
    nodes: [..]*Node;

    while !end(tokenizer) {
        if stop(peek_token(tokenizer)) break;

        if seperator != 0 && is_token(tokenizer, seperator) {
            eat_token(tokenizer, seperator);
            continue;
        }

        node := parse(tokenizer);
        if node == null continue;
        array_add(*nodes, node);

        if stop(peek_token(tokenizer)) break;
    }

    return nodes;
}

// TODO: IF, ELSE, FOR, WHILE, CASE, Directivy pořádně, ...

parse :: (tokenizer: *Tokenizer) -> *Node {

    if is_identifier(tokenizer) {
        ident := eat_token(tokenizer, .IDENTIFIER);

        // age+20
        if is_operator(peek_token(tokenizer)) {
            identifier := parse_identifier(ident.string_value);
            return parse_binary_operation(tokenizer, identifier);
        }

        if is_token(tokenizer, #char "(") {
            return parse_procedure_call(ident.string_value, tokenizer);
        }

        if is_token(tokenizer, #char ":") {
            return parse_declaration(ident.string_value, tokenizer);
        }

        return parse_identifier(ident.string_value);
    }

    if is_token(tokenizer, #char "(") { 
        // TODO: cislo :: (10+20); nebo cislo :: (10)
        return parse_procedure(tokenizer);
    }

    if is_token(tokenizer, .KEYWORD_STRUCT) {
        return parse_struct(tokenizer);
    }
    
    if is_token(tokenizer, .KEYWORD_ENUM) {
        return parse_enum(tokenizer);
    }
    
    if is_token(tokenizer, .KEYWORD_RETURN) {
        return parse_return(tokenizer);
    }

    // Directive
    if is_token(tokenizer, #char "#") {
        return parse_directive(tokenizer);
    }

    if peek_token(tokenizer).kind == .STRING {
        return parse_literal(tokenizer, .STRING);
    }    
    
    if peek_token(tokenizer).kind == .NUMBER {
   
        // 10+20
        if is_operator(peek_token(tokenizer, 1)) {
            literal := parse_literal(tokenizer, .NUMBER);
            return parse_binary_operation(tokenizer, literal);    
        }

        return parse_literal(tokenizer, .NUMBER);
    }

    if is_token(tokenizer, .KEYWORD_TRUE) {
        return parse_literal(tokenizer, .TRUE);
    }    
    
    if is_token(tokenizer, .KEYWORD_FALSE) {
        return parse_literal(tokenizer, .FALSE);
    }

    if is_token(tokenizer, #char "{") {
        return parse_block(tokenizer);
    }

    // print("Eaten non match:\n");
    // print_token(eat_token(tokenizer));

    eat_token(tokenizer);

    return null;
}


parse_declaration :: (name: string, tokenizer: *Tokenizer) -> *Declaration {
    decl := New(Declaration);
    decl.name = name;

    eat_token(tokenizer, #char ":"); 

    // decl :: exp;
    if is_token(tokenizer, #char ":") {
        eat_token(tokenizer, #char ":");
        decl.expression = parse(tokenizer);
        decl.const = true;

        return decl;
    }

    // decl := exp;
    if is_token(tokenizer, #char "=") {
        eat_token(tokenizer, #char "=");
        decl.expression = parse(tokenizer);
        decl.const = false;

        return decl;
    }

    // decl: type_inst;
    if is_token(tokenizer, .IDENTIFIER) {
        decl.type_inst = parse(tokenizer);
        decl.const = false;

        // decl: type_inst = exp;
        if is_operator(peek_token(tokenizer)) {
            eat_token(tokenizer, #char "=");
            decl.expression = parse(tokenizer);
        }

        return decl;
    }
    
    return decl;
}

parse_procedure :: (tokenizer: *Tokenizer) -> *Procedure {
    proc := New(Procedure);

    proc.arguments = delimeted(tokenizer, #char "(", #char ")", #char ",");

    parse_proc_directives :: (tokenizer: *Tokenizer, proc: *Procedure) {
        eat_token(tokenizer, #char "#");

        proc_directive := eat_token(tokenizer, .IDENTIFIER);
            
        // @TODO: make directives more robust!
        if proc_directive.string_value == {
            case "expand";
                proc.flags |= .MACRO;
            case "no_context";
                proc.flags |= .SYNTACTICALLY_MARKED_AS_NO_CONTEXT;
            case "dump";
                proc.flags |= .DEBUG_DUMP;
            case "cpp_method";
                proc.flags |= .CPP_METHOD;
            case "no_debug";
                proc.flags |= .NO_DEBUG;
            case "c_call";
                proc.flags |= .SYNTACTICALLY_MARKED_AS_NO_CONTEXT;
                proc.flags |= .C_CALL;

        }

        if is_token(tokenizer, #char "#") {
            parse_proc_directives(tokenizer, proc);
        }
    }   

    // Directives
    // if is_operator(tokenizer, #char "#") {
    //     parse_proc_directives(tokenizer, proc);
    // }
    
    // returns
    if meaybe_eat_token(tokenizer, #char "-") {
        eat_token(tokenizer, #char ">");
        meaybe_eat_token(tokenizer, #char "(");
        
        proc.returns = eat_until(tokenizer, token => token.kind == #char "{" || token.kind == #char ")", #char ",");

        meaybe_eat_token(tokenizer, #char ")");
    }

    // Body
    if is_token(tokenizer, #char "{") {
        proc.body = parse_block(tokenizer);
    } else {
        print("Exprected procedure body! Got:");
        print_token(peek_token(tokenizer));
    }

    return proc;
}

parse_struct :: (tokenizer: *Tokenizer) -> *Struct {
    _struct := New(Struct);

    eat_token(tokenizer, .KEYWORD_STRUCT);

    if is_token(tokenizer, #char "{") {
        _struct.block = parse_block(tokenizer);
    } else {
        print("Exprected struct body! Got:");
        print_token(peek_token(tokenizer));
    }

    return _struct;
}

parse_enum :: (tokenizer: *Tokenizer) -> *Enum {
    _enum := New(Enum);

    eat_token(tokenizer, .KEYWORD_ENUM);

    // Type specifier
    if is_identifier(tokenizer) {
        _enum.type = eat_token(tokenizer, .IDENTIFIER).string_value;
    }

    // Body
    if is_token(tokenizer, #char "{") {
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
    type_inst.result = eat_token(tokenizer, .IDENTIFIER).string_value;
    return type_inst;
}
 
parse_procedure_call :: (procedure_name: string, tokenizer: *Tokenizer) -> *Procedure_Call {
    proc_call := New(Procedure_Call);
    proc_call.name = procedure_name;
    proc_call.arguments = delimeted(tokenizer, #char "(", #char ")", #char ",");
    return proc_call;
}

parse_directive :: (tokenizer: *Tokenizer) -> *Node {
    eat_token(tokenizer, #char "#");

    if is_token(tokenizer, .KEYWORD_IMPORT) {
        return parse_import_or_load(tokenizer, false);
    }

    if is_token(tokenizer, .KEYWORD_LOAD) {
        return parse_import_or_load(tokenizer, true);
    }

    directive_name_identifier := eat_token(tokenizer);

    directive := New(Directive);
    directive.name = directive_name_identifier.string_value;

    return directive;
}

parse_import_or_load :: (tokenizer: *Tokenizer, load: bool) -> *Import_Or_Load {
    import_or_load := New(Import_Or_Load);
    eat_token(tokenizer, ifx load then Token_Kind.KEYWORD_LOAD else .KEYWORD_IMPORT);
    import_or_load.file = eat_token(tokenizer, .STRING).string_value;
    return import_or_load;
}

parse_identifier :: (name: string) -> *Identifier {
    identifier := New(Identifier);
    identifier.name = name;
    return identifier;
}

parse_literal :: (tokenizer: *Tokenizer, type: Literal.Value_Type) -> *Literal {
    literal := New(Literal);
    literal.value_type = type;

    if type == {
        case .STRING;
            literal._string = eat_token(tokenizer).string_value;
        case .TRUE;
            eat_token(tokenizer);       
        case .FALSE;
            eat_token(tokenizer);
        case .NUMBER;
            // number := eat_token(tokenizer).integer_value;
            // literal._string = number.value;
    }

    return literal;
}

parse_binary_operation :: (tokenizer: *Tokenizer, left: *Node) -> *Binary_Operation {
    binary_operation := New(Binary_Operation);
    binary_operation.left = left;

    op := eat_token(tokenizer);
    assert(is_operator(op));

    // @@InComplete
    if op.kind == {
        case #char ">";         binary_operation.operation = .GREATER;
        case #char "<";         binary_operation.operation = .LESS;
        case #char "+";         binary_operation.operation = .ADDITION;
        case #char "-";         binary_operation.operation = .SUBTRACTION;
        case #char "*";         binary_operation.operation = .MULTIPLICATION;
        case #char "/";         binary_operation.operation = .DIVISION;
        case #char "%";         binary_operation.operation = .MODULO;
        case #char "=";         binary_operation.operation = .ASSING;

        case .GREATER_EQUEAL;   binary_operation.operation = .GREATER_EQUEAL;
        case .LESS_EQUEAL;      binary_operation.operation = .LESS_EQUEAL;
        case .IS_EQUAL;         binary_operation.operation = .IS_EQUAL;
        case .IS_NOT_EQUAL;     binary_operation.operation = .IS_NOT_EQUAL;

        case; assert(false, tprint("invalid operator %", to_string(*cast(u8)op.kind, 1)));
    }

    binary_operation.right = parse(tokenizer); // @TODO: anything?
    
    return binary_operation;
}

parse_return :: (tokenizer: *Tokenizer) -> *Node {
    _return := New(Return);
    eat_token(tokenizer, .KEYWORD_RETURN);
    _return.returns = eat_until(tokenizer, token => token.kind == #char ";", #char ",");
    return _return;
}
