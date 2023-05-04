Files :: Table(string, []*Node);

// TODO: IF, ELSE, FOR, WHILE, CASE, Directivy pořádně, ...
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
        COMMENT;
        RETURN;
        USING;
        COMMA_SEPERATED_EXPRESSION;
        RUN;
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

Comment :: struct {
    using #as node: Node;
    kind = .COMMENT;
    value: string;
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

    backticked: bool;
    returns: []*Node;
}

Using :: struct {
    using #as node: Node;
    kind = .USING;

    expression: *Node;
    filter_expression: *Node;

    filter_type: enum u8 {
        NONE   :: 0;
        ONLY   :: 1;
        EXCEPT :: 2;
        MAP    :: 3;
    }

    no_parameters := false;  // If this using is marked 'no_parameters'.
}

Type_Instantiation :: struct {
    using #as node: Node;
    kind = .TYPE_INSTANTIATION;

    result: *Node; 
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
        UNINITIALIZED;
        INT;
        FLOAT;
        STRING;
        BOOL;
        ARRAY;
        STRUCT;
        POINTER;
    }

    value_type: Value_Type;

    using values: union {
        _string:  string;
        _float:   float;
        _int:     int;
        _bool:    bool;
        
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

    // @InComplete: >>> <<< >>= <<= ...
    Operation :: enum {
        INVALID;

        DOT; // .

        ADDITION; // +
        SUBTRACTION; // -
        MULTIPLICATION; // *
        DIVISION; // /
        MODULO; // %
        LESS; // >
        GREATER; // <
        ASSING; // =

        GREATER_EQUEAL; // >=
        LESS_EQUEAL; // <=
        PLUS_EQUEAL; // +=
        MINUS_EQUEAL; // -=
        MOD_EQUEAL; // %=
        DIV_EQUEAL; // /=
        TIMES_EQUEAL; // *=
        LOGICAL_AND; // &&
        LOGICAL_OR; // ||
        IS_EQUAL; // ==
        IS_NOT_EQUAL; // !=
    }

    left: *Node;
    operation: Operation = .INVALID;
    right: *Node;
}

Comma_Seperated_Expression :: struct {
    using #as node: Node;
    kind = .COMMA_SEPERATED_EXPRESSION;
    members: []*Node;
}

