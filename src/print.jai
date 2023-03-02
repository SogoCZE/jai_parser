
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
            print("() ");
            proc := cast(*Procedure) node;
            print_block(*proc.body);
        case .ENUM;
            print("enum ");
        case .LITERAL;
            print_literal(xx node);
    }
}

print_decl :: (decl: *Declaration) {
    if decl.expression && !decl.type_inst {

        if decl.const 
            printo("% :: ", decl.name); 
        else 
            printo("% := ", decl.name);

        print_node(decl.expression);

        return;
    }

    if !decl.expression && decl.type_inst {
        printo("%: %;\n", decl.name, decl.type_inst.result);
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
            print("\"%\";\n", literal._string);       
        case .NUMBER;
            print("%;\n", literal._string);
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