#import "Basic";
#import "String";
#import "Reflection";

// TODO: Token\   Kind 

Token_Kind :: enum {
    // ASCII Types...

    IDENTIFIER :: 256; // person
    NUMBER; // 10, 3.14, 2_456_000
    STRING; // "text"
    COMMENT; // */ */ //
    NULL; // NULL

    PLUS_EQUEAL; // +=
    MINUS_EQUEAL; // -=
    MOD_EQUEAL; // %=
    DIV_EQUEAL; // /=
    TIMES_EQUEAL; // *=
    LESS_EQUEAL; // <=
    GREATER_EQUEAL; // >=
    LOGICAL_AND; // &&
    LOGICAL_OR; // ||
    IS_EQUAL; // ==
    IS_NOT_EQUAL; // !=

    DOUBLE_MINUS; // --
    TRIPLE_MINUS; // ---
    DOUBLE_DOLLAR; // $$
    DOUBLE_DOT; // ..
    ARROW_RIGHT; // ->

    CONSTANT_DECLARATION; // ::
    DECLARATION_AND_ASIGN; // :=

    NOTE; // @note
    DIRECTIVE; // #run
    QUICK_LAMBDA; // =>

    KEYWORD_STRUCT;
    KEYWORD_ENUM;
    KEYWORD_ENUM_FLAGS;
    KEYWORD_UNION;
    KEYWORD_FOR;
    KEYWORD_WHILE;
    KEYWORD_USING;
    KEYWORD_IF;
    KEYWORD_IFX;
    KEYWORD_ELSE;
    KEYWORD_RETURN;
    KEYWORD_DEFER;
    KEYWORD_NO_INLINE;
    KEYWORD_CAST;
    KEYWORD_CONTEXT;
    KEYWORD_PUSH_CONTEXT;
    KEYWORD_OPERATOR;
    KEYWORD_BREAK;
    KEYWORD_CONTINUE; 
    KEYWORD_IMPORT;
    KEYWORD_LOAD;
    KEYWORD_INLINE;
    KEYWORD_FALSE;
    KEYWORD_TRUE;
    KEYWORD_IS_CONSTANT;
    KEYWORD_AUTO_CAST; // xx

    UNKNOWN;
}

Token :: struct {
    kind: Token_Kind = .UNKNOWN;

    l0: int;
    c0: int;
    l1: int;
    c1: int;
    
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

print_token :: (token: Token) {
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

end :: (using tokenizer: *Tokenizer) -> bool {
    return cursor + 1 > tokens.count;
}

peek_token :: (using tokenizer: *Tokenizer, $count := 0) -> *Token {
    if cursor + count >= tokens.count return null;
    return *tokens[cursor+count];
}

is_identifier :: inline (tokenizer: *Tokenizer) -> bool {
    return peek_token(tokenizer).kind == .IDENTIFIER;
}

maybe_eat_token :: (tokenizer: *Tokenizer, predicate: (token: *Token) -> bool) -> bool, *Token {
    token := peek_token(tokenizer);
    if !predicate(token) return false, null;
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

    // Numbers
    if is_digit(char) {
        return parse_digit(iterator);
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
    token.l0 = iterator.line;
    token.c0 = iterator.column;

    identifier := next_while(iterator,  char => is_identifier_char(char) || is_digit(char)); // is_digit because we can have numbers in at the end of the idents Person2 :: struct {}
    keyword := false;

    for token_kind: enum_names(Token_Kind) {
        if !starts_with(token_kind, "KEYWORD") continue;

        token_kind_lower_without_prefix := to_lower_copy(replace(token_kind, "KEYWORD_", ""));

        if identifier == token_kind_lower_without_prefix || identifier == "xx" {
            keyword = true;
            break;
        }
    }

    if keyword {
        identifier_uppercased: string;
        
        if identifier == "xx" {
            identifier_uppercased = "AUTO_CAST";
        } else {
            identifier_uppercased = to_upper_copy(identifier);
        }

        enum_value, ok := enum_name_to_value(Token_Kind, tprint("KEYWORD_%", identifier_uppercased));
        assert(ok, "invalid keyword %", identifier_uppercased);
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
    token.l0 = iterator.line;
    token.c0 = iterator.column;

    next_while(iterator, is_space); // Skip all whitespaces

    if !is_identifier_char(peek(iterator)) {
        log_error("Exprected identifier after #string");
        return .{};
    }

    here_identifier := parse_identifier(iterator).string_value;

    print("..: %\n", here_identifier);

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

parse_digit :: (using iterator: *Iterator) -> Token {
    token: Token;
    token.l0 = iterator.line;
    token.c0 = iterator.column;
    token.kind = .NUMBER;

    number_value := next_while(iterator, char => is_digit(char) || char == #char "." || char == #char "_");
    number_value = replace(number_value, "_", ""); // Remove all _ in number

    ok: bool;
    if contains(number_value, ".") {
        token.float_value, ok = parse_float(*number_value);
    } else {
        token.integer_value, ok = parse_int(*number_value);
    }

    if !ok {
        log_error("Invalid number!"); // @InComplete: What now?
    }

    token.l1 = iterator.line;
    token.c1 = iterator.column;

    return token;
}

parse_char_token :: (iterator: *Iterator) -> Token {
    token: Token;
    token.l0 = iterator.line;
    token.c0 = iterator.column;

    char := next(iterator);
    next_char := peek(iterator);

    if char == #char "+" && next_char == #char "=" {
        next(iterator);
        token.kind = .PLUS_EQUEAL;
    }

    if char == #char "-" {
        if next_char == #char ">" {
            next(iterator);
            token.kind = .ARROW_RIGHT; // ->
        } 
        
        if next_char == #char "=" {
            next(iterator);
            token.kind = .MINUS_EQUEAL; // -=
        } 

        if next_char == #char "-" {
            next(iterator);
            
            if peek(iterator) == #char "-" {
                next(iterator);
                token.kind = .TRIPLE_MINUS;
            } else {
                token.kind = .DOUBLE_MINUS;
            }

        }
    }

    if char == #char "%" && next_char == #char "=" {
        next(iterator);
        token.kind = .MOD_EQUEAL;
    }
    
    if char == #char "/" && next_char == #char "=" {
        next(iterator);
        token.kind = .DIV_EQUEAL;
    }
    
    if char == #char "*" && next_char == #char "=" {
        next(iterator);
        token.kind = .TIMES_EQUEAL;
    }
    
    if char == #char "<" && next_char == #char "=" {
        next(iterator);
        token.kind = .LESS_EQUEAL;
    }
    
    if char == #char ">" && next_char == #char "=" {
        next(iterator);
        token.kind = .GREATER_EQUEAL;
    }
    
    if char == #char "&" && next_char == #char "&" {
        next(iterator);
        token.kind = .LOGICAL_AND;
    }
    
    if char == #char "|" && next_char == #char "|" {
        next(iterator);
        token.kind = .LOGICAL_OR;
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
            token.kind = .DECLARATION_AND_ASIGN;
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