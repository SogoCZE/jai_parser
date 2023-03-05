
#add_context print_offset: int = 0;

with_offset :: () -> Context {
    new_context := context;
    new_context.print_offset += 1;
    return new_context;
}

printo :: (format: string, args: ..Any) {
    for 0..context.print_offset-1 print("   ");
    print(format, ..args);    
} @PrintLike

print_node :: (node: *Node) {
    if node.kind == {
        case .DECLARATION;
            print_decl(xx node);
        case .STRUCT;
            print("struct ");
            _struct := cast(*Struct) node;
            print_block(_struct.block);
        case .PROCEDURE;
            proc := cast(*Procedure) node;
            
            printo("(");
            first := true;

            for proc.arguments {
                if first {
                    first = false;
                } else {
                    print(", ");
                }
                print_node(it);
            }
            printo(") ");
            
            print_block(proc.body);
        case .ENUM;
            print("enum ");
            _enum := cast(*Enum) node;
            print_block(_enum.block);
        case .LITERAL;
            print_literal(xx node);
        case .IDENTIFIER;
            ident := cast(*Identifier) node;
            printo("%;", ident.name);
    }
}

print_decl :: (decl: *Declaration, new_line := false) {
    if decl.expression && !decl.type_inst {

        if decl.const 
            printo("% :: ", decl.name); 
        else 
            printo("% := ", decl.name);

        print_node(decl.expression);

        return;
    }

    if !decl.expression && decl.type_inst {
        printo("%: %", decl.name, decl.type_inst.result);
        return;
    }

    if decl.expression && decl.type_inst {
        printo("%: % =", decl.name, decl.type_inst.result);
        print_node(decl.expression);            
    }
}

print_literal :: (literal: *Literal) {
    if literal.value_type == {
        case .STRING;
            print("\"%\";", literal._string);       
        case .NUMBER;
            print("%;", literal._string);
        case .FALSE;
            print("false;");
        case .TRUE;
            print("true;");
    }
}

print_block :: (block: *Block) {
    printo("{\n");
    push_context with_offset() {
        for block.members {
            print_node(it);
            printo("\n");
        }
    }
    printo("}\n");
}