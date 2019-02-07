#!/usr/bin/env bash
# **START**

export GOPATH=$HOME
export PATH=$GOPATH/bin:$PATH
echo "machine github.com login $GITHUB_USERNAME password $GITHUB_PAT" >> $HOME/.netrc
echo "" >> $HOME/.netrc
echo "machine api.github.com login $GITHUB_USERNAME password $GITHUB_PAT" >> $HOME/.netrc
git config --global user.email "$GITHUB_USERNAME@example.com"
git config --global user.name "$GITHUB_USERNAME"
git config --global advice.detachedHead false
git config --global push.default current

now=$(date +'%Y%m%d%H%M%S_%N')
githubcli repo renameIfExists $GITHUB_ORG/code-gen code-gen_$now
githubcli repo transfer $GITHUB_ORG/code-gen_$now $GITHUB_ORG_ARCHIVE
githubcli repo create $GITHUB_ORG/code-gen

mkdir -p $HOME/scratchpad/code-gen
cd $HOME/scratchpad/code-gen
git init -q
go mod init github.com/$GITHUB_ORG/code-gen
go get -m golang.org/x/tools@v0.0.0-20190125232054-d66bd3c5d5a6
go install golang.org/x/tools/cmd/stringer

mkdir stringer-example
cd stringer-example

cat <<EOD | gofmt > tools.go
// +build tools

package tools

import (
	_ "golang.org/x/tools/cmd/stringer"
)
EOD

cat <<EOD | gofmt > painkiller.go
// 1
package painkiller

type Pill int

const (
	Placebo Pill = iota
	Aspirin
	Ibuprofen
	Paracetamol
	Acetaminophen = Paracetamol
)
// 2
//go:generate stringer -type=Pill
// 3
EOD

go generate
go test

# block: painkiller
cat painkiller.go

# block: pill
cat pill_string.go

cd $HOME/scratchpad/code-gen
mkdir t-example
cd t-example
cat <<EOD | gofmt > t.go
package t

type T int

// 1
func (t T) TypeName() string {
 return fmt.Sprintf("%T", t)
}
// 2
EOD

# block: t
cat t.go

cd $HOME/scratchpad/code-gen
mkdir typename
cd typename

cat <<"EOD" | gofmt > main.go
// 01
package main
// 02

import (
	"fmt"
	"go/ast"
	"go/parser"
	"go/token"
	"io/ioutil"
	"log"
	"os"
)

// 1
func main() {
	typeName := os.Args[1]
	// 2
	found := false
	// 25
	pkgName := os.Getenv("GOPACKAGE")
	declFile := os.Getenv("GOFILE")
	// 3
	fset := token.NewFileSet()
	f, err := parser.ParseFile(fset, declFile, nil, 0)
	if err != nil {
		log.Fatalf("failed to parse %v: %v", declFile, err)
	}
	// 4
Decls:
	for _, d := range f.Decls {
		switch d := d.(type) {
		case *ast.GenDecl:
			if d.Tok != token.TYPE {
				continue Decls
			}
			for _, s := range d.Specs {
				s := s.(*ast.TypeSpec)
				if s.Name.Name != typeName {
					continue Decls
				}
				if id, ok := s.Type.(*ast.Ident); ok && id.Name == "int" {
					found = true
					break Decls
				}
			}
		}
	}
	// 5
	if !found {
		log.Fatalf("failed to find type declaration named %v of type int", typeName)
	}
	// 6
	output := fmt.Sprintf(`
	package %[1]v
	func (v %[2]v) TypeName() string {
		return "%[2]v"
	}
	`, pkgName, typeName)
	outfile := fmt.Sprintf("gen_%v_typename.go", typeName)
	// 7
	if err := ioutil.WriteFile(outfile, []byte(output), 0666); err != nil {
		log.Fatalf("failed to write output to %v: %v", outfile, err)
	}
	// 8
}
EOD

# block: typename
cat main.go

# block: go generate help
go help generate

go install

cd $HOME/scratchpad/code-gen
mkdir typename-example
cd typename-example

cat <<EOD | gofmt > main.go
package main

import "fmt"

type GoSheffield int

//go:generate typename GoSheffield

func main() {
	var gopher GoSheffield = 42
	fmt.Printf("Today's special number is %v (%v)\n", gopher, gopher.TypeName())
}
EOD

# block: typename example go generate
go generate .

gofmt -w gen_*.go

# block: run typename example
go run .

# block: main
cat main.go

# block: gen
cat gen_GoSheffield_typename.go

# Add code to repo
cd $HOME/scratchpad/code-gen
go mod tidy
git remote add origin https://github.com/$GITHUB_ORG/code-gen
sed -i -E -e '/^\/\/ [0-9]+$/d' **/*.go
gofmt -w **/*.go
git add -A
git commit -am 'Initial commit'
git push

