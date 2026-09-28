

# <a name="Extending"></a> 42 Extending SWIG to support new languages

<!-- INDEX -->

<!-- INDEX -->

## <a name="Extending_nn2"></a> 42.1 Introduction

This chapter primarily describes SWIG's internal organization and the process by which
new target languages can be developed.
It also provides details for debugging and extending existing target languages and functionality.

First, a brief word of warning—SWIG
is continually evolving.
The information in this chapter is mostly up to
date, but changes are ongoing.   Expect a few inconsistencies.

Also, this chapter is not meant to be a hand-holding tutorial.  As a starting point,
you should probably look at one of SWIG's existing modules.

## <a name="Extending_nn3"></a> 42.2 Prerequisites

In order to extend SWIG, it is useful to have the following background:

- An understanding of the C API for the target language.
- A good grasp of the C++ type system.
- An understanding of typemaps and some of SWIG's advanced features.
- Some familiarity with writing C++ (language modules are currently written in C++).

Since SWIG is essentially a specialized C++ compiler, it may be useful
to have some prior experience with compiler design (perhaps even a
compilers course) to better understand certain parts of the system.  A
number of books will also be useful.  For example, "The C Programming
Language" by Kernighan and Ritchie (a.k.a, "K&R") and the C++ standard,
"ISO/IEC 14882 Programming Languages - C++" will be of great use.

Also, it is useful to keep in mind that SWIG primarily operates as an
extension of the C++ *type* system.  At first glance, this might not be
obvious, but almost all SWIG directives as well as the low-level generation of
wrapper code are driven by C++ datatypes.

## <a name="Extending_nn4"></a> 42.3 The Big Picture

SWIG is a special purpose compiler that parses C++ declarations to
generate wrapper code.  To make this conversion possible, SWIG makes
three fundamental extensions to the C++ language:

- **Typemaps**. Typemaps are used to define the
conversion/marshalling behavior of specific C++ datatypes.  All type conversion in SWIG is
based on typemaps.  Furthermore, the association of typemaps to datatypes utilizes an advanced pattern matching
mechanism that is fully integrated with the C++ type system.
- **Declaration Annotation**. To customize wrapper code
generation, most declarations can be annotated with special features.
For example, you can make a variable read-only, you can ignore a
declaration, you can rename a member function, you can add exception
handling, and so forth.  Virtually all of these customizations are built on top of a low-level
declaration annotator that can attach arbitrary attributes to any declaration.
Code generation modules can look for these attributes to guide the wrapping process.
- **Class extension**. SWIG allows classes and structures to be extended with new
methods and attributes (the `%extend` directive).   This has the effect of altering
the API in the target language and can be used to generate OO interfaces to C libraries.

It is important to emphasize that virtually all SWIG features reduce to one of these three
fundamental concepts.  The type system and pattern matching rules also play a critical
role in making the system work.  For example, both typemaps and declaration annotation are
based on pattern matching and interact heavily with the underlying type system.

## <a name="Extending_nn5"></a> 42.4 Execution Model

When you run SWIG on an interface, processing is handled in stages by a series of system components:

- An integrated C preprocessor reads a collection of configuration
files and the specified interface file into memory.  The preprocessor
performs the usual functions including macro expansion and file
inclusion.   However, the preprocessor also performs some transformations of the
interface.  For instance, `#define` statements are sometimes transformed into
`%constant` declarations.  In addition, information related to file/line number
tracking is inserted.
- A C/C++ parser reads the preprocessed input and generates a full
parse tree of all of the SWIG directives and C declarations found.
The parser is responsible for many aspects of the system including
renaming, declaration annotation, and template expansion.  However, the parser
does not produce any output nor does it interact with the target
language module as it runs.  SWIG is not a one-pass compiler.
- A type-checking pass is made. This adjusts all of the C++ typenames to properly
handle namespaces, typedefs, nested classes, and other issues related to type scoping.
- A semantic pass is made on the parse tree to collect information
related to properties of the C++ interface.  For example, this pass
would determine whether or not a class allows a default constructor.
- A code generation pass is made using a specific target language
module.  This phase is responsible for generating the actual wrapper
code.  All of SWIG's user-defined modules are invoked during this
latter stage of compilation.

The next few sections briefly describe some of these stages.

### <a name="Extending_nn6"></a> 42.4.1 Preprocessing

The preprocessor plays a critical role in the SWIG implementation.  This is because a lot
of SWIG's processing and internal configuration is managed not by code written in C, but
by configuration files in the SWIG library.  In fact, when you
run SWIG, parsing starts with a small interface file like this (note: this explains
the cryptic error messages that new users sometimes get when SWIG is misconfigured or installed
incorrectly):

```swig

%include "swig.swg"             // Global SWIG configuration
%include "langconfig.swg"       // Language specific configuration
%include "yourinterface.i"      // Your interface file

```

The `swig.swg` file contains global configuration information.  In addition, this file
defines many of SWIG's standard directives as macros.  For instance, part of
of `swig.swg` looks like this:

```swig

...
/* Code insertion directives such as %wrapper %{ ... %} */

#define %begin       %insert("begin")
#define %runtime     %insert("runtime")
#define %header      %insert("header")
#define %wrapper     %insert("wrapper")
#define %init        %insert("init")

/* Access control directives */

#define %immutable   %feature("immutable", "1")
#define %mutable     %feature("immutable")

/* Directives for callback functions */

#define %callback(x) %feature("callback") `x`;
#define %nocallback  %feature("callback");

/* %ignore directive */

#define %ignore         %rename($ignore)
#define %ignorewarn(x)  %rename("$ignore:" x)
...

```

The fact that most of the standard SWIG directives are macros is
intended to simplify the implementation of the internals.  For instance,
rather than having to support dozens of special directives, it is
easier to have a few basic primitives such as `%feature` or
`%insert`.

The *`langconfig.swg`* file is supplied by the target
language. This file contains language-specific configuration
information.  More often than not, this file provides run-time wrapper
support code (e.g., the type-checker) as well as a collection of
typemaps that define the default wrapping behavior.  Note: the name of this
file depends on the target language and is usually something like `python.swg`
or `perl5.swg`.

As a debugging aid, the text that SWIG feeds to its C++ parser can be
obtained by running `swig -E interface.i`.
This option, like the same option that regular C/C++ compilers support, generates the preprocessed output
and is useful for looking at how macros have
been expanded as well as everything else that goes into the low-level
construction of the wrapper code.
Also, like a regular C/C++ compiler, the preprocessed output can be generated in one invocation and
then fed back in with a second invocation.
This is the approach that the [CCache](CCache/#CCache) tool uses as part of its strategy to speed up repeated builds with the same inputs.

### <a name="Extending_nn7"></a> 42.4.2 Parsing

The current C++ parser handles a subset of C++.  Most incompatibilities with C are due to
subtle aspects of how SWIG parses declarations.  Specifically, SWIG expects all C/C++ declarations to follow this general form:

```
storagetypedeclaratorinitializer;

```

`storage` is a keyword such as `extern`,
`static`, `typedef`, or `virtual`.  `type` is a primitive
datatype such as `int` or `void`.   `type` may be optionally
qualified with a qualifier such as `const` or `volatile`. `declarator`
is a name with additional type-construction modifiers attached to it (pointers, arrays, references,
functions, etc.).  Examples of declarators include `*x`, `**x`, `x[20]`, and
`(*x)(int, double)`.   The `initializer` may be a value assigned using `=` or
body of code enclosed in braces `{ ... }`.

This declaration format covers most common C++ declarations. However, the C++ standard
is somewhat more flexible in the placement of the parts.  For example, it is technically legal, although
uncommon to write something like `int typedef const a` in your program.   SWIG simply
doesn't bother to deal with this case.

The other significant difference between C++ and SWIG is in the
treatment of typenames.  In C++, if you have a declaration like this,

```swig

int blah(Foo *x, Bar *y);

```

it won't parse correctly unless `Foo` and `Bar` have
been previously defined as types either using a `class`
definition or a `typedef`.  The reasons for this are subtle,
but this treatment of typenames is normally integrated at the level of the C
tokenizer—when a typename appears, a different token is returned to the parser
instead of an identifier.

SWIG does not operate in this manner–any legal identifier can be used
as a type name.  The reason for this is primarily motivated by the use
of SWIG with partially defined data.  Specifically,
SWIG is supposed to be easy to use on interfaces with missing type information.

Because of the different treatment of typenames, the most serious
limitation of the SWIG parser is that it can't process type declarations where
an extra (and unnecessary) grouping operator is used.  For example:

```swig

int (x);         /* A variable x */
int (y)(int);    /* A function y */

```

The placing of extra parentheses in type declarations like this is
already recognized by the C++ community as a potential source of
strange programming errors. For example, Scott Meyers "Effective STL"
discusses this problem in a section on avoiding C++'s "most vexing
parse."

The parser is also unable to handle declarations with no return type or bare argument names.
For example, in an old C program, you might see things like this:

```swig

foo(a, b) {
...
}

```

In this case, the return type as well as the types of the arguments
are taken by the C compiler to be an `int`.  However, SWIG
interprets the above code as an abstract declarator for a function
returning a `foo` and taking types `a` and `b` as
arguments).

### <a name="Extending_nn8"></a> 42.4.3 Parse Trees

The SWIG parser produces a complete parse tree of the input file before any wrapper code
is actually generated.  Each item in the tree is known as a "Node".   Each node is identified
by a symbolic tag.   Furthermore, a node may have an arbitrary number of children.
The parse tree structure and tag names of an interface can be displayed using `swig -debug-tags`.
For example:

```shell

$ swig -c++ -python -debug-tags example.i
 . top (example.i:1)
 . top . include (example.i:1)
 . top . include . typemap (/r0/beazley/Projects/lib/swig1.3/swig.swg:71)
 . top . include . typemap . typemapitem (/r0/beazley/Projects/lib/swig1.3/swig.swg:71)
 . top . include . typemap (/r0/beazley/Projects/lib/swig1.3/swig.swg:83)
 . top . include . typemap . typemapitem (/r0/beazley/Projects/lib/swig1.3/swig.swg:83)
 . top . include (example.i:4)
 . top . include . insert (/r0/beazley/Projects/lib/swig1.3/python/python.swg:7)
 . top . include . insert (/r0/beazley/Projects/lib/swig1.3/python/python.swg:8)
 . top . include . typemap (/r0/beazley/Projects/lib/swig1.3/python/python.swg:19)
...
 . top . include (example.i:6)
 . top . include . module (example.i:2)
 . top . include . insert (example.i:6)
 . top . include . include (example.i:9)
 . top . include . include . class (example.h:3)
 . top . include . include . class . access (example.h:4)
 . top . include . include . class . constructor (example.h:7)
 . top . include . include . class . destructor (example.h:10)
 . top . include . include . class . cdecl (example.h:11)
 . top . include . include . class . cdecl (example.h:11)
 . top . include . include . class . cdecl (example.h:12)
 . top . include . include . class . cdecl (example.h:13)
 . top . include . include . class . cdecl (example.h:14)
 . top . include . include . class . cdecl (example.h:15)
 . top . include . include . class (example.h:18)
 . top . include . include . class . access (example.h:19)
 . top . include . include . class . cdecl (example.h:20)
 . top . include . include . class . access (example.h:21)
 . top . include . include . class . constructor (example.h:22)
 . top . include . include . class . cdecl (example.h:23)
 . top . include . include . class . cdecl (example.h:24)
 . top . include . include . class (example.h:27)
 . top . include . include . class . access (example.h:28)
 . top . include . include . class . cdecl (example.h:29)
 . top . include . include . class . access (example.h:30)
 . top . include . include . class . constructor (example.h:31)
 . top . include . include . class . cdecl (example.h:32)
 . top . include . include . class . cdecl (example.h:33)

```

Even for the most simple interface, the parse tree structure is larger than you might expect.  For example, in the
above output, a substantial number of nodes are actually generated by the `python.swg` configuration file
which defines typemaps and other directives.   The contents of the user-supplied input file don't appear until the end
of the output.

