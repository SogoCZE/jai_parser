// @TODO:
// - Split parsing into multiple files? 

// To Parse:

// - notes
// - multiple assings declaration (a, b := 1, 2)
// - multiple declaration (a, b: int)

// Scope:
// - #scope_export
// - #scope_file
// - #scope_module

// ??:
// - type keywords (is this needed?)
// - #insert_internal - deprecated

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
        RETURN_VALUE;
        ARRAY_TYPE;
        ARRAY_SUBSCRIPT;
        IDENTIFIER;
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
        // TYPE_INSTANTIATION;

        DIRECTIVE_IMPORT;
        DIRECTIVE_LOAD;
        DIRECTIVE_RUN;
        DIRECTIVE_CHAR;
        DIRECTIVE_AS;
        DIRECTIVE_PLACE;
        DIRECTIVE_TYPE;
        DIRECTIVE_CODE;
        DIRECTIVE_ADD_CONTEXT;
        DIRECTIVE_ASSERT;
        DIRECTIVE_BYTES;
        DIRECTIVE_LIBRARY;
        DIRECTIVE_NO_RESET;
        DIRECTIVE_INSERT;
        DIRECTIVE_LOCATION;
        DIRECTIVE_MODULE_PARAMETERS;
        DIRECTIVE_PLACEHOLDER;
        DIRECTIVE_PROCEDURE_OF_CALL;
        DIRECTIVE_PROGRAM_EXPORT;
        DIRECTIVE_THIS;
        DIRECTIVE_POKE_NAME;
        DIRECTIVE_BAKE_ARGUMENTS;
        DIRECTIVE_BAKE_CONSTANTS;
        DIRECTIVE_DYNAMIC_SPECIALIZE;
        DIRECTIVE_CALLER_CODE;
        DIRECTIVE_CALLER_LOCATION;
        DIRECTIVE_FILE;
        DIRECTIVE_FILEPATH;
        DIRECTIVE_LINE;
        DIRECTIVE_THROUGH;
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
    no_abc: bool; // #no_abc

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

    Flags :: enum_flags {
        INLINE;                    
        MACRO;
        NO_CONTEXT;
        DEBUG_DUMP;                    
        CPP_RETURN_TYPE_IS_NON_POD;       
        CPP_METHOD;
        NO_DEBUG;
        C_CALL;                        
        INTRINSIC;                     
        COMPILER;     
        ELSEWHERE;                     
        FOREIGN;               
        NO_CALL;
        DEPRECATED;       
        MUST_CONSUME_ALL_RETURNS;       
        NO_ALIAS;      
        RUNTIME_SUPPORT;      
        SYMMETRIC;      
        NO_ABC;
    }

    foreign_lib: string;
    foreign_alias: string;
    elsewhere: string;
    intrinsic: string;
    deprecated_note: string;

    flags: Flags;
    arguments: []*Node;
    returns: []*Return_Value;
    modify_block: *Block;
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

Return_Value :: struct {
    using #as node: Node;
    kind = .RETURN_VALUE;

    must: bool;
    expression: *Node;
}

Struct :: struct {
    using #as node: Node; 
    kind = .STRUCT;

    Flags :: enum_flags {
        TYPE_INFO_NO_SIZE_COMPLAINT;
        TYPE_INFO_PROCEDURES_ARE_VOID_POINTERS;
        TYPE_INFO_NONE;
        NO_PADDING;
    }

    flags: Flags;
    polymorphic_arguments: [] *Node;
    modify_block: *Block;
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

    specified: bool;
    is_enum_flags: bool;
    type: *Node;
    block: *Block;
}

