#import "Basic";
#import "String";
#import "reflection";

Token_Kind :: enum {
    UNKNOWN;
    KEYWORD;
    IDENTIFIER;
    PUNCTUATION;
    OPERATOR;
    NUMBER; 
    STRING; 
}

Token :: struct {
    kind: Token_Kind;
    union {
        keyword: Keyword;
        value: string;
        char: u8;
    }
}

Keyword :: enum {
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
}

print_token :: (token: Token) -> string {
    value: string;

    if token.kind == .UNKNOWN || token.kind == .PUNCTUATION || token.kind == .OPERATOR {
        if is_space(token.char) {
            value = "<whitespace>";
        } else {
            value = to_string(*token.char);
        }
    }

    if token.kind == .IDENTIFIER || token.kind == .STRING || token.kind == .NUMBER {
        value = token.value;
    }

    if token.kind == .KEYWORD {
        value = sprint("%", token.keyword);
    }

    print("% -> %\n", token.kind, value);
}

is_operator :: inline (char: u8) -> bool {
    return is_any(char, "+-/%$<>!=*");
}

is_punctuation :: inline (char: u8) -> bool {
    return is_any(char, ".,;:{}[]()");
}

next_while :: (character_iterator: *Character_Iterator, predicate: (char: u8) -> bool) -> string {
    builder: String_Builder;
    init_string_builder(*builder);

    while !end(character_iterator) && predicate(peek(character_iterator)) {
        append(*builder, next(character_iterator));
    }

    return builder_to_string(*builder);
}

is_identifier_char :: (char: u8) -> bool {
    return is_alpha(char) || char == #char "_";
}

next_token :: (character_iterator: *Character_Iterator) -> Token {
    next_while(character_iterator, is_space); // Přeskočíme všechny whitespace charaktery.

    char := peek(character_iterator);

    if is_identifier_char(char) {
        return parse_identifier(character_iterator);
    }

    if is_punctuation(char) || is_operator(char) {
        token: Token;
        token.kind = ifx is_punctuation(char) then Token_Kind.PUNCTUATION else .OPERATOR;
        token.char = next(character_iterator);
        return token;
    }

    if char == #char "\"" {
        return parse_string(character_iterator);
    }

    if is_digit(char) {
        return parse_digit(character_iterator);
    }

    token: Token;
    token.char = next(character_iterator);
    return token;
}

parse_identifier :: (using character_iterator: *Character_Iterator) -> Token {
    token: Token;
    identifier := next_while(character_iterator, is_identifier_char);
    identifier_uppercased := to_upper_copy(identifier);
    keyword := contains_any_string(identifier_uppercased, ..enum_names(Keyword));

    if keyword {
        token.kind = .KEYWORD;
        enum_value, ok := enum_name_to_value(Keyword, identifier_uppercased);
        assert(ok, "invalid keyword %", identifier_uppercased);
        token.keyword = enum_value;
    } else {
        token.kind = .IDENTIFIER;
        token.value = identifier;
    }
    
    return token;
}

parse_string :: (using character_iterator: *Character_Iterator) -> Token {
    next(character_iterator); // Přeskočíme první uvozovku
    escaped := false;

    builder: String_Builder;
    init_string_builder(*builder);
    
    while !end(character_iterator) {
        char := next(character_iterator);

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

parse_digit :: (using character_iterator: *Character_Iterator) -> Token {
    token: Token;
    number := next_while(character_iterator, char => is_digit(char) || char == #char ".");

    token.kind = .NUMBER;
    token.value = number;

    return token;
}
