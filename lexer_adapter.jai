Fast_Lexer :: #import "Jai_Parser"(ENABLE_TRIVIA=true, EVALUATE_STRING_ESCAPES=false);

Adapter_State :: struct {
	result: *Lexer;
	file: string;
	line: int;
	column: int;
}

create_lexer_from_jai_parser :: (source: string, file: string) -> Lexer {
	fast: Fast_Lexer.Lexer;
	Fast_Lexer.set_input_from_string(*fast, source);

	result: Lexer;
	state := Adapter_State.{result=*result, file=file};

	while true {
		fast_token := Fast_Lexer.peek_next_token(*fast);
		if fast_token.type == .END_OF_INPUT {
			consume_trivia(*state, fast_token.trailing_trivia);
			break;
		}


		if fast_token.type == #char "#" {
			next := Fast_Lexer.peek_token(*fast, 1);
			if next.type == .IDENT || is_fast_keyword(next.type) {
				consume_directive(*fast, *state);
				continue;
			}
		}


		if fast_token.type == #char ":" {
			next := Fast_Lexer.peek_token(*fast, 1);
			if next.preceding_trivia.count == 0
				&& (next.type == #char ":" || next.type == #char "=") {
				first := consume_fast_token(*fast, *state);
				second := consume_fast_token(*fast, *state);
				kind := ifx next.type == #char ":" then Token.Kind.CONSTANT_DECLARATION else .DECLARATION_AND_ASSIGN;
				append_combined_token(*state, first, second, kind);
				continue;
			}
		}


		fast_value := consume_fast_token(*fast, *state);
		if fast_value.type == .POSTFIX_DEREFERENCE {
			append_split_postfix_dereference(*state, fast_value);
			continue;
		}


		append_converted_token(*state, fast_value);
	}

	result.has_syntax_errors = result.has_syntax_errors || fast.reported_error;
	return result;
}

consume_directive :: (fast: *Fast_Lexer.Lexer, state: *Adapter_State) {
	consume_fast_token(fast, state);
	name := consume_fast_token(fast, state);

	directive := convert_fast_token(state.file, name);
	directive.kind = .DIRECTIVE;
	directive.string_value = cast(string) name.ident_value.name;
	append_adapter_token(state, directive);

	if directive.string_value != "string" {
		return;
	}


	want_cr := false;
	while Fast_Lexer.peek_next_token(fast).type == #char "," {
		comma := consume_fast_token(fast, state);
		append_converted_token(state, comma);

		modifier := consume_fast_token(fast, state);
		append_converted_token(state, modifier);
		if modifier.type == .IDENT && modifier.ident_value.name == "cr" {
			want_cr = true;
		}
	}

	delimiter := consume_fast_token(fast, state);
	assert(delimiter.type == .IDENT || is_fast_keyword(delimiter.type));
	append_converted_token(state, delimiter);

	body := Fast_Lexer.parse_here_string_body(fast, delimiter.ident_value.name, want_cr);
	if !body {
		state.result.has_syntax_errors = true;
		return;
	}


	consume_trivia(state, body.preceding_trivia);
	advance_adapter_position(state, body.original_text);
	append_adapter_token(state, convert_fast_token(state.file, body.*));

	terminator := consume_fast_token(fast, state);
	assert(terminator.type == .IDENT || is_fast_keyword(terminator.type));
	assert(terminator.ident_value.name == delimiter.ident_value.name);
}

consume_fast_token :: (fast: *Fast_Lexer.Lexer, state: *Adapter_State) -> Fast_Lexer.Token {
	token := Fast_Lexer.peek_next_token(fast);
	consume_trivia(state, token.preceding_trivia);
	advance_adapter_position(state, token.original_text);
	result := token.*;
	Fast_Lexer.eat_token(fast);
	return result;
}

