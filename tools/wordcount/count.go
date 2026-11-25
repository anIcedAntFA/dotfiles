package main

import (
	"bytes"
	"regexp"
	"strings"
	"unicode"

	"github.com/yuin/goldmark"
	"github.com/yuin/goldmark/ast"
	"github.com/yuin/goldmark/extension"
	"github.com/yuin/goldmark/text"
)

// WordsPerMinute is the reading speed behind ReadingMinutes.
const WordsPerMinute = 200

// Options controls how a document is reduced to prose.
type Options struct {
	// MDX drops top-level ESM paragraphs (lines starting with import/export),
	// which MDX compiles as JavaScript rather than rendering as text.
	MDX bool
}

// markdown parses CommonMark plus the GFM extensions a blog post relies on:
// tables (so cell text is read without the pipes), strikethrough, task lists,
// linkify (so a bare URL becomes an AutoLink and is dropped) and footnotes.
var markdown = goldmark.New(goldmark.WithExtensions(extension.GFM, extension.Footnote))

var (
	htmlComment = regexp.MustCompile(`(?s)<!--.*?-->`)
	htmlTag     = regexp.MustCompile(`(?s)<[^>]*>`)
	htmlEntity  = regexp.MustCompile(`&(#[0-9]+|#[xX][0-9a-fA-F]+|[A-Za-z][A-Za-z0-9]*);`)
	esmLine     = regexp.MustCompile(`^(import|export)\b`)
)

// Count returns the number of prose words in a Markdown or MDX document.
func Count(src []byte, opts Options) int {
	n := 0
	for f := range strings.FieldsSeq(Prose(src, opts)) {
		if isWord(f) {
			n++
		}
	}
	return n
}

// ReadingMinutes estimates reading time at WordsPerMinute, rounded up so any
// non-empty text reads as at least one minute.
func ReadingMinutes(words int) int {
	return (words + WordsPerMinute - 1) / WordsPerMinute
}

// Prose returns the text a reader of the rendered document would read. It drops
// front matter, code blocks, images, URLs, HTML comments and tags (keeping the
// text between tags), and markup characters; inline code is kept because it is
// part of the sentence around it. Blocks are separated by newlines.
func Prose(src []byte, opts Options) string {
	src = stripFrontMatter(src)
	doc := markdown.Parser().Parse(text.NewReader(src))

	var b strings.Builder
	_ = ast.Walk(doc, func(n ast.Node, entering bool) (ast.WalkStatus, error) {
		if !entering {
			return ast.WalkContinue, nil
		}
		if n.Type() == ast.TypeBlock {
			b.WriteByte('\n')
		}
		switch n := n.(type) {
		case *ast.FencedCodeBlock, *ast.CodeBlock, *ast.Image, *ast.AutoLink, *ast.RawHTML:
			return ast.WalkSkipChildren, nil
		case *ast.HTMLBlock:
			b.WriteString(htmlBlockText(n, src))
			return ast.WalkSkipChildren, nil
		case *ast.Paragraph:
			if opts.MDX && isESM(n, src) {
				return ast.WalkSkipChildren, nil
			}
		case *ast.Text:
			b.Write(n.Segment.Value(src))
			if n.SoftLineBreak() || n.HardLineBreak() {
				b.WriteByte(' ')
			}
		case *ast.String:
			b.Write(n.Value)
		}
		return ast.WalkContinue, nil
	})
	return htmlEntity.ReplaceAllString(b.String(), " ")
}

// stripFrontMatter removes a leading YAML (---) or TOML (+++) front matter
// block. An opening fence with no matching close is left alone: it is then
// ordinary Markdown (a thematic break).
func stripFrontMatter(src []byte) []byte {
	first, rest, ok := bytes.Cut(src, []byte("\n"))
	if !ok {
		return src
	}
	fence := bytes.TrimRight(first, " \t\r")
	if !bytes.Equal(fence, []byte("---")) && !bytes.Equal(fence, []byte("+++")) {
		return src
	}
	for len(rest) > 0 {
		var line []byte
		line, rest, _ = bytes.Cut(rest, []byte("\n"))
		if bytes.Equal(bytes.TrimRight(line, " \t\r"), fence) {
			return rest
		}
	}
	return src
}

// htmlBlockText keeps the text between the tags of a raw HTML (or MDX JSX)
// block. Blocks whose content is not prose — <script>, <style>, <pre>,
// <textarea> — are dropped whole.
func htmlBlockText(n *ast.HTMLBlock, src []byte) string {
	if n.HTMLBlockType == ast.HTMLBlockType1 {
		return ""
	}
	var raw bytes.Buffer
	lines := n.Lines()
	for i := range lines.Len() {
		seg := lines.At(i)
		raw.Write(seg.Value(src))
	}
	if n.HasClosure() {
		raw.Write(n.ClosureLine.Value(src))
	}
	s := htmlComment.ReplaceAllString(raw.String(), " ")
	return htmlTag.ReplaceAllString(s, " ")
}

// isESM reports whether a paragraph is an MDX ESM block: top level, and its
// first line starts with import or export.
func isESM(n *ast.Paragraph, src []byte) bool {
	if n.Parent() == nil || n.Parent().Kind() != ast.KindDocument || n.Lines().Len() == 0 {
		return false
	}
	first := n.Lines().At(0)
	return esmLine.Match(first.Value(src))
}

// isWord reports whether a whitespace-separated token is a word rather than
// stray punctuation such as an em dash or a leftover "/>".
func isWord(token string) bool {
	return strings.IndexFunc(token, func(r rune) bool {
		return unicode.IsLetter(r) || unicode.IsNumber(r)
	}) >= 0
}
