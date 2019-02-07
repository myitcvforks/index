<!-- __JSON: gobin -m -run myitcv.io/cmd/egrunner script.sh # LONG ONLINE

Write less (code), generate more
Exploring code generation in Go
7 Feb 2019

Paul Jolly
modelogiq
paul@myitcv.io
https://myitcv.io
@_myitcv

: I am Paul
: Co-organiser of London Gophers
: Enjoy building tools in Go, including code generators

* Today we will

- examine the principles of code generation
- discover the main parts of a code generator
- look at some popular code generators
- write a simple code generator
- see how code generation fits into developer workflow
- inspire everyone to join the golang-tools community of tool builders!

.image images/tool_gopher.png 200 _
.caption Gopherize.me artwork courtesy of Ashley McNamara

: The goal of this talk is to equip and inspire people to experiment with code generation in their development workflow,
: and therefore become more efficient/effective at writing software/software engineering in the process.

* What do we mean by code generation?

Code generation is the process of generating code.

Code generators are the things that generate code.

.image images/code_gen_output.png _ 900

: Quick show of hands: who here has written some (Go) code?

* What is a code generator?

Humans are code generators:

- very creative
- good at problem solving
- not good at repetitive, robotic tasks

.image images/homer.png 300 _
.caption ©2006 Twentieth Century Fox Film Corporation

* What is a code generator?

Programs can be code generators:

- a computer program can write a computer program
- (currently) no creative or problem solving abilities
- good at repetitive, robotic tasks