consume_trivia :: (state: *Adapter_State, source: string) {
	iterator := Fast_Lexer.make_trivia_iterator(source);
	while true {
		success, trivia := Fast_Lexer.next_trivia(*iterator);
		if !success		break;


		if trivia.kind == .LINE_COMMENT || trivia.kind == .BLOCK_COMMENT {
			comment: Comment_Token;
			comment.file = state.file;
			comment.l0 = state.line;
			comment.c0 = state.column;
			comment.multiline = trivia.kind == .BLOCK_COMMENT;

			advance_adapter_position(state, trivia.text);
			comment.l1 = state.line;
			comment.c1 = state.column;

			if comment.multiline {
				body_count := Max(cast(s64) 0, trivia.text.count - 4);
				comment.string_value = slice(trivia.text, 2, body_count);
			} else {
				comment.string_value = slice(trivia.text, 2, trivia.text.count - 2);
			}

			array_add(*state.result.comments, comment);
		} else {
			advance_adapter_position(state, trivia.text);
		}
	}
}

advance_adapter_position :: (state: *Adapter_State, source: string) {
	for character: source {
		if character == #char "\n" {
			state.line += 1;
			state.column = 0;
		} else {
			state.column += 1;
		}
	}
}

append_adapter_token :: (state: *Adapter_State, token: Token) {
	array_add(*state.result.tokens, token);
	total_tokens += 1;
}

append_converted_token :: (state: *Adapter_State, token: Fast_Lexer.Token) {
	converted := convert_fast_token(state.file, token);
	if converted.kind != .UNKNOWN {
		append_adapter_token(state, converted);
	}
}

append_combined_token :: (
	state: *Adapter_State,
	first: Fast_Lexer.Token,
	second: Fast_Lexer.Token,
	kind: Token.Kind,
) {
	result := convert_fast_token(state.file, first);
	result.kind = kind;
	result.l1 = cast(int) second.l1 - 1;
	result.c1 = cast(int) second.c1 - 1;
	result.string_value.data = first.original_text.data;
	result.string_value.count = first.original_text.count + second.original_text.count;
	append_adapter_token(state, result);
}

append_split_postfix_dereference :: (state: *Adapter_State, source: Fast_Lexer.Token) {
	dot := convert_fast_token(state.file, source);
	dot.kind = #char ".";
	dot.l1 = dot.l0;
	dot.c1 = dot.c0 + 1;
	dot.string_value = slice(source.original_text, 0, 1);
	append_adapter_token(state, dot);

	star := dot;
	star.kind = #char "*";
	star.c0 += 1;
	star.c1 += 1;
	star.string_value = slice(source.original_text, 1, 1);
	append_adapter_token(state, star);
}

convert_fast_token :: (file: string, source: Fast_Lexer.Token) -> Token {
	result: Token;
	result.file = file;
	result.l0 = cast(int) source.l0 - 1;
	result.c0 = cast(int) source.c0 - 1;
	result.l1 = cast(int) source.l1 - 1;
	result.c1 = cast(int) source.c1 - 1;
	result.backticked = source.ident_is_backticked;
	result.string_value = source.original_text;

	if cast(s16) source.type < 256 {
		result.kind = cast(Token.Kind) cast(s16) source.type;
		return result;
	}


	result.kind = map_fast_token_kind(source.type);
	if source.type == .IDENT || is_unmapped_keyword(source.type) {
		result.kind = .IDENTIFIER;
		result.string_value = cast(string) source.ident_value.name;
	} else if is_fast_keyword(source.type) {
		result.string_value = cast(string) source.ident_value.name;
	} else if source.type == .NUMBER {
		result.string_value = source.original_text;
		result.number_kind = number_kind_from_fast_token(source);
		if source.value_flags & .FLOAT {
			result.float_value = source.float64_value;
		} else {
			result.integer_value = cast(int) source.integer_value;
		}
	} else if source.type == .STRING {
		result.string_value = source.string_value;
	} else if source.type == .NOTE {
		if source.original_text.count >= 3
			&& source.original_text[0] == #char "@"
			&& source.original_text[1] == #char "\"" {
			result.string_value = slice(source.original_text, 1, source.original_text.count - 1);
		} else {
			result.string_value = cast(string) source.ident_value.name;
		}
	}

	return result;
}

number_kind_from_fast_token :: (source: Fast_Lexer.Token) -> Number_Kind {
	if source.value_flags & .FLOAT {
		if source.value_flags & .HEX	return .HEX_FLOAT;
		for character: source.original_text {
			if character == #char "e" || character == #char "E"	return .SCIENTIFIC_FLOAT;
		}
		return .FLOAT;
	}


	if source.value_flags & .BINARY		return .BINARY;
	if source.value_flags & .HEX		return .HEX_INT;
	return .INT;
}

