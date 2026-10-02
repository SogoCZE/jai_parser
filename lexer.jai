// @TODO: remove this
total_tokens: int;

Token :: struct {

    Kind :: enum u16 {
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
        BITWISE_AND_ASSIGNMENT; // &=
        BITWISE_XOR_ASSIGNMENT; // ^=
        LOGICAL_OR; // ||
        LOGICAL_OR_ASSIGNMENT; // ||=
        IS_EQUAL; // ==
        IS_NOT_EQUAL; // !=

        DOUBLE_MINUS; // --
        TRIPLE_MINUS; // ---
        DOUBLE_DOLLAR; // $$
        DOUBLE_DOT; // ..
        ARROW_RIGHT; // ->

        DOUBLE_COMMA; // ,,

        // @TODO: Do these have correct names?
        LEFT_SHIFT; // <<, POINTER_DEREFERENCE
        RIGHT_SHIFT; // >>
        LEFT_SHIFT_ASSIGNMENT; // <<=
        RIGHT_SHIFT_ASSIGNMENT; // >>=
        UNSIGNED_RIGHT_SHIFT; // >>>
        UNSIGNED_LEFT_SHIFT; // <<<
        UNSIGNED_RIGHT_SHIFT_ASSIGNMENT; // >>>=
        UNSIGNED_LEFT_SHIFT_ASSIGNMENT; // <<<=

        PREFIX_DEREFERENCE; // (.*) as a unary operator

        CONSTANT_DECLARATION; // ::
        DECLARATION_AND_ASSIGN; // :=

        NOTE; // @note
        DIRECTIVE; // #run
        QUICK_LAMBDA; // =>

        BEGIN_STRUCT_LITERAL; // .{
        BEGIN_ARRAY_LITERAL; // .[

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
        KEYWORD_REMOVE;
        KEYWORD_FALSE;
        KEYWORD_TRUE;
        KEYWORD_AUTO_CAST; // xx

        UNKNOWN;
    }

    kind: Kind = .UNKNOWN;
    number_kind: Number_Kind;
    backticked: bool;

    file: string;

    l0: int;
    c0: int;
    l1: int;
    c1: int;

    // NOTE: string_value is separated from int and float value because for numbers we want to keep both representations - string represantation of a number is usefull for example in formatting to not remove underscores from literals.
    string_value: string;
    union {
        integer_value: int;
        float_value: float64;
    }
}

Number_Kind :: enum u8 {
    UNKNOWN;
    INT;
    FLOAT;
    SCIENTIFIC_FLOAT;
    HEX_INT;
    HEX_FLOAT;
    BINARY;
}

Comment_Token :: struct
{
    #as using token: Token;
    token.kind = .COMMENT;

    multiline: bool;
}

Lexer :: struct {
    tokens: [..]Token;
    comments: [..]Comment_Token;
    cursor := 0;
    next_backticked: bool;

    has_syntax_errors: bool;
}

create_lexer :: (source: string, file: string) -> Lexer {
    text := copy_string(source);

    iterator: Iterator;
    iterator.file = file;
    iterator.cursor = text.data;
    iterator.end = text.data + text.count;

    lexer: Lexer;
    array_reserve(*lexer.tokens, text.count / 5 + 16);

    while !end(*iterator) {
        token := array_add(*lexer.tokens);
        result := parse_next_token(*iterator, *lexer, token);

        if result == .NONE {
            lexer.tokens.count -= 1;
            continue;
        }

        if result == .TOKEN && lexer.next_backticked {
            lexer.next_backticked = false;
            token.backticked = true;
        }
    }

    return lexer;
}

print_token :: (token: *Token) {
    if !token {
        log("<null token>\n");
        return;
    }

    value: string;

    if token.kind == .STRING || token.kind == .COMMENT || token.kind == .IDENTIFIER {
        value = token.string_value;
    }

    if token.kind == .NUMBER {
        kind := token.number_kind;
        if kind == .FLOAT || kind == .SCIENTIFIC_FLOAT || kind == .HEX_FLOAT {
            value = tprint("%", token.float_value);
        } else {
            value = tprint("%", token.integer_value);
        }
    }

    if value.count == 0 {
        if token.kind < 255 {
            log("% -> %\n", token, to_string(*cast(u8) token.kind, 1));
        } else {
            log("% -> %\n", token, token.kind);
        }
    } else {
        log("% -> %\n", token, value);
    }
}

