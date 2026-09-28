

<h1 id="Typemaps">16 Typemaps</h1>

<!-- INDEX -->

<!-- INDEX -->

<h2 id="Typemaps_nn2">16.1 Introduction</h2>

Chances are, you are reading this chapter for one of two reasons; you
either want to customize SWIG's behavior or you overheard someone
mumbling some incomprehensible drivel about "typemaps" and you asked
yourself "typemaps, what are those?"  That said, let's start with a
short disclaimer that "typemaps" are an advanced customization feature
that provide direct access to SWIG's low-level code generator. Not
only that, they are an integral part of the SWIG C++ type system (a
non-trivial topic of its own).  Typemaps are generally
*not* a required part of using SWIG.  Therefore, you might want
to re-read the earlier chapters if you have found your way to this
chapter with only a vague idea of what SWIG already does by default.

<h3 id="Typemaps_nn3">16.1.1 Type conversion</h3>

One of the most important problems in wrapper code generation is the
conversion or marshalling of datatypes between programming languages.  Specifically,
for every C/C++ declaration, SWIG must somehow generate wrapper code
that allows values to be passed back and forth between languages.
Since every programming language represents data differently, this is
not a simple of matter of simply linking code together with the
C linker.  Instead, SWIG has to know something about how data is
represented in each language and how it can be manipulated.

To illustrate, suppose you had a simple C function like this:

```swig

int factorial(int n);

```

To access this function from Python, a pair of Python API functions
are used to convert integer values.  For example:

```swig

long PyLong_AsLong(PyObject *obj);      /* Python --> C */
PyObject *PyLong_FromLong(long x);      /* C --> Python */

```

The first function is used to convert the input argument from a Python integer object
to C `long`.  The second function is used to convert a value from C back into a Python integer object.

Inside the wrapper function, you might see these functions used like this:

```swig

PyObject *wrap_factorial(PyObject *self, PyObject *args) {
  int       arg1;
  int       result;
  PyObject *obj1;
  PyObject *resultobj;

  if (!PyArg_ParseTuple("O:factorial", &obj1)) return NULL;
  arg1 = PyLong_AsLong(obj1);
  result = factorial(arg1);
  resultobj = PyLong_FromLong(result);
  return resultobj;
}

```

Every target language supported by SWIG has functions that work in a similar manner.  For example, in
Perl, the following functions are used:

```swig

IV SvIV(SV *sv);                     /* Perl --> C */
void sv_setiv(SV *sv, IV val);       /* C --> Perl */

```

In Tcl:

```swig

int Tcl_GetLongFromObj(Tcl_Interp *interp, Tcl_Obj *obj, long *value);
Tcl_Obj *Tcl_NewIntObj(long value);

```

The precise details are not so important.  What is important is that
all of the underlying type conversion is handled by collections of
utility functions and short bits of C code like this—you simply have
to read the extension documentation for your favorite language to know
how it works (an exercise left to the reader).

<h3 id="Typemaps_nn4">16.1.2 Typemaps</h3>

Since type handling is so central to wrapper code generation, SWIG
allows it to be completely defined (or redefined) by the user.  To do this,
a special `%typemap` directive is used.  For example:

```swig

/* Convert from Python --> C */
%typemap(in) int {
  $1 = PyLong_AsLong($input);
}

/* Convert from C --> Python */
%typemap(out) int {
  $result = PyLong_FromLong($1);
}

```

At first glance, this code will look a little confusing.
However, there is really not much to it.  The first typemap (the "in"
typemap) is used to convert a value from the target language to C.  The second
typemap (the "out" typemap) is used to convert in the other
direction. The content of each typemap is a small fragment of code
that is inserted directly into the SWIG generated wrapper functions.
The code is usually C or C++ code which will be generated into the C/C++ wrapper functions.
Note that this isn't always the case as some target language modules allow target language 
code within the typemaps which gets generated into target language specific files.
Within this code, a number of special variables prefixed with a `$` are expanded.  These are
really just placeholders for C/C++ variables that are generated in the course
of creating the wrapper function. In this case, `$input` refers to an
input object that needs to be converted to C/C++ and `$result`
refers to an object that is going to be returned by a wrapper
function.  `$1` refers to a C/C++ variable that has the same type as
specified in the typemap declaration (an `int` in this
example).

A short example might make this a little more clear.  If you were wrapping a
function like this:

```swig

int gcd(int x, int y);

```

A wrapper function would look approximately like this:

```swig

PyObject *wrap_gcd(PyObject *self, PyObject *args) {
  int arg1;
  int arg2;
  int result;
  PyObject *obj1;
  PyObject *obj2;
  PyObject *resultobj;

  if (!PyArg_ParseTuple("OO:gcd", &obj1, &obj2)) return NULL;

  /* "in" typemap, argument 1 */
  {
    arg1 = PyLong_AsLong(obj1);
  }

  /* "in" typemap, argument 2 */
  {
    arg2 = PyLong_AsLong(obj2);
  }

  result = gcd(arg1, arg2);

  /* "out" typemap, return value */
  {
    resultobj = PyLong_FromLong(result);
  }

  return resultobj;
}

```

In this code, you can see how the typemap code has been inserted into
the function.  You can also see how the special $ variables have been
expanded to match certain variable names inside the wrapper function.  This is really the
whole idea behind typemaps–they simply let you insert arbitrary code into different 
parts of the generated wrapper functions.   Because arbitrary code can be inserted, it
possible to completely change the way in which values are converted.

<h3 id="Typemaps_nn5">16.1.3 Pattern matching</h3>

As the name implies, the purpose of a typemap is to "map" C datatypes to 
types in the target language.   Once a typemap is defined for a C datatype,
it is applied to all future occurrences of that type in the input file.  For example:

```swig

/* Convert from Perl --> C */
%typemap(in) int {
  $1 = SvIV($input);
}

...
int factorial(int n);
int gcd(int x, int y);
int count(char *s, char *t, int max);

```

The matching of typemaps to C datatypes is more than a simple textual match.  In fact,
typemaps are fully built into the underlying type system.  Therefore, typemaps are
unaffected by `typedef`, namespaces, and other declarations that might hide the
underlying type.  For example, you could have code like this:

```swig

/* Convert from Ruby--> C */
%typemap(in) int {
  $1 = NUM2INT($input);
}
...
typedef int Integer;
namespace foo {
  typedef Integer Number;
};

int foo(int x);
int bar(Integer y);
int spam(foo::Number a, foo::Number b);

```

In this case, the typemap is still applied to the proper arguments even though typenames don't always
match the text "int".  This ability to track types is a critical part of SWIG–in fact, all
of the target language modules work merely define a family of typemaps for the basic types.  Yet, it
is never necessary to write new typemaps for typenames introduced by `typedef`.

In addition to tracking typenames, typemaps may also be specialized to match against a specific argument name.  For
example, you could write a typemap like this:

```swig

%typemap(in) double nonnegative {
  $1 = PyFloat_AsDouble($input);
  if ($1 < 0) {
    PyErr_SetString(PyExc_ValueError, "argument must be nonnegative.");
    SWIG_fail;
  }
}

...
double sin(double x);
double cos(double x);
double sqrt(double nonnegative);

typedef double Real;
double log(Real nonnegative);
...

```

For certain tasks such as input argument conversion, typemaps can be defined for sequences of
consecutive arguments.    For example:

```swig

%typemap(in) (char *str, int len) {
  Py_ssize_t nbytes;
  $1 = (char *) PyUnicode_AsUTF8AndSize($input, &nbytes);  /* char *str */
  $2 = (int) nbytes;                                       /* int len   */
}
...
int count(char *str, int len, char c);

```

In this case, a single input object is expanded into a pair of C arguments.  This example also
provides a hint to the unusual variable naming scheme involving `$1`, `$2`, and so forth.

<h3 id="Typemaps_nn6">16.1.4 Reusing typemaps</h3>

Typemaps are normally defined for specific type and argument name patterns.  However, typemaps can also 
be copied and reused.  One way to do this is to use assignment like this:

```swig

%typemap(in) Integer = int;   
%typemap(in) (char *buffer, int size) = (char *str, int len);

```

There is a more powerful way to copy a family of typemaps though.
Consider the following family of two typemap methods, "in" and "out" for type `int`:

```swig

%typemap(in) int {
  /* Convert an integer argument */
  ...
}
%typemap(out) int {
  /* Return an integer value */
  ...
}

```

Each of the two typemap methods could be copied individually for type `size_t` as follows:

```swig

/* Apply all of the int typemaps to size_t */
%typemap(in) size_t = int;   
%typemap(out) size_t = int;   

```

A more powerful form of copying is available from the `%apply` directive.
The code below is identical to the above:

```swig

/* Apply all of the int typemaps to size_t */
%apply int { size_t };    

```

`%apply` merely takes *all* of the typemaps that are defined for one type and
applies them to other types.  Note: you can include a comma separated set of types in the 
`{ ... }` part of `%apply`.

It should be noted that it is not necessary to copy typemaps for types that are related by `typedef`.
For example, if you have this,

```swig

typedef int size_t;

```

then SWIG already knows that the `int` typemaps apply.  You don't have to do anything.

<h3 id="Typemaps_nn7">16.1.5 What can be done with typemaps?</h3>

The primary use of typemaps is for defining wrapper generation behavior at the level
of individual C/C++ datatypes.  There are currently six general categories of problems that
typemaps address:

**Argument handling**

```swig

int foo(int x, double y, char *s);

```

- Input argument conversion ("in" typemap).
- Input argument type checking for types used in overloaded methods ("typecheck" typemap).
- Output argument handling ("argout" typemap).
- Input argument value checking ("check" typemap).
- Input argument initialization ("arginit" typemap).
- Default arguments ("default" typemap).
- Input argument resource management ("freearg" typemap).

**Return value handling**

```swig
int foo(int x, double y, char *s);

```

- Function return value conversion ("out" typemap).
- Return value resource management ("ret" typemap).
- Resource management for newly allocated objects ("newfree" typemap).

**Exception handling**

```swig
int foo(int x, double y, char *s) throw(MemoryError, IndexError);

```

- Handling of C++ exception specifications. ("throw" typemap).

**Global variables**

```swig
int foo;
```

- Assignment of a global variable. ("varin" typemap).
- Reading a global variable. ("varout" typemap).

**Member variables**

```swig

struct Foo {
  int x[20];
};

```

- Assignment of data to a class/structure member. ("memberin" typemap).

**Constant creation**

```swig

#define FOO 3
%constant int BAR = 42;
enum { ALE, LAGER, STOUT };

```

- Creation of constant values. ("consttab" or "constcode" typemap).

Details of each of these typemaps will be covered shortly.  Also, certain language modules may define additional
typemaps that expand upon this list.  For example, the Java module defines a variety of typemaps for controlling additional
aspects of the Java bindings.  Consult language specific documentation for further details.

<h3 id="Typemaps_nn8">16.1.6 What can't be done with typemaps?</h3>

Typemaps can't be used to define properties that apply to C/C++ declarations as a whole.  For example,
suppose you had a declaration like this,

```swig

Foo *make_Foo(int n);

```