is_unmapped_keyword :: (type: Fast_Lexer.Token_Type) -> bool {
	return type == .KEYWORD_SIZE_OF
		|| type == .KEYWORD_TYPE_OF
		|| type == .KEYWORD_CODE_OF
		|| type == .KEYWORD_INITIALIZER_OF
		|| type == .KEYWORD_TYPE_INFO
		|| type == .KEYWORD_CONTEXT
		|| type == .KEYWORD_IS_CONSTANT;
}

is_fast_keyword :: inline (type: Fast_Lexer.Token_Type) -> bool {
	return type >= .__FIRST_KEYWORD && type <= .__LAST_KEYWORD;
}

FAST_TOKEN_KIND_FIRST :: Fast_Lexer.Token_Type.IDENT;
FAST_TOKEN_KIND_LAST :: Fast_Lexer.Token_Type.NOTE;
FAST_TOKEN_KIND_COUNT: int: xx (FAST_TOKEN_KIND_LAST - FAST_TOKEN_KIND_FIRST + 1);

FAST_TOKEN_KIND_LOOKUP :: #run () -> [FAST_TOKEN_KIND_COUNT] Token.Kind {
	result: [FAST_TOKEN_KIND_COUNT] Token.Kind;
	result[Fast_Lexer.Token_Type.IDENT - FAST_TOKEN_KIND_FIRST] = .IDENTIFIER;
	result[Fast_Lexer.Token_Type.NUMBER - FAST_TOKEN_KIND_FIRST] = .NUMBER;
	result[Fast_Lexer.Token_Type.STRING - FAST_TOKEN_KIND_FIRST] = .STRING;
	result[Fast_Lexer.Token_Type.PLUSEQUALS - FAST_TOKEN_KIND_FIRST] = .PLUS_EQUAL;
	result[Fast_Lexer.Token_Type.MINUSEQUALS - FAST_TOKEN_KIND_FIRST] = .MINUS_EQUAL;
	result[Fast_Lexer.Token_Type.TIMESEQUALS - FAST_TOKEN_KIND_FIRST] = .TIMES_EQUAL;
	result[Fast_Lexer.Token_Type.DIVEQUALS - FAST_TOKEN_KIND_FIRST] = .DIV_EQUAL;
	result[Fast_Lexer.Token_Type.MODEQUALS - FAST_TOKEN_KIND_FIRST] = .MOD_EQUAL;
	result[Fast_Lexer.Token_Type.ISEQUAL - FAST_TOKEN_KIND_FIRST] = .IS_EQUAL;
	result[Fast_Lexer.Token_Type.ISNOTEQUAL - FAST_TOKEN_KIND_FIRST] = .IS_NOT_EQUAL;
	result[Fast_Lexer.Token_Type.LOGICAL_AND - FAST_TOKEN_KIND_FIRST] = .LOGICAL_AND;
	result[Fast_Lexer.Token_Type.LOGICAL_OR - FAST_TOKEN_KIND_FIRST] = .LOGICAL_OR;
	result[Fast_Lexer.Token_Type.LESSEQUALS - FAST_TOKEN_KIND_FIRST] = .LESS_EQUAL;
	result[Fast_Lexer.Token_Type.GREATEREQUALS - FAST_TOKEN_KIND_FIRST] = .GREATER_EQUAL;
	result[Fast_Lexer.Token_Type.RIGHT_ARROW - FAST_TOKEN_KIND_FIRST] = .ARROW_RIGHT;
	result[Fast_Lexer.Token_Type.DOUBLE_DOT - FAST_TOKEN_KIND_FIRST] = .DOUBLE_DOT;
	result[Fast_Lexer.Token_Type.DOUBLE_DOLLAR - FAST_TOKEN_KIND_FIRST] = .DOUBLE_DOLLAR;
	result[Fast_Lexer.Token_Type.SHIFT_LEFT - FAST_TOKEN_KIND_FIRST] = .LEFT_SHIFT;
	result[Fast_Lexer.Token_Type.SHIFT_RIGHT - FAST_TOKEN_KIND_FIRST] = .RIGHT_SHIFT;
	result[Fast_Lexer.Token_Type.ROTATE_LEFT - FAST_TOKEN_KIND_FIRST] = .UNSIGNED_LEFT_SHIFT;
	result[Fast_Lexer.Token_Type.ROTATE_RIGHT - FAST_TOKEN_KIND_FIRST] = .UNSIGNED_RIGHT_SHIFT;
	result[Fast_Lexer.Token_Type.SHIFT_LEFT_EQUALS - FAST_TOKEN_KIND_FIRST] = .LEFT_SHIFT_ASSIGNMENT;
	result[Fast_Lexer.Token_Type.SHIFT_RIGHT_EQUALS - FAST_TOKEN_KIND_FIRST] = .RIGHT_SHIFT_ASSIGNMENT;
	result[Fast_Lexer.Token_Type.ROTATE_LEFT_EQUALS - FAST_TOKEN_KIND_FIRST] = .UNSIGNED_LEFT_SHIFT_ASSIGNMENT;
	result[Fast_Lexer.Token_Type.ROTATE_RIGHT_EQUALS - FAST_TOKEN_KIND_FIRST] = .UNSIGNED_RIGHT_SHIFT_ASSIGNMENT;
	result[Fast_Lexer.Token_Type.BITWISE_AND_EQUALS - FAST_TOKEN_KIND_FIRST] = .BITWISE_AND_ASSIGNMENT;
	result[Fast_Lexer.Token_Type.BITWISE_OR_EQUALS - FAST_TOKEN_KIND_FIRST] = .PIPE_EQUAL;
	result[Fast_Lexer.Token_Type.BITWISE_XOR_EQUALS - FAST_TOKEN_KIND_FIRST] = .BITWISE_XOR_ASSIGNMENT;
	result[Fast_Lexer.Token_Type.LOGICAL_AND_EQUALS - FAST_TOKEN_KIND_FIRST] = .LOGICAL_AND_ASSIGNMENT;
	result[Fast_Lexer.Token_Type.LOGICAL_OR_EQUALS - FAST_TOKEN_KIND_FIRST] = .LOGICAL_OR_ASSIGNMENT;
	result[Fast_Lexer.Token_Type.PREFIX_DEREFERENCE - FAST_TOKEN_KIND_FIRST] = .PREFIX_DEREFERENCE;
	result[Fast_Lexer.Token_Type.ISEQUAL_FOR_SWITCH_STATEMENT - FAST_TOKEN_KIND_FIRST] = .IS_EQUAL;
	result[Fast_Lexer.Token_Type.DOUBLE_MINUS - FAST_TOKEN_KIND_FIRST] = .DOUBLE_MINUS;
	result[Fast_Lexer.Token_Type.TRIPLE_MINUS - FAST_TOKEN_KIND_FIRST] = .TRIPLE_MINUS;
	result[Fast_Lexer.Token_Type.DOUBLE_COMMA - FAST_TOKEN_KIND_FIRST] = .DOUBLE_COMMA;
	result[Fast_Lexer.Token_Type.BEGIN_STRUCT_LITERAL - FAST_TOKEN_KIND_FIRST] = .BEGIN_STRUCT_LITERAL;
	result[Fast_Lexer.Token_Type.BEGIN_ARRAY_LITERAL - FAST_TOKEN_KIND_FIRST] = .BEGIN_ARRAY_LITERAL;
	result[Fast_Lexer.Token_Type.KEYWORD_FOR - FAST_TOKEN_KIND_FIRST] = .KEYWORD_FOR;
	result[Fast_Lexer.Token_Type.KEYWORD_IF - FAST_TOKEN_KIND_FIRST] = .KEYWORD_IF;
	result[Fast_Lexer.Token_Type.KEYWORD_IFX - FAST_TOKEN_KIND_FIRST] = .KEYWORD_IFX;
	result[Fast_Lexer.Token_Type.KEYWORD_THEN - FAST_TOKEN_KIND_FIRST] = .KEYWORD_THEN;
	result[Fast_Lexer.Token_Type.KEYWORD_ELSE - FAST_TOKEN_KIND_FIRST] = .KEYWORD_ELSE;
	result[Fast_Lexer.Token_Type.KEYWORD_CASE - FAST_TOKEN_KIND_FIRST] = .KEYWORD_CASE;
	result[Fast_Lexer.Token_Type.KEYWORD_RETURN - FAST_TOKEN_KIND_FIRST] = .KEYWORD_RETURN;
	result[Fast_Lexer.Token_Type.KEYWORD_STRUCT - FAST_TOKEN_KIND_FIRST] = .KEYWORD_STRUCT;
	result[Fast_Lexer.Token_Type.KEYWORD_WHILE - FAST_TOKEN_KIND_FIRST] = .KEYWORD_WHILE;
	result[Fast_Lexer.Token_Type.KEYWORD_BREAK - FAST_TOKEN_KIND_FIRST] = .KEYWORD_BREAK;
	result[Fast_Lexer.Token_Type.KEYWORD_CONTINUE - FAST_TOKEN_KIND_FIRST] = .KEYWORD_CONTINUE;
	result[Fast_Lexer.Token_Type.KEYWORD_REMOVE - FAST_TOKEN_KIND_FIRST] = .KEYWORD_REMOVE;
	result[Fast_Lexer.Token_Type.KEYWORD_USING - FAST_TOKEN_KIND_FIRST] = .KEYWORD_USING;
	result[Fast_Lexer.Token_Type.KEYWORD_DEFER - FAST_TOKEN_KIND_FIRST] = .KEYWORD_DEFER;
	result[Fast_Lexer.Token_Type.KEYWORD_NULL - FAST_TOKEN_KIND_FIRST] = .NULL;
	result[Fast_Lexer.Token_Type.KEYWORD_ENUM - FAST_TOKEN_KIND_FIRST] = .KEYWORD_ENUM;
	result[Fast_Lexer.Token_Type.KEYWORD_TRUE - FAST_TOKEN_KIND_FIRST] = .KEYWORD_TRUE;
	result[Fast_Lexer.Token_Type.KEYWORD_FALSE - FAST_TOKEN_KIND_FIRST] = .KEYWORD_FALSE;
	result[Fast_Lexer.Token_Type.KEYWORD_INLINE - FAST_TOKEN_KIND_FIRST] = .KEYWORD_INLINE;
	result[Fast_Lexer.Token_Type.KEYWORD_NO_INLINE - FAST_TOKEN_KIND_FIRST] = .KEYWORD_NO_INLINE;
	result[Fast_Lexer.Token_Type.KEYWORD_CAST - FAST_TOKEN_KIND_FIRST] = .KEYWORD_CAST;
	result[Fast_Lexer.Token_Type.KEYWORD_AUTO_CAST - FAST_TOKEN_KIND_FIRST] = .KEYWORD_AUTO_CAST;
	result[Fast_Lexer.Token_Type.KEYWORD_PUSH_CONTEXT - FAST_TOKEN_KIND_FIRST] = .KEYWORD_PUSH_CONTEXT;
	result[Fast_Lexer.Token_Type.KEYWORD_OPERATOR - FAST_TOKEN_KIND_FIRST] = .KEYWORD_OPERATOR;
	result[Fast_Lexer.Token_Type.KEYWORD_ENUM_FLAGS - FAST_TOKEN_KIND_FIRST] = .KEYWORD_ENUM_FLAGS;
	result[Fast_Lexer.Token_Type.KEYWORD_UNION - FAST_TOKEN_KIND_FIRST] = .KEYWORD_UNION;
	result[Fast_Lexer.Token_Type.KEYWORD_INTERFACE - FAST_TOKEN_KIND_FIRST] = .KEYWORD_INTERFACE;
	result[Fast_Lexer.Token_Type.QUICK_LAMBDA - FAST_TOKEN_KIND_FIRST] = .QUICK_LAMBDA;
	result[Fast_Lexer.Token_Type.NOTE - FAST_TOKEN_KIND_FIRST] = .NOTE;
	return result;
}();

map_fast_token_kind :: inline (type: Fast_Lexer.Token_Type) -> Token.Kind {
	index: int = xx (type - FAST_TOKEN_KIND_FIRST);
	return ifx index < 0 || index >= FAST_TOKEN_KIND_COUNT
		then .UNKNOWN
		else FAST_TOKEN_KIND_LOOKUP[index];
}