token_kind_to_string :: (kind: Token.Kind) -> string {
    if kind > 255 {
        return tprint("%", kind);
    } else {
        return tprint("%", to_string(*(cast(u8) kind), 1));
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
        case #char "^";                          return true;
        case #char "~";                          return true;
        case .PLUS_EQUAL;                        return true;
        case .MINUS_EQUAL;                       return true;
        case .MOD_EQUAL;                         return true;
        case .DIV_EQUAL;                         return true;
        case .TIMES_EQUAL;                       return true;
        case .LESS_EQUAL;                        return true;
        case .GREATER_EQUAL;                     return true;
        case .BITWISE_AND_ASSIGNMENT;            return true;
        case .LOGICAL_AND;                       return true;
        case .LOGICAL_AND_ASSIGNMENT;            return true;
        case .PIPE_EQUAL;                        return true;
        case .BITWISE_XOR_ASSIGNMENT;            return true;
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
        case .PREFIX_DEREFERENCE;                return true;
    }

    return false;
}

is_operator_assignment :: (token: *Token) -> bool {
    if !token return false;

    if token.kind == {
        case #char "=";                          return true;
        case .IS_EQUAL;                          return true;
        case .PIPE_EQUAL;                        return true;
        case .PLUS_EQUAL;                        return true;
        case .MINUS_EQUAL;                       return true;
        case .MOD_EQUAL;                         return true;
        case .DIV_EQUAL;                         return true;
        case .TIMES_EQUAL;                       return true;
        case .BITWISE_AND_ASSIGNMENT;            return true;
        case .LOGICAL_AND_ASSIGNMENT;            return true;
        case .BITWISE_XOR_ASSIGNMENT;            return true;
        case .LOGICAL_OR_ASSIGNMENT;             return true;
        case .LEFT_SHIFT_ASSIGNMENT;             return true;
        case .RIGHT_SHIFT_ASSIGNMENT;            return true;
        case .UNSIGNED_RIGHT_SHIFT_ASSIGNMENT;   return true;
        case .UNSIGNED_LEFT_SHIFT_ASSIGNMENT;    return true;
    }

    return false;
}

eat_token :: inline (using lexer: *Lexer) -> *Token {
    if end(lexer) return null;
    cursor += 1;
    return *tokens[cursor-1];
}

EMPTY_TOKEN: Token;

eat_token :: (lexer: *Lexer, kind: Token.Kind) -> *Token {
    token := eat_token(lexer);
    if !token {
        lexer.has_syntax_errors = true;
        log_error("Null token! (expected '%')", token_kind_to_string(kind)); // @TODO: add caller_location or something?
        EMPTY_TOKEN = .{};
        return *EMPTY_TOKEN;
    }

    if token.kind != kind {
        lexer.has_syntax_errors = true;
        log_error("token '%' != required '%' (%:%:%)", token_kind_to_string(token.kind), token_kind_to_string(kind), token.file, token.l0, token.c0); // @TODO: is this ok?
    }

    return token;
}

eat_all_upcoming_comments :: inline (lexer: *Lexer) {
    while is_token(lexer, .COMMENT) eat_token(lexer);
}

is_token :: inline (lexer: *Lexer, kind: Token.Kind, $peek := 0) -> bool {
    token := peek_token(lexer, peek);
    if !token || token.kind != kind return false;
    return true;
}

is_token :: (lexer: *Lexer, predicate: (token: *Token) -> bool, $peek := 0) -> bool {
    token := peek_token(lexer, peek);
    if !token || !predicate(token) return false;
    return true;
}

end :: inline (using lexer: *Lexer) -> bool {
    return cursor + 1 > tokens.count;
}

peek_token :: inline (using lexer: *Lexer, $count := 0) -> *Token {
    if cursor + count < 0 return null;
    if cursor + count >= tokens.count return null;
    return *tokens[cursor+count];
}

is_identifier :: inline (lexer: *Lexer) -> bool {
    return is_token(lexer, .IDENTIFIER);
}

