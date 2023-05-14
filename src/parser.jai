// @TODO:
// - Split parsing into multiple files? 

// To Parse:
// - #if
// - #ifx
// - #bake_arguments
// - #bake_constants
// - #bytes
// - #caller_code
// - #caller_location
// - #code
// - #compiler
// - #cpp_return_type_is_non_pod
// - #deprecated
// - #dump
// - #dynamic_specialize
// - #file
// - #filepath
// - #library
// - #system_library
// - #insert
// - #insert,scope
// - #insert_internal
// - #line
// - #location
// - #modify
// - #module_parameters
// - #must
// - #no_abc
// - #no_alias
// - #no_padding
// - #no_reset
// - #placeholder
// - #poke_name
// - #procedure_of_call
// - #program_export
// - #runtime_support
// - #scope_export
// - #scope_file
// - #scope_module
// - #specified
// - #symmetric
// - #this
// - #through
// - #type_info_no_size_complaint
// - #type_info_none
// - #type_info_procedures_are_void_pointers
// - #import,file
// - #import,dir
// - #import,string
// - notes
// - multiple assings declaration
// - operators (bitshift, rotate, bitwise)
// - type keywords (is this needed?)

Files :: Table(string, []*Node);

Node :: struct {

    Kind :: enum {
        UNINITIALIZATED;
        DECLARATION;
        BLOCK;
        STRUCT;
        UNION;
        ENUM;
        PUSH_CONTEXT;
        PROCEDURE;
        OPERATOR_OVERLOAD;
        PROCEDURE_CALL;
        QUICK_LAMBDA;
        ARRAY_TYPE;
        ARRAY_SUBSCRIPT;
        // TYPE_INSTANTIATION;
        IDENTIFIER;
        DIRECTIVE;
        LITERAL;
        BINARY_OPERATION;
        UNARY_OPERATION;
        POLYMORPHIC_CONSTANT;
        COMMENT;
        RETURN;
        CONTINUE;
        DEFER;
        USING;
        CAST;
        AUTO_CAST;
        COMMA_SEPERATED_EXPRESSION;
        IF; 
        CASE;
        BREAK;
        FOR;
        WHILE;
        INLINE_ASSEMBLY;

        DIRECTIVE_IMPORT_OR_LOAD;
        DIRECTIVE_RUN;
        DIRECTIVE_CHAR;
        DIRECTIVE_AS;
        DIRECTIVE_PLACE;
        DIRECTIVE_TYPE;
        DIRECTIVE_CODE;
        DIRECTIVE_ADD_CONTEXT;
        DIRECTIVE_ASSERT;
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
    backticked: bool;
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

    backticked: bool;
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
    filters: []*Node;

    Filter_Type :: enum u8 {
        NONE   :: 0;
        ONLY   :: 1;
        EXCEPT :: 2;
        MAP    :: 3;
    }

    filter_type: Filter_Type = .NONE;

    no_parameters := false;  // If this using is marked 'no_parameters'.
}

Cast :: struct {
    using #as node: Node;
    kind = .CAST;

    expression: *Node;
    cast_expression: *Node;

    truncate: bool;
    no_check: bool;
}  

Auto_Cast :: struct {
    using #as node: Node;
    kind = .AUTO_CAST;

    expression: *Node;
}

Break :: struct {
    using #as node: Node;
    kind = .BREAK;
    expression: *Node;
}  

Continue :: struct {
    using #as node: Node;
    kind = .CONTINUE;
    expression: *Node;
}  

Defer :: struct {
    using #as node: Node;
    kind = .DEFER;
    expression: *Node;
    backticked: bool;
}  

While :: struct {
    using #as node: Node;
    kind = .WHILE;
    expression: *Node;
    body: *Node;    
}

For :: struct {
    using #as node: Node;
    kind = .FOR;

    by_pointer: bool;
    reversed: bool;

    value: *Node;
    index: *Node;
    iterator: *Node;
    body: *Node;    
}

// Type_Instantiation :: struct {
//     using #as node: Node;
//     kind = .TYPE_INSTANTIATION;

//     array_element_type: *Node;
//     array_dimension: *Node;
//     array_resizable: *Node;

//     result: *Node; 
// }

Procedure :: struct {
    using #as node: Node;
    kind = .PROCEDURE;

    Flags :: enum_flags u32 {
        INLINE;                     
        ELSEWHERE;                     
        COMPILE_TIME;     
        POLYMORPHIC;                   
        COMPILER_GENERATED;            
        DEBUG_DUMP;                    
        C_CALL;                        
        TYPE_ONLY;                     
        INTRINSIC;                     
        DEPRECATED;                    
        SYNTACTICALLY_MARKED_AS_NO_CONTEXT;  // This means it has #no_context written in the declaration. There are other ways for a procedure to have no context, though (for example, being #c_call).
        QUICK;
        CPP_METHOD;
        NO_CALL;
        MACRO;
        NO_DEBUG;
    }

    foreign: string;
    elsewhere: string;
    intrinsic: string;

    flags: Flags;
    arguments: []*Node;
    returns: []*Node;
    body: *Block; // @TODO: Defer this...? Why?
}

Procedure_Call :: struct {
    using #as node: Node;
    kind = .PROCEDURE_CALL;

    inlined: bool;
    backticked: bool;
    name: string;
    arguments: [] *Node;
}

Quick_Lambda :: struct {
    using #as node: Node;
    kind = .QUICK_LAMBDA;

    arguments: [] *Node;
    _return: *Node; 
}

Struct :: struct {
    using #as node: Node; 
    kind = .STRUCT;

    polymorphic_arguments: [] *Node;
    block: *Block;
}

Union :: struct {
    using #as node: Node; 
    kind = .UNION;

    block: *Block;
}

Enum :: struct {
    using #as node: Node; 
    kind = .ENUM;

    is_enum_flags: bool;
    type: *Node;
    block: *Block;
}

Directive :: struct {
    using #as node: Node; 
    kind = .DIRECTIVE;

    name: string;
}

If :: struct {
    using #as node: Node;
    kind = .IF;

    If_Kind :: enum u8 {
        IF;
        IFX;
        SWITCH;
    }

    condition: *Node;
    if_kind: If_Kind;
    marked_as_complete: bool;
    _then: *Node;
    _else: *Node;
}

Case :: struct {
    using #as node: Node;
    kind = .CASE;

    expression: *Node;
    members: [] *Node;
}

Directive_Import_Or_Load :: struct {
    using #as node: Node; 
    kind = .DIRECTIVE_IMPORT_OR_LOAD;

    load: bool;
    file: string;
}

Literal :: struct {
    using #as node: Node; 
    kind = .LITERAL;

    Value_Type :: enum u8 {
        UNINITIALIZED;
        INT;
        FLOAT;
        STRING;
        BOOL;
        ARRAY;
        STRUCT;
    }

    value_type: Value_Type;
    here_string_cr: bool;

    using values: union {
        _string:  string;
        _float:   float;
        _int:     int;
        _bool:    bool;
        
        struct_literal_info: Struct_Literal_Info;
        array_literal_info: Array_Literal_Info;
    };
}

// :array_literal_json_export_structure:
Struct_Literal_Info :: struct {
    type: *Node;
    body: [] *Node;
}

// :struct_literal_json_export_structure:
Array_Literal_Info :: struct {
    element_type: *Node;
    elements: [] *Node;
}

// @InComplete: >>> <<< >>= <<=, &, | ...
_Operator :: enum u8 {
    INVALID;

    DOT; // .
    RANGE; // ..

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

Binary_Operation :: struct {
    using #as node: Node; 
    kind = .BINARY_OPERATION;

    left: *Node;
    operation: _Operator = .INVALID;
    right: *Node;
}

Polymorphic_Constant :: struct {
    using #as node: Node;
    kind = .POLYMORPHIC_CONSTANT;

    maybe_constant: bool;
    type: string;
    restrictions_interface: bool;
    restriction: *Node;
}

Unary_Operation :: struct {
    using #as node: Node;
    kind = .UNARY_OPERATION;

    Operation :: enum {
        INVALID;

        NEGATE;
        DOT;
        POINTER;
        POINTER_DEREFERENCE;
        EXPAND;
        ELLIPSIS;
    }

    operation: Operation = .INVALID;
    expression: *Node;
}

Comma_Seperated_Expression :: struct {
    using #as node: Node;
    kind = .COMMA_SEPERATED_EXPRESSION;

    members: []*Node;
}

Directive_Run :: struct {
    using #as node: Node;
    kind = .DIRECTIVE_RUN;

    stallable: bool;
    expression: *Node;
}

Directive_Char :: struct {
    using #as node: Node;
    kind = .DIRECTIVE_CHAR;
    string_literal: *Node; // @TODO: Can this be String_Literal upfront?
}

Directive_As :: struct {
    using #as node: Node;
    kind = .DIRECTIVE_AS;

    expression: *Node; // @TODO: Can this be String_Literal upfront?
}

// @TODO: Should this contain the placed field?
Directive_Place :: struct {
    using #as node: Node;
    kind = .DIRECTIVE_PLACE;

    expression: *Node;
}

Directive_Type :: struct {
    using #as node: Node;
    kind = .DIRECTIVE_TYPE;

    isa: bool;
    distinct: bool;
    expression: *Node;
}

Directive_Code :: struct {
    using #as node: Node;
    kind = .DIRECTIVE_CODE;

    typed: bool;
    _null: bool;
    expression: *Node;
}

Directive_Add_Context :: struct {
    using #as node: Node;
    kind = .DIRECTIVE_ADD_CONTEXT;
    expression: *Node;
}

Directive_Assert :: struct {
    using #as node: Node;
    kind = .DIRECTIVE_ASSERT;

    condition: *Node;
    message: string;
}

Array_Type :: struct {
    using #as node: Node;
    kind = .ARRAY_TYPE;

    dimension: *Node;
    element_type: *Node;
    resizable: bool;   
}

Array_Subscript :: struct {
    using #as node: Node;
    kind = .ARRAY_SUBSCRIPT;

    subscript: *Node;
}

Push_Context :: struct {
    using #as node: Node;
    kind = .PUSH_CONTEXT;

    backticked: bool;
    defer_pop: bool;
    pushed: *Node;
    block: *Block; 
}

Operator_Overload :: struct {
    using #as node: Node;
    kind = .OPERATOR_OVERLOAD;

    operation: _Operator;
    procedure: *Node;
}

Inline_Assembly :: struct {
    using #as node: Node;
    kind = .INLINE_ASSEMBLY;

    expression: *Node;
    body: string; // @TODO: @InComplete: We currently don't parse content of inline assembly blocks. 
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

    maybe_eat_token(tokenizer, close);

    return nodes;
}

// @TODO: Rename this to parse_until?
eat_until :: (tokenizer: *Tokenizer, stop: (token: *Token) -> bool, seperator: Token_Kind = 0) -> []*Node {
    nodes: [..]*Node;

    while !end(tokenizer) {
        if !peek_token(tokenizer) || stop(peek_token(tokenizer)) break;

        if seperator != 0 && is_token(tokenizer, seperator) {
            eat_token(tokenizer, seperator);
            continue;
        }

        node := parse(tokenizer);
        if node == null continue;
        array_add(*nodes, node);

        if !peek_token(tokenizer) || stop(peek_token(tokenizer)) break;
    }

    return nodes;
}

create_operator_from_token :: (kind: Token_Kind) -> _Operator {
    // @InComplete
    // @TODO: this is proably silly we could use some sort of metaprogramming to make this automaticly...
    if kind == {
        case #char ">";         return .GREATER;
        case #char "<";         return .LESS;
        case #char "+";         return .ADDITION;
        case #char "-";         return .SUBTRACTION;
        case #char "*";         return .MULTIPLICATION;
        case #char "/";         return .DIVISION;
        case #char "%";         return .MODULO;
        case #char "=";         return .ASSING;
        case #char ".";         return .DOT;

        case .GREATER_EQUEAL;   return .GREATER_EQUEAL;
        case .LESS_EQUEAL;      return .LESS_EQUEAL;
        case .PLUS_EQUEAL;      return .PLUS_EQUEAL;
        case .MINUS_EQUEAL;     return .MINUS_EQUEAL;
        case .MOD_EQUEAL;       return .MOD_EQUEAL;
        case .DIV_EQUEAL;       return .DIV_EQUEAL;
        case .TIMES_EQUEAL;     return .TIMES_EQUEAL;
        case .LOGICAL_AND;      return .LOGICAL_AND;
        case .LOGICAL_OR;       return .LOGICAL_OR;
        case .IS_EQUAL;         return .IS_EQUAL;
        case .IS_NOT_EQUAL;     return .IS_NOT_EQUAL;
        case .DOUBLE_DOT;       return .RANGE;
    }

    log_error(tprint("Invalid operator '%'.", kind));
    
    return .INVALID;
}

get_module_entry :: (root: string) -> string {
    uri := tprint("%/module.jai", root);
    if !file_exists(uri) {
        uri = tprint("%.jai", root);
    }

    return uri;
}

parse_file :: (files: *Files, path: string) {
    print("Parsing file %...\n", path);
    path_without_filename := path_strip_filename(path);

    iterator := create_iterator(File_Module.read_entire_file(path), path);
    tokenizer := create_tokenizer(*iterator);

    nodes: [..]*Node;

    while !end(*tokenizer) {
        node := parse(*tokenizer);
        if !node continue;

        if node.kind == .DIRECTIVE_IMPORT_OR_LOAD {
            import_or_load := cast(*Directive_Import_Or_Load) node;

            if import_or_load.load {
                load_relative_path := tprint("%/%", path_without_filename, import_or_load.file);
                parse_file(files, load_relative_path); // @TODO: Run this in another thread?
            } else {
                module_path := tprint("%/%", JAI_MODULES_PATH, import_or_load.file);
                module_entry := get_module_entry(module_path);
                parse_file(files, module_entry); // @TODO: Run this in another thread?
            }
        }

        array_add(*nodes, node);
    }

    table_set(files, path, nodes);
}

parse :: (tokenizer: *Tokenizer) -> *Node {

    // Declaration, Binary Operation, Unary Operation, Identifier
    if is_identifier(tokenizer) {
        ident := eat_token(tokenizer, .IDENTIFIER);

        // age+20
        if is_operator(peek_token(tokenizer)) {
            identifier := parse_identifier(ident);

            // Array or Struct literal
            if is_token(tokenizer, #char ".") && is_token(tokenizer, token => token.kind == #char "[" || token.kind == #char "{", 1) {
                return parse_array_or_struct_literal(tokenizer, identifier);
            } 

            return parse_binary_operation(tokenizer, identifier);
        }

        // Array Subscript
        if is_token(tokenizer, #char "[") {
            return parse_array_subscript(tokenizer);
        }

        // Multiple Assings Declaration (a, b, c := 10, 20, 30)
        if is_token(tokenizer, #char ",") {
            // print("Some!\n");
        }

        if is_token(tokenizer, .QUICK_LAMBDA) {
            identifier := parse_identifier(ident);
            arguments := NewArray(1, *Node);
            arguments[0] = identifier;
            return parse_quick_lambda(tokenizer, arguments);
        }

        if is_token(tokenizer, #char "(") {
            return parse_procedure_call(tokenizer, ident);
        }

        if is_token(tokenizer, .CONSTANT_DECLARATION) {
            return parse_constant_declaration(tokenizer, ident);
        }
        
        if is_token(tokenizer, .DECLARATION_AND_ASSIGN) {
            return parse_declaration_and_assign(tokenizer, ident);
        }
        
        if is_token(tokenizer, #char ":") {
            return parse_type_instantiation(tokenizer, ident);
        }

        return parse_identifier(ident);
    }

    // Procedure
    if is_token(tokenizer, #char "(") { 
        return parse_procedure(tokenizer);
    }

    // Inline
    if is_token(tokenizer, .KEYWORD_INLINE) {
        return parse_inline(tokenizer);
    }

    // Push Context
    if is_token(tokenizer, .KEYWORD_PUSH_CONTEXT) {
        return parse_push_context(tokenizer);
    }

    if is_token(tokenizer, .KEYWORD_OPERATOR) {
        return parse_operator_overload(tokenizer);
    }

    // Polymorphic_Constant
    if is_token(tokenizer, #char "$") {
        return parse_polymorphic_constant(tokenizer, false);
    }
    
    // Polymorphic_Constant
    if is_token(tokenizer, .DOUBLE_DOLLAR) {
        return parse_polymorphic_constant(tokenizer, true);
    }

    // Unary Operation
    if is_unary_operator(tokenizer) {

        // Array or Struct literal
        if is_token(tokenizer, #char ".") && is_token(tokenizer, token => token.kind == #char "[" || token.kind == #char "{", 1) {
            return parse_array_or_struct_literal(tokenizer, null);
        } 

        return parse_unary_operation(tokenizer);
    }

    // If
    if is_token(tokenizer, .KEYWORD_IF) || is_token(tokenizer, .KEYWORD_IFX) {
        return parse_if(tokenizer);
    }

    // Case
    if is_token(tokenizer, .KEYWORD_CASE) {
        return parse_case(tokenizer);
    }

    // While
    if is_token(tokenizer, .KEYWORD_WHILE) {
        return parse_while(tokenizer);
    }
    
    // For
    if is_token(tokenizer, .KEYWORD_FOR) {
        return parse_for(tokenizer);
    }

    // Struct
    if is_token(tokenizer, .KEYWORD_STRUCT) {
        return parse_struct(tokenizer);
    }

    // Union
    if is_token(tokenizer, .KEYWORD_UNION) {
        return parse_union(tokenizer);
    }
    
    // Enum
    if is_token(tokenizer, .KEYWORD_ENUM) {
        return parse_enum(tokenizer, false);
    }

    // Enum_Flags
    if is_token(tokenizer, .KEYWORD_ENUM_FLAGS) {
        return parse_enum(tokenizer, true);
    }
    
    // Return
    if is_token(tokenizer, .KEYWORD_RETURN) {
        return parse_return(tokenizer);
    }

    // Using
    if is_token(tokenizer, .KEYWORD_USING) {
        return parse_using(tokenizer);
    }
    
    // Break
    if is_token(tokenizer, .KEYWORD_BREAK) {
        return parse_break(tokenizer);
    }

    // Continue
    if is_token(tokenizer, .KEYWORD_CONTINUE) {
        return parse_continue(tokenizer);
    }
    
    // Defer
    if is_token(tokenizer, .KEYWORD_DEFER) {
        return parse_defer(tokenizer);
    }

    // Cast
    if is_token(tokenizer, .KEYWORD_CAST) {
        return parse_cast(tokenizer);
    }
    
    // Auto Cast (xx)
    if is_token(tokenizer, .KEYWORD_AUTO_CAST) {
        return parse_auto_cast(tokenizer);
    }

    // Directive
    if is_token(tokenizer, .DIRECTIVE) {
        return parse_directive(tokenizer);
    }

    // String literal
    if peek_token(tokenizer).kind == .STRING {
        return parse_literal(tokenizer);
    }    
    
    // Numeric literal
    if peek_token(tokenizer).kind == .NUMBER {
   
        // 10+20
        if is_operator(peek_token(tokenizer, 1)) {
            literal := parse_literal(tokenizer);
            return parse_binary_operation(tokenizer, literal);    
        }

        return parse_literal(tokenizer);
    }

    // True literal
    if is_token(tokenizer, .KEYWORD_TRUE) {
        return parse_literal(tokenizer);
    }    
    
    // False literal
    if is_token(tokenizer, .KEYWORD_FALSE) {
        return parse_literal(tokenizer);
    }

    // Block
    if is_token(tokenizer, #char "{") {
        return parse_block(tokenizer);
    }

    // Array_Type
    if is_token(tokenizer, #char "[") {
        return parse_array_type(tokenizer);
    }

    // Comment
    if is_token(tokenizer, .COMMENT) {
        comment_token := eat_token(tokenizer, .COMMENT);
        comment := New(Comment);
        comment.value = comment_token.string_value;
        return comment;
    }

    // print("Eaten non match:\n");
    // print_token(eat_token(tokenizer));

    // Skip other
    eat_token(tokenizer);

    return null;
}

// player: Player;
parse_type_instantiation :: (tokenizer: *Tokenizer, ident_token: *Token) -> *Declaration {
    eat_token(tokenizer, #char ":");
    decl := New(Declaration);
    decl.name = ident_token.string_value;
    decl.type_inst = parse(tokenizer);
    decl.backticked = ident_token.backticked;

    // decl: type_inst = exp;
    if is_token(tokenizer, #char "=") {
        eat_token(tokenizer, #char "=");
        decl.expression = parse(tokenizer);
    }

    return decl;
}

// PLAYER_MAX_HP :: 120;
parse_constant_declaration :: (tokenizer: *Tokenizer, ident_token: *Token) -> *Declaration {
    eat_token(tokenizer, .CONSTANT_DECLARATION);
    decl := New(Declaration);
    decl.name = ident_token.string_value;
    decl.backticked = ident_token.backticked;
    decl.const = true;
    decl.expression = parse(tokenizer);
    return decl;
}

// player_position := Vec3.{10, 20, 10};
parse_declaration_and_assign :: (tokenizer: *Tokenizer, ident_token: *Token) -> *Declaration {
    eat_token(tokenizer, .DECLARATION_AND_ASSIGN);
    decl := New(Declaration);
    decl.name = ident_token.string_value;
    decl.backticked = ident_token.backticked;
    decl.expression = parse(tokenizer);
    return decl;
}

parse_procedure :: (tokenizer: *Tokenizer) -> *Node {
    members := delimeted(tokenizer, #char "(", #char ")", #char ",");

    // @TODO: this is kinda messy? We probably want to do this in some other way...
    if members.count > 0 && members[0].kind != .DECLARATION {

        // Quick Lambda
        if is_token(tokenizer, .QUICK_LAMBDA) {
            return parse_quick_lambda(tokenizer, members);
        }

        // Comma Seperated Expression
        comma_seperated_expression := New(Comma_Seperated_Expression);
        comma_seperated_expression.members = members;
        return comma_seperated_expression;
    }

    proc := New(Procedure);
    proc.arguments = members;

    parse_proc_directives :: (tokenizer: *Tokenizer, proc: *Procedure) {
        directive := eat_token(tokenizer, .DIRECTIVE);

        // @TODO: make directives more robust!
        if directive.string_value == {
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
            case "intrinsic";
                proc.flags |= .INTRINSIC;
                proc.intrinsic = eat_token(tokenizer, .IDENTIFIER).string_value;

            case "elsewhere";
                proc.flags |= .ELSEWHERE;
                proc.elsewhere = eat_token(tokenizer, .IDENTIFIER).string_value;
            case "foreign";
                proc.foreign = eat_token(tokenizer, .IDENTIFIER).string_value;
        }

        if is_token(tokenizer, .DIRECTIVE) {
            parse_proc_directives(tokenizer, proc);
        }
    }   

    // returns
    if meaybe_eat_token(tokenizer, .ARROW_RIGHT) {
        meaybe_eat_token(tokenizer, #char "(");
        proc.returns = eat_until(tokenizer, token => token.kind == #char "{" || token.kind == #char ")" || token.kind == .DIRECTIVE, #char ",");
        meaybe_eat_token(tokenizer, #char ")");
    }

    // Directives
    if is_token(tokenizer, .DIRECTIVE) {
        parse_proc_directives(tokenizer, proc);
    }

    // Body
    if is_token(tokenizer, #char "{") {
        proc.body = parse_block(tokenizer);
    } 

    return proc;
}

parse_quick_lambda :: (tokenizer: *Tokenizer, arguments: []*Node) -> *Quick_Lambda {
    quick_lambda := New(Quick_Lambda);
    quick_lambda.arguments = arguments;

    eat_token(tokenizer, .QUICK_LAMBDA);
    quick_lambda._return = parse(tokenizer);

    return quick_lambda;
}

parse_struct :: (tokenizer: *Tokenizer) -> *Struct {
    _struct := New(Struct);

    eat_token(tokenizer, .KEYWORD_STRUCT);

    if is_token(tokenizer, #char "(") {
        _struct.polymorphic_arguments = delimeted(tokenizer, #char "(", #char ")", #char ",");
    }

    if is_token(tokenizer, #char "{") {
        _struct.block = parse_block(tokenizer);
    } else {
        print("Exprected struct body! Got:");
        // print_token(peek_token(tokenizer));
    }

    return _struct;
}

// union {}
parse_union :: (tokenizer: *Tokenizer) -> *Union {
    _union := New(Union);

    eat_token(tokenizer, .KEYWORD_UNION);

    if is_token(tokenizer, #char "{") {
        _union.block = parse_block(tokenizer);
    } else {
        print("Exprected union body! Got:");
        print_token(peek_token(tokenizer));
    }

    return _union;
}

// enum {}
parse_enum :: (tokenizer: *Tokenizer, is_enum_flags: bool) -> *Enum {
    _enum := New(Enum);
    _enum.is_enum_flags = is_enum_flags;

    eat_token(tokenizer, ifx is_enum_flags then Token_Kind.KEYWORD_ENUM_FLAGS else .KEYWORD_ENUM );

    // Type specifier
    if !is_token(tokenizer, #char "{") {
        _enum.type = parse(tokenizer);
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

// {}
parse_block :: (tokenizer: *Tokenizer) -> *Block {
    block := New(Block);
    block.members = delimeted(tokenizer, #char "{", #char "}");
    return block;
}
 
// print()
parse_procedure_call :: (tokenizer: *Tokenizer, ident_token: *Token) -> *Procedure_Call {
    proc_call := New(Procedure_Call);
    proc_call.name = ident_token.string_value;
    proc_call.backticked = ident_token.backticked;
    proc_call.arguments = delimeted(tokenizer, #char "(", #char ")", #char ",");
    return proc_call;
}

// #run 
parse_directive :: (tokenizer: *Tokenizer) -> *Node {
    directive_token := eat_token(tokenizer, .DIRECTIVE);

    if directive_token.string_value == {
        case "import";          return parse_directive_import_or_load(tokenizer, false);
        case "load";            return parse_directive_import_or_load(tokenizer, true);
        case "run";             return parse_directive_run(tokenizer);
        case "as";              return parse_directive_as(tokenizer);
        case "place";           return parse_directive_place(tokenizer);
        case "type";            return parse_directive_type(tokenizer);
        case "code";            return parse_directive_code(tokenizer);
        case "char";            return parse_directive_char(tokenizer);
        case "add_context";     return parse_directive_add_context(tokenizer);
        case "assert";          return parse_directive_assert(tokenizer);
        case "asm";             return parse_inline_assembly(tokenizer);
    }

    directive_name_identifier := eat_token(tokenizer);

    directive := New(Directive);
    directive.name = directive_token.string_value;

    return directive;
}

parse_directive_run :: (tokenizer: *Tokenizer) -> *Directive_Run {
    directive_run := New(Directive_Run);

    if maybe_eat_token(tokenizer, #char ",") 
        && is_token(tokenizer, token => token.kind == .IDENTIFIER && token.string_value == "stallable") {
        eat_token(tokenizer, .IDENTIFIER);

        directive_run.stallable = true;
    }

    directive_run.expression = parse(tokenizer);   

    return directive_run;
}

parse_directive_char :: (tokenizer: *Tokenizer) -> *Directive_Char {
    directive_char := New(Directive_Char);
    directive_char.string_literal = parse(tokenizer);
    return directive_char;
}

parse_directive_code :: (tokenizer: *Tokenizer) -> *Directive_Code {
    directive_code := New(Directive_Code);

    if maybe_eat_token(tokenizer, #char ",") {  

        if is_token(tokenizer, token => token.kind == .IDENTIFIER && token.string_value == "typed") {
            eat_token(tokenizer, .IDENTIFIER);
            directive_code.typed = true;
        }
        
        if is_token(tokenizer, token => token.kind == .IDENTIFIER && token.string_value == "null") {
            eat_token(tokenizer, .IDENTIFIER);
            directive_code._null = true;
        }

    }

    directive_code.expression = parse(tokenizer);

    return directive_code;
}

parse_directive_as :: (tokenizer: *Tokenizer) -> *Directive_As {
    directive_as := New(Directive_As);
    directive_as.expression = parse(tokenizer);
    return directive_as;
}

parse_directive_add_context :: (tokenizer: *Tokenizer) -> *Directive_Add_Context {
    directive_add_context := New(Directive_Add_Context);
    directive_add_context.expression = parse(tokenizer);
    return directive_add_context;
}

parse_directive_import_or_load :: (tokenizer: *Tokenizer, load: bool) -> *Directive_Import_Or_Load {
    directive_import_or_load := New(Directive_Import_Or_Load);
    directive_import_or_load.load = load;
    directive_import_or_load.file = eat_token(tokenizer, .STRING).string_value;
    return directive_import_or_load;
}

parse_directive_place :: (tokenizer: *Tokenizer) -> *Directive_Place {
    directive_place := New(Directive_Place);
    directive_place.expression = parse(tokenizer);
    return directive_place;
}

parse_directive_type :: (tokenizer: *Tokenizer) -> *Directive_Type {
    directive_type := New(Directive_Type);

    if maybe_eat_token(tokenizer, #char ",") {

        if is_token(tokenizer, char  => char.kind == .IDENTIFIER && char.string_value == "isa") {
            eat_token(tokenizer, .IDENTIFIER);
            directive_type.isa = true;
        }
        
        if is_token(tokenizer, char  => char.kind == .IDENTIFIER && char.string_value == "distinct") {
            eat_token(tokenizer, .IDENTIFIER);
            directive_type.distinct = true;
        }

    }

    directive_type.expression = parse(tokenizer);
    return directive_type;
}

parse_directive_assert :: (tokenizer: *Tokenizer) -> *Directive_Assert {
    directive_assert := New(Directive_Assert);

    directive_assert.condition = parse(tokenizer);

    if is_token(tokenizer, .STRING) {
        message_token := eat_token(tokenizer, .STRING);
        directive_assert.message = message_token.string_value;
    }

    return directive_assert;
}
 
parse_identifier :: (ident_token: *Token) -> *Identifier {
    identifier := New(Identifier);
    identifier.name = ident_token.string_value;
    identifier.backticked = ident_token.backticked;
    return identifier;
}

parse_array_or_struct_literal :: (tokenizer: *Tokenizer, type: *Node) -> *Literal {
    literal := New(Literal);

    eat_token(tokenizer, #char ".");

    if maybe_eat_token(tokenizer, #char "[") {
        literal.value_type = .ARRAY;
        literal.values.array_literal_info = .{element_type=type};
        literal.values.array_literal_info.elements = eat_until(tokenizer, token => token.kind == #char "]", #char ",");
    } else if maybe_eat_token(tokenizer, #char "{") {
        literal.value_type = .STRUCT;
        literal.values.struct_literal_info = .{type=type};
        literal.values.struct_literal_info.body = eat_until(tokenizer, token => token.kind == #char "}", #char ",");
    }

    return literal;
}

parse_literal :: (tokenizer: *Tokenizer) -> *Literal {
    literal := New(Literal);

    base_literal := eat_token(tokenizer);

    if base_literal.kind == {
        case .STRING;
            literal.value_type = .STRING;
            literal.here_string_cr = base_literal.here_string_cr;
            literal._string = base_literal.string_value;
        case .KEYWORD_TRUE;
            literal.value_type = .BOOL;
            literal._bool = true;
        case .KEYWORD_FALSE;
            literal.value_type = .BOOL;
            literal._bool = false;
        case .NUMBER;
            // @TODO: This is temporary solution!! Fix this :number_types:
            literal._string = base_literal.string_value; 

            if base_literal.integer_value == 0 {
                literal.value_type = .FLOAT;
                // literal._float = base_literal.float_value; // @TODO: Bug!!!
            } else {
                literal.value_type = .INT;
                // literal._int = base_literal.integer_value;
            }
    }

    return literal;
}

parse_array_subscript :: (tokenizer: *Tokenizer) -> *Array_Subscript {
    array_subscript := New(Array_Subscript);
    eat_token(tokenizer, #char "[");
    array_subscript.subscript = parse(tokenizer); 
    eat_token(tokenizer, #char "]");
    return array_subscript;
}

parse_array_type :: (tokenizer: *Tokenizer) -> *Array_Type {
    array_type := New(Array_Type);

    eat_token(tokenizer, #char "[");

    if !is_token(tokenizer, #char "]") {

        if maybe_eat_token(tokenizer, .DOUBLE_DOT) {
            array_type.resizable = true;
        } else {
            array_type.dimension = parse(tokenizer);
        }

    }

    eat_token(tokenizer, #char "]");
    array_type.element_type = parse(tokenizer);

    return array_type;
}

is_unary_operator :: (tokenizer: *Tokenizer) -> bool {
    if is_token(tokenizer, #char ".")            return true;
    if is_token(tokenizer, #char "*")            return true;
    if is_token(tokenizer, #char "!")            return true;
    if is_token(tokenizer, #char "$")            return true;
    if is_token(tokenizer, .DOUBLE_DOLLAR)       return true;
    if is_token(tokenizer, .POINTER_DEREFERENCE) return true;
    if is_token(tokenizer, .DOUBLE_DOT)          return true;
    return false;
}

parse_polymorphic_constant :: (tokenizer: *Tokenizer, maybe_constant: bool) -> *Polymorphic_Constant {
    polymorphic_constant := New(Polymorphic_Constant);
    polymorphic_constant.maybe_constant = maybe_constant;

    if maybe_constant {
        eat_token(tokenizer, .DOUBLE_DOLLAR);
    } else {
        eat_token(tokenizer, #char "$");
    }

    polymorphic_constant.type = eat_token(tokenizer, .IDENTIFIER).string_value;

    if maybe_eat_token(tokenizer, #char "/") {

        if is_token(tokenizer, .KEYWORD_INTERFACE) {
            eat_token(tokenizer, .KEYWORD_INTERFACE);
            polymorphic_constant.restrictions_interface = true;
        }

        polymorphic_constant.restriction = parse(tokenizer);
    }

    return polymorphic_constant;
}

parse_unary_operation :: (tokenizer: *Tokenizer) -> *Unary_Operation {
    unary_operation := New(Unary_Operation);

    op := eat_token(tokenizer);
    
    if op.kind == {
        case #char ".";             unary_operation.operation = .DOT;
        case #char "*";             unary_operation.operation = .POINTER;
        case #char "!";             unary_operation.operation = .NEGATE;
        case .POINTER_DEREFERENCE;  unary_operation.operation = .POINTER_DEREFERENCE;
        case .DOUBLE_DOT;           unary_operation.operation = .ELLIPSIS;
    }

    unary_operation.expression = parse(tokenizer);

    return unary_operation;
}

parse_binary_operation :: (tokenizer: *Tokenizer, left: *Node) -> *Binary_Operation {
    binary_operation := New(Binary_Operation);
    binary_operation.left = left;

    op := eat_token(tokenizer);
    assert(is_operator(op));
    binary_operation.operation = create_operator_from_token(op.kind);

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

parse_continue :: (tokenizer: *Tokenizer) -> *Node {
    _continue := New(Continue);
    eat_token(tokenizer, .KEYWORD_CONTINUE);

    if !is_token(tokenizer, #char ";") {
        _continue.expression = parse(tokenizer);
    }

    return _continue;
}

parse_defer :: (tokenizer: *Tokenizer) -> *Node {
    _defer := New(Defer);
    defer_token := eat_token(tokenizer, .KEYWORD_DEFER);

    _defer.backticked = defer_token.backticked;

    if !is_token(tokenizer, #char ";") {
        _defer.expression = parse(tokenizer);
    }

    return _defer;
}

parse_while :: (tokenizer: *Tokenizer) -> *Node {
    _while := New(While);
    eat_token(tokenizer, .KEYWORD_WHILE);
    _while.expression = parse(tokenizer);
    _while.body = parse(tokenizer);
    return _while;
}

parse_for :: (tokenizer: *Tokenizer) -> *Node {
    _for := New(For);

    eat_token(tokenizer, .KEYWORD_FOR);

    if maybe_eat_token(tokenizer, #char "<") {
        _for.reversed = true;
        _for.by_pointer = maybe_eat_token(tokenizer, #char "*");
    }
    
    if maybe_eat_token(tokenizer, #char "*") {
        _for.by_pointer = true;
        _for.reversed = maybe_eat_token(tokenizer, #char "<");
    }

    // Only iterator
    if !is_token(tokenizer, #char ":", 1) && !is_token(tokenizer, #char ",", 1) {
        _for.iterator = parse(tokenizer);
    } else {
        _for.index = parse_identifier(eat_token(tokenizer, .IDENTIFIER));

        // @TODO: Is this correct?
        if maybe_eat_token(tokenizer, #char ",") {
            _for.value = parse_identifier(eat_token(tokenizer, .IDENTIFIER));
        } else {
            _for.value = _for.index;
            _for.index = null;
        }

        eat_token(tokenizer, #char ":");
        _for.iterator = parse(tokenizer);
    }

    _for.body = parse(tokenizer);
    return _for;
}

parse_if :: (tokenizer: *Tokenizer) -> *Node {
    _if := New(If);
    
    if_token: *Token;

    if is_token(tokenizer, .KEYWORD_IFX) {
        if_token = eat_token(tokenizer, .KEYWORD_IFX);
        _if.if_kind = .IFX;
    } else {
        if_token = eat_token(tokenizer, .KEYWORD_IF);
        _if.if_kind = .IF;
    }

    has_directive, directive_token := maybe_eat_token(tokenizer, .DIRECTIVE);
    if has_directive && directive_token.string_value == "complete" {
        _if.marked_as_complete = true;
    }

    _if.condition = parse(tokenizer);

    switch := false;

    if _if.condition && _if.condition.kind == .BINARY_OPERATION {
        binary_op := cast(*Binary_Operation) _if.condition;
        switch = binary_op.operation == .IS_EQUAL && binary_op.right && binary_op.right.kind == .BLOCK;
    }

    if !switch {
        maybe_eat_token(tokenizer, .KEYWORD_THEN);
        _if._then = parse(tokenizer);
    
        if maybe_eat_token(tokenizer, .KEYWORD_ELSE) {
            _if._else = parse(tokenizer);
        }
    } else {
        _if.if_kind = .SWITCH;
    }

    return _if;
}

parse_case :: (tokenizer: *Tokenizer) -> *Node {
    _case := New(Case);
    eat_token(tokenizer, .KEYWORD_CASE);
    _case.expression = parse(tokenizer);
    maybe_eat_token(tokenizer, #char ";");
    _case.members = eat_until(tokenizer, token => token.kind == .KEYWORD_CASE || token.kind == #char "}");
    return _case;
}

parse_break :: (tokenizer: *Tokenizer) -> *Node {
    _break := New(Break);
    eat_token(tokenizer, .KEYWORD_BREAK);

    if !is_token(tokenizer, #char ";") {
        _break.expression = parse(tokenizer);
    }

    return _break;
}

parse_using :: (tokenizer: *Tokenizer) -> *Node {
    _using := New(Using);
    using_token := eat_token(tokenizer, .KEYWORD_USING);

    // modifiers
    if is_token(tokenizer, #char ",") {
        eat_token(tokenizer, #char ",");

        modifier := eat_token(tokenizer, .IDENTIFIER);

        if modifier.string_value == {
            case "map";
             _using.filter_type = .MAP;
            case "except";
             _using.filter_type = .EXCEPT;
            case "only";
             _using.filter_type = .ONLY;
        }
    }

    if is_token(tokenizer, #char "(") {
        _using.filters = delimeted(tokenizer, #char "(", #char ")", #char ",");
    }

    _using.expression = parse(tokenizer);

    return _using;
}

parse_cast :: (tokenizer: *Tokenizer) -> *Cast {
    _cast := New(Cast);
    cast_token := eat_token(tokenizer, .KEYWORD_CAST);

    // modifiers
    if is_token(tokenizer, #char ",") {
        eat_token(tokenizer, #char ",");

        modifier := eat_token(tokenizer, .IDENTIFIER);

        if modifier.string_value == {
            case "trunc";
             _cast.truncate = true;
            case "no_check";
             _cast.no_check = true;
        }
    }

    eat_token(tokenizer, #char "(");
    _cast.cast_expression = parse(tokenizer);
    eat_token(tokenizer, #char ")");

    _cast.expression = parse(tokenizer);

    return _cast;
}

parse_auto_cast :: (tokenizer: *Tokenizer) -> *Auto_Cast {
    auto_cast := New(Auto_Cast);
    eat_token(tokenizer, .KEYWORD_AUTO_CAST);
    auto_cast.expression = parse(tokenizer);
    return auto_cast;
}

parse_inline :: (tokenizer: *Tokenizer) -> *Node {
    eat_token(tokenizer, .KEYWORD_INLINE);
    next_node := parse(tokenizer);

    if next_node.kind == .PROCEDURE {
        (cast(*Procedure) next_node).flags |= .INLINE;
    }

    if next_node.kind == .PROCEDURE_CALL {
        (cast(*Procedure_Call) next_node).inlined = true;
    } 

    return next_node;
}

parse_push_context :: (tokenizer: *Tokenizer) -> *Push_Context {
    _push_context := New(Push_Context);

    push_context_token := eat_token(tokenizer, .KEYWORD_PUSH_CONTEXT);
    _push_context.backticked = push_context_token.backticked;

    if maybe_eat_token(tokenizer, #char ",") {
        modifier_token := eat_token(tokenizer, .IDENTIFIER);
        _push_context.defer_pop = modifier_token.string_value == "defer_pop";
    }

    _push_context.pushed = parse(tokenizer);

    // @TODO: Block only?
    if is_token(tokenizer, #char "{") {
        _push_context.block = parse_block(tokenizer);
    }

    return _push_context;
}

parse_operator_overload :: (tokenizer: *Tokenizer) -> *Operator_Overload {
    operator_overload := New(Operator_Overload);

    eat_token(tokenizer, .KEYWORD_OPERATOR);

    op := eat_token(tokenizer);
    assert(is_operator(op));
    operator_overload.operation = create_operator_from_token(op.kind);

    eat_token(tokenizer, .CONSTANT_DECLARATION);

    operator_overload.procedure = parse_procedure(tokenizer);

    return operator_overload;
}

// @TODO: We currently don't parse ASM blocks body.
// @TODO: We want catch the ASM block probably at tokenizer level not in parser. (useless tokens being created)
parse_inline_assembly :: (tokenizer: *Tokenizer) -> *Inline_Assembly {
    inline_assembly := New(Inline_Assembly);

    if !is_token(tokenizer, #char "{") {
        inline_assembly.expression = parse(tokenizer);
    }

    eat_token(tokenizer, #char "{");
    while !is_token(tokenizer, #char "}") eat_token(tokenizer);
    eat_token(tokenizer, #char "}");

    return inline_assembly;
}