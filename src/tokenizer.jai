#import "Basic";
#import "String";
#import "Reflection";

Token_Kind :: enum {
    // ASCII Types...

    IDENTIFIER :: 256; // person
    NUMBER; // 10, 3.14, 2_456_000, .40
    STRING; // "text"
    // HERE_STRING; // "text"
    COMMENT; // */ */ //
    NULL; // NULL

    PLUS_EQUAL; // +=
    MINUS_EQUAL; // -=
    MOD_EQUAL; // %=
    DIV_EQUAL; // /=
    TIMES_EQUAL; // *=
    LESS_EQUAL; // <=
    GREATER_EQUAL; // >=
    LOGICAL_AND; // &&
    LOGICAL_AND_ASSIGNMENT; // &&=
    PIPE_EQUAL; // |=
    BITWISE_EQUAL; // &=
    LOGICAL_OR; // ||
    LOGICAL_OR_ASSIGNMENT; // ||=
    IS_EQUAL; // ==
    IS_NOT_EQUAL; // !=

    DOUBLE_MINUS; // --
    TRIPLE_MINUS; // ---
    DOUBLE_DOLLAR; // $$
    DOUBLE_DOT; // ..
    ARROW_RIGHT; // ->

    // @TODO: Do these have correct names?
    LEFT_SHIFT; // <<, POINTER_DEREFERENCE
    RIGHT_SHIFT; // >>
    LEFT_SHIFT_ASSIGNMENT; // <<= 
    RIGHT_SHIFT_ASSIGNMENT; // >>=
    UNSIGNED_RIGHT_SHIFT; // >>>
    UNSIGNED_LEFT_SHIFT; // <<<
    UNSIGNED_RIGHT_SHIFT_ASSIGNMENT; // >>>=
    UNSIGNED_LEFT_SHIFT_ASSIGNMENT; // <<<=

    CONSTANT_DECLARATION; // ::
    DECLARATION_AND_ASSIGN; // :=

    NOTE; // @note
    DIRECTIVE; // #run
    QUICK_LAMBDA; // =>

    KEYWORD_STRUCT;
    KEYWORD_INTERFACE;
    KEYWORD_ENUM;
    KEYWORD_ENUM_FLAGS;
    KEYWORD_UNION;
    KEYWORD_FOR;
    KEYWORD_WHILE;
    KEYWORD_BREAK;
    KEYWORD_USING;
    KEYWORD_IF;
    KEYWORD_IFX;
    KEYWORD_CASE;
    KEYWORD_ELSE;
    KEYWORD_THEN;
    KEYWORD_DEFER;
    KEYWORD_RETURN;
    KEYWORD_INLINE;
    KEYWORD_NO_INLINE;
    KEYWORD_CAST;
    KEYWORD_PUSH_CONTEXT;
    KEYWORD_OPERATOR;
    KEYWORD_CONTINUE; 
    KEYWORD_IMPORT;
    KEYWORD_LOAD;
    KEYWORD_FALSE;
    KEYWORD_TRUE;
    KEYWORD_AUTO_CAST; // xx
    // KEYWORD_IS_CONSTANT;
    // KEYWORD_CONTEXT;
    // KEYWORD_ADD_CONTEXT;

    UNKNOWN;
}

Token :: struct {
    kind: Token_Kind = .UNKNOWN;

    file: string;

    l0: int;
    c0: int;
    l1: int;
    c1: int;
    
    here_string_cr: bool; // @TODO: Is this good to have this here?

    union {
        string_value: string;
        integer_value: int;
        float_value: float;
    }

    backticked: bool;
}

Tokenizer :: struct {
    tokens: [..]Token;
    cursor := 0;
    next_backticked: bool;
}

create_tokenizer :: (iterator: *Iterator) -> Tokenizer {
    tokenizer: Tokenizer;
    
    while !end(iterator) {
        token := parse_next_token(iterator, *tokenizer);
        if token.kind == .UNKNOWN continue;

        if tokenizer.next_backticked {
            tokenizer.next_backticked = false;
            token.backticked = true;
        }

        array_add(*tokenizer.tokens, token);
    }

    return tokenizer;
}

print_token :: (token: *Token) {
    if !token {
        print("<null token>\n");
        return;
    }

    value: string;

    if token.kind == .STRING || token.kind == .COMMENT || token.kind == .IDENTIFIER {
        value = token.string_value;
    }

    if token.kind == .NUMBER {
        if token.float_value > 0 {
            value = tprint("%", token.float_value);
        } else {
            value = tprint("%", token.integer_value);
        }
    }

    if value.count == 0 {
        if token.kind < 256 {
            print("% -> %\n", token, to_string(*cast(u8) token.kind, 1));
        } else {
            print("% -> %\n", token, token.kind);
        }
    } else {
        print("% -> %\n", token, value);
    }
}

