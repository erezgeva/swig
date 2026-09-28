

<h1 id="Preprocessor">13 Preprocessing</h1>

<!-- INDEX -->

<!-- INDEX -->

SWIG includes its own enhanced version of the C preprocessor.  The preprocessor
supports the standard preprocessor directives and macro expansion rules.
However, a number of modifications and enhancements have been made.  This
chapter describes some of these modifications.

<h2 id="Preprocessor_nn2">13.1 File inclusion</h2>

To include another file into a SWIG interface, use the `%include` directive
like this:

```swig

%include "cpointer.i"

```

Unlike, `#include`, `%include` includes each file once (and will not
reload the file on subsequent `%include` declarations).  Therefore, it
is not necessary to use include-guards in SWIG interfaces.

By default, the `#include` is ignored unless you run SWIG with the
`-includeall` option.   The reason for ignoring traditional includes
is that you often don't want SWIG to try and wrap everything included
in standard header system headers and auxiliary files.

<h2 id="Preprocessor_nn3">13.2 File imports</h2>

SWIG provides another file inclusion directive with the `%import` directive.
For example:

```swig

%import "foo.i"

```

The purpose of `%import` is to collect certain information from another 
SWIG interface file or a header file without actually generating any wrapper code.
Such information generally includes type declarations (e.g., `typedef`) as well as
C++ classes that might be used as base-classes for class declarations in the interface.
The use of `%import` is also important when SWIG is used to generate
extensions as a collection of related modules.   This is an advanced topic and is described
in later in the [Working with Modules](Modules/#Modules) chapter.

The `-importall` directive tells SWIG to follow all `#include` statements
as imports.    This might be useful if you want to extract type definitions from system 
header files without generating any wrappers.

<h2 id="Preprocessor_condition_compilation">13.3 Conditional Compilation</h2>

SWIG fully supports the use of `#if`, `#ifdef`,
`#ifndef`, `#else`, `#endif` to conditionally
include parts of an interface.

SWIG's preprocessor conditionals support the standard C/C++ preprocessor
integer expressions.  As a SWIG-specific extension, string equality and
inequality tests are also supported, for example:

```swig

#if defined __cplusplus && (#__VA_ARGS__ != "" || #TYPE == "void")

```

The following symbols are predefined by SWIG when it is parsing the interface:

```swig

SWIG                            Always defined when SWIG is processing a file
SWIGIMPORTED                    Defined when SWIG is importing a file with `%import`
SWIG_VERSION                    Hexadecimal (binary-coded decimal) number containing SWIG version,
                                such as 0x010311 (corresponding to SWIG-1.3.11).

SWIGCSHARP                      Defined when using C#
SWIGD                           Defined when using D
SWIGGO                          Defined when using Go
SWIGGUILE                       Defined when using Guile
SWIGJAVA                        Defined when using Java
SWIGJAVASCRIPT                  Defined when using Javascript
SWIG_JAVASCRIPT_JSC             Defined when using Javascript with -jsc
SWIG_JAVASCRIPT_V8              Defined when using Javascript with -v8 or -node
SWIG_JAVASCRIPT_NAPI            Defined when using Javascript with -napi
SWIGLUA                         Defined when using Lua
SWIGOCAML                       Defined when using OCaml
SWIGOCTAVE                      Defined when using Octave
SWIGPERL                        Defined when using Perl
SWIGPHP                         Defined when using PHP (any version)
SWIGPHP7                        Defined when using PHP 7 or later (with a compatible C API)
SWIGPYTHON                      Defined when using Python
SWIGR                           Defined when using R
SWIGRUBY                        Defined when using Ruby
SWIGSCILAB                      Defined when using Scilab
SWIGTCL                         Defined when using Tcl
SWIGXML                         Defined when using XML

```

SWIG also defines `SWIG_VERSION` and a target language macro in
the generated wrapper file (since SWIG 4.1.0 - in older versions these
were defined for some target languages but this wasn't consistent).  Best
practice is to use SWIG-time conditional checks because that results in smaller
generated wrapper sources.

In addition, SWIG defines the following set of standard C/C++ macros:

```swig

__LINE__                        Current line number
__FILE__                        Current file name
__STDC__                        Defined to indicate ISO C/C++
__cplusplus                     Defined when -c++ option used, value controlled by `-std=c++NN`
__STDC_VERSION__                May be defined when -c++ option is not used, value controlled by `-std=cNN`
```

Since SWIG 4.2.0, `__STDC__` is defined to `1` to match
the behaviour of ISO C/C++ compilers.  Before this SWIG defined it to
have an empty value.

Since SWIG 4.2.0, `__cplusplus` is defined to `199711L`
(the value for C++98) by default. Before this SWIG always defined it to have
the **value** `__cplusplus`.

Since SWIG 4.2.0, SWIG supports command line options `-std=cNN` and
`-std=c++NN` to specify the C/C++ standards version.  The only effect of
these options is to set appropriate values for `__STDC_VERSION__` and
`__cplusplus` respectively, which is useful if you're wrapping
headers which have preprocessor checks based on their values.

If your code requires these macros to be set to a version of the standard
that is not a final official version, or one that SWIG is not yet aware of,
you can simply redefine the appropriate macro to an alternative value at the
top of your interface file, for example:

```swig

#undef __cplusplus
#define __cplusplus 202211L

```

The following are language specific symbols that might be defined:

```swig

SWIG_D_VERSION                  Unsigned integer target version when using D
SWIGGO_CGO                      Defined when using Go for cgo
SWIGGO_GCCGO                    Defined when using Go for gccgo
SWIGGO_INTGO_SIZE               Size of the Go type int when using Go (32 or 64)
SWIGPYTHON_BUILTIN              Defined when using Python with -builtin
SWIGPYTHON_NOGIL                Defined when using Python with -nogil
SWIG_RUBY_AUTORENAME            Defined when using Ruby with -autorename

```

Interface files can look at these symbols as necessary to change the
way in which an interface is generated or to mix SWIG directives with
C code.

<h2 id="Preprocessor_nn5">13.4 Macro Expansion</h2>

Traditional preprocessor macros can be used in SWIG interfaces.  Be aware that the `#define` statement
is also used to try and detect constants.  Therefore, if you have something like this in your file,

```swig

#ifndef FOO_H 1
#define FOO_H 1
...
#endif

```

you may get some extra constants such as `FOO_H` showing up in the scripting interface.

More complex macros can be defined in the standard way. For example:

```swig

#define EXTERN extern
#ifdef __STDC__
#define ISOC_(args)   (args)
#else
#define ISOC_(args) ()
#endif

```

The following operators can appear in macro definitions:

- `#x`

Converts macro argument `x` to a string surrounded by double quotes ("x").
- `x ## y`

Concatenates x and y together to form `xy`.
- ``x``

If `x` is a string surrounded by double quotes, do nothing.  Otherwise, turn into a string
like `#x`.  This is a non-standard SWIG extension.

<h2 id="Preprocessor_nn6">13.5 SWIG Macros</h2>

SWIG provides an enhanced macro capability with the `%define` and `%enddef` directives. 
For example:

```swig

%define ARRAYHELPER(type, name)
%inline %{
type *new_ ## name (int nitems) {
  return (type *) malloc(sizeof(type)*nitems);
}
void delete_ ## name(type *t) {
  free(t);
}
type name ## _get(type *t, int index) {
  return t[index];
}
void name ## _set(type *t, int index, type val) {
  t[index] = val;
}
%}
%enddef

ARRAYHELPER(int, IntArray)
ARRAYHELPER(double, DoubleArray)

```

The primary purpose of `%define` is to define large macros of code.  Unlike normal C preprocessor
macros, it is not necessary to terminate each line with a continuation character (\)–the macro definition
extends to the first occurrence of `%enddef`.    Furthermore, when such macros are expanded,
they are reparsed through the C preprocessor.  Thus, SWIG macros can contain all other preprocessor
directives except for nested `%define` statements.

The SWIG macro capability is a very quick and easy way to generate large amounts of code.  In fact,
many of SWIG's advanced features and libraries are built using this mechanism (such as C++ template
support).

<h2 id="Preprocessor_nn7">13.6 Variadic Macros</h2>

SWIG-1.3.12 and newer releases support variadic preprocessor macros which were
standardised by C99 and C++11.  For example:

```swig

#define DEBUGF(fmt, ...)   fprintf(stderr, fmt, __VA_ARGS__)

```

When used, any extra arguments to `...` are placed into the
special variable `__VA_ARGS__`.   This also works with special SWIG
macros defined using `%define`.

The variable arguments can be empty.  However, this often results
in an extra comma (`,`) and syntax error in the resulting expansion. For
example:

```swig

DEBUGF("hello");   --> fprintf(stderr, "hello", );

```

C++20 and C23 added `__VA_OPT__()` as a solution to this, which SWIG
4.3.0 added support for.  `__VA_OPT__()` expands to its argument if the
variable arguments contain any tokens, and to nothing otherwise.  It can be
used to solve the problem above like so:

```swig

#define DEBUGF(fmt, ...)   fprintf(stderr, fmt __VA_OPT__(,) __VA_ARGS__)

```

An early non-standardised solution to this problem which gave a special
meaning to the token sequence `, ## __VA_ARGS__` is supported by
several C and C++ compilers, and also by SWIG 4.3.0 and later (it was
documented as supported by earlier SWIG versions, but didn't actually work in
at least SWIG 2.x and 3.x).  Using this feature you can get rid of the extra
comma like this:

```swig

#define DEBUGF(fmt, ...)   fprintf(stderr, fmt, ##__VA_ARGS__)

```

SWIG also supports GNU-style variadic macros, which specify a name for the
variable arguments instead of using `__VA_ARGS__`.  For example:

```swig

#define DEBUGF(fmt, args...)  fprintf(stdout, fmt, args)

```

SWIG supports `__VA_OPT__()` in combination with GNU-style variadic
macros (following the lead of GCC and clang which also support this, albeit
with a warning by default).

<h2 id="Preprocessor_delimiters">13.7 Preprocessing and delimiters</h2>

The preprocessor handles { }, " " and %{ %} delimiters differently.

<h3 id="Preprocessor_nn8">13.7.1 Preprocessing and %{ ... %} & " ... " delimiters</h3>

The SWIG preprocessor does not process any text enclosed in a code block `%{` ... `%}` or in double quotes `"` ... `"`.  Therefore,
if you write code like this,

```swig

%{
#ifdef NEED_BLAH
int blah() {
  ...
}
#endif
%}

```

the contents of the `%{ ... %}` block are copied without
modification to the output (including all preprocessor directives).

<h3 id="Preprocessor_nn9">13.7.2 Preprocessing and { ... } delimiters</h3>

SWIG always runs the preprocessor on text appearing inside `{ ... }`.  However,
sometimes it is desirable to make a preprocessor directive pass through to the output
file.  For example:

```swig

%extend Foo {
  void bar() {
    #ifdef DEBUG
      printf("I'm in bar\n");
    #endif
  }
}

```

By default, SWIG will interpret the `#ifdef DEBUG` statement.   However, if you really wanted that code
to actually go into the wrapper file, prefix the preprocessor directives with `%` like this:

```swig

%extend Foo {
  void bar() {
    %#ifdef DEBUG
      printf("I'm in bar\n");
    %#endif
  }
}

```

SWIG will strip the extra `%` and leave the preprocessor directive in the code.

<h2 id="Preprocessor_typemap_delimiters">13.8 Preprocessor and Typemaps</h2>

[Typemaps](Typemaps/#Typemaps) support a special attribute called `noblock` where the { ... } delimiters can be used,
but the delimiters are not actually generated into the code.
The effect is then similar to using "" or %{ %} delimiters but the code **is** run through the preprocessor. For example:

```swig

#define SWIG_macro(CAST) (CAST)$input
%typemap(in) Int {$1= SWIG_macro(int);}

```

might generate

```swig

  {
    arg1=(int)jarg1;
  }

```

whereas

```swig

#define SWIG_macro(CAST) (CAST)$input
%typemap(in, noblock=1) Int {$1= SWIG_macro(int);}

```

might generate

```swig

  arg1=(int)jarg1;

```

and

```swig

#define SWIG_macro(CAST) (CAST)$input
%typemap(in) Int %{$1=SWIG_macro(int);%}

```

would generate

```swig

  arg1=SWIG_macro(int);

```

<h2 id="Preprocessor_nn10">13.9 Viewing preprocessor output</h2>

Like many compilers, SWIG supports a `-E` command line option to display the output from the preprocessor.
When the `-E` option is used, SWIG will not generate any wrappers.
Instead the results after the preprocessor has run are displayed.
This might be useful as an aid to debugging and viewing the results of macro expansions.

<h2 id="Preprocessor_warning_error">13.10 The #error and #warning directives</h2>

SWIG supports the standard `#warning` and `#error` preprocessor directives.
The `#warning` directive will cause SWIG to issue a warning then continue processing.
It was standardised in C++23 and C23, and has been widely supported as an extension by
most C and C++ compilers for a long time.
The `#error` directive will cause SWIG to exit with a fatal error.
Example usage:

```swig

#error "This is a fatal error message"
#warning "This is a warning message"

```

The `#error` behaviour can be made to work like `#warning` if the `-cpperraswarn`
commandline option is used. Alternatively, the `#pragma` directive can be used to the same effect, for example:

```swig

  /* Modified behaviour: #error does not cause SWIG to exit with error */
  #pragma SWIG cpperraswarn=1
  /* Normal behaviour: #error does cause SWIG to exit with error */
  #pragma SWIG cpperraswarn=0

```

<h2 id="Preprocessor_trigraphs">13.11 Trigraphs</h2>

SWIG's preprocessor does not implement trigraphs (such as `??!` being
mapped to `|`).  They are very rarely used deliberately but these
character sequences sometimes occur in code where they aren't intended as
trigraphs.  Compilers typically don't enable trigraph support by default, and
they've been removed in C++17 and C23.

<h2 id="Preprocessor_digraphs">13.12 Digraphs</h2>

SWIG's preprocessor does not currently implement digraphs (such as
`<%` being an alternative way to write the token `{`).
These are standard in C++ and C95, but they're intended to support working with
code on systems with very restricted character sets which are really rare
these days so digraphs just don't seem to be used in practice.
