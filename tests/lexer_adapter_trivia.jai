#import "Basic";
#import "Pool";

Wrapper :: #import "../..";

assert_token_equal :: (actual: Wrapper.Token, expected: Wrapper.Token, compare_end := true) {
	assert(actual.kind == expected.kind);
	assert(actual.file == expected.file);
	assert(actual.l0 == expected.l0 && actual.c0 == expected.c0);
	if compare_end {
		assert(actual.l1 == expected.l1 && actual.c1 == expected.c1);
	}
	assert(actual.string_value == expected.string_value);
	assert(actual.number_kind == expected.number_kind);
	assert(actual.backticked == expected.backticked);

	if actual.kind == .NUMBER {
		assert(actual.integer_value == expected.integer_value);
	}
}

main :: () {
	sources := string.[
		"",
		" \t\r\n",
		"// tail",
		"/* tail */",
		"value := 42; // tail\n  ",
		"value: int; /* tail */ \r\n",
		"// lead\nvalue: int;\n// tail",
		"/* lead */ value: int; /* tail */"
	];

	final_comment_lines := int.[-1, -1, 0, 0, 0, 0, 2, 0];
	final_comment_starts := int.[-1, -1, 0, 0, 13, 12, 0, 23];
	final_comment_ends := int.[-1, -1, 7, 10, 20, 22, 7, 33];

	for source, source_index: sources {
		storage: Pool;
		set_allocators(*storage);
		defer release(*storage);

		test_context := context;
		test_context.allocator = .{proc = pool_allocator_proc, data = *storage};
		push_context test_context {
			expected := Wrapper.create_lexer(source, "trivia-regression.jai");

			actual := Wrapper.create_lexer_from_jai_parser(source, "trivia-regression.jai");

			assert(!expected.has_syntax_errors && !actual.has_syntax_errors);
			assert(actual.tokens.count == expected.tokens.count);
			assert(actual.comments.count == expected.comments.count);

			for token, index: actual.tokens {
				assert_token_equal(token, expected.tokens[index]);
			}

			for comment, index: actual.comments {
				assert_token_equal(comment.token, expected.comments[index].token, compare_end = false);
				assert(comment.multiline == expected.comments[index].multiline);
			}

			if final_comment_lines[source_index] >= 0 {
				comment := actual.comments[actual.comments.count - 1];
				assert(comment.l0 == final_comment_lines[source_index]);
				assert(comment.l1 == final_comment_lines[source_index]);
				assert(comment.c0 == final_comment_starts[source_index]);
				assert(comment.c1 == final_comment_ends[source_index]);
			}
		}
	}

	print("Lexer adapter trivia parity PASS: % inputs.\n", sources.count);
}
