Parser :: struct(User_Data_Type: Type) {
    lexer: *Lexer;
    node_visit: (node: *Node, user_data: User_Data_Type);
    user_data: User_Data_Type;
    inside_proc_args: bool;
}

Node :: struct {

    Kind :: enum {
        UNINITIALIZATED;
        DECLARATION;
        COMPOUND_DECLARATION;
        COMPOUND_DECLARATION_ITEM;
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
        COMMA_SEPERATED_EXPRESSION;
        IF;
        CASE;
        BREAK;
        FOR;
        WHILE;
        INITIALIZE_ZERO;
        INLINE_ASSEMBLY;

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
        DIRECTIVE_PROCEDURE_NAME;
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
        DIRECTIVE_SCOPE;
        DIRECTIVE_COMPILE_TIME;
        DIRECTIVE_DISCARD;
        DIRECTIVE_EXISTS;

        NOTE;
    }

    Location :: struct {
        l0,c0,l1,c1: int;
        file: string;
    }

    parent: *Node;

    location: Location;
    kind: Kind;
}

Note :: struct {
    using #as node: Node;
    kind = .NOTE;

    name: string;
    value: string;
}

Declaration :: struct {
    using #as node: Node;
    kind = .DECLARATION;

    name: string;
    const: bool;
    has_elsewhere: bool;
    elsewhere: string;
    type_inst: *Node;
    expression: *Node;
    backticked: bool;
    notes: [] *Note;
    alignment: int; // @TODO: move this maybe into Type Instantiation struct?
}

Compound_Declaration :: struct {
    using #as node: Node;
    kind = .COMPOUND_DECLARATION;

    members: [] *Node;

    type_inst: *Node;
    expression: *Node;
}

Compound_Declaration_Item :: struct {
    using #as node: Node;
    kind = .COMPOUND_DECLARATION_ITEM;

    Item_Kind :: enum {
        DECLARATION;
        ASSING;
    }

    item_kind: Item_Kind;
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
    no_aoc: bool; // #no_aoc

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
    filter_expression: *Node; // for cases like: using,except #run get_conflicting_names() Person;

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

    auto: bool;

    expression: *Node;
    cast_expression: *Node;

    truncate: bool;
    no_check: bool;
    force: bool;
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
    no_abc: bool; // #no_abc
}

For :: struct {
    using #as node: Node;
    kind = .FOR;

    by_pointer: bool;
    reversed: bool;
    no_abc: bool; // #no_abc
    no_aoc: bool; // #no_aoc

    value: *Node;
    index: *Node;
    iterator: *Node;
    body: *Node;
}

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
        NO_AOC;
    }

    header_location: Node.Location;

    foreign_lib: string;
    foreign_alias: string;
    elsewhere: string;
    intrinsic: string;
    deprecated_note: string;

    flags: Flags;
    arguments: []*Node;
    returns: []*Return_Value;
    modify_block: *Block;
    body: *Block;
    notes: [] *Note;
}

Procedure_Call :: struct {
    using #as node: Node;
    kind = .PROCEDURE_CALL;

    inlined: bool;
    backticked: bool;
    procedure: *Node;
    arguments: [] *Node;
    context_changes: []*Node;
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

    notes: [] *Note;
}

Union :: struct {
    using #as node: Node;
    kind = .UNION;
    polymorphic_arguments: [] *Node;

    block: *Block;
    notes: [] *Note;
}

Enum :: struct {
    using #as node: Node;
    kind = .ENUM;

    specified: bool;
    is_enum_flags: bool;
    type: *Node;
    block: *Block;
    notes: [] *Note;
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

    no_aoc: bool; // #no_aoc
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

    arguments: []*Node;
    import_kind: Import_Kind;
    module: string;
}

Directive_Load :: struct {
    using #as node: Node;
    kind = .DIRECTIVE_LOAD;

    file: string;
}

Directive_Scope :: struct {
    using #as node: Node;
    kind = .DIRECTIVE_SCOPE;

    Scope_Kind :: enum u8 {
        EXPORT;
        FILE;
        MODULE;
    }

    scope_kind: Scope_Kind;
    members: [] *Node;
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
    BITWISE_AND; // &
    PIPE; // |
    BITWISE_NOT; // ~
    BITWISE_XOR; // ^
    NEGATE; // !

    BITWISE_AND_ASSIGNMENT; // &=
    BITWISE_XOR_ASSIGNMENT; // ^=
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

    ARRAY_SUBSCRIPT; // []
    ARRAY_SUBSCRIPT_ASSIGNMENT; // []=
}

Binary_Operation :: struct {
    using #as node: Node;
    kind = .BINARY_OPERATION;

    left: *Node;
    operation: _Operator = .INVALID;
    right: *Node;
}

// @TODO: Maybe rename this? Because it can be also a baked argument:
// proc :: ($baked: i32)
// or Polymorphic_Constant
// proc :: (poly_arg: $T)
Polymorphic_Constant :: struct {
    using #as node: Node;
    kind = .POLYMORPHIC_CONSTANT;

    maybe_constant: bool;
    restrictions_interface: bool;
    restriction: *Node;

    expression: *Node;
}

