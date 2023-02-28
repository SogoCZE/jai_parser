
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
        if node.kind == .DECLARATION {
            decl := cast(*Declaration) node;

            if decl.expression && !decl.type_inst {

                if decl.const 
                    printo("% :: ", decl.name); 
                else 
                    printo("% := ", decl.name);


                if decl.expression.kind == {
                    case .STRUCT;
                        printo("struct ");
                        _struct := cast(*Struct) decl.expression;
                        print_block(_struct.block);
                    case .PROCEDURE;
                        printo("() ");
                        proc := cast(*Procedure) decl.expression;
                        print_block(*proc.body);
                    case .ENUM;
                        printo("enum ");

                    case .LITERAL;
                        literal := cast(*Literal) decl.expression;
                        print_literal(literal);

                } 


                return;
            }

            if !decl.expression && decl.type_inst {
                printo("%: %;\n", decl.name, decl.type_inst.result);
                return;
            }

            if decl.expression && decl.type_inst {
                printo("%: % = %;\n", decl.name, decl.type_inst.kind, decl.expression.kind);            
            }

        }
}

print_literal :: (literal: *Literal) {
    if literal.value_type == {
        case .STRING;
            print("\"%\";\n", literal._string);
        case .FALSE;
            print("false;\n");
        case .TRUE;
            print("true;\n");

    }
}

print_block :: (block: *Block) {
    printo("{\n");
    push_context with_offset() {
        for block.members print_node(it);
    }
    printo("}\n");
}