.image images/gopher.png 300 _
.caption _Gopher_ by [[http://www.reneefrench.com][Renée French]]

* What code can be generated?

.image images/languages.jpg 500 _
.caption Image taken from codeinstitute.net

* But what about the input(s)?

- Code
- Configuration
- Metadata
- Environment
- No input
- ...

* Examples of code generators

- [[https://golang.org/cmd/go/#hdr-Test_packages][go test]]
  - Input: `*_test.go` Go source files
  - Output: `package`main` test program source file

- [[https://github.com/gopherjs/gopherjs][github.com/gopherjs/gopherjs]]
 - Input: Go source code
 - Output: JavaScript source code

- [[https://developers.google.com/protocol-buffers/][Protocol Buffers compiler]]
  - Input: .proto declarations
  - Output: Go source code, Java source code...

- [[https://godoc.org/golang.org/x/tools/cmd/stringer][golang.org/x/tools/cmd/stringer]]
  - Input: type declarations in Go code
  - Output: `String()` method for those types

* Today: we will focus on Go-based code generation

.image images/go_code_gen.png _ 800

* stringer: deep dive

Stringer is a tool to automate the creation of methods that satisfy the fmt.Stringer interface

- takes name of an integer type T that has constants defined
- creates a new Go source file implementing:

  func (t T) String() string

* stringer: input

{{PrintBlockOut "painkiller" | between "// 1" "// 2" | indent}}

* stringer: code generator

.image images/stringer_docs.png _ 900

* stringer: output

{{PrintBlockOut "pill" | indent}}

* stringer: workflow

We could run stringer by hand

But doing so with potentially multiple code generators across multiple packages would be tedious.

* stringer: meet go generate

go generate helps automates the process of running code generators by scanning for special comments in Go source code that identify general commands to run.

These special comments are called directives:

{{PrintBlockOut "painkiller" | between "// 2" "// 3" | indent}}

We run go generate with a list of packages:

  go generate ./...

For more details see:

{{PrintBlock "go generate help" | lineEllipsis 4 | indent}}

* Go tool refresher

  $ go help
  ...
        build       compile packages and dependencies
        doc         show documentation for package or symbol
        get         download and install packages and dependencies
        install     compile and install packages and dependencies
        list        list packages or modules
        test        test packages
        ...         ...
        generate    generate Go files by processing source

- go generate is not part of go build
- no dependency analysis; must be run explicitly

* Writing our own simple code generator: typename

We will create stringer-esque code generator:

- take name of an integer type T
- create a new Go source file implementing:

  func (t T) TypeName() string

In effect we are writing a code generated version of:

{{PrintBlockOut "t" | between "// 1" "// 2" | indent}}

* typename: process

- take a single type name as an argument
- parse Go source file using go/parser
- find type declaration in abstract syntax tree (AST)
- ensure it is an int type
- generate output file

* typename: implementation

We are creating a program:

{{PrintBlockOut "typename" | between "// 01" "// 02" | indent}}

Our program takes a single argument, the type name:

{{PrintBlockOut "typename" | between "// 1" "// 2" | lineEllipsis 2 | indent}}

go generate sets some useful environment variables:

{{PrintBlockOut "typename" | between "	// 25" "	// 3" | indent}}

* typename: implementation

Parse the file containing the directive:

{{PrintBlockOut "typename" | between "	// 3" "	// 4" | indent}}

* typename: implementation

Find the type declaration:

{{PrintBlockOut "typename" | between "	// 4" "	// 5" | indent}}

* typename: implementation

Bail if we can't find the declaration:

{{PrintBlockOut "typename" | between "	// 5" "	// 6" | indent}}

* typename: implementation

Prepare output:

{{PrintBlockOut "typename" | between "	// 6" "	// 7" | indent}}

Write output:

{{PrintBlockOut "typename" | between "	// 7" "	// 8" | indent}}

* typename: in action

{{PrintBlockOut "main" | indent}}

* typename: output

Run go generate:

{{PrintBlock "typename example go generate" | indent}}

Review generated file:

{{PrintBlockOut "gen" | indent}}

Run our program:

{{PrintBlock "run typename example" | indent}}

* typename: recap

- simple Go-based code generator
- looks at syntax of single input file only
- takes a single argument
- not robust in the presence of syntax errors
- not tested
- ...

* Where could we go from here?

- look at more than just structure of code; analyse types
- use [[https://godoc.org/golang.org/x/tools/go/packages][golang.org/x/tools/go/packages]] to help load syntax and type information
- be more robust in the presence of errors
- use conventions in your source code as hints for the code generator: type name prefix (i.e. template), special comments
- code generate "generic" data structures with [[https://github.com/ncw/gotemplate][github.com/ncw/gotemplate]]
- ...

* Problems with go generate

- no dependency analysis; have to run things "in right order"
- slow; always re-runs generators
- hard to chain generators together, or have generators themselves use code generation

: you don't have to do any of these things for go build/install

* Introducing gg

  myitcv.io/cmd/gg

- artefact cache-based wrapper around go generate directives
- import dependency aware
- generator dependency aware
- only re-runs generators if inputs change
- re-runs generators until a fixed point is reached
- much more simple to add code generation to your workflow
- see [[https://github.com/myitcv/x/blob/master/cmd/gg/README.md][the README]] for more details

* gg: run from cold

  # first round (4.133s)
  > gg -trace -p 1 ./...
  [stderr]
  go list -deps -test -json ./...
  hash commandDep commandDep: copy1
  generate {Pkg: mod [G]}
  ran generator: copy1 input1 2.00
  generate {Pkg: mod [G]}
  ran generator: copy1 input1 2.00
  hash {Pkg: mod [G]}

- copy1 takes an input file and copies it to create a generated output file
- copy1 also has a 2s sleep to simulate a long-running generator

* gg: cache hit

  # second round (0.126s)
  > gg -trace -p 1 ./...
  [stderr]
  go list -deps -test -json ./...
  hash commandDep commandDep: copy1
  hash {Pkg: mod [G]}

Please experiment with gg and report bugs!

*Bonus:* report bugs using a [[https://godoc.org/github.com/rogpeppe/go-internal/testscript][testscript]] test case!

* golang-tools

- golang-tools is a development list for Go Programming Language
- for discussion of the development of tools that analyze and manipulate Go source code
- including editor/IDE plugins (language server)
- also the #tools channel on Gophers Slack

See [[https://github.com/golang/go/wiki/golang-tools][the golang-tools wiki]] for more details.

* Today we have

- examined the principles of code generation
- discovered the main parts of a code generator
- looked at some popular code generators
- written a simple code generator
- seen how code generation fits into developer workflow
- inspired everyone to join the golang-tools community of tool builders!

.image images/tool_gopher.png 200 _
.caption Gopherize.me artwork courtesy of Ashley McNamara

* Links

- [[https://github.com/myitcv-talks-repos/code-gen][code from today's examples]]
- [[https://blog.golang.org/generate][go generate blog post]]
- [[https://godoc.org/golang.org/x/tools/cmd/stringer][stringer documentation]]
- [[https://godoc.org/go][standard library packages for handling Go code (parsing, type analysis etc)]]
- [[https://godoc.org/golang.org/x/tools/go/packages][convenience, modules-aware syntax and type loading]]

-->

<!-- END -->
