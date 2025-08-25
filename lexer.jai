// @TODO: remove this
total_tokens: int;

Token :: struct {

    Kind :: enum {
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
        // KEYWORD_IMPORT;
        // KEYWORD_LOAD;
        // KEYWORD_IS_CONSTANT;
        // KEYWORD_CONTEXT;
        // KEYWORD_ADD_CONTEXT;

        UNKNOWN;
    }

    kind: Kind = .UNKNOWN;

    file: string;

    l0: int;
    c0: int;
    l1: int;
    c1: int;

    // NOTE: string_value is separated from int and float value because for numbers we want to keep both representations - string represantation of a number is usefull for example in formatting to not remove underscores from literals.
    string_value: string;
    number_kind: Number_Kind;
    union {
        integer_value: int;
        float_value: float64;
    }

    backticked: bool;
}

Number_Kind :: enum {
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
}

create_lexer :: (source: string, file: string) -> Lexer {
    iterator: Iterator;
    iterator.file = file;
    iterator.buffer = source;

    lexer: Lexer;

    while !end(*iterator) {
        token := parse_next_token(*iterator, *lexer);
        if token.kind == .UNKNOWN continue;

        if lexer.next_backticked {
            lexer.next_backticked = false;
            token.backticked = true;
        }

        array_add(*lexer.tokens, token);
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

eat_token :: (using lexer: *Lexer) -> *Token {
    if end(lexer) return null;
    cursor += 1;
    return *tokens[cursor-1];
}

eat_token :: (lexer: *Lexer, kind: Token.Kind) -> *Token {
    token := eat_token(lexer);
    if !token {
        log_error("Null token!"); // @TODO: add caller_location or something?
        return *(Token.{});
    }

    if token.kind != kind {
        log_error("token '%' != required '%' (%:%:%)", token_kind_to_string(token.kind), token_kind_to_string(kind), token.file, token.l0, token.c0); // @TODO: is this ok?
    }

    return token;
}

eat_all_upcoming_comments :: inline (lexer: *Lexer) {
    while is_token(lexer, .COMMENT) eat_token(lexer);
}

is_token :: (lexer: *Lexer, kind: Token.Kind, $peek := 0) -> bool {
    token := peek_token(lexer, peek);
    if !token || token.kind != kind return false;
    return true;
}

is_token :: (lexer: *Lexer, predicate: (token: *Token) -> bool, $peek := 0) -> bool {
    token := peek_token(lexer, peek);
    if !token || !predicate(token) return false;
    return true;
}

end :: (using lexer: *Lexer) -> bool {
    return cursor + 1 > tokens.count;
}

peek_token :: (using lexer: *Lexer, $count := 0) -> *Token {
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

maybe_eat_token :: (lexer: *Lexer, kind: Token.Kind) -> bool, *Token {
    token := peek_token(lexer);
    if !token || token.kind != kind return false, null;
    return true, eat_token(lexer);
}

#scope_module

Iterator :: struct {
    line := 0;
    column := 0;
    buffer: string;
    file: string;
}

next :: (using iterator: *Iterator) -> u8 {
    if buffer.count == 0 return 0;
    // assert(buffer.count != 0);

    char := buffer[0];
    advance(*buffer);

    if char == #char "\n" {
        line += 1;
        column = 0;
    } else {
        column += 1;
    }

    return char;
}

peek :: (using iterator: *Iterator, to := 1) -> u8 {
    if buffer.count <= to-1 return 0;
    // assert(buffer.count > to-1);
    return buffer[to-1];
}

end :: (using iterator: *Iterator) -> bool {
    return buffer.count == 0;
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

eat_comments :: (iterator: *Iterator, lexer: *Lexer) -> bool {
    comments_found: bool;
    while is_comment(iterator) {
        comment := parse_comment(iterator);
        array_add(*lexer.comments, comment);
        comments_found = true;
        next_while(iterator, is_space); // We skip all whitespaces
    }

    return comments_found;
}

parse_next_token :: (iterator: *Iterator, lexer: *Lexer) -> Token {
    next_while(iterator, is_space); // We skip all whitespaces

    // @TODO: remove this
    total_tokens += 1;

    // Skip comments - we don't want them in the parser. But we're keeping a separate list of comments if someone needs them (for example for formatting).
    eat_comments(iterator, lexer);

    char := peek(iterator);

    // Notes
    if char == #char "@" && (is_identifier_char(peek(iterator, 2)) || peek(iterator, 2) == #char "\"") {
        return parse_note_or_directive(iterator, false);
    }

    // Directives
    if char == #char "#" && is_identifier_char(peek(iterator, 2)) {
        directive_token := parse_note_or_directive(iterator, true);

        if directive_token.string_value == "string" {
            array_add(*lexer.tokens, directive_token);

            // NOTE: Here strings are processed in a bit hacky way. parse_here_string adds multiple tokens to the tokens list in lexer. That's why we return an empty token here.
            parse_here_string(iterator, lexer);
            return .{};
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

    has_sign: bool;
    previous_token := ifx lexer.tokens then lexer.tokens[lexer.tokens.count - 1] else .{};
    if (is_operator(*previous_token) || previous_token.kind == .DECLARATION_AND_ASSIGN) &&
       (char == #char "+" || char == #char "-") {
        has_sign = true;
        char = peek(iterator, 2);
    }

    // .40
    if char == #char "." && is_digit(peek(iterator, 2)) {
        return parse_number(iterator, true, has_sign);
    }

    // Numbers
    if is_digit(char) {
        return parse_number(iterator, false, has_sign);
    }

    // Backtick
    if char == #char "`" {
        next(iterator); // eat `
        lexer.next_backticked = true;
        return .{}; // empty token (skipped by lexer)
    }

    // Special chars or compound chars
    return parse_char_token(iterator, lexer);
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

    builder: String_Builder;

    nested_comment: int;

    while !end(iterator) {
        char := next(iterator);
        if !multiline && char == #char "\n" break;

        if multiline {

            if char == #char "/" && peek(iterator) == #char "*" {
                nested_comment += 1;
            }

            if char == #char "*" && peek(iterator) == #char "/" {
                if nested_comment == 0 {
                    next(iterator); // We remove end "/"
                    break;
                }

                nested_comment -= 1;
            }

        }

        append(*builder, char);
    }


    token.string_value = builder_to_string(*builder);
    token.l1 = iterator.line;
    token.c1 = iterator.column;

    if ends_with(token.string_value, "\r") {
        token.string_value.count -= 1;
    }

    return token;
}

