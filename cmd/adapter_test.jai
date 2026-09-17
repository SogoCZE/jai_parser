#import "Basic";

Parser :: #import,dir "..";

main :: () {
	source :: "value :: #string /**/ , /**/ cr /**/ , /**/ \\% END\n123\n  END;";
	lexer := Parser.create_lexer_from_jai_parser(source, "adapter_test.jai");

	assert(lexer.tokens.count == 10);
	assert_token(lexer.tokens[0], .IDENTIFIER, "value");
	assert_token(lexer.tokens[1], .CONSTANT_DECLARATION);
	assert_token(lexer.tokens[2], .DIRECTIVE, "string");
	assert_token(lexer.tokens[3], #char ",");
	assert_token(lexer.tokens[4], .IDENTIFIER, "cr");
	assert_token(lexer.tokens[5], #char ",");
	assert_token(lexer.tokens[6], .IDENTIFIER, "\\%");
	assert_token(lexer.tokens[7], .IDENTIFIER, "END");
	assert_token(lexer.tokens[8], .STRING, "123\r\n");
	assert_token(lexer.tokens[9], #char ";");

	for token: lexer.tokens {
		assert(token.file == "adapter_test.jai");
	}

	assert(lexer.comments.count == 4);
	for comment: lexer.comments {
		assert(comment.multiline);
		assert(comment.string_value == "");
		assert(comment.file == "adapter_test.jai");
	}

	keyword_source :: "#string if\nvalue\nif";
	keyword_lexer := Parser.create_lexer_from_jai_parser(keyword_source, "keyword_delimiter.jai");
	assert(keyword_lexer.tokens.count == 3);
	assert_token(keyword_lexer.tokens[0], .DIRECTIVE, "string");
	assert_token(keyword_lexer.tokens[1], .KEYWORD_IF, "if");
	assert_token(keyword_lexer.tokens[2], .STRING, "value\n");
	assert(!keyword_lexer.has_syntax_errors);

	malformed_source :: "#string END\nunterminated\n";
	malformed_lexer := Parser.create_lexer_from_jai_parser(malformed_source, "malformed_here_string.jai");
	assert(malformed_lexer.has_syntax_errors);

	directive_source :: "#ifx true then false";
	directive_lexer := Parser.create_lexer_from_jai_parser(directive_source, "keyword_directive.jai");
	assert(directive_lexer.tokens.count == 4);
	assert_token(directive_lexer.tokens[0], .DIRECTIVE, "ifx");
	assert_token(directive_lexer.tokens[1], .KEYWORD_TRUE, "true");
	assert_token(directive_lexer.tokens[2], .KEYWORD_THEN, "then");
	assert_token(directive_lexer.tokens[3], .KEYWORD_FALSE, "false");

	string_source :: "\"line\\n\\x41\" @\"note\\n\"";
	string_lexer := Parser.create_lexer_from_jai_parser(string_source, "raw_strings.jai");
	assert(string_lexer.tokens.count == 2);
	assert_token(string_lexer.tokens[0], .STRING, "line\\n\\x41");
	assert_token(string_lexer.tokens[1], .NOTE, "\"note\\n\"");

	asm_source :: "#asm { mov.q value:, 1; }";
	asm_lexer := Parser.create_lexer_from_jai_parser(asm_source, "inline_asm.jai");
	open_brace: *Parser.Token;
	close_brace: *Parser.Token;
	for *token: asm_lexer.tokens {
		if token.kind == #char "{" && !open_brace	open_brace = token;
		if token.kind == #char "}"	close_brace = token;
	}
	assert(open_brace && close_brace);
	assert(open_brace.string_value == "{");
	assert(close_brace.string_value == "}");
	asm_body: string;
	asm_body.data = open_brace.string_value.data;
	asm_body.count = close_brace.string_value.data - open_brace.string_value.data + 1;
	assert(asm_body == "{ mov.q value:, 1; }");

	assert(Parser.create_lexer("\"unterminated", "unterminated_string.jai").has_syntax_errors);
	assert(Parser.create_lexer("\"line one\nline two\"", "multiline_string.jai").has_syntax_errors);
	assert(Parser.create_lexer("#string", "missing_here_delimiter.jai").has_syntax_errors);
	assert(Parser.create_lexer("#string END\nunterminated", "unterminated_eager_here_string.jai").has_syntax_errors);
}

assert_token :: (token: Parser.Token, kind: Parser.Token.Kind, value := "") {
	assert(token.kind == kind);
	if value {
		assert(token.string_value == value);
	}
}