Run :: struct {
    using #as node: Node;
    kind = .RUN;
    stallable: bool;
    statement: *Node;
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

parse_file :: (files: *Files, path: string) {
    print("Parsing file %...\n", path);
    path_without_filename := path_strip_filename(path);

    iterator := create_iterator(File_Module.read_entire_file(path));
    tokenizer := create_tokenizer(*iterator);

    nodes: [..]*Node;

    while !end(*tokenizer) {
        node := parse(*tokenizer);
        if !node continue;

        if node.kind == .IMPORT_OR_LOAD {
            import_or_load := cast(*Import_Or_Load) node;
            if import_or_load.load {
                load_relative_path := tprint("%/%", path_without_filename, import_or_load.file);
                parse_file(files, load_relative_path); // @TODO: Run this in another thread?
            }
        }

        array_add(*nodes, node);
    }

    table_set(files, path, nodes);
}

parse :: (tokenizer: *Tokenizer) -> *Node {

    if is_identifier(tokenizer) {
        ident := eat_token(tokenizer, .IDENTIFIER);

        // age+20
        if is_operator(peek_token(tokenizer)) {
            identifier := parse_identifier(ident.string_value);
            return parse_binary_operation(tokenizer, identifier);
        }

        if is_token(tokenizer, #char "(") {
            return parse_procedure_call(tokenizer, ident.string_value);
        }

        if is_token(tokenizer, .CONSTANT_DECLARATION) {
            return parse_constant_declaration(tokenizer, ident.string_value);
        }
        
        if is_token(tokenizer, .DECLARATION_AND_ASSIGN) {
            return parse_declaration_and_assign(tokenizer, ident.string_value);
        }
        
        if is_token(tokenizer, #char ":") {
            return parse_type_instantiation(tokenizer, ident.string_value);
        }

        return parse_identifier(ident.string_value);
    }

    if is_token(tokenizer, #char "(") { 
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

    if is_token(tokenizer, .KEYWORD_USING) {
        return parse_using(tokenizer);
    }

    // Directive
    if is_token(tokenizer, .DIRECTIVE) {
        return parse_directive(tokenizer);
    }

    if peek_token(tokenizer).kind == .STRING {
        return parse_literal(tokenizer);
    }    
    
    if peek_token(tokenizer).kind == .NUMBER {
   
        // 10+20
        if is_operator(peek_token(tokenizer, 1)) {
            literal := parse_literal(tokenizer);
            return parse_binary_operation(tokenizer, literal);    
        }

        return parse_literal(tokenizer);
    }

    if is_token(tokenizer, .KEYWORD_TRUE) {
        return parse_literal(tokenizer);
    }    
    
    if is_token(tokenizer, .KEYWORD_FALSE) {
        return parse_literal(tokenizer);
    }

    if is_token(tokenizer, #char "{") {
        return parse_block(tokenizer);
    }

    if is_token(tokenizer, .COMMENT) {
        comment_token := eat_token(tokenizer, .COMMENT);
        comment := New(Comment);
        comment.value = comment_token.string_value;
        return comment;
    }

    // print("Eaten non match:\n");
    // print_token(eat_token(tokenizer));

    eat_token(tokenizer);

    return null;
}

// player: Player;
parse_type_instantiation :: (tokenizer: *Tokenizer, name: string) -> *Declaration {
    eat_token(tokenizer, #char ":");
    decl := New(Declaration);
    decl.name = name;
    decl.type_inst = parse(tokenizer);

    // decl: type_inst = exp;
    if is_token(tokenizer, #char "=") {
        eat_token(tokenizer, #char "=");
        decl.expression = parse(tokenizer);
    }

    return decl;
}

// PLAYER_MAX_HP :: 120;
parse_constant_declaration :: (tokenizer: *Tokenizer, name: string) -> *Declaration {
    eat_token(tokenizer, .CONSTANT_DECLARATION);
    decl := New(Declaration);
    decl.name = name;
    decl.const = true;
    decl.expression = parse(tokenizer);
    return decl;
}

// player_position := Vec3.{10, 20, 10};
parse_declaration_and_assign :: (tokenizer: *Tokenizer, name: string) -> *Declaration {
    eat_token(tokenizer, .DECLARATION_AND_ASSIGN);
    decl := New(Declaration);
    decl.name = name;
    decl.expression = parse(tokenizer);
    return decl;
}

parse_procedure :: (tokenizer: *Tokenizer) -> *Node {
    members := delimeted(tokenizer, #char "(", #char ")", #char ",");

    if members.count > 0 && members[0].kind != .DECLARATION {
        comma_seperated_expression := New(Comma_Seperated_Expression);
        comma_seperated_expression.members = members;
        return comma_seperated_expression;
    }

    proc := New(Procedure);
    proc.arguments = members;

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
    if meaybe_eat_token(tokenizer, .ARROW_RIGHT) {
        meaybe_eat_token(tokenizer, #char "(");
        proc.returns = eat_until(tokenizer, token => token.kind == #char "{" || token.kind == #char ")", #char ",");
        meaybe_eat_token(tokenizer, #char ")");
    }

    // Body
    if is_token(tokenizer, #char "{") {
        proc.body = parse_block(tokenizer);
    } 

    if proc.body == null && proc.returns.count == 0 {

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
 
parse_procedure_call :: (tokenizer: *Tokenizer, procedure_name: string) -> *Procedure_Call {
    proc_call := New(Procedure_Call);
    proc_call.name = procedure_name;
    proc_call.arguments = delimeted(tokenizer, #char "(", #char ")", #char ",");
    return proc_call;
}

parse_directive :: (tokenizer: *Tokenizer) -> *Node {
    directive_token := eat_token(tokenizer, .DIRECTIVE);

    if directive_token.string_value == {
        case "import"; return parse_import_or_load(tokenizer, false);
        case "load"; return parse_import_or_load(tokenizer, true);
        case "run"; return parse_run(tokenizer);
    }

    directive_name_identifier := eat_token(tokenizer);

    directive := New(Directive);
    directive.name = directive_token.string_value;

    return directive;
}

parse_run :: (tokenizer: *Tokenizer) -> *Node {
    run := New(Run);

    if is_token(tokenizer, #char ",") {
        eat_token(tokenizer, #char ",");

        if is_token(tokenizer, token => token.kind == .IDENTIFIER && token.string_value == "stallable") {
            eat_token(tokenizer, .IDENTIFIER);
            run.stallable = true;
        }
    }

    run.statement = parse(tokenizer);    
    return run;
}

parse_import_or_load :: (tokenizer: *Tokenizer, load: bool) -> *Import_Or_Load {
    import_or_load := New(Import_Or_Load);
    import_or_load.load = load;
    import_or_load.file = eat_token(tokenizer, .STRING).string_value;
    return import_or_load;
}

parse_identifier :: (name: string) -> *Identifier {
    identifier := New(Identifier);
    identifier.name = name;
    return identifier;
}

parse_literal :: (tokenizer: *Tokenizer) -> *Literal {
    literal := New(Literal);

    base_literal := eat_token(tokenizer);

    if base_literal.kind == {
        case .STRING;
            literal.value_type = .STRING;
            literal._string = base_literal.string_value;
        case .KEYWORD_TRUE;
            literal.value_type = .BOOL;
            literal._bool = true;
        case .KEYWORD_FALSE;
            literal.value_type = .BOOL;
            literal._bool = false;
        case .NUMBER;
            if base_literal.integer_value == 0 {
                literal.value_type = .FLOAT;
                literal._float = base_literal.float_value; // @TODO: Bug!!!
            } else {
                literal.value_type = .INT;
                literal._int = base_literal.integer_value;
            }
    }

    return literal;
}

parse_binary_operation :: (tokenizer: *Tokenizer, left: *Node) -> *Binary_Operation {
    binary_operation := New(Binary_Operation);
    binary_operation.left = left;

    op := eat_token(tokenizer);
    assert(is_operator(op));

    // @InComplete
    // @TODO: this is proably silly we could use some sort of metaprogramming to make this automatic...
    if op.kind == {
        case #char ">";         binary_operation.operation = .GREATER;
        case #char "<";         binary_operation.operation = .LESS;
        case #char "+";         binary_operation.operation = .ADDITION;
        case #char "-";         binary_operation.operation = .SUBTRACTION;
        case #char "*";         binary_operation.operation = .MULTIPLICATION;
        case #char "/";         binary_operation.operation = .DIVISION;
        case #char "%";         binary_operation.operation = .MODULO;
        case #char "=";         binary_operation.operation = .ASSING;
        case #char ".";         binary_operation.operation = .DOT;

        case .GREATER_EQUEAL;   binary_operation.operation = .GREATER_EQUEAL;
        case .LESS_EQUEAL;      binary_operation.operation = .LESS_EQUEAL;
        case .PLUS_EQUEAL;      binary_operation.operation = .PLUS_EQUEAL;
        case .MINUS_EQUEAL;     binary_operation.operation = .MINUS_EQUEAL;
        case .MOD_EQUEAL;       binary_operation.operation = .MOD_EQUEAL;
        case .DIV_EQUEAL;       binary_operation.operation = .DIV_EQUEAL;
        case .TIMES_EQUEAL;     binary_operation.operation = .TIMES_EQUEAL;
        case .LOGICAL_AND;      binary_operation.operation = .LOGICAL_AND;
        case .LOGICAL_OR;       binary_operation.operation = .LOGICAL_OR;
        case .IS_EQUAL;         binary_operation.operation = .IS_EQUAL;
        case .IS_NOT_EQUAL;     binary_operation.operation = .IS_NOT_EQUAL;

        case; log_error(tprint("Invalid operator '%'.", op.kind));
    }

    binary_operation.right = parse(tokenizer); // @TODO: anything?
    
    return binary_operation;
}

parse_return :: (tokenizer: *Tokenizer) -> *Node {
    _return := New(Return);
    return_token := eat_token(tokenizer, .KEYWORD_RETURN);
    _return.backticked = return_token.backticked;
    _return.returns = eat_until(tokenizer, token => token.kind == #char ";", #char ",");
    return _return;
}

parse_using :: (tokenizer: *Tokenizer) -> *Node {
    _using := New(Using);
    using_token := eat_token(tokenizer, .KEYWORD_USING);
    return _using;
}