maybe_eat_token :: (lexer: *Lexer, predicate: (token: *Token) -> bool) -> bool, *Token {
    token := peek_token(lexer);
    if !token return false, null;
    if !predicate(token) return false, null;
    return true, eat_token(lexer);
}

maybe_eat_token :: inline (lexer: *Lexer, kind: Token.Kind) -> bool, *Token {
    token := peek_token(lexer);
    if !token || token.kind != kind return false, null;
    return true, eat_token(lexer);
}

#scope_module

Iterator :: struct {
    line := 0;
    column := 0;
    cursor: *u8;
    end: *u8;
    file: string;
}

next :: inline (using iterator: *Iterator) -> u8 {
    if cursor >= end return 0;

    char := cursor.*;
    cursor += 1;

    if char == #char "\n" {
        line += 1;
        column = 0;
    } else {
        column += 1;
    }

    return char;
}

peek :: inline (using iterator: *Iterator, to := 1) -> u8 {
    if cursor + to - 1 >= end return 0;
    return cursor[to - 1];
}

end :: inline (using iterator: *Iterator) -> bool {
    return cursor >= end;
}

text_from :: inline (start: *u8, end: *u8) -> string {
    result: string;
    result.data = start;
    result.count = end - start;
    return result;
    }

CHAR_IDENTIFIER :: 1; // a-z A-Z _
CHAR_DIGIT      :: 2; // 0-9
CHAR_SPACE      :: 4; // space \t \r \n

CHAR_CLASSES :: #run -> [256]u8 {
    classes: [256]u8;
    for char: 0..255 {
        if (char >= #char "a" && char <= #char "z") || (char >= #char "A" && char <= #char "Z") || char == #char "_" classes[char] |= CHAR_IDENTIFIER;
        if char >= #char "0" && char <= #char "9" classes[char] |= CHAR_DIGIT;
        if char == #char " " || char == #char "\t" || char == #char "\r" || char == #char "\n" classes[char] |= CHAR_SPACE;
    }
    return classes;
};

is_identifier_char :: inline (char: u8) -> bool {
    return (CHAR_CLASSES[char] & CHAR_IDENTIFIER) != 0;
}

is_identifier_or_digit :: inline (char: u8) -> bool {
    return (CHAR_CLASSES[char] & (CHAR_IDENTIFIER | CHAR_DIGIT)) != 0;
}

is_space_char :: inline (char: u8) -> bool {
    return (CHAR_CLASSES[char] & CHAR_SPACE) != 0;
}

EIGHT_SPACES :: 0x2020_2020_2020_2020;

skip_spaces :: inline (using iterator: *Iterator) -> skipped: bool {
    start := cursor;
    while cursor < end {
        char := cursor.*;
        if char == #char " " {
            run_start := cursor;
            cursor += 1;
            while cursor + 8 <= end && (cast(*u64) cursor).* == EIGHT_SPACES cursor += 8;
            while cursor < end && cursor.* == #char " " cursor += 1;
            column += cursor - run_start;
        } else if char == #char "\t" || char == #char "\r" {
            cursor += 1;
            column += 1;
        } else if char == #char "\n" {
            cursor += 1;
            line += 1;
            column = 0;
        } else {
            break;
        }
    }

    return cursor != start;
}

find_newline :: (start: *u8, end: *u8) -> *u8 {
    ONES :: 0x0101_0101_0101_0101;
    HIGH :: 0x8080_8080_8080_8080;
    NEWLINES :: 0x0a0a_0a0a_0a0a_0a0a;

    cursor := start;
    while cursor + 8 <= end {
        word := (cast(*u64) cursor).* ^ NEWLINES;
        if (word - ONES) & ~word & HIGH break;
        cursor += 8;
    }

    while cursor < end && cursor.* != #char "\n" cursor += 1;
    return cursor;
}

is_comment :: inline (iterator: *Iterator) -> bool {
    if peek(iterator) != #char "/" return false;
    next_char := peek(iterator, 2);
    return next_char == #char "/" || next_char == #char "*";
}