parse_note_or_directive :: (using iterator: *Iterator, directive: bool) -> Token {
    next(iterator); // Skip the "@"

    token: Token;
    token.file = iterator.file;
    token.l0 = iterator.line;
    token.c0 = iterator.column;

    token.kind = ifx directive then Token.Kind.DIRECTIVE else .NOTE;
    if directive {
        token.string_value = next_while(iterator, char => is_identifier_char(char) || is_digit(char));
    } else {
        char := peek(iterator);
        if char == #char "\"" {
            builder: String_Builder;
            string_token := parse_string(iterator);
            print(*builder, "\"%\"", string_token.string_value);
            token.string_value = builder_to_string(*builder);
        } else {
            token.string_value = next_while(iterator, char => !is_space(char));
        }
    }

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

    for token_kind: enum_names(Token.Kind) {
        if !starts_with(token_kind, "KEYWORD") continue;

        KEYWORD_COUNT :: #run "KEYWORD_".count;

        token_kind_lower_without_prefix := token_kind;
        token_kind_lower_without_prefix = slice(token_kind_lower_without_prefix, KEYWORD_COUNT, token_kind.count-KEYWORD_COUNT);
        token_kind_lower_without_prefix = to_lower_copy(token_kind_lower_without_prefix); // @TODO: Do we need to free something?

        if identifier == "xx" {
            keyword = "KEYWORD_AUTO_CAST";
            break;
        }

        if identifier == token_kind_lower_without_prefix {
            keyword = token_kind;
            break;
        }
    }

    if keyword {
        enum_value, ok := enum_name_to_value(Token.Kind, keyword);
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
            append(*builder, "\\");
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
parse_here_string :: (using iterator: *Iterator, lexer: *Lexer) {

    // #string,cr or #string,\%
    while peek(iterator) == #char "," {
        comma_token := parse_char_token(iterator, lexer);
        array_add(*lexer.tokens, comma_token);

        if is_identifier_char(peek(iterator)) {
            identifier := parse_identifier(iterator);
            print("parsing here string: %\n", identifier.string_value);
            array_add(*lexer.tokens, identifier);
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

    next_while(iterator, is_space); // Skip all whitespaces

    if !is_identifier_char(peek(iterator)) {
        log_error("Exprected identifier after #string");
        return;
    }

    here_identifier_token := parse_identifier(iterator);
    array_add(*lexer.tokens, here_identifier_token);
    here_identifier := here_identifier_token.string_value;

    string_token: Token;
    string_token.kind = .STRING;
    string_token.file = iterator.file;
    string_token.l0 = iterator.line;
    string_token.c0 = iterator.column;

    builder: String_Builder;

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

    string_token.l1 = iterator.line;
    string_token.c1 = iterator.column;
    string_token.string_value = builder_to_string(*builder);

    array_add(*lexer.tokens, string_token);
}

parse_number :: (using iterator: *Iterator, from_dot: bool, has_sign: bool) -> Token {
    token: Token;
    token.l0 = iterator.line;
    token.file = iterator.file;
    token.c0 = iterator.column;
    token.kind = .NUMBER;

    kind: Number_Kind = .UNKNOWN;

    builder: String_Builder;

    if has_sign {
        append(*builder, next(iterator)); // skip the sign
    }

    if from_dot {
        kind = .FLOAT;
        append(*builder, next(iterator)); // eat .
    }

    if !from_dot && peek(iterator) == #char "0" {
        next_char := peek(iterator, 2);
        if next_char == {
            case #char "x"; kind = .HEX_INT;
            case #char "h"; kind = .HEX_FLOAT;
            case #char "b"; kind = .BINARY;
        }

        if kind != .UNKNOWN {
            append(*builder, next(iterator)); // eat 0
            append(*builder, next(iterator)); // eat x, h or b
        }
    }

    if kind == .UNKNOWN {
        // NOTE: It could be int, float or scientific float. Now we assume int because float type will be decided after we parse the integer part.
        kind = .INT;
    }

    is_hex_char :: (char: u8) -> bool {
        return (char >= #char "a" && char <= #char "f") ||
               (char >= #char "A" && char <= #char "F");
    }

    is_underscore :: (char: u8) -> bool { return char == #char "_"; }

    int_predicate :: (char) => is_digit(char) || is_underscore(char);
    hex_predicate :: (char) => is_digit(char) || is_hex_char(char) || is_underscore(char);
    binary_predicate :: (char) => char == #char "1" || char == #char "0" || is_underscore(char);

    value: string;
    if kind == {
        case .INT;
            value = next_while(iterator, int_predicate);
        case .HEX_INT; #through;
        case .HEX_FLOAT;
            value = next_while(iterator, hex_predicate);
        case .BINARY;
            value = next_while(iterator, binary_predicate);
    }

    append(*builder, value);

    if from_dot || (peek(iterator, 1) == #char "." && peek(iterator, 2) != #char ".") {
        kind = .FLOAT;
        if !from_dot append(*builder, next(iterator)); // eat '.' if it wasn'y already eaten at the beginning

        decimal_part := next_while(iterator, int_predicate);
        append(*builder, decimal_part);

        if peek(iterator) == #char "e" {
            kind = .SCIENTIFIC_FLOAT;
            append(*builder, next(iterator));
            sign := peek(iterator);
            if sign == #char "+" || sign == #char "-" {
                append(*builder, next(iterator));
            }

            exponent_part := next_while(iterator, int_predicate);
            append(*builder, exponent_part);
        }
    }

    number_value := builder_to_string(*builder);
    token.string_value = number_value;
    token.number_kind = kind;

    without_underscores := replace(number_value, "_", ""); // Remove all _ in number
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

    return token;
}

parse_char_token :: (iterator: *Iterator, lexer: *Lexer) -> Token {
    token: Token;
    token.l0 = iterator.line;
    token.file = iterator.file;
    token.c0 = iterator.column;

    char_start := iterator.buffer.data;
    char := next(iterator);
    next_char := peek(iterator);

    // other compound tokens follow the pattern of branching on the first char

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
        token.kind = .BITWISE_AND_ASSIGNMENT;
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

    if char == #char "^" && next_char == #char "=" {
        next(iterator);
        token.kind = .BITWISE_XOR_ASSIGNMENT;
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

    if char == #char "." {

        if next_char == #char "." {
            next(iterator);
            token.kind = .DOUBLE_DOT;
        }

        if next_char == #char "{" {
            next(iterator);
            token.kind = .BEGIN_STRUCT_LITERAL;
        }

        if next_char == #char "[" {
            next(iterator);
            token.kind = .BEGIN_ARRAY_LITERAL;
        }

    }

    if char == #char "(" {
        // Prefix dereference operator: (.*)
        if next_char == #char "." &&
           peek(iterator, 2) == #char "*" && peek(iterator, 3) == #char ")" {
            next(iterator); // eat '.'
            next(iterator); // eat '*'
            next(iterator); // eat ')'
            token.kind = .PREFIX_DEREFERENCE;
        }
    }

    if char == #char "," && next_char == #char "," {
        next(iterator);
        token.kind = .DOUBLE_COMMA;
    }

    if char == #char ":" {
        // NOTE: For cases like test:   = 5;
        whitespace := next_while(iterator, is_space);
        // NOTE: For cases like: test :/*comment*/: () {}
        comments_found := eat_comments(iterator, lexer);
        if comments_found || whitespace.count > 0 then next_char = peek(iterator);

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

    char_end := iterator.buffer.data;
    token.string_value.data = char_start;
    token.string_value.count = char_end - char_start;

    token.l1 = iterator.line;
    token.c1 = iterator.column;

    return token;
}
