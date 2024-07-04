// This file contains procedures to turn parser nodes into string.
// This is useful when we need to provide "peek" of code to the editor.
// Also we could probably use this for formatter?

ast_print :: (builder: *String_Builder, node: *Node) {
    if !node return;
    if node.kind == {
        case .IDENTIFIER;                   ast_print_identifier(builder, xx node);
        case .DECLARATION;                  ast_print_declaration(builder, xx node);
        case .UNARY_OPERATION;              ast_print_unary_operation(builder, xx node);
        case .BINARY_OPERATION;             ast_print_binary_operation(builder, xx node);
        case .RETURN_VALUE;                 ast_print_return_value(builder, xx node);
        case .POLYMORPHIC_CONSTANT;         ast_print_polymorphic_constant(builder, xx node);
        case .PROCEDURE;                    ast_print_procedure_header(builder, xx node);
        case .USING;                        ast_print_using(builder, xx node);
        case .ARRAY_TYPE;                   ast_print_array_type(builder, xx node);
        case .LITERAL;                      ast_print_literal(builder, xx node);
        case;                               append(builder, sprint("%", node.kind));
    }
}

ast_print_identifier :: (builder: *String_Builder, ident: *Identifier) {
    if ident.backticked append(builder, #char "`");
    append(builder, ident.name);
}

ast_print_polymorphic_constant :: (builder: *String_Builder, poly_const: *Polymorphic_Constant) {
    append(builder, #char "$");
    if poly_const.maybe_constant append(builder, #char "$");

    if poly_const.expression {
        ast_print(builder, poly_const.expression);
    }

    if poly_const.restriction {
        append(builder, #char "/");
        if poly_const.restrictions_interface append(builder, "interface ");
        ast_print(builder, poly_const.restriction);
    }

}

ast_print_unary_operation :: (builder: *String_Builder, unary_op: *Unary_Operation) {
    if unary_op.operation == {
        case .PLUS; append(builder, #char "+");
        case .MINUS; append(builder, #char "-");
        case .POINTER; append(builder, #char "*");
        case .ELLIPSIS; append(builder, "..");
        case .NEGATE; append(builder, #char "!");
        case .POINTER_DEREFERENCE; append(builder, "<<");
        case .BITWISE_NOT; append(builder, #char "~");
        case .DOT; append(builder, #char ".");
    }

    if unary_op.expression {
        ast_print(builder, unary_op.expression);
    }
}

ast_print_binary_operation :: (builder: *String_Builder, binary_op: *Binary_Operation) {
    if binary_op.left {
        ast_print(builder, binary_op.left);
    }

    if binary_op.operation == {
        case .DOT;                                      append(builder, #char ".");
        case .RANGE;                                    append(builder, "..");

        case .ADDITION;                                 append(builder, #char "+");
        case .SUBTRACTION;                              append(builder, #char "-");
        case .MULTIPLICATION;                           append(builder, #char "*");
        case .DIVISION;                                 append(builder, #char "/");
        case .MODULO;                                   append(builder, #char "%");
        case .LESS;                                     append(builder, #char ">");
        case .GREATER;                                  append(builder, #char "<");
        case .ASSING;                                   append(builder, #char "=");
        case .BITWISE_AND;                              append(builder, #char "%");
        case .PIPE;                                     append(builder, #char "|");
        case .BITWISE_NOT;                              append(builder, #char "~");
        case .BITWISE_XOR;                              append(builder, #char "^");

        case .BITWISE_AND_ASSIGNMENT;                   append(builder, "&=");
        case .BITWISE_XOR_ASSIGNMENT;                   append(builder, "^=");
        case .PIPE_EQUAL;                               append(builder, "|=");
        case .GREATER_EQUAL;                            append(builder, ">=");
        case .LESS_EQUAL;                               append(builder, "<=");
        case .PLUS_EQUAL;                               append(builder, "+=");
        case .MINUS_EQUAL;                              append(builder, "-=");
        case .MOD_EQUAL;                                append(builder, "%=");
        case .DIV_EQUAL;                                append(builder, "/=");
        case .TIMES_EQUAL;                              append(builder, "*=");
        case .LOGICAL_AND;                              append(builder, "&&");
        case .LOGICAL_AND_ASSIGNMENT;                   append(builder, "&&=");
        case .LOGICAL_OR;                               append(builder, "||");
        case .LOGICAL_OR_ASSIGNMENT;                    append(builder, "||=");
        case .IS_EQUAL;                                 append(builder, "==");
        case .IS_NOT_EQUAL;                             append(builder, "!=");
        case .LEFT_SHIFT;                               append(builder, "<<");
        case .RIGHT_SHIFT;                              append(builder, ">>");
        case .LEFT_SHIFT_ASSIGNMENT;                    append(builder, "<<= ");
        case .RIGHT_SHIFT_ASSIGNMENT;                   append(builder, ">>=");
        case .UNSIGNED_RIGHT_SHIFT;                     append(builder, ">>>");
        case .UNSIGNED_LEFT_SHIFT;                      append(builder, "<<<");
        case .UNSIGNED_RIGHT_SHIFT_ASSIGNMENT;          append(builder, ">>>=");
        case .UNSIGNED_LEFT_SHIFT_ASSIGNMENT;           append(builder, "<<<=");

        case .ARRAY_SUBSCRIPT;                          append(builder, "[]");
        case .ARRAY_SUBSCRIPT_ASSIGNMENT;               append(builder, "[]=");
    }

    if binary_op.right {
        ast_print(builder, binary_op.right);
    }
}

ast_print_declaration :: (builder: *String_Builder, decl: *Declaration) {
    if decl.backticked {
        append(builder, #char "`");
    }

    append(builder, decl.name);

    if decl.type_inst {
        append(builder, ": ");
        ast_print(builder, decl.type_inst);
    }

    if decl.expression {

        if decl.const {
            append(builder, " :: ");
        } else {
            append(builder, " = ");
        }

        ast_print(builder, decl.expression);
    }

    if decl.has_elsewhere {
        append(builder, "#elsewhere");

        if decl.elsewhere.count > 0 {
            append(builder, #char "\"");
            append(builder, decl.elsewhere);
            append(builder, #char "\"");
        }
    }

}

ast_print_using :: (builder: *String_Builder, _using: *Using) {
    append(builder, "using");

    if _using.filter_type != .NONE {
        append(builder, #char ",");

        if _using.filter_expression {
            append(builder, #char " ");
            ast_print(builder, _using.filter_expression);
        } else {
            append(builder, #char "(");
            for filter: _using.filters ast_print(builder, filter);
            append(builder, #char ")");
        }

    }

    append(builder, #char " ");
    ast_print(builder, _using.expression);
}

ast_print_array_type :: (builder: *String_Builder, array_type: *Array_Type) {
    append(builder, #char "[");

    if array_type.resizable {
        append(builder, "..");
    }

    if array_type.dimension {
        ast_print(builder, array_type.dimension);
    }

    append(builder, #char "]");
    ast_print(builder, array_type.element_type);
}

ast_print_return_value :: (builder: *String_Builder, return_val: *Return_Value) {
    if return_val.must append(builder, "#must ");

    if return_val.expression {
        ast_print(builder, return_val.expression);
    }
}

ast_print_literal :: (builder: *String_Builder, literal: *Literal) {

    if literal.value_type == {
        case .BOOL; append(builder, ifx literal._bool "true" else "false");
        case .INT; append(builder, literal._string);
        case .FLOAT; append(builder, literal._string);
        case .STRING; append(builder, literal._string);

        case .ARRAY;
            array_info := literal.array_literal_info;

            if array_info.element_type {
                ast_print(builder, array_info.element_type);
            }

            append(builder, #char ".");
            append(builder, #char "[");

            for element: array_info.elements {
                ast_print(builder, element);
                if it_index != array_info.elements.count-1 {
                    append(builder, #char ",");
                }
            }

            append(builder, #char "]");

        case .STRUCT;
            struct_info := literal.struct_literal_info;

            if struct_info.type {
                ast_print(builder, struct_info.type);
            }

            append(builder, #char ".");
            append(builder, #char "{");

            for member: struct_info.body {
                ast_print(builder, member);
                if it_index != struct_info.body.count-1 {
                    append(builder, #char ",");
                }
            }

            append(builder, #char "}");
    }

}

ast_print_procedure_header :: (builder: *String_Builder, proc: *Procedure) {
    append(builder, #char "(");

    for arg: proc.arguments {
        ast_print(builder, arg);
        if it_index != proc.arguments.count-1 {
            append(builder, ", ");
        }
    }

    append(builder, #char ")");

    if proc.returns.count > 0 {
        append(builder, " -> ");

        multiple := proc.returns.count > 1;
        if multiple append(builder, #char "(");

        for _return: proc.returns {
            ast_print(builder, _return);
            if it_index != proc.returns.count-1 {
                append(builder, ", ");
            }
        }

        if multiple append(builder, #char ")");
    }
}

ast_print_struct :: (builder: *String_Builder, _struct: *Struct) {

}