eat_comments :: (iterator: *Iterator, lexer: *Lexer) -> bool {
    comments_found: bool;
    while is_comment(iterator) {
        comment := parse_comment(iterator);
        array_add(*lexer.comments, comment);
        comments_found = true;
        skip_spaces(iterator);
    }

    return comments_found;
}

Token_Result :: enum u8 {
    NONE;
    TOKEN;
    HERE_STRING;
}

parse_next_token :: (iterator: *Iterator, lexer: *Lexer, token: *Token) -> Token_Result {
    skip_spaces(iterator);

    // @TODO: remove this
    total_tokens += 1;

    // Skip comments - we don't want them in the parser. But we're keeping a separate list of comments if someone needs them (for example for formatting).
    eat_comments(iterator, lexer);

    if end(iterator) return .NONE;

    char := peek(iterator);

    if is_identifier_char(char) {
        parse_identifier(iterator, token);
        return .TOKEN;
    }

    // Notes
    if char == #char "@" && (is_identifier_char(peek(iterator, 2)) || peek(iterator, 2) == #char "\"") {
        parse_note_or_directive(iterator, false, token);
        return .TOKEN;
    }

    // Directives
    if char == #char "#" && is_identifier_char(peek(iterator, 2)) {
        parse_note_or_directive(iterator, true, token);

        if token.string_value == "string" {
            // NOTE: Here strings are processed in a bit hacky way. parse_here_string adds multiple tokens to the tokens list in lexer (after this one).
            parse_here_string(iterator, lexer);
            return .HERE_STRING;
        }

        return .TOKEN;
    }

    // Strings
    if char == #char "\"" {
        parse_string(iterator, token);
        return .TOKEN;
    }

    has_sign: bool;
    if (char == #char "+" || char == #char "-") && lexer.tokens.count > 1 {
        previous_token := *lexer.tokens[lexer.tokens.count - 2]; // The last one is the slot being filled.
        if is_operator(previous_token) || previous_token.kind == .DECLARATION_AND_ASSIGN {
        has_sign = true;
        char = peek(iterator, 2);
    }
    }

    // .40
    if char == #char "." && peek(iterator, 2) >= #char "0" && peek(iterator, 2) <= #char "9" {
        parse_number(iterator, true, has_sign, token);
        return .TOKEN;
    }

    // Numbers
    if char >= #char "0" && char <= #char "9" {
        parse_number(iterator, false, has_sign, token);
        return .TOKEN;
    }

    // Backtick
    if char == #char "`" {
        next(iterator); // eat `
        lexer.next_backticked = true;
        return .NONE;
    }

    // Special chars or compound chars
    parse_char_token(iterator, lexer, token);
    return .TOKEN;
}

parse_comment :: (using iterator: *Iterator) -> Comment_Token {
    token: Comment_Token;
    token.file = iterator.file;
    token.l0 = iterator.line;
    token.c0 = iterator.column;

    // Skip the first //
    next(iterator);
    multiline := next(iterator) == #char "*";
    token.multiline = multiline;

    content_start := cursor;
    content_end := cursor;

    if multiline {
    nested_comment: int;

        while cursor < end {
        char := next(iterator);

            if char == #char "/" && peek(iterator) == #char "*" {
                nested_comment += 1;
            }

            if char == #char "*" && peek(iterator) == #char "/" {
                if nested_comment == 0 {
                    content_end = cursor - 1; // Without the "*".
                    next(iterator); // We remove end "/"
                    break;
                }

                nested_comment -= 1;
            }

            content_end = cursor;
        }
    } else {
        line_start := cursor;
        cursor = find_newline(cursor, end);
        column += cursor - line_start;

        content_end = cursor;
        if cursor < end next(iterator);
        }

    token.string_value = text_from(content_start, content_end);
    token.l1 = iterator.line;
    token.c1 = iterator.column;

    if ends_with(token.string_value, "\r") {
        token.string_value.count -= 1;
    }

    return token;
}