If :: struct {
    using #as node: Node;
    kind = .IF;

    If_Kind :: enum u8 {
        UNKNOWN;
        IF;
        IFX;
        SWITCH;
    }

    compile_time: bool;
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

Directive_Import :: struct {
    using #as node: Node; 
    kind = .DIRECTIVE_IMPORT;

    Import_Kind :: enum u8 {
        MODULE;
        FILE;
        DIR;
        STRING;
    }

    import_kind: Import_Kind;
    module: string;
}

Directive_Load :: struct {
    using #as node: Node; 
    kind = .DIRECTIVE_LOAD;

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
    BITWISE; // &
    PIPE; // |

    BITWISE_EQUAL; // &=
    PIPE_EQUAL; // |=
    GREATER_EQUAL; // >=
    LESS_EQUAL; // <=
    PLUS_EQUAL; // +=
    MINUS_EQUAL; // -=
    MOD_EQUAL; // %=
    DIV_EQUAL; // /=
    TIMES_EQUAL; // *=
    LOGICAL_AND; // &&
    LOGICAL_AND_ASSIGNMENT; // &&=
    LOGICAL_OR; // ||
    LOGICAL_OR_ASSIGNMENT; // ||=
    IS_EQUAL; // ==
    IS_NOT_EQUAL; // !=
    LEFT_SHIFT; // <<, POINTER_DEREFERENCE
    RIGHT_SHIFT; // >>
    LEFT_SHIFT_ASSIGNMENT; // <<= 
    RIGHT_SHIFT_ASSIGNMENT; // >>=
    UNSIGNED_RIGHT_SHIFT; // >>>
    UNSIGNED_LEFT_SHIFT; // <<<
    UNSIGNED_RIGHT_SHIFT_ASSIGNMENT; // >>>=
    UNSIGNED_LEFT_SHIFT_ASSIGNMENT; // <<<=
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

Directive_Bake_Arguments :: struct {
    using #as node: Node;
    kind = .DIRECTIVE_BAKE_ARGUMENTS;

    expression: *Node;
}

Directive_Bake_Constants :: struct {
    using #as node: Node;
    kind = .DIRECTIVE_BAKE_CONSTANTS;

    expression: *Node;
}

Directive_Bytes :: struct {
    using #as node: Node;
    kind = .DIRECTIVE_BYTES;

    expression: *Node;
}

Directive_Library :: struct {
    using #as node: Node;
    kind = .DIRECTIVE_LIBRARY;

    system: bool;
    no_static_library: bool;
    name: string;    
}

Directive_No_Reset :: struct {
    using #as node: Node;
    kind = .DIRECTIVE_NO_RESET;

    expression: *Node;
}

Directive_Insert :: struct {
    using #as node: Node;
    kind = .DIRECTIVE_INSERT;

    Insert_Kind :: enum {
        UNKNOWN;
        STRING;
        CODE;
    }

    type: Insert_Kind; // Set when using -> Code or -> string
    scoped: bool; // #insert,scope()
    scope: *Node; // #insert,scope(scope)
    expression: *Node;
}

Directive_Location :: struct {
    using #as node: Node;
    kind = .DIRECTIVE_LOCATION;

    expression: *Node;
}

Directive_Module_Parameters :: struct {
    using #as node: Node;
    kind = .DIRECTIVE_MODULE_PARAMETERS;

    // @TODO: rename this (currently we don't know why does the directive have double parameters)
    parameters: [] *Node;
    second_parameters: [] *Node;
}

Directive_Placeholder :: struct {
    using #as node: Node;
    kind = .DIRECTIVE_PLACEHOLDER;

    expression: *Node;
}

Directive_Procedure_Of_Call :: struct {
    using #as node: Node;
    kind = .DIRECTIVE_PROCEDURE_OF_CALL;

    expression: *Node;
}

Directive_Program_Export :: struct {
    using #as node: Node;
    kind = .DIRECTIVE_PROGRAM_EXPORT;

    exported_name: string;
    expression: *Node;
}

Directive_This :: struct {
    using #as node: Node;
    kind = .DIRECTIVE_THIS;

    arguments: [] *Node; // In-case of #this(10, 20) - where #this is procedure.
}

Directive_Poke_Name :: struct {
    using #as node: Node;
    kind = .DIRECTIVE_POKE_NAME;

    module: string;
    name: string; 
}

Directive_Dynamic_Specialize :: struct {
    using #as node: Node;
    kind = .DIRECTIVE_DYNAMIC_SPECIALIZE;

    expression: *Node;
}

Directive_Caller_Code :: struct {
    using #as node: Node;
    kind = .DIRECTIVE_CALLER_CODE;
}

Directive_Caller_Location :: struct {
    using #as node: Node;
    kind = .DIRECTIVE_CALLER_LOCATION;
}

Directive_File :: struct {
    using #as node: Node;
    kind = .DIRECTIVE_FILE;
}

Directive_Filepath :: struct {
    using #as node: Node;
    kind = .DIRECTIVE_FILEPATH;
}

Directive_Line :: struct {
    using #as node: Node;
    kind = .DIRECTIVE_LINE;
}

Directive_Through :: struct {
    using #as node: Node;
    kind = .DIRECTIVE_THROUGH;
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
    // @TODO: this is totally silly we could use some sort of metaprogramming to make this automaticly...
    if kind == {
        case #char ">";                           return .GREATER;
        case #char "<";                           return .LESS;
        case #char "+";                           return .ADDITION;
        case #char "-";                           return .SUBTRACTION;
        case #char "*";                           return .MULTIPLICATION;
        case #char "/";                           return .DIVISION;
        case #char "%";                           return .MODULO;
        case #char "=";                           return .ASSING;
        case #char ".";                           return .DOT;
        case #char "&";                           return .BITWISE;
        case #char "|";                           return .PIPE;

        case .BITWISE_EQUAL;                      return .BITWISE_EQUAL;
        case .PIPE_EQUAL;                         return .PIPE_EQUAL;
        case .GREATER_EQUAL;                      return .GREATER_EQUAL;
        case .LESS_EQUAL;                         return .LESS_EQUAL;
        case .PLUS_EQUAL;                         return .PLUS_EQUAL;
        case .MINUS_EQUAL;                        return .MINUS_EQUAL;
        case .MOD_EQUAL;                          return .MOD_EQUAL;
        case .DIV_EQUAL;                          return .DIV_EQUAL;
        case .TIMES_EQUAL;                        return .TIMES_EQUAL;
        case .LOGICAL_AND;                        return .LOGICAL_AND;
        case .LOGICAL_AND_ASSIGNMENT;             return .LOGICAL_AND_ASSIGNMENT;
        case .LOGICAL_OR;                         return .LOGICAL_OR;
        case .LOGICAL_OR_ASSIGNMENT;              return .LOGICAL_OR;
        case .IS_EQUAL;                           return .IS_EQUAL;
        case .IS_NOT_EQUAL;                       return .IS_NOT_EQUAL;
        case .DOUBLE_DOT;                         return .RANGE;

        case .LEFT_SHIFT;                         return .LEFT_SHIFT;
        case .RIGHT_SHIFT;                        return .RIGHT_SHIFT;
        case .LEFT_SHIFT_ASSIGNMENT;              return .LEFT_SHIFT_ASSIGNMENT;
        case .RIGHT_SHIFT_ASSIGNMENT;             return .RIGHT_SHIFT_ASSIGNMENT;
        case .UNSIGNED_RIGHT_SHIFT;               return .UNSIGNED_RIGHT_SHIFT;
        case .UNSIGNED_LEFT_SHIFT;                return .UNSIGNED_LEFT_SHIFT;
        case .UNSIGNED_RIGHT_SHIFT_ASSIGNMENT;    return .UNSIGNED_RIGHT_SHIFT_ASSIGNMENT;
        case .UNSIGNED_LEFT_SHIFT_ASSIGNMENT;     return .UNSIGNED_LEFT_SHIFT_ASSIGNMENT;
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

        if node.kind == .DIRECTIVE_IMPORT {
            _import := cast(*Directive_Import) node;

            path: string;

            if _import.import_kind == {
                case .MODULE;
                    module_path := tprint("%/%", JAI_MODULES_PATH, _import.module);
                    path = get_module_entry(module_path);
                case .FILE;
                    path = tprint("%/%", path_without_filename, _import.module); 
                case .DIR;
                    path = tprint("%/%", path_without_filename, get_module_entry(_import.module)); 
                case .STRING;
                    // @TODO: Do we wanna parse the string here?
            }

            parse_file(files, path); // @TODO: Run this in another thread?
        }

        if node.kind == .DIRECTIVE_LOAD {
            _load := cast(*Directive_Load) node;
            load_relative_path := tprint("%/%", path_without_filename, _load.file);
            parse_file(files, load_relative_path); // @TODO: Run this in another thread?
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

    // returns
    if meaybe_eat_token(tokenizer, .ARROW_RIGHT) {
        meaybe_eat_token(tokenizer, #char "(");
        returns: [..]*Return_Value;

        while !end(tokenizer) && !is_token(tokenizer, #char ")") && !is_token(tokenizer, #char "{") {
            if maybe_eat_token(tokenizer, #char ",") continue; 

            return_value := New(Return_Value);
            return_value.expression = parse(tokenizer);

            if is_token(tokenizer, t => t.kind == .DIRECTIVE && t.string_value == "must") {
                eat_token(tokenizer, .DIRECTIVE);
                return_value.must = true;
            }

            array_add(*returns, return_value);
        }

        // If the last return value is must all the returns must be consumed.
        if returns.count > 0 && returns[returns.count-1].must {
            proc.flags |= .MUST_CONSUME_ALL_RETURNS;
        }

        proc.returns = returns;
        meaybe_eat_token(tokenizer, #char ")");
    }

    parse_proc_directive :: (tokenizer: *Tokenizer, proc: *Procedure) {
        directive := eat_token(tokenizer, .DIRECTIVE);

        if directive.string_value == {
            case "expand";
                proc.flags |= .MACRO;
            case "no_context";
                proc.flags |= .NO_CONTEXT;
            case "dump";
                proc.flags |= .DEBUG_DUMP;
            case "cpp_method";
                proc.flags |= .CPP_METHOD;
            case "cpp_return_type_is_non_pod";
                proc.flags |= .CPP_RETURN_TYPE_IS_NON_POD;
            case "no_debug";
                proc.flags |= .NO_DEBUG;
            case "c_call";
                proc.flags |= .NO_CONTEXT;
                proc.flags |= .C_CALL;
            case "intrinsic";
                proc.flags |= .INTRINSIC;
                proc.intrinsic = eat_token(tokenizer, .IDENTIFIER).string_value;
            case "compiler";
                proc.flags |= .COMPILER;
            case "elsewhere";
                proc.flags |= .ELSEWHERE;
                proc.elsewhere = eat_token(tokenizer, .IDENTIFIER).string_value;
            case "foreign";
                proc.flags |= .FOREIGN;
                proc.foreign_lib = eat_token(tokenizer, .IDENTIFIER).string_value;
                if is_token(tokenizer, .STRING) {
                    proc.foreign_alias = eat_token(tokenizer, .STRING).string_value;
                }
            case "no_call";
                proc.flags |= .NO_CALL;
            case "deprecated";
                proc.flags |= .DEPRECATED;
                if is_token(tokenizer, .STRING) {
                    proc.deprecated_note = eat_token(tokenizer, .STRING).string_value;
                }
            case "no_alias";
                proc.flags |= .NO_ALIAS;
            case "runtime_support";
                proc.flags |= .RUNTIME_SUPPORT;
            case "symmetric"; // @TODO: this is only needed for Operator Overload
                proc.flags |= .SYMMETRIC;
            case "modify";
                proc.modify_block = parse_block(tokenizer);
            case "no_abc";
                proc.flags |= .NO_ABC;
        }

        if is_token(tokenizer, .DIRECTIVE) {
            parse_proc_directive(tokenizer, proc);
        }
    }   

    // Directives
    if is_token(tokenizer, .DIRECTIVE) {
        parse_proc_directive(tokenizer, proc);
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

    parse_struct_directive :: (tokenizer: *Tokenizer, _struct: *Struct) {
        directive := eat_token(tokenizer, .DIRECTIVE);

        if directive.string_value == {
            case "modify";
                _struct.modify_block = parse_block(tokenizer);
            case "type_info_no_size_complaint";
                _struct.flags |= .TYPE_INFO_NO_SIZE_COMPLAINT;
            case "type_info_procedures_are_void_pointers";
                _struct.flags |= .TYPE_INFO_PROCEDURES_ARE_VOID_POINTERS;
            case "type_info_none";
                _struct.flags |= .TYPE_INFO_NONE;
        }

        if is_token(tokenizer, .DIRECTIVE) {
            parse_struct_directive(tokenizer, _struct);
        }
    }

    // Directives
    if is_token(tokenizer, .DIRECTIVE) {
        parse_struct_directive(tokenizer, _struct);
    }

    if is_token(tokenizer, #char "{") {
        _struct.block = parse_block(tokenizer);
    } else {
        print("Exprected struct body! Got:");
        print_token(peek_token(tokenizer));
    }

    if is_token(tokenizer, token => token.kind == .DIRECTIVE && token.string_value == "no_padding") {
        eat_token(tokenizer, .DIRECTIVE);
        _struct.flags |= .NO_PADDING;
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

    // Specified directive
    if is_token(tokenizer, token => token.kind == .DIRECTIVE && token.string_value == "specified") {
        eat_token(tokenizer, .DIRECTIVE);
        _enum.specified = true;
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
        case "import";              return parse_directive_import(tokenizer);
        case "load";                return parse_directive_load(tokenizer);
        case "run";                 return parse_directive_run(tokenizer);
        case "as";                  return parse_directive_as(tokenizer);
        case "place";               return parse_directive_place(tokenizer);
        case "type";                return parse_directive_type(tokenizer);
        case "code";                return parse_directive_code(tokenizer);
        case "char";                return parse_directive_char(tokenizer);
        case "add_context";         return parse_directive_add_context(tokenizer);
        case "assert";              return parse_directive_assert(tokenizer);
        case "bake_arguments";      return parse_directive_bake_arguments(tokenizer);
        case "bake_constants";      return parse_directive_bake_constants(tokenizer);
        case "bytes";               return parse_directive_bytes(tokenizer);
        case "no_reset";            return parse_directive_no_reset(tokenizer);
        case "insert";              return parse_directive_insert(tokenizer);
        case "location";            return parse_directive_location(tokenizer);
        case "module_parameters";   return parse_directive_module_parameters(tokenizer);
        case "placeholder";         return parse_directive_placeholder(tokenizer);
        case "procedure_of_call";   return parse_directive_procedure_of_call(tokenizer);
        case "program_export";      return parse_directive_program_export(tokenizer);
        case "this";                return parse_directive_this(tokenizer);
        case "poke_name";           return parse_directive_poke_name(tokenizer);
        case "dynamic_specialize";  return parse_directive_dynamic_specialize(tokenizer);
        case "caller_code";         return parse_directive_caller_code(tokenizer);
        case "caller_location";     return parse_directive_caller_location(tokenizer);
        case "file";                return parse_directive_file(tokenizer);
        case "filepath";            return parse_directive_filepath(tokenizer);
        case "line";                return parse_directive_line(tokenizer);
        case "through";             return parse_directive_through(tokenizer);

        case "library";             return parse_directive_library(tokenizer, false);
        case "system_library";      return parse_directive_library(tokenizer, true);

        case "asm";                 return parse_inline_assembly(tokenizer);
        case "if";                  return parse_if(tokenizer, .IF, true);
        case "ifx";                 return parse_if(tokenizer, .IFX, true);
    }

    // @TODO: Unknown directive?
    eat_token(tokenizer);
    log_error("Unknown directive #%!", directive_token.string_value);

    return null;
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

parse_directive_import :: (tokenizer: *Tokenizer) -> *Directive_Import {
    directive_import := New(Directive_Import);

    if maybe_eat_token(tokenizer, #char ",") {
        ok, modifier_token := maybe_eat_token(tokenizer, t => t.kind == .IDENTIFIER);
        if ok {

            if modifier_token.string_value == {
                case "file"; directive_import.import_kind = .FILE;
                case "dir"; directive_import.import_kind = .DIR;
                case "string"; directive_import.import_kind = .STRING;
            }

        }

    }

    directive_import.module = eat_token(tokenizer, .STRING).string_value;
    
    return directive_import;
}

parse_directive_load :: (tokenizer: *Tokenizer) -> *Directive_Load {
    directive_load := New(Directive_Load);
    directive_load.file = eat_token(tokenizer, .STRING).string_value;
    return directive_load;
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

parse_directive_bake_arguments :: (tokenizer: *Tokenizer) -> *Directive_Bake_Arguments {
    directive_bake_arguments := New(Directive_Bake_Arguments);
    directive_bake_arguments.expression = parse(tokenizer);

    return directive_bake_arguments;
}

parse_directive_bake_constants :: (tokenizer: *Tokenizer) -> *Directive_Bake_Constants {
    directive_bake_constants := New(Directive_Bake_Constants);
    directive_bake_constants.expression = parse(tokenizer);

    return directive_bake_constants;
}

parse_directive_bytes :: (tokenizer: *Tokenizer) -> *Directive_Bytes {
    directive_bytes := New(Directive_Bytes);
    directive_bytes.expression = parse(tokenizer);

    return directive_bytes;
}

parse_directive_library :: (tokenizer: *Tokenizer, system: bool) -> *Directive_Library {
    directive_library := New(Directive_Library);
    directive_library.system = system; 

    if maybe_eat_token(tokenizer, #char ",") && maybe_eat_token(tokenizer, token => token.string_value == "no_static_library") {
        directive_library.no_static_library = true;
    }

    if is_token(tokenizer, .STRING) {
        name_token := eat_token(tokenizer, .STRING);
        directive_library.name = name_token.string_value;
    }

    return directive_library;
}

parse_directive_no_reset :: (tokenizer: *Tokenizer) -> *Directive_No_Reset {
    directive_no_reset := New(Directive_No_Reset);
    directive_no_reset.expression = parse(tokenizer);

    return directive_no_reset;
}

parse_directive_insert :: (tokenizer: *Tokenizer) -> *Directive_Insert {
    directive_insert := New(Directive_Insert);
    
    if maybe_eat_token(tokenizer, #char ",") 
    && maybe_eat_token(tokenizer, token => token.string_value == "scope") {
        directive_insert.scoped = true;

        maybe_eat_token(tokenizer, #char "(");
    
        if !is_token(tokenizer, #char ")") {
            directive_insert.scope = parse(tokenizer);
        }

        maybe_eat_token(tokenizer, #char ")");
    }

    if maybe_eat_token(tokenizer, .ARROW_RIGHT) {
        insert_type_ident := eat_token(tokenizer, .IDENTIFIER);
        
        if insert_type_ident.string_value == {
            case "string"; directive_insert.type   = .STRING;
            case "Code"; directive_insert.type     = .CODE;
        }

    }

    directive_insert.expression = parse(tokenizer);

    return directive_insert;
}

parse_directive_location :: (tokenizer: *Tokenizer) -> *Directive_Location {
    directive_location := New(Directive_Location);

    if maybe_eat_token(tokenizer, #char "(") {
        
        if !is_token(tokenizer, #char ")") {
            directive_location.expression = parse(tokenizer);
        }
        
        eat_token(tokenizer, #char ")");
    }

    return directive_location;
}

parse_directive_module_parameters :: (tokenizer: *Tokenizer) -> *Directive_Module_Parameters {
    directive_module_parameters := New(Directive_Module_Parameters);

    if is_token(tokenizer, #char "(") {
        directive_module_parameters.parameters = delimeted(tokenizer, #char "(", #char ")", #char ",");
    }

    if is_token(tokenizer, #char "(") {
        directive_module_parameters.second_parameters = delimeted(tokenizer, #char "(", #char ")", #char ",");
    }

    return directive_module_parameters;
}

parse_directive_placeholder :: (tokenizer: *Tokenizer) -> *Directive_Placeholder {
    directive_placeholder := New(Directive_Placeholder);

    directive_placeholder.expression = parse(tokenizer);

    return directive_placeholder;
}

parse_directive_procedure_of_call :: (tokenizer: *Tokenizer) -> *Directive_Procedure_Of_Call {
    directive_procedure_of_call := New(Directive_Procedure_Of_Call);

    directive_procedure_of_call.expression = parse(tokenizer);

    return directive_procedure_of_call;
}

parse_directive_program_export :: (tokenizer: *Tokenizer) -> *Directive_Program_Export {
    directive_program_export := New(Directive_Program_Export);

    if is_token(tokenizer, .STRING) {
        name_token := eat_token(tokenizer, .STRING);
        directive_program_export.exported_name = name_token.string_value;
    }

    directive_program_export.expression = parse(tokenizer);

    return directive_program_export;
}

parse_directive_this :: (tokenizer: *Tokenizer) -> *Directive_This {
    directive_this := New(Directive_This);

    if is_token(tokenizer, #char "(") {
        directive_this.arguments = delimeted(tokenizer, #char "(", #char ")", #char ",");
    }

    return directive_this;
}

parse_directive_poke_name :: (tokenizer: *Tokenizer) -> *Directive_Poke_Name {
    directive_poke_name := New(Directive_Poke_Name);

    if is_token(tokenizer, .IDENTIFIER) {
        module_token := eat_token(tokenizer, .IDENTIFIER);
        directive_poke_name.module = module_token.string_value;
    }
    
    if is_token(tokenizer, .IDENTIFIER) {
        name_token := eat_token(tokenizer, .IDENTIFIER);
        directive_poke_name.name = name_token.string_value;
    }

    return directive_poke_name;
}

parse_directive_dynamic_specialize :: (tokenizer: *Tokenizer) -> *Directive_Dynamic_Specialize {
    dynamic_specialize := New(Directive_Dynamic_Specialize);

    dynamic_specialize.expression = parse(tokenizer);

    return dynamic_specialize;
}

// @TODO: Those empty directives are kinda dumb... We could probably return then directly in parse_directive...
parse_directive_caller_code :: (tokenizer: *Tokenizer) -> *Directive_Caller_Code {
    return New(Directive_Caller_Code);
}

parse_directive_caller_location :: (tokenizer: *Tokenizer) -> *Directive_Caller_Location {
    return New(Directive_Caller_Location);
}

parse_directive_file :: (tokenizer: *Tokenizer) -> *Directive_File {
    return New(Directive_File);
}

parse_directive_filepath :: (tokenizer: *Tokenizer) -> *Directive_Filepath {
    return New(Directive_Filepath);
}

parse_directive_line :: (tokenizer: *Tokenizer) -> *Directive_Line {
    return New(Directive_Line);
}
 
parse_directive_through :: (tokenizer: *Tokenizer) -> *Directive_Through {
    return New(Directive_Through);
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
    if is_token(tokenizer, .LEFT_SHIFT)          return true;
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
        case .LEFT_SHIFT;           unary_operation.operation = .POINTER_DEREFERENCE;
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

    if maybe_eat_token(tokenizer, t => t.kind == .DIRECTIVE && t.string_value == "no_abc") {
        _for.no_abc = true;
    }

    _for.body = parse(tokenizer);
    return _for;
}

parse_if :: (tokenizer: *Tokenizer, kind: If.If_Kind = .UNKNOWN, compile_time := false) -> *Node {
    _if := New(If);
    _if.compile_time = compile_time;
    
    if kind == .UNKNOWN {
        if_token: *Token;

        if is_token(tokenizer, .KEYWORD_IFX) {
            if_token = eat_token(tokenizer, .KEYWORD_IFX);
            _if.if_kind = .IFX;
        } else {
            if_token = eat_token(tokenizer, .KEYWORD_IF);
            _if.if_kind = .IF;
        }
    } else {
        _if.if_kind = kind;
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
    // assert(is_operator(op));
    operator_overload.operation = create_operator_from_token(op.kind);

    eat_token(tokenizer, .CONSTANT_DECLARATION);

    operator_overload.procedure = parse(tokenizer);

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