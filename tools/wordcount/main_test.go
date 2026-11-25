package main

import (
	"bytes"
	"os"
	"path/filepath"
	"strings"
	"testing"
)

// env returns a getenv func backed by a map, standing in for os.Getenv.
func env(vars map[string]string) func(string) string {
	return func(key string) string { return vars[key] }
}

// writeFile writes content to name inside a fresh temp dir and returns its path.
func writeFile(t *testing.T, name, content string) string {
	t.Helper()
	path := filepath.Join(t.TempDir(), name)
	if err := os.WriteFile(path, []byte(content), 0o600); err != nil {
		t.Fatal(err)
	}
	return path
}

func TestRun(t *testing.T) {
	t.Parallel()

	md := writeFile(t, "post.md", "---\ntitle: Post\n---\nOne two three\n")
	mdx := writeFile(t, "post.mdx", "import X from './x'\n\nOne two\n")

	tests := []struct {
		name    string
		args    []string
		env     map[string]string
		stdin   string
		want    string
		wantErr string
	}{
		{name: "file", args: []string{md}, want: "post.md: 3 words · ~1 min read\n"},
		{name: "mdx implied by extension", args: []string{mdx}, want: "post.mdx: 2 words · ~1 min read\n"},
		{name: "stdin", stdin: "just one", want: "stdin: 2 words · ~1 min read\n"},
		{name: "stdin dash", args: []string{"-"}, stdin: "word", want: "stdin: 1 word · ~1 min read\n"},
		{name: "mdx flag on stdin", args: []string{"-mdx"}, stdin: "export const a = 1\n\nHi", want: "stdin: 1 word · ~1 min read\n"},
		{name: "empty input", stdin: "```\ncode only\n```\n", want: "stdin: 0 words\n"},
		{
			name: "zed: selection wins over file",
			args: []string{"-zed"},
			env:  map[string]string{"ZED_FILE": md, "ZED_SELECTED_TEXT": "picked words"},
			want: "post.md (selection): 2 words · ~1 min read\n",
		},
		{
			name: "zed: selection with shell metacharacters",
			args: []string{"-zed"},
			env:  map[string]string{"ZED_SELECTED_TEXT": `say "hi" $(rm -rf /) ` + "`x`"},
			want: "selection: 5 words · ~1 min read\n",
		},
		{
			name: "zed: selection in mdx file is mdx",
			args: []string{"-zed"},
			env:  map[string]string{"ZED_FILE": mdx, "ZED_SELECTED_TEXT": "export const a = 1\n\nHi"},
			want: "post.mdx (selection): 1 word · ~1 min read\n",
		},
		{
			name: "zed: blank selection falls back to file",
			args: []string{"-zed"},
			env:  map[string]string{"ZED_FILE": md, "ZED_SELECTED_TEXT": " \n"},
			want: "post.md: 3 words · ~1 min read\n",
		},
		{name: "zed: nothing set", args: []string{"-zed"}, wantErr: "neither ZED_SELECTED_TEXT nor ZED_FILE"},
		{name: "zed: rejects FILE", args: []string{"-zed", md}, wantErr: "takes no FILE"},
		{name: "too many files", args: []string{md, mdx}, wantErr: "at most one FILE"},
		{name: "missing file", args: []string{filepath.Join(t.TempDir(), "nope.md")}, wantErr: "no such file"},
		{name: "unknown flag", args: []string{"-nope"}, wantErr: "flag provided but not defined"},
		{name: "help is not an error", args: []string{"-h"}},
	}

	for _, tt := range tests {
		t.Run(tt.name, func(t *testing.T) {
			t.Parallel()
			var stdout, stderr bytes.Buffer
			err := run(tt.args, env(tt.env), strings.NewReader(tt.stdin), &stdout, &stderr)

			if tt.wantErr != "" {
				if err == nil || !strings.Contains(err.Error(), tt.wantErr) {
					t.Fatalf("run(%q) error = %v, want it to contain %q", tt.args, err, tt.wantErr)
				}
				return
			}
			if err != nil {
				t.Fatalf("run(%q) unexpected error: %v", tt.args, err)
			}
			if got := stdout.String(); got != tt.want {
				t.Errorf("run(%q) stdout = %q, want %q", tt.args, got, tt.want)
			}
		})
	}
}