parse_note_or_directive :: (using iterator: *Iterator, directive: bool, token: *Token) {
    token.file = iterator.file;
    token.l0 = iterator.line;
    token.c0 = iterator.column;

    next(iterator); // Skip the "@" or "#"

    token.kind = ifx directive then Token.Kind.DIRECTIVE else .NOTE;
    if directive {
        start := cursor;
        while cursor < end && is_identifier_or_digit(cursor.*) {
            cursor += 1;
            column += 1;
        }

        token.string_value = text_from(start, cursor);
    } else {
        char := peek(iterator);
        if char == #char "\"" {
            string_token: Token;
            parse_string(iterator, *string_token);
            token.string_value = join("\"", string_token.string_value, "\"");
        } else {
            start := cursor;
            while cursor < end && !is_space_char(cursor.*) next(iterator);
            token.string_value = text_from(start, cursor);
        }
    }

    token.l1 = iterator.line;
    token.c1 = iterator.column;
}

parse_identifier :: (using iterator: *Iterator, token: *Token) {
    token.file = iterator.file;
    token.l0 = iterator.line;
    token.c0 = iterator.column;

    start := cursor;
    while cursor < end && is_identifier_or_digit(cursor.*) cursor += 1;
    column += cursor - start;

    identifier := text_from(start, cursor);

    if cursor < end && cursor.* == #char "\\" {
    builder: String_Builder;
        append(*builder, identifier);

    escaped_white_space: bool;
        while cursor < end {
            char := peek(iterator);

            if escaped_white_space && (char == #char " " || char == #char "\t") {
            next(iterator); // eat space
            continue;
        }

            if is_identifier_or_digit(char) {
            append(*builder, next(iterator));
                escaped_white_space = false;
            continue;
        }

        if char == #char "\\" {
            escaped_white_space = true;
            next(iterator); // eat \
            continue;
        }

        break;
    }

        identifier = builder_to_string(*builder);
    }

    token.kind = keyword_kind_from_identifier(identifier);
    token.string_value = identifier;

    token.l1 = iterator.line;
    token.c1 = iterator.column;
}

is_keyword :: inline (kind: Token.Kind) -> bool {
    return kind >= .KEYWORD_STRUCT && kind <= .KEYWORD_AUTO_CAST;
}

// This smartness has been taken from Jai_Lexer (Jai  compiler included module)
keyword_kind_from_identifier :: (identifier: string) -> Token.Kind {
    if identifier.count == {
        case 2;
            if identifier == "if"           return .KEYWORD_IF;
            if identifier == "xx"           return .KEYWORD_AUTO_CAST;
        case 3;
            if identifier == "for"          return .KEYWORD_FOR;
            if identifier == "ifx"          return .KEYWORD_IFX;
        case 4;
            if identifier == "enum"         return .KEYWORD_ENUM;
            if identifier == "case"         return .KEYWORD_CASE;
            if identifier == "else"         return .KEYWORD_ELSE;
            if identifier == "then"         return .KEYWORD_THEN;
            if identifier == "cast"         return .KEYWORD_CAST;
            if identifier == "true"         return .KEYWORD_TRUE;
        case 5;
            if identifier == "union"        return .KEYWORD_UNION;
            if identifier == "while"        return .KEYWORD_WHILE;
            if identifier == "break"        return .KEYWORD_BREAK;
            if identifier == "using"        return .KEYWORD_USING;
            if identifier == "defer"        return .KEYWORD_DEFER;
            if identifier == "false"        return .KEYWORD_FALSE;
        case 6;
            if identifier == "struct"       return .KEYWORD_STRUCT;
            if identifier == "return"       return .KEYWORD_RETURN;
            if identifier == "inline"       return .KEYWORD_INLINE;
            if identifier == "remove"       return .KEYWORD_REMOVE;
        case 8;
            if identifier == "operator"     return .KEYWORD_OPERATOR;
            if identifier == "continue"     return .KEYWORD_CONTINUE;
        case 9;
            if identifier == "interface"    return .KEYWORD_INTERFACE;
            if identifier == "no_inline"    return .KEYWORD_NO_INLINE;
            if identifier == "auto_cast"    return .KEYWORD_AUTO_CAST;
        case 10;
            if identifier == "enum_flags"   return .KEYWORD_ENUM_FLAGS;
        case 12;
            if identifier == "push_context" return .KEYWORD_PUSH_CONTEXT;
    }

    return .IDENTIFIER;
}

