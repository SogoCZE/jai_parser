
#import "Jason";

struct_with_nodes_to_json :: (node: *$T/Node) -> string {
    json_builder: String_Builder;

    append(*json_builder, "{");

    is_node :: (member: Type_Info_Struct_Member) -> bool {
        
        // TODO:
        return false;
    }

    #insert -> string {
        info := type_info(T);
        assert(info.type == .STRUCT);

        builder: String_Builder;

        for member: info.members {
            if member.name == "node" continue;
            if is_node(member) continue;

            if it_index > 1 {
                append(*builder, #string JAI 
                    append(*json_builder, ",");
                JAI);
            }

            print_to_builder(*builder, #string JAI 
                append(*json_builder, "\""); 
                append(*json_builder, "%1"); 
                append(*json_builder, "\":");
                
                append(*json_builder, json_write_string(node.%1));
            JAI, member.name);
        }

        return builder_to_string(*builder);
    }

    append(*json_builder, "}");

    return builder_to_string(*json_builder);
}

to_json :: (node: *Node) -> string {

    // TYPE_INSTANTIATION => Type_Instantiation
    enum_to_struct_name :: (enum_name: string) -> string {
        lower_enum_name := to_lower_copy(enum_name);
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

json_key_value :: (key: string, value: string) -> string {
    return sprint("\"%\":\"%\"", key, value);
}

to_json :: (decl: *Declaration) -> string {
    builder: String_Builder;

    append(*builder, "{");

    print_to_builder(*builder, json_key_value("name", decl.name));
    append(*builder, ",");
    print_to_builder(*builder, json_key_value("expression", to_json(decl.expression)));

    append(*builder, "}");

    return builder_to_string(*builder);
}