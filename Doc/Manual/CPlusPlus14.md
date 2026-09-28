

<h1 id="CPlusPlus14">8 SWIG and C++14</h1>

<!-- INDEX -->

<!-- INDEX -->

<h2 id="CPlusPlus14_introduction">8.1 Introduction</h2>

This chapter gives you a brief overview about the SWIG
implementation of the C++14 standard.
There isn't much in C++14 that affects SWIG, however, work has only just begun on adding
C++14 support.

**Compatibility note:** SWIG-4.0.0 is the first version to support any C++14 features.

<h2 id="CPlusPlus14_core_language_changes">8.2 Core language changes</h2>

<h3 id="CPlusPlus14_binary_literals">8.2.1 Binary integer literals</h3>

C++14 added binary integer literals and SWIG supports these.
Example:

```swig

int b = 0b101011;

```

<h3 id="CPlusPlus14_return_type_deduction">8.2.2 Return type deduction</h3>

C++14 added the ability to specify `auto` for the return type of a function
and have the compiler deduce it from the body of the function (in C++11 you had
to explicitly specify a trailing return type if you used `auto` for the
return type).

SWIG parses these types of functions, but with one significant limitation: SWIG
can't actually deduce the return type!  If you want to wrap such a function
you will need to tell SWIG the return type explicitly.

The trick for specifying the return type is to use `%ignore` to tell
SWIG to ignore the function with the deduced return type, but first provide
SWIG with an alternative declaration of the function with an explicit return
type.  The generated wrapper will wrap this alternative declaration, and the
call in the wrapper to the function will call the actual declaration.  Here is
an actual example:

```swig

std::tuple<int, int> va_static_cast();
%ignore va_static_cast();
#pragma SWIG nowarn=SWIGWARN_CPP14_AUTO

%inline %{
#include <tuple>

auto va_static_cast() {
    return std::make_tuple(0, 0);
}
%}

```

For member methods the trick is to use `%extend` to redeclare the method and call it as follows:

```swig

%extend X {
  const char * a() const { return $self->a(); }
}
%inline %{
struct X {
  auto a() const {
    return "a string";
  }
};
%}

```

A conversion function can have a deduced return type too, and the same
workaround applies:

```swig

%warnfilter(SWIGWARN_CPP14_AUTO) Deduced::operator auto;

%extend Deduced {
  int toInt() const { return static_cast<int>(*$self); }
}

%inline %{
struct Deduced {
  int v;
  Deduced(int vv) : v(vv) {}
  operator auto() const { return v; }
};
%}

```

A deleted function can be declared with a deduced return type as well, for
example `auto m() const = delete;`.  Deleted functions are never wrapped,
so this needs no workaround and no warning is issued.

**Compatibility note:** SWIG-4.2.0 first introduced support for functions declared with an auto return without a trailing return type.
SWIG 4.4.0 added support for forward declarations of such functions.
SWIG-4.6.0 added support for a conversion function with a deduced return type.

<h3 id="CPlusPlus14_decltype_auto">8.2.3 decltype(auto)</h3>

C++14 added a second placeholder type, `decltype(auto)`, which can be used
anywhere `auto` can.  The two deduce differently: `auto` deduces as a
template parameter does, dropping references and top level cv-qualifiers, while
`decltype(auto)` deduces the declared type of the initialiser exactly.

```swig

%inline %{
int global_int = 42;
int& global_ref = global_int;
const int global_const = 7;

auto           plain_var = global_ref;    // int
decltype(auto) exact_var = global_ref;    // int &
decltype(auto) const_var = global_const;  // const int
%}

```

SWIG wraps each of these variables with the type it deduces, so
`exact_var` is wrapped as a reference where `plain_var` is wrapped as a
plain `int`.

Used as a return type, `decltype(auto)` has to be deduced from the function
body, which SWIG does not analyse, so the function is ignored with warning 345,
*Unable to deduce auto return type for 'name' (ignored)*, in the same way as
a function returning `auto` with no trailing return type.  The workarounds
shown in [Return type deduction](#CPlusPlus14_return_type_deduction)
apply here too.

```swig

%inline %{
decltype(auto) deduced_from_body() { return global_int; }  // ignored, warning 345
%}

```

**Compatibility note:** SWIG-4.6.0 added support for `decltype(auto)`.
Earlier versions reported a syntax error which could not be recovered from, so the
rest of the file was not parsed.

<h3 id="CPlusPlus14_generic_lambdas">8.2.4 Generic lambdas</h3>

C++14 lifted the restriction that lambda parameters be explicit types and
allowed `auto` as a parameter type, making the lambda a templated
function object whose `operator()` deduces each `auto`
parameter at the call site.  SWIG parses generic lambdas, but - like non-templated
[Lambda functions and expressions](CPlusPlus11/#CPlusPlus11_lambda_functions_and_expressions) - they are not currently automatically wrapped.  Users
should write additional code to call the lambda from an ordinary wrapped
function as a workaround, for example:

```swig

%inline %{
auto twice = [](auto x) { return x + x; };
auto add = [](auto a, auto b) { return a + b; };

int run_twice(int x)      { return twice(x); }
int run_add(int a, int b) { return add(a, b); }
%}

```

Return type deduction applies to a lambda too, so the explicit trailing return
type of a lambda can be the `auto` placeholder, cv-qualified or decorated
with a reference or a pointer:

```swig

%inline %{
int thing = 7;

auto negate_value = [](int x) -> auto { return -x; };
auto halve = [](int x) -> const auto { return x / 2; };
auto reference_thing = [](int) -> auto&& { return thing; };
auto address_of_thing = [](int) -> auto* { return &thing; };
%}

```

**Compatibility note:** SWIG-4.5.0 is the first version to parse generic lambdas with `auto` parameters.
SWIG-4.6.0 is the first version to parse a lambda whose explicit trailing return type is the `auto` placeholder.

<h3 id="CPlusPlus14_variable_templates">8.2.5 Variable templates</h3>

C++14 added variable templates - templated `constexpr` (or
`const`) variables whose value depends on the template arguments.
The pattern mirrors the `_v` aliases the standard library uses for
type traits: a typed compile time constant derived from a template
parameter, written once and instantiated wherever the parameter changes.
SWIG parses variable templates, and a `%template` instantiation of
one is wrapped as a read only variable holding the value:

```swig

%inline %{
template<typename T>
constexpr int bits_in = sizeof(T) * 8;
%}

%template(bits_in_char) bits_in<char>;   // wraps as read only int = 8

```

Non-type template parameters are also accepted, so a variable template can
hold the result of a compile time computation indexed by an integer.
Precomputing the result at instantiation avoids the work being repeated
on each call at runtime:

```swig

%inline %{
constexpr int compute_factorial(int n) {
  return n <= 1 ? 1 : n * compute_factorial(n - 1);
}

template<int N>
constexpr int factorial = compute_factorial(N);
%}

%template(factorial_5)  factorial<5>;    // 120
%template(factorial_10) factorial<10>;   // 3628800

```

**Compatibility note:** SWIG-3.0.0 is the first version to parse C++14
variable templates and wrap a `%template` instantiation of one as a
read only variable.

<h2 id="CPlusPlus14_standard_library_changes">8.3 Standard library changes</h2>