parse_string :: (using iterator: *Iterator, token: *Token) {
    token.kind = .STRING;
    token.file = iterator.file;
    token.l0 = iterator.line;
    token.c0 = iterator.column;

    next(iterator); // We skip the first "


    start := cursor;
    content_end := cursor;
    while cursor < end {
        char := next(iterator);
        if char == #char "\\" {
            if cursor < end {
                next(iterator);
                content_end = cursor;
            }
            continue;
        }

        if char == #char "\"" break;
        content_end = cursor;
    }

    token.l1 = iterator.line;
    token.c1 = iterator.column;
    token.string_value = text_from(start, content_end);
}

// @TODO: We need to test it more!
parse_here_string :: (using iterator: *Iterator, lexer: *Lexer) {

    // #string,cr or #string,\%
    while peek(iterator) == #char "," {
        parse_char_token(iterator, lexer, array_add(*lexer.tokens));

        if is_identifier_char(peek(iterator)) {
            parse_identifier(iterator, array_add(*lexer.tokens));
        } else if peek(iterator, 1) == #char "\\" && peek(iterator, 2) == #char "%" {
            token: Token;
            token.kind = .IDENTIFIER;
            token.file = iterator.file;
            token.l0 = iterator.line;
            token.c0 = iterator.column;
            token.l1 = token.l0;
            token.c1 = token.c0;
            token.string_value = "\\%";
            array_add(*lexer.tokens, token);
            next(iterator);
            next(iterator);
        }
    }

    skip_spaces(iterator);

    if !is_identifier_char(peek(iterator)) {
        log_error("Exprected identifier after #string");
        return;
    }

    here_identifier_token := array_add(*lexer.tokens);
    parse_identifier(iterator, here_identifier_token);
    here_identifier := here_identifier_token.string_value;

    if !here_identifier {
        log_error("Expected identifier after #string (%:%:%)", iterator.file, here_identifier_token.l0, here_identifier_token.c0);
        lexer.has_syntax_errors = true;
        return;
    }

    string_token: Token;
    string_token.kind = .STRING;
    string_token.file = iterator.file;
    string_token.l0 = iterator.line;
    string_token.c0 = iterator.column;

    start := cursor;
    content_end := cursor;

    while true {
        before := cursor;
        char := next(iterator);

        if char == 0 {
            log_error("Unexpected end of file inside #string");
            content_end = before;
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
                content_end = before;
                for 1..here_identifier.count-1 next(iterator); // eat and
                break;
            }
        }
    }

    string_token.l1 = iterator.line;
    string_token.c1 = iterator.column;
    string_token.string_value = text_from(start, content_end);

    array_add(*lexer.tokens, string_token);
}

