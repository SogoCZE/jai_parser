
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

            if decl.expression && decl.type_inst == null {

                if decl.expression.kind == {
                    case .STRUCT;
                        printo("% :: struct ", decl.name);
                        _struct := cast(*Struct) decl.expression;
                        print_block(_struct.block);
                    case .PROCEDURE;
                        printo("% :: ()", decl.name);
                        proc := cast(*Procedure) decl.expression;
                        print_block(*proc.body);
                    case .ENUM;
                        printo("% :: enum\n", decl.name);
                } 


                return;
            }

            if !decl.expression && decl.type_inst {
                printo("%: %;\n", decl.name, decl.type_inst.kind);
                return;
            }

            if decl.expression && decl.type_inst {
                printo("%: % = %;\n", decl.name, decl.type_inst.kind, decl.expression.kind);            
            }

        }
}

print_block :: (block: *Block) {
    printo("{\n");
    push_context with_offset() {
        for block.members print_node(it);
    }
    printo("}\n");
}