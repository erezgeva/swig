

<h1 id="CPlusPlus20">10 SWIG and C++20</h1>

<!-- INDEX -->

<!-- INDEX -->

<h2 id="CPlusPlus20_introduction">10.1 Introduction</h2>

This chapter gives you a brief overview about the SWIG
implementation of the C++20 standard.
Work has only just begun on adding C++20 support.

**Compatibility note:** SWIG-4.1.0 is the first version to support any C++20 features.

<h2 id="CPlusPlus20_core_language_changes">10.2 Core language changes</h2>

<h3 id="CPlusPlus20_spaceship_operator">10.2.1 Spaceship operator</h3>

The C++20 three-way comparison operator `<=>`, commonly called the
spaceship operator, is parsed, but not wrapped by default.  As with most
[overloaded operators](SWIGPlus/#SWIGPlus_nn28), the C++ name
`operator<=>` is not a valid identifier in the target languages, and
no target language module currently supplies a default renaming for it or maps it
onto a three-way comparison of its own.  The operator in:

```swig

struct Ordered {
  int v;

  std::strong_ordering operator<=>(const Ordered& o) const { return v <=> o.v; }
};

```

is therefore ignored with warning 503 (*Can't wrap 'operator<=\>' unless
renamed to a valid identifier*).  Give it a name the target language can use
and it is wrapped as an ordinary method:

```swig

%rename(compare) Ordered::operator<=>;

```

A comparison operator can also be defaulted, which is how a C++ class opts in to
the compiler generated comparisons:

```swig

%warnfilter(SWIGWARN_CPP14_AUTO) Defaulted::operator<=>;
%rename(is_equal) Defaulted::operator==;

%inline %{
#include <compare>

struct Defaulted {
  int v;

  explicit Defaulted(int v_) : v(v_) { }

  auto operator<=>(const Defaulted&) const = default;
  bool operator==(const Defaulted&) const = default;
};
%}

```

The canonical spelling used above gives the three-way comparison operator a
deduced return type, which SWIG cannot deduce, so `operator<=>` is
ignored for that reason rather than because of its name: the warning is 345
(*Unable to deduce auto return type for 'name' without a trailing return type
(ignored)*), the same as for any other function with an `auto` return
type and no trailing return type.  Renaming makes no difference here, so the
warning is filtered out instead.

The example declares `operator==` as well because C++ declares an equality
operator implicitly for every defaulted three-way comparison operator:
`Defaulted` supports `==` whether or not one is written out.  SWIG
wraps only the declarations it is given, so writing the equality operator out is
what makes the comparison reachable from the target language.  A defaulted
`operator==` has to return `bool`, so unlike
`operator<=>` it has no deduced return type and is wrapped as usual.

The `std::strong_ordering` that `operator<=>` deduces would
not be wrappable as a three-way comparison in any target language anyway, so
ignoring it loses nothing in practice.

SWIG also supports `<=>` in constant expressions.  It does not give
the result of the comparison a type of its own, which does not matter for the
usual case of comparing that result against another ordering or against a literal
`0`, but does mean that a constant whose value is an ordering is not
wrapped:

```swig

#define SPACE (3 <=> 3 == 0)
#define SHIP (1 <=> 2)  // Warning 304: Unsupported constant value (ignored)

```

**Compatibility note:** SWIG-4.6.0 is the first version to parse a defaulted or deleted function that
is declared with a cv-qualifier and an `auto` return type.

<h3 id="CPlusPlus20_lambda_templates">10.2.2 Lambda templates</h3>

SWIG parses lambda templates, but like
[ non-templated lambdas](CPlusPlus11/#CPlusPlus11_lambda_functions_and_expressions), they aren't currently wrapped. For example:

```swig

auto templated_lambda_sum = []<typename T>(std::vector<T> v) {
  return std::reduce(v.begin(), v.end());
};

```

<h3 id="CPlusPlus20_constexpr_destructors">10.2.3 Constexpr destructors</h3>

Destructors that are declared `constexpr` are parsed and handled like any other constructor.
For example:

```swig

class DtorA {
public:
  constexpr ~DtorA() {}
};

```

<h3 id="CPlusPlus20_abbreviated_templates">10.2.4 Abbreviated function templates</h3>

C++20 generalised the C++14
[Generic lambdas](CPlusPlus14/#CPlusPlus14_generic_lambdas)
idea to ordinary functions: an `auto` parameter type in a function
declaration introduces an invented type template parameter, so the
function becomes a function template.  SWIG parses this form and the
function is wrapped by instantiating it with `%template`, just
like an explicit template.  The return type must be explicit; SWIG
cannot deduce `auto` return types without a trailing return type
(the same restriction documented in
[Return type deduction](CPlusPlus14/#CPlusPlus14_return_type_deduction)).

```swig

%inline %{
int add1(auto a) { return a + 1; }
double scale(auto x, auto factor) { return x * factor; }
%}

%template(add1_int) add1<int>;
%template(scale_id) scale<int, double>;

```

In C++20 a concept type-constraint can qualify the `auto`, equivalent to
declaring the invented type template parameter with a
[`requires`-clause](#CPlusPlus20_concepts).
Each constrained `auto` parameter carries its own type-constraint:

```swig

%inline %{
#include <concepts>

template<typename T>
concept Numeric = std::integral<T> || std::floating_point<T>;

int twice_numeric(Numeric auto x) { return x + x; }
double scale_mixed(Numeric auto x, Numeric auto factor) { return x * factor; }
%}

%template(twice_numeric_int) twice_numeric<int>;
%template(scale_mixed_id)    scale_mixed<int, double>;

```

A *constrained auto return type* is parsed using the same syntax.
As with plain `auto` returns, SWIG can only wrap the function
when an explicit trailing return type is provided; without one the
function is ignored with a warning since SWIG cannot deduce the
return type:

```swig

Numeric auto half(int x) -> int { return x / 2; }                    // wrappable
Numeric auto cube_constrained(Sized auto x) -> int { return x*x*x; } // wrappable
Numeric auto times2(int x) { return x * 2; }                         // ignored with warning
Numeric auto times3(int x);                                          // ignored with warning

```

The `auto` parameter form combines freely with an explicit
`template<...>` template parameter list.  Per the C++20
standard each `auto` parameter introduces a distinct invented
type template parameter that is appended to the explicit template
parameter list.
When instantiating with `%template` the user supplies one
argument for each parameter in order - first the explicit parameters,
then one for each `auto` parameter in declaration order:

```swig

%include <std_string.i>

%inline %{
#include <string>

template<typename T>
T tag(T prefix, auto count) { return prefix + std::to_string(count); }
%}

%template(tag_si) tag<std::string, int>;

```

Above, `tag` has two template parameters: the explicit
`T` and an invented type template parameter for the
`auto` parameter.  The `%template` arguments
`<std::string, int>` bind them in that order, so
`T` becomes `std::string` (the type of `prefix`)
and the invented parameter becomes `int` (the type of
`count`).  Calling `tag_si("v", 3)` returns
`"v3"`. Type-constraints and trailing return types mix the same way.

A variadic explicit template pack can also be combined with one or more
`auto` parameters.  Per [dcl.fct]/19 the invented type template parameter
for each `auto` is appended after the explicit list, so when the explicit
list ends in a pack the invented sits past it.  The `%template` argument
list is bound positionally: leading non-variadic parameters first, the variadic
pack absorbs the middle args, and trailing args bind to the invented parms in
declaration order.

```swig

%include <std_string.i>

%inline %{
#include <string>

template<typename... Ts>
std::string f_mix(auto x, Ts... ys);
%}

%template(f_mix_isd) f_mix<int, std::string, double>;

```

Here `f_mix` has the invented type template parameter for `x`
appended after `Ts...`.  The three `%template` arguments bind as
`Ts = {int, std::string}` (absorbed by the pack) and the trailing
`double` binds to the invented parm for `x`, giving the
wrapper signature `f_mix(double x, int y1, std::string y2)`.

An `auto` parameter can itself be a pack.  The invented type template
parameter is then a template parameter pack, just as it is for the equivalent
explicit `template<typename... Ts>` spelling, so the number of types
given to `%template` is the number of parameters the wrapped function
takes:

```swig

%inline %{
int sum(auto... args) { return (args + ... + 0); }
%}

%template(sum_ii)  sum<int, int>;
%template(sum_iii) sum<int, int, int>;

```

`sum_ii` takes two parameters and `sum_iii` takes three.  The
decorated spellings `const auto&...`, `auto&&...` and
`auto*...` introduce a pack in exactly the same way.

The `auto` placeholder may carry the usual parameter decorations -
reference, pointer, forwarding reference, and CV-qualifiers.

```swig

int h(auto& x);                   // reference to invented type
int i(auto* x);                   // pointer to invented type
int j(auto&& x);                  // forwarding reference
int k(const auto x);              // const-qualified by value
int l(const auto& x);             // const reference
int m(Numeric auto& x);           // constrained reference
int n(const Numeric auto& x);     // const-qualified constrained reference

template<typename T>
T o(T x, const auto& y);          // decorated auto mixed with explicit head

```

**Compatibility note:** SWIG-4.5.0 is the first version to parse and support abbreviated function templates with `auto` parameters, including the constrained auto form in both parameter and return type positions, mixing with an explicit template parameter list, and CV-qualifier / reference / pointer decorations on the `auto` placeholder.  SWIG-4.6.0 is the first version to instantiate an `auto` parameter pack, which previously invented a template parameter that was not a pack and so could not be instantiated at all.

<h3 id="CPlusPlus20_concepts">10.2.5 Concepts and requires-clauses</h3>

SWIG provides support for parsing C++20 `concept` declarations
and `requires`-clauses, in both the trailing position (after the
parameter list) and the prefix position (between the template parameter
list and the declarator).  Constraints are accepted on function templates, class
templates and member function templates; both constructs are consumed by
the parser and a constrained template wraps as if it were unconstrained.
This is sufficient for SWIG to accept headers that use concepts to
express template constraints, without the user having to strip them by
hand.  Applying `%template` to a concept is rejected with an
error, since concepts are not types and cannot be instantiated.

The following interface parses cleanly and wraps each instantiation as an
ordinary function template instantiation:

```swig

%inline %{
#include <concepts>

template<typename T>
concept Numeric = std::integral<T> || std::floating_point<T>;

// Trailing requires-clause.
template<typename T>
T cube(T x) requires Numeric<T> {
  return x * x * x;
}

// Prefix requires-clause.
template<typename T>
requires Numeric<T>
T quad(T x) {
  return x * x * x * x;
}
%}

%template(cube_int) cube<int>;
%template(quad_int) quad<int>;

```

Compound prefix constraints joined by `&&` or `||`
and parenthesised constraint subexpressions are also accepted - for
example `requires Numeric<T>&& SmallNumeric<T>` or
`requires (Numeric<T> || std::same_as<T, bool>)`.

When the function has a
[trailing return type](CPlusPlus11/#CPlusPlus11_alternate_function_syntax),
the trailing requires-clause comes after it, the trailing return type being the
end of the declarator:

```swig

template<typename T>
auto negate_value(T x) -> T requires Numeric<T> {
  return -x;
}

%template(negate_value_int) negate_value<int>;

```

The body of a `concept` is not restricted to concept names: any
expression is accepted, including a bare literal and one containing a
top level comparison operator.

```swig

template<typename T>
concept Anything = true;

template<typename T>
concept NonEmpty = sizeof(T) > 0;

```

A `requires`-expression itself - the new C++20 primary that lists
a sequence of requirements in braces - can serve as the primary of a
constraint, giving the "double `requires`" form
`requires requires (...) { ... }`:

```swig

template<typename T>
T add(T a, T b) requires requires (T t) { t + t; } {
  return a + b;
}

%template(add_int) add<int>;

```

Equivalently, the requires-expression can be lifted into a named
`concept` and reused as a constraint:

```swig

template<typename T>
concept Summable = requires (T t) { t + t; };

template<typename T>
T sum_pair(T a, T b) requires Summable<T> {
  return a + b;
}

%template(sum_pair_int) sum_pair<int>;

```

The body of a `requires`-expression can mix simple-requirements
(`expr;`) with compound-requirements that carry a trailing
return-type-requirement
(`{ expr } ->type-constraint;`), for example:

```swig

template<typename T>
concept AddableSame = requires(T a, T b) {
  { a + b } -> std::same_as<T>;
};

template<typename T>
T add_same(T a, T b) requires AddableSame<T> {
  return a + b;
}

%template(add_same_int) add_same<int>;

```

A class template can carry a prefix `requires`-clause on its
template parameter list; the constraint propagates to every instantiation:

```swig

template<typename T>
requires Numeric<T>
class NumericBox {
  T value;
public:
  NumericBox(T v) : value(v) {}
  T cube() const { return value * value * value; }
};

%template(NumericBoxInt) NumericBox<int>;

```

Ordinary methods and constructors of an unconstrained class template can
carry their own trailing `requires`-clause.  Both `int`
and `double` satisfy `Numeric<T>`, so both
instantiations of `CheckedBox` below succeed:

```swig

template<typename T>
class CheckedBox {
  T value;
public:
  CheckedBox() : value(T()) {}
  CheckedBox(T v) requires Numeric<T> : value(v) {}
  T get() const { return value; }
};

%template(CheckedBoxInt)    CheckedBox<int>;
%template(CheckedBoxDouble) CheckedBox<double>;

```

Member function templates of an ordinary (non-templated) class can carry
constraints in either the trailing or prefix position, including on
`static` member function templates:

```swig

class Calculator {
public:
  template<typename T>
  T cube(T x) const requires Numeric<T> { return x * x * x; }

  template<typename T> requires Numeric<T>
  T quad(T x) const { return x * x * x * x; }

  template<typename T>
  static T sum(T a, T b) requires requires(T t) { t + t; } { return a + b; }
};

```

Function templates that share a name and differ in arity may each carry
their own `requires`-clause; SWIG dispatches by argument count at
runtime and the constraints do not affect that path:

```swig

template<typename T> requires Numeric<T>
T accumulate(T a) { return a + 1; }

template<typename T> requires Numeric<T>
T accumulate(T a, T b) { return a + b; }

```

A class template can have a structural partial specialization (such as
`T` against `T*`) whose template parameter list additionally
carries a `requires`-clause.  SWIG selects between primary and partial
spec on the structural pattern alone; the `requires`-clause is
captured but does not participate in selection.  The two specs wrap as
distinct types with their own method sets:

```swig

template<typename T>
struct Storage {
  int primary_method() const { return 100; }
};

template<typename T> requires Numeric<T>
struct Storage<T*> {
  int partial_method() const { return 200; }
};

%template(StorageInt)    Storage<int>;
%template(StorageIntPtr) Storage<int*>;

```

Templated lambdas accept `requires`-clause in all positions, such as:

```swig

auto prefix = []<typename T> requires Numeric<T> (T x) { return x + x; };
auto with_ret = []<typename T>(T x) -> T requires Numeric<T> { return x + x; };

```

Limitations:

- SWIG does not model C++20 constraint subsumption, so two declarations
that share a name and signature and differ only by their
`requires`-clause cannot be distinguished.  This affects two
common patterns:

Function templates that share a name and signature, differing only by
constraint, trip warning 302 (*Redefinition of identifier 'X'
ignored*) and the later declaration is dropped.  Differentiate
constrained overloads by signature - typically a different arity:

```swig

// warning 302 - SWIG cannot pick by constraint, the second declaration is dropped
template<typename T> requires std::integral<T>       T process(T x);
template<typename T> requires std::floating_point<T> T process(T x);

// accepted - SWIG dispatches by argument count
template<typename T> requires Numeric<T> T process(T x);
template<typename T> requires Numeric<T> T process(T x, T y);

```

A class template "partial specialization" whose structural
template-argument pattern is identical to the primary, intended to be
selected by a `requires`-clause alone, is not distinguishable
from the primary.  The last declared candidate wins for every
instantiation:

```swig

template<typename T>                     struct S { /* primary */ };
template<typename T> requires Numeric<T> struct S<T> { /* not selected by SWIG */ };

```

Use a structural pattern (such as `T*`, `T const&`,
etc.) to differentiate partial specs that need to wrap distinctly.

The captured constraint does not drive wrapper code generation: overload
resolution still happens at C++ compile time, by which point SWIG has
already produced the wrapper.  The generated bindings are therefore the
same as for an unconstrained template, for any constraint that the
underlying C++ compiler accepts.

**Compatibility note:** SWIG-4.5.0 is the first version to support C++20 concepts.

<h3 id="CPlusPlus20_type_constrained_template_parameters">10.2.6 Type constrained template parameters</h3>

A *type-constraint* may also stand in place of `typename` /
`class` in a template parameter list.
For example, given the following concept:

```swig

template<typename T>
concept Numeric = std::integral<T> || std::floating_point<T>;

```

the two function declarations below are equivalent and both a C++ compiler and SWIG treats them interchangeably:

```swig

// shorthand
template<Numeric T>
T cube(T x);

// fully spelt out
template<typename T> requires Numeric<T>
T cube(T x);

```

The shorthand fits anywhere `typename` / `class` would
appear: `::`-qualified concept-ids, variadic packs, mixed parameter
lists, default arguments and class templates are all accepted, such as:

```swig

template<Numeric T>                     T cube(T x);                  // single
template<nest::Integral T>              T half(T x);                  // ::-qualified
template<Numeric T, typename U>         T scale(T x, U factor);       // mixed
template<Numeric T = int>               T identity(T x);              // default arg
template<Numeric... Ts>                 int count_numeric(Ts...);     // variadic pack
template<Numeric T> class Box { T v; };                               // class template

```

Wrapping procedes by remapping the template parameter from `Numeric T` to `typename T`.
If the concept definition has not been parsed by SWIG the remap is still
applied silently, since SWIG always tries a best effort approach to wrapping
partial type information.
The generated wrapper emits the templated call literally and the C++ compiler
resolves the constraint when compiling the generated wrapper code.
For example, the following wraps cleanly even though SWIG has not seen the
declaration of `Numeric`:

```swig

// SWIG has not parsed 'Numeric' anywhere
template<Numeric T>
T cube(T x) { return x * x * x; }
%template(cube_int) cube<int>;

```

The examples above all use single parameter concepts, but a type-constraint may
itself be a concept-id with explicit template arguments.  This is the form most
often seen with the STL and SWIG also supports these two parameter concepts such as
`std::convertible_to<From, To>`, `std::same_as<T, U>`,
`std::derived_from<Derived, Base>` and
`std::predicate<F, Args...>`.

The rule the C++ standard gives is that the constrained template parameter is
prepended to the list in angle brackets to form the full concept-id, becoming the
*first* argument; the arguments written inside the brackets supply the
remaining arguments.  So the shorthand:

```swig

template<std::convertible_to<int> T>
T to_int(T x);

```

is equivalent to the fully spelt out form:

```swig

template<typename T> requires std::convertible_to<T, int>
T to_int(T x);

```

that is, `T` is constrained to be convertible to `int`.  A
user defined two parameter concept follows the same rule:

```swig

%inline %{
template<typename T, typename U>
concept Pair = std::convertible_to<T, U>;

template<Pair<int> T>        // requires Pair<T, int>
int first_int(T x) { return (int)x; }
%}

%template(first_int_d) first_int<double>;

```

**Compatibility note:** SWIG-4.5.0 is the first version to parse template parameters
carrying a type-constraint, including the template-id form above.

<h3 id="CPlusPlus20_constrained_alias_templates">10.2.7 Constrained alias templates</h3>

A C++11 alias template
(see [Alias templates](CPlusPlus11/#CPlusPlus11_alias_templates)
in the C++11 chapter) may carry a C++20 concept constraint on its template
parameters, in either the type-constraint shorthand form or the
`requires`-clause long form:

```swig

template<typename T>
concept Numeric = std::integral<T> || std::floating_point<T>;

template<typename T>
class Box { T v; public: Box(T x):v(x){} T get() const { return v; } };

// shorthand
template<Numeric T>
using NumBox = Box<T>;

// fully spelt out (equivalent)
template<typename T> requires Numeric<T>
using ReqBox = Box<T>;

```

SWIG accepts both forms.  Both aliases resolve to the same underlying
`Box<T>`, and the generated wrappers are identical to those for
an unconstrained alias.  Wrapping uses the same two-step pattern as any
other alias template as described in
[Alias templates](CPlusPlus11/#CPlusPlus11_alias_templates)
- instantiate the underlying template once with
`%template(Name)`, then register each alias with an empty
`%template()`:

```swig

%template(BoxInt) Box<int>;
%template() NumBox<int>;
%template() ReqBox<int>;

```

SWIG does not enforce the constraint itself; the C++ compiler resolves it
when compiling the generated wrapper.  An unparsed concept name in the
parameter list is silently remapped to `typename`, following SWIG's
best effort policy for partial type information.

**Compatibility note:** SWIG-4.5.0 is the first version to parse the
`requires`-clause form on alias templates.

<h3 id="CPlusPlus20_variable_templates">10.2.8 Variable templates initialised from a requires-expression</h3>

C++14 already permitted a variable template
(see [Variable templates](CPlusPlus14/#CPlusPlus14_variable_templates) in the C++14 chapter).  C++20 adds the
`requires`-expression, a new primary that evaluates to `bool`
and whose body lists requirements for a type, and these two pair naturally:
a variable template can be declared `constexpr bool` and initialised
from a `requires`-expression to give a compile time predicate over
the template parameter.  This is the variable template equivalent of the
type trait `_v` pattern (such as `std::is_integral_v`) that `<type_traits>` uses to
expose a class template trait as a bool variable,
written without needing a separate concept declaration.

```swig

%inline %{
template<typename T>
constexpr bool Addable = requires (T t) { t + t; };

struct NotAddable {};   // empty struct, no operator+
%}

%template(addable_int)        Addable<int>;          // read only bool = true
%template(addable_notaddable) Addable<NotAddable>;   // read only bool = false

```

SWIG cannot evaluate the requirements at parse time; the C++ compiler
decides the value at instantiation time and the wrapper exposes the
resulting bool.  A `requires`-expression is always typed
`bool` by the standard, so this idiom is effectively limited to
`bool`-typed variable templates - any other declared type would
have to be implicitly constructible from `bool` to compile, and is
not idiomatic.

**Compatibility note:** SWIG-4.5.0 is the first version to parse a
`requires`-expression in expression position.

<h3 id="CPlusPlus20_class_template_argument_deduction">10.2.9 Class template argument deduction</h3>

C++20 (P1816) extended
[class template argument deduction (CTAD)](CPlusPlus17/#CPlusPlus17_class_template_argument_deduction)
to aggregates - which have no constructors to deduce from - so an aggregate variable such as
the [Overloaded](CPlusPlus17/#CPlusPlus17_using_pack_expansion) helper can be
declared with a bare class template name and no explicit deduction guide:

```swig

Overloaded ov{ IntCase{}, DoubleCase{} };   // C++20 aggregate CTAD

```

SWIG handles aggregate CTAD exactly as it handles any other CTAD variable: it performs no
template argument deduction, so it issues Warning 347 and skips the variable.  See
[Class template argument deduction](CPlusPlus17/#CPlusPlus17_class_template_argument_deduction)
in the C++17 chapter for details.

<h2 id="CPlusPlus20_preprocessor_changes">10.3 Preprocessor changes</h2>

<h3 id="CPlusPlus20_va_opt">10.3.1 __VA_OPT__()</h3>

Support for `__VA_OPT__()` was added in SWIG 4.3.0.

<h2 id="CPlusPlus20_standard_library_changes">10.4 Standard library changes</h2>

