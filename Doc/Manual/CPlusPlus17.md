

<h1 id="CPlusPlus17">9 SWIG and C++17</h1>

<!-- INDEX -->

<!-- INDEX -->

<h2 id="CPlusPlus17_introduction">9.1 Introduction</h2>

This chapter gives you a brief overview about the SWIG
implementation of the C++17 standard.
There isn't much in C++17 that affects SWIG, however, work has only just begun on adding
C++17 support.

**Compatibility note:** SWIG-4.0.0 is the first version to support any C++17 features.

<h2 id="CPlusPlus17_core_language_changes">9.2 Core language changes</h2>

<h3 id="CPlusPlus17_nested_namespaces">9.2.1 Nested namespace definitions</h3>

C++17 offers a more concise syntax for defining namespaces.
SWIG has support for nested namespace definitions such as:

```swig

namespace A::B::C {
  ...
}

```

This is the equivalent to the C++98 namespace definitions:

```swig

namespace A {
  namespace B {
    namespace C {
      ...
    }
  }
}

```

<h3 id="CPlusPlus17_u8_char_literals">9.2.2 UTF-8 character literals</h3>

C++17 added UTF-8 (u8) character literals.
These are of type char.
Example:

```swig

char a = u8'a';

```

<h3 id="CPlusPlus17_hexadecimal_floating_literals">9.2.3 Hexadecimal floating literals</h3>

C++17 added hexadecimal floating literals.
For example:

```swig

double f = 0xF.68p2;

```

<h3 id="CPlusPlus17_fold_expressions">9.2.4 Fold expressions</h3>

C++17 added template fold expressions.  SWIG 4.3.0 and later support
parsing these with a few restrictions.  Unary left fold expressions are
not supported currently.  Also the same restrictions that apply to other
expressions apply here too.

<h3 id="CPlusPlus17_using_pack_expansion">9.2.5 Pack expansion in using-declaration</h3>

C++17 extended the using-declaration so a single statement can bring all the names
of a template parameter pack into scope.  This generalises the C++11
[mixin form](CPlusPlus11/#CPlusPlus11_using_declaration_template_base),
which inherits a member through one type-template parameter base, to an arbitrary
number of bases.  The common use is the *Overloaded* helper that merges the
`operator()` of several functor types into one overload set:

```swig

template <typename... Ts>
struct Overloaded : Ts... {
    using Ts::operator()...;   // C++17: pull in every base's operator()
};

```

For two concrete types this is the same as writing out each base and using-declaration
by hand:

```swig

template <typename I, typename D>
struct Overloaded : I, D {
    using I::operator();
    using D::operator();
};

```

SWIG expands the pack during `%template` instantiation into one concrete
using-declaration per base type, exactly as if the explicit form above had been
written.  Pair that with a `%rename` to turn `operator()` into an
ordinary identifier and the instantiated proxy gains a single overloaded method that
dispatches by argument type to the matching base:

```swig

%include <std_string.i>

%rename(call) *::operator();

%inline %{
#include <string>

struct IntCase    { std::string operator()(int v)    const { return "Int:" + std::to_string(v); } };
struct DoubleCase { std::string operator()(double v) const { return "Double:" + std::to_string(v); } };

template <typename... Ts>
struct Overloaded : Ts... {
    using Ts::operator()...;
};
%}

%template(OverloadedIntDouble) Overloaded<IntCase, DoubleCase>;

```

From the target language the merged overload set is reached through the renamed
method, with the usual SWIG overload dispatch selecting the right base:

```cplusplus17

ov = OverloadedIntDouble()
print(ov.call(7))     # "Int:7"
print(ov.call(2.5))   # "Double:2.500000"

```

In C++ this helper is typically passed to `std::visit` over a
`std::variant`, but that is a purely C++ side detail - the wrapped proxy simply
exposes the overloaded method.  An empty pack (for example
`%template(OverloadedEmpty) Overloaded<>`) introduces no names, so the
proxy has no such method.

**Compatibility note:** SWIG-4.5.0 is the first version to parse pack expansion in a
using-declaration and to expand it during `%template` instantiation.

<h3 id="CPlusPlus17_class_template_argument_deduction">9.2.6 Class template argument deduction</h3>

Class template argument deduction (CTAD) lets a variable be declared with a bare class
template name, the template arguments being deduced from the initializer.  The deduction
uses guides synthesised from the class's constructors, so a class template with a
constructor can be used like:

```swig

%inline %{
template <typename T>
struct Box {
    T value;
    Box(T v) : value(v) {}
};

Box bx{42};   // C++17 CTAD - deduces Box<int> from the constructor
%}

```

CTAD is only valid when declaring a variable, so this is the only kind of declaration
affected.  SWIG performs no template argument deduction, so it cannot work out the deduced
type.  It issues Warning 347 and skips the variable; other declarations are unaffected:

```shell

example.i:8: Warning 347: Unable to deduce class template arguments for variable 'bx' of type 'Box' (ignored).

```

C++20 extended CTAD to aggregates; see
[Class template argument deduction](CPlusPlus20/#CPlusPlus20_class_template_argument_deduction)
in the C++20 chapter.

**Compatibility note:** SWIG-4.5.0 is the first version to skip a CTAD variable
declaration cleanly; earlier versions generated uncompilable wrapper code that named the
template without arguments.

<h3 id="CPlusPlus17_deduction_guides">9.2.7 User-defined deduction guides</h3>

As well as the deduction guides the compiler synthesises from a class's constructors, a program can
declare its own user-defined deduction guides to steer class template argument deduction.  A guide
is written at the same scope as the class template, either as a non-template declaration or, when
itself a template, under a template parameter list:

```swig

%inline %{
template <typename T>
struct Box {
    T value;
    Box(T v) : value(v) {}
};

Box(int) -> Box<int>;                      // non-template deduction guide
template <typename T> Box(T *) -> Box<T>;  // templated deduction guide
explicit Box(int, int) -> Box<int>;        // explicit deduction guide
%}

```

A deduction guide is not a function: it has no body and emits no symbol, and only steers argument
deduction at compile time.  There is therefore nothing for SWIG to wrap, so it parses the guide and
discards it.  A guide may carry the optional `explicit` specifier, which is also accepted.

**Compatibility note:** SWIG-4.5.0 is the first version to parse user-defined deduction guides;
earlier versions reported a syntax error.

<h3 id="CPlusPlus17_structured_bindings">9.2.8 Structured bindings</h3>

A structured binding declares a name for each element of the initialiser rather
than a single variable:

```swig

%inline %{
struct Pt {
  int x;
  int y;
};

Pt global_pt = {1, 2};

auto [a, b] = global_pt;
auto& [c, d] = global_pt;
const auto& [e, f] = global_pt;
%}

```

SWIG parses all of these, including the `static` and `auto&&`
spellings, but does not wrap the names.  Giving each name a type means knowing how
the initialiser decomposes, which for a class type depends on its members and for a
tuple-like type on the `std::tuple_size` and `std::tuple_element`
specialisations for it, none of which SWIG resolves.  The declaration is therefore
ignored with warning 349, *Structured binding 'names' is not supported
(ignored)*.

Wrap the members directly, or add an accessor with `%extend`, where a name
is needed in the target language.

Note that a structured binding inside a function body has always been accepted,
because SWIG skips function bodies without parsing them.  Only one at namespace or
class scope reaches the parser.

**Compatibility note:** SWIG-4.6.0 is the first version to parse structured
bindings; earlier versions reported a syntax error.

<h2 id="CPlusPlus17_standard_library_changes">9.3 Standard library changes</h2>

