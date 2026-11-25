package main

import "testing"

func TestCount(t *testing.T) {
	t.Parallel()

	tests := []struct {
		name string
		src  string
		mdx  bool
		want int
	}{
		{name: "empty", src: "", want: 0},
		{name: "plain prose", src: "Hello world", want: 2},
		{name: "vietnamese counts syllables", src: "Sinh viên học bài.", want: 4},
		{name: "soft line break separates words", src: "one\ntwo", want: 2},
		{name: "hard line break separates words", src: "line one\\\nline two", want: 4},
		{name: "emphasis inside a word stays one word", src: "**bold**er text", want: 2},
		{name: "heading marker dropped", src: "# Title here", want: 2},
		{name: "list markers dropped", src: "- one\n- two\n", want: 2},
		{name: "task list checkbox dropped", src: "- [x] done item", want: 2},
		{name: "blockquote marker dropped", src: "> quoted words", want: 2},
		{name: "strikethrough text kept", src: "~~old~~ new", want: 2},
		{name: "link keeps text, drops URL", src: "[read more](https://example.com/a)", want: 2},
		{name: "autolink dropped", src: "<https://example.com>", want: 0},
		{name: "bare URL dropped", src: "see https://example.com now", want: 2},
		{name: "image dropped with its alt text", src: "![a cat](cat.png) meow", want: 1},
		{name: "inline code kept", src: "run `go test` now", want: 4},
		{name: "fenced code dropped", src: "text\n\n```go\nfunc main() {}\n```\n", want: 1},
		{name: "indented code dropped", src: "text\n\n    code here\n", want: 1},
		{name: "table cells read without pipes", src: "| a b | c |\n|---|---|\n| d | e f |\n", want: 6},
		{name: "punctuation-only tokens ignored", src: "foo — bar", want: 2},
		{name: "html entity is not a word", src: "Tom &amp; Jerry", want: 2},
		{name: "footnote marker dropped, definition kept", src: "Claim[^1].\n\n[^1]: Source text.\n", want: 3},

		{name: "yaml front matter dropped", src: "---\ntitle: Hi there\ntags: [a, b]\n---\nBody text\n", want: 2},
		{name: "toml front matter dropped", src: "+++\ntitle = \"Hi\"\n+++\nBody text\n", want: 2},
		{name: "crlf front matter dropped", src: "---\r\ntitle: Hi\r\n---\r\nBody text\r\n", want: 2},
		{name: "unclosed front matter is a thematic break", src: "---\nfoo bar\n", want: 2},
		// Mid-document, the "---" pair is a thematic break plus a setext heading.
		{name: "front matter only at the start", src: "Intro\n\n---\nnot: front matter\n---\n", want: 4},

		{name: "inline html comment dropped", src: "a <!-- hidden note --> b", want: 2},
		{name: "html comment block dropped", src: "<!--\nhidden words\n-->\n\nshown", want: 1},
		{name: "html block keeps inner text", src: "<div>\ninside text\n</div>\n", want: 2},
		{name: "script block dropped whole", src: "<script>\nconst x = 1\n</script>\n\nafter", want: 1},
		{name: "inline html tags dropped", src: "press <kbd>Ctrl</kbd> now", want: 3},

		{name: "mdx: jsx block keeps inner text", src: "<Callout type=\"note\">\nCareful here\n</Callout>\n", mdx: true, want: 2},
		{name: "mdx: esm lines dropped", src: "import X from './x'\nexport const y = 1\n\nHello there\n", mdx: true, want: 2},
		{name: "mdx: esm only at top level", src: "> import this idea\n", mdx: true, want: 3},
		{name: "markdown keeps import-like prose", src: "import X from './x'\n\nHello there\n", want: 6},
	}

	for _, tt := range tests {
		t.Run(tt.name, func(t *testing.T) {
			t.Parallel()
			if got := Count([]byte(tt.src), Options{MDX: tt.mdx}); got != tt.want {
				t.Errorf("Count(%q) = %d, want %d\nprose: %q", tt.src, got, tt.want, Prose([]byte(tt.src), Options{MDX: tt.mdx}))
			}
		})
	}
}

func TestReadingMinutes(t *testing.T) {
	t.Parallel()

	tests := []struct {
		words, want int
	}{
		{0, 0},
		{1, 1},
		{WordsPerMinute, 1},
		{WordsPerMinute + 1, 2},
		{10 * WordsPerMinute, 10},
	}
	for _, tt := range tests {
		if got := ReadingMinutes(tt.words); got != tt.want {
			t.Errorf("ReadingMinutes(%d) = %d, want %d", tt.words, got, tt.want)
		}
	}
}