// @TODO: Is this complete? ...
is_operator :: (token: *Token) -> bool {
    if !token return false;

    if token.kind == {
        case #char "+";                          return true;
        case #char "-";                          return true;
        case #char "/";                          return true;
        case #char "*";                          return true;
        case #char "%";                          return true;
        case #char ">";                          return true;
        case #char "<";                          return true;
        case #char ".";                          return true;
        case #char "=";                          return true;
        case #char "&";                          return true;
        case #char "|";                          return true;
        case .PLUS_EQUAL;                       return true;
        case .MINUS_EQUAL;                      return true;
        case .MOD_EQUAL;                        return true;
        case .DIV_EQUAL;                        return true;
        case .TIMES_EQUAL;                      return true;
        case .LESS_EQUAL;                       return true;
        case .GREATER_EQUAL;                    return true;
        case .BITWISE_EQUAL;                     return true;
        case .LOGICAL_AND;                       return true;
        case .LOGICAL_AND_ASSIGNMENT;            return true;
        case .PIPE_EQUAL;                        return true;
        case .LOGICAL_OR;                        return true;
        case .LOGICAL_OR_ASSIGNMENT;             return true;
        case .IS_EQUAL;                          return true;
        case .IS_NOT_EQUAL;                      return true;
        case .DOUBLE_DOT;                        return true;
        case .LEFT_SHIFT;                        return true;
        case .RIGHT_SHIFT;                       return true;
        case .LEFT_SHIFT_ASSIGNMENT;             return true;
        case .RIGHT_SHIFT_ASSIGNMENT;            return true;
        case .UNSIGNED_RIGHT_SHIFT;              return true;
        case .UNSIGNED_LEFT_SHIFT;               return true;
        case .UNSIGNED_RIGHT_SHIFT_ASSIGNMENT;   return true;
        case .UNSIGNED_LEFT_SHIFT_ASSIGNMENT;    return true;
    }

    return false;
}

next_while :: (iterator: *Iterator, predicate: (char: u8) -> bool) -> string {
    builder: String_Builder;
    init_string_builder(*builder);

    while !end(iterator) && predicate(peek(iterator)) {
        append(*builder, next(iterator));
    }

    return builder_to_string(*builder);
}

is_identifier_char :: (char: u8) -> bool {
    return is_alpha(char) || char == #char "_";
}

is_comment :: (iterator: *Iterator) -> bool {
    if peek(iterator) != #char "/" return false;
    next_char := peek(iterator, 2);
    return next_char == #char "/" || next_char == #char "*";
}

eat_token :: (using tokenizer: *Tokenizer) -> *Token {
    if end(tokenizer) return null;
    cursor += 1;
    return *tokens[cursor-1];
}

eat_token :: (tokenizer: *Tokenizer, kind: Token_Kind) -> *Token {
    token := eat_token(tokenizer);
    assert(token != null, "Token is null!");

    if token.kind != kind {
        log_error("token % != required % (%:%:%)", token.kind, kind, token.file, token.l0, token.c0); // @TODO: is this ok?
    }

    return token;
}

is_token :: (tokenizer: *Tokenizer, kind: Token_Kind, $peek := 0) -> bool {
    token := peek_token(tokenizer, peek);
    if !token || token.kind != kind return false;
    return true;
}

is_token :: (tokenizer: *Tokenizer, predicate: (token: *Token) -> bool, $peek := 0) -> bool {
    token := peek_token(tokenizer, peek);
    if !token || !predicate(token) return false;
    return true;
}

meaybe_eat_token :: (tokenizer: *Tokenizer, kind: Token_Kind) -> bool {
    next_token := peek_token(tokenizer);
    if !next_token || next_token.kind != kind return false;
    eat_token(tokenizer, kind);
    return true;
}

end :: (using tokenizer: *Tokenizer) -> bool {
    return cursor + 1 > tokens.count;
}

peek_token :: (using tokenizer: *Tokenizer, $count := 0) -> *Token {
    if cursor + count >= tokens.count return null;
    return *tokens[cursor+count];
}

is_identifier :: inline (tokenizer: *Tokenizer) -> bool {
    return is_token(tokenizer, .IDENTIFIER);
}

maybe_eat_token :: (tokenizer: *Tokenizer, predicate: (token: *Token) -> bool) -> bool, *Token {
    token := peek_token(tokenizer);
    if !predicate(token) return false, null;
    return true, eat_token(tokenizer);
}

