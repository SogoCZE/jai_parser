#import "Basic";
#import "String";
#import "Reflection";

Token_Kind :: enum {
    UNKNOWN;
    NULL;
    KEYWORD;
    IDENTIFIER;
    PUNCTUATION;
    OPERATOR;
    NUMBER; 
    STRING; 
    COMMENT; 
}

Token :: struct {
    kind: Token_Kind;
    line: int;
    column: int;
    
    union {
        keyword: Keyword;
        value: string;
        char: u8;
    }
}

Keyword :: enum u8 {
    STRUCT;
    ENUM;
    UNION;
    FOR;
    WHILE;
    IF;
    ELSE;
    RETURN;
    BREAK;
    CONTINUE; 
    IMPORT;
    LOAD;
    INLINE;
    FALSE;
    TRUE;
}

Tokenizer :: struct {
    tokens: [..]Token;
    cursor: int;
}

create_tokenizer :: (iterator: *Iterator) -> Tokenizer {
    tokenizer: Tokenizer;
    tokenizer.cursor = 0;
    
    while !end(iterator) {
        token := parse_next_token(iterator);
        array_add(*tokenizer.tokens, token);
    }

    return tokenizer;
}

print_token :: (token: Token) {
    value := token.value;

    if token.kind == .UNKNOWN || token.kind == .PUNCTUATION || token.kind == .OPERATOR {
        if is_space(token.char) {
            value = "<whitespace>";
        } else {
            value = to_string(*token.char);
        }
    }

    if token.kind == .KEYWORD {
        value = sprint("%", token.keyword);
    }

    print("% -> %\n", token.kind, value);
}

is_operator :: inline (char: u8) -> bool {
    return is_any(char, "+-/%$<>!=*#");
}

is_punctuation :: inline (char: u8) -> bool {
    return is_any(char, ".,;:{}[]()");
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

eat_identifier :: (tokenizer: *Tokenizer) -> *Token {
    token := eat_token(tokenizer);
    if token == null return null;
    assert(token.kind == .IDENTIFIER);
    return token;
}

eat_string :: (tokenizer: *Tokenizer) -> *Token {
    token := eat_token(tokenizer);
    if token == null return null;
    assert(token.kind == .STRING);
    return token;
}

eat_number :: (tokenizer: *Tokenizer) -> *Token {
    token := eat_token(tokenizer);
    if token == null return null;
    assert(token.kind == .NUMBER);
    return token;
}

eat_punction :: (tokenizer: *Tokenizer, punction: u8) -> *Token {
    token := eat_token(tokenizer);
    if token == null return null;
    assert(token.kind == .PUNCTUATION && token.char == punction);
    return token;
} 

eat_operator :: (tokenizer: *Tokenizer, char: u8) -> *Token {
    token := eat_token(tokenizer);
    if token == null return null;
    assert(token.kind == .OPERATOR && token.char == char);
    return token;
}   

eat_keyword :: (tokenizer: *Tokenizer, keyword: Keyword) -> *Token {
    token := eat_token(tokenizer);
    if token == null return null;
    assert(token.kind == .KEYWORD && token.keyword == keyword);
    return token;
}

end :: (using tokenizer: *Tokenizer) -> bool {
    return cursor + 1 >= tokens.count;
}

peek_token :: (using tokenizer: *Tokenizer, $count := 0) -> *Token {
    if cursor + count >= tokens.count return null;
    return *tokens[cursor+count];
}

is_punctuation :: (tokenizer: *Tokenizer, char: u8) -> bool {
    token := peek_token(tokenizer);
    return token.kind == .PUNCTUATION && token.char == char;
}

is_operator :: (tokenizer: *Tokenizer, char: u8) -> bool {
    token := peek_token(tokenizer);
    return token.kind == .OPERATOR && token.char == char;
}

is_keyword :: (tokenizer: *Tokenizer, keyword: Keyword) -> bool  {
    token := peek_token(tokenizer);
    return token.kind == .KEYWORD && token.keyword == keyword;
}

is_identifier :: inline (tokenizer: *Tokenizer) -> bool {
    return peek_token(tokenizer).kind == .IDENTIFIER;
}

parse_next_token :: (iterator: *Iterator) -> Token {
    next_while(iterator, is_space); // Přeskočíme všechny whitespace charaktery.

    if is_comment(iterator) {
        return parse_comment(iterator);
    }

    char := peek(iterator);

    if is_identifier_char(char) {
        return parse_identifier(iterator);
    }

    if is_punctuation(char) || is_operator(char) {
        token: Token;
        token.kind = ifx is_punctuation(char) then Token_Kind.PUNCTUATION else .OPERATOR;
        token.char = next(iterator);
        return token;
    }

    if char == #char "\"" {
        return parse_string(iterator);
    }

    if is_digit(char) {
        return parse_digit(iterator);
    }

    token: Token;
    token.char = next(iterator);
    return token;
}

parse_comment :: (using iterator: *Iterator) -> Token {
    // Přeskočíme první //
    next(iterator); 
    multiline := next(iterator) == #char "*";

    builder: String_Builder;
    init_string_builder(*builder);

    while !end(iterator) {
        char := next(iterator);
        if !multiline && char == #char "\n" break;
        if multiline && char == #char "*" && peek(iterator) == #char "/" {
            next(iterator); // Odebereme konec "/"
            break;
        }

        append(*builder, char);
    }

    token: Token;
    token.kind = .COMMENT;
    token.value = builder_to_string(*builder);

    return token;
}

parse_identifier :: (using iterator: *Iterator) -> Token {
    token: Token;
    identifier := next_while(iterator,  char => is_identifier_char(char) || is_digit(char)); // is_digit protože můžeme mít např. Person2 :: struct {}
    keyword := false;

    for keyword_name: enum_names(Keyword) {
        if identifier == to_lower_copy(keyword_name) {
            keyword = true;
            break;
        }
    }

    if keyword {
        token.kind = .KEYWORD;
        identifier_uppercased := to_upper_copy(identifier);
        enum_value, ok := enum_name_to_value(Keyword, identifier_uppercased);
        assert(ok, "invalid keyword %", identifier_uppercased);
        token.keyword = enum_value;
    } else {
        token.kind = .IDENTIFIER;
        token.value = identifier;
    }
    
    return token;
}

parse_string :: (using iterator: *Iterator) -> Token {
    next(iterator); // Přeskočíme první uvozovku
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

    token: Token;
    token.kind = .STRING;
    token.value = builder_to_string(*builder);

    return token;
}

parse_digit :: (using iterator: *Iterator) -> Token {
    token: Token;
    number := next_while(iterator, char => is_digit(char) || char == #char ".");

    token.kind = .NUMBER;
    token.value = number;

    return token;
}