and you wanted to tell SWIG that `make_Foo(int n)` returned a newly
allocated object (for the purposes of providing better memory
management).  Clearly, this property of `make_Foo(int n)` is
*not* a property that would be associated with the datatype
`Foo *` by itself.  Therefore, a completely different SWIG
customization mechanism (`%feature`) is used for this purpose.  Consult the [Customization Features](Customization/#Customization) chapter for more
information about that.

Typemaps also can't be used to rearrange or transform the order of arguments.  For example,
if you had a function like this:

```swig

void foo(int, char *);

```

you can't use typemaps to interchange the arguments, allowing you to call the
function like this:

```

foo("hello", 3)          # Reversed arguments

```

If you want to change the calling conventions of a function, write a helper
function instead.  For example:

```swig

%rename(foo) wrap_foo;
%inline %{
void wrap_foo(char *s, int x) {
  foo(x, s);
}
%}

```

<h3 id="Typemaps_aspects">16.1.7 Similarities to Aspect Oriented Programming</h3>

SWIG has parallels to [Aspect Oriented Software Development (AOP)](https://en.wikipedia.org/wiki/Aspect-oriented_programming).
The [AOP terminology](https://en.wikipedia.org/wiki/Aspect-oriented_programming#Terminology) with respect to SWIG typemaps can be viewed as follows:

- **Cross-cutting concerns**: The cross-cutting concerns are the modularization of the functionality that the typemaps implement, which is primarily marshalling of types from/to the target language and C/C++.
- **Advice**: The typemap body contains code which is executed whenever the marshalling is required.
- **Pointcut**: The pointcuts are the positions in the wrapper code that the typemap code is generated into.
- **Aspect**: Aspects are the combination of the pointcut and the advice, hence each typemap is an aspect.

SWIG can also be viewed as has having a second set of aspects based around [%feature](Customization/#Customization).
Features such as `%exception` are also cross-cutting concerns as they encapsulate code that can be used to add logging or exception handling to any function.

<h3 id="Typemaps_nn9">16.1.8 The rest of this chapter</h3>

The rest of this chapter provides detailed information for people who
want to write new typemaps.  This information is of particular importance to anyone
who intends to write a new SWIG target language module.  Power users can also
use this information to write application specific type conversion rules.

Since typemaps are strongly tied to the underlying C++ type system,
subsequent sections assume that you are reasonably familiar with the
basic details of values, pointers, references, arrays, type qualifiers
(e.g., `const`), structures, namespaces, templates, and memory
management in C/C++.   If not, you would be well-advised to consult a copy 
of "The C Programming Language" by Kernighan and Ritchie or 
"The C++ Programming Language" by Stroustrup before going any further.

<h2 id="Typemaps_nn10">16.2 Typemap specifications</h2>

This section describes the behavior of the `%typemap` directive itself.

<h3 id="Typemaps_defining">16.2.1 Defining a typemap</h3>

New typemaps are defined using the `%typemap` declaration.  The general form of
this declaration is as follows (parts enclosed in [ ... ] are optional):

```swig

%typemap(method [, modifiers]) typelistcode ;

```

*method* is a simply a name that specifies what kind of typemap is being defined.  It
is usually a name like `"in"`, `"out"`, or `"argout"`.   The purpose of
these methods is described later.

*modifiers* is an optional comma separated list of `name="value"` values. 
These are sometimes to attach extra information to a typemap and is often target-language dependent.
They are also known as typemap attributes.

*typelist* is a list of the C++ type patterns that the typemap will match.   The general form of
this list is as follows:

```

typelist    :  typepattern [, typepattern, typepattern, ... ] ;

typepattern :  type [ (parms) ]
            |  type name [ (parms) ]
            |  ( typelist ) [ (parms) ]

```

Each type pattern is either a simple type, a simple type and argument name, or a list of types in the
case of multi-argument typemaps. In addition, each type pattern can be parameterized with a list of temporary
variables (parms).   The purpose of these variables will be explained shortly.

*code* specifies the code used in the typemap.
Usually this is C/C++ code, but in the statically typed target languages, such as Java and C#, this can contain target language code for certain typemaps.
It can take any one of the following forms:

```

code       : { ... }
           | " ... "
           | %{ ... %}

```

Note that the preprocessor will expand code within the {} delimiters, but not in the last two styles of delimiters,
see [Preprocessor and Typemaps](Preprocessor/#Preprocessor_delimiters).
Here are some examples of valid typemap specifications:

```swig

/* Simple typemap declarations */
%typemap(in) int {
  $1 = PyLong_AsLong($input);
}
%typemap(in) int "$1 = PyLong_AsLong($input);"
%typemap(in) int %{ 
  $1 = PyLong_AsLong($input);
%}

/* Typemap with extra argument name */
%typemap(in) int nonnegative {
  ...
}

/* Multiple types in one typemap */
%typemap(in) int, short, long { 
  $1 = SvIV($input);
}

/* Typemap with modifiers */
%typemap(in, doc="integer") int "$1 = scm_to_int($input);"

/* Typemap applied to patterns of multiple arguments */
%typemap(in) (char *str, int len),
             (char *buffer, int size)
{
  Py_ssize_t nbytes;
  $1 = (char *) PyUnicode_AsUTF8AndSize($input, &nbytes);
  $2 = (int) nbytes;
}

/* Typemap with extra pattern parameters */
%typemap(in, numinputs=0) int *output (int temp),
                          long *output (long temp)
{
  $1 = &temp;
}

```

Admittedly, it's not the most readable syntax at first glance.  However, the purpose of the
individual pieces will become clear.

<h3 id="Typemaps_nn12">16.2.2 Typemap scope</h3>

Once defined, a typemap remains in effect for all of the declarations that follow.  A typemap may be redefined for
different sections of an input file.  For example:

```swig

// typemap1
%typemap(in) int {
...
}

int fact(int);                    // typemap1
int gcd(int x, int y);            // typemap1

// typemap2
%typemap(in) int {
...
}

int isprime(int);                 // typemap2

```

One exception to the typemap scoping rules pertains to the `%extend` declaration.  `%extend` is used to attach
new declarations to a class or structure definition.  Because of this, all of the declarations in an `%extend` block are
subject to the typemap rules that are in effect at the point where the class itself is defined.  For example:

```swig

class Foo {
  ...
};

%typemap(in) int {
 ...
}

%extend Foo {
  int blah(int x);    // typemap has no effect.  Declaration is attached to Foo which
                      // appears before the %typemap declaration.
};

```

<h3 id="Typemaps_nn13">16.2.3 Copying a typemap</h3>

A typemap is copied by using assignment.   For example:

```swig

%typemap(in) Integer = int;

```

or this:

```swig

%typemap(in) Integer, Number, int32_t = int;

```

Types are often managed by a collection of different typemaps.  For example:

```swig

%typemap(in)     int { ... }
%typemap(out)    int { ... }
%typemap(varin)  int { ... }
%typemap(varout) int { ... }

```

To copy all of these typemaps to a new type, use `%apply`.  For example:

```swig

%apply int { Integer };            // Copy all int typemaps to Integer
%apply int { Integer, Number };    // Copy all int typemaps to both Integer and Number

```

The patterns for `%apply` follow the same rules as for `%typemap`. For example:

```swig

%apply int *output { Integer *output };                    // Typemap with name
%apply (char *buf, int len) { (char *buffer, int size) };  // Multiple arguments

```

<h3 id="Typemaps_nn14">16.2.4 Deleting a typemap</h3>

A particular typemap can be deleted / cleared by simply defining no code.  For example:

```swig

%typemap(in) int;                 // Clears the "in" typemap for int
%typemap(in) int, long, short;    // Clears the "in" typemap for int, long, short
%typemap(in) int *output;       

```

The above syntax deletes a typemap for just one typemap method - the "in" method in each of the examples above.
The `%clear` directive is more powerful and will delete / clear a family of typemaps, that is, all the typemap methods for a given type.
For example:

```swig

%clear int;                       // Delete all typemaps ("in", "out", "varin", ...) for int
%clear int *output, long *output;

```

**Note:** Since SWIG's default behavior is defined by typemaps, clearing a fundamental type like
`int` will make that type unusable unless you also define a new family of typemaps immediately
after the clear operation.

<h3 id="Typemaps_nn15">16.2.5 Placement of typemaps</h3>

Typemap declarations can be declared in the global scope, within a C++ namespace, and within a C++ class.  For
example:

```swig

%typemap(in) int {
  ...
}

namespace std {
  class string;
  %typemap(in) string {
    ...
  }
}

class Bar {
public:
  typedef const int & const_reference;
  %typemap(out) const_reference {
    ...
  }
};

```

When a typemap appears inside a namespace or class, it stays in effect until the end of the SWIG input 
(just like before). However, the typemap takes the local scope into account.   Therefore, this
code

```swig

namespace std {
  class string;
  %typemap(in) string {
    ...
  }
}

```

is really defining a typemap for the type `std::string`.   You could have code like this:

```swig

namespace std {
  class string;
  %typemap(in) string {          /* std::string */
    ...
  }
}

namespace Foo {
  class string;
  %typemap(in) string {          /* Foo::string */
    ...
  }
}

```

In this case, there are two completely distinct typemaps that apply to two completely different
types (`std::string` and `Foo::string`).

It should be noted that for scoping to work, SWIG has to know that `string` is a typename defined
within a particular namespace.  In this example, this is done using the forward class declaration `class string`.

<h2 id="Typemaps_pattern_matching">16.3 Pattern matching rules</h2>

The section describes the pattern matching rules by which C/C++ datatypes are associated with typemaps.
The matching rules can be observed in practice by using the debugging options also described.

<h3 id="Typemaps_nn17">16.3.1 Basic matching rules</h3>

Typemaps are matched using both a type and a name (typically the name of an
argument, but in the case of `out` typemaps, the name of a function,
qualified by the class name if it's a class method).  For a given ```
TYPE
NAME
``` pair, the following rules are applied, in order, to find a match.
The first typemap found is used.

- Typemaps that exactly match `TYPE` and `NAME`.
- Typemaps that exactly match `TYPE` only.
- If `TYPE` is a C++ template of type `T< TPARMS >`, where `TPARMS` are the template parameters,
    the type is stripped of the template parameters and the following checks are then made:
  

- Typemaps that exactly match `T` and `NAME`.
- Typemaps that exactly match `T` only.

If `TYPE` includes qualifiers (const, volatile, etc.), each qualifier is stripped one at a time to form a new stripped type 
and the matching rules above are repeated on the stripped type.
The left-most qualifier is stripped first, resulting in the right-most (or top-level) qualifier being stripped last.
For example `int const*const` is first stripped to `int *const` then `int *`.

If `TYPE` is an array.  The following transformation is made:

- Replace all dimensions to `[ANY]` and look for a generic array typemap.

To illustrate, suppose that you had a function like this:

```swig

int foo(const char *s);

```

To find a typemap for the argument `const char *s`, SWIG will search for the following typemaps:

```

const char *s           Exact type and name match
const char *            Exact type match
char *s                 Type and name match (qualifier stripped)
char *                  Type match (qualifier stripped)

```

When more than one typemap rule might be defined, only the first match
found is actually used.  Here is an example that
shows how some of the basic rules are applied:

```swig

%typemap(in) int *x {
  ... typemap 1
}

%typemap(in) int * {
  ... typemap 2
}

%typemap(in) const int *z {
  ... typemap 3
}

%typemap(in) int [4] {
  ... typemap 4
}

%typemap(in) int [ANY] {
  ... typemap 5
}

void A(int *x);        // int *x rule       (typemap 1)
void B(int *y);        // int * rule        (typemap 2)
void C(const int *x);  // int *x rule       (typemap 1)
void D(const int *z);  // const int *z rule (typemap 3)
void E(int x[4]);      // int [4] rule      (typemap 4)
void F(int x[1000]);   // int [ANY] rule    (typemap 5)

```

**Compatibility note:** SWIG-2.0.0 introduced stripping the qualifiers one step at a time. Prior versions
stripped all qualifiers in one step.

<h3 id="Typemaps_typedef_reductions">16.3.2 Typedef reductions matching</h3>

If no match is found using the rules in the previous section, SWIG
applies a typedef reduction to the type and repeats the typemap search
for the reduced type.   To illustrate, suppose you had code like this:

```swig

%typemap(in) int {
  ... typemap 1
}

typedef int Integer;
void blah(Integer x);

```

To find the typemap for `Integer x`, SWIG will first search for the following
typemaps:

```

Integer x
Integer

```

Finding no match, it then applies a reduction `Integer -> int` to the type and
repeats the search.

```

int x
int      --> match: typemap 1

```

Even though two types might be the same via typedef, SWIG allows typemaps to be defined 
for each typename independently.  This allows for interesting customization possibilities based
solely on the typename itself.  For example, you could write code like this:

```swig

typedef double  pdouble;     // Positive double

// typemap 1
%typemap(in) double {
  ... get a double ...
}
// typemap 2
%typemap(in) pdouble {
  ... get a positive double ...
}
double sin(double x);           // typemap 1
pdouble sqrt(pdouble x);        // typemap 2

```

When reducing the type, only one typedef reduction is applied at a
time.  The search process continues to apply reductions until a
match is found or until no more reductions can be made.

For complicated types, the reduction process can generate a long list of patterns.  Consider the following:

```swig

typedef int Integer;
typedef Integer Row4[4];
void foo(Row4 rows[10]);

```

To find a match for the `Row4 rows[10]` argument, SWIG would
check the following patterns, stopping only when it found a match:

```swig

Row4 rows[10]
Row4 [10]
Row4 rows[ANY]
Row4 [ANY]

# Reduce Row4 --> Integer[4]
Integer rows[10][4]
Integer [10][4]
Integer rows[ANY][ANY]
Integer [ANY][ANY]

# Reduce Integer --> int
int rows[10][4]
int [10][4]
int rows[ANY][ANY]
int [ANY][ANY]

```

For parameterized types like templates, the situation is even more complicated.  Suppose you had some declarations
like this:

```swig

typedef int Integer;
typedef foo<Integer, Integer> fooii;
void blah(fooii *x);

```

In this case, the following typemap patterns are searched for the argument `fooii *x`:

```swig

fooii *x
fooii *

# Reduce fooii --> foo<Integer, Integer>
foo<Integer, Integer> *x
foo<Integer, Integer> *

# Reduce Integer -> int
foo<int, Integer> *x
foo<int, Integer> *

# Reduce Integer -> int
foo<int, int> *x
foo<int, int> *

```

Typemap reductions are always applied to the left-most type that appears.  Only when no reductions can be made to the left-most
type are reductions made to other parts of the type.   This behavior means that you could define a typemap for
`foo<int, Integer>`, but a typemap for `foo<Integer, int>` would never be matched.  Admittedly, this
is rather esoteric–there's little practical reason to write a typemap quite like that.  Of course, you could rely on this
to confuse your coworkers even more.

As a point of clarification, it is worth emphasizing that typedef matching is a typedef **reduction** process only, that is, SWIG does not search for every single possible typedef.
Given a type in a declaration, it will only reduce the type, it won't build it up looking for typedefs.
For example, given the type `Struct`, the typemap below will not be used for the `aStruct` parameter,
because `Struct` is fully reduced:

```swig

struct Struct {...};
typedef Struct StructTypedef;

%typemap(in) StructTypedef { 
  ...
}

void go(Struct aStruct);

```

<h3 id="Typemaps_nn19">16.3.3 Default typemap matching rules</h3>

If the basic pattern matching rules result in no match being made, even after typedef reductions,
the default typemap matching rules are used to look for a suitable typemap match.
These rules match a generic typemap based on the reserved `SWIGTYPE` base type.
For example pointers will use `SWIGTYPE *` and references will use `SWIGTYPE&`.
More precisely, the rules are based on the C++ class template partial specialization matching rules used
by C++ compilers when looking for an appropriate partial template specialization.
This means that a match is chosen from the most specialized set of generic typemap types available. For example,
when looking for a match to `int const *`, the rules will prefer to match `SWIGTYPE const *`
if available before matching `SWIGTYPE *`, before matching `SWIGTYPE`.

Most SWIG language modules use typemaps to define the default behavior of the C primitive types.  This
is entirely straightforward.  For example, a set of typemaps for primitives marshalled by value or
const reference are written like this:

```swig

%typemap(in) int           "... convert to int ..."
%typemap(in) short         "... convert to short ..."
%typemap(in) float         "... convert to float ..."
...
%typemap(in) const int &   "... convert ..."
%typemap(in) const short & "... convert ..."
%typemap(in) const float & "... convert ..."
...

```

Since typemap matching follows all `typedef` declarations, any sort of type that is
mapped to a primitive type by value or const reference through `typedef` will be picked
up by one of these primitive typemaps.
Most language modules also define typemaps for char pointers and char arrays to handle strings,
so these non-default types will also be used in preference as the basic typemap matching rules
provide a better match than the default typemap matching rules.

Below is a list of the typical default types supplied by language modules, showing what the "in" typemap would look like:

```swig

%typemap(in) SWIGTYPE &            { ... default reference handling ...                       }
%typemap(in) SWIGTYPE *            { ... default pointer handling ...                         }
%typemap(in) SWIGTYPE *const       { ... default pointer const handling ...                   }
%typemap(in) SWIGTYPE *const&      { ... default pointer const reference handling ...         }
%typemap(in) SWIGTYPE[ANY]         { ... 1D fixed size arrays handling ...                    }
%typemap(in) SWIGTYPE []           { ... unknown sized array handling ...                     }
%typemap(in) enum SWIGTYPE         { ... default handling for enum values ...                 }
%typemap(in) const enum SWIGTYPE & { ... default handling for const enum reference values ... }
%typemap(in) SWIGTYPE (CLASS::*)   { ... default pointer member handling ...                  }
%typemap(in) SWIGTYPE              { ... simple default handling ...                          }

```

If you wanted to change SWIG's default handling for
simple pointers, you would simply redefine the rule for `SWIGTYPE *`.
Note, the simple default typemap rule is used to match against simple types that don't match any other rules:

```swig

%typemap(in) SWIGTYPE              { ... simple default handling ...                          } 

```

This typemap is important because it is the rule that gets triggered
when call or return by value is used.  For instance, if you have a
declaration like this:

```swig

double dot_product(Vector a, Vector b);

```

The `Vector` type will usually just get matched against
`SWIGTYPE`. The default implementation of `SWIGTYPE` is
to convert the value into pointers ([as described in this earlier section](SWIG/#SWIG_nn22)).

By redefining `SWIGTYPE` it may be possible to implement other
behavior.  For example, if you cleared all typemaps for
`SWIGTYPE`, SWIG simply won't wrap any unknown datatype (which might
be useful for debugging).   Alternatively, you might modify SWIGTYPE to marshal
objects into strings instead of converting them to pointers.

Let's consider an example where the following typemaps are defined and SWIG is looking for the best match for the enum shown below:

```swig

%typemap(in) const Hello &          { ... }
%typemap(in) const enum SWIGTYPE &  { ... }
%typemap(in) enum SWIGTYPE &        { ... }
%typemap(in) SWIGTYPE &             { ... }
%typemap(in) SWIGTYPE               { ... }

enum Hello {};
const Hello &hi;

```

The typemap at the top of the list will be chosen, not because it is defined first, but because it is the closest match for the type being wrapped.
If any of the typemaps in the above list were not defined, then the next one on the list would have precedence.

The best way to explore the default typemaps is to look at the ones
already defined for a particular language module.  Typemap
definitions are usually found in the SWIG library in a file such as
`java.swg`, `csharp.swg` etc.
However, for many of the target languages the typemaps are hidden behind complicated macros,
so the best way to view the default typemaps, or any typemaps for that matter, 
is to look at the preprocessed output by running `swig -E` on any interface file.
Finally the best way to view the typemap matching rules in action is via the [debugging typemap pattern matching](#Typemaps_debugging_search) options covered later on.

**Compatibility note:** The default typemap matching rules were modified in SWIG-2.0.0 from a slightly 
simpler scheme to match the current C++ class template partial specialization matching rules.

<h3 id="Typemaps_multi_argument_typemaps_patterns">16.3.4 Multi-arguments typemaps</h3>

When multi-argument typemaps are specified, they take precedence over
any typemaps specified for a single type.  For example:

```swig

%typemap(in) (char *buffer, int len) {
  // typemap 1
}

%typemap(in) char *buffer {
  // typemap 2
}

void foo(char *buffer, int len, int count); // (char *buffer, int len)
void bar(char *buffer, int blah);           // char *buffer

```

Multi-argument typemaps are also more restrictive in the way that they are matched.
Currently, the first argument follows the matching rules described in the previous section,
but all subsequent arguments must match exactly.

<h3 id="Typemaps_matching_template_comparison">16.3.5 Matching rules compared to C++ templates</h3>

For those intimately familiar with C++ templates, a comparison of the typemap matching rules and template type deduction is interesting.
The two areas considered are firstly the default typemaps and their similarities to partial template specialization and secondly, non-default typemaps and their similarities to full template specialization.

For default (SWIGTYPE) typemaps the rules are inspired by C++ class template
partial specialization. For example, given partial specialization for `T const&` :

```swig

template <typename T> struct X             { void a(); };
template <typename T> struct X< T const&> { void b(); };

```

The full (unspecialized) template is matched with most types, such as:

```swig

X< int &>            x1;  x1.a();

```

and the following all match the `T const&` partial specialization:

```swig

X< int *const&>      x2;  x2.b();
X< int const*const&> x3;  x3.b();
X< int const&>       x4;  x4.b();

```

Now, given just these two default typemaps, where T is analogous to SWIGTYPE:

```swig

%typemap(...) SWIGTYPE        { ... }
%typemap(...) SWIGTYPE const& { ... }

```

The generic default typemap `SWIGTYPE` is used with most types, such as

```swig

int &
```

and the following all match the `SWIGTYPE const&` typemap, just like the partial template matching:

```swig

int *const&
int const*const&
int const&
```

Note that the template and typemap matching rules are not identical for all default typemaps though, for example, with arrays.

For non-default typemaps, one might expect SWIG to follow the fully specialized template rules.
This is nearly the case, but not quite.
Consider a very similar example to the earlier partially specialized template but this time there is a fully specialized template:

```swig

template <typename T> struct Y       { void a(); };
template <> struct Y< int const &>  { void b(); };

```

Only the one type matches the specialized template exactly:

```swig

Y< int &>             y1;  y1.a();
Y< int *const&>       y2;  y2.a();
Y< int const *const&> y3;  y3.a();
Y< int const&>        y4;  y4.b(); // fully specialized match

```

Given typemaps with the same types used for the template declared above, where T is again analogous to SWIGTYPE:

```swig

%typemap(...) SWIGTYPE        { ... }
%typemap(...) int const&      { ... }

```

The comparison between non-default typemaps and fully specialized single parameter templates turns out to be the same, as just the one type will match the non-default typemap:

```swig

int &
int *const&
int const*const&
int const&        // matches non-default typemap int const&
```

However, if a non-const type is used instead:

```swig

%typemap(...) SWIGTYPE        { ... }
%typemap(...) int &           { ... }

```

then there is a clear difference to template matching as both the const and non-const types match the typemap:

```swig

int &             // matches non-default typemap int &
int *const&
int const*const&
int const&        // matches non-default typemap int &
```

There are other subtle differences such as typedef handling, but at least it should be clear that the typemap matching rules
are similar to those for specialized template handling.

<h3 id="Typemaps_debugging_search">16.3.6 Debugging typemap pattern matching</h3>

There are two useful debug command line options available for debugging typemaps, `-debug-tmsearch` and `-debug-tmused`.

The `-debug-tmsearch` option is a verbose option for debugging typemap searches.
This can be very useful for watching the pattern matching process in action and for debugging which typemaps are used.
The option displays all the typemaps and types that are looked for until a successful pattern match is made.
As the display includes searches for each and every type needed for wrapping, the amount of information displayed can be large.
Normally you would manually search through the displayed information for the particular type that you are interested in.

For example, consider some of the code used in the [Typedef reductions](#Typemaps_typedef_reductions) section already covered:

```swig

typedef int Integer;
typedef Integer Row4[4];
void foo(Row4 rows[10]);

```

A sample of the debugging output is shown below for the "in" typemap:

```shell

swig -perl -debug-tmsearch example.i
...
example.h:3: Searching for a suitable 'in' typemap for: Row4 rows[10]
  Looking for: Row4 rows[10]
  Looking for: Row4 [10]
  Looking for: Row4 rows[ANY]
  Looking for: Row4 [ANY]
  Looking for: Integer rows[10][4]
  Looking for: Integer [10][4]
  Looking for: Integer rows[ANY][ANY]
  Looking for: Integer [ANY][ANY]
  Looking for: int rows[10][4]
  Looking for: int [10][4]
  Looking for: int rows[ANY][ANY]
  Looking for: int [ANY][ANY]
  Looking for: SWIGTYPE rows[ANY][ANY]
  Looking for: SWIGTYPE [ANY][ANY]
  Looking for: SWIGTYPE rows[ANY][]
  Looking for: SWIGTYPE [ANY][]
  Looking for: SWIGTYPE *rows[ANY]
  Looking for: SWIGTYPE *[ANY]
  Looking for: SWIGTYPE rows[ANY]
  Looking for: SWIGTYPE [ANY]
  Looking for: SWIGTYPE rows[]
  Looking for: SWIGTYPE []
  Using: %typemap(in) SWIGTYPE []
...

```

showing that the best default match supplied by SWIG is the `SWIGTYPE []` typemap.
As the example shows, the successful match displays the used typemap source including typemap method, type and optional name in one of these simplified formats:

- `Using: %typemap(method) type name`
- `Using: %typemap(method) type name = type2 name2`
- `Using: %apply type2 name2 { type name }`

This information might meet your debugging needs, however, you might want to analyze further.
If you next invoke SWIG with the `-E` option to display the preprocessed output, and search for the particular typemap used,
you'll find the full typemap contents (example shown below for Python):

```swig

%typemap(in, noblock=1) SWIGTYPE [] (void *argp = 0, int res = 0) {
  res = SWIG_ConvertPtr($input, &argp, $descriptor, $disown |  0 );
  if (!SWIG_IsOK(res)) { 
    SWIG_exception_fail(SWIG_ArgError(res), "in method '" "$symname" "', argument "
                       "$argnum"" of type '" "$type""'"); 
  } 
  $1 = ($ltype)(argp);
}

```

The generated code for the `foo` wrapper will then contain the snippets of the typemap with the special variables expanded.
The rest of this chapter will need reading though to fully understand all of this, however, the relevant parts of the generated code for the above typemap can be seen below:

```swig

SWIGINTERN PyObject *_wrap_foo(PyObject *SWIGUNUSEDPARM(self), PyObject *args) {
...
  void *argp1 = 0 ;
  int res1 = 0 ;
...
  res1 = SWIG_ConvertPtr(obj0, &argp1, SWIGTYPE_p_a_4__int, 0 |  0 );
  if (!SWIG_IsOK(res1)) {
    SWIG_exception_fail(SWIG_ArgError(res1), "in method '" "foo" "', argument "
                       "1"" of type '" "int [10][4]""'"); 
  } 
  arg1 = (int (*)[4])(argp1);
...
}

```

Searches for multi-argument typemaps are not mentioned unless a matching multi-argument typemap does actually exist.
For example, the output for the code in the [earlier multi-arguments section](#Typemaps_multi_argument_typemaps_patterns) is as follows:

```shell

...
example.h:39: Searching for a suitable 'in' typemap for: char *buffer
  Looking for: char *buffer
  Multi-argument typemap found...
  Using: %typemap(in) (char *buffer, int len)
...

```

The second option for debugging is `-debug-tmused` and this displays the typemaps used.
This option is a less verbose version of the `-debug-tmsearch` option as it only displays each successfully found typemap on a separate single line.
The output displays the type, and name if present, the typemap method in brackets and then the actual typemap used in the same simplified format output by the `-debug-tmsearch` option.
Below is the output for the example code at the start of this section on debugging.

```shell

$ swig -perl -debug-tmused example.i
example.h:3: Typemap for Row4 rows[10] (in) : %typemap(in) SWIGTYPE []
example.h:3: Typemap for Row4 rows[10] (typecheck) : %typemap(typecheck) SWIGTYPE *
example.h:3: Typemap for Row4 rows[10] (freearg) : %typemap(freearg) SWIGTYPE []
example.h:3: Typemap for void foo (out) : %typemap(out) void

```

Now, consider the following interface file:

```swig

%module example

%{
void set_value(const char* val) {}
%}

%typemap(check) char *NON_NULL {
  if (!$1) {
    /* ... error handling ... */
  }
}

// use default pointer handling instead of strings
%apply SWIGTYPE * { const char* val, const char* another_value }

%typemap(check) const char* val = char* NON_NULL;

%typemap(arginit, noblock=1) const char* val {
  $1 = "";
}

void set_value(const char* val);

```

and the output debug:

```shell

swig -perl5 -debug-tmused example.i
example.i:21: Typemap for char const *val (arginit) : %typemap(arginit) char const *val
example.i:21: Typemap for char const *val (in) : %apply SWIGTYPE * { char const *val }
example.i:21: Typemap for char const *val (typecheck) : %apply SWIGTYPE * { char const *val }
example.i:21: Typemap for char const *val (check) : %typemap(check) char const *val = char *NON_NULL
example.i:21: Typemap for char const *val (freearg) : %apply SWIGTYPE * { char const *val }
example.i:21: Typemap for void set_value (out) : %typemap(out) void

```

The following observations about what is displayed can be noted (the same applies for `-debug-tmsearch`):

- The relevant typemap is shown, but for typemap copying, the appropriate `%typemap` or `%apply` is displayed, for example, the "check" and "in" typemaps.
- The typemap modifiers are not shown, eg the `noblock=1` modifier in the "arginit" typemap.
- The exact `%apply` statement might look different to what is in the actual code. For example, the `const char* another_value` is not shown as it is not relevant here.
Also the types may be displayed slightly differently - `char const *` and not `const char*`.

<h2 id="Typemaps_nn21">16.4 Code generation rules</h2>

This section describes rules by which typemap code is inserted into
the generated wrapper code.

<h3 id="Typemaps_nn22">16.4.1 Scope</h3>

When a typemap is defined like this:

```swig

%typemap(in) int {
  $1 = PyLong_AsLong($input);
}

```

the typemap code is inserted into the wrapper function using a new block scope.  In other words, the
wrapper code will look like this:

```swig

wrap_whatever() {
  ...
  // Typemap code
  {
    arg1 = PyLong_AsLong(obj1);
  }
  ...
}

```

Because the typemap code is enclosed in its own block, it is legal to declare temporary variables
for use during typemap execution.  For example:

```swig

%typemap(in) short {
  long temp;          /* Temporary value */
  if (Tcl_GetLongFromObj(interp, $input, &temp) != TCL_OK) {
    return TCL_ERROR;
  }
  $1 = (short) temp;
}

```

Of course, any variables that you declare inside a typemap are destroyed as soon as the typemap
code has executed (they are not visible to other parts of the wrapper function or other typemaps
that might use the same variable names).

Occasionally, typemap code will be specified using a few alternative forms.  For example:

```swig

%typemap(in) int "$1 = PyLong_AsLong($input);"
%typemap(in) int %{
$1 = PyLong_AsLong($input);
%}
%typemap(in, noblock=1) int {
$1 = PyLong_AsLong($input);
}

```

These three forms are mainly used for cosmetics–the specified code is not enclosed inside
a block scope when it is emitted.   This sometimes results in a less complicated looking wrapper function.
Note that only the third of the three typemaps have the typemap code passed through the SWIG preprocessor.

<h3 id="Typemaps_nn23">16.4.2 Declaring new local variables</h3>

Sometimes it is useful to declare a new local variable that exists
within the scope of the entire wrapper function.  A good example of this
might be an application in which you wanted to marshal strings.   Suppose
you had a C++ function like this

```swig

int foo(std::string *s);

```

and you wanted to pass a native string in the target language as an argument.   For instance,
in Perl, you wanted the function to work like this:

```

$x = foo("Hello World");

```

To do this, you can't just pass a raw Perl string as the `std::string *` argument. 
Instead, you have to create a temporary `std::string` object, copy the Perl string data into it, and
then pass a pointer to the object.   To do this, simply specify the typemap with an extra parameter like this:

```swig

%typemap(in) std::string * (std::string temp) {
  unsigned int len;
  char        *s;
  s = SvPV($input, len);         /* Extract string data */
  temp.assign(s, len);           /* Assign to temp */
  $1 = &temp;                   /* Set argument to point to temp */
}

```

In this case, `temp` becomes a local variable in
the scope of the entire wrapper function.  For example:

```swig

wrap_foo() {
  std::string temp;    <--- Declaration of temp goes here
  ...

  /* Typemap code */
  {
    ...
    temp.assign(s, len);
    ...
  }
  ...
}

```

When you set `temp` to a value, it
persists for the duration of the wrapper function and gets
cleaned up automatically on exit.

It is perfectly safe to use more than one typemap involving local
variables in the same declaration. For example, you could declare a
function as :

```swig

void foo(std::string *x, std::string *y, std::string *z);

```

This is safely handled because SWIG actually renames all local
variable references by appending an argument number suffix.  Therefore, the
generated code would actually look like this:

```swig

wrap_foo() {
  int *arg1;    /* Actual arguments */
  int *arg2;
  int *arg3;
  std::string temp1;    /* Locals declared in the typemap */
  std::string temp2;
  std::string temp3;
  ...
  {
    char *s;
    unsigned int len;
    ...
    temp1.assign(s, len);
    arg1 = *temp1;
  }
  {
    char *s;
    unsigned int len;
    ...
    temp2.assign(s, len);
    arg2 = &temp2;
  }
  {
    char *s;
    unsigned int len;
    ...
    temp3.assign(s, len);
    arg3 = &temp3;
  }
  ...
}

```

There are two exceptions: First, if the variable name starts with the `_global_` prefix,
the argument number is not appended. Such variables can be used throughout the generated
wrapper function. For example, the above typemap could be rewritten to use `_global_temp`
instead of `temp` and the generated code would then contain a single `_global_temp` variable
instead of `temp1`, `temp2` and `temp3`:

```swig

%typemap(in) std::string * (std::string _global_temp) {
 ... as above ...
}

```

The second exception occurs if the local variable name contains the special variable `$n` in the variable name.
Special variables are covered in the next section, but simply the `$n` special variable is expanded to a unique parameter name, such as `arg1`, `arg2` etc.
As this special variable already contains a unique name, there is no further need to append an argument number suffix to make the temporary variable name unique.
So in the example below, `$1_temp` is typically expanded to `arg1_temp`, `arg2_temp` etc depending on which argument the typemap is being used for:

```swig

%typemap(in) std::string * (std::string $1_temp) {
 ... as above ...
}

```

**Compatibility note:** Support for `$n` expansion in typemap local variable names was added in SWIG-4.4.0.

**Note:**

Some typemaps do not recognize local variables (or they may simply not
apply). At this time, only typemaps that apply to argument conversion support this (input typemaps such as the "in" typemap).

When declaring a typemap for multiple types, 
each type must have its own local variable declaration.

```swig

%typemap(in) const std::string *, std::string * (std::string temp) // NO!
// only std::string * has a local variable
// const std::string * does not (oops)
....

%typemap(in) const std::string * (std::string temp), std::string * (std::string temp) // Correct
....

```

<h3 id="Typemaps_special_variables">16.4.3 Special variables</h3>

Special variables are prefixed with a `$` and are expanded by SWIG as part of the code generation process.

<h4 id="Typemaps_type_special_variables">16.4.3.1 Type related special variables</h4>

Within all typemaps, the following special variables are expanded.
These are related in some way to a typemap's type.
This is by no means a complete list as some target languages have additional special variables which are documented in the language specific chapters.

| Variable | Meaning | 
|---|---|
| $*n* |  A C local variable corresponding to type *n* in the typemap pattern.  | 
| $argnum | Argument number.  Only available in typemaps related to argument conversion | 
| $*n*_name | Argument name | 
| $*n*_type | Real C datatype of type *n*. | 
| $*n*_ltype | ltype of type *n* | 
| $*n*_mangle | Mangled form of type *n*.  For example `_p_Foo` | 
| $*n*_descriptor | Type descriptor structure for type *n*.  For example `SWIGTYPE_p_Foo`.  This is primarily used when interacting with the run-time type checker (described later). | 
| $**n*_type | Real C datatype of type *n* with one pointer removed. | 
| $**n*_ltype | ltype of type *n* with one pointer removed. | 
| $**n*_mangle | Mangled form of type *n* with one pointer removed.  | 
| $**n*_descriptor | Type descriptor structure for type *n* with one pointer removed.  |
| $&*n*_type | Real C datatype of type *n* with one pointer added. | 
| $&*n*_ltype | ltype of type *n* with one pointer added. | 
| $&*n*_mangle | Mangled form of type *n* with one pointer added. | 
| $&*n*_descriptor | Type descriptor structure for type *n* with one pointer added.  |
| $*n*_basetype | Base typename with all pointers and qualifiers stripped.  | 

**Table:** Typemap type related special variables

Within the table, $*n* refers to a specific type within the typemap specification.  For example,
if you write this

```swig

%typemap(in) int *INPUT {

}

```

then $1 refers to `int *INPUT`.  If you have a typemap like this,

```swig

%typemap(in) (int argc, char *argv[]) {
  ...
}

```

then $1 refers to `int argc` and $2 refers to `char *argv[]`.

Substitutions related to types and names always fill in values from the actual code that was matched.
This is useful when a typemap might match multiple C datatype.  For example:

```swig

%typemap(in)  int, short, long {
  $1 = ($1_ltype) PyLong_AsLong($input);
}

```

In this case, `$1_ltype` is replaced with the datatype that is actually matched.

When typemap code is emitted, the C/C++ datatype of the special variables `$1` and 
`$2` is always an "ltype."   An "ltype" is simply a type that can legally appear
on the left-hand side of a C assignment operation.   Here are a few examples of types
and ltypes:

```

type              ltype
------            ----------------
int               int
const int         int
const int *       int *
int [4]           int *
int [4][5]        int (*)[5]

```

In most cases a ltype is simply the C datatype with qualifiers stripped off.  In addition,
arrays are converted into pointers.

Variables such as `$&1_type` and `$*1_type` are used to
safely modify the type by removing or adding pointers.  Although not
needed in most typemaps, these substitutions are sometimes needed to properly
work with typemaps that convert values between pointers and values.

If necessary, type related substitutions can also be used when declaring locals.  For example:

```swig

%typemap(in) int * ($*1_type temp) {
  temp = PyLong_AsLong($input);
  $1 = &temp;
}

```

There is one word of caution about declaring local variables in this manner. If you declare a local variable
using a type substitution such as `$1_ltype temp`, it won't work like you expect for arrays and certain
kinds of pointers.   For example, if you wrote this,

```swig

%typemap(in) int [10][20] {
  $1_ltype temp;
}

```

then the declaration of `temp` will be expanded as

```swig

int (*)[20] temp;

```

This is illegal C syntax and won't compile.  There is currently no
straightforward way to work around this problem in SWIG due to the way
that typemap code is expanded and processed.  However, one possible workaround
is to simply pick an alternative type such as `void *` and use
casts to get the correct type when needed.  For example:

```swig

%typemap(in) int [10][20] {
  void *temp;
  ...
  (($1_ltype) temp)[i][j] = x;    /* set a value */
  ...
}

```

Another approach, which only works for arrays is to use the `$1_basetype` substitution.  For example:

```swig

%typemap(in) int [10][20] {
  $1_basetype temp[10][20];
  ...
  temp[i][j] = x;    /* set a value */
  ...
}

```

<h4 id="Typemaps_non_type_special_variables">16.4.3.2 Non-type related special variables</h4>

The following are additional special variables.
These are not specifically related to a typemap's type.

| Variable | Meaning | 
|---|---|
| $*isvoid* |  Expands to 1 if the wrapped function has a void return, otherwise expands to 0. Note that it expands to 1 in destructors and 0 in constructors.  | 
| $*isvoidresult* |  The same as `$isvoid`, plus it also expands to 1 when the ["out"](#Typemaps_nn28) typemap declares `numoutputs=0` to suppress a non void return value. It therefore expands to 1 whenever the wrapped function returns no value of its own, rather than just when the C++ return type is void. Use it in place of `$isvoid` where what matters is whether there is a value for the ["argout"](#Typemaps_nn32) typemaps to append to, such as in a target language's `SWIG_AppendOutput` macro.  | 
| $*symname* |  Name of function/method being wrapped.  | 

**Table:** Non-type related special variables

<h3 id="Typemaps_special_variable_macros">16.4.4 Special variable macros</h3>

Special variable macros are like macro functions in that they take one or more input arguments 
which are used for the macro expansion. 
They look like macro/function calls but use the special variable `$` prefix to the macro name. 
Note that unlike normal macros, the expansion is not done by the preprocessor, 
it is done during the SWIG parsing/compilation stages. 
The following special variable macros are available across all language modules.

<h4 id="Typemaps_special_macro_descriptor">16.4.4.1 $descriptor(type)</h4>

This macro expands into the type descriptor structure for any C/C++ type specified in `type`.
It behaves like the `$1_descriptor` special variable described above except that the type to expand is 
taken from the macro argument rather than inferred from the typemap type. 
For example, `$descriptor(std::vector<int> *)` will expand into `SWIGTYPE_p_std__vectorT_int_t`.
This macro is mostly used in the scripting target languages and is demonstrated later in the [Run-time type checker usage](#Typemaps_runtime_type_checker_usage) section.

<h4 id="Typemaps_special_macro_typemap">16.4.4.2 $typemap(method, typepattern)</h4>

This macro uses the [pattern matching rules](#Typemaps_pattern_matching) described earlier to lookup and 
then substitute the special variable macro with the body of the matched typemap.
The typemap to search for is specified by the arguments, where `method` is the typemap method name and 
`typepattern` is a type pattern as per the `%typemap` specification in the [Defining a typemap](#Typemaps_defining) section.

The special variables within the matched typemap are expanded into those for the matched typemap type, 
not the typemap within which the macro is called.
In practice, there is little use for this macro in the scripting target languages.
It is mostly used in the target languages that are statically typed as a way to obtain the target language type given the C/C++ type and more commonly only when the C++ type is a template parameter.

The example below is for C# only and uses some typemap method names documented in the C# chapter, but it shows some of the possible syntax variations.

```swig

%typemap(cstype) unsigned long    "uint"
%typemap(cstype) unsigned long bb "bool"
%typemap(cscode) BarClass %{
  void foo($typemap(cstype, unsigned long aa) var1,
           $typemap(cstype, unsigned long bb) var2,
           $typemap(cstype, (unsigned long bb)) var3,
           $typemap(cstype, unsigned long) var4)
  {
    // do something
  }
%}

```

The result is the following expansion

```swig

%typemap(cstype) unsigned long    "uint"
%typemap(cstype) unsigned long bb "bool"
%typemap(cscode) BarClass %{
  void foo(uint var1,
           bool var2,
           bool var3,
           uint var4)
  {
    // do something
  }
%}

```

<h4 id="Typemaps_special_macro_typemap_attribute">16.4.4.3 $typemap(method:attribute, typepattern)</h4>

An enhanced version of `$typemap` provides access to typemap attributes by
appending a colon and the attribute name after the method name. In the example below,
"cstype" is the typemap method and "out" is the typemap attribute.

```swig

%typemap(cstype, out="object") XClass "XClass"
%typemap(cscode) BarClass %{
  $typemap(cstype:out, XClass) bar()
  {
    return null;
  }

```

which expands to

```swig

  object bar()
  {
    return null;
  }

```

**Compatibility note:** Support for typemap attributes in `$typemap`
was introduced in SWIG-4.1.0.

<h3 id="Typemaps_special_variable_attributes">16.4.5 Special variables and typemap attributes</h3>

As of SWIG-3.0.7 typemap attributes will also expand special variables and special variable macros.

Example usage showing the expansion in the 'out' attribute (C# specific) as well as the main typemap body:

```swig

%typemap(ctype, out="$*1_ltype") unsigned int& "$*1_ltype"

```

is equivalent to the following as `$*1_ltype` expands to `unsigned int`:

```swig

%typemap(ctype, out="unsigned int") unsigned int& "unsigned int"

```

<h3 id="Typemaps_special_variables_and_macros">16.4.6 Special variables combined with special variable macros</h3>

Special variables can also be used within special variable macros.
The special variables are expanded before they are used in the special variable macros.

Consider the following C# typemaps:

```swig

%typemap(cstype) unsigned int "uint"
%typemap(cstype, out="$typemap(cstype, $*1_ltype)") unsigned int& "$typemap(cstype, $*1_ltype)"

```

Special variables are expanded first and hence the above is equivalent to:

```swig

%typemap(cstype) unsigned int "uint"
%typemap(cstype, out="$typemap(cstype, unsigned int)") unsigned int& "$typemap(cstype, unsigned int)"

```

which then expands to:

```swig

%typemap(cstype) unsigned int "uint"
%typemap(cstype, out="uint") unsigned int& "uint"

```

<h3 id="Typemaps_copy_special_variable_macro">16.4.7 Using $typemap for copying typemaps</h3>

The `$typemap` special variable macro can be used to copy entire typemaps or parts thereof.
Consider the existence of the following named typemap:

```swig

%typemap(ctype, out="void *") unsigned short & MYMAP "unsigned short *"

```

The best and simplest way to [copy a typemap](Typemaps/#Typemaps_nn13) in its entirety, say for use everywhere an `unsigned short&` is parsed is:

```swig

%typemap(ctype) unsigned short & = unsigned short & MYMAP;

```

A naive approach to copying the typemap via the `$typemap` special variable could be:

```swig

%typemap(ctype) unsigned short & "$typemap(ctype, unsigned short & MYMAP)"

```

However, it is incorrect in this case as the new typemap only copies the typemap body from `MYMAP`
and is missing the typemap attributes from the original. It is actually just the same as:

```swig

%typemap(ctype) unsigned short & "unsigned short *"

```

The typemap attributes need copying as well. There is only one attribute in this case, so a full *typemap copy equivalent* is:

```swig

%typemap(ctype, out="$typemap(ctype:out, unsigned short & MYMAP)") unsigned short & "$typemap(ctype, unsigned short & MYMAP)"

```

Generally one would only use `$typemap` as a way to copy another typemap and then tweak it slightly.
For example in this case we could use the original typemap body and use a different "out" attribute as follows:

```swig

%typemap(ctype, out="unsigned int *") unsigned short & "$typemap(ctype, unsigned short & MYMAP)"

```

This technique can be used to use an existing or default typemap and then say append or prepend some code.
Consider the `bool` "in" typemap shipped with SWIG for C#:

```swig

%typemap(in) bool %{ $1 = $input ? true : false; %}

```

The following creates a new typemap which re-uses the above typemap body and adds some simple "printf" logging.
It effectively replaces the default typemap shipped with SWIG.

```swig

%typemap(in) bool NAMED_DEFAULT = bool;
%typemap(in) bool %{
  /* custom typemap */
  $typemap(in, bool NAMED_DEFAULT)
  printf("bool input value: %s\n", $1 ? "true" : "false");
%}

void bool_input(bool flag);

```

The relevant snippet of generated code for C# when wrapping the `bool_input` method shown are the last three lines of the generated code:

```swig

SWIGEXPORT void SWIGSTDCALL CSharp_bool_input(unsigned int jarg1) {
  bool arg1 ;

  /* logging typemap */
  arg1 = jarg1 ? true : false;
  printf("bool input value: %s\n", arg1 ? "true" : "false");

```

The `NAMED_DEFAULT` intermediate/temporary typemap copy is a trick required to avoid a recursive lookup error

```shell

Error: Likely recursive $typemap calls containing $typemap(in, bool). Use -debug-tmsearch to debug.

```

caused if used as follows:

```swig

%typemap(in) bool %{
  /* logging typemap */
  $typemap(in, bool)
  printf("bool input value: %s\n", $1 ? "true" : "false");
%}

```

because `$typemap(in, bool)` is attempting to copy itself.

<h2 id="Typemaps_nn25">16.5 Common typemap methods</h2>

The family of typemaps recognized by a language module may vary.  However,
the following typemap methods are nearly universal:

<h3 id="Typemaps_nn26">16.5.1 "in" typemap</h3>

The "in" typemap is used to convert function arguments from the target language
to C.  For example:

```swig

%typemap(in) int {
  $1 = PyLong_AsLong($input);
}

```

The following additional special variables are available:

```swig

$input            - Input object holding value to be converted.

```

This is probably the most commonly redefined typemap because it can be used
to implement customized conversions.

In addition, the "in" typemap allows the number of converted arguments to be
specified.  The `numinputs` attributes facilitates this. For example:

```swig

// Ignored argument.
%typemap(in, numinputs=0) int *out (int temp) {
  $1 = &temp;
}

```

At this time, only zero or one arguments may be converted. 
When `numinputs` is set to 0, the argument is effectively ignored and cannot be supplied from the target language. 
The argument is still required when making the C/C++ call and the above typemap
shows the value used is instead obtained from a locally declared variable called `temp`.
Usually `numinputs` is not specified, whereupon the default value is 1, that is, there is a one to one mapping of the number of arguments when used from the target language to the C/C++ call. 
[Multi-argument typemaps](#Typemaps_multi_argument_typemaps) provide a similar concept where the number of arguments mapped from the target language to C/C++ can be changed for multiple adjacent C/C++ arguments.

<h3 id="Typemaps_nn27">16.5.2 "typecheck" typemap</h3>

The "typecheck" typemap is used to support overloaded functions and methods.  It merely checks an argument
to see whether or not it matches a specific type.  For example:

```swig

%typemap(typecheck, precedence=SWIG_TYPECHECK_INTEGER) int {
  $1 = PyLong_Check($input) ? 1 : 0;
}

```

For typechecking, the $1 variable is always a simple integer that is set to 1 or 0 depending on whether or not
the input argument is the correct type.
Set to 1 if the input argument is the correct type otherwise set to 0.

If you define new "in" typemaps *and* your program uses overloaded methods, you should also define a collection of
"typecheck" typemaps.  More details about this follow in the [Typemaps and overloading](#Typemaps_overloading) section.

<h3 id="Typemaps_nn28">16.5.3 "out" typemap</h3>

The "out" typemap is used to convert function/method return values from C
into the target language.  For example:

```swig

%typemap(out) int {
  $result = PyLong_FromLong($1);
}

```

The following additional special variables are available.

```swig

$result           - Result object returned to target language.

```

The "out" typemap supports an optional attribute flag called "optimal". This is for code optimisation and is detailed in the [Optimal code generation when returning by value](#Typemaps_optimal) section.

The "out" typemap also supports the `numoutputs` attribute, which says how many values
the typemap returns to the target language. It defaults to 1 and the only other supported value
is 0, meaning the function return value is not returned to the target language at all. This is
useful for a C function that signals errors through its return value, where the error is turned
into an exception and only the ["argout"](#Typemaps_nn32) values are of interest:

```swig

%typemap(out, numoutputs=0) MyErr ""

%typemap(ret) MyErr %{
  if ($1 != 0) {
    PyErr_Format(PyExc_RuntimeError, "error code %d", (int)$1);
    SWIG_fail;
  }
%}

%apply int *OUTPUT { int *out };

MyErr get_value(int *out);

```

Without `numoutputs=0` the wrapped function returns a list containing the suppressed
return value followed by the value of `out`. With it, only the value of `out` is
returned. The typemap does not have to set `$result` when `numoutputs=0` is used.

**Note:** The `numoutputs` attribute is only supported by the scripting languages (not
the statically typed languages, such as Java) that generate accurate type information for what a
wrapped function returns, such as the Python
[PEP 484 annotations](Python/#Python_annotations). In such a target language it
suppresses the return value in the generated wrapper as well as leaving the function return type
out of the type information. Other target languages ignore the attribute.

<h3 id="Typemaps_nn29">16.5.4 "arginit" typemap</h3>

The "arginit" typemap is used to set the initial value of a function
argument–before any conversion has occurred.   This is not normally
necessary, but might be useful in highly specialized applications.
For example:

```swig

// Set argument to NULL before any conversion occurs
%typemap(arginit) int *data {
  $1 = NULL;
}

```

<h3 id="Typemaps_nn30">16.5.5 "default" typemap</h3>

The "default" typemap is used to turn an argument into a default
argument.   For example:

```swig

%typemap(default) int flags {
  $1 = DEFAULT_FLAGS;
}
...
int foo(int x, int y, int flags);

```

The primary use of this typemap is to either change the wrapping of
default arguments or specify a default argument in a language where
they aren't supported (like C). Target languages that do not support
optional arguments, such as Java and C#, effectively ignore the value specified
by this typemap as all arguments must be given.

Once a default typemap has been applied to an argument, all arguments
that follow must have default values.
See the [Default/optional arguments](SWIG/#SWIG_default_args) section
for further information on default argument wrapping.

<h3 id="Typemaps_nn31">16.5.6 "check" typemap</h3>

The "check" typemap is used to supply value checking code during argument
conversion.  The typemap is applied *after* arguments have been
converted.  For example:

```swig

%typemap(check) int positive {
  if ($1 <= 0) {
    SWIG_exception(SWIG_ValueError, "Expected positive value.");
  }
}

```

<h3 id="Typemaps_nn32">16.5.7 "argout" typemap</h3>

The "argout" typemap is used to return values from arguments.  This
is most commonly used to write wrappers for C/C++ functions that need
to return multiple values.   The "argout" typemap is almost always combined
with an "in" typemap—possibly to ignore the input value.  For example:

```swig

/* Set the input argument to point to a temporary variable */
%typemap(in, numinputs=0) int *out (int temp) {
  $1 = &temp;
}

%typemap(argout) int *out {
  // Append output value $1 to $result
  ...
}

```

The following additional special variables are available.

```

$result           - Result object returned to target language.
$input            - The original input object passed.

```

The code in the "argout" typemap is always generated after
the code in the "out" typemap.  If multiple return values are used, the extra
return values are often appended to return value of the function.

Appending is a convention, not a requirement. An "argout" typemap is free to check an error
code and return nothing, or to discard `$result` and replace it with something else.
SWIG cannot tell which of these a typemap does by looking at the code, so three optional
attributes are provided to say so.

The `numoutputs` attribute says how many values the typemap returns. It defaults to 1
and the only other supported value is 0, for a typemap that returns nothing:

```swig

%typemap(argout, numoutputs=0) int *ERRCHECK {
  if (*$1 != 0) {
    /* turn the error code into an exception */
    SWIG_exception_fail(SWIG_RuntimeError, "call failed");
  }
}

```

The `overwrite` attribute marks a typemap that replaces `$result` instead of
appending to it, discarding everything returned before it, including the function return value:

```swig

%typemap(argout, overwrite=1) (void *rbuffer, size_t len) {
  Py_DecRef($result);   /* Blow away any previous result */
  $result = PyBytes_FromStringAndSize((char *)$1, result);
  free($1);
}

```

The `container` attribute says what the typemap appends into when more than one value is
returned. It defaults to `"list"`, which is what `SWIG_AppendOutput` builds for most
target languages. Use `"tuple"` for a typemap that appends into a fixed size sequence
instead, using a replacement for `SWIG_AppendOutput`:

```swig

%typemap(argout, container="tuple") short *OutTuple {
  $result = MyTupleAppend($result, PyLong_FromLong(*$1), $isvoidresult);
}

```

The attribute names the container, it does not have to be one the target language knows about.
A target language annotates the containers it understands and uses its catch-all type for any
other container named, so `container="str"` for a typemap appending characters to a string is
accepted but will result in the catch-all type being used.

The container is a property of the whole wrapped function, as all the "argout" typemaps append
into the same `$result`. If the "argout" typemaps used for any one function disagree on the type of container to append to,
there is a conflict and a catch-all type is used for the return type instead (`typing.Any` in the case
of Python). [Warning 478](Warnings/#Warnings_nn13) is issued when this happens:

```shell

example.i:12: Warning 478: The argout typemaps for 'clash' append into different containers,
'list' and 'tuple', so the type of the values returned cannot be worked out and a catch-all
type is used for the return type instead. Check the container attribute in each argout typemap
used by this function, noting that it defaults to 'list'.

```

The warning says that SWIG cannot work the type out, not that there is no type, so a target
language may offer a way to supply it by hand - see
[Annotations for argout typemaps](Python/#Python_annotations_argout) for Python.

On a typemap also using `overwrite=1` the attribute names the container the typemap
assigns to `$result`, rather than one it appends into:

```swig

%typemap(argout, overwrite=1, container="tuple") short *OutTupleReplace {
  Py_XDECREF($result);
  $result = PyTuple_New(1);
  PyTuple_SET_ITEM($result, 0, PyLong_FromLong(*$1));
}

```

Both kinds of typemap put two or more returned values in the container they name, so there is
nothing to choose between them when a function returns several values:

```swig

void two_appended(short *OutTuple, short *OutTuple2);                 // -> "typing.Tuple[int, int]"
void assigned_then_appended(short *OutTupleReplace, short *OutTuple); // -> "typing.Tuple[int, int]"

```

They differ when the typemap supplies the only value a function returns. Appending combines a
new value with whatever `$result` holds already, so with nothing there to combine with,
a replacement for `SWIG_AppendOutput` conventionally makes `$result` that one
value and does not build a container at all. This is what `MyTupleAppend` above does when
`$isvoidresult` tells it there is no result yet. An overwriting typemap makes no such
decision: its own code calls `PyTuple_New` every time it runs, so one value is in a
tuple just as several would be:

```swig

void one_appended(short *OutTuple);        // -> "int"
void one_assigned(short *OutTupleReplace); // -> "typing.Tuple[int]"

```

So `container` on an appending typemap says what the typemap appends into when it has
something to append to, and on an overwriting typemap it says what the typemap always builds.

The default of `"list"` is for appending. Leaving the attribute off an overwriting
typemap says something different: that the type of the value already describes everything the
typemap assigns, and no further container wraps it. This is the usual case, as an overwriting
typemap is normally described by a type for the object it assigns. A typemap assigning a list of
integers is `typing.List[int]`, not a list holding that list.

**Note:** These attributes are only needed for target languages that generate accurate type
information for what a wrapped function returns, such as the Python
[PEP 484 annotations](Python/#Python_annotations). They do not change the
generated wrapper code, so a target language without such support ignores them and adding them
to a typemap is harmless.

See the `typemaps.i` library file for examples.

<h3 id="Typemaps_nn33">16.5.8 "freearg" typemap</h3>

The "freearg" typemap is used to cleanup argument data.  It is only
used when an argument might have allocated resources that need to be
cleaned up when the wrapper function exits.  The "freearg" typemap
usually cleans up argument resources allocated by the "in" typemap.  
For example:

```swig

// Get a list of integers
%typemap(in) int *items {
  int nitems = Length($input);
  $1 = (int *) malloc(sizeof(int)*nitems);
}
// Free the list 
%typemap(freearg) int *items {
  free($1);
}

```

The "freearg" typemap inserted at the end of the wrapper function,
just before control is returned back to the target language.  This
code is also placed into a special variable `$cleanup` that may
be used in other typemaps whenever a wrapper function needs to abort
prematurely.

<h3 id="Typemaps_nn34">16.5.9 "newfree" typemap</h3>

The "newfree" typemap is used in conjunction with the `%newobject`
directive and is used to deallocate memory used by the return result 
of a function.  For example:

```swig

%typemap(newfree) string * {
  delete $1;
}
%typemap(out) string * {
  $result = PyUnicode_FromString($1->c_str());
}
...

%newobject foo;
...
string *foo();

```

See [Object ownership and %newobject](Customization/#Customization_ownership) for further details.

<h3 id="Typemaps_ret">16.5.10 "ret" typemap</h3>

The "ret" typemap is not used very often, but can be useful for anything associated with
the return type, such as resource management, return value error checking, etc.
Usually this can all be done in the "out" typemap, but sometimes it is handy to use the
"out" typemap code untouched and add to the generated code using the code in the "ret" typemap.
One such case is memory clean up. For example, a `stringheap_t` type is defined indicating
that the returned memory must be deleted and a `string_t` type is defined indicating
that the returned memory must not be deleted.

```swig

%typemap(ret) stringheap_t %{
  free($1);
%}

typedef char * string_t;
typedef char * stringheap_t;

string_t MakeString1();
stringheap_t MakeString2();

```

The "ret" typemap above will only be used for `MakeString2`, but both functions
will use the default "out" typemap for `char *` provided by SWIG.
The code above would ensure the appropriate memory is freed in all target languages as the need
to provide custom "out" typemaps (which involve target language specific code) is not necessary.

This approach is an alternative to using the "newfree" typemap and `%newobject` as there
is no need to list all the functions that require the memory cleanup, it is purely done on types.

<h3 id="Typemaps_nn35">16.5.11 "memberin" typemap</h3>

The "memberin" typemap is used to copy data from *an already converted input value*
into a structure member.  It is typically used to handle array members and other special
cases.  For example:

```swig

%typemap(memberin) int [4] {
  memmove($1, $input, 4*sizeof(int));
}

```

It is rarely necessary to write "memberin" typemaps—SWIG already provides
a default implementation for arrays, strings, and other objects.

<h3 id="Typemaps_nn36">16.5.12 "varin" typemap</h3>

The "varin" typemap is used to convert objects in the target language to C for the
purposes of assigning to a C/C++ global variable.    This is implementation specific.

<h3 id="Typemaps_nn37">16.5.13 "varout" typemap</h3>

The "varout" typemap is used to convert a C/C++ object to an object in the target
language when reading a C/C++ global variable.  This is implementation specific.

<h3 id="Typemaps_throws_typemap">16.5.14 "throws" typemap</h3>

The "throws" typemap is only used when SWIG parses a C++ method with an exception specification or has the `%catches` feature attached to the method (see [Exception handling with %catches](SWIGPlus/#SWIGPlus_catches)).
It provides a default mechanism for handling C++ methods that have declared the exceptions they will throw.
The purpose of this typemap is to convert a C++ exception into an error or exception in the target language.
It is slightly different to the other typemaps as it is based around the exception type rather than the type of a parameter or variable.
For example:

```swig

%typemap(throws) const char * %{
  PyErr_SetString(PyExc_RuntimeError, $1);
  SWIG_fail;
%}

// Either an exception specification on the method
  void bar() throw (const char *);

// Or a %catches feature attached to the method
  %catches(const char *) bar();
  void bar();

```

As can be seen from the resulting generated code below, SWIG generates an exception handler
when wrapping the `bar` function with the catch block comprising the "throws" typemap content.

```swig

...
try {
  bar();
} catch(char const *_e) {
  PyErr_SetString(PyExc_RuntimeError, _e);
  SWIG_fail;
}
...

```

Note that if your methods do not have an exception specification but they do throw exceptions and you are not using `%catches`, SWIG cannot know how to deal with them.
Please also see the [Exception handling with %exception](Customization/#Customization_exception) section for another way to handle exceptions.

<h2 id="Typemaps_nn39">16.6 Some typemap examples</h2>

This section contains a few examples.  Consult language module documentation
for more examples.

<h3 id="Typemaps_nn40">16.6.1 Typemaps for arrays</h3>

A common use of typemaps is to provide support for C arrays appearing both as
arguments to functions and as structure members.

For example, suppose you had a function like this:

```swig

void set_vector(int type, float value[4]);

```

If you wanted to handle `float value[4]` as a list of floats, you might write a typemap
similar to this:

```swig

%typemap(in) float value[4] (float temp[4]) {
  int i;
  if (!PySequence_Check($input)) {
    PyErr_SetString(PyExc_ValueError, "Expected a sequence");
    SWIG_fail;
  }
  if (PySequence_Length($input) != 4) {
    PyErr_SetString(PyExc_ValueError, "Size mismatch. Expected 4 elements");
    SWIG_fail;
  }
  for (i = 0; i < 4; i++) {
    PyObject *o = PySequence_GetItem($input, i);
    if (PyNumber_Check(o)) {
      temp[i] = (float) PyFloat_AsDouble(o);
    } else {
      PyErr_SetString(PyExc_ValueError, "Sequence elements must be numbers");      
      SWIG_fail;
    }
  }
  $1 = temp;
}

```

In this example, the variable `temp` allocates a small array on the
C stack.  The typemap then populates this array and passes it to the underlying C function.

When used from Python, the typemap allows the following type of function call:

```
>>> set_vector(type, [ 1, 2.5, 5, 20 ])

```

If you wanted to generalize the typemap to apply to arrays of all dimensions you might write this:

```swig

%typemap(in) float value[ANY] (float temp[$1_dim0]) {
  int i;
  if (!PySequence_Check($input)) {
    PyErr_SetString(PyExc_ValueError, "Expected a sequence");
    SWIG_fail;
  }
  if (PySequence_Length($input) != $1_dim0) {
    PyErr_SetString(PyExc_ValueError, "Size mismatch. Expected $1_dim0 elements");
    SWIG_fail;
  }
  for (i = 0; i < $1_dim0; i++) {
    PyObject *o = PySequence_GetItem($input, i);
    if (PyNumber_Check(o)) {
      temp[i] = (float) PyFloat_AsDouble(o);
    } else {
      PyErr_SetString(PyExc_ValueError, "Sequence elements must be numbers");      
      SWIG_fail;
    }
  }
  $1 = temp;
}

```

In this example, the special variable `$1_dim0` is expanded with the actual
array dimensions.   Multidimensional arrays can be matched in a similar manner.  For example:

```swig

%typemap(in) float matrix[ANY][ANY] (float temp[$1_dim0][$1_dim1]) {
  ... convert a 2d array ...
}

```

For large arrays, it may be impractical to allocate storage on the stack using a temporary variable
as shown.   To work with heap allocated data, the following technique can be used.

```swig

%typemap(in) float value[ANY] {
  int i;
  if (!PySequence_Check($input)) {
    PyErr_SetString(PyExc_ValueError, "Expected a sequence");
    SWIG_fail;
  }
  if (PySequence_Length($input) != $1_dim0) {
    PyErr_SetString(PyExc_ValueError, "Size mismatch. Expected $1_dim0 elements");
    SWIG_fail;
  }
  $1 = (float *) malloc($1_dim0*sizeof(float));
  for (i = 0; i < $1_dim0; i++) {
    PyObject *o = PySequence_GetItem($input, i);
    if (PyNumber_Check(o)) {
      $1[i] = (float) PyFloat_AsDouble(o);
    } else {
      free($1);
      PyErr_SetString(PyExc_ValueError, "Sequence elements must be numbers");
      SWIG_fail;
    }
  }
}
%typemap(freearg) float value[ANY] {
  free($1);
}

```

In this case, an array is allocated using `malloc`.   The `freearg` typemap is then used
to release the argument after the function has been called.

Another common use of array typemaps is to provide support for array structure members.
Due to subtle differences between pointers and arrays in C, you can't just "assign" to
a array structure member.  Instead, you have to explicitly copy elements into the array.
For example, suppose you had a structure like this:

```swig

struct SomeObject {
  float  value[4];
  ...
};

```

When SWIG runs, it won't produce any code to set the `vec` member.
You may even get a warning message like this:

```shell

$ swig -python  example.i
example.i:10: Warning 462: Unable to set variable of type float [4].

```

These warning messages indicate that SWIG does not know how you want
to set the `vec` field.

To fix this, you can supply a special "memberin" typemap like this:

```swig

%typemap(memberin) float [ANY] {
  int i;
  for (i = 0; i < $1_dim0; i++) {
      $1[i] = $input[i];
  }
}

```

The memberin typemap is used to set a structure member from data that has already been converted
from the target language to C.  In this case, `$input` is the local variable in which 
converted input data is stored.   This typemap then copies this data into the structure.

When combined with the earlier typemaps for arrays, the combination of the "in" and "memberin" typemap allows
the following usage:

```
>>> s = SomeObject()
>>> s.x = [1, 2.5, 5, 10]

```

Related to structure member input, it may be desirable to return structure members as a new kind of
object.  For example, in this example, you will get very odd program behavior where the structure member
can be set nicely, but reading the member simply returns a pointer:

```
>>> s = SomeObject()
>>> s.x = [1, 2.5, 5, 10]
>>> print s.x
_1008fea8_p_float
>>>
```

To fix this, you can write an "out" typemap.   For example:

```swig

%typemap(out) float [ANY] {
  int i;
  $result = PyList_New($1_dim0);
  for (i = 0; i < $1_dim0; i++) {
    PyObject *o = PyFloat_FromDouble((double) $1[i]);
    PyList_SetItem($result, i, o);
  }
}

```

Now, you will find that member access is quite nice:

```
>>> s = SomeObject()
>>> s.x = [1, 2.5, 5, 10]
>>> print s.x
[ 1, 2.5, 5, 10]

```

**Compatibility Note:**  SWIG1.1 used to provide a special "memberout" typemap.  However, it was mostly
useless and has since been eliminated.   To return structure members, simply use the "out" typemap.

<h3 id="Typemaps_nn41">16.6.2 Implementing constraints with typemaps</h3>

One particularly interesting application of typemaps is the
implementation of argument constraints. This can be done with the
"check" typemap. When used, this allows you to provide code for
checking the values of function arguments. For example:

```swig

%module math

%typemap(check) double posdouble {
  if ($1 < 0) {
    croak("Expecting a positive number");
  }
}

...
double sqrt(double posdouble);

```

This provides a sanity check to your wrapper function. If a negative
number is passed to this function, a Perl exception will be raised and
your program terminated with an error message.

This kind of checking can be particularly useful when working with
pointers. For example:

```swig

%typemap(check) Vector * {
  if ($1 == 0) {
    PyErr_SetString(PyExc_TypeError, "NULL Pointer not allowed");
    SWIG_fail;
  }
}

```

will prevent any function involving a `Vector *` from accepting
a NULL pointer. As a result, SWIG can often prevent a potential
segmentation faults or other run-time problems by raising an exception
rather than blindly passing values to the underlying C/C++ program.

<h2 id="Typemaps_nn43">16.7 Typemaps for multiple target languages</h2>

The code within typemaps is usually language dependent,
however, many target languages support the same typemaps.
In order to distinguish typemaps across different languages, the preprocessor should be used.
For example, the "in" typemap for Perl and Ruby could be written as:

```swig

#if defined(SWIGPERL)
  %typemap(in) int "$1 = ($1_ltype) SvIV($input);"
#elif defined(SWIGRUBY)
  %typemap(in) int "$1 = NUM2INT($input);"
#else
  #warning no "in" typemap defined
#endif

```

The full set of language specific macros is defined in the [Conditional Compilation](Preprocessor/#Preprocessor_condition_compilation) section.
The example above also shows a common approach of issuing a warning for an as yet unsupported language.

**Compatibility note:** In SWIG-1.1 different languages could be distinguished with the language name being put within the `%typemap` directive, but this was deprecated in SWIG 1.3.28 and support finally dropped completely in SWIG 4.1.0 so you'll need to update any remaining uses to use the approach above.  For example, 

`%typemap(ruby, in) int "$1 = NUM2INT($input);"`.

<h2 id="Typemaps_optimal">16.8 Optimal code generation when returning by value</h2>

The "out" typemap is the main typemap for return types.
This typemap supports an optional attribute flag called "optimal", which is for reducing the number of
temporary variables and the amount of generated code, thereby giving the compiler the opportunity to 
use *return value optimization* for generating faster executing code.
It only really makes a difference when returning objects by value and has some limitations on usage,
as explained later on.

When a function returns an object by value, SWIG generates code that instantiates the default
type on the stack then assigns the value returned by the function call to it.
A copy of this object is then made on the heap and this is what is ultimately stored and
used from the target language.
This will be clearer considering an example.
Consider running the following code through SWIG:

```swig

%typemap(out) SWIGTYPE %{
  $result = new $1_ltype($1);
%}

%inline %{
#include <iostream>
using namespace std;

struct XX {
  XX() { cout << "XX()" << endl; }
  XX(int i) { cout << "XX(" << i << ")" << endl; }
  XX(const XX &other) { cout << "XX(const XX &)" << endl; }
  XX & operator =(const XX &other) { cout << "operator=(const XX &)" << endl; return *this; }
  ~XX() { cout << "~XX()" << endl; }
  static XX create() { 
    return XX(0);
  }
};
%}

```

The "out" typemap shown is the default typemap for C# when returning objects by value.
When making a call to `XX::create()` from C#, the output is as follows:

```

XX()
XX(0)
operator=(const XX &)
~XX()
XX(const XX &)
~XX()
~XX()

```

Note that three objects are being created as well as an assignment.
Wouldn't it be great if the `XX::create()` method was the only time a constructor was called?
As the method returns by value, this is asking a lot and the code that SWIG generates by default
makes it impossible for the compiler to use *return value optimisation (RVO)*.
However, this is where the "optimal" attribute in the "out" typemap can help out.
If the typemap code is kept the same and just the "optimal" attribute specified like this:

```swig

%typemap(out, optimal="1") SWIGTYPE %{
  $result = new $1_ltype($1);
%}

```

then when the code is run again, the output is simply:

```

XX(0)
~XX()

```

How the "optimal" attribute works is best explained using the generated code.
Without "optimal", the generated code is:

```swig

SWIGEXPORT void * SWIGSTDCALL CSharp_XX_create() {
  void * jresult ;
  XX result;
  result = XX::create();
  jresult = new XX(result);
  return jresult;
}

```

With the "optimal" attribute, the code is:

```swig

SWIGEXPORT void * SWIGSTDCALL CSharp_XX_create() {
  void * jresult ;
  jresult = new XX(XX::create());
  return jresult;
}

```

The major difference is the `result` temporary variable holding the value returned from `XX::create()` is no longer generated and instead the copy constructor call is made directly from
the value returned by `XX::create()`.
With modern compilers implementing RVO, the copy is not actually done, in fact the object is never created
on the stack in `XX::create()` at all, it is simply created directly on the heap.
In the first instance, the `$1` special variable in the typemap is expanded into `result`.
In the second instance, `$1` is expanded into `XX::create()` and this is essentially
what the "optimal" attribute is telling SWIG to do.

The "optimal" attribute optimisation is not turned on by default as it has a number of restrictions.
Firstly, some code cannot be condensed into a simple call for passing into the copy constructor.
One common occurrence is when [%exception](Customization/#Customization_exception) is used.
Consider adding the following `%exception` to the example:

```swig

%exception XX::create() %{
try {
  $action
} catch(const std::exception &e) {
  cout << e.what() << endl;
}
%}

```

SWIG can detect when the "optimal" attribute cannot be used and will ignore it and in this case will issue the following warning:

```

example.i:28: Warning 474: Method XX::create() usage of the optimal attribute ignored
example.i:14: Warning 474: in the out typemap as the following cannot be used to generate
optimal code: 
try {
  result = XX::create();
} catch(const std::exception &e) {
  cout << e.what() << endl;
}

```

It should be clear that the above code cannot be used as the argument to the copy constructor call, that is, for the `$1` substitution.

Secondly, if the typemap uses `$1` more than once, then multiple calls to the wrapped function
will be made. Obviously that is not very optimal.
In fact SWIG attempts to detect this and will issue a warning something like:

```

example.i:21: Warning 475: Multiple calls to XX::create() might be generated due to
example.i:7: Warning 475: optimal attribute usage in the out typemap.

```

However, it doesn't always get it right, for example when `$1` is within some commented out code.

<h2 id="Typemaps_multi_argument_typemaps">16.9 Multi-argument typemaps</h2>

So far, the typemaps presented have focused on the problem of dealing with
single values.  For example, converting a single input object to a single argument
in a function call.   However, certain conversion problems are difficult to handle
in this manner.   As an example, consider the example at the very beginning of this
chapter:

```swig

int foo(int argc, char *argv[]);

```

Suppose that you wanted to wrap this function so that it accepted a single
list of strings like this:

```
>>> foo(["ale", "lager", "stout"])

```

To do this, you not only need to map a list of strings to `char *argv[]`, but the
value of `int argc` is implicitly determined by the length of the list.   Using only simple
typemaps, this type of conversion is possible, but extremely painful.
Multi-argument typemaps help in this situation.

A multi-argument typemap is a conversion rule that specifies how to
convert a *single* object in the target language to a set of
consecutive function arguments in C/C++.  For example, the following multi-argument
maps perform the conversion described for the above example:

```swig

%typemap(in) (int argc, char *argv[]) {
  int i;
  if (!PyList_Check($input)) {
    PyErr_SetString(PyExc_ValueError, "Expecting a list");
    SWIG_fail;
  }
  $1 = PyList_Size($input);
  $2 = (char **) malloc(($1+1)*sizeof(char *));
  for (i = 0; i < $1; i++) {
    PyObject *s = PyList_GetItem($input, i);
    if (!PyUnicode_Check(s)) {
      free($2);
      PyErr_SetString(PyExc_ValueError, "List items must be strings");
      SWIG_fail;
    }
    $2[i] = (char *) PyUnicode_AsUTF8(s);
  }
  $2[i] = 0;
}

%typemap(freearg) (int argc, char *argv[]) {
  free($2);
}

/* Required for C++ method overloading */
%typecheck(SWIG_TYPECHECK_STRING_ARRAY) (int argc, char *argv[]) {
  $1 = PyList_Check($input) ? 1 : 0;
}

```

A multi-argument map is always specified by surrounding the arguments with parentheses as shown.
For example:

```swig

%typemap(in) (int argc, char *argv[]) { ... }

```

Within the typemap code, the variables `$1`, `$2`, and so forth refer to each type
in the map.  All of the usual substitutions apply–just use the appropriate `$1` or `$2`
prefix on the variable name (e.g., `$2_type`, `$1_ltype`, etc.)

Multi-argument typemaps always have precedence over simple typemaps and SWIG always performs longest-match searching.
Therefore, you will get the following behavior:

```swig

%typemap(in) int argc                              { ... typemap 1 ... }
%typemap(in) (int argc, char *argv[])              { ... typemap 2 ... }
%typemap(in) (int argc, char *argv[], char *env[]) { ... typemap 3 ... }

int foo(int argc, char *argv[]);                   // Uses typemap 2
int bar(int argc, int x);                          // Uses typemap 1
int spam(int argc, char *argv[], char *env[]);     // Uses typemap 3

```

It should be stressed that multi-argument typemaps can appear anywhere in a function declaration and can
appear more than once.  For example, you could write this:

```swig

%typemap(in) (int scount, char *swords[]) { ... }
%typemap(in) (int wcount, char *words[]) { ... }

void search_words(int scount, char *swords[], int wcount, char *words[], int maxcount);

```

Other directives such as `%apply` and `%clear` also work with multi-argument maps.  For example:

```swig

%apply (int argc, char *argv[]) {
    (int scount, char *swords[]),
    (int wcount, char *words[])
};
...
%clear (int scount, char *swords[]), (int wcount, char *words[]);
...

```

Don't forget to also provide a suitable [typemap for overloaded functions](#Typemaps_overloading), such as `%typecheck` shown for foo above.
This is only required if the function is overloaded in C++.

Although multi-argument typemaps may seem like an exotic, little used feature, there
are several situations where they make sense.  First, suppose you wanted to wrap
functions similar to the low-level `read()` and `write()` system calls.
For example:

```swig

typedef unsigned int size_t;

int read(int fd, void *rbuffer, size_t len);
int write(int fd, void *wbuffer, size_t len);

```

As is, the only way to use the functions would be to allocate memory and pass some kind of pointer
as the second argument—a process that might require the use of a helper function.  However, using
multi-argument maps, the functions can be transformed into something more natural.  For example, you 
might write typemaps like this:

```swig

// typemap for an outgoing buffer
%typemap(in) (void *wbuffer, size_t len) {
  if (!PyBytes_Check($input)) {
    PyErr_SetString(PyExc_ValueError, "Expecting a bytes object");
    SWIG_fail;
  }
  $1 = (void *) PyBytes_AsString($input);
  $2 = PyBytes_Size($input);
}

// typemap for an incoming buffer
%typemap(in) (void *rbuffer, size_t len) {
  if (!PyLong_Check($input)) {
    PyErr_SetString(PyExc_ValueError, "Expecting an integer");
    SWIG_fail;
  }
  $2 = PyLong_AsLong($input);
  if ($2 < 0) {
    PyErr_SetString(PyExc_ValueError, "Positive integer expected");
    SWIG_fail;
  }
  $1 = (void *) malloc($2);
}

// Return the buffer.  Discarding any previous return result
%typemap(argout) (void *rbuffer, size_t len) {
  Py_DecRef($result);   /* Blow away any previous result */
  if (result < 0) {      /* Check for I/O error */
    free($1);
    PyErr_SetFromErrno(PyExc_IOError);
    return NULL;
  }
  $result = PyBytes_FromStringAndSize($1, result);
  free($1);
}

```

(note: In the above example, `$result` and `result` are two different variables.
`result` is the real C datatype that was returned by the function.  `$result` is the
scripting language object being returned to the interpreter.).

Now, in a script, you can write code that simply passes buffers as bytes objects like this:

```
>>> f = example.open("Makefile")
>>> example.read(f, 40)
b'TOP        = ../..\nSWIG       = $(TOP)/.'
>>> example.read(f, 40)
b'./swig\nSRCS       = example.c\nTARGET    '
>>> example.close(f)
0
>>> g = example.open("foo", example.O_WRONLY | example.O_CREAT, 0o644)
>>> example.write(g, b"Hello world\n")
12
>>> example.write(g, b"This is a test\n")
15
>>> example.close(g)
0
>>>
```

A number of multi-argument typemap problems also arise in libraries that
perform matrix-calculations–especially if they are mapped onto low-level Fortran
or C code. For example, you might have a function like this:

```swig

int is_symmetric(double *mat, int rows, int columns);

```

In this case, you might want to pass some kind of higher-level object as an matrix.  To do
this, you could write a multi-argument typemap like this:

```swig

%typemap(in) (double *mat, int rows, int columns) {
  MatrixObject *a;
  a = GetMatrixFromObject($input);     /* Get matrix somehow */

  /* Get matrix properties */
  $1 = GetPointer(a);
  $2 = GetRows(a);
  $3 = GetColumns(a);
}

```

This kind of technique can be used to hook into scripting-language matrix packages such as
Numeric Python.  However, it should also be stressed that some care is in order.  For example,
when crossing languages you may need to worry about issues such as row-major vs. column-major
ordering (and perform conversions if needed). Note that multi-argument typemaps cannot deal
with non-consecutive C/C++ arguments; a workaround such as a helper function re-ordering
the arguments to make them consecutive will need to be written.

<h2 id="Typemaps_warnings">16.10 Typemap warnings</h2>

Warnings can be added to typemaps so that SWIG generates a warning message whenever the typemap is used.
See the information in the [issuing warnings](Warnings/#Warnings_nn5) section.

<h2 id="Typemaps_fragments">16.11 Typemap fragments</h2>

The primary purpose of fragments is to reduce code bloat that repeated use of typemap code can lead to.
Fragments are snippets of code that can be thought of as code dependencies of a typemap.
If a fragment is used by more than one typemap, then the snippet of code within the fragment is only generated once.
Code bloat is typically reduced by moving typemap code into a support function
and then placing the support function into a fragment.

For example, if you have a very long typemap

```swig

%typemap(in) MyClass * {
  MyClass *value = 0;

  ... many lines of marshalling code  ...

  $result = value;
}

```

the same marshalling code is often repeated in several typemaps, such as "in", "varin", "directorout", etc.
SWIG copies the code for each argument that requires the typemap code, easily leading to code bloat
in the generated code.
To eliminate this, define a fragment that includes the common marshalling code:

```swig

%fragment("AsMyClass", "header") {
  MyClass *AsMyClass(PyObject *obj) {
    MyClass *value = 0;

    ... many lines of marshalling code  ...

    return value;
  }
}

%typemap(in, fragment="AsMyClass") MyClass * {
  $result = AsMyClass($input);
}

%typemap(varin, fragment="AsMyClass") MyClass * {
  $result = AsMyClass($input);
}

```

When the "in" or "varin" typemaps for MyClass are required, the
contents of the fragment called "AsMyClass" are added to the "header" section within the generated code, and then the
typemap code is emitted. Hence, the method `AsMyClass` will be
generated into the wrapper code before any typemap code that calls it.

To define a fragment you need a fragment name, a section name for generating the fragment code into, and the code itself.
See [Code insertion blocks](SWIG/#SWIG_nn42) for a full list of section names.
Usually the section name used is "header". Different delimiters can be used:

```swig

%fragment("my_name", "header") %{ ... %}
%fragment("my_name", "header") { ... }
%fragment("my_name", "header") " ... "

```

and these follow the usual preprocessing rules mentioned in the 
[Preprocessing delimiters](Preprocessor/#Preprocessor_delimiters)
section.
The following are some rules and guidelines for using fragments:

1. A fragment is added to the wrapping code only once. When using the `MyClass *` typemaps above and wrapping the method:

```swig

void foo(MyClass *a, MyClass *b);

```

the generated code will look something like:

```swig

MyClass *AsMyClass(PyObject *obj) {
  ...
}

void _wrap_foo(...) {
  ....
  arg1 = AsMyClass(obj1);
  arg2 = AsMyClass(obj2);
  ...
  foo(arg1, arg2);
}

```

even as there is duplicated typemap code to process both `a` and
`b`, the `AsMyClass` method will be defined only once.
1. A fragment should only be defined once. If there is more than
one definition, the first definition is the one used.
All other definitions are silently ignored. For example, if you have

```swig

%fragment("AsMyClass", "header") { ...definition 1... }
....
%fragment("AsMyClass", "header") { ...definition 2... }

```

only the first definition is used. In this way
you can override the default fragments in a SWIG library by defining your fragment before the library `%include`.
Note that this behavior is the opposite to typemaps, where the last typemap defined/applied prevails.
Fragments follow the first-in-first-out convention since they are intended to be global,
while typemaps are intended to be locally specialized.
1. Fragment names cannot contain commas.
1. A fragment can use one or more additional fragments, for example:

```swig

%fragment("<limits.h>", "header") %{
  #include <limits.h>
%}

%fragment("AsMyClass", "header", fragment="<limits.h>") {
  MyClass *AsMyClass(PyObject *obj) {
    MyClass *value = 0;

    ... some marshalling code  ...

    if  (ival < CHAR_MIN /*defined in <limits.h>*/) {
      ...
    } else {
      ...
    }
    ...
    return value;
  }
}

```

in this case, when the "AsMyClass" fragment is emitted, it also
triggers the inclusion of the "<limits.h\>" fragment.
1. A fragment can have dependencies on a number of other fragments, for example:

```swig

%fragment("bigfragment", "header", fragment="frag1", fragment="frag2", fragment="frag3") "";

```

When the "bigfragment" is used, the three dependent fragments "frag1",
"frag2" and "frag3" are also pulled in. Note that as "bigframent" is 
empty (the empty string - ""), it does not add any code itself, but merely triggers the
inclusion of the other fragments.
1. A typemap can also use more than one fragment:

```swig

%typemap("in", fragment="frag1", fragment="frag2", fragment="frag3") {...}

```

**Compatibility note:** The ability to use multiple
`fragment` keys as shown above was introduced in SWIG-4.1.0.

Multiple fragments can alternatively be specified as a comma
separated list value in a single `fragment` key.
Note that no whitespace is allowed within this comma separated list.
The following is the equivalent to the above:

```swig

%typemap(in, fragment="frag1,frag2,frag3") {...}

```

which in turn is functionally equivalent to:

```swig

%typemap(in, fragment="bigfragment") {...}

```

when used with the "bigfragment" defined above.
1. Finally, you can force the inclusion of a fragment at any point in the generated code as follows:

```swig

%fragment("bigfragment");

```

which, for example, is very useful inside a template class.
Another useful case is when using `%extend` inside a class
where the additional code in the `%extend` block depends on the contents of the fragment.

```swig

%fragment("<limits.h>", "header") %{
  #include <limits.h>
%}

struct X {
  ...
  %extend {
    %fragment("<limits.h>");
    bool check(short val) {
      if (val < SHRT_MIN /*defined in <limits.h>*/) {
        return true;
      } else {
        return false;
      }
    }
  }
};

```

Forced inclusion of fragments can be used as a replacement for [code insertion block](SWIG/#SWIG_nn42), ensuring the
code block is only generated once.
Consider the contents of FileA.i below which first uses a code insertion block and then a forced fragment inclusion to generate code:

```swig

// FileA.i
%{
  #include <stdio.h>
%}
%fragment("<limits.h>");

```

and another file including the above:

```swig

// FileB.i
%include "FileA.i"

```

The resulting code in the wrappers for FileB.i is:

```swig

  #include <stdio.h>

  #include <limits.h>
```

A note of caution must be mentioned when using `%fragment` forced inclusion or code insertion blocks with `%import`.
If `%import` is used instead:

```swig

// FileC.i
%import "FileA.i"

```

then nothing is generated in the resulting code in the wrappers for FileC.i.
This is because `%import` is for collecting type information and does not result in any code
being generated, see [File Imports](Preprocessor/#Preprocessor_nn3).

Most readers will probably want to skip the next two sub-sections on advanced
fragment usage unless a desire to really get to grips
with some powerful but tricky macro and fragment usage that is used in parts of the SWIG typemap library.

<h3 id="Typemaps_fragment_type_specialization">16.11.1 Fragment type specialization</h3>

Fragments can be *type specialized*. The syntax is as follows:

```swig

%fragment("name", "header") { ...a type independent fragment... }
%fragment("name"{type}, "header") { ...a type dependent fragment...  }

```

where `type` is a C/C++ type. Like typemaps, fragments can also be used inside templates, for example:

```swig

template <class T>
struct A {
  %fragment("incode"{A<T>}, "header") {
    ... 'incode' specialized fragment ...
  }

  %typemap(in, fragment="incode"{A<T>}) {
    ... here we use the 'type specialized' fragment "incode"{A<T>} ...
  }
};

```

<h3 id="Typemaps_automatic_specialization">16.11.2 Fragments and automatic typemap specialization</h3>

Since fragments can be type specialized, they can be elegantly used
to specialize typemaps. For example, if you have something like:

```swig

%fragment("incode"{float}, "header") {
  float in_method_float(PyObject *obj) {
    ...
  }
}

%fragment("incode"{long}, "header") {
  float in_method_long(PyObject *obj) {
    ...
  }
}

// %my_typemaps macro definition
%define %my_typemaps(Type) 
%typemap(in, fragment="incode"{Type}) Type {
  value = in_method_##Type(obj);
}
%enddef

%my_typemaps(float);
%my_typemaps(long);

```

then the proper `"incode"{float}` or `"incode"{long}` fragment will be used,
and the `in_method_float` and `in_method_long` methods will be called whenever
the `float` or `long` types are used as input parameters.

This feature is used a lot in the typemaps shipped in the SWIG library for some scripting languages.
The interested (or very brave) reader can take a look at the fragments.swg file shipped with SWIG to see this in action.

<h2 id="Typemaps_runtime_type_checker">16.12 The run-time type checker</h2>

Most scripting languages need type information at run-time.  This type information
can include how to construct types, how to garbage collect types, and the inheritance
relationships between types.  If the language interface does not provide its own type
information storage, the generated SWIG code needs to provide it.

Requirements for the type system:

- Store inheritance and type equivalence information and be able to correctly 
re-create the type pointer.
- Share type information between modules.
- Modules can be loaded in any order, regardless of actual type
dependency.
- Avoid the use of dynamically allocated memory, and library/system calls in general.
- Provide a reasonably fast implementation, minimizing the lookup time for all
language modules.
- Custom, language specific information can be attached to types.
- Modules can be unloaded from the type system.

<h3 id="Typemaps_nn45">16.12.1 Implementation</h3>

The run-time type checker is used by many, but not all, of SWIG's supported target languages.
The run-time type checker features
are not required and are thus not used for statically typed languages such as Java and C#.
The scripting and scheme based languages rely on it and it forms
a critical part of SWIG's operation for these languages.

When pointers, arrays, and objects are wrapped by SWIG, they are normally converted
into typed pointer objects.  For example, an instance of `Foo *` might be
a string encoded like this:

```

_108e688_p_Foo

```

At a basic level, the type checker simply restores some type-safety to
extension modules.  However, the type checker is also responsible for
making sure that wrapped C++ classes are handled
correctly—especially when inheritance is used.   This is especially
important when an extension module makes use of multiple inheritance.
For example:

```swig

class Foo {
public:
  int x;
};

class Bar {
public:
  int y;
};

class FooBar : public Foo, public Bar {
public:
  int z;
};

```

When the class `FooBar` is organized in memory, it contains the contents
of the classes `Foo` and `Bar` as well as its own data members.  For example:

```

FooBar --> | -----------|  <-- Foo
           |   int x    |
           |------------|  <-- Bar
           |   int y    |
           |------------|
           |   int z    |
           |------------|

```

Because of the way that base class data is stacked together, the
casting of a `Foobar *` to either of the base classes may
change the actual value of the pointer.  This means that it is
generally not safe to represent pointers using a simple integer or a
bare `void *`—type tags are needed to implement correct
handling of pointer values (and to make adjustments when needed).

In the wrapper code generated for each language, pointers are handled through
the use of special type descriptors and conversion functions.  For example,
if you look at the wrapper code for Python, you will see code similar to the following
(simplified for brevity):

```swig

if (!SWIG_IsOK(SWIG_ConvertPtr(obj0, (void **) &arg1, SWIGTYPE_p_Foo, 0))) {
  SWIG_exception_fail(SWIG_TypeError, "in method 'GrabVal', expecting type Foo");
}

```

In this code, `SWIGTYPE_p_Foo` is the type descriptor that
describes `Foo *`.  The type descriptor is actually a pointer to a 
structure that contains information about the type name to use in the
target language, a list of equivalent typenames (via typedef or
inheritance), and pointer value handling information (if applicable).
The `SWIG_ConvertPtr()` function is simply a utility function
that takes a pointer object in the target language and a
type-descriptor object and uses this information to generate a C++ pointer.
The `SWIG_IsOK` macro checks the return value for errors and
`SWIG_exception_fail` can be called to raise an exception in the target language.
However, the exact name and calling conventions of the conversion
function depends on the target language (see language specific chapters for details).

The actual type code is in swigrun.swg, and gets inserted near the top of the generated
swig wrapper file.  The phrase "a type X that can cast into a type Y" means
that given a type X, it can be converted into a type Y.  In other words, X is a derived
class of Y or X is a typedef of Y.  The structure to store type information looks like this:

```swig

/* Structure to store information on one type */
typedef struct swig_type_info {
  const char *name;             /* mangled name of this type */
  const char *str;              /* human readable name for this type */
  swig_dycast_func dcast;       /* dynamic cast function down a hierarchy */
  struct swig_cast_info *cast;  /* Linked list of types that can cast into this type */
  void *clientdata;             /* Language specific type data */
} swig_type_info;

/* Structure to store a type and conversion function used for casting */
typedef struct swig_cast_info {
  swig_type_info *type;          /* pointer to type that is equivalent to this type */
  swig_converter_func converter; /* function to cast the void pointers */
  struct swig_cast_info *next;   /* pointer to next cast in linked list */
  struct swig_cast_info *prev;   /* pointer to the previous cast */
} swig_cast_info;

```

Each `swig_type_info` stores a linked list of types that it is equivalent to.  Each entry in this
doubly linked list stores a pointer back to another swig_type_info structure,
along with a pointer to a conversion function.  This conversion function is used
to solve the above problem of the FooBar class, correctly returning a pointer to
the type we want.

The basic problem we need to solve is verifying and building arguments passed to functions.
So going back to the `SWIG_ConvertPtr()` function example from above, we are
expecting a `Foo *` and need to
check if `obj0` is in fact a `Foo *`.  From before, `SWIGTYPE_p_Foo` is just
a pointer to the `swig_type_info` structure describing `Foo *`.  So we loop through the
linked list of `swig_cast_info` structures attached to `SWIGTYPE_p_Foo`.  If we see that the type of `obj0` is in the
linked list, we pass the object through the associated conversion function and
then return a positive.  If we reach the end of the linked list without a match,
then `obj0` can not be converted to a `Foo *` and an error is generated.

Another issue needing to be addressed is sharing type information between multiple modules.
More explicitly, we need
to have ONE `swig_type_info` for each type.  If two modules both use the type, the
second module loaded must lookup and use the swig_type_info structure from the module already loaded.
Because no dynamic memory is used and the circular dependencies of the
casting information, loading the type information is somewhat tricky, and not explained here.
A complete description is in the `Lib/swiginit.swg` file (and near the top of any generated file).

Each module has one swig_module_info structure which looks like this:

```swig

/* Structure used to store module information
 * Each module generates one structure like this, and the runtime collects
 * all of these structures and stores them in a circularly linked list.*/
typedef struct swig_module_info {
  swig_type_info **types;         /* Array of pointers to swig_type_info structs in this module */
  int size;                       /* Number of types in this module */
  struct swig_module_info *next;  /* Pointer to next element in circularly linked list */
  swig_type_info **type_initial;  /* Array of initially generated type structures */
  swig_cast_info **cast_initial;  /* Array of initially generated casting structures */
  void *clientdata;               /* Language specific module data */
} swig_module_info;

```

Each module stores an array of pointers to `swig_type_info` structures and the number of
types in this module.  So when a second module is loaded, it finds the `swig_module_info`
structure for the first module and searches the array of types. If any of its own
types are in the first module and have already been loaded, it uses those `swig_type_info`
structures rather than creating new ones.  These `swig_module_info` 
structures are chained together in a circularly linked list.

<h3 id="Typemaps_runtime_type_checker_usage">16.12.2 Usage</h3>

This section covers how to use these functions from typemaps.  To learn how to
call these functions from external files (not the generated _wrap.c file), see
the [External access to the run-time system](Modules/#Modules_external_run_time)
section.

When pointers are converted in a typemap, the typemap code often looks
similar to this:

```swig

%typemap(in) Foo * {
  if (!SWIG_IsOK(SWIG_ConvertPtr($input, (void **) &$1, $1_descriptor, 0))) {
    SWIG_exception_fail(SWIG_TypeError, "in method '$symname', expecting type Foo");
  }
}

```

The most critical part is the typemap is the use of the `$1_descriptor`
special variable.  When placed in a typemap, this is expanded into the
`SWIGTYPE_*` type descriptor object above.  As a general rule,
you should always use `$1_descriptor` instead of trying to
hard-code the type descriptor name directly.

There is another reason why you should always use the
`$1_descriptor` variable.  When this special variable is
expanded, SWIG marks the corresponding type as "in use."  When
type-tables and type information is emitted in the wrapper file,
descriptor information is only generated for those datatypes that were
actually used in the interface.  This greatly reduces the size of the
type tables and improves efficiency.

Occasionally, you might need to write a typemap that needs to convert
pointers of other types.  To handle this, the special variable macro
`$descriptor(type)` covered earlier can be used to generate the SWIG type
descriptor name for any C datatype.  For example:

```swig

%typemap(in) Foo * {
  if (!SWIG_IsOK(SWIG_ConvertPtr($input, (void **) &$1, $1_descriptor, 0))) {
    Bar *temp;
    if (!SWIG_IsOK(SWIG_ConvertPtr($input, (void **) &temp, $descriptor(Bar *), 0))) {
      SWIG_exception_fail(SWIG_TypeError, "in method '$symname', expecting type Foo or Bar");
    }
    $1 = (Foo *)temp;
  }
}

```

The primary use of `$descriptor(type)` is when writing typemaps for container
objects and other complex data structures.  There are some restrictions on the argument—namely it must
be a fully defined C datatype.  It can not be any of the special typemap variables.

In certain cases, SWIG may not generate type-descriptors like you expect.  For example,
if you are converting pointers in some non-standard way or working with an unusual
combination of interface files and modules, you may find that SWIG omits information
for a specific type descriptor.  To fix this, you may need to use the `%types` directive.
For example:

```swig

%types(int *, short *, long *, float *, double *);

```

When `%types` is used, SWIG generates type-descriptor
information even if those datatypes never appear elsewhere in the
interface file.

Further details about the run-time type checking can be found in the documentation for
individual language modules.   Reading the source code may also help.  The file
`Lib/swigrun.swg` in the SWIG library contains all of the source of the generated code for 
type-checking.  This code is also included in every generated wrapped file so you
probably just look at the output of SWIG to get a better sense for how types are
managed.

<h2 id="Typemaps_overloading">16.13 Typemaps and overloading</h2>

This section does not apply to the statically typed languages like Java and C#, where overloading
of the types is handled much like C++ by generating overloaded methods in the target language.
In many of the other target languages, SWIG still fully supports C++ overloaded methods and functions.   For example,
if you have a collection of functions like this:

```swig

int foo(int x);
int foo(double x);
int foo(char *s, int y);

```

You can access the functions in a normal way from the scripting interpreter:

```

# Python
foo(3)           # foo(int)
foo(3.5)         # foo(double)
foo("hello", 5)  # foo(char *, int)

# Tcl
foo 3            # foo(int)
foo 3.5          # foo(double)
foo hello 5      # foo(char *, int)

```

To implement overloading, SWIG generates a separate wrapper function for each overloaded method.
For example, the above functions would produce something roughly like this:

```swig

// wrapper pseudocode
_wrap_foo_0(argc, args[]) {       // foo(int)
  int arg1;
  int result;
  ...
  arg1 = FromInteger(args[0]);
  result = foo(arg1);
  return ToInteger(result);
}

_wrap_foo_1(argc, args[]) {       // foo(double)
  double arg1;
  int result;
  ...
  arg1 = FromDouble(args[0]);
  result = foo(arg1);
  return ToInteger(result);
}

_wrap_foo_2(argc, args[]) {       // foo(char *, int)
  char *arg1;
  int   arg2;
  int result;
  ...
  arg1 = FromString(args[0]);
  arg2 = FromInteger(args[1]);
  result = foo(arg1, arg2);
  return ToInteger(result);
}

```

Next, a dynamic dispatch function is generated:

```swig

_wrap_foo(argc, args[]) {
  if (argc == 1) {
    if (IsInteger(args[0])) {
      return _wrap_foo_0(argc, args);
    }
    if (IsDouble(args[0])) {
      return _wrap_foo_1(argc, args);
    }
  }
  if (argc == 2) {
    if (IsString(args[0]) && IsInteger(args[1])) {
      return _wrap_foo_2(argc, args);
    }
  }
  error("No matching function!\n");
}

```

The purpose of the dynamic dispatch function is to select the appropriate C++ function based on 
argument types—a task that must be performed at runtime in most of SWIG's target languages.

The generation of the dynamic dispatch function is a relatively tricky affair.  Not only must input typemaps
be taken into account (these typemaps can radically change the types of arguments accepted), but overloaded
methods must also be sorted and checked in a very specific order to resolve potential ambiguity.   A high-level
overview of this ranking process is found in the "[SWIG and C++](SWIGPlus/#SWIGPlus)" chapter.    What isn't mentioned in that chapter
is the mechanism by which it is implemented—as a collection of typemaps.

To support dynamic dispatch, SWIG first defines a general purpose type hierarchy as follows:

```

Symbolic Name                   Precedence Value
------------------------------  ------------------
SWIG_TYPECHECK_POINTER           0
SWIG_TYPECHECK_ITERATOR          5
SWIG_TYPECHECK_VOIDPTR           10
SWIG_TYPECHECK_BOOL              15
SWIG_TYPECHECK_UINT8             20
SWIG_TYPECHECK_INT8              25
SWIG_TYPECHECK_UINT16            30
SWIG_TYPECHECK_INT16             35
SWIG_TYPECHECK_UINT32            40
SWIG_TYPECHECK_INT32             45
SWIG_TYPECHECK_SIZE              47
SWIG_TYPECHECK_PTRDIFF           48
SWIG_TYPECHECK_UINT64            50
SWIG_TYPECHECK_INT64             55
SWIG_TYPECHECK_UINT128           60
SWIG_TYPECHECK_INT128            65
SWIG_TYPECHECK_INTEGER           70
SWIG_TYPECHECK_FLOAT             80
SWIG_TYPECHECK_DOUBLE            90
SWIG_TYPECHECK_CPLXFLT           95
SWIG_TYPECHECK_CPLXDBL           100
SWIG_TYPECHECK_COMPLEX           105
SWIG_TYPECHECK_UNICHAR           110
SWIG_TYPECHECK_STDUNISTRING      115
SWIG_TYPECHECK_UNISTRING         120
SWIG_TYPECHECK_CHAR              130
SWIG_TYPECHECK_STDSTRING         135
SWIG_TYPECHECK_STRING            140
SWIG_TYPECHECK_PAIR              150
SWIG_TYPECHECK_STDARRAY          155
SWIG_TYPECHECK_VECTOR            160
SWIG_TYPECHECK_DEQUE             170
SWIG_TYPECHECK_LIST              180
SWIG_TYPECHECK_SET               190
SWIG_TYPECHECK_MULTISET          200
SWIG_TYPECHECK_MAP               210
SWIG_TYPECHECK_MULTIMAP          220
SWIG_TYPECHECK_STACK             230
SWIG_TYPECHECK_QUEUE             240
SWIG_TYPECHECK_BOOL_ARRAY        1015
SWIG_TYPECHECK_INT8_ARRAY        1025
SWIG_TYPECHECK_INT16_ARRAY       1035
SWIG_TYPECHECK_INT32_ARRAY       1045
SWIG_TYPECHECK_INT64_ARRAY       1055
SWIG_TYPECHECK_INT128_ARRAY      1065
SWIG_TYPECHECK_FLOAT_ARRAY       1080
SWIG_TYPECHECK_DOUBLE_ARRAY      1090
SWIG_TYPECHECK_CHAR_ARRAY        1130
SWIG_TYPECHECK_STRING_ARRAY      1140
SWIG_TYPECHECK_OBJECT_ARRAY      1150
SWIG_TYPECHECK_BOOL_PTR          2015
SWIG_TYPECHECK_UINT8_PTR         2020
SWIG_TYPECHECK_INT8_PTR          2025
SWIG_TYPECHECK_UINT16_PTR        2030
SWIG_TYPECHECK_INT16_PTR         2035
SWIG_TYPECHECK_UINT32_PTR        2040
SWIG_TYPECHECK_INT32_PTR         2045
SWIG_TYPECHECK_UINT64_PTR        2050
SWIG_TYPECHECK_INT64_PTR         2055
SWIG_TYPECHECK_FLOAT_PTR         2080
SWIG_TYPECHECK_DOUBLE_PTR        2090
SWIG_TYPECHECK_CHAR_PTR          2130
SWIG_TYPECHECK_SWIGOBJECT        5000

```

(These precedence levels are defined in `swig.swg`, a library file that's included by all target language modules.)

In this table, the precedence-level determines the order in which types are going to be checked.  Low values
are always checked before higher values.  For example, integers are checked before floats, single values are checked
before arrays, and so forth.

Using the above table as a guide, each target language defines a collection of "typecheck" typemaps. 
The following excerpt from the Python module illustrates this:

```swig

/* Python type checking rules */
/* Note:  %typecheck(X) is a macro for %typemap(typecheck, precedence=X) */

%typecheck(SWIG_TYPECHECK_INTEGER)
  int, short, long,
  unsigned int, unsigned short, unsigned long,
  signed char, unsigned char,
  long long, unsigned long long,
  const int &, const short &, const long &,
  const unsigned int &, const unsigned short &, const unsigned long &,
  const long long &, const unsigned long long &,
  enum SWIGTYPE,
  bool, const bool &
{
  $1 = PyLong_Check($input) ? 1 : 0;
}

%typecheck(SWIG_TYPECHECK_DOUBLE)
  float, double,
  const float &, const double &
{
  $1 = (PyFloat_Check($input) || PyLong_Check($input)) ? 1 : 0;
}

%typecheck(SWIG_TYPECHECK_CHAR) char {
  $1 = (PyUnicode_Check($input) && (PyUnicode_GetLength($input) == 1)) ? 1 : 0;
}

%typecheck(SWIG_TYPECHECK_STRING) char * {
  $1 = PyUnicode_Check($input) ? 1 : 0;
}

%typemap(typecheck, precedence=SWIG_TYPECHECK_POINTER, noblock=1) SWIGTYPE * {
  void *vptr = 0;
  int res = SWIG_ConvertPtr($input, &vptr, $1_descriptor, 0);
  $1 = SWIG_IsOK(res) ? 1 : 0;
}

%typecheck(SWIG_TYPECHECK_POINTER) PyObject * {
  $1 = ($input != 0);
}

```

It might take a bit of contemplation, but this code has merely organized all of the basic C++ types, provided some simple type-checking
code, and assigned each type a precedence value.

Finally, to generate the dynamic dispatch function, SWIG uses the following algorithm:

- Overloaded methods are first sorted by the number of required arguments.
- Methods with the same number of arguments are then sorted by precedence values of argument types.
- Typecheck typemaps are then emitted to produce a dispatch function that checks arguments in the correct order.

If you haven't written any typemaps of your own, it is unnecessary to worry about the typechecking rules.
However, if you have written new input typemaps, you might have to supply a typechecking rule as well.
An easy way to do this is to simply copy one of the existing typechecking rules. 
Here is an example,

```swig

// Typemap for a C++ string
%typemap(in) std::string {
  if (PyUnicode_Check($input)) {
    $1 = std::string(PyUnicode_AsUTF8($input));
  } else {
    SWIG_exception(SWIG_TypeError, "string expected");
  }
}
// Copy the typecheck code for "char *".  
%typemap(typecheck) std::string = char *;

```

The bottom line:  If you are writing new typemaps and you are using overloaded methods, you will probably 
have to write new typecheck code or copy and modify existing typecheck code.

If you write a typecheck typemap and omit the precedence level, for example commenting it out as shown below:

```swig

%typemap(typecheck /*, precedence=SWIG_TYPECHECK_INTEGER*/) int {
  $1 = PyLong_Check($input) ? 1 : 0;
}

```

then the type is given a precedence higher than any other known precedence level and a [warning](Warnings/#Warnings) is issued:

```shell

example.i:18: Warning 467: Overloaded method foo(int) not supported (incomplete type
checking rule - no precedence level in typecheck typemap for 'int').

```

**Notes:**

- Typecheck typemaps are not used for non-overloaded methods.  Because of this, it is
still always necessary to check types in any "in" typemaps.
- The dynamic dispatch process is only meant to be a heuristic.  There are many corner
cases where SWIG simply can't disambiguate types to the same degree as C++.   The only way to
resolve this ambiguity is to use the %rename directive to rename one of the overloaded methods (effectively
eliminating overloading).
- Typechecking may be partial.  For example, if working with arrays, the typecheck code might 
simply check the type of the first array element and use that to dispatch to the correct function.
Subsequent "in" typemaps would then perform more extensive type-checking.
- Make sure you read the section on [overloading](SWIGPlus/#SWIGPlus_overloaded_methods) in the SWIG and C++ chapter.

<h3 id="Typemaps_typecheck_pointer">16.13.1 SWIG_TYPECHECK_POINTER precedence level and the typecheck typemap</h3>

When it comes to overloading of a particular type passed by value, pointer or reference (const and non-const),
a C++ compiler can disambiguate which overloaded function to call.
However, SWIG effectively treats these as pointers in the target language and thus as equivalent types.
For example, consider:

```swig

class X { ... };
void m(X const &c); // equivalent: void m(X *c);
void m(X &r);       // equivalent: void m(X *r);
void m(X *p);       // equivalent: void m(X *p);

```

These cannot be disambiguated in the target languages and so SWIG will choose the first method and ignore the subsequent two methods.
The scripting languages do this by using the overload dispatch mechanism described earlier and warnings indicate this:

```shell

example.i:6: Warning 509: Overloaded method m(X &) effectively ignored,
example.i:5: Warning 509: as it is shadowed by m(X const &).
example.i:7: Warning 509: Overloaded method m(X *) effectively ignored,
example.i:5: Warning 509: as it is shadowed by m(X const &).

```

The statically typed languages like Java and C# automatically ignore all but the first equivalent overloaded methods with warnings:

```shell

example.i:6: Warning 516: Overloaded method m(X &) ignored,
example.i:5: Warning 516: using m(X const &) instead.
example.i:7: Warning 516: Overloaded method m(X *) ignored,
example.i:5: Warning 516: using m(X const &) instead.

```

You can select the overloaded method you would like to wrap by ignoring the other two with `%ignore` or rename two of them with `%rename`
and this will of course remove the warnings too.
The problem of ambiguity is also discussed in the C++ chapter on [overloading](SWIGPlus/#SWIGPlus_overloaded_methods).

So how does this work with respect to typemaps?
The typemaps SWIG provides to handle overloading for these three methods are from the SWIGTYPE family.
As discussed earlier, in [Default typemap matching rules](Typemaps/#Typemaps_nn19),
the `SWIGTYPE&` typemaps are used for references and `SWIGTYPE *` typemaps are used for pointers.
SWIG uses the special `SWIG_TYPECHECK_POINTER` (0) precedence level to handle these types in the "typecheck" typemap:

```swig

%typemap(typecheck, precedence=SWIG_TYPECHECK_POINTER) SWIGTYPE & "..."
%typemap(typecheck, precedence=SWIG_TYPECHECK_POINTER) SWIGTYPE * "..."

```

When the SWIGTYPE "typecheck" typemaps use the `SWIG_TYPECHECK_POINTER` precedence level,
SWIG converts the type to a pointer equivalent type and then uses the equivalent type to detect if it can be disambiguated in an overloaded method in the target language.
In our example above, the equivalent types for `X const&`, `X&` and `X *` are all `X *`.
As they are the same, they cannot be disambiguated and so just the first overloaded method is chosen.

The automatic conversion to equivalent types and subsequent type comparison is triggered via the use of the special `SWIG_TYPECHECK_POINTER` precedence level
and works for types passed by value, pointer and reference.
Alas, there are more ways to overload a method that also need handling.
C++ smart pointers are such a type which can be disambiguated by a C++ compiler but not automatically by SWIG.
SWIG does not automatically know that a smart pointer has an equivalent type, but it can be told manually.
Just specify the 'equivalent' attribute in the "typecheck" typemap with a pointer to the underlying type.

```swig

%typemap(typecheck, precedence=SWIG_TYPECHECK_POINTER, equivalent="X *") MySmartPtr<X> " ... "

void m(X &r);            // equivalent: void m(X *r);
void m(MySmartPtr<X> s); // equivalent: void m(X *s);

```

Now SWIG will detect the two types are equivalent and generate valid code by wrapping just the first overloaded method.
You can of course choose which method to wrap by ignoring one of them with `%ignore`.
Otherwise both can be wrapped by removing the overloading name ambiguity by renaming one of them with `%rename`.

The 'equivalent' attribute is used in the implementation for the [shared_ptr smart pointer](Library/#Library_std_shared_ptr) library.

<h2 id="Typemaps_nn48">16.14 More about %apply and %clear</h2>

In order to implement certain kinds of program behavior, it is sometimes necessary to
write a family of typemap methods.  For example, to support output arguments, one often writes
a family of typemaps like this:

```swig

%typemap(in, numinputs=0) int *OUTPUT (int temp) {
  $1 = &temp;
}
%typemap(argout) int *OUTPUT {
  // return value somehow
}

```

To make it easier to apply the typemap to different argument types and names, the `%apply` directive
performs a copy of all typemaps from a source type to one or more set of target types.  For example, if you specify this,

```swig

%apply int *OUTPUT { int *retvalue, int32 *output };

```

then all of the `int *OUTPUT` (source) typemap methods are copied to `int *retvalue` and `int32 *output` (the targets).

However, there is a subtle aspect of `%apply` that needs clarification.  
Namely, if a target contains a typemap method that the source does not,
the target typemap method remains in place and unchanged.
This behavior allows you to do two things:

- You can specialize parts of a complex typemap rule by first defining a few typemaps and then using
`%apply` to incorporate the remaining pieces.
- Different typemaps can be applied to the same datatype using repeated `%apply` directives.

For example:

```swig

%typemap(in) int *INPUT (int temp) {
  temp = ... get value from $input ...;
  $1 = &temp;
}

%typemap(check) int *POSITIVE {
  if (*$1 <= 0) {
    SWIG_exception(SWIG_ValueError, "Expected a positive number!\n");
  }
}

%typemap(arginit) int *invalue %{
  $1 = NULL;
%}

...
%apply int *INPUT     { int *invalue };
%apply int *POSITIVE  { int *invalue };

```

In this example, neither of the two `%apply` directives will overwrite / delete the "arginit" typemap as neither has an "arginit" typemap.
The result is a family of three relevant typemaps for `int *invalue`.
Since `%apply` does not overwrite / delete any existing rules, the only way to reset behavior is to
delete them, such as with the `%clear` directive.
For example:

```swig

%clear int *invalue;

```

will delete the typemaps for all the typemap methods; namely "in", "check" and "arginit". Alternatively delete each one individually:

```swig

%typemap(in) int *invalue;
%typemap(check) int *invalue;
%typemap(arginit) int *invalue;

```

<h3 id="Typemaps_apply_typedefs">16.14.1 Typedefs and %apply</h3>

Consider a similar example to that shown earlier but this time with a couple of typedefs:

```swig

%typemap(check) int *NEGATIVE {
  if (*$1 >= 0) {
    SWIG_exception(SWIG_ValueError, "Expected a negative number!\n");
  }
}

typedef int integer;
typedef integer negative_integer;
void fff(negative_integer *number);

```

Typically `%apply` is specified with the exact type *being applied*, such as `int *` in the following case:

```swig

%apply int *NEGATIVE { negative_integer *number };

```

to find an exact typemap match: `int *NEGATIVE`.

However, the following will also work in this case:

```swig

%apply negative_integer *NEGATIVE { negative_integer *number };

```

as SWIG will use the typedefs to find a match. Typemaps will be searched for until one matches by following the typedefs in the expected order:

- `negative_integer *NEGATIVE`
- `integer *NEGATIVE`
- `int *NEGATIVE`

Note that the search looks for a **family of typemaps** and will stop when a typemap with **any matching method name** is found.
So for example, consider the addition of an "argout" typemap method to the example:

```swig

%typemap(argout) negative_integer *NEGATIVE {
  // return value somehow
}

```

There is then at least one typemap method creating a family of typemaps: `negative_integer *NEGATIVE`.
As the search halts on the closest match when chasing typedefs,
and this family of typemaps does not have a "check" typemap method, there is no "check" typemap method to apply.

In summary, the addition of the better matching "argout" typemap
for `negative_integer *NEGATIVE`
introduces a new family of typemaps resulting in the previously matching "check" typemap 
for `int *NEGATIVE`
no longer being available for applying.

<h2 id="Typemaps_nn47">16.15 Passing data between typemaps</h2>

It is also important to note that the primary use of local variables
is to create stack-allocated objects for temporary use inside a
wrapper function (this is faster and less-prone to error than
allocating data on the heap).  In general, the variables are not intended
to pass information between different types of typemaps.  However, this
can be done if you realize that local names have the argument number appended
to them.  For example, you could do this:

```swig

%typemap(in) int *(int temp) {
  temp = (int) PyLong_AsLong($input);
  $1 = &temp;
}

%typemap(argout) int * {
  PyObject *o = PyLong_FromLong(temp$argnum);
  ...
}

```

In this case, the `$argnum` variable is expanded into the argument
number.  Therefore, the code will reference the appropriate local
such as `temp1` and `temp2`.   It should be noted that there are 
plenty of opportunities to break the universe here and that accessing locals
in this manner should probably be avoided.  At the very least, you should make
sure that the typemaps sharing information have exactly the same types and names.

<h2 id="Typemaps_nn52">16.16 C++ "this" pointer</h2>

All the rules discussed for typemaps apply to C++ as well as C.
However in addition C++ passes an extra parameter into every
non-static class method – the `this` pointer.  Occasionally it can be
useful to apply a typemap to this pointer (for example to check
and make sure `this` is non-null before deferencing).
Actually, C also has an the equivalent of the `this` pointer which is used
when accessing variables in a C struct.

In order to customise the `this` pointer handling, target a variable named `self` in your typemaps.
`self` is the name SWIG uses to refer to the extra parameter in wrapped functions.

For example, if wrapping for Java generation:

```swig

%typemap(check) SWIGTYPE *self %{
if (!$1) {
  SWIG_JavaThrowException(jenv, SWIG_JavaNullPointerException,
    "invalid native object; delete() likely already called");
  return $null;
}
%}

```

In the above case, the `$1` variable is expanded into the argument
name that SWIG is using as the `this` pointer.

SWIG will then insert the check code before the actual C++ class method
is called, and will raise an exception rather than crash
the Java virtual machine.

The generated code will look something like:

```swig

  if (!arg1) {
    SWIG_JavaThrowException(jenv, SWIG_JavaNullPointerException,
      "invalid native object; delete() likely already called");
    return ;
  }
  (arg1)->wrappedFunction(...);

```

Note that if you have a parameter named `self` then it
will also match the typemap.  One work around is to create an interface file that wraps
the method, but gives the argument a name other than `self`.

<h2 id="Typemaps_nn51">16.17 Where to go for more information?</h2>

The
best place to find out more information about writing typemaps is to
look in the SWIG library.  Most language modules define all of their
default behavior using typemaps.  These are found in files such as
`python.swg`, `perl5.swg`, `tcl8.swg` and so
forth.  The `typemaps.i` file in the library also contains
numerous examples.   You should look at these files to get a feel
for how to define typemaps of your own.
Some of the language modules support additional typemaps and further
information is available in the individual chapters for each target language.
There you may also find more hands-on practical examples.