maybe_eat_token :: (tokenizer: *Tokenizer, kind: Token_Kind) -> bool, *Token {
    token := peek_token(tokenizer);
    if !token || token.kind != kind return false, null;
    return true, eat_token(tokenizer);
}

parse_next_token :: (iterator: *Iterator, tokenizer: *Tokenizer) -> Token {
    next_while(iterator, is_space); // We skip all whitespaces

    if is_comment(iterator) {
        return parse_comment(iterator);
    }

    char := peek(iterator);

    // Notes
    if char == #char "@" && is_identifier_char(peek(iterator, 2)) {
        return parse_note_or_directive(iterator, false);
    }

    // Directives
    if char == #char "#" && is_identifier_char(peek(iterator, 2)) {
        directive_token := parse_note_or_directive(iterator, true);

        if directive_token.string_value == "string" {
            return parse_here_string(iterator);
        }

        return directive_token;
    }

    // Identifiers
    if is_identifier_char(char) {
        return parse_identifier(iterator); // could also be a keyword ;
    }

    // Strings
    if char == #char "\"" {
        return parse_string(iterator);
    }

    // .40
    if char == #char "." && is_digit(peek(iterator, 2)) {
        return parse_number(iterator, true);
    }

    // Numbers
    if is_digit(char) {
        return parse_number(iterator, false);
    }

    // Backtick 
    if char == #char "`" {
        next(iterator); // eat `
        tokenizer.next_backticked = true;
        return .{}; // empty token (skipped by tokenizer)
    }

    // Special chars or compound chars
    return parse_char_token(iterator);
}

parse_comment :: (using iterator: *Iterator) -> Token {
    token: Token;
    token.kind = .COMMENT;
    token.file = iterator.file;
    token.l0 = iterator.line;
    token.c0 = iterator.column;

    // Skip the first //
    next(iterator); 
    multiline := next(iterator) == #char "*";

    builder: String_Builder;
    init_string_builder(*builder);

    while !end(iterator) {
        char := next(iterator);
        if !multiline && char == #char "\n" break;
        if multiline && char == #char "*" && peek(iterator) == #char "/" {
            next(iterator); // We remove end "/"
            break;
        }

        append(*builder, char);
    }


    token.string_value = builder_to_string(*builder);
    token.l1 = iterator.line;
    token.c1 = iterator.column;

    return token;
}

parse_note_or_directive :: (using iterator: *Iterator, directive: bool) -> Token {
    next(iterator); // Skip the "@"

    token: Token;
    token.file = iterator.file;
    token.l0 = iterator.line;
    token.c0 = iterator.column;

    token.kind = ifx directive then Token_Kind.DIRECTIVE else .NOTE;
    token.string_value = next_while(iterator,  char => is_identifier_char(char) || is_digit(char));

    token.l1 = iterator.line;
    token.c1 = iterator.column;   

    return token;
}

parse_identifier :: (using iterator: *Iterator) -> Token {
    token: Token;
    token.file = iterator.file;
    token.l0 = iterator.line;
    token.c0 = iterator.column;

    builder: String_Builder;
    init_string_builder(*builder);

    escaped_white_space: bool;
    
    while !end(iterator) {
        char := peek(iterator);
        is_ident_valid_char := is_identifier_char(char) || is_digit(char);

        if escaped_white_space && char == #char " " || char == #char "\t" {
            next(iterator); // eat space
            continue;
        }

        if is_ident_valid_char {
            append(*builder, next(iterator));

            if escaped_white_space escaped_white_space = false;
            
            continue;
        }

        if char == #char "\\" {
            escaped_white_space = true;
            next(iterator); // eat \
            continue;
        }

        break;
    }

    identifier := builder_to_string(*builder); // is_digit because we can have numbers in at the end of the idents Person2 :: struct {}
    keyword: string;

    for token_kind: enum_names(Token_Kind) {
        if !starts_with(token_kind, "KEYWORD") continue;

        KEYWORD_COUNT :: #run "KEYWORD_".count;

        token_kind_lower_without_prefix := token_kind;
        token_kind_lower_without_prefix = slice(token_kind_lower_without_prefix, KEYWORD_COUNT, token_kind.count-KEYWORD_COUNT);
        to_lower_in_place(token_kind_lower_without_prefix); // @TODO: this is dangerous because we lowering values in the enum type info!!! :lowering_in_type_info:

        if identifier == "xx" {
            keyword = "KEYWORD_auto_cast"; // This has to be lower because of :lowering_in_type_info:
            break;
        }

        if identifier == token_kind_lower_without_prefix {
            keyword = token_kind;
            break;
        }
    }

    if keyword {
        enum_value, ok := enum_name_to_value(Token_Kind, keyword); // This works with KEYWORD_lower because of :lowering_in_type_info:
        assert(ok, "invalid keyword %", keyword);
        token.kind = enum_value;
    } else {
        token.kind = .IDENTIFIER;
        token.string_value = identifier;
    }

    token.l1 = iterator.line;
    token.c1 = iterator.column;
    
    return token;
}

