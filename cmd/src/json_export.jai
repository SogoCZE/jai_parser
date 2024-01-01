
#import "Jason";

is_array_of_nodes :: (info: *Type_Info) -> bool {
    if info.type != .ARRAY return false;
    array_info := cast(*Type_Info_Array) info;
    if !array_info.element_type return false;

    return is_node(array_info.element_type);
}

is_node_struct :: (info: *Type_Info) -> bool {
    if info.type != .STRUCT return false;
    _struct_info := cast(*Type_Info_Struct) info;

    return _struct_info.name == "Node" || _struct_info.name == "Return_Value" || _struct_info.name == "Note";
}

is_pointer_to_struct :: (info: *Type_Info) -> bool {
    if info.type != .POINTER return false;
    pointer_info := cast(*Type_Info_Pointer) info;
    if !pointer_info.pointer_to return false;

    return pointer_info.pointer_to.type == .STRUCT;
}


is_pointer_to_node :: (info: *Type_Info) -> bool {
    if info.type != .POINTER return false;
    pointer_info := cast(*Type_Info_Pointer) info;
    if !pointer_info.pointer_to return false;

    return is_node(pointer_info.pointer_to);
}

is_node :: (info: *Type_Info) -> bool {
    if info.type == {
        case .POINTER;
            return is_pointer_to_node(info);
        case .STRUCT;
            return is_node_struct(info);
        case .ARRAY;
            return is_array_of_nodes(info);
    }

    return false;
}

struct_with_nodes_to_json :: (node: *$T/Node) -> string {
    if !node return "null";

    json_builder: String_Builder;

    append(*json_builder, "{");

    print_to_builder(*json_builder, "\"kind\": %,", json_write_string(node.kind));
    print_to_builder(*json_builder, "\"location\": %", json_write_string(node.location, indent_char=""));

    #insert -> string {
        info := type_info(T);
        assert(info.type == .STRUCT);

        builder: String_Builder;

        real_index: int;

        for member: info.members {
            if member.name == "node" continue;
            if member.type.type == .TYPE continue;

             append(*builder, #string STR 
                append(*json_builder, ",");
            STR);

            if member.name == "values" {

                // Fix this :number_types:
                print_to_builder(*builder, #string _STR

                    append(*json_builder, "\"values\":");

                    if node.value_type == {
                        case .BOOL;
                            append(*json_builder, json_write_string(node._bool));
                        case .INT;
                            append(*json_builder, json_write_string(node._string));
                        case .FLOAT;
                            append(*json_builder, json_write_string(node._string));
                        case .STRING;
                            append(*json_builder, json_write_string(node._string));

                        // :array_literal_json_export_structure:
                        case .ARRAY;
                            append(*json_builder, "{");

                            append(*json_builder, "\"element_type\":");
                            append(*json_builder, to_json(node.array_literal_info.element_type));
                            
                            append(*json_builder, ",");
                            append(*json_builder, "\"elements\":");
                            append(*json_builder, "[");

                            for element: node.array_literal_info.elements {
                                if it_index != 0 append(*json_builder, ",");
                                append(*json_builder, to_json(element));
                            }

                            append(*json_builder, "]");
                            append(*json_builder, "}");

                        // :struct_literal_json_export_structure:
                        case .STRUCT;
                            append(*json_builder, "{");

                            append(*json_builder, "\"type\":");
                            append(*json_builder, to_json(node.struct_literal_info.type));

                            append(*json_builder, ",");
                            append(*json_builder, "\"body\":");
                            append(*json_builder, "[");

                            for node: node.struct_literal_info.body {
                                if it_index != 0 append(*json_builder, ",");
                                append(*json_builder, to_json(node));
                            }

                            append(*json_builder, "]");
                            append(*json_builder, "}");
                        case;
                            append(*json_builder, "null");
                    }
                _STR);

                continue;
            }

            real_index += 1;

            print_to_builder(*builder, #string STR 
                append(*json_builder, "\""); 
                append(*json_builder, "%"); 
                append(*json_builder, "\":");
            STR, member.name);

            if is_node(member.type) {
                if is_array_of_nodes(member.type) {
                    print_to_builder(*builder, #string STR 
                        append(*json_builder, "[");
                        for node.% {
                            if it_index > 0 {
                                append(*json_builder, ",");
                            }
                            append(*json_builder, to_json(it));
                        }
                        append(*json_builder, "]");
                    STR, member.name);
                } else {
                    print_to_builder(*builder, #string STR 
                        append(*json_builder, to_json(node.%));
                    STR, member.name);
                }

                continue;
            }

            if member.type.type == .STRUCT || is_pointer_to_struct(member.type) {
                // Hardcoded skip!!
                if member.name == "header_location" {
                    print_to_builder(*builder, #string STR 
                        append(*json_builder, "\"\"");
                    STR, member.name);
                    continue;
                }

                print_to_builder(*builder, #string STR 
                    append(*json_builder, struct_with_nodes_to_json(node.%));
                STR, member.name);
                continue;
            }

            print_to_builder(*builder, #string STR 
                append(*json_builder, json_write_string(node.%1));
            STR, member.name);
        }

        return builder_to_string(*builder);
    }

    append(*json_builder, "}");

    return builder_to_string(*json_builder);
}

to_json :: (node: *Node) -> string {
    if !node return "null";

    // TYPE_INSTANTIATION => Type_Instantiation
    enum_to_struct_name :: (enum_name: string) -> string {
        lower_enum_name := to_lower_copy_new(enum_name);
        upper_next := true;
        for cast([]u8) lower_enum_name {
            if upper_next {
                lower_enum_name[it_index] = to_upper(it);
            }

            upper_next = it == #char "_";
        }

        return lower_enum_name;
    }

    #insert -> string {
        info := type_info(Node.Kind);
        builder: String_Builder;

        print_to_builder(*builder, "if node.kind == {");

        for name: info.names {
            if name == "UNINITIALIZATED" continue; 
            struct_name := enum_to_struct_name(name);
            print_to_builder(*builder, "case .%; return struct_with_nodes_to_json(cast(*%) node);\n", name, struct_name);
        }

        append(*builder, "}");

        return builder_to_string(*builder);
    } 

    return "";
}