parse_number :: (using iterator: *Iterator, from_dot: bool, has_sign: bool, token: *Token) {
    token.l0 = iterator.line;
    token.file = iterator.file;
    token.c0 = iterator.column;
    token.kind = .NUMBER;

    kind: Number_Kind = .UNKNOWN;
    start := cursor;

    if has_sign {
        next(iterator); // skip the sign
    }

    if from_dot {
        kind = .FLOAT;
        next(iterator); // eat .
    }

    if !from_dot && peek(iterator) == #char "0" {
        next_char := peek(iterator, 2);
        if next_char == {
            case #char "x"; kind = .HEX_INT;
            case #char "h"; kind = .HEX_FLOAT;
            case #char "b"; kind = .BINARY;
        }

        if kind != .UNKNOWN {
            next(iterator); // eat 0
            next(iterator); // eat x, h or b
        }
    }

    if kind == .UNKNOWN {
        // NOTE: It could be int, float or scientific float. Now we assume int because float type will be decided after we parse the integer part.
        kind = .INT;
    }

    is_int_char :: inline (char: u8) -> bool {
        return (char >= #char "0" && char <= #char "9") || char == #char "_";
    }

    is_hex_char :: inline (char: u8) -> bool {
        return is_int_char(char) || (char >= #char "a" && char <= #char "f") || (char >= #char "A" && char <= #char "F");
    }

    is_binary_char :: inline (char: u8) -> bool {
        return char == #char "1" || char == #char "0" || char == #char "_";
    }

    skip_digits :: (iterator: *Iterator, $predicate: (char: u8) -> bool) #expand {
        digits_start := iterator.cursor;
        while iterator.cursor < iterator.end && predicate(iterator.cursor.*) iterator.cursor += 1;
        iterator.column += iterator.cursor - digits_start;
    }

    if kind == {
        case .INT;
            skip_digits(iterator, is_int_char);
        case .HEX_INT; #through;
        case .HEX_FLOAT;
            skip_digits(iterator, is_hex_char);
        case .BINARY;
            skip_digits(iterator, is_binary_char);
    }

    if from_dot || (peek(iterator, 1) == #char "." && peek(iterator, 2) != #char ".") {
        kind = .FLOAT;
        if !from_dot next(iterator); // eat '.' if it wasn't already eaten at the beginning

        skip_digits(iterator, is_int_char);

        if peek(iterator) == #char "e" {
            kind = .SCIENTIFIC_FLOAT;
            next(iterator);
            sign := peek(iterator);
            if sign == #char "+" || sign == #char "-" {
                next(iterator);
            }

            skip_digits(iterator, is_int_char);
        }
    }

    number_value := text_from(start, cursor);
    token.string_value = number_value;
    token.number_kind = kind;

    // The value without "_" separators, on the stack for normal literals.
    stack_buffer: [128]u8;
    without_underscores: string;
    without_underscores.data = ifx number_value.count <= stack_buffer.count then stack_buffer.data else cast(*u8) talloc(number_value.count);
    for 0..number_value.count-1 {
        char := number_value[it];
        if char == #char "_" continue;
        without_underscores.data[without_underscores.count] = char;
        without_underscores.count += 1;
    }

    if kind == .FLOAT || kind == .SCIENTIFIC_FLOAT {
        token.float_value = string_to_float(without_underscores);
    } else {
        base := 10;
        if kind == {
            case .HEX_FLOAT; #through;
            case .HEX_INT; base = 16;
            case .BINARY; base = 2;
        }

        if kind != .INT {
            advance(*without_underscores, 2); // Skip 0x, 0h or 0b
            sign_to_set := ifx kind == .HEX_FLOAT then #char "+" else number_value[0];
            // NOTE: If the number had a sing the skip above won't skip everything we need. For example -0xFF after the skip will become xFF. But because we know that there was a sign in the original string we can replace the 'x' with it so in the end we get: -FF.
            if has_sign {
                without_underscores[0] = sign_to_set;
            }
        }

        // NOTE: We're also parsing HEX_FLOAT here because string_to_float doesn't do that. Because the float is in hex format we can parse it in the same way as an integer and then just treat the bits as a float.
        token.integer_value = string_to_int(without_underscores, base);

        // NOTE: For HEX_FLOAT if it was negative we need to negate the number after parsing because if we pass a negated hex string into string_to_int it changes the bit layout.
        // For example -0xFF becomes 0xffffffffffffff01 which is correct for integers but not for our hack with hex floats. For hex floats we want the bits to be the same as the literal so we always parse it as a positive number and negate at the end.
        sign := number_value[0];
        if kind == .HEX_FLOAT && has_sign && sign == #char "-" {
            token.float_value *= -1;
        }
    }

    token.l1 = iterator.line;
    token.c1 = iterator.column;
}