parse_string :: (using iterator: *Iterator) -> Token {
    token: Token;
    token.kind = .STRING;
    token.file = iterator.file;
    token.l0 = iterator.line;
    token.c0 = iterator.column;
    
    next(iterator); // We skip the first "
    escaped := false;

    builder: String_Builder;
    init_string_builder(*builder);
    
    while !end(iterator) {
        char := next(iterator);

        if escaped {
            append(*builder, char);
            escaped = false;   
        } else if char == #char "\\" {
            escaped = true;
        } else if char == #char "\"" {
            break;
        } else {
            append(*builder, char);
        }
    }

    token.l1 = iterator.line;
    token.c1 = iterator.column;
    token.string_value = builder_to_string(*builder);

    return token;
}

// @TODO: We need to test it more!
parse_here_string :: (using iterator: *Iterator) -> Token {
    token: Token;
    token.kind = .STRING;
    token.file = iterator.file;
    token.l0 = iterator.line;
    token.c0 = iterator.column;

    // #string,cr
    if peek(iterator) == #char "," {
        next(iterator); // eat ,

        if is_identifier_char(peek(iterator)) {
            token.here_string_cr = parse_identifier(iterator).string_value == "cr";
        }

    }

    next_while(iterator, is_space); // Skip all whitespaces

    if !is_identifier_char(peek(iterator)) {
        log_error("Exprected identifier after #string");
        return .{};
    }

    here_identifier := parse_identifier(iterator).string_value;

    builder: String_Builder;
    init_string_builder(*builder);

    while true {
        char := next(iterator);

        if char == 0 {
            log_error("Unexpected end of file inside #string");
            break;
        }   

        if char == here_identifier[0] {
            ok := true;
            for 1..here_identifier.count-1 {
                if peek(iterator, it) == here_identifier[it] continue;
                
                ok = false;
                break;                
            }

            if ok {
                for 1..here_identifier.count-1 next(iterator); // eat and
                break;
            }
        }

        append(*builder, char);
    }

    token.l1 = iterator.line;
    token.c1 = iterator.column;
    token.string_value = builder_to_string(*builder);

    return token;
}

parse_number :: (using iterator: *Iterator, from_dot: bool) -> Token {
    token: Token;
    token.l0 = iterator.line;
    token.file = iterator.file;
    token.c0 = iterator.column;
    token.kind = .NUMBER; 

    hex := false;
    if !from_dot && peek(iterator) == #char "0" && peek(iterator, 2) == #char "x" {
        next(iterator); // eat 0
        next(iterator); // eat x
        hex = true;
    }

    builder: String_Builder;
    init_string_builder(*builder);

    if from_dot {
        next(iterator); // eat .
        append(*builder, "0.");
    }

    if hex append(*builder, "0x");

    is_float := from_dot;

    is_valid_numeric_char :: (char: u8, iterator: *Iterator, is_float: *bool) -> bool {
        if is_digit(char) return true;
        if char == #char "_" return true;
        if !<<is_float && char == #char "." && is_digit(peek(iterator, 2)) {
            <<is_float = true;
            return true;
        }

        return false;
    }

    while !end(iterator) && is_valid_numeric_char(peek(iterator), iterator, *is_float) {
        append(*builder, next(iterator));
    }

    number_value := builder_to_string(*builder);
    number_value = replace(number_value, "_", ""); // Remove all _ in number

    // if hex {
    //
    // } else {
    //     ok: bool;
    //     if contains(number_value, ".") {
    //         token.float_value, ok = parse_float(*number_value);
    //     } else {
    //         token.integer_value, ok = parse_int(*number_value);
    //     }

    //     if !ok {
    //         log_error("Invalid number!"); // @InComplete: What now?
    //     }
    // }

    token.string_value = number_value;

    token.l1 = iterator.line;
    token.c1 = iterator.column;

    return token;
}

