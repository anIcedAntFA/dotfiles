// Command dot-wordcount counts the prose words in a Markdown or MDX document
// and estimates its reading time.
//
// Zed has no built-in word count, so this backs a Zed task (see docs/zed.md):
// with -zed it counts the editor selection when there is one, else the saved
// file. Zed passes both as environment variables, which are read here rather
// than spliced into a shell command line, so any selected text is safe.
//
// Usage:
//
//	dot-wordcount [-mdx] [FILE]   count FILE, or stdin when FILE is absent or "-"
//	dot-wordcount -zed            count $ZED_SELECTED_TEXT, else $ZED_FILE
package main

import (
	"errors"
	"flag"
	"fmt"
	"io"
	"os"
	"path/filepath"
	"strings"
)

func main() {
	if err := run(os.Args[1:], os.Getenv, os.Stdin, os.Stdout, os.Stderr); err != nil {
		fmt.Fprintln(os.Stderr, "dot-wordcount:", err)
		os.Exit(1)
	}
}

// input is the document to count and how to label it in the report.
type input struct {
	label string // what was counted, e.g. "post.md (selection)"
	path  string // the backing file, if any; its extension implies MDX
	src   []byte
}

func run(args []string, getenv func(string) string, stdin io.Reader, stdout, stderr io.Writer) error {
	fs := flag.NewFlagSet("dot-wordcount", flag.ContinueOnError)
	fs.SetOutput(stderr)
	zed := fs.Bool("zed", false, "count Zed's $ZED_SELECTED_TEXT, else $ZED_FILE (for a Zed task)")
	mdx := fs.Bool("mdx", false, "treat the input as MDX (implied by a .mdx file)")
	fs.Usage = func() {
		fmt.Fprintln(fs.Output(), "usage: dot-wordcount [-mdx] [FILE]\n       dot-wordcount -zed")
		fs.PrintDefaults()
	}
	if err := fs.Parse(args); err != nil {
		if errors.Is(err, flag.ErrHelp) {
			return nil
		}
		return err
	}

	var (
		in  input
		err error
	)
	switch {
	case *zed:
		if fs.NArg() > 0 {
			return errors.New("-zed takes no FILE argument")
		}
		in, err = zedInput(getenv)
	case fs.NArg() > 1:
		return errors.New("at most one FILE")
	case fs.NArg() == 0 || fs.Arg(0) == "-":
		in.label = "stdin"
		in.src, err = io.ReadAll(stdin)
	default:
		in.path = fs.Arg(0)
		in.label = filepath.Base(in.path)
		in.src, err = os.ReadFile(in.path)
	}
	if err != nil {
		return err
	}

	opts := Options{MDX: *mdx || strings.EqualFold(filepath.Ext(in.path), ".mdx")}
	_, err = fmt.Fprintln(stdout, report(in.label, Count(in.src, opts)))
	return err
}

// zedInput picks the Zed selection when it holds any text, else the file. Zed
// only sets ZED_SELECTED_TEXT while something is selected. The file is read
// from disk, so unsaved edits are not counted.
func zedInput(getenv func(string) string) (input, error) {
	path := getenv("ZED_FILE")
	if sel := getenv("ZED_SELECTED_TEXT"); strings.TrimSpace(sel) != "" {
		label := "selection"
		if path != "" {
			label = filepath.Base(path) + " (selection)"
		}
		return input{label: label, path: path, src: []byte(sel)}, nil
	}
	if path == "" {
		return input{}, errors.New("-zed: neither ZED_SELECTED_TEXT nor ZED_FILE is set (run it as a Zed task)")
	}
	src, err := os.ReadFile(path)
	if err != nil {
		return input{}, err
	}
	return input{label: filepath.Base(path), path: path, src: src}, nil
}

// report formats a count as "post.md: 1234 words · ~7 min read".
func report(label string, words int) string {
	if words == 0 {
		return label + ": 0 words"
	}
	unit := "words"
	if words == 1 {
		unit = "word"
	}
	return fmt.Sprintf("%s: %d %s · ~%d min read", label, words, unit, ReadingMinutes(words))
}
