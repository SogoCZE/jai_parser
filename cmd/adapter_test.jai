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
}

assert_token :: (token: Parser.Token, kind: Parser.Token.Kind, value := "") {
	assert(token.kind == kind);
	if value {
		assert(token.string_value == value);
	}
}