parse_char_token :: (iterator: *Iterator, lexer: *Lexer, token: *Token) {
    token.l0 = iterator.line;
    token.file = iterator.file;
    token.c0 = iterator.column;

    char_start := iterator.cursor;
    char := next(iterator);
    next_char := peek(iterator);

    // Eats the next character when it is `expected`.
    eat :: (expected: u8) -> bool #expand {
        if peek(iterator) != expected return false;
        next(iterator);
        return true;
    }

    if char == {
        case #char "+";
            if eat(#char "=") token.kind = .PLUS_EQUAL;

        case #char "-";
            if next_char == #char ">" {
                next(iterator);
                token.kind = .ARROW_RIGHT; // ->
            } else if next_char == #char "=" {
                next(iterator);
                token.kind = .MINUS_EQUAL; // -=
            } else if next_char == #char "-" {
                next(iterator);
                token.kind = ifx eat(#char "-") then Token.Kind.TRIPLE_MINUS else .DOUBLE_MINUS; // --- or --
            }

        case #char "%";
            if eat(#char "=") token.kind = .MOD_EQUAL;

        case #char "/";
            if eat(#char "=") token.kind = .DIV_EQUAL;

        case #char "*";
            if eat(#char "=") token.kind = .TIMES_EQUAL;

        case #char "<";
            if next_char == #char "<" {
                next(iterator); // <
                if eat(#char "<") {
                    token.kind = ifx eat(#char "=") then Token.Kind.UNSIGNED_LEFT_SHIFT_ASSIGNMENT else .UNSIGNED_LEFT_SHIFT;
                } else {
                    token.kind = ifx eat(#char "=") then Token.Kind.LEFT_SHIFT_ASSIGNMENT else .LEFT_SHIFT;
                }
            } else if eat(#char "=") {
                token.kind = .LESS_EQUAL;
            }

        case #char ">";
            if next_char == #char ">" {
                next(iterator); // >
                if eat(#char ">") {
                    token.kind = ifx eat(#char "=") then Token.Kind.UNSIGNED_RIGHT_SHIFT_ASSIGNMENT else .UNSIGNED_RIGHT_SHIFT;
                } else {
                    token.kind = ifx eat(#char "=") then Token.Kind.RIGHT_SHIFT_ASSIGNMENT else .RIGHT_SHIFT;
                }
            } else if eat(#char "=") {
                token.kind = .GREATER_EQUAL;
            }

        case #char "&";
            if next_char == #char "=" {
                next(iterator);
                token.kind = .BITWISE_AND_ASSIGNMENT;
            } else if next_char == #char "&" {
                next(iterator);
                token.kind = ifx eat(#char "=") then Token.Kind.LOGICAL_AND_ASSIGNMENT else .LOGICAL_AND;
            }

        case #char "^";
            if eat(#char "=") token.kind = .BITWISE_XOR_ASSIGNMENT;

        case #char "|";
            if next_char == #char "=" {
                next(iterator);
                token.kind = .PIPE_EQUAL;
            } else if next_char == #char "|" {
                next(iterator);
                token.kind = ifx eat(#char "=") then Token.Kind.LOGICAL_OR_ASSIGNMENT else .LOGICAL_OR;
            }

        case #char "=";
            if next_char == #char ">" {
                next(iterator);
                token.kind = .QUICK_LAMBDA;
            } else if next_char == #char "=" {
                next(iterator);
                token.kind = .IS_EQUAL;
            }

        case #char "!";
            if eat(#char "=") token.kind = .IS_NOT_EQUAL;

        case #char "$";
            if eat(#char "$") token.kind = .DOUBLE_DOLLAR;

        case #char ".";
            if next_char == #char "." {
                next(iterator);
                token.kind = .DOUBLE_DOT;
            } else if next_char == #char "{" {
                next(iterator);
                token.kind = .BEGIN_STRUCT_LITERAL;
            } else if next_char == #char "[" {
                next(iterator);
                token.kind = .BEGIN_ARRAY_LITERAL;
            }

        case #char "(";
            // Prefix dereference operator: (.*)
            if next_char == #char "." && peek(iterator, 2) == #char "*" && peek(iterator, 3) == #char ")" {
                next(iterator); // eat '.'
                next(iterator); // eat '*'
                next(iterator); // eat ')'
                token.kind = .PREFIX_DEREFERENCE;
            }

        case #char ",";
            if eat(#char ",") token.kind = .DOUBLE_COMMA;

        case #char ":";
            // NOTE: For cases like test:   = 5;
            whitespace_found := skip_spaces(iterator);
            // NOTE: For cases like: test :/*comment*/: () {}
            comments_found := eat_comments(iterator, lexer);
            if comments_found || whitespace_found then next_char = peek(iterator);

            if next_char == #char "=" {
                next(iterator);
                token.kind = .DECLARATION_AND_ASSIGN;
            } else if next_char == #char ":" {
                next(iterator);
                token.kind = .CONSTANT_DECLARATION;
            }
    }

    if token.kind == .UNKNOWN {
        token.kind = xx char;
    }

    token.string_value = text_from(char_start, iterator.cursor);

    token.l1 = iterator.line;
    token.c1 = iterator.column;
}