Unary_Operation :: struct {
    using #as node: Node;
    kind = .UNARY_OPERATION;

    Operation :: enum {
        INVALID;

        PLUS;
        MINUS;
        NEGATE;
        DOT;
        POINTER;
        POINTER_DEREFERENCE;
        EXPAND;
        ELLIPSIS;
        BITWISE_NOT;
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
    host: bool;
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

Initialize_Zero :: struct {
    using #as node: Node;
    kind = .INITIALIZE_ZERO;
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

    link_always: bool;
    system: bool;
    no_static_library: bool;
    no_dll: bool;
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

Directive_Procedure_Name :: struct {
    using #as node: Node;
    kind = .DIRECTIVE_PROCEDURE_NAME;

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

Directive_Compile_Time :: struct {
    using #as node: Node;
    kind = .DIRECTIVE_COMPILE_TIME;
}

Directive_Discard :: struct {
    using #as node: Node;
    kind = .DIRECTIVE_DISCARD;
    expression: *Node;
}

Directive_Line :: struct {
    using #as node: Node;
    kind = .DIRECTIVE_LINE;
}

Directive_Through :: struct {
    using #as node: Node;
    kind = .DIRECTIVE_THROUGH;
}

Directive_Exists :: struct {
    using #as node: Node;
    kind = .DIRECTIVE_EXISTS;

    wait_for: *Node;
    expression: *Node;
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

    expression: *Node; // @TODO: rename this to array?
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

parse :: (parser: *Parser, parent: *Node) -> *Node {
    current_token := peek_token(parser.lexer);

    base_node := parse_node(parser);
    if !base_node return null;
    base_node.parent = parent;

    set_start_location(base_node, current_token);
    defer set_end_location(base_node, peek_token(parser.lexer, -1));

    can_contain_comma_separated_expression :: (kind: Node.Kind) -> bool {
        if kind == .BLOCK return true;
        if kind == .COMPOUND_DECLARATION return true;
        // if kind == .STRUCT return true;
        // if kind == .ENUM return true;
        // if kind == .UNION return true;
        // if kind == .BINARY_OPERATION return true;
        return false;
    }

    is_start_of_comma_separated :: (lexer: *Lexer) -> bool {
        if is_token(lexer, #char ",") return true;

        if !is_token(lexer, #char "=") && !is_token(lexer, #char ":") return false;
        if is_token(lexer, #char ",", 1) return true;

        return false;
    }

    // Comma Separated Expression, Compound Declaration ...
    if (parent == null || can_contain_comma_separated_expression(parent.kind)) && is_start_of_comma_separated(parser.lexer) {
        unprocessed_tokens: [..]Token;
        nodes: [..] *Node;

        nodes_types: Table(int, Compound_Declaration_Item.Item_Kind);
        init(*nodes_types);

        if maybe_eat_token(parser.lexer, #char "=") {
            table_add(*nodes_types, 0, .ASSING);
        } else if maybe_eat_token(parser.lexer, #char ":") {
            table_add(*nodes_types, 0, .DECLARATION);
        }

        eat_token(parser.lexer, #char ",");
        array_add(*nodes, base_node);

        parse_token_array :: (parser: *Parser, to: *[..] *Node, from: [..]Token, left := false) {

            // @TODO: Is there any buildin compiler util for this?
            get_type_from_pointer_type :: (info: Type) -> Type {
                p := cast(*Type_Info_Pointer) info;
                return get_type(p.pointer_to);
            }

            local_parser: #run get_type_from_pointer_type(type_of(parser)); // @TODO: is this ok?
            local_parser.node_visit = parser.node_visit;
            local_parser.user_data = parser.user_data;
            local_parser.lexer = New(Lexer);
            local_parser.lexer.tokens = from;

            while !end(local_parser.lexer) {
                node := parse(*local_parser, *(Node.{})); // @TODO: Parent hack!
                if !node continue;
                array_add(to, node);
            }
        }

        skip_brackets: int;
        item_index := 1;

        while !end(parser.lexer) {

            is_end :: (lexer: *Lexer, $peek := 0) -> bool {
                // @TODO: Anything else?
                if is_token(lexer, #char "=", peek) return true;
                if is_token(lexer, #char ":", peek) return true;
                if is_token(lexer, #char ";", peek) return true;
                if is_token(lexer, #char ")", peek) return true; // @TODO: maybe check for this only if we open the comma_seperated_expression with the ( ...
                if is_token(lexer, .DECLARATION_AND_ASSIGN, peek) return true;

                return false;
            }

            // For stuff like cast(float)x, cast(float)y inside comma separated expression.
            if is_token(parser.lexer, #char "(") skip_brackets += 1;
            if is_token(parser.lexer, #char ")") && skip_brackets > 0 {
                skip_brackets -= 1;
                array_add(*unprocessed_tokens, eat_token(parser.lexer));
                continue;
            }

            if is_token(parser.lexer, #char ":") {

                if is_token(parser.lexer, #char ",", 1) || is_end(parser.lexer, 1) {
                    eat_token(parser.lexer, #char ":");
                    table_add(*nodes_types, item_index, .DECLARATION);
                } else {
                    break;
                }

            }

            if is_token(parser.lexer, #char "=") {

                if is_token(parser.lexer, #char ",", 1) || is_end(parser.lexer, 1) {
                    eat_token(parser.lexer, #char "=");
                    table_add(*nodes_types, item_index, .ASSING);
                } else {
                    break;
                }

            }

            if maybe_eat_token(parser.lexer, #char ",") {
                parse_token_array(parser, *nodes, unprocessed_tokens);
                array_reset(*unprocessed_tokens);
                item_index += 1;
                continue;
            }

            if is_end(parser.lexer) break;

            array_add(*unprocessed_tokens, eat_token(parser.lexer));
        }

        // Left overs
        parse_token_array(parser, *nodes, unprocessed_tokens, true);

        transform_nodes_into_items :: (parent: *Node, nodes_types: Table(int, Compound_Declaration_Item.Item_Kind), nodes: []*Node, default: Compound_Declaration_Item.Item_Kind) {
            for node: nodes {
                item := New(Compound_Declaration_Item);
                item.parent = parent;

                item_kind, ok := table_find(*nodes_types, it_index);
                if ok {
                    item.item_kind = item_kind;
                } else {
                    item.item_kind = default;
                }

                set_start_location(item, node);
                set_end_location(item, node);

                node.parent = item;
                item.expression = node;

                nodes[it_index] = item;
            }
        }

        // Compound Declaration
        if maybe_eat_token(parser.lexer, #char ":") {
            compound_declaration := New(Compound_Declaration);

            transform_nodes_into_items(compound_declaration, nodes_types, nodes, .DECLARATION);

            compound_declaration.members = nodes;
            compound_declaration.parent = parent;
            compound_declaration.type_inst = parse(parser, compound_declaration);

            set_start_location(compound_declaration, base_node);
            set_end_location(compound_declaration, peek_token(parser.lexer, -1));
            parser.node_visit(compound_declaration, parser.user_data);

            return compound_declaration;
        }

        // Compound Declaration & Assing
        if maybe_eat_token(parser.lexer, .DECLARATION_AND_ASSIGN) {
            compound_declaration := New(Compound_Declaration);

            transform_nodes_into_items(compound_declaration, nodes_types, nodes, .DECLARATION);

            compound_declaration.members = nodes;
            compound_declaration.parent = parent;
            compound_declaration.expression = parse(parser, compound_declaration);

            set_start_location(compound_declaration, base_node);
            set_end_location(compound_declaration, peek_token(parser.lexer, -1));
            parser.node_visit(compound_declaration, parser.user_data);

            return compound_declaration;
        }

        comma_seperated_expression := New(Comma_Seperated_Expression);

        if is_token(parser.lexer, #char "=") {
            transform_nodes_into_items(comma_seperated_expression, nodes_types, nodes, .ASSING);
        } else {
            for nodes it.parent = comma_seperated_expression;
        }

        comma_seperated_expression.members = nodes;

        if maybe_eat_token(parser.lexer, #char "=") {
            binary_operation := New(Binary_Operation);

            binary_operation.parent = parent;
            binary_operation.left = comma_seperated_expression;
            binary_operation.operation = .ASSING;
            binary_operation.right = parse(parser, null);

            if binary_operation.left {
                binary_operation.left.parent  = binary_operation;
            }

            if binary_operation.right {
                binary_operation.right.parent = binary_operation;
            }

            set_start_location(binary_operation, base_node);
            set_end_location(binary_operation, peek_token(parser.lexer, -1));
            parser.node_visit(binary_operation, parser.user_data);

            return binary_operation;
        }

        comma_seperated_expression.parent = parent;

        set_start_location(comma_seperated_expression, base_node);
        set_end_location(comma_seperated_expression, peek_token(parser.lexer, -1));
        parser.node_visit(comma_seperated_expression, parser.user_data);

        return comma_seperated_expression;
    }

    parser.node_visit(base_node, parser.user_data);

    return base_node;
}

#scope_module

set_start_location :: (using node: *Node, token: *Token) {
    if !token return;
    location.file = token.file;
    location.l0 = token.l0;
    location.c0 = token.c0;
}

set_start_location :: (location: *Node.Location, token: *Token) {
    if !token return;
    location.file = token.file;
    location.l0 = token.l0;
    location.c0 = token.c0;
}

set_start_location :: (using node: *Node, from_node: *Node) {
    if !from_node return;
    location.file = from_node.location.file;
    location.l0 = from_node.location.l0;
    location.c0 = from_node.location.c0;
}

set_end_location :: (using node: *Node, token: *Token) {
    if !token return;
    location.file = token.file;
    location.l1 = token.l1;
    location.c1 = token.c1;
}

set_end_location :: (location: *Node.Location, token: *Token) {
    if !token return;
    location.file = token.file;
    location.l1 = token.l1;
    location.c1 = token.c1;
}

set_end_location :: (using node: *Node, from_node: *Node) {
    if !from_node return;
    location.file = from_node.location.file;
    location.l1 = from_node.location.l1;
    location.c1 = from_node.location.c1;
}

delimeted :: (parser: *Parser, open: Token.Kind, close: Token.Kind, seperator: Token.Kind = 0, parent: *Node) -> []*Node {
    nodes: [..]*Node;

    eat_token(parser.lexer, open);

    while !end(parser.lexer) {
        if is_token(parser.lexer, close) break;

        if seperator != 0 && is_token(parser.lexer, seperator) {
            eat_token(parser.lexer, seperator);
            continue;
        }

        node := parse(parser, parent);
        if node == null continue;
        array_add(*nodes, node);

        if is_token(parser.lexer, close) break;
    }

    maybe_eat_token(parser.lexer, close);

    return nodes;
}

parse_until :: (parser: *Parser, stop: (token: *Token) -> bool, seperator: Token.Kind = 0, parent: *Node) -> []*Node {
    nodes: [..]*Node;

    while !end(parser.lexer) {
        if !peek_token(parser.lexer) || stop(peek_token(parser.lexer)) break;

        if seperator != 0 && is_token(parser.lexer, seperator) {
            eat_token(parser.lexer, seperator);
            continue;
        }

        node := parse(parser, parent);
        if node == null continue;
        array_add(*nodes, node);

        if !peek_token(parser.lexer) || stop(peek_token(parser.lexer)) break;
    }

    return nodes;
}

create_operator_from_token :: (using token: Token) -> _Operator {

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
        case #char "&";                           return .BITWISE_AND;
        case #char "|";                           return .PIPE;
        case #char "~";                           return .BITWISE_NOT;
        case #char "!";                           return .NEGATE;
        case #char "^";                           return .BITWISE_XOR;

        case .BITWISE_AND_ASSIGNMENT;             return .BITWISE_AND_ASSIGNMENT;
        case .BITWISE_XOR_ASSIGNMENT;             return .BITWISE_XOR_ASSIGNMENT;
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

    log_error(tprint("Invalid operator '%' %:%:%.", token_kind_to_string(kind), file, l0, c0));

    return .INVALID;
}

parse_node :: (parser: *Parser) -> *Node {

    // Declaration, Binary Operation, Unary Operation, Identifier
    if is_identifier(parser.lexer) {
        ident := eat_token(parser.lexer, .IDENTIFIER);

        // Binary operation
        if is_operator(peek_token(parser.lexer)) && (!is_token(parser.lexer, #char "=") || !is_token(parser.lexer, #char ",", 1)) {
            return parse_binary_operation(parser, parse_identifier(parser, ident));
        }

        // Array Subscript
        if is_token(parser.lexer, #char "[") {
            return parse_array_subscript(parser, parse_identifier(parser, ident));
        }

        if is_token(parser.lexer, .QUICK_LAMBDA) {
            identifier := parse_identifier(parser, ident);
            arguments := NewArray(1, *Node);
            arguments[0] = identifier;
            return parse_quick_lambda(parser, arguments);
        }

        if is_token(parser.lexer, #char "(") {
            return parse_procedure_call(parser, parse_identifier(parser, ident));
        }

        if is_token(parser.lexer, .CONSTANT_DECLARATION) {
            return parse_constant_declaration(parser, ident);
        }

        if is_token(parser.lexer, .DECLARATION_AND_ASSIGN) {
            return parse_declaration_and_assign(parser, ident);
        }

        if is_token(parser.lexer, #char ":") && !is_token(parser.lexer, #char ",", 1) {
            return parse_type_instantiation(parser, ident);
        }

        return parse_identifier(parser, ident, false);
    }

    // Procedure
    if is_token(parser.lexer, #char "(") {
        return parse_procedure(parser);
    }

    // Inline
    if is_token(parser.lexer, .KEYWORD_INLINE) {
        return parse_inline(parser);
    }

    // Push Context
    if is_token(parser.lexer, .KEYWORD_PUSH_CONTEXT) {
        return parse_push_context(parser);
    }

    if is_token(parser.lexer, .KEYWORD_OPERATOR) {
        return parse_operator_overload(parser);
    }

    // Polymorphic_Constant
    if is_token(parser.lexer, #char "$") {
        return parse_polymorphic_constant(parser, false);
    }

    // INITIALIZE ZERO
    if is_token(parser.lexer, .TRIPLE_MINUS) {
        return parse_initialize_zero(parser);
    }

    // Polymorphic_Constant
    if is_token(parser.lexer, .DOUBLE_DOLLAR) {
        return parse_polymorphic_constant(parser, true);
    }

    // Unary Operation
    if is_unary_operator(parser) {

        // Array or Struct literal
        if is_token(parser.lexer, #char ".") && is_token(parser.lexer, token => token.kind == #char "[" || token.kind == #char "{", 1) {
            return parse_array_or_struct_literal(parser, null);
        }

        return parse_unary_operation(parser);
    }

    // If
    if is_token(parser.lexer, .KEYWORD_IF) || is_token(parser.lexer, .KEYWORD_IFX) {
        return parse_if(parser);
    }

    // Case
    if is_token(parser.lexer, .KEYWORD_CASE) {
        return parse_case(parser);
    }

    // While
    if is_token(parser.lexer, .KEYWORD_WHILE) {
        return parse_while(parser);
    }

    // For
    if is_token(parser.lexer, .KEYWORD_FOR) {
        return parse_for(parser);
    }

    // Struct
    if is_token(parser.lexer, .KEYWORD_STRUCT) {
        return parse_struct(parser);
    }

    // Union
    if is_token(parser.lexer, .KEYWORD_UNION) {
        return parse_union(parser);
    }

    // Enum
    if is_token(parser.lexer, .KEYWORD_ENUM) {
        return parse_enum(parser, false);
    }

    // Enum_Flags
    if is_token(parser.lexer, .KEYWORD_ENUM_FLAGS) {
        return parse_enum(parser, true);
    }

    // Return
    if is_token(parser.lexer, .KEYWORD_RETURN) {
        return parse_return(parser);
    }

    // Using
    if is_token(parser.lexer, .KEYWORD_USING) {
        return parse_using(parser);
    }

    // Break
    if is_token(parser.lexer, .KEYWORD_BREAK) {
        return parse_break(parser);
    }

    // Continue
    if is_token(parser.lexer, .KEYWORD_CONTINUE) {
        return parse_continue(parser);
    }

    // Defer
    if is_token(parser.lexer, .KEYWORD_DEFER) {
        return parse_defer(parser);
    }

    // Cast
    if is_token(parser.lexer, .KEYWORD_CAST) {
        return parse_cast(parser);
    }

    // Auto Cast (xx)
    if is_token(parser.lexer, .KEYWORD_AUTO_CAST) {
        return parse_cast(parser, true);
    }

    // Directive
    if is_token(parser.lexer, .DIRECTIVE) {
        return parse_directive(parser);
    }

    // String literal
    if is_token(parser.lexer, .STRING) {
        return parse_literal(parser);
    }

    // Numeric literal
    if is_token(parser.lexer, .NUMBER) {
        return parse_literal(parser);
    }

    // True literal
    if is_token(parser.lexer, .KEYWORD_TRUE) {
        return parse_literal(parser);
    }

    // False literal
    if is_token(parser.lexer, .KEYWORD_FALSE) {
        return parse_literal(parser);
    }

    // Block
    if is_token(parser.lexer, #char "{") {
        return parse_block(parser, false);
    }

    // Array_Type
    if is_token(parser.lexer, #char "[") {
        return parse_array_type(parser);
    }

    // Comment
    if is_token(parser.lexer, .COMMENT) {
        return parse_comment(parser);
    }

    // Skip other
    eat_token(parser.lexer);

    return null;
}

parse_comment :: (parser: *Parser) -> *Comment {
    comment_token := eat_token(parser.lexer, .COMMENT);
    comment := New(Comment);
    comment.value = comment_token.string_value;
    return comment;
}

// player: Entity;
// player: Entity = .{health=20};
parse_type_instantiation :: (parser: *Parser, ident_token: *Token) -> *Declaration {
    eat_token(parser.lexer, #char ":");
    decl := New(Declaration);
    decl.name = ident_token.string_value;

    if is_token(parser.lexer, #char "(") {
        decl.type_inst = parse_procedure(parser, true);
    } else {
        decl.type_inst = parse(parser, decl);
    }

    decl.backticked = ident_token.backticked;

    // decl: u8 #align 32
    if maybe_eat_token(parser.lexer, t => t.kind == .DIRECTIVE && t.string_value == "align") {
        align_token := eat_token(parser.lexer, .NUMBER);
        decl.alignment = parse_int(*align_token.string_value);
    }

    // decl: type_inst = exp;
    if maybe_eat_token(parser.lexer, #char "=") {
        decl.expression = parse(parser, decl);
    }

    // maybe_eat_token(parser.lexer, #char ";");

    if maybe_eat_token(parser.lexer, t => t.kind == .DIRECTIVE && t.string_value == "elsewhere") {
        decl.has_elsewhere = true;
        if is_token(parser.lexer, .IDENTIFIER) {
            decl.elsewhere = eat_token(parser.lexer, .IDENTIFIER).string_value;
        }
    }

    // Notes
    if is_token(parser.lexer, .NOTE) {
        notes: [..]*Note;
        parse_notes(parser, decl, *notes);
        decl.notes = notes;
    }

    return decl;
}

// PLAYER_MAX_HP :: 120;
parse_constant_declaration :: (parser: *Parser, ident_token: *Token) -> *Declaration {
    eat_token(parser.lexer, .CONSTANT_DECLARATION);
    decl := New(Declaration);
    decl.name = ident_token.string_value;
    decl.backticked = ident_token.backticked;
    decl.const = true;
    decl.expression = parse(parser, decl);

    maybe_eat_token(parser.lexer, #char ";");

    // Notes
    if is_token(parser.lexer, .NOTE) {
        notes: [..]*Note;
        parse_notes(parser, decl, *notes);
        decl.notes = notes;
    }

    return decl;
}

// player_position := Vec3.{10, 20, 10};
parse_declaration_and_assign :: (parser: *Parser, ident_token: *Token) -> *Declaration {
    eat_token(parser.lexer, .DECLARATION_AND_ASSIGN);
    decl := New(Declaration);
    decl.name = ident_token.string_value;
    decl.backticked = ident_token.backticked;
    decl.expression = parse(parser, decl);

    maybe_eat_token(parser.lexer, #char ";");

    // Notes
    if is_token(parser.lexer, .NOTE) {
        notes: [..]*Note;
        parse_notes(parser, decl, *notes);
        decl.notes = notes;
    }

    return decl;
}

parse_procedure :: (parser: *Parser, force_procedure := false) -> *Node {
    header_location: Node.Location;
    set_start_location(*header_location, peek_token(parser.lexer));

    // @TODO: This is kinda hack... Maybe do this in some other better way!
    inside_proc_args_was_already_set := parser.inside_proc_args;
    if !inside_proc_args_was_already_set {
        parser.inside_proc_args = true;
    }

    members := delimeted(parser, #char "(", #char ")", #char ",", *(Node.{})); // @TODO: Parent hack!?

    if !inside_proc_args_was_already_set {
        parser.inside_proc_args = false;
    }

    // Probably @InComplete
    is_procedure_args :: (kind: Node.Kind) -> bool {
        if kind == .DECLARATION return true;
        if kind == .USING return true;
        if kind == .POLYMORPHIC_CONSTANT return true;
        if kind == .COMMENT return true;
        if kind == .DIRECTIVE_DISCARD return true;
        // ...

        return false;
    }

    // @TODO: this is kinda messy? We probably want to do this in some other way...
    if !force_procedure && members.count > 0 && !is_procedure_args(members[0].kind) {

        // Quick Lambda
        if is_token(parser.lexer, .QUICK_LAMBDA) {
            return parse_quick_lambda(parser, members);
        }

        // Comma Seperated Expression @TODO: maybe move this somewhere else?
        comma_seperated_expression := New(Comma_Seperated_Expression);

        comma_seperated_expression.members = members;
        for comma_seperated_expression.members it.parent = comma_seperated_expression;

        // Binary operation eg: ((10+10) - (20+5))
        if is_operator(peek_token(parser.lexer)) {
            return parse_binary_operation(parser, comma_seperated_expression);
        }

        // Array Subscript after Comma Seperated Expression eg: *(<<arr)[it]
        if is_token(parser.lexer, #char "[") {
            return parse_array_subscript(parser, comma_seperated_expression);
        }

        return comma_seperated_expression;
    }

    proc := New(Procedure);

    proc.arguments = members;
    for proc.arguments it.parent = proc;

    // returns
    if maybe_eat_token(parser.lexer, .ARROW_RIGHT) {
        starts_with_bracket := maybe_eat_token(parser.lexer, #char "(");
        returns: [..]*Return_Value;

        is_returns_end_token :: (token: *Token) -> bool {
            if token.kind == #char ";" return true;
            if token.kind == #char ")" return true;
            if token.kind == #char "{" return true;
            if token.kind == .DIRECTIVE return true;
            return false;
        }

        while !end(parser.lexer) && !is_token(parser.lexer, is_returns_end_token) {
            if maybe_eat_token(parser.lexer, #char ",") continue;

            expression := parse(parser, proc);
            if !expression continue;

            return_value := New(Return_Value);
            return_value.expression = expression;

            if is_token(parser.lexer, t => t.kind == .DIRECTIVE && t.string_value == "must") {
                eat_token(parser.lexer, .DIRECTIVE);
                return_value.must = true;
            }

            array_add(*returns, return_value);

            // If we are inside procedure args we take only one return if we are not in parentheses.
            if !starts_with_bracket && parser.inside_proc_args {
                break;
            }
        }

        // If the last return value is must all the returns must be consumed.
        if returns.count > 0 && returns[returns.count-1].must {
            proc.flags |= .MUST_CONSUME_ALL_RETURNS;
        }

        proc.returns = returns;

        if starts_with_bracket maybe_eat_token(parser.lexer, #char ")");
    }

    set_end_location(*header_location, peek_token(parser.lexer, -1));
    proc.header_location = header_location;

    parse_proc_directive :: (parser: *Parser, proc: *Procedure) {
        directive := eat_token(parser.lexer, .DIRECTIVE);

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
                if is_token(parser.lexer, .IDENTIFIER) {
                    proc.intrinsic = eat_token(parser.lexer, .IDENTIFIER).string_value;
                }

            case "compiler";
                proc.flags |= .COMPILER;
            case "elsewhere";
                proc.flags |= .ELSEWHERE;
                proc.elsewhere = eat_token(parser.lexer, .IDENTIFIER).string_value;
            case "foreign";
                proc.flags |= .FOREIGN;

                if is_token(parser.lexer, .IDENTIFIER) {
                    proc.foreign_lib = eat_token(parser.lexer, .IDENTIFIER).string_value;

                    if is_token(parser.lexer, .STRING) {
                        proc.foreign_alias = eat_token(parser.lexer, .STRING).string_value;
                    }
                }

            case "no_call";
                proc.flags |= .NO_CALL;
            case "deprecated";
                proc.flags |= .DEPRECATED;
                if is_token(parser.lexer, .STRING) {
                    proc.deprecated_note = eat_token(parser.lexer, .STRING).string_value;
                }
            case "no_alias";
                proc.flags |= .NO_ALIAS;
            case "runtime_support";
                proc.flags |= .RUNTIME_SUPPORT;
            case "symmetric"; // @TODO: this is only needed for Operator Overload
                proc.flags |= .SYMMETRIC;
            case "modify";
                proc.modify_block = parse_block(parser);
                proc.modify_block.parent = proc;
            case "no_abc";
                proc.flags |= .NO_ABC;
            case "no_aoc";
                proc.flags |= .NO_AOC;
        }

        if is_token(parser.lexer, .DIRECTIVE) {
            parse_proc_directive(parser, proc);
        }
    }

    // Directives
    if is_token(parser.lexer, .DIRECTIVE) {
        parse_proc_directive(parser, proc);
    }

    // Body
    if is_token(parser.lexer, #char "{") {
        proc.body = parse_block(parser);
        proc.body.parent = proc;
    }

    // Notes
    if is_token(parser.lexer, .NOTE) {
        notes: [..] * Note;
        parse_notes(parser, proc, *notes);
        proc.notes = notes;
    }

    return proc;
}

parse_quick_lambda :: (parser: *Parser, arguments: []*Node) -> *Quick_Lambda {
    quick_lambda := New(Quick_Lambda);
    quick_lambda.arguments = arguments;
    for quick_lambda.arguments it.parent = quick_lambda;

    eat_token(parser.lexer, .QUICK_LAMBDA);
    quick_lambda._return = parse(parser, quick_lambda);

    return quick_lambda;
}

parse_struct :: (parser: *Parser) -> *Struct {
    _struct := New(Struct);

    eat_token(parser.lexer, .KEYWORD_STRUCT);

    if is_token(parser.lexer, #char "(") {
        _struct.polymorphic_arguments = delimeted(parser, #char "(", #char ")", #char ",", _struct);
    }

    parse_struct_directive :: (parser: *Parser, _struct: *Struct) {
        directive := eat_token(parser.lexer, .DIRECTIVE);

        if directive.string_value == {
            case "modify";
                _struct.modify_block = parse_block(parser);
            case "type_info_no_size_complaint";
                _struct.flags |= .TYPE_INFO_NO_SIZE_COMPLAINT;
            case "type_info_procedures_are_void_pointers";
                _struct.flags |= .TYPE_INFO_PROCEDURES_ARE_VOID_POINTERS;
            case "type_info_none";
                _struct.flags |= .TYPE_INFO_NONE;
        }

        if is_token(parser.lexer, .DIRECTIVE) {
            parse_struct_directive(parser, _struct);
        }
    }

    notes: [..]*Note;

    if is_token(parser.lexer, .NOTE) {
        parse_notes(parser, _struct, *notes);
    }

    // Directives
    if is_token(parser.lexer, .DIRECTIVE) {
        parse_struct_directive(parser, _struct);
    }

    if is_token(parser.lexer, .NOTE) {
        parse_notes(parser, _struct, *notes);
    }

    if is_token(parser.lexer, #char "{") {
        _struct.block = parse_block(parser);
        _struct.block.parent = _struct;
    } else {
        token := peek_token(parser.lexer);
        if token {
            log_error("Exprected struct body! %:%:%", token.file, token.l0, token.c0);
        } else {
            log_error("Exprected struct body! (token is null)");
        }
    }

    if is_token(parser.lexer, token => token.kind == .DIRECTIVE && token.string_value == "no_padding") {
        eat_token(parser.lexer, .DIRECTIVE);
        _struct.flags |= .NO_PADDING;
    }

    if is_token(parser.lexer, .NOTE) {
        parse_notes(parser, _struct, *notes);
    }

    _struct.notes = notes;

    return _struct;
}

// union {}
parse_union :: (parser: *Parser) -> *Union {
    _union := New(Union);

    eat_token(parser.lexer, .KEYWORD_UNION);

    if is_token(parser.lexer, #char "(") {
        _union.polymorphic_arguments = delimeted(parser, #char "(", #char ")", #char ",", _union);
    }

    if is_token(parser.lexer, #char "{") {
        _union.block = parse_block(parser);
        _union.block.parent = _union;
    } else {
        token := peek_token(parser.lexer);
        if token {
            log_error("Exprected union body! %:%:%", token.file, token.l0, token.c0);
        } else {
            log_error("Exprected union body! (token is null)");
        }
    }

    if is_token(parser.lexer, .NOTE) {
        notes: [..] *Note;
        parse_notes(parser, _union, *notes);
        _union.notes = notes;
    }

    return _union;
}

// enum {}
parse_enum :: (parser: *Parser, is_enum_flags: bool) -> *Enum {
    _enum := New(Enum);
    _enum.is_enum_flags = is_enum_flags;

    eat_token(parser.lexer, ifx is_enum_flags then Token.Kind.KEYWORD_ENUM_FLAGS else .KEYWORD_ENUM);

    notes: [..] *Note;

    if is_token(parser.lexer, .NOTE) {
        parse_notes(parser, _enum, *notes);
    }

    // Type specifier
    if is_token(parser.lexer, .IDENTIFIER) {
        _enum.type = parse(parser, _enum);
    }

    if is_token(parser.lexer, .NOTE) {
        parse_notes(parser, _enum, *notes);
    }

    // Specified directive
    if is_token(parser.lexer, token => token.kind == .DIRECTIVE && token.string_value == "specified") {
        eat_token(parser.lexer, .DIRECTIVE);
        _enum.specified = true;
    }

    // Body
    if is_token(parser.lexer, #char "{") {
        _enum.block = parse_block(parser);
        _enum.block.parent = _enum;
    } else {
        token := peek_token(parser.lexer);
        if token {
            log_error("Exprected enum body! %:%:%", token.file, token.l0, token.c0);
        } else {
            log_error("Exprected enum body! (token is null)");
        }
    }

    if is_token(parser.lexer, .NOTE) {
        parse_notes(parser, _enum, *notes);
    }

    _enum.notes = notes;

    return _enum;
}

// {}
parse_block :: (parser: *Parser, call_node_visit := true, no_aoc := false) -> *Block {
    block := New(Block);
    block.no_aoc = no_aoc;
    set_start_location(block, peek_token(parser.lexer));
    block.members = delimeted(parser, #char "{", #char "}", parent=block);
    set_end_location(block, peek_token(parser.lexer, -1));

    if call_node_visit parser.node_visit(block, parser.user_data);

    return block;
}

// print()
parse_procedure_call :: (parser: *Parser, procedure: *Node) -> *Node {
    proc_call := New(Procedure_Call);
    proc_call.procedure = procedure;
    procedure.parent = proc_call;

    if procedure.kind == .IDENTIFIER {
        proc_call.backticked = (cast(*Identifier)procedure).backticked;
    }

    eat_token(parser.lexer, #char "(");

    proc_call.arguments = parse_until(parser, token => token.kind == #char ")" || token.kind == .DOUBLE_COMMA, #char ",", proc_call);

    end_token := peek_token(parser.lexer);
    if end_token && end_token.kind == .DOUBLE_COMMA {
        eat_token(parser.lexer, .DOUBLE_COMMA);
        proc_call.context_changes = parse_until(parser, token => token.kind == #char ")", #char ",", proc_call);
    }

    eat_token(parser.lexer, #char ")");

    // Array Subscript generate_array()[0]
    if is_token(parser.lexer, #char "[") {
        return parse_array_subscript(parser, proc_call);
    }

    // Procedure Call generate_proc()();
    if is_token(parser.lexer, #char "(") {
        return parse_procedure_call(parser, proc_call);
    }

    // Binary operation
    if is_operator(peek_token(parser.lexer)) {
        return parse_binary_operation(parser, proc_call);
    }

    return proc_call;
}

// #run
parse_directive :: (parser: *Parser) -> *Node {
    directive_token := eat_token(parser.lexer, .DIRECTIVE);

    if directive_token.string_value == {
        case "import";              return parse_directive_import(parser);
        case "load";                return parse_directive_load(parser);
        case "run";                 return parse_directive_run(parser);
        case "as";                  return parse_directive_as(parser);
        case "place";               return parse_directive_place(parser);
        case "type";                return parse_directive_type(parser);
        case "code";                return parse_directive_code(parser);
        case "char";                return parse_directive_char(parser);
        case "add_context";         return parse_directive_add_context(parser);
        case "assert";              return parse_directive_assert(parser);
        case "bake_arguments";      return parse_directive_bake_arguments(parser);
        case "bake_constants";      return parse_directive_bake_constants(parser);
        case "bytes";               return parse_directive_bytes(parser);
        case "no_reset";            return parse_directive_no_reset(parser);
        case "insert";              return parse_directive_insert(parser);
        case "location";            return parse_directive_location(parser);
        case "module_parameters";   return parse_directive_module_parameters(parser);
        case "placeholder";         return parse_directive_placeholder(parser);
        case "procedure_of_call";   return parse_directive_procedure_of_call(parser);
        case "procedure_name";      return parse_directive_procedure_name(parser);
        case "program_export";      return parse_directive_program_export(parser);
        case "this";                return parse_directive_this(parser);
        case "poke_name";           return parse_directive_poke_name(parser);
        case "dynamic_specialize";  return parse_directive_dynamic_specialize(parser);
        case "caller_code";         return parse_directive_caller_code(parser);
        case "caller_location";     return parse_directive_caller_location(parser);
        case "file";                return parse_directive_file(parser);
        case "filepath";            return parse_directive_filepath(parser);
        case "line";                return parse_directive_line(parser);
        case "through";             return parse_directive_through(parser);
        case "exists";              return parse_directive_exists(parser);
        case "compile_time";        return parse_directive_compile_time(parser);
        case "discard";             return parse_directive_discard(parser);

        case "library";             return parse_directive_library(parser, false);
        case "system_library";      return parse_directive_library(parser, true);

        case "scope_export";        return parse_directive_scope(parser, .EXPORT);
        case "scope_file";          return parse_directive_scope(parser, .FILE);
        case "scope_module";        return parse_directive_scope(parser, .MODULE);

        case "asm";                 return parse_inline_assembly(parser);
        case "if";                  return parse_if(parser, .IF, true);
        case "ifx";                 return parse_if(parser, .IFX, true);

        case "no_aoc";              if is_token(parser.lexer, #char "{") return parse_block(parser, no_aoc=true);
    }

    // @TODO: Unknown directive?
    eat_token(parser.lexer);
    log_error("Unknown directive #% (%:%:%)!", directive_token.string_value, directive_token.file, directive_token.l0, directive_token.c0);

    return null;
}

parse_directive_run :: (parser: *Parser) -> *Directive_Run {
    directive_run := New(Directive_Run);

    while maybe_eat_token(parser.lexer, #char ",") {
        if maybe_eat_token(parser.lexer, token => token.kind == .IDENTIFIER && token.string_value == "stallable") {
            directive_run.stallable = true;
        }

        if maybe_eat_token(parser.lexer, token => token.kind == .IDENTIFIER && token.string_value == "host") {
            directive_run.host = true;
        }
    }

    // if maybe_eat_token(parser.lexer, #char ",")
    //     && is_token(parser.lexer, token => token.kind == .IDENTIFIER && token.string_value == "stallable") {
    //     eat_token(parser.lexer, .IDENTIFIER);

    //     directive_run.stallable = true;
    // }

    directive_run.expression = parse(parser, directive_run);

    return directive_run;
}

parse_directive_char :: (parser: *Parser) -> *Directive_Char {
    directive_char := New(Directive_Char);
    directive_char.string_literal = parse(parser, directive_char);
    return directive_char;
}

parse_directive_code :: (parser: *Parser) -> *Directive_Code {
    directive_code := New(Directive_Code);

    if maybe_eat_token(parser.lexer, #char ",") {

        if is_token(parser.lexer, token => token.kind == .IDENTIFIER && token.string_value == "typed") {
            eat_token(parser.lexer, .IDENTIFIER);
            directive_code.typed = true;
        }

        if is_token(parser.lexer, token => token.kind == .IDENTIFIER && token.string_value == "null") {
            eat_token(parser.lexer, .IDENTIFIER);
            directive_code._null = true;
        }

    }

    if !directive_code._null {
        directive_code.expression = parse(parser, directive_code);
    }

    return directive_code;
}

parse_directive_as :: (parser: *Parser) -> *Directive_As {
    directive_as := New(Directive_As);
    directive_as.expression = parse(parser, directive_as);
    return directive_as;
}

parse_directive_add_context :: (parser: *Parser) -> *Directive_Add_Context {
    directive_add_context := New(Directive_Add_Context);
    directive_add_context.expression = parse(parser, directive_add_context);
    return directive_add_context;
}

parse_directive_import :: (parser: *Parser) -> *Directive_Import {
    directive_import := New(Directive_Import);

    if maybe_eat_token(parser.lexer, #char ",") {
        ok, modifier_token := maybe_eat_token(parser.lexer, t => t.kind == .IDENTIFIER);
        if ok {

            if modifier_token.string_value == {
                case "file"; directive_import.import_kind = .FILE;
                case "dir"; directive_import.import_kind = .DIR;
                case "string"; directive_import.import_kind = .STRING;
            }

        }

    }

    directive_import.module = eat_token(parser.lexer, .STRING).string_value;

    if is_token(parser.lexer, #char "(") {
        directive_import.arguments = delimeted(parser, #char "(", #char ")", #char ",", directive_import);
    }

    return directive_import;
}

parse_directive_load :: (parser: *Parser) -> *Directive_Load {
    directive_load := New(Directive_Load);
    directive_load.file = eat_token(parser.lexer, .STRING).string_value;
    return directive_load;
}

parse_directive_place :: (parser: *Parser) -> *Directive_Place {
    directive_place := New(Directive_Place);
    directive_place.expression = parse(parser, directive_place);
    return directive_place;
}

parse_directive_type :: (parser: *Parser) -> *Directive_Type {
    directive_type := New(Directive_Type);

    if maybe_eat_token(parser.lexer, #char ",") {

        if is_token(parser.lexer, char  => char.kind == .IDENTIFIER && char.string_value == "isa") {
            eat_token(parser.lexer, .IDENTIFIER);
            directive_type.isa = true;
        }

        if is_token(parser.lexer, char  => char.kind == .IDENTIFIER && char.string_value == "distinct") {
            eat_token(parser.lexer, .IDENTIFIER);
            directive_type.distinct = true;
        }

    }

    if is_token(parser.lexer, #char "(") {
        directive_type.expression = parse_procedure(parser, true);
    } else {
        directive_type.expression = parse(parser, directive_type);
    }

    return directive_type;
}

parse_directive_assert :: (parser: *Parser) -> *Directive_Assert {
    directive_assert := New(Directive_Assert);

    directive_assert.condition = parse(parser, directive_assert);

    if is_token(parser.lexer, .STRING) {
        message_token := eat_token(parser.lexer, .STRING);
        directive_assert.message = message_token.string_value;
    }

    return directive_assert;
}

parse_directive_bake_arguments :: (parser: *Parser) -> *Directive_Bake_Arguments {
    directive_bake_arguments := New(Directive_Bake_Arguments);
    directive_bake_arguments.expression = parse(parser, directive_bake_arguments);

    return directive_bake_arguments;
}

parse_directive_bake_constants :: (parser: *Parser) -> *Directive_Bake_Constants {
    directive_bake_constants := New(Directive_Bake_Constants);
    directive_bake_constants.expression = parse(parser, directive_bake_constants);

    return directive_bake_constants;
}

parse_directive_bytes :: (parser: *Parser) -> *Directive_Bytes {
    directive_bytes := New(Directive_Bytes);
    directive_bytes.expression = parse(parser, directive_bytes);

    return directive_bytes;
}

parse_directive_library :: (parser: *Parser, system: bool) -> *Directive_Library {
    directive_library := New(Directive_Library);
    directive_library.system = system;

    while maybe_eat_token(parser.lexer, #char ",") {
        if maybe_eat_token(parser.lexer, token => token.string_value == "no_static_library") {
            directive_library.no_static_library = true;
        }

        if maybe_eat_token(parser.lexer, token => token.string_value == "link_always") {
            directive_library.link_always = true;
        }

        if maybe_eat_token(parser.lexer, token => token.string_value == "system") {
            directive_library.system = true;
        }

        if maybe_eat_token(parser.lexer, token => token.string_value == "no_dll") {
            directive_library.no_dll = true;
        }
    }

    if is_token(parser.lexer, .STRING) {
        name_token := eat_token(parser.lexer, .STRING);
        directive_library.name = name_token.string_value;
    }

    return directive_library;
}

parse_directive_no_reset :: (parser: *Parser) -> *Directive_No_Reset {
    directive_no_reset := New(Directive_No_Reset);
    directive_no_reset.expression = parse(parser, directive_no_reset);

    return directive_no_reset;
}

parse_directive_insert :: (parser: *Parser) -> *Directive_Insert {
    directive_insert := New(Directive_Insert);

    if maybe_eat_token(parser.lexer, #char ",")
    && maybe_eat_token(parser.lexer, token => token.string_value == "scope") {
        directive_insert.scoped = true;

        maybe_eat_token(parser.lexer, #char "(");

        if !is_token(parser.lexer, #char ")") {
            directive_insert.scope = parse(parser, directive_insert);
        }

        maybe_eat_token(parser.lexer, #char ")");
    }

    if maybe_eat_token(parser.lexer, .ARROW_RIGHT) {
        insert_type_ident := eat_token(parser.lexer, .IDENTIFIER);

        if insert_type_ident.string_value == {
            case "string"; directive_insert.type   = .STRING;
            case "Code"; directive_insert.type     = .CODE;
        }

    }

    directive_insert.expression = parse(parser, directive_insert);

    return directive_insert;
}

parse_directive_location :: (parser: *Parser) -> *Directive_Location {
    directive_location := New(Directive_Location);

    if maybe_eat_token(parser.lexer, #char "(") {

        if !is_token(parser.lexer, #char ")") {
            directive_location.expression = parse(parser, directive_location);
        }

        eat_token(parser.lexer, #char ")");
    }

    return directive_location;
}

parse_directive_module_parameters :: (parser: *Parser) -> *Directive_Module_Parameters {
    directive_module_parameters := New(Directive_Module_Parameters);

    if is_token(parser.lexer, #char "(") {
        directive_module_parameters.parameters = delimeted(parser, #char "(", #char ")", #char ",", directive_module_parameters);
    }

    if is_token(parser.lexer, #char "(") {
        directive_module_parameters.second_parameters = delimeted(parser, #char "(", #char ")", #char ",", directive_module_parameters);
    }

    return directive_module_parameters;
}

parse_directive_placeholder :: (parser: *Parser) -> *Directive_Placeholder {
    directive_placeholder := New(Directive_Placeholder);
    directive_placeholder.expression = parse(parser, directive_placeholder);
    return directive_placeholder;
}

parse_directive_procedure_of_call :: (parser: *Parser) -> *Directive_Procedure_Of_Call {
    directive_procedure_of_call := New(Directive_Procedure_Of_Call);
    directive_procedure_of_call.expression = parse(parser, directive_procedure_of_call);
    return directive_procedure_of_call;
}

parse_directive_procedure_name :: (parser: *Parser) -> *Directive_Procedure_Name {
    directive_procedure_name := New(Directive_Procedure_Name);

    if maybe_eat_token(parser.lexer, #char "(") {
        if !is_token(parser.lexer,  #char ")") {
            directive_procedure_name.expression = parse(parser, directive_procedure_name);
            maybe_eat_token(parser.lexer, #char ")");
        } else {
            eat_token(parser.lexer, #char ")");
        }
    }

    return directive_procedure_name;
}

parse_directive_program_export :: (parser: *Parser) -> *Directive_Program_Export {
    directive_program_export := New(Directive_Program_Export);

    if is_token(parser.lexer, .STRING) {
        name_token := eat_token(parser.lexer, .STRING);
        directive_program_export.exported_name = name_token.string_value;
    }

    directive_program_export.expression = parse(parser, directive_program_export);

    return directive_program_export;
}

parse_directive_this :: (parser: *Parser) -> *Directive_This {
    directive_this := New(Directive_This);

    if is_token(parser.lexer, #char "(") {
        directive_this.arguments = delimeted(parser, #char "(", #char ")", #char ",", directive_this);
    }

    return directive_this;
}

parse_directive_poke_name :: (parser: *Parser) -> *Directive_Poke_Name {
    directive_poke_name := New(Directive_Poke_Name);

    if is_token(parser.lexer, .IDENTIFIER) {
        module_token := eat_token(parser.lexer, .IDENTIFIER);
        directive_poke_name.module = module_token.string_value;
    }

    if is_token(parser.lexer, .IDENTIFIER) {
        name_token := eat_token(parser.lexer, .IDENTIFIER);
        directive_poke_name.name = name_token.string_value;
    }

    return directive_poke_name;
}

parse_directive_dynamic_specialize :: (parser: *Parser) -> *Directive_Dynamic_Specialize {
    dynamic_specialize := New(Directive_Dynamic_Specialize);
    dynamic_specialize.expression = parse(parser, dynamic_specialize);
    return dynamic_specialize;
}

// @TODO: Those empty directives are kinda dumb... We could probably return then directly in parse_directive...
parse_directive_caller_code :: (parser: *Parser) -> *Directive_Caller_Code {
    return New(Directive_Caller_Code);
}

parse_directive_caller_location :: (parser: *Parser) -> *Directive_Caller_Location {
    return New(Directive_Caller_Location);
}

parse_directive_file :: (parser: *Parser) -> *Directive_File {
    return New(Directive_File);
}

parse_directive_filepath :: (parser: *Parser) -> *Directive_Filepath {
    return New(Directive_Filepath);
}

parse_directive_line :: (parser: *Parser) -> *Directive_Line {
    return New(Directive_Line);
}

parse_directive_through :: (parser: *Parser) -> *Directive_Through {
    return New(Directive_Through);
}

parse_directive_exists :: (parser: *Parser) -> *Directive_Exists {
    exists := New(Directive_Exists);

    if maybe_eat_token(parser.lexer, #char "(") {
        exists.expression = parse(parser, exists);

        if maybe_eat_token(parser.lexer, #char ",") {
            exists.wait_for = parse(parser, exists);
        }

        maybe_eat_token(parser.lexer, #char ")");
    }

    return exists;
}

parse_directive_compile_time :: (parser: *Parser) -> *Directive_Compile_Time {
    return New(Directive_Compile_Time);
}

parse_directive_discard :: (parser: *Parser) -> *Directive_Discard {
    discard := New(Directive_Discard);
    discard.expression = parse(parser, discard);
    return discard;
}

// @TODO: Consider this...
// We currently wrap scoped stuff in another node but we could maybe just flag
// Directives that they are exported in some scope instead of wrapping it with new node...
parse_directive_scope :: (parser: *Parser, scope_kind: Directive_Scope.Scope_Kind) -> *Directive_Scope {
    directive_scope := New(Directive_Scope);
    directive_scope.scope_kind = scope_kind;

    members: [..]*Node;

    is_token_end_of_scope_directive :: (token: *Token) -> bool {
        // end of scope
        if token.kind == #char "}" return true;

        if token.kind != .DIRECTIVE return false;

        if token.string_value == "scope_export" return true;
        if token.string_value == "scope_file"   return true;
        if token.string_value == "scope_module" return true;

        return false;
    }

    while !end(parser.lexer) && !is_token(parser.lexer, is_token_end_of_scope_directive) {
        node := parse(parser, directive_scope);
        if !node continue; // Skip null nodes...
        array_add(*members, node);
    }

    directive_scope.members = members;

    return directive_scope;
}

parse_identifier :: (parser: *Parser, ident_token: *Token, node_visit := true) -> *Identifier {
    identifier := New(Identifier);
    set_start_location(identifier, ident_token);
    identifier.name = ident_token.string_value;
    identifier.backticked = ident_token.backticked;
    set_end_location(identifier, peek_token(parser.lexer, -1));
    if node_visit parser.node_visit(identifier, parser.user_data);
    return identifier;
}

parse_array_or_struct_literal :: (parser: *Parser, type: *Node) -> *Node {
    literal := New(Literal);
    if type type.parent = literal;

    eat_token(parser.lexer, #char ".");

    if maybe_eat_token(parser.lexer, #char "[") {
        literal.value_type = .ARRAY;
        literal.values.array_literal_info = .{element_type=type};
        literal.values.array_literal_info.elements = parse_until(parser, token => token.kind == #char "]", #char ",", parent=literal);
        eat_token(parser.lexer, #char "]");
    } else if maybe_eat_token(parser.lexer, #char "{") {
        literal.value_type = .STRUCT;
        literal.values.struct_literal_info = .{type=type};
        literal.values.struct_literal_info.body = parse_until(parser, token => token.kind == #char "}", #char ",", parent=literal);
        eat_token(parser.lexer, #char "}");
    }

    // Binary operation
    if is_operator(peek_token(parser.lexer)) {
        return parse_binary_operation(parser, literal);
    }

    return literal;
}

parse_literal :: (parser: *Parser) -> *Node {
    literal := New(Literal);

    base_literal := eat_token(parser.lexer);

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

    // Binary operation
    if is_operator(peek_token(parser.lexer)) {
        return parse_binary_operation(parser, literal);
    }

    return literal;
}

parse_array_subscript :: (parser: *Parser, expression: *Node) -> *Node {
    array_subscript := New(Array_Subscript);
    array_subscript.expression = expression;
    array_subscript.expression.parent = array_subscript;

    eat_token(parser.lexer, #char "[");

    if !is_token(parser.lexer, #char "]") {
        array_subscript.subscript = parse(parser, array_subscript);
    }

    eat_token(parser.lexer, #char "]");

    // Binary operation
    if is_operator(peek_token(parser.lexer)) {
        return parse_binary_operation(parser, array_subscript);
    }

    // Another Array Subscript
    if is_token(parser.lexer, #char "[") {
        return parse_array_subscript(parser, array_subscript);
    }

    return array_subscript;
}

parse_array_type :: (parser: *Parser) -> *Array_Type {
    array_type := New(Array_Type);

    eat_token(parser.lexer, #char "[");

    if !is_token(parser.lexer, #char "]") {

        if maybe_eat_token(parser.lexer, .DOUBLE_DOT) {
            array_type.resizable = true;
        } else {
            array_type.dimension = parse(parser, array_type);
        }

    }

    eat_token(parser.lexer, #char "]");
    array_type.element_type = parse(parser, array_type);

    return array_type;
}

is_unary_operator :: (parser: *Parser) -> bool {
    if is_token(parser.lexer, #char "+")            return true;
    if is_token(parser.lexer, #char "-")            return true;
    if is_token(parser.lexer, #char ".")            return true;
    if is_token(parser.lexer, #char "*")            return true;
    if is_token(parser.lexer, #char "!")            return true;
    if is_token(parser.lexer, #char "$")            return true;
    if is_token(parser.lexer, #char "~")            return true;
    if is_token(parser.lexer, .DOUBLE_DOLLAR)       return true;
    if is_token(parser.lexer, .LEFT_SHIFT)          return true;
    if is_token(parser.lexer, .DOUBLE_DOT)          return true;
    return false;
}

parse_polymorphic_constant :: (parser: *Parser, maybe_constant: bool) -> *Polymorphic_Constant {
    polymorphic_constant := New(Polymorphic_Constant);
    polymorphic_constant.maybe_constant = maybe_constant;

    if maybe_constant {
        eat_token(parser.lexer, .DOUBLE_DOLLAR);
    } else {
        eat_token(parser.lexer, #char "$");
    }

    polymorphic_constant.expression = parse(parser, polymorphic_constant);

    if maybe_eat_token(parser.lexer, #char "/") {

        if is_token(parser.lexer, .KEYWORD_INTERFACE) {
            eat_token(parser.lexer, .KEYWORD_INTERFACE);
            polymorphic_constant.restrictions_interface = true;
        }

        polymorphic_constant.restriction = parse(parser, polymorphic_constant);
    }

    return polymorphic_constant;
}

parse_unary_operation :: (parser: *Parser) -> *Node {
    unary_operation := New(Unary_Operation);

    op := eat_token(parser.lexer);

    if op.kind == {
        case #char "+";             unary_operation.operation = .PLUS;
        case #char "-";             unary_operation.operation = .MINUS;
        case #char ".";             unary_operation.operation = .DOT;
        case #char "*";             unary_operation.operation = .POINTER;
        case #char "!";             unary_operation.operation = .NEGATE;
        case #char "~";             unary_operation.operation = .BITWISE_NOT;
        case .LEFT_SHIFT;           unary_operation.operation = .POINTER_DEREFERENCE;
        case .DOUBLE_DOT;           unary_operation.operation = .ELLIPSIS;
    }

    unary_operation.expression = parse(parser, unary_operation);

    // Binary operation
    if is_operator(peek_token(parser.lexer)) {
        return parse_binary_operation(parser, unary_operation);
    }

    return unary_operation;
}

parse_binary_operation :: (parser: *Parser, left: *Node) -> *Node {
    // Array or Struct literal
    if is_token(parser.lexer, #char ".") && is_token(parser.lexer, token => token.kind == #char "[" || token.kind == #char "{", 1) {
        return parse_array_or_struct_literal(parser, left);
    }

    binary_operation := New(Binary_Operation);
    binary_operation.left = left;
    binary_operation.left.parent = binary_operation;

    set_start_location(binary_operation, left);

    op := eat_token(parser.lexer);
    assert(is_operator(op));
    binary_operation.operation = create_operator_from_token(op);

    // pointer.*
    if binary_operation.operation == .DOT && maybe_eat_token(parser.lexer, #char "*") {
        unary_operation := New(Unary_Operation);
        unary_operation.operation = .POINTER_DEREFERENCE;

        unary_operation.expression = left;
        binary_operation.left.parent = unary_operation;

        free(binary_operation);

        // Binary operation
        if is_operator(peek_token(parser.lexer)) && (!is_token(parser.lexer, #char "=") || !is_token(parser.lexer, #char ",", 1)) {
            return parse_binary_operation(parser, unary_operation);
        }

        // Array Subscript
        if is_token(parser.lexer, #char "[") {
            return parse_array_subscript(parser, unary_operation);
        }

        return unary_operation;
    }

    binary_operation.right = parse(parser, binary_operation); // @TODO: anything?

    set_end_location(binary_operation, binary_operation.right);

    return binary_operation;
}

parse_return :: (parser: *Parser) -> *Node {
    _return := New(Return);
    return_token := eat_token(parser.lexer, .KEYWORD_RETURN);
    _return.backticked = return_token.backticked;

    _return.returns = parse_until(parser, token => token.kind == #char ";", #char ",", parent=_return);
    for _return.returns it.parent = _return;

    return _return;
}

parse_continue :: (parser: *Parser) -> *Node {
    _continue := New(Continue);
    eat_token(parser.lexer, .KEYWORD_CONTINUE);

    if !is_token(parser.lexer, #char ";") {
        _continue.expression = parse(parser, _continue);
    }

    return _continue;
}

parse_defer :: (parser: *Parser) -> *Node {
    _defer := New(Defer);
    defer_token := eat_token(parser.lexer, .KEYWORD_DEFER);

    _defer.backticked = defer_token.backticked;

    if !is_token(parser.lexer, #char ";") {
        _defer.expression = parse(parser, _defer);
    }

    return _defer;
}

parse_while :: (parser: *Parser) -> *Node {
    _while := New(While);
    eat_token(parser.lexer, .KEYWORD_WHILE);
    _while.expression = parse(parser, _while);

    if maybe_eat_token(parser.lexer, t => t.kind == .DIRECTIVE && t.string_value == "no_abc") {
        _while.no_abc = true;
    }

    _while.body = parse(parser, _while);
    return _while;
}

parse_for :: (parser: *Parser) -> *Node {
    _for := New(For);

    eat_token(parser.lexer, .KEYWORD_FOR);

    if maybe_eat_token(parser.lexer, #char "<") {
        _for.reversed = true;
        _for.by_pointer = maybe_eat_token(parser.lexer, #char "*");
    }

    if maybe_eat_token(parser.lexer, #char "*") {
        _for.by_pointer = true;
        _for.reversed = maybe_eat_token(parser.lexer, #char "<");
    }

    // Only iterator
    if !is_token(parser.lexer, #char ":", 1) && !is_token(parser.lexer, #char ",", 1) {
        _for.iterator = parse(parser, _for);
    } else {
        _for.index = parse_identifier(parser, eat_token(parser.lexer, .IDENTIFIER));
        _for.index.parent = _for;

        // @TODO: Is this correct?
        if maybe_eat_token(parser.lexer, #char ",") {
            _for.value = parse_identifier(parser, eat_token(parser.lexer, .IDENTIFIER));
            _for.value.parent = _for;
        } else {
            _for.value = _for.index;
            _for.index = null;
        }

        eat_token(parser.lexer, #char ":");
        _for.iterator = parse(parser, _for);
    }

    if maybe_eat_token(parser.lexer, t => t.kind == .DIRECTIVE && t.string_value == "no_abc") {
        _for.no_abc = true;
    }

    if maybe_eat_token(parser.lexer, t => t.kind == .DIRECTIVE && t.string_value == "no_aoc") {
        _for.no_aoc = true;
    }

    _for.body = parse(parser, _for);
    return _for;
}

parse_if :: (parser: *Parser, kind: If.If_Kind = .UNKNOWN, compile_time := false) -> *Node {
    _if := New(If);
    _if.compile_time = compile_time;

    if kind == .UNKNOWN {
        if_token: *Token;

        if is_token(parser.lexer, .KEYWORD_IFX) {
            if_token = eat_token(parser.lexer, .KEYWORD_IFX);
            _if.if_kind = .IFX;
        } else {
            if_token = eat_token(parser.lexer, .KEYWORD_IF);
            _if.if_kind = .IF;
        }
    } else {
        _if.if_kind = kind;
    }

    has_directive, directive_token := maybe_eat_token(parser.lexer, .DIRECTIVE);
    if has_directive && directive_token.string_value == "complete" {
        _if.marked_as_complete = true;
    }

    _if.condition = parse(parser, _if);

    switch := false;

    find_last_binary_operator :: (binary_operation: *Binary_Operation) -> *Binary_Operation {
        if binary_operation.right && binary_operation.right.kind == . BINARY_OPERATION {
            return find_last_binary_operator(xx binary_operation.right);
        }

        return binary_operation;
    }

    if _if.condition && _if.condition.kind == .BINARY_OPERATION {
        binary_op := find_last_binary_operator(xx _if.condition);

        switch = binary_op.operation == .IS_EQUAL && binary_op.right && binary_op.right.kind == .BLOCK;
    }

    if !switch {

        // #no_aoc -> if true #no_aoc {}
        if maybe_eat_token(parser.lexer, t => t.kind == .DIRECTIVE && t.string_value == "no_aoc") {
            _if.no_aoc = true;
        }

        maybe_eat_token(parser.lexer, .KEYWORD_THEN);
        _if._then = parse(parser, _if);

        if maybe_eat_token(parser.lexer, .KEYWORD_ELSE) {
            _if._else = parse(parser, _if);
        }
    } else {
        _if.if_kind = .SWITCH;
    }

    return _if;
}

parse_case :: (parser: *Parser) -> *Node {
    _case := New(Case);
    eat_token(parser.lexer, .KEYWORD_CASE);
    _case.expression = parse(parser, _case);
    maybe_eat_token(parser.lexer, #char ";");

    _case.members = parse_until(parser, token => token.kind == .KEYWORD_CASE || token.kind == #char "}", parent = _case);

    return _case;
}

parse_break :: (parser: *Parser) -> *Node {
    _break := New(Break);
    eat_token(parser.lexer, .KEYWORD_BREAK);

    if !is_token(parser.lexer, #char ";") {
        _break.expression = parse(parser, _break);
    }

    return _break;
}

parse_using :: (parser: *Parser) -> *Node {
    _using := New(Using);
    using_token := eat_token(parser.lexer, .KEYWORD_USING);

    // modifiers
    if is_token(parser.lexer, #char ",") {
        eat_token(parser.lexer, #char ",");

        modifier := eat_token(parser.lexer, .IDENTIFIER);

        if modifier.string_value == {
            case "map";
             _using.filter_type = .MAP;
            case "except";
             _using.filter_type = .EXCEPT;
            case "only";
             _using.filter_type = .ONLY;
        }
    }

    if _using.filter_type != .NONE {

        if is_token(parser.lexer, #char "(") {
            _using.filters = delimeted(parser, #char "(", #char ")", #char ",", _using);
        } else {
            _using.filter_expression = parse(parser, _using);
        }

    }

    _using.expression = parse(parser, _using);

    return _using;
}

parse_cast :: (parser: *Parser, auto: bool = false) -> *Cast {
    _cast := New(Cast);
    _cast.auto = auto;

    eat_token(parser.lexer, ifx auto then Token.Kind.KEYWORD_AUTO_CAST else Token.Kind.KEYWORD_CAST);

    // modifiers
    if is_token(parser.lexer, #char ",") {
        eat_token(parser.lexer, #char ",");

        modifier := eat_token(parser.lexer, .IDENTIFIER);

        if modifier.string_value == {
            case "trunc";
             _cast.truncate = true;
            case "no_check";
             _cast.no_check = true;
            case "force";
             _cast.force = true;
        }
    }

    if !auto && maybe_eat_token(parser.lexer, #char "(") {
        _cast.cast_expression = parse(parser, _cast);
        eat_token(parser.lexer, #char ")");
    }

    _cast.expression = parse(parser, _cast);

    return _cast;
}

parse_inline :: (parser: *Parser) -> *Node {
    eat_token(parser.lexer, .KEYWORD_INLINE);
    next_node := parse(parser, null);

    if next_node.kind == .PROCEDURE {
        (cast(*Procedure) next_node).flags |= .INLINE;
    }

    if next_node.kind == .PROCEDURE_CALL {
        (cast(*Procedure_Call) next_node).inlined = true;
    }

    return next_node;
}

parse_push_context :: (parser: *Parser) -> *Push_Context {
    _push_context := New(Push_Context);

    push_context_token := eat_token(parser.lexer, .KEYWORD_PUSH_CONTEXT);
    _push_context.backticked = push_context_token.backticked;

    if maybe_eat_token(parser.lexer, #char ",") {
        modifier_token := eat_token(parser.lexer, .IDENTIFIER);
        _push_context.defer_pop = modifier_token.string_value == "defer_pop";
    }

    _push_context.pushed = parse(parser, _push_context);

    // @TODO: Block only?
    if is_token(parser.lexer, #char "{") {
        _push_context.block = parse_block(parser);
        _push_context.block.parent = _push_context;
    }

    return _push_context;
}

parse_operator_overload :: (parser: *Parser) -> *Operator_Overload {
    operator_overload := New(Operator_Overload);

    eat_token(parser.lexer, .KEYWORD_OPERATOR);

    op := eat_token(parser.lexer);
    // assert(is_operator(op));

    // operator [] :: and operator []= ::
    if op.kind == #char "[" {
        eat_token(parser.lexer, #char "]");

        if maybe_eat_token(parser.lexer, #char "=") {
            operator_overload.operation = .ARRAY_SUBSCRIPT;
        } else {
            operator_overload.operation = .ARRAY_SUBSCRIPT_ASSIGNMENT;
        }

    } else {
        operator_overload.operation = create_operator_from_token(op);
    }


    if maybe_eat_token(parser.lexer, .CONSTANT_DECLARATION) {
        operator_overload.procedure = parse(parser, operator_overload);
    }

    return operator_overload;
}

// @TODO: We currently don't parse ASM blocks body.
// @TODO: We want catch the ASM block probably at lexer level not in parser. (useless tokens being created)
parse_inline_assembly :: (parser: *Parser) -> *Inline_Assembly {
    inline_assembly := New(Inline_Assembly);

    if !is_token(parser.lexer, #char "{") {
        inline_assembly.expression = parse(parser, inline_assembly);
    }

    eat_token(parser.lexer, #char "{");
    while !is_token(parser.lexer, #char "}") eat_token(parser.lexer);
    eat_token(parser.lexer, #char "}");

    return inline_assembly;
}

parse_notes :: (parser: *Parser, parent: *Node, notes: *[..]*Note) {
    while is_token(parser.lexer, .NOTE) array_add(notes, parse_note(parser, parent));
}

parse_note :: (parser: *Parser, parent: *Node) -> *Note  {
    note_token := eat_token(parser.lexer, .NOTE);
    note := New(Note);
    note.name = note_token.string_value;
    note.parent = parent;

    set_start_location(note, note_token);

    if maybe_eat_token(parser.lexer, #char "(") {
        builder: String_Builder;

        // @TODO: This is ugly
        while !end(parser.lexer) && !is_token(parser.lexer, #char ")") {
            token := eat_token(parser.lexer);

            if token.kind < 256 {
                append(*builder, cast(u8) token.kind);
                continue;
            }

            if token.kind == .STRING || token.kind == .NUMBER || token.kind == .DIRECTIVE || token.kind == .NOTE || token.kind == .IDENTIFIER {
                append(*builder, token.string_value);
                continue;
            }

            // @TODO: Operators!
            append(*builder, enum_value_to_name(token.kind));
        }

        note.value = builder_to_string(*builder);
        maybe_eat_token(parser.lexer, #char ")");
    }

    set_end_location(note, peek_token(parser.lexer, -1));

    return note;
}

parse_initialize_zero :: (parser: *Parser) -> *Initialize_Zero {
    eat_token(parser.lexer, .TRIPLE_MINUS);
    return New(Initialize_Zero);
}
