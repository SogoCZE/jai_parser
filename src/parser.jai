Node :: struct {

    Kind :: enum {
        UNINITIALIZATED;
        DECLARATION;
        BLOCK;
        STRUCT;
        ENUM;
        PROCEDURE;
        PROCEDURE_CALL;
        TYPE_INSTANTIATION;
        DIRECTIVE;
        LITERAL;
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

    type_inst: *Type_Instantiation;
    expression: *Node;
}

Block :: struct {
    using #as node: Node;
    kind = .BLOCK;

    members: []*Node;
}

Type_Instantiation :: struct {
    using #as node: Node;
    kind = .TYPE_INSTANTIATION;

    result: string; 
}

Procedure :: struct {
    using #as node: Node;
    kind = .PROCEDURE;

    arguments: []*Node;
    body: Block; // Body asi budemem uset defernout!
}

Struct :: struct {
    using #as node: Node; 
    kind = .STRUCT;

    block: *Block;
    name: string;
}

Enum :: struct {
    using #as node: Node; 
    kind = .ENUM;

    block: *Block;
    name: string;
}

Directive :: struct {
    using #as node: Node; 
    kind = .DIRECTIVE;

    name: string;
}

Literal :: struct {
    using #as node: Node; 
    kind = .LITERAL;
}

parse :: (tokenizer: *Tokenizer) -> *Node {

    if is_identifier(tokenizer) {
        ident := eat_identifier(tokenizer);

        // Declaration
        // Statement
        if is_punctuation(tokenizer, #char "(") {
            print("procedure call!\n");
        }

        if is_punctuation(tokenizer, #char ":") {
            return parse_declaration(ident.value, tokenizer);
        }

    }

    eat_token(tokenizer);

    // print("Skipped:");
    // print_token(token);

    return null;
}

parse_declaration :: (name: string, tokenizer: *Tokenizer) -> *Declaration {
    decl := New(Declaration);

    decl.name = name;

    eat_punction(tokenizer, #char ":"); 

    if is_punctuation(tokenizer, #char ":") {
        print("% :: exp\n", decl.name);
    }

    if is_punctuation(tokenizer, #char "=") {
        print("% := exp\n", decl.name);
    }

    if is_identifier(tokenizer) {
        print("%: type_inst\n", decl.name);
    }



    return decl;
}
