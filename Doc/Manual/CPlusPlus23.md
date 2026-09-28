

<h1 id="CPlusPlus23">11 SWIG and C++23</h1>

<!-- INDEX -->

<!-- INDEX -->

<h2 id="CPlusPlus23_introduction">11.1 Introduction</h2>

This chapter gives you a brief overview about the SWIG implementation of
the C++23 standard.  Support for the core language features introduced by
C++23 has only just begun.

SWIG accepts `-std=c++23` on the command line.  As for every other
standard, the only effect of the option is to set `__cplusplus` to
the value for that standard, `202302L`, so that a header with
preprocessor checks on the value is handled the way a C++23 compiler would
handle it.  The option does not gate the grammar, so it does not otherwise
change what SWIG parses.  See
[Conditional Compilation](Preprocessor/#Preprocessor_condition_compilation)
in the preprocessor chapter for the full list of standard macros SWIG defines.

<h2 id="CPlusPlus23_core_language_changes">11.2 Core language changes</h2>

<h3 id="CPlusPlus23_explicit_object_parameters">11.2.1 Explicit object parameters</h3>

C++23 lets a member function declare its first parameter with the
`this` specifier, so that the object the function is called on is an
explicit parameter instead of the implicit `*this`.  The feature is
often called "deducing this", as the parameter can be declared with a deduced
`auto` placeholder.

It was added to c++23 mainly to help remove near duplicate code.  A member function whose body
differs only in the constness and value category of the object had to be written
as four almost identical `&`, `const&`, `&&`
and `const&&` ref-qualified overloads, and a deduced explicit
object parameter collapses them into a single function template.  It also lets a
base class member function deduce the derived type without the CRTP idiom, and
lets a lambda name its own closure object, which is how the recursive lambda
shown below is written.

```swig

%inline %{
struct Counter {
  int value;

  Counter() : value(10) {}

  int by_ref(this Counter& self) { return self.value + 1; }
  int by_value(this Counter self) { return self.value + 2; }
  int deduced(this auto&& self) { return self.value + 3; }
  auto deduced_trailing(this auto&& self) -> int { return self.value + 4; }
  int add(this Counter& self, int a, int b) { return self.value + a + b; }
};
%}

```

The explicit object parameter is how the object itself is passed, so it is not
one of the function's arguments.  Each of the above is wrapped as an ordinary
member function taking only the parameters declared after it, that is
`by_ref`, `by_value`, `deduced` and
`deduced_trailing` take no arguments and `add` takes two:

```

c = Counter()
print(c.by_ref())      # 11
print(c.add(1, 2))     # 13

```

A deduced explicit object parameter makes the member function a template in
C++, but the object type is deduced from the object the wrapper passes, so
there is nothing for the user to instantiate and the function is wrapped like
any other member function.  This is unlike a C++20
[abbreviated function template](CPlusPlus20/#CPlusPlus20_abbreviated_templates),
where the invented type template parameter has to be given a type with
`%template`.

C++ requires a member function with an explicit object parameter to be neither
static nor virtual, and it cannot be declared with a cv-qualifier or a
ref-qualifier.  SWIG reports an error for each of these, and for an explicit
object parameter on a function that is not a member function:

```swig

%module example

struct S {
  static int stat(this S& self);
  virtual int virt(this S& self);
  int cv_qualified(this S& self) const;
  int ref_qualified(this S& self) &;
};

int not_a_member(this S& self);

```

```shell

$ swig -c++ -python example.i
example.i:4: Error: Member function stat() with an explicit object parameter 'this' cannot be declared static or virtual.
example.i:5: Error: Member function virt() with an explicit object parameter 'this' cannot be declared static or virtual.
example.i:6: Error: Member function cv_qualified() const with an explicit object parameter 'this' cannot have a qualifier.
example.i:7: Error: Member function ref_qualified() & with an explicit object parameter 'this' cannot have a qualifier.
example.i:10: Error: Function not_a_member() is not a member function so cannot have an explicit object parameter 'this'.

```

An explicit object parameter cannot have a default argument either, and the
parameter itself has to be declared, so `int m(this S& self = S());`
and `int m(this);` are errors too.

A lambda can have an explicit object parameter too, which is the usual way of
writing a recursive lambda.  It is parsed, but a lambda is still wrapped as an
opaque object, as described in
[Lambda functions and expressions](CPlusPlus11/#CPlusPlus11_lambda_functions_and_expressions).

```swig

auto factorial = [](this auto&& self, int n) -> int { return n <= 1 ? 1 : n * self(n - 1); };

```

An explicit object parameter declared as an rvalue reference to the class,
`this Counter&& self`, can only be called on an rvalue.  SWIG calls
the member function on the object the wrapper was passed, which is an lvalue,
so the generated code does not compile and such a member function needs to be
ignored with `%ignore`.  The deduced `this auto&& self` form
is a forwarding reference rather than an rvalue reference and is not affected.

**Compatibility note:** SWIG-4.6.0 is the first version to support explicit
object parameters.  Earlier versions rejected the non-deduced spelling with a
syntax error, and wrapped the deduced `this auto&& self` spelling as
a method taking one argument.

<h2 id="CPlusPlus23_standard_library_changes">11.3 Standard library changes</h2>

The SWIG library does not yet wrap any of the containers and types added
to the standard library by C++23.