The contents of each parse tree node consist of a collection of attribute/value
pairs.  Internally, the nodes are simply represented by hash tables.  A display of
the entire parse-tree structure can be obtained using `swig -debug-top<n>`, where `n` is
the stage being processed. 
There are a number of other parse tree display options, for example, `swig -debug-module<n>` will
avoid displaying system parse information and only display the parse tree pertaining to the user's module at
stage `n` of processing.
Adding the `-debug-quiet` option is recommended as it removes some noise which is not usually needed,
that is, the display of many linked list pointers and symbol table pointers.
See [Debugging Options](Extending/#Extending_debugging_options) for a full list.

```shell

$ swig -c++ -python -debug-module 1 -debug-quiet example.i
debug-module stage 1
+++ module ----------------------------------------
| name         - "example"
| 
+++ insert ----------------------------------------
| code         - "\n#include \"example.h\"\n"
| 
+++ include ----------------------------------------
| name         - "example.h"

      +++ class ----------------------------------------
      | abstracts    - 0x7f4f15182930
      | allows_typedef - "1"
      | kind         - "class"
      | name         - "Shape"
      | sym:name     - "Shape"

            +++ access ----------------------------------------
            | kind         - "public"
            | 
            +++ constructor ----------------------------------------
            | access       - "public"
            | code         - "{\n    nshapes++;\n  }"
            | decl         - "f()."
            | feature:new  - "1"
            | ismember     - "1"
            | name         - "Shape"
            | sym:name     - "Shape"
            | 
            +++ destructor ----------------------------------------
            | access       - "public"
            | code         - "{\n    nshapes--;\n  }"
            | decl         - "f()."
            | ismember     - "1"
            | name         - "~Shape"
            | storage      - "virtual"
            | sym:name     - "~Shape"
            | 
            +++ cdecl ----------------------------------------
            | access       - "public"
            | decl         - ""
            | ismember     - "1"
            | kind         - "variable"
            | name         - "x"
            | sym:name     - "x"
            | type         - "double"
            | 
            +++ cdecl ----------------------------------------
            | access       - "public"
            | decl         - ""
            | ismember     - "1"
            | kind         - "variable"
            | name         - "y"
            | sym:name     - "y"
            | type         - "double"
            | 
            +++ cdecl ----------------------------------------
            | access       - "public"
            | decl         - "f(double,double)."
            | ismember     - "1"
            | kind         - "function"
            | name         - "move"
            | parms        - 'double dx,double dy'
            | sym:name     - "move"
            | type         - "void"
            | 
            +++ cdecl ----------------------------------------
            | abstract     - "1"
            | access       - "public"
            | decl         - "f()."
            | ismember     - "1"
            | kind         - "function"
            | name         - "area"
            | storage      - "virtual"
            | sym:name     - "area"
            | type         - "double"
            | value        - "0"
            | valuetype    - "int"
            | 
            +++ cdecl ----------------------------------------
            | abstract     - "1"
            | access       - "public"
            | decl         - "f()."
            | ismember     - "1"
            | kind         - "function"
            | name         - "perimeter"
            | storage      - "virtual"
            | sym:name     - "perimeter"
            | type         - "double"
            | value        - "0"
            | valuetype    - "int"
            | 
            +++ cdecl ----------------------------------------
            | access       - "public"
            | decl         - ""
            | ismember     - "1"
            | kind         - "variable"
            | name         - "nshapes"
            | storage      - "static"
            | sym:name     - "nshapes"
            | type         - "int"
            | 
      +++ class ----------------------------------------
      | allows_typedef - "1"
      | baselist     - 0x7f4f15182ad0
      | kind         - "class"
      | name         - "Circle"
      | privatebaselist - 0x7f4f15182b10
      | protectedbaselist - 0x7f4f15182af0
      | sym:name     - "Circle"

            +++ access ----------------------------------------
            | kind         - "private"
            | 
            +++ cdecl ----------------------------------------
            | access       - "private"
            | decl         - ""
            | ismember     - "1"
            | kind         - "variable"
            | name         - "radius"
            | type         - "double"
            | 
            +++ access ----------------------------------------
            | kind         - "public"
            | 
            +++ constructor ----------------------------------------
            | access       - "public"
            | code         - "{ }"
            | decl         - "f(double)."
            | feature:new  - "1"
            | ismember     - "1"
            | name         - "Circle"
            | parms        - 'double r'
            | sym:name     - "Circle"
            | 
            +++ cdecl ----------------------------------------
            | access       - "public"
            | decl         - "f()."
            | ismember     - "1"
            | kind         - "function"
            | name         - "area"
            | storage      - "virtual"
            | sym:name     - "area"
            | type         - "double"
            | 
            +++ cdecl ----------------------------------------
            | access       - "public"
            | decl         - "f()."
            | ismember     - "1"
            | kind         - "function"
            | name         - "perimeter"
            | storage      - "virtual"
            | sym:name     - "perimeter"
            | type         - "double"
            | 
      +++ class ----------------------------------------
      | allows_typedef - "1"
      | baselist     - 0x7f4f15183830
      | kind         - "class"
      | name         - "Square"
      | privatebaselist - 0x7f4f15183870
      | protectedbaselist - 0x7f4f15183850
      | sym:name     - "Square"

            +++ access ----------------------------------------
            | kind         - "private"
            | 
            +++ cdecl ----------------------------------------
            | access       - "private"
            | decl         - ""
            | ismember     - "1"
            | kind         - "variable"
            | name         - "width"
            | type         - "double"
            | 
            +++ access ----------------------------------------
            | kind         - "public"
            | 
            +++ constructor ----------------------------------------
            | access       - "public"
            | code         - "{ }"
            | decl         - "f(double)."
            | feature:new  - "1"
            | ismember     - "1"
            | name         - "Square"
            | parms        - 'double w'
            | sym:name     - "Square"
            | 
            +++ cdecl ----------------------------------------
            | access       - "public"
            | decl         - "f()."
            | ismember     - "1"
            | kind         - "function"
            | name         - "area"
            | storage      - "virtual"
            | sym:name     - "area"
            | type         - "double"
            | 
            +++ cdecl ----------------------------------------
            | access       - "public"
            | decl         - "f()."
            | ismember     - "1"
            | kind         - "function"
            | name         - "perimeter"
            | storage      - "virtual"
            | sym:name     - "perimeter"
            | type         - "double"

```

### <a name="Extending_nn9"></a> 42.4.4 Attribute namespaces

Attributes of parse tree nodes are often prepended with a namespace qualifier.
For example, the attributes
`sym:name` and `sym:symtab` are attributes related to
symbol table management and are prefixed with `sym:`.  As a
general rule, only those attributes which are directly related to the raw declaration
appear without a prefix (type, name, declarator, etc.).

Target language modules may add additional attributes to nodes to assist the generation
of wrapper code.  The convention for doing this is to place these attributes in a namespace
that matches the name of the target language.  For example, `python:foo` or
`perl:foo`.

### <a name="Extending_nn10"></a> 42.4.5 Symbol Tables

During parsing, all symbols are managed in the space of the target
language.  The `sym:name` attribute of each node contains the symbol name
selected by the parser.  Normally, `sym:name` and `name`
are the same.  However, the `%rename` directive can be used to
change the value of `sym:name`.  You can see the effect of
`%rename` by trying it on a simple interface and dumping the
parse tree.  For example:

```swig

%rename(foo_i) foo(int);
%rename(foo_d) foo(double);

void foo(int);
void foo(double);
void foo(Bar *b);

```

There are various `debug-` options that can be useful for debugging and analysing the parse tree.
For example, the `debug-top<n>` or `debug-module<n>` options will
dump the entire/top of the parse tree or the module subtree at one of the four `n` stages of processing.
The parse tree can be viewed after the final stage of processing by running SWIG:

```shell

$ swig -debug-top 1 -debug-quiet example.i
...
            +++ cdecl ----------------------------------------
            | decl         - "f(int)."
            | name         - "foo"
            | parms        - int
            | sym:name     - "foo_i"
            | type         - "void"
            |
            +++ cdecl ----------------------------------------
            | decl         - "f(double)."
            | name         - "foo"
            | parms        - double
            | sym:name     - "foo_d"
            | type         - "void"
            |
            +++ cdecl ----------------------------------------
            | decl         - "f(p.Bar)."
            | name         - "foo"
            | parms        - Bar *
            | sym:name     - "foo"
            | type         - "void"

```

All symbol-related conflicts and complaints about overloading are based on `sym:name` values.
For instance, the following example uses `%rename` in reverse to generate a name clash.

```swig

%rename(foo) foo_i(int);
%rename(foo) foo_d(double);

void foo_i(int);
void foo_d(double);
void foo(Bar *b);

```

When you run SWIG on this you now get:

```shell

$ ./swig example.i
example.i:6. Overloaded declaration ignored.  foo_d(double )
example.i:5. Previous declaration is foo_i(int )
example.i:7. Overloaded declaration ignored.  foo(Bar *)
example.i:5. Previous declaration is foo_i(int )

```

### <a name="Extending_nn11"></a> 42.4.6 The %feature directive

A number of SWIG directives such as `%exception` are implemented using the
low-level `%feature` directive.  For example:

```swig

%feature("except") getitem(int) {
  try {
     $action
  } catch (badindex) {
     ...
  }
}

...
class Foo {
public:
  Object *getitem(int index) throws(badindex);
  ...
};

```

The behavior of `%feature` is very easy to describe–it simply
attaches a new attribute to any parse tree node that matches the
given prototype.   When a feature is added, it shows up as an attribute in the `feature:` namespace.
You can see this when running with the `-debug-top 4 -debug-quiet` option.   For example:

```shell

 +++ cdecl ----------------------------------------
 | decl         - "f(int).p."
 | feature:except - "{\n    try {\n       $action\n    } catc..."
 | name         - "getitem"
 | parms        - int
 | sym:name     - "getitem"
 | type         - "Object"
 |

```

Feature names are completely arbitrary and a target language module can be
programmed to respond to any feature name that it wants to recognize.  The 
data stored in a feature attribute is usually just a raw unparsed string.   
For example, the exception code above is simply
stored without any modifications.

### <a name="Extending_nn12"></a> 42.4.7 Code Generation

Language modules work by defining handler functions that know how to respond to
different types of parse-tree nodes.  These handlers simply look at the
attributes of each node in order to produce low-level code.

In reality, the generation of code is somewhat more subtle than simply
invoking handler functions.  This is because parse-tree nodes might be
transformed. For example, suppose you are wrapping a class like this:

```swig

class Foo {
public:
  virtual int *bar(int x);
};

```

When the parser constructs a node for the member `bar`, it creates a raw "cdecl" node with the following
attributes:

```

nodeType    : cdecl
name        : bar
type        : int
decl        : f(int).p
parms       : int x
storage     : virtual
sym:name    : bar

```

To produce wrapper code, this "cdecl" node undergoes a number of transformations.  First, the node is recognized as a function declaration.   This adjusts some of the type information–specifically, the declarator is joined with the base datatype to produce this:

```

nodeType    : cdecl
name        : bar
type        : p.int        <-- Notice change in return type
decl        : f(int).p
parms       : int x
storage     : virtual
sym:name    : bar

```

Next, the context of the node indicates that the node is really a
member function.  This produces a transformation to a low-level
accessor function like this:

```

nodeType    : cdecl
name        : bar
type        : int.p
decl        : f(int).p
parms       : Foo *self, int x            <-- Added parameter
storage     : virtual
wrap:action : result = (arg1)->bar(arg2)  <-- Action code added
sym:name    : Foo_bar                     <-- Symbol name changed

```

In this transformation, notice how an additional parameter was added
to the parameter list and how the symbol name of the node has suddenly
changed into an accessor using the naming scheme described in the
"SWIG Basics" chapter.  A small fragment of "action" code has also
been generated–notice how the `wrap:action` attribute defines
the access to the underlying method.  The data in this transformed
node is then used to generate a wrapper.

Language modules work by registering handler functions for dealing with
various types of nodes at different stages of transformation.   This is done by
inheriting from a special `Language` class and defining a collection
of virtual methods.   For example, the Python module defines a class as
follows:

```swig

class PYTHON : public Language {
protected:
public :
  virtual void main(int, char *argv[]);
  virtual int  top(Node *);
  virtual int  functionWrapper(Node *);
  virtual int  constantWrapper(Node *);
  virtual int  variableWrapper(Node *);
  virtual int  nativeWrapper(Node *);
  virtual int  membervariableHandler(Node *);
  virtual int  memberconstantHandler(Node *);
  virtual int  memberfunctionHandler(Node *);
  virtual int  constructorHandler(Node *);
  virtual int  destructorHandler(Node *);
  virtual int  classHandler(Node *);
  virtual int  classforwardDeclaration(Node *);
  virtual int  insertDirective(Node *);
  virtual int  importDirective(Node *);
};

```

The role of these functions is described shortly.

### <a name="Extending_nn13"></a> 42.4.8 SWIG and XML

Much of SWIG's current parser design was originally motivated by
interest in using XML to represent SWIG parse trees.  Although XML is
not currently used in any direct manner, the parse tree structure, use
of node tags, attributes, and attribute namespaces are all influenced
by aspects of XML parsing.  Therefore, in trying to understand SWIG's
internal data structures, it may be useful to keep XML in the back of
your mind as a model.

In addition to the options beginning `-debug-` for dumping out SWIG's parse tree in a simple text format,
the parse tree can also be dumped as XML.
There are three options below, where `file` specifies the name of a file for generating the resulting XML into:

1. `-xmlout<file>`

Use this XML option in addition to any target language options.
The parse tree is dumped after the final stage of processing, that is, after the target language has finished processing.
It is useful for seeing the parse tree at stage 4 after any target language processing.
The parse tree dumped is very similar in content to that generated by `-debug-top 4`.
1. `-xml -o<file>`

Use this XML option without specifying a target language.
The parse tree that is dumped is the same as if there was a no target language option.
It is useful for seeing the parse tree at stage 3, which is the same as stage 4, as there is no target language processing.
The parse tree dumped is very similar in content to that generated by `-debug-top 3`.
1. `-xml -xmllite -o<file>`

Same as above, except the addition of `-xmllite` reduces the output by skipping some type information, that is, the typescope and typetab nodes.

The parse tree generated using `-xmlout` is much bigger than that using `-xml` as the target languages
process numerous extra SWIG system files and also add to the parse tree quite considerably in stage 4.

The XML is a dump of SWIG's internal parse tree and as such it is subject to change at any
time as and when SWIG's implementation changes.

## <a name="Extending_nn14"></a> 42.5 Primitive Data Structures

Most of SWIG is constructed using three basic data structures:
strings, hashes, and lists.  These data structures are dynamic in same way as
similar structures found in many scripting languages.  For instance,
you can have containers (lists and hash tables) of mixed types and
certain operations are polymorphic.

This section briefly describes the basic structures so that later
sections of this chapter make more sense.

When describing the low-level API, the following type name conventions are
used:

- `String`.  A string object.
- `Hash`. A hash object.
- `List`. A list object.
- `String_or_char`. A string object or a `char *`.
- `Object_or_char`. An object or a `char *`.
- `Object`.  Any object (string, hash, list, etc.)

In most cases, other typenames in the source are aliases for one of these
primitive types.   Specifically:

```swig

typedef String SwigType;
typedef Hash   Parm;
typedef Hash   ParmList;
typedef Hash   Node;
typedef Hash   Symtab;
typedef Hash   Typetab;

```

### <a name="Extending_nn15"></a> 42.5.1 Strings

**`String *NewString(const String_or_char *val)`**

Creates a new string with initial value `val`. `val` may
be a `char *` or another `String` object.   If you want
to create an empty string, use "" for val.

**`String *NewStringf(const char *fmt, ...)`**

Creates a new string whose initial value is set according to a C `printf` style
format string in `fmt`.   Additional arguments follow depending
on `fmt`.

**`String *Copy(String *s)`**

Make a copy of the string `s`.

**`void Delete(String *s)`**

Deletes `s`.

**`int Len(const String_or_char *s)`**

Returns the length of the string.

**`char *Char(const String_or_char *s)`**

Returns a pointer to the first character in a string.

**`void Append(String *s, const String_or_char *t)`**

Appends `t` to the end of string `s`.

**`void Insert(String *s, int pos, const String_or_char *t)`**

Inserts `t` into `s` at position `pos`.  The contents
of `s` are shifted accordingly.    The special value `DOH_END`
can be used for `pos` to indicate insertion at the end of the string (appending).

**`int Strcmp(const String_or_char *s, const String_or_char *t)`**

Compare strings `s` and `t`.   Same as the C `strcmp()`
function.

**`int Strncmp(const String_or_char *s, const String_or_char *t, int len)`**

Compare the first `len` characters of strings `s` and `t`.   Same as the C `strncmp()`
function.

**`char *Strstr(const String_or_char *s, const String_or_char *pat)`**

Returns a pointer to the first occurrence of `pat` in `s`.
Same as the C `strstr()` function.

**`char *Strchr(const String_or_char *s, char ch)`**

Returns a pointer to the first occurrence of character `ch` in `s`.
Same as the C `strchr()` function.

**`void Chop(String *s)`**

Chops trailing whitespace off the end of `s`.

**`int Replace(String *s, const String_or_char *pat, const String_or_char *rep, int flags)`**

Replaces the pattern `pat` with `rep` in string `s`.
`flags` is a combination of the following flags:

```swig

DOH_REPLACE_ANY       - Replace all occurrences
DOH_REPLACE_ID        - Valid C identifiers only
DOH_REPLACE_NOQUOTE   - Don't replace in quoted strings
DOH_REPLACE_FIRST     - Replace first occurrence only.

```

Returns the number of replacements made (if any).

At most one of `DOH_REPLACE_ANY` and `DOH_REPLACE_FIRST` should be specified.
`DOH_REPLACE_ANY` is the default if neither is specified.

### <a name="Extending_nn16"></a> 42.5.2 Hashes

**`Hash *NewHash()`**

Creates a new empty hash table.

**`Hash *Copy(Hash *h)`**

Make a shallow copy of the hash `h`.

**`void Delete(Hash *h)`**

Deletes `h`.

**`int Len(Hash *h)`**

Returns the number of items in `h`.

**`Object *Getattr(Hash *h, const String_or_char *key)`**

Gets an object from `h`.  `key` may be a string or
a simple `char *` string.   Returns NULL if not found.

**`int Setattr(Hash *h, const String_or_char *key, const Object_or_char *val)`**

Stores `val` in `h`. `key` may be a string or
a simple `char *`. If `val` is not a standard
object (String, Hash, or List) it is assumed to be a `char *` in which
case it is used to construct a `String` that is stored in the hash.
If `val` is NULL, the object is deleted. Increases the reference count
of `val`.   Returns 1 if this operation replaced an existing hash entry,
0 otherwise.

**`int Delattr(Hash *h, const String_or_char *key)`**

Deletes the hash item referenced by `key`.  Decreases the
reference count on the corresponding object (if any).  Returns 1
if an object was removed, 0 otherwise.

**`List *Keys(Hash *h)`**

Returns the list of hash table keys.

**`List *SortedKeys(Hash *h, int (*cmp) (const DOH *, const DOH *))`**

Returns the list of sorted hash table keys.

### <a name="Extending_nn17"></a> 42.5.3 Lists

**`List *NewList()`**

Creates a new empty list.

**`List *Copy(List *x)`**

Make a shallow copy of the List `x`.

**`void Delete(List *x)`**

Deletes `x`.

**`int Len(List *x)`**

Returns the number of items in `x`.

**`Object *Getitem(List *x, int n)`**

Returns an object from `x` with index `n`.  If `n` is
beyond the end of the list, the last item is returned. If `n` is
negative, the first item is returned.

**`int *Setitem(List *x, int n, const Object_or_char *val)`**

Stores `val` in `x`.
If `val` is not a standard
object (String, Hash, or List) it is assumed to be a `char *` in which
case it is used to construct a `String` that is stored in the list.
`n` must be in range.  Otherwise, an assertion will be raised.

**`int *Delitem(List *x, int n)`**

Deletes item `n` from the list, shifting items down if necessary.
To delete the last item in the list, use the special value `DOH_END`
for `n`.

**`void Append(List *x, const Object_or_char *t)`**

Appends `t` to the end of `x`.  If `t` is not
a standard object, it is assumed to be a `char *` and is
used to create a String object.

**`void Insert(String *s, int pos, const Object_or_char *t)`**

Inserts `t` into `s` at position `pos`.  The contents
of `s` are shifted accordingly.    The special value `DOH_END`
can be used for `pos` to indicate insertion at the end of the list (appending).
If `t` is not a standard object, it is assumed to be a `char *`
and is used to create a String object.

### <a name="Extending_nn18"></a> 42.5.4 Common operations

The following operations are applicable to all datatypes.

**`Object *Copy(Object *x)`**

Make a copy of the object `x`.

**`void Delete(Object *x)`**

Deletes `x`.

**`void Setfile(Object *x, String_or_char *f)`**

Sets the filename associated with `x`.  Used to track
objects and report errors.

**`String *Getfile(Object *x)`**

Gets the filename associated with `x`.

**`void Setline(Object *x, int n)`**

Sets the line number associated with `x`.  Used to track
objects and report errors.

**`int Getline(Object *x)`**

Gets the line number associated with `x`.

### <a name="Extending_nn19"></a> 42.5.5 Iterating over Lists and Hashes

To iterate over the elements of a list or a hash table, the following functions are used:

**`Iterator First(Object *x)`**

Returns an iterator object that points to the first item in a list or hash table.  The
`item` attribute of the Iterator object is a pointer to the item.  For hash tables, the `key` attribute
of the Iterator object additionally points to the corresponding Hash table key.  The `item` and `key` attributes
are NULL if the object contains no items or if there are no more items.

**`Iterator Next(Iterator i)`**

Returns an iterator that points to the next item in a list or hash table.

Here are two examples of iteration:

```swig

List *l = (some list);
Iterator i;

for (i = First(l); i.item; i = Next(i)) {
  Printf(stdout, "%s\n", i.item);
}

Hash *h = (some hash);
Iterator j;

for (j = First(j); j.item; j= Next(j)) {
  Printf(stdout, "%s : %s\n", j.key, j.item);
}

```

### <a name="Extending_nn20"></a> 42.5.6 I/O

Special I/O functions are used for all internal I/O.  These operations
work on C `FILE *` objects, String objects, and special `File` objects
(which are merely a wrapper around `FILE *`).

**`int Printf(String_or_FILE *f, const char *fmt, ...)`**

Formatted I/O.   Same as the C `fprintf()` function except that output
can also be directed to a string object.  Note:  the `%s` format
specifier works with both strings and `char *`.  All other format
operators have the same meaning.

**`int Printv(String_or_FILE *f, String_or_char *arg1, ..., NULL)`**

Prints a variable number of strings arguments to the output.  The last
argument to this function must be NULL.   The other arguments can either
be `char *` or string objects.

**`int Putc(int ch, String_or_FILE *f)`**

Same as the C `fputc()` function.

**`int Write(String_or_FILE *f, void *buf, int len)`**

Same as the C `write()` function.

**`int Read(String_or_FILE *f, void *buf, int maxlen)`**

Same as the C `read()` function.

**`int Getc(String_or_FILE *f)`**

Same as the C `fgetc()` function.

**`int Ungetc(int ch, String_or_FILE *f)`**

Same as the C `ungetc()` function.

**`int Seek(String_or_FILE *f, int offset, int whence)`**

Same as the C `seek()` function.  `offset` is the number
of bytes.  `whence` is one of `SEEK_SET`, `SEEK_CUR`,
or `SEEK_END`..

**`long Tell(String_or_FILE *f)`**

Same as the C `tell()` function.

**`File *NewFile(const char *filename, const char *mode, List *newfiles)`**

Create a File object using the `fopen()` library call.  This
file differs from `FILE *` in that it can be placed in the standard
SWIG containers (lists, hashes, etc.). The `filename` is added to the 
`newfiles` list if `newfiles` is non-zero and the file was created successfully.

**`File *NewFileFromFile(FILE *f)`**

Create a File object wrapper around an existing `FILE *` object.

There's no explicit function to close a file, just call `Delete(f)` -
this decreases the reference count, and the file will be closed when the
reference count reaches zero.

The use of the above I/O functions and strings play a critical role in SWIG.   It is
common to see small code fragments of code generated using code like this:

```swig

/* Print into a string */
String *s = NewString("");
Printf(s, "Hello\n");
for (i = 0; i < 10; i++) {
  Printf(s, "%d\n", i);
}
...
/* Print string into a file */
Printf(f, "%s\n", s);

```

Similarly, the preprocessor and parser all operate on string-files.

## <a name="Extending_nn21"></a> 42.6 Navigating and manipulating parse trees

Parse trees are built as collections of hash tables.   Each node is a hash table in which
arbitrary attributes can be stored.  Certain attributes in the hash table provide links to
other parse tree nodes.   The following macros can be used to move around the parse tree.

**`String *nodeType(Node *n)`**

Returns the node type tag as a string.  The returned string indicates the type of parse
tree node.

**`Node *nextSibling(Node *n)`**

Returns the next node in the parse tree.  For example, the next C declaration.

**`Node *previousSibling(Node *n)`**

Returns the previous node in the parse tree.  For example, the previous C declaration.

**`Node *firstChild(Node *n)`**

Returns the first child node.  For example, if `n` was a C++ class node, this would
return the node for the first class member.

**`Node *lastChild(Node *n)`**

Returns the last child node.   You might use this if you wanted to append a new
node to the children of a class.

**`Node *parentNode(Node *n)`**

Returns the parent of node `n`.  Use this to move up the pass tree.

The following macros can be used to change all of the above attributes.
Normally, these functions are only used by the parser.  Changing them without
knowing what you are doing is likely to be dangerous.

**`void set_nodeType(Node *n, const String_or_char)`**

Change the node type.
tree node.

**`void set_nextSibling(Node *n, Node *s)`**

Set the next sibling.

**`void set_previousSibling(Node *n, Node *s)`**

Set the previous sibling.

**`void set_firstChild(Node *n, Node *c)`**

Set the first child node.

**`void set_lastChild(Node *n, Node *c)`**

Set the last child node.

**`void set_parentNode(Node *n, Node *p)`**

Set the parent node.

The following utility functions are used to alter the parse tree (at your own risk)

**`void appendChild(Node *parent, Node *child)`**

Append a child to `parent`.  The appended node becomes the last child.

**`void deleteNode(Node *node)`**

Deletes a node from the parse tree.  Deletion reconnects siblings and properly updates
the parent so that sibling nodes are unaffected.

## <a name="Extending_nn22"></a> 42.7 Working with attributes

Since parse tree nodes are just hash tables, attributes are accessed using the `Getattr()`,
`Setattr()`, and `Delattr()` operations.  For example:

```swig

int functionHandler(Node *n) {
  String *name    = Getattr(n, "name");
  String *symname = Getattr(n, "sym:name");
  SwigType *type  = Getattr(n, "type");
  ...
}

```

New attributes can be freely attached to a node as needed.   However, when new attributes
are attached during code generation, they should be prepended with a namespace prefix.
For example:

```swig

...
Setattr(n, "python:docstring", doc);     /* Store docstring */
...

```

A quick way to check the value of an attribute is to use the `checkAttribute()` function like this:

```swig

if (checkAttribute(n, "storage", "virtual")) {
  /* n is virtual */
  ...
}

```

Changing the values of existing attributes is allowed and is sometimes done to implement
node transformations.   However, if a function/method modifies a node, it is required to restore
modified attributes to their original values.  To simplify the task of saving/restoring attributes,
the following functions are used:

**`int Swig_save(const char *ns, Node *n, const char *name1, const char *name2, ..., NIL)`**

Saves a copy of attributes `name1`, `name2`, etc. from node `n`.
Copies of the attributes are actually resaved in the node in a different namespace which is
set by the `ns` argument.   For example, if you call `Swig_save("foo", n, "type", NIL)`,
then the "type" attribute will be copied and saved as "foo:type".  The namespace name itself is stored in
the "view" attribute of the node.  If necessary, this can be examined to find out where previous
values of attributes might have been saved.

**`int Swig_restore(Node *n)`**

Restores the attributes saved by the previous call to `Swig_save()`.  Those
attributes that were supplied to `Swig_save()` will be restored to their
original values.

The `Swig_save()` and `Swig_restore()` functions must always be used as a pair.
That is, every call to `Swig_save()` must have a matching call to `Swig_restore()`.
Calls can be nested if necessary.  Here is an example that shows how the functions might be used:

```swig

int variableHandler(Node *n) {
  Swig_save("variableHandler", n, "type", "sym:name", NIL);
  String *symname = Getattr(n, "sym:name");
  SwigType *type  = Getattr(n, "type");
  ...
  Append(symname, "_global");        // Change symbol name
  SwigType_add_pointer(type);        // Add pointer
  ...
  generate wrappers
  ...
  Swig_restore(n);                  // Restore original values
  return SWIG_OK;
}

```

**`int Swig_require(const char *ns, Node *n, const char *name1, const char *name2, ..., NIL)`**

This is an enhanced version of `Swig_save()` that adds error checking.  If an attribute
name is not present in `n`, a failed assertion results and SWIG terminates with a fatal
error.  Optionally, if an attribute name is specified as "**name*", a copy of the
attribute is saved as with `Swig_save()`.  If an attribute is specified as "?*name*",
the attribute is optional.   `Swig_restore()` must always be called after using this
function.

## <a name="Extending_nn23"></a> 42.8 Type system

SWIG implements the complete C++ type system including typedef, inheritance,
pointers, references, and pointers to members.   A detailed discussion of
type theory is impossible here.   However, let's cover the highlights.

### <a name="Extending_nn24"></a> 42.8.1 String encoding of types

All types in SWIG consist of a base datatype and a collection of type
operators that are applied to the base.   A base datatype is almost
always some kind of primitive type such as `int` or `double`.
The operators consist of things like pointers, references, arrays, and so forth.
Internally, types are represented as strings that are constructed in a very
precise manner.  Here are some examples:

```

C datatype                     SWIG encoding (strings)
-----------------------------  --------------------------
int                            "int"
int *                          "p.int"
const int *                    "p.q(const).int"
int (*x)(int, double)          "p.f(int, double).int"
int [20][30]                   "a(20).a(30).int"
int (F::*)(int)                "m(F).f(int).int"
vector<int> *                  "p.vector<(int)>"

```

Reading the SWIG encoding is often easier than figuring out the C code—just
read it from left to right.  For a type of "p.f(int, double).int" is
a "pointer to a function(int, double) that returns int".

The following operator encodings are used in type strings:

```

Operator              Meaning
-------------------   -------------------------------
p.                    Pointer to
a(n).                 Array of dimension n
r.                    C++ reference
m(class).             Member pointer to class
f(args).              Function.
q(qlist).             Qualifiers
auto.                 C++20 constrained placeholder marker (paired with c(...))
c(id)                 Base carrying the concept-id of a C++20 'Concept auto'

```

In addition, type names may be parameterized by templates.  This is
represented by enclosing the template parameters in ```
<(
... )>
```.  Variable length arguments are represented by the
special base type of `v(...)`.

SWIG's encoding as it is much easier to work with than the C/C++ type syntax -
types can be easily examined, modified, and constructed using simple string
operations (comparison, substrings, concatenation, etc.).   For
example, in the parser, a declaration like this

```swig

int *a[30];

```

is processed in a few pieces.  In this case, you have the base type
"`int`" and the declarator of type "`a(30).p.`".  To
make the final type, the two parts are just joined together using
string concatenation.

### <a name="Extending_nn25"></a> 42.8.2 Type construction

The following functions are used to construct types.  You should use
these functions instead of trying to build the type strings yourself.

**`void SwigType_add_pointer(SwigType *ty)`**

Adds a pointer to `ty`.

**`void SwigType_del_pointer(SwigType *ty)`**

Removes a single pointer from `ty`.

**`void SwigType_add_reference(SwigType *ty)`**

Adds a reference to `ty`.

**`void SwigType_add_array(SwigType *ty, const String_or_char *size)`**

Adds an array with dimension `dim` to `ty`.

**`void SwigType_del_array(SwigType *ty)`**

Removes a single array dimension from `ty`.

**`int SwigType_array_ndim(SwigType *ty)`**

Returns number of array dimensions of `ty`.

**`String* SwigType_array_getdim(SwigType *ty, int n)`**

Returns `n`th array dimension of `ty`.

**`void SwigType_array_setdim(SwigType *ty, int n, const String_or_char *rep)`**

Sets `n`th array dimensions of `ty` to `rep`.

**`void SwigType_add_qualifier(SwigType *ty, const String_or_char *q)`**

Adds a type qualifier `q` to `ty`.  `q` is typically
`"const"` or `"volatile"`.

**`void SwigType_add_memberpointer(SwigType *ty, const String_or_char *cls)`**

Adds a pointer to a member of class `cls` to `ty`.

**`void SwigType_add_function(SwigType *ty, ParmList *p)`**

Adds a function to `ty`.  `p` is a linked-list of parameter
nodes as generated by the parser. See the section on parameter lists
for details about the representation.

**`void SwigType_add_template(SwigType *ty, ParmList *p)`**

Adds a template to `ty`.  `p` is a linked-list of parameter
nodes as generated by the parser. See the section on parameter lists
for details about the representation.

**`SwigType *SwigType_pop(SwigType *ty)`**

Removes the last type constructor from `ty` and returns it.
`ty` is modified.

**`void SwigType_push(SwigType *ty, SwigType *op)`**

Pushes the type operators in `op` onto type `ty`.  The
opposite of `SwigType_pop()`.

**`SwigType *SwigType_pop_arrays(SwigType *ty)`**

Removes all leading array operators from `ty` and returns them.
`ty` is modified.   For example, if `ty` is `"a(20).a(10).p.int"`,
then this function would return `"a(20).a(10)."` and modify `ty`
so that it has the value `"p.int"`.

**`SwigType *SwigType_pop_function(SwigType *ty)`**

Removes a function operator from `ty` including any qualification.
`ty` is modified.   For example, if `ty` is `"f(int).int"`,
then this function would return `"f(int)."` and modify `ty`
so that it has the value `"int"`.

**`SwigType *SwigType_base(SwigType *ty)`**

Returns the base type of a type.  For example, if `ty` is
`"p.a(20).int"`, this function would return `"int"`.
`ty` is unmodified.

**`SwigType *SwigType_prefix(SwigType *ty)`**

Returns the prefix of a type. For example, if `ty` is
`"p.a(20).int"`, this function would return `"p.a(20)."`.
`ty` is unmodified.

### <a name="Extending_nn26"></a> 42.8.3 Type tests

The following functions can be used to test properties of a datatype.

**`int SwigType_ispointer(SwigType *ty)`**

Checks if `ty` is a standard pointer.

**`int SwigType_ismemberpointer(SwigType *ty)`**

Checks if `ty` is a member pointer.

**`int SwigType_isreference(SwigType *ty)`**

Checks if `ty` is a C++ reference.

**`int SwigType_isarray(SwigType *ty)`**

Checks if `ty` is an array.

**`int SwigType_isfunction(SwigType *ty)`**

Checks if `ty` is a function.

**`int SwigType_isqualifier(SwigType *ty)`**

Checks if `ty` is a qualifier.

**`int SwigType_issimple(SwigType *ty)`**

Checks if `ty` is a simple type.  No operators applied.

**`int SwigType_isconst(SwigType *ty)`**

Checks if `ty` is a const type.

**`int SwigType_isvarargs(SwigType *ty)`**

Checks if `ty` is a varargs type.

**`int SwigType_istemplate(SwigType *ty)`**

Checks if `ty` is a templatized type.

### <a name="Extending_nn27"></a> 42.8.4 Typedef and inheritance

The behavior of `typedef` declaration is to introduce a type alias.
For instance, `typedef int Integer` makes the identifier
`Integer` an alias for `int`.  The treatment of typedef in
SWIG is somewhat complicated due to the pattern matching rules that get applied
in typemaps and the fact that SWIG prefers to generate wrapper code
that closely matches the input to simplify debugging (a user will see the
typedef names used in their program instead of the low-level primitive C
datatypes).

To handle `typedef`, SWIG builds a collection of trees containing typedef relations. For example,

```swig

typedef int Integer;
typedef Integer *IntegerPtr;
typedef int Number;
typedef int Size;

```

produces two trees like this:

```

                 int               p.Integer
               ^  ^  ^                 ^
              /   |   \                |
             /    |    \               |
        Integer  Size   Number    IntegerPtr

```

To resolve a single typedef relationship, the following function is used:

**`SwigType *SwigType_typedef_resolve(SwigType *ty)`**

Checks if `ty` can be reduced to a new type via typedef.  If so,
returns the new type.  If not, returns NULL.

Typedefs are only resolved in simple typenames that appear in a type.
For example, the type base name and in function parameters.   When
resolving types, the process starts in the leaf nodes and moves up
the tree towards the root.   Here are a few examples that show how it works:

```

Original type            After typedef_resolve()
------------------------ -----------------------
Integer                  int
a(30).Integer            int
p.IntegerPtr             p.p.Integer
p.p.Integer              p.p.int

```

For complicated types, the process can be quite involved.  Here is the
reduction of a function pointer:

```

p.f(Integer, p.IntegerPtr, Size).Integer          : Start
p.f(Integer, p.IntegerPtr, Size).int
p.f(int, p.IntegerPtr, Size).int
p.f(int, p.p.Integer, Size).int
p.f(int, p.p.int, Size).int
p.f(int, p.p.int, int).int                        : End

```

Two types are equivalent if their full type reductions are the same.
The following function will fully reduce a datatype:

**`SwigType *SwigType_typedef_resolve_all(SwigType *ty)`**

Fully reduces `ty` according to typedef rules.  Resulting datatype
will consist only of primitive typenames.

### <a name="Extending_nn28"></a> 42.8.5 Lvalues

When generating wrapper code, it is necessary to emit datatypes that can
be used on the left-hand side of an assignment operator (an lvalue). However,
not all C datatypes can be used in this way—especially arrays and
const-qualified types.  To generate a type that can be used as an lvalue,
use the following function:

**`SwigType *SwigType_ltype(SwigType *ty)`**

Converts type `ty` to a type that can be used as an lvalue in
assignment.  The resulting type is stripped of qualifiers and arrays are
converted to a pointers.

The creation of lvalues is fully aware of typedef and other aspects
of the type system.  Therefore, the creation of an lvalue may result in
unexpected results.  Here are a few examples:

```swig

typedef double Matrix4[4][4];
Matrix4 x;    // type = 'Matrix4', ltype='p.a(4).double'

typedef const char * Literal;
Literal y;    // type = 'Literal', ltype='p.char'

```

### <a name="Extending_nn29"></a> 42.8.6 Output functions

The following functions produce strings that are suitable for output.

**`String *SwigType_str(SwigType *ty, const String_or_char *id = 0)`**

Generates a C string for a datatype.  `id` is an optional declarator.
For example, if `ty` is "p.f(int).int" and `id` is "foo", then
this function produces "`int (*foo)(int)`".   This function is
used to convert string-encoded types back into a form that is valid C syntax.

**`String *SwigType_lstr(SwigType *ty, const String_or_char *id = 0)`**

This is the same as `SwigType_str()` except that the result
is generated from the type's lvalue (as generated from SwigType_ltype).

**`String *SwigType_lcaststr(SwigType *ty, const String_or_char *id = 0)`**

Generates a casting operation that converts from type `ty` to its
lvalue.  `id` is an optional name to include in the cast.  For example,
if `ty` is "`q(const).p.char`" and `id` is "`foo`",
this function produces the string "`(char *) foo`".

**`String *SwigType_rcaststr(SwigType *ty, const String_or_char *id = 0)`**

Generates a casting operation that converts from a type's lvalue to a
type equivalent to `ty`. `id` is an optional name to
include in the cast.  For example, if `ty` is
"`q(const).p.char`" and `id` is "`foo`", this
function produces the string "`(const char *) foo`".

**`String *SwigType_manglestr(SwigType *ty)`**

Generates a mangled string encoding of type `ty`.   The
mangled string only contains characters that are part of a valid
C identifier.   The resulting string is used in various parts of
SWIG, but is most commonly associated with type-descriptor objects
that appear in wrappers (e.g., `SWIGTYPE_p_double`).

## <a name="Extending_nn30"></a> 42.9 Parameters

Several type-related functions involve parameter lists.  These include
functions and templates.  Parameter list are represented as a list of
nodes with the following attributes:

```

"type"        -  Parameter type  (required)
"name"        -  Parameter name  (optional)
"value"       -  Initializer     (optional)

```

Typically parameters are denoted in the source by using a typename of
`Parm *` or `ParmList *`.  To walk a parameter list, simply use
code like this:

```

Parm *parms;
Parm *p;
for (p = parms; p; p = nextSibling(p)) {
  SwigType *type  = Getattr(p, "type");
  String   *name  = Getattr(p, "name");
  String   *value = Getattr(p, "value");
  ...
}

```

Note: this code is exactly the same as what you would use to walk parse tree nodes.

An empty list of parameters is denoted by a NULL pointer.

Since parameter lists are fairly common, the following utility functions are provided
to manipulate them:

**`Parm  *CopyParm(Parm *p);`**

Copies a single parameter.

**`ParmList  *CopyParmList(ParmList *p);`**

Copies an entire list of parameters.

**`int ParmList_len(ParmList *p);`**

Returns the number of parameters in a parameter list.

**`String *ParmList_str(ParmList *p);`**

Converts a parameter list into a C string.  For example,
produces a string like "`(int *p, int n, double x);`".

**`String *ParmList_protostr(ParmList *p);`**

The same as `ParmList_str()` except that parameter names are not
included.  Used to emit prototypes.

**`int ParmList_numrequired(ParmList *p);`**

Returns the number of required (non-optional) arguments in `p`.

## <a name="Extending_nn31"></a> 42.10 Writing a Language Module

One of the easiest routes to supporting a new language module is to copy an already
supported language module implementation and modify it.
Be sure to choose a language that is similar in nature to the new language.
All language modules follow a similar structure and 
this section briefly outlines the steps needed to create a bare-bones
language module from scratch.
Since the code is relatively easy to read, this section
describes the creation of a minimal Python module.   You should be able to extrapolate
this to other languages.

### <a name="Extending_nn32"></a> 42.10.1 Execution model

Code generation modules are defined by inheriting from the `Language` class,
currently defined in the `Source/Modules` directory of SWIG.  Starting from
the parsing of command line options, all aspects of code generation are controlled by
different methods of the `Language` that must be defined by your module.

### <a name="Extending_starting_out"></a> 42.10.2 Starting out

To define a new language module, first create a minimal implementation using
this example as a guide:

```swig

#include "swigmod.h"

class PYTHON : public Language {
public:

  virtual void main(int argc, char *argv[]) {
    printf("I'm the Python module.\n");
  }

  virtual int top(Node *n) {
    printf("Generating code.\n");
    return SWIG_OK;
  }

};

extern "C" Language *
swig_python(void) {
  return new PYTHON();
}

```

The "swigmod.h" header file contains, among other things, the declaration
of the `Language` base class and so you should include it at the top
of your language module's source file. Similarly, the "swigconfig.h" header
file contains some other useful definitions that you may need. Note that you
should *not* include any header files that are installed with the
target language. That is to say, the implementation of the SWIG Python module
shouldn't have any dependencies on the Python header files. The wrapper code
generated by SWIG will almost always depend on some language-specific C/C++
header files, but SWIG itself does not.

Give your language class a reasonable name, usually the same as the target language.
By convention, these class names are all uppercase (e.g. "PYTHON" for the Python
language module) but this is not a requirement. This class will ultimately consist
of a number of overrides of the virtual functions declared in the `Language`
base class, in addition to any language-specific member functions and data you
need. For now, just use the dummy implementations shown above.

The language module ends with a factory function, `swig_python()`, that simply
returns a new instance of the language class. As shown, it should be declared with the
`extern "C"` storage qualifier so that it can be called from C code. It should
also return a pointer to the base class (`Language`) so that only the interface
(and not the implementation) of your language module is exposed to the rest of SWIG.

Save the code for your language module in a file named "`python.cxx`" and
place this file in the `Source/Modules` directory of the SWIG distribution.
To ensure that your module is compiled into SWIG along with the other language modules,
modify the file `Source/Makefile.am` to include the additional source
files.  In addition, modify the file `Source/Modules/swigmain.cxx`
with an additional command line option that activates the module. Read the source—it's straightforward.

Next, at the top level of the SWIG distribution, re-run the `autogen.sh` script
to regenerate the various build files:

```shell

$ ./autogen.sh
```

Next re-run `configure` to regenerate all of the Makefiles:

```shell

$ ./configure
```

Finally, rebuild SWIG with your module added:

```shell

$ make
```

Once it finishes compiling, try running SWIG with the command-line option
that activates your module. For example, `swig -python foo.i`. The
messages from your new module should appear.

### <a name="Extending_nn34"></a> 42.10.3 Command line options

When SWIG starts, the command line options are passed to your language module.  This occurs
before any other processing occurs (preprocessing, parsing, etc.).   To capture the
command line options, simply use code similar to this:

```swig

void Language::main(int argc, char *argv[]) {
  for (int i = 1; i < argc; i++) {
    if (argv[i]) {
      if (strcmp(argv[i], "-interface") == 0) {
        if (argv[i+1]) {
          interface = NewString(argv[i+1]);
          Swig_mark_arg(i);
          Swig_mark_arg(i+1);
          i++;
        } else {
          Swig_arg_error();
        }
      } else if (strcmp(argv[i], "-globals") == 0) {
        if (argv[i+1]) {
          global_name = NewString(argv[i+1]);
          Swig_mark_arg(i);
          Swig_mark_arg(i+1);
          i++;
        } else {
          Swig_arg_error();
        }
      } else if ((strcmp(argv[i], "-proxy") == 0)) {
        proxy_flag = 1;
        Swig_mark_arg(i);
      } else if (strcmp(argv[i], "-keyword") == 0) {
        use_kw = 1;
        Swig_mark_arg(i);
      } else if (strcmp(argv[i], "-help") == 0) {
        fputs(usage, stderr);
      }
      ...
    }
  }
}

```

The exact set of options depends on what you want to do in your module.   Generally,
you would use the options to change code generation modes or to print diagnostic information.

If a module recognizes an option, it should always call `Swig_mark_arg()`
to mark the option as valid.   If you forget to do this, SWIG will terminate with an
unrecognized command line option error.

### <a name="Extending_nn35"></a> 42.10.4 Configuration and preprocessing

In addition to looking at command line options, the `main()` method is responsible
for some initial configuration of the SWIG library and preprocessor.   To do this,
insert some code like this:

```swig

void main(int argc, char *argv[]) {
  ... command line options ...

  /* Set language-specific subdirectory in SWIG library */
  SWIG_library_directory("python");

  /* Set language-specific preprocessing symbol */
  Preprocessor_define("SWIGPYTHON 1", 0);

  /* Set language-specific configuration file */
  SWIG_config_file("python.swg");
}

```

The above code does several things–it registers the name of the
language module with the core, it supplies some preprocessor macro definitions
for use in input files (so that they can determine the target language), and
it registers a start-up file.   In this case, the file `python.swg` will
be parsed before any part of the user-supplied input file.

Before proceeding any further, create a directory for your module in the SWIG
library (The `Lib` directory).   Now, create a configuration file in the
directory.  For example, `python.swg`.

Just to review, your language module should now consist of two files–
an implementation file `python.cxx` and a configuration file
`python.swg`.

### <a name="Extending_nn36"></a> 42.10.5 Entry point to code generation

SWIG is a multi-pass compiler.  Once the `main()` method has
been invoked, the language module does not execute again until
preprocessing, parsing, and a variety of semantic analysis passes have
been performed.  When the core is ready to start generating wrappers,
it invokes the `top()` method of your language class.  The
argument to `top` is a single parse tree node that corresponds to
the top of the entire parse tree.

To get the code generation process started, the `top()` procedure needs
to do several things:

- Initialize the wrapper code output.
- Set the module name.
- Emit common initialization code.
- Emit code for all of the child nodes.
- Finalize the wrapper module and cleanup.

An outline of `top()` might be as follows:

```swig

int Python::top(Node *n) {

  /* Get the module name */
  String *module = Getattr(n, "name");

  /* Get the output file name */
  String *outfile = Getattr(n, "outfile");

  /* Initialize I/O (see next section) */
  ...

  /* Output module initialization code */
  ...

  /* Emit code for children */
  Language::top(n);

  ...
  /* Cleanup files */
  ...

  return SWIG_OK;
}

```

### <a name="Extending_nn37"></a> 42.10.6 Module I/O and wrapper skeleton

<!-- please report bugs in this section to mgossage -->

Within SWIG wrappers, there are five main sections. These are (in order)

- begin: This section is a placeholder for users to put code at the beginning of the C/C++ wrapper file.
- runtime: This section has most of the common SWIG runtime code.
- header: This section holds declarations and inclusions from the .i file.
- wrapper: This section holds all the wrapper code.
- init: This section holds the module initialisation function
(the entry point for the interpreter).

Different parts of the SWIG code will fill different sections,
then upon completion of the wrappering all the sections will be saved
to the wrapper file.

To perform this will require several additions to the code in various places,
such as:

```swig

class PYTHON : public Language {
protected:
  /* General DOH objects used for holding the strings */
  File *f_begin;
  File *f_runtime;
  File *f_header;
  File *f_wrappers;
  File *f_init;

public:
  ...

};

int Python::top(Node *n) {

  ...

  /* Initialize I/O */
  f_begin = NewFile(outfile, "w", SWIG_output_files());
  if (!f_begin) {
    FileErrorDisplay(outfile);
    Exit(EXIT_FAILURE);
  }
  f_runtime = NewString("");
  f_init = NewString("");
  f_header = NewString("");
  f_wrappers = NewString("");

  /* Register file targets with the SWIG file handler */
  Swig_register_filebyname("begin", f_begin);
  Swig_register_filebyname("header", f_header);
  Swig_register_filebyname("wrapper", f_wrappers);
  Swig_register_filebyname("runtime", f_runtime);
  Swig_register_filebyname("init", f_init);

  /* Output module initialization code */
  Swig_banner(f_begin);
  ...

  /* Emit code for children */
  Language::top(n);

  ...
  /* Write all to the file */
  Dump(f_runtime, f_begin);
  Dump(f_header, f_begin);
  Dump(f_wrappers, f_begin);
  Wrapper_pretty_print(f_init, f_begin);

  /* Cleanup files */
  Delete(f_runtime);
  Delete(f_header);
  Delete(f_wrappers);
  Delete(f_init);
  Delete(f_begin);

  return SWIG_OK;
}

```

Using this to process a file will generate a wrapper file, however the
wrapper will only consist of the common SWIG code as well as any inline
code which was written in the .i file. It does not contain any wrappers for
any of the functions or classes.

The code to generate the wrappers are the various member functions, which
currently have not been touched. We will look at `functionWrapper()` as this
is the most commonly used function. In fact many of the other wrapper routines
will call this to do their work.

A simple modification to write some basic details to the wrapper looks like this:

```swig

int Python::functionWrapper(Node *n) {
  /* Get some useful attributes of this function */
  String   *name   = Getattr(n, "sym:name");
  SwigType *type   = Getattr(n, "type");
  ParmList *parms  = Getattr(n, "parms");
  String   *parmstr= ParmList_str_defaultargs(parms); // to string
  String   *func   = SwigType_str(type, NewStringf("%s(%s)", name, parmstr));
  String   *action = Getattr(n, "wrap:action");

  Printf(f_wrappers, "functionWrapper   : %s\n", func);
  Printf(f_wrappers, "           action : %s\n", action);
  return SWIG_OK;
}

```

This will now produce some useful information within your wrapper file.

```shell

functionWrapper   : void delete_Shape(Shape *self)
           action : delete arg1;

functionWrapper   : void Shape_x_set(Shape *self, double x)
           action : if (arg1) (arg1)->x = arg2;

functionWrapper   : double Shape_x_get(Shape *self)
           action : result = (double) ((arg1)->x);

functionWrapper   : void Shape_y_set(Shape *self, double y)
           action : if (arg1) (arg1)->y = arg2;
...

```

### <a name="Extending_nn38"></a> 42.10.7 Low-level code generators

<!-- please report bugs in this section to mgossage -->

As ingenious as SWIG is, and despite all its capabilities and the power of
its parser, the Low-level code generation takes a lot of work to write
properly. Mainly because every language insists on its own manner of
interfacing to C/C++. To write the code generators you will need a good
understanding of how to manually write an interface to your chosen
language, so make sure you have your documentation handy.

At this point it is also probably a good idea to take a very simple file
(just one function), and try letting SWIG generate wrappers for many
different languages. Take a look at all of the wrappers generated, and decide
which one looks closest to the language you are trying to wrap.
This may help you to decide which code to look at.

In general most language wrappers look a little like this:

```swig

/* wrapper for TYPE3 some_function(TYPE1, TYPE2); */
RETURN_TYPE _wrap_some_function(ARGS){
  TYPE1 arg1;
  TYPE2 arg2;
  TYPE3 result;

  if(ARG1 is not of TYPE1) goto fail;
  arg1=(convert ARG1);
  if(ARG2 is not of TYPE2) goto fail;
  arg2=(convert ARG2);

  result=some_function(arg1, arg2);

  convert 'result' to whatever the language wants;

  do any tidy up;

  return ALL_OK;

  fail:
  do any tidy up;
  return ERROR;
}

```

Yes, it is rather vague and not very clear. But each language works differently
so this will have to do for now.

Tackling this problem will be done in two stages:

- The skeleton: the function wrapper, and call, but without the conversion
- The conversion: converting the arguments to-from what the language wants

The first step will be done in the code, the second will be done in typemaps.

Our first step will be to write the code for `functionWrapper()`. What is
shown below is **NOT** the solution, merely a step in the right direction.
There are a lot of issues to address.

- Variable length and default parameters
- Typechecking and number of argument checks
- Overloaded functions
- Inout and Output only arguments

```swig

virtual int functionWrapper(Node *n) {
  /* get useful attributes */
  String   *name   = Getattr(n, "sym:name");
  SwigType *type   = Getattr(n, "type");
  ParmList *parms  = Getattr(n, "parms");
  ...

  /* create the wrapper object */
  Wrapper *wrapper = NewWrapper();

  /* create the wrapper function's name */
  String *wname = Swig_name_wrapper(iname);

  /* deal with overloading */
  ....

  /* write the wrapper function definition */
  Printv(wrapper->def, "RETURN_TYPE ", wname, "(ARGS) {", NIL);

  /* if any additional local variables are needed, add them now */
  ...

  /* write the list of locals/arguments required */
  emit_args(type, parms, wrapper);

  /* check arguments */
  ...

  /* write typemaps(in) */
  ....

  /* write constraints */
  ....

  /* Emit the function call */
  emit_action(n, wrapper);

  /* return value if necessary  */
  ....

  /* write typemaps(out) */
  ....

  /* add cleanup code */
  ....

  /* Close the function(ok) */
  Printv(wrapper->code, "return ALL_OK;\n", NIL);

  /* add the failure cleanup code */
  ...

  /* Close the function(error) */
  Printv(wrapper->code, "return ERROR;\n", "}\n", NIL);

  /* final substitutions if applicable */
  ...

  /* Dump the function out */
  Wrapper_print(wrapper, f_wrappers);

  /* tidy up */
  Delete(wname);
  DelWrapper(wrapper);

  return SWIG_OK;
}

```

Executing this code will produce wrappers which have our basic skeleton
but without the typemaps, there is still work to do.

### <a name="Extending_configuration_files"></a> 42.10.8 Configuration files

<!-- please report bugs in this section to ttn -->

At the time of this writing, SWIG supports nearly twenty languages,
which means that for continued sanity in maintaining the configuration
files, the language modules need to follow some conventions.  These are
outlined here along with the admission that, yes it is ok to violate
these conventions in minor ways, as long as you know where to apply the
proper kludge to keep the overall system regular and running.
Engineering is the art of compromise, see...

Much of the maintenance regularity depends on choosing a suitable
nickname for your language module (and then using it in a controlled
way).  Nicknames should be all lower case letters with an optional
numeric suffix (no underscores, no dashes, no spaces).  Some examples
are: `foo`, `bar`, `qux99`.

The numeric suffix variant, as in the last example, is somewhat tricky
to work with because sometimes people expect to refer to the language
without this number but sometimes that number is extremely relevant
(especially when it corresponds to language implementation versions with
incompatible interfaces).  New language modules that unavoidably require
a numeric suffix in their nickname should include that number in all
uses, or be prepared to kludge.

The nickname is used in four places:

| **usage** | **transform** | 
|---|---|
| "skip" tag | (none) | 
| Examples/ subdir name | (none) | 
| Examples/test-suite/ subdir name | (none) | 
<!-- add more uses here (remember to adjust header) -->

**Table:** nickname table

As you can see, most usages are direct.

- **configure.ac**

    This file is processed by

    [autoconf](https://www.gnu.org/software/autoconf/)
    to generate the `configure` script.  This is where you
    need to add shell script fragments and autoconf macros to detect the
    presence of whatever development support your language module requires,
    typically directories where headers and libraries can be found, and/or
    utility programs useful for integrating the generated wrapper code.

    Use the `AC_ARG_WITH`, `AC_MSG_CHECKING`, `AC_SUBST`
    macros and so forth (see other languages for examples).  Avoid using the
    `[` and `]` character in shell script fragments.  The
    variable names passed to `AC_SUBST` should begin with the nickname,
    entirely upcased.

    At the end of the new section is the place to put the aforementioned
    nickname kludges (should they be needed).  See Perl5 for
    examples of what to do.  [If this is still unclear after you've read
    the code, ping me and I'll expand on this further.  –ttn]

- **Makefile.in**

    Some of the variables AC_SUBSTituted are essential to the
    support of your language module.  Fashion these into a shell script
    "test" clause and assign that to a skip tag using "-z" and "-o":

    ```
    skip-qux99 = [ -z "@QUX99INCLUDE@" -o -z "@QUX99LIBS" ]
    ```

    This means if those vars should ever be empty, qux99 support should
    be considered absent and so it would be a good idea to skip actions that
    might rely on it.

    Here is where you may also define an alias (but then you'll need to
    kludge — don't do this):

    ```
    skip-qux = $(skip-qux99)
    ```

    Lastly, you need to modify each of `check-aliveness`,
    `check-examples`, `check-test-suite`
    and `lib-languages` (var).
    Use the nickname for these, not the alias.
    Note that you can do this even before you have any tests or examples
    set up; the Makefile rules do some sanity checking and skip around
    these kinds of problems.

- **Examples/Makefile.in**

    Nothing special here; see comments at the top of this file
    and look to the existing languages for examples.

- **Examples/qux99/check.list**

    Do `cp ../python/check.list .` and modify to taste.
    One subdir per line.

- **Lib/qux99/extra-install.list**

    If you add your language to the top-level Makefile.in var
    `lib-languages`, then `make install` will install
    all `*.i` and `*.swg` files from the language-specific
    subdirectory of `Lib`.  Use (optional) file
    `extra-install.list` in that directory to name
    additional files to install (see ruby for example).

- **Source/Modules/Makefile.am**

    Add appropriate files to this Automake file. That's it!

    When you have modified these files, please make sure that the new language module is completely
    ignored if it is not installed and detected on a box, that is, `make check-examples` and `make check-test-suite`
    politely displays the ignoring language message.

### <a name="Extending_nn40"></a> 42.10.9 Runtime support

Discuss the kinds of functions typically needed for SWIG runtime support (e.g.
`SWIG_ConvertPtr()` and `SWIG_NewPointerObj()`) and the names of
the SWIG files that implement those functions.

### <a name="Extending_nn41"></a> 42.10.10 Standard library files

The standard library files that most languages supply keeps growing as SWIG matures.
The following are the minimum that are usually supported:

- typemaps.i
- std_string.i
- std_vector.i
- stl.i

Please copy these and modify for any new language.

### <a name="Extending_nn42"></a> 42.10.11 User examples

Each of the language modules provides one or more examples. These examples
are used to demonstrate different features of the language module to SWIG
end-users, but you'll find that they're useful during development and testing
of your language module as well. You can use examples from the existing SWIG
language modules for inspiration.

Each example is self-contained and consists of (at least) a `Makefile`,
a SWIG interface file for the example module, and a 'runme' script that demonstrates
the functionality for that module. All of these files are stored in the same
subdirectory under the `Examples/[lang]` directory.
There are two classic examples which should be the first to convert to a new
language module. These are the "simple" C example and the "class" C++ example.
These can be found, for example for Python, in
`Examples/python/simple` and `Examples/python/class`.

By default, all of the examples are built and run when the user types
`make check`. To ensure that your examples are automatically run
during this process, see the section on [configuration files](#Extending_configuration_files).

### <a name="Extending_test_suite"></a> 42.10.12 Test driven development and the test-suite

A test driven development approach is central to the improvement and development of SWIG.
Most modifications to SWIG are accompanied by additional regression tests and checking all 
tests to ensure that no regressions have been introduced.

The regression testing is carried out by the SWIG *test-suite*.
The test-suite consists of numerous testcase interface files in the `Examples/test-suite` directory
as well as target language specific runtime tests in the `Examples/test-suite/[lang]` directory. 
When a testcase is run, it will execute the following steps for each testcase:

1. Execute SWIG passing it the testcase interface file.
1. Compile the resulting generated C/C++ code with either the C or C++ compiler into object files.
1. Link the object files into a dynamic library (dll/shared object).
1. Compile any generated and any runtime test target language code with the target language compiler, if the target language supports compilation. This step thus does not apply to the interpreted languages.
1. Execute a runtime test if one exists.

For example, the *ret_by_value* testcase consists of two components.
The first component is the `Examples/test-suite/ret_by_value.i` interface file.
The name of the SWIG module **must** always be the name of the testcase, so the `ret_by_value.i` interface file thus begins with:

```swig

%module ret_by_value

```

The testcase code will then follow the module declaration,
usually within a `%inline %{ ... %}` section for the majority of the tests.

The second component is the optional runtime tests.
Any runtime tests are named using the following convention: `[testcase]_runme.[ext]`, 
where `[testcase]` is the testcase name and `[ext]` is the normal extension for the target language file.
In this case, the Java and Python target languages implement a runtime test, so their files are respectively, 
`Examples/test-suite/java/ret_by_value_runme.java` and 
`Examples/test-suite/python/ret_by_value_runme.py`.

The goal of the test-suite is to test as much as possible in a **silent** manner.
This way any SWIG or compiler errors or warnings are easily visible.
Should there be any warnings, changes must be made to either fix them (preferably) or suppress them.
Compilation or runtime errors result in a testcase failure and will be immediately visible.
It is therefore essential that the runtime tests are written in a manner that displays nothing to stdout/stderr on success 
but error/exception out with an error message on stderr on failure.

#### <a name="Extending_running_test_suite"></a> 42.10.12.1 Running the test-suite

In order for the test-suite to work for a particular target language, the language must be correctly detected
and configured during the configure stage so that the correct Makefiles are generated.
Most development occurs on Linux, so usually it is a matter of installing the development packages for the target language
and simply configuring as outlined [earlier](#Extending_starting_out).

If when running the test-suite commands that follow, you get a message that the test was skipped, it indicates that the
configure stage is missing information in order to compile and run everything for that language.

The test-suite can be run in a number of ways.
The first group of commands are for running multiple testcases in one run and should be executed in the top level directory.
To run the entire test-suite (can take a long time):

```shell

make -k check-test-suite

```

To run the test-suite just for target language [lang], replace [lang] with one of csharp, java, perl5, python, ruby, tcl etc:

```shell

make check-[lang]-test-suite

```

Note that if a runtime test is available, a message "(with run test)" is displayed when run. For example:

```shell

$ make check-python-test-suite
checking python test-suite
checking python testcase argcargvtest (with run test)
checking python testcase python_autodoc
checking python testcase python_append (with run test)
checking python testcase callback (with run test)

```

The files generated on a previous run can be deleted using the clean targets, either the whole test-suite or for a particular language:

```shell

make clean-test-suite
make clean-[lang]-test-suite

```

The test-suite can be run in a *partialcheck* mode where just SWIG is executed, that is, the compile, 
link and running of the testcases is not performed.
Note that the partialcheck does not require the target language to be correctly configured and detected and unlike the other test-suite make targets, is never skipped. Once again, either all the languages can be executed or just a chosen language:

```shell

make partialcheck-test-suite
make partialcheck-[lang]-test-suite

```

If your computer has more than one CPU, you are strongly advised to use parallel make to speed up the execution speed. 
This can be done with any of the make targets that execute more than one testcase.
For example, a dual core processor can efficiently use 2 parallel jobs:

```shell

make -j2 check-test-suite
make -j2 check-python-test-suite
make -j2 partialcheck-java-test-suite

```

The second group of commands are for running individual testcases and should be executed in the appropriate
target language directory, `Examples/test-suite/[lang]`.
Testcases can contain either C or C++ code and when one is written, a decision must be made as to which of these input
languages is to be used.
Replace `[testcase]` in the commands below with the name of the testcase.

For a C language testcase, add the testcase under the C_TEST_CASES list in `Examples/test-suite/common.mk` and 
execute individually as:

```shell

make -s [testcase].ctest

```

For a C++ language testcase, add the testcase under the CPP_TEST_CASES list in `Examples/test-suite/common.mk` and 
execute individually as:

```shell

make -s [testcase].cpptest

```

A third category of tests are C++ language testcases testing multiple modules (the %import directive).
These require more than one shared library (dll/shared object) to be built and so are separated out from the normal C++ testcases.
Add the testcase under the MULTI_CPP_TEST_CASES list in `Examples/test-suite/common.mk` and 
execute individually as:

```shell

make -s [testcase].multicpptest

```

To delete the generated files, execute:

```shell

make -s [testcase].clean

```

If you would like to see the exact commands being executed, drop the -s option:

```shell

make [testcase].ctest
make [testcase].cpptest
make [testcase].multicpptest

```

Some real examples of each:

```shell

make -s ret_by_value.clean
make -s ret_by_value.ctest
make -s bools.cpptest
make -s imports.multicpptest

```

Advanced usage of the test-suite facilitates running tools on some of the five stages.
The make variables `SWIGTOOL` and `RUNTOOL` are used to specify a tool to respectively, invoke SWIG 
and the execution of the runtime test.
You are advised to view the `Examples/test-suite/common.mk` file for details but for a short summary,
the classic usage is to use [Valgrind](https://valgrind.org/) for memory checking.
For example, checking for memory leaks when running the runtime test in the target language interpreter:

```shell

make ret_by_value.ctest RUNTOOL="valgrind --leak-check=full"

```

This will probably make more sense if you look at the output of the above as it will show the exact commands being executed.
SWIG can be analyzed for bad memory by first rebuilding swig with just the `-g` option.
Also define DOH_DEBUG_MEMORY_POOLS, see [](#Extending_further_info) section.
SWIG can then be invoked via valgrind using:

```shell

make ret_by_value.ctest SWIGTOOL="valgrind --tool=memcheck --trace-children=yes"

```

A debugger can also be invoked easily on an individual test, for example gdb:

```shell

make ret_by_value.ctest RUNTOOL="gdb --args"

```

SWIG reads the `SWIG_FEATURES` environment variable to obtain options in addition to those passed on the command line.
This is particularly useful as the entire test-suite or a particular testcase can be run customized by using additional 
arguments, for example the -O optimization flag can be added in, as shown below for the bash shell:

```shell

env SWIG_FEATURES=-O make check-python-test-suite

```

The syntax for setting environment variables varies from one shell to the next, but it also works as shown in the example below, where some typemap debugging is added in:

```shell

make ret_by_value.ctest SWIG_FEATURES="-debug-tmsearch"

```

There is also a special 'errors' test-suite which is a set of regression tests checking SWIG warning and error messages.
It can be run in the same way as the other language test-suites, replacing [lang] with errors, such as `make check-errors-test-suite`.
The test cases used and the way it works is described in `Examples/test-suite/errors/Makefile.in`.

### <a name="Extending_nn43"></a> 42.10.13 Documentation

Don't forget to write end-user documentation for your language module. Currently,
each language module has a dedicated chapter 
You shouldn't rehash things that are already covered in sufficient
detail in the [SWIG Basics](SWIG/#SWIG) and [SWIG and C++](SWIGPlus/#SWIGPlus) chapters. There is no fixed format for *what*, exactly, you should
document about your language module, but you'll obviously want to cover issues that
are unique to your language.

Some topics that you'll want to be sure to address include:

- Command line options unique to your language module.
- Non-obvious mappings between C/C++ and target language concepts.
     For example, if your target language provides a single floating
     point type, it should be no big surprise to find that C/C++
     `float` and `double` types are mapped to it. On the other
     hand, if your target language doesn't provide support for "classes"
     or something similar, you'd want to discuss how C++ classes are handled.
- How to compile the SWIG-generated wrapper code into shared libraries
     that can actually be used. For some languages, there are well-defined
     procedures for doing this, but for others it's an ad hoc process.
     Provide as much detail as appropriate, and links to other resources
     if available.

### <a name="Extending_coding_style_guidelines"></a> 42.10.14 Coding style guidelines

The coding guidelines for the C/C++ source code are defined and implemented by the clang-format tool using
the `Source/.clang-format` config file.
Interested readers should take a look at the [ClangFormat documentation](https://clang.llvm.org/docs/ClangFormat.html) for more details.
SWIG developers are encouraged to use this ClangFormat documentation for setting up their chosen editor for integrating clang-format during editing and development.

The clang-format tool is searched for during the configuration of SWIG and if found
it will automatically be used to warn about code formatting discrepancies during the build.
The tool can be invoked during compilation and linking of the SWIG executable.
There are various make target which allow a developer to invoke clang-format
to check the code format as well as reformat the code.
These coding style guidelines are just for the SWIG C and C++ source code including header files.

How the tool is used during the development/building of SWIG depends on configure time options as follows:

| **Configure options** | **Description** | **Recommended for** | 
|---|---|---|
| ./configure | Look for clang-format and only use if found (default) | SWIG developers if clang-format is installed, everyone else if not installed | 
| ./configure --with-clang-format | Look for clang-format and only use if found | SWIG developers with a standard clang-format installation | 
| ./configure --with-clang-format=<path\> | Use explicit/renamed clang-format binary | SWIG developers with a non-standard clang-format installation | 
| ./configure --without-clang-format | Don't use clang-format even if installed on system | SWIG users, system builders and other non-developers | 

**Table:** clang-format configure options

The version of clang-format is inspected at configure time.
If the `--with-clang-format` option is not passed to configure then named versions,
such as clang-format-18, are searched for first before clang-format.
It is only enabled if the version is recent enough and this is clearly shown in the output of configure.
Version 18 is the minimum supported version and was carefully chosen when clang-format was first used for SWIG as this is the first version to support the
`Source/.clang-format-ignore` file that SWIG requires.
The ignore file helps the clang-format tooling format just the files in the source tree that should be formatted.

If clang-format is found during configure time, the make targets listed below can be used:

| **Make target** | **Example usage** | **Description** | 
|---|---|---|
| format-review | make format-review | For invoking clang-format to warn about source formatting discrepancies | 
| format-check | make format-check | For invoking clang-format to error out when there are source formatting discrepancies | 
| format-inplace | make format-inplace | For invoking clang-format to correct source formatting - overwrites source files in-place | 
| format | make format | Identical to format-inplace target | 
|  | make | Default make target for building the swig executable and invoking the format-review target | 

**Table:** make targets for formatting

The targets are available in both the root directory and the Source subdirectory.
The `CLANG_FORMAT_OPTIONS` variable can be used to add options to the clang-format invocation (the variable is empty by default).
For example, clang-format has a `--verbose` option to output the name of the file it is currently working on:

```shell

$ make format CLANG_FORMAT_OPTIONS=--verbose

```

As mentioned, if clang-format is configured to be used during configure time, the `format-review` target is always invoked after the SWIG executable has been built.
This can be temporarily avoided without rerunning configure.
Instead set the `CLANG_FORMAT` variable set to nothing (it normally holds the name of the clang-format executable):

```shell

$ make format CLANG_FORMAT=

```

Developers are also urged to use the SWIG pre-commit git hook script which is available in `Tools/pre-commit`.
This is useful for preventing accidental commits with incorrectly formatted code.
It invokes clang-format to validate the formatting is correct on all modified (both git staged and unstaged) files in the Source directory.
Find the .git/hooks directory for the SWIG repository (usually in your git working directory) and copy it there, such as:

```shell

$ cp Tools/pre-commit .git/hooks/

```

Modify the `clang_format` variable in the script if clang-format is not the name of the clang-format executable that is version 18 or later.
Then when committing code, you'll see something like the following if the code is not formatted correctly:

```shell

$ git commit .
Running clang-format in git pre-commit hook to validate modified files...
Source/Modules/java.cxx:26:30: error: code should be clang-formatted [-Wclang-format-violations]
  const String *empty_string;
                             ^
Error: Fix formatting before committing, see Doc/Manual/Extending.html#Extending_coding_style_guidelines.

```

Of particular note regarding the code style is only spaces are used and indentation is 2 spaces.
The generated C/C++ code should also follow this whitespace style as close as possible.

**Compatibility Note:** The clang-formatting was introduced during the development of SWIG-4.5.0.
Prior to that the GNU `indent` tool was recommended for formatting.
The switch to clang-format was made in order to gain automated, consistent and working reformatting for C++ source code.
The SWIG code base had to undergo some subtle formatting changes as a result.

### <a name="Extending_language_status"></a> 42.10.15 Target language status

Target languages are given a status of either 'Supported', 'Experimental' or 'Deprecated' depending on their maturity as broadly outlined in
the [Target language introduction](Introduction/#Introduction_target_languages).
This section provides more details on how this status is given.

#### <a name="Extending_supported_status"></a> 42.10.15.1 Supported status

A target language is given the 'Supported' status when

- It is in a mature, well functioning state.
- It has its own comprehensive chapter in the documentation.
  The level of documentation should be comprehensive and match the standard of the other mature modules.
  Python and Java are good references.
- It passes all of the main SWIG test-suite.
  The main test-suite is defined by the tests in the C_TEST_CASES, CPP_TEST_CASES and MULTI_CPP_TEST_CASES lists in Examples/test-suite/common.mk.
  All the newer C++ standard tests need to work and are grouped together, such as CPP11_TEST_CASES for C++11. These more 'modern' C++ standards are only tested though if the compiler is detected as supporting the given standard.
- The test-suite must also include at least twenty wide-ranging runtime tests.
  The most mature languages have a few hundred runtime tests.
  Note that porting runtime tests from another language module is a quick and easy way to achieve this.
- It supports the vast majority of SWIG features.
  Some more advanced features, such as, directors, full nested class support and target language namespaces (nspace) may be unimplemented.
  A few support libraries may be missing, for example, a small number of STL libraries.
- It provides strong backwards compatibility between releases.
  Each point release must aim to be fully backwards compatible.
  A point release version is the 3rd version digit, so each of the x.y.* versions should be backwards compatible.
  Backwards compatibility breakages can occur in a new major or minor version if absolutely necessary and if documented.
  A major or minor version is the first or second digit in the three digit version.
- Fixing unintended regressions in the Supported languages will be given higher priority over the Experimental languages by the core SWIG developers.
- Examples must be available and run successfully.
- The examples and test-suite must be fully functioning on the Github Actions Continuous Integration platform.

#### <a name="Extending_experimental_status"></a> 42.10.15.2 Experimental status

A target language is given the 'Experimental' status when

- It is of sub-standard quality, failing to meet the above 'Supported' status.
- It is somewhere between the mid to mature stage of development.
- It is in need of help to finish development.

Some minimum requirements and notes about languages with the 'Experimental' status:

- Will at least implement basic functionality - support wrapping C functions and simple C++ classes and templates.
- Have its own documentation chapter containing a reasonable level of detail.
  The documentation must provide enough basic functionality for a user to get started.
- Have fully functional examples of basic functionality (the simple and class examples).
- The test-suite must be implemented and include a few runtime tests for both C and C++ test cases.
- Failing tests must be put into one of the FAILING_CPP_TESTS or FAILING_C_TESTS lists in the test-suite.
  This will ensure the test-suite can be superficially made to pass by ignoring failing tests.
  The number of tests in these lists should be no greater than half of the number of tests in the full test-suite.
- The examples and test-suite must also be fully functioning on the Github Actions Continuous Integration platform.
  However, experimental languages will be flagged as 'continue-on-error'.
  This means that pull requests and normal development commits will not break the entire Github Actions build should an experimental language fail.
- Any new failed tests will be fixed on a 'best effort' basis by core developers with no promises made.
- If a language module has an official maintainer, then the maintainer will be requested to focus on fixing test-suite regressions and commit to migrating the module to become a 'Supported' module.
- If a module does not have an official maintainer, then, as maintenance will be on a 'best efforts' basis by the core maintainers, no guarantees will be provided from one release to the next and regressions may creep in.
- Experimental target languages will have a (suppressible) warning explaining the Experimental sub-standard status and encourage users to help improve it.
- No backwards compatibility is guaranteed as the module is effectively 'in development'.
  If a language module has an official maintainer, then a backwards compatibility guarantee may be provided at the maintainer's discretion and should be documented as such.

#### <a name="Extending_deprecated_status"></a> 42.10.15.3 Deprecated status

Unfortunately target languages that once met 'Experimental' or 'Supported' status can become non-functional and simply bit rot
due to neglect or due to the language's C/C++ API evolving and changing over time.
If there is no language maintainer and the maintenance burden becomes too much for the core
SWIG developers to keep the test-suite working with easily available versions of the target language,
the language is put into the 'Deprecated' status.

Changing the status to 'Deprecated' is an unfortunate step not done lightly and only if recent versions cannot successfully
run the test-suite and examples on the Github Actions Continuous Integration platform.
As the target language would once have had a working set of examples and test-suite, this usually only occurs
when the more modern operating system distributions available on Github can no longer run any distribution supplied version of the target language.

Changing status to 'Deprecated' flags it for removal from SWIG in a subsequent release (usually one SWIG release).
This step becomes the final plea for help from the community who use the target language.
The language will need updating by an interested community member to meet the requirements of at least 'Experimental' status in order to prevent removal.
If you are a user of a 'Deprecated' target language and would like to keep it available in future releases, please contact the SWIG developers for details of how you can help.

### <a name="Extending_prerequisites"></a> 42.10.16 Prerequisites for adding a new language module to the SWIG distribution

New target language modules can be included in SWIG and contributions are encouraged for popular languages.
In order to be considered for inclusion, a language must at a minimum fit the 'Experimental' status described above.

Below are some practical steps that should help meet these requirements.

1. The "simple" example needs to be working to demonstrate basic C code wrappers.
  Port the example from another language, such as from `Examples/python/simple`.
1. The "class" example needs to be working to demonstrate basic C++ code wrappers.
  Port the example from another language, such as from `Examples/python/class`.
1. Modify `configure.ac`, `Makefile.in` and `Examples/Makefile.in` to run
  these examples. Please make sure that if the new language is not
  installed properly on a box, `make -k check` should still work by
  skipping the tests and examples for the new language module.
1. Copying an existing language module and adapting the source for it is likely to be the most efficient
  approach to fully developing a new module as a number of corner cases are covered in the existing implementations.
  The most advanced scripting languages are Python and Ruby.
  The most advanced compiled target languages are Java and C#.
1. Get the [test-suite](#Extending_running_test_suite) running for the new language (`make check-[lang]-test-suite`).
  While the test-suite tests many corner cases,
  we'd expect the majority of it to work without much effort once the generated code is compiling
  correctly for basic functionality as most of the corner cases are covered in the SWIG core. Aim to first get
  one C and one C++ runtime test running in the test-suite.
  Adding further runtime tests should be a lot easier afterwards by porting existing runtime tests from another language module.
1. The structure and contents of the html documentation chapter can be copied and adapted from one of the other language modules.
1. Source code can be formatted correctly using the info in the [coding style guidelines](#Extending_coding_style_guidelines) section.
1. When ready, post a patch on Github, join the swig-devel mailing list and email the SWIG developers with a demonstration of
  commitment to maintaining the language module,
  certainly in the short term and ideally long term.

Once accepted into the official Git repository, development efforts should concentrate on
getting the entire test-suite to work
in order to migrate the language module to the 'Supported' status.
Runtime tests should be added for existing testcases and new test cases 
can be added should there be an area not already covered by 
the existing tests.

## <a name="Extending_debugging_options"></a> 42.11 Debugging Options

There are various command line options which can aid debugging a SWIG interface as well as debugging the development of a language module. These are as follows:

```shell

-debug-classes    - Display information about the classes found in the interface
-debug-module <n> - Display module parse tree at stages 1-4, <n> is a csv list of stages
-debug-symtabs    - Display symbol tables information
-debug-symbols    - Display target language symbols in the symbol tables
-debug-csymbols   - Display C symbols in the symbol tables
-debug-lsymbols   - Display target language layer symbols
-debug-quiet      - Display less parse tree node debug info when using other -debug options
-debug-tags       - Display information about the tags found in the interface
-debug-template   - Display information for debugging templates
-debug-top <n>    - Display entire parse tree at stages 1-4, <n> is a csv list of stages
-debug-typedef    - Display information about the types and typedefs in the interface
-debug-typemap    - Display information for debugging typemaps
-debug-tmsearch   - Display typemap search debugging information
-debug-tmused     - Display typemaps used debugging information

```

The complete list of command line options for SWIG are available by running `swig -help`.

## <a name="Extending_nn46"></a> 42.12 Guide to parse tree nodes

This section describes the different parse tree nodes and their attributes.

**cdecl**

Describes general C declarations including variables, functions, and typedefs.
A declaration is parsed as "storage T D" where storage is a storage class, T is a base type,
and D is a declarator.

```

"name"          - Declarator name
"type"          - Base type T
"decl"          - Declarator type (abstract)
"storage"       - Storage class (static, extern, typedef, etc.)
"parms"         - Function parameters (if a function)
"code"          - Function body code (if supplied)
"value"         - Default value (if supplied)
"constraint"    - C++20 trailing requires-clause subtree (if any)

```

**constructor**

C++ constructor declaration.

```

"name"          - Name of constructor
"parms"         - Parameters
"decl"          - Declarator (function with parameters)
"code"          - Function body code (if any)
"feature:new"   - Set to indicate return of new object.
"constraint"    - C++20 trailing requires-clause subtree (if any)

```

**destructor**

C++ destructor declaration.

```

"name"          - Name of destructor
"code"          - Function body code (if any)
"storage"       - Storage class (set if virtual)
"value"         - Default value (set if pure virtual).

```

**access**

C++ access change.

```

"kind"          - public, protected, private

```

**constant**

Constant created by %constant or #define.

```

"name"          - Name of constant.
"type"          - Base type.
"value"         - Value.
"storage"       - Set to %constant
"feature:immutable" - Set to indicate read-only

```

**class**

C++ class definition or C structure definition.

```

"name"          - Name of the class.
"kind"          - Class kind ("struct", "union", "class")
"symtab"        - Enclosing symbol table.
"tdname"        - Typedef name. Use for typedef struct { ... } A.
"abstract"      - Set if class has pure virtual methods.
"baselist"      - List of base class names.
"storage"       - Storage class (if any)
"unnamed"       - Set if class is unnamed.
"constraint"    - C++20 prefix requires-clause subtree (class templates)

```

**enum**

Enumeration.

```

"name"          - Name of the enum (if supplied).
"storage"       - Storage class (if any)
"tdname"        - Typedef name (typedef enum { ... } name).
"unnamed"       - Set if enum is unnamed.

```

**enumitem**

Enumeration value.

```

"name"          - Name of the enum value.
"type"          - Type (integer or char)
"value"         - Enum value (if given)
"feature:immutable" - Set to indicate read-only

```

**namespace**

C++ namespace.

```

"name"          - Name of the namespace.
"symtab"        - Symbol table for enclosed scope.
"unnamed"       - Set if unnamed namespace
"alias"         - Alias name. Set for namespace A = B;

```

**using**

C++ using directive.

```

"name"          - Name of the object being referred to.
"uname"         - Qualified name actually given to using.
"node"          - Node being referenced.
"namespace"     - Namespace name being reference (using namespace name)

```

**classforward**

A forward C++ class declaration.

```

"name"          - Name of the class.
"kind"          - Class kind ("union", "struct", "class")

```

**constraint**

C++20 constraint-expression node, held on the host's "constraint" attribute (cdecl, class,
template, concept, constructor).  A single nodeType covers the constraint-logical-or grammar;
the operator structure is in the "op" attribute, not in the type tag.

```

"op"            - "or" / "and" / "atom"
"kind"          - For atom only: "concept-id" / "parens" / "requires-expression" / "fold" / "expression"
"type"          - For atom kind="concept-id": SwigType encoded concept-id (e.g. Numeric<(T)>)
"value"         - For atom kind="expression": opaque source text
"valuetype"     - For atom kind="expression": typically T_BOOL
"fold_op"       - For atom kind="fold": "&&" or "||"
"fold_kind"     - For atom kind="fold": "unary-left" / "unary-right" / "binary"
"firstChild"    - For op "and"/"or": chain of operand constraints (n-ary, flattened);
                  for atom kind="parens" / "requires-expression" / "fold": the inner subtree

```

**requires-expression**

C++20 'requires (parms) { requirements }' primary, appearing as the firstChild of an atomic
constraint with kind="requires-expression".

```

"parms"         - Requirement-parameter-list as a ParmList (NULL if absent)
"firstChild"    - Chain of requirement nodes

```

**requirement**

A single requirement inside a requires-expression body.

```

"kind"          - "simple" / "type" / "compound" / "nested"
"type"          - For kind="type": the named type (SwigType)
"value"         - For kind="simple"/"compound"/"nested": opaque expression text
"noexcept"      - For kind="compound": "1" if 'noexcept' was present
"firstChild"    - For kind="compound": atomic concept-id constraint for the optional
                  return-type-requirement (-> Concept)

```

**insert**

Code insertion directive.  For example, %{ ... %} or
%insert(section).

```

"code"          - Inserted code
"section"       - Section name ("header", "wrapper", etc.)

```

**top**

Top of the parse tree.

```

"module"        - Module name

```

**extend**

%extend directive.

```

"name"          - Module name
"symtab"        - Symbol table of enclosed scope.

```

**apply**

%apply pattern { patternlist }.

```

"pattern"       - Source pattern.
"symtab"        - Symbol table of enclosed scope.

```

**clear**

%clear patternlist;

```

"firstChild"    - Patterns to clear

```

**include**

%include directive.

```

"name"         - Filename
"firstChild"   - Children

```

**import**

%import directive.

```

"name"         - Filename
"firstChild"   - Children

```

**module**

%module directive.

```

"name"         - Name of the module

```

**typemap**

%typemap directive.

```

"method"       - Typemap method name.
"code"         - Typemap code.
"kwargs"       - Keyword arguments (if any)
"firstChild"   - Typemap patterns

```

**typemapcopy**

%typemap directive with copy.

```

"method"       - Typemap method name.
"pattern"      - Typemap source pattern.
"firstChild"   - Typemap patterns

```

**typemapitem**

%typemap pattern. Used with %apply, %clear, %typemap.

```

"pattern"      - Typemap pattern (a parameter list)
"parms"        - Typemap parameters.

```

**types**

%types directive.

```

"parms"        - List of parameter types.
"convcode"     - Code which replaces the default casting / conversion code

```

**extern**

extern "X" { ... } declaration.

```

"name"       - Name "C", "Fortran", etc.

```

## <a name="Extending_further_info"></a> 42.13 Further Development Information

There is further documentation available on the internals of SWIG, API documentation and debugging information.
This is shipped with SWIG in the `Doc/Devel` directory.