parse_char_token :: (iterator: *Iterator) -> Token {
    token: Token;
    token.l0 = iterator.line;
    token.file = iterator.file;
    token.c0 = iterator.column;

    char := next(iterator);
    next_char := peek(iterator);

    if char == #char "+" && next_char == #char "=" {
        next(iterator);
        token.kind = .PLUS_EQUAL;
    }

    if char == #char "-" {
        if next_char == #char ">" {
            next(iterator);
            token.kind = .ARROW_RIGHT; // ->
        } 
        
        if next_char == #char "=" {
            next(iterator);
            token.kind = .MINUS_EQUAL; // -=
        } 

        if next_char == #char "-" {
            next(iterator);
            
            if peek(iterator) == #char "-" {
                next(iterator);
                token.kind = .TRIPLE_MINUS; // ---
            } else {
                token.kind = .DOUBLE_MINUS; // --
            }

        }
    }

    if char == #char "%" && next_char == #char "=" {
        next(iterator);
        token.kind = .MOD_EQUAL;
    }
    
    if char == #char "/" && next_char == #char "=" {
        next(iterator);
        token.kind = .DIV_EQUAL;
    }
    
    if char == #char "*" && next_char == #char "=" {
        next(iterator);
        token.kind = .TIMES_EQUAL;
    }

    if char == #char "<" && next_char == #char "<" {
        next(iterator); // <

        if peek(iterator) == #char "<" {
            next(iterator); // <

            if peek(iterator) == #char "=" {
                next(iterator); // =
                token.kind = .UNSIGNED_LEFT_SHIFT_ASSIGNMENT;
            } else {
                token.kind = .UNSIGNED_LEFT_SHIFT;
            }

        } else if peek(iterator) == #char "=" {
            next(iterator); // =
            token.kind = .LEFT_SHIFT_ASSIGNMENT;
        } else {
            token.kind = .LEFT_SHIFT;
        }

    }

    if char == #char "<" && next_char == #char "=" {
        next(iterator);
        token.kind = .LESS_EQUAL;
    }

    if char == #char ">" && next_char == #char ">" {
        next(iterator); // >

        if peek(iterator) == #char ">" {
            next(iterator); // >

            if peek(iterator) == #char "=" {
                next(iterator); // =
                token.kind = .UNSIGNED_RIGHT_SHIFT_ASSIGNMENT;
            } else {
                token.kind = .UNSIGNED_RIGHT_SHIFT;
            }

        } else if peek(iterator) == #char "=" {
            next(iterator); // =
            token.kind = .RIGHT_SHIFT_ASSIGNMENT;
        } else {
            token.kind = .RIGHT_SHIFT;
        }

    }
    
    if char == #char ">" && next_char == #char "=" {
        next(iterator);
        token.kind = .GREATER_EQUAL;
    }

    if char == #char "&" && next_char == #char "=" {
        next(iterator);
        token.kind = .BITWISE_EQUAL;
    }
    
    if char == #char "&" && next_char == #char "&" {
        next(iterator);

        if peek(iterator) == #char "=" {
            next(iterator); // =
            token.kind = .LOGICAL_AND_ASSIGNMENT;
        } else {
            token.kind = .LOGICAL_AND;
        }

    }

    if char == #char "|" && next_char == #char "=" {
        next(iterator);
        token.kind = .PIPE_EQUAL;
    }
    
    if char == #char "|" && next_char == #char "|" {
        next(iterator);

        if peek(iterator) == #char "=" {
            next(iterator); // =
            token.kind = .LOGICAL_OR_ASSIGNMENT;
        } else {
            token.kind = .LOGICAL_OR;
        }

    }
    
    if char == #char "=" {

        if next_char == #char ">" {
            next(iterator);
            token.kind = .QUICK_LAMBDA;
        } 

        if next_char == #char "=" {
            next(iterator);
            token.kind = .IS_EQUAL;
        }
    }

    if char == #char "!" && next_char == #char "=" {
        next(iterator);
        token.kind = .IS_NOT_EQUAL;
    }
    
    if char == #char "$" && next_char == #char "$" {
        next(iterator);
        token.kind = .DOUBLE_DOLLAR;
    }
    
    if char == #char "." && next_char == #char "." {
        next(iterator);    
        token.kind = .DOUBLE_DOT;
    }
    
    if char == #char ":" {
        if next_char == #char "=" {
            next(iterator);
            token.kind = .DECLARATION_AND_ASSIGN;
        }
        
        if next_char == #char ":" {
            next(iterator);
            token.kind = .CONSTANT_DECLARATION;
        }
    }

    if token.kind == .UNKNOWN {
        token.kind = xx char;
    }

    token.l1 = iterator.line;
    token.c1 = iterator.column;

    return token;
}