

# <a name="CPlusPlus11"></a> 7 SWIG and C++11

<!-- INDEX -->

<!-- INDEX -->

## <a name="CPlusPlus11_introduction"></a> 7.1 Introduction

This chapter gives you a brief overview about the SWIG
implementation of the C++11 standard.

SWIG supports the new C++ syntax changes with some minor limitations
in some areas such as decltype expressions and variadic templates. Wrappers for the
new STL types (unordered_ containers, result_of, tuples) are incomplete.
The wrappers for the new containers would work much like the C++03 containers and 
users are welcome to help by adapting the existing container interface files and submitting them
as a patch for inclusion in future versions of SWIG.

## <a name="CPlusPlus11_core_language_changes"></a> 7.2 Core language changes

### <a name="CPlusPlus11_rvalue_reference_and_move_semantics"></a> 7.2.1 Rvalue reference and move semantics

SWIG correctly parses the rvalue reference syntax '&&',
for example the typical usage of it in the move constructor and move assignment operator below:

```swig

class MyClass {
...
  std::vector<int> numbers;
public:
  MyClass() : numbers() {}
  MyClass(MyClass &&other) : numbers(std::move(other.numbers)) {}
  MyClass & operator=(MyClass &&other) {
    numbers = std::move(other.numbers);
    return *this;
  }
};

```

Rvalue references are designed for C++ temporaries and are not particularly useful when used from non-C++ target languages.
One option is to just ignore them via `%ignore`.
For example, ignore the move constructor:

```swig

%ignore MyClass::MyClass(MyClass &&);

```

#### <a name="CPlusPlus11_rvalue_reference_inputs"></a> 7.2.1.1 Rvalue reference inputs

Rvalue reference parameters are useful as input parameters in C++ for implementing move semantics, such as,
in the move constructor and move assignment operator.
This type of usage can be useful from target languages too to avoid copying large objects.

If you do wrap a function/constructor with an rvalue reference parameter and pass a proxy class to it, SWIG will assume that after the call, the rvalue reference parameter object will have been 'moved'.
The proxy class passed as the rvalue reference, will own the underlying C++ object up until it is used as an rvalue reference parameter.
Afterwards, the proxy class will have the underlying C++ pointer set to the nullptr so that the proxy class instance cannot be used again and the underlying (moved from) C++ object will be deleted after the function/constructor call has returned.

In this way, the SWIG proxy class works much like an exclusively owned smart pointer (think of `std::unique_ptr`), passing ownership to the called C++ function/constructor.
Let's consider an example in Java using the wrapped proxy class from above:

```cplusplus11

MyClass mc = new MyClass();
MyClass mc1 = new MyClass(mc); // move constructor
MyClass mc2 = new MyClass(mc); // move constructor fails

```

The second call to the move constructor will fail as the `mc` proxy instance has been moved.
Each target language handles the moved proxy class slightly differently when attempting to move it again, but typically you'll get an exception such as in Java:

```shell

Exception in thread "main" java.lang.RuntimeException: Cannot release ownership as memory is not owned
        at MyClass.swigRelease(MyClass.java:27)
        at MyClass.<init>(MyClass.java:55)
        at runme.main(runme.java:18)

```

Note that both normal copy assignment operators as well as move assignment operators are ignored by default in the target languages with the following warning:

```shell

example.i:18: Warning 503: Can't wrap 'operator =' unless renamed to a valid identifier.

```

Using a `%rename` will remove the warning and also makes the move assignment operator available from the target language:

```swig

%rename(MoveAssign) MyClass::operator=(MyClass &&);

```

You can then use it, but like the move constructor example above, you cannot use
a proxy class once it has already been moved:

```cplusplus11

MyClass mc = new MyClass();
MyClass mc2 = mc.MoveAssign(mc);
MyClass mc3 = mc.MoveAssign(mc); // Use of mc again will fail

```

It is of course perfectly possible in C++ for a function/constructor to not move an object passed to it in an rvalue reference parameter. The assumption that SWIG makes would then not hold and customisation of the appropriate input typemaps would be required.
For scripting languages, this would be for the 'in' typemap and for the non-scripting languages additional typemaps such as the 'javain' typemap, which is used to set the memory ownership of the underlying C++ object for Java, would also need copying and modifying appropriately.

**Compatibility note:**
SWIG-4.1.0 changed the way that rvalue reference parameters were handled and implemented typemaps assuming that the
proxy class owns the underlying C++ object and transfers ownership of the object when a function/constructor with an rvalue reference parameter is called.

#### <a name="CPlusPlus11_rvalue_reference_outputs"></a> 7.2.1.2 Rvalue reference outputs

While rvalue reference parameter inputs are not uncommon in C++ and can be usefully utilised from target languages, this cannot be said for rvalue reference outputs.
Firstly, it is quite unusual in C++ to have functions that return an rvalue reference.
Secondly, these cases are nigh on impossible to use from a target language.
The main problem is these references are for C++ compiler temporaries used on the stack and the target languages use objects on the heap
and the concept of compiler temporary objects doesn't make sense from another language.

Using `MyClass` from earlier and this C++ code:

```swig

void use(MyClass &&mc);
MyClass && get1();
MyClass & get2();

```

SWIG wraps the `get1` and `get2` functions more or less identically.
The returned references are converted into pointers that are not owned by the target language.
It means that the following perfectly valid C++ has no equivalent in any of the target languages:

```swig

use(get1());
use(std::move(get2()));

```

An attempt to call the equivalent `use(get1())` from one of the target languages will result in the ownership failure mentioned in the previous section as the object being passed to the `use` function is not owned by the proxy class.
In order to own the object, it would need to be cloned for the object to move from the stack to the heap, for which an appropriate clone function would be required, but may not even be available.
Note that a move constructor or copy constructor may slice the object when inheritance is involved.
Alternatively, customising the input rvalue reference typemap, as mentioned in the previous section, could remove the ownership requirement.
Another alternative would be to modify the output rvalue reference typemap to always clone the rvalue reference object.
Fortunately you're highly unlikely to have to solve any of these issues!

#### <a name="CPlusPlus11_move_only"></a> 7.2.1.3 Movable and move-only types by value

SWIG has traditionally relied on wrapped C++ types to be copy constructible or copy assignable, either via an explicit or implicit copy constructor and copy assignment operator.
Prior to C++11, a function could not return nor take a type by value that was not copyable.
In C++11 this is no longer the case. A type can also be movable if it has has a move constructor and a move assignment operator.
A move-only type is movable but not copyable; it has both the copy constructor and copy assignment operator deleted.
Movable types can appear in function signatures for passing 'by value' and in C++11 the object can then be moved rather than copied.

SWIG has support for both copyable and/or movable types.
Support for move semantics is quite seamless when returning by value from a function.
Support for move semantics is less so and may require some customisation when passing by value to a function.
First let's consider returning by value from a function.

The support for function return values is generically implemented in the "out" `SWIGTYPE` typemap which supports any type, including copyable, movable and move-only types.
The typemap code is very simple and written so that the compiler will call the move constructor if possible,
otherwise the copy constructor:

```swig

%typemap(out) SWIGTYPE %{
  $result = new $1_ltype($1);
%}

```

The above typemap is for C# and when used to wrap a move-only type such as:

```swig

struct MoveOnly {
  int  val;
  MoveOnly(): val(0)  {}

  MoveOnly(const MoveOnly &) = delete;
  MoveOnly(MoveOnly &&) = default;

  MoveOnly & operator=(const MoveOnly &) = delete;
  MoveOnly & operator=(MoveOnly &&) = default;

  static MoveOnly create() { return MoveOnly(); }
  static void take(MoveOnly mo);
};

```

will generate wrapper code for the `create` factory method:

```swig

SWIGEXPORT void * SWIGSTDCALL CSharp_MoveOnly_create() {
  void * jresult ;
  SwigValueWrapper< MoveOnly > result;

  result = MoveOnly::create();
  jresult = new MoveOnly(result);
  return jresult;
}

```

`SwigValueWrapper` is covered in [Pass and return by value](SWIGPlus/#SWIGPlus_nn19) and is automatically generated in this case as `MoveOnly` is not assignable.
Note that the generated code could be optimised further using the ["optimal" attribute](Typemaps/#Typemaps_optimal)
in the "out" typemap, so if the above typemap is customised as follows (note that this is C# specific):

```swig

%typemap(out, optimal="1") MoveOnly %{
  $result = new $1_ltype($1);
%}

```

then the generated code will result in the object being optimally moved:

```swig

SWIGEXPORT void * SWIGSTDCALL CSharp_MoveOnly_create() {
  void * jresult ;
  jresult = new MoveOnly(MoveOnly::create());
  return jresult;
}

```

Now let's consider passing by value.
We'll consider three cases; namely types that are:

1. Copyable and not movable - `CopyOnly`.
1. Copyable and movable - `MovableCopyable`.
1. Movable and not copyable - `MoveOnly`.

and for clarification, define these two additional types as follows:

```swig

struct CopyOnly {
  int  val;
  CopyOnly(): val(0)  {}

  CopyOnly(const CopyOnly &) = default;
  CopyOnly & operator=(const CopyOnly &) = default;

  static CopyOnly create() { return CopyOnly(); }
  static void take(CopyOnly co);
};

struct MovableCopyable {
  int  val;
  MovableCopyable(): val(0)  {}

  MovableCopyable(const MovableCopyable &) = default;
  MovableCopyable(MovableCopyable &&) = default;
  MovableCopyable & operator=(const MovableCopyable &) = default;
  MovableCopyable & operator=(MovableCopyable &&) = default;

  static MovableCopyable create() { return MovableCopyable(); }
  static void take(MovableCopyable mc);
};

```

The generated code is shown below for `CopyOnly::take` (with additional comments for when constructors and assignment operators are called).
While the code shown is C# specific, the generated constructor and/or assignment operator calls are ultimately the same for all target languages.

```swig

SWIGEXPORT void SWIGSTDCALL CSharp_CopyOnly_take(void * jarg1) {
  CopyOnly arg1 ; // (a) Default constructor
  CopyOnly *argp1 ;
  
  argp1 = (CopyOnly *)jarg1; 
  if (!argp1) {
    SWIG_CSharpSetPendingExceptionArgument(SWIG_CSharpArgumentNullException, "Attempt to dereference null CopyOnly", 0);
    return ;
  }
  arg1 = *argp1; // (b) Copy assignment
  CopyOnly::take(SWIG_STD_MOVE(arg1)); // (c) Copy constructor
}

```

Note that `SWIG_STD_MOVE` is a macro defined as shown below to use `std::move` which is only available from C++11 onwards:

```swig

#if __cplusplus >=201103L
# define SWIG_STD_MOVE(OBJ) std::move(OBJ)
#else
# define SWIG_STD_MOVE(OBJ) OBJ
#endif

```

Also note: *(c) Copy constructor*.
Yes, when passing by value the copy constructor is called for all versions of C++, even C++11 and later even though std::move is specified.
It's a C++ language feature for types that don't have move semantics!

The generated code for `MovableCopyable::take` is the same as for `CopyOnly::take`, however, the C++ compiler will choose the move constructor this time where commented *(c) Move constructor*:

```swig

SWIGEXPORT void SWIGSTDCALL CSharp_MovableCopyable_take(void * jarg1) {
  MovableCopyable arg1 ; // (a) Default constructor
  MovableCopyable *argp1 ;
  
  argp1 = (MovableCopyable *)jarg1; 
  if (!argp1) {
    SWIG_CSharpSetPendingExceptionArgument(SWIG_CSharpArgumentNullException, "Attempt to dereference null MovableCopyable", 0);
    return ;
  }
  arg1 = *argp1; // (b) Copy assignment
  MovableCopyable::take(SWIG_STD_MOVE(arg1)); // (c) Move constructor
}

```

There are two optimisation opportunities available.

1. Remove the default constructor call with the `%feature("valuewrapper")` covered in [Pass and return by value](SWIGPlus/#SWIGPlus_nn19) and replace it with `SwigValueWrapper`.
1. Apply the SWIGTYPE MOVE typemaps which are designed specifically to implement full move semantics when passing parameters by value.
    They replace the copy assignment with a call to `SwigValueWrapper::reset`, which works much like `std::unique_ptr::reset`.
    These typemaps could alternatively have replaced the copy assignment with a move assignment, but this is not maximally optimal.

Simply add the following before the `MovableCopyable::take` method is parsed:

```swig

%valuewrapper MovableCopyable;
%include <swigmove.i>
%apply SWIGTYPE MOVE { MovableCopyable }

```

will result in this optimal code where just one move constructor is invoked:

```swig

SWIGEXPORT void SWIGSTDCALL CSharp_MovableCopyable_take(void * jarg1) {
  SwigValueWrapper< MovableCopyable > arg1 ; // (a) No constructors invoked
  MovableCopyable *argp1 ;
  
  argp1 = (MovableCopyable *)jarg1;
  if (!argp1) {
    SWIG_CSharpSetPendingExceptionArgument(SWIG_CSharpArgumentNullException, "Attempt to dereference null MovableCopyable", 0);
    return ;
  }
  SwigValueWrapper< MovableCopyable >::reset(arg1, argp1);  // (b) No constructor or assignment operator invoked
  MovableCopyable::take(SWIG_STD_MOVE(arg1)); // (c) Move constructor
}

```

Note that `SwigValueWrapper` will call the destructor for the pointer passed to it in the `reset` function.
This pointer is the underlying C++ object that the proxy class owns.
The details aren't shown, but the 'csin' typemap also generates C# code to ensure that the proxy class releases ownership of the object.
Please see the 'SWIGTYPE MOVE' typemaps in the swigmove.i file provided for each target language.
Therefore full move semantics are implemented; ownership is moved from the proxy class into the C++ layer and the net effect
is the same as using an [rvalue reference parameter](#CPlusPlus11_rvalue_reference_inputs) discussed earlier.

Lastly, let's consider the `MoveOnly::take` function defined earlier.
By default the generated code fails to compile as `MoveOnly` does not have a copy assignment operator.
SWIG is not designed to select a different typemap automatically for move-only types and the user
must apply the SWIGTYPE MOVE typemaps to ensure that only move-only semantics are used.
However, SWIG is able to automatically use `%feature("valuewrapper")` for move-only
types so it is not necessary to explicitly use this feature.
So in this move-only case, simply add the following before `MoveOnly::take` is parsed, which results in the same optimal code shown above for `MovableCopyable`:

```swig

%include <swigmove.i>
%apply SWIGTYPE MOVE { MoveOnly }

```

**Compatibility note:**
SWIG-4.1.0 introduced support for taking advantage of types with move semantics and making it possible to easily use move only types.

### <a name="CPlusPlus11_generalized_constant_expressions"></a> 7.2.2 Generalized constant expressions

SWIG parses and identifies the keyword `constexpr`, but cannot fully utilise it.
These C++ compile time constants are usable as runtime constants from the target languages.
Below shows example usage for assigning a C++ compile time constant from a compile time constant function:

```swig

constexpr int XXX() { return 10; }
constexpr int YYY = XXX() + 100;

```

When either of these is used from a target language, a runtime call is made to obtain the underlying constant.

### <a name="CPlusPlus11_extern_template"></a> 7.2.3 Extern template

SWIG correctly parses `extern template` explicit instantiation declarations.
However, this template instantiation suppression in a translation unit has no relevance outside of the C++ compiler and so is not used by SWIG.
SWIG only uses `%template` for instantiating and wrapping templates.
Consider the class template below:

```swig

// Class template
template class std::vector<int>;        // C++03 template explicit instantiation definition in C++
extern template class std::vector<int>; // C++11 template explicit instantiation declaration (extern template)
%template(VectorInt) std::vector<int>;  // SWIG template instantiation

```

The above result in warnings:

```shell

example.i:2: Warning 320: Explicit template instantiation ignored.
example.i:3: Warning 327: Extern template ignored.

```

Similarly for the function template below:

```swig

// Function template
template void Func<int>();              // C++03 template explicit instantiation definition in C++
extern template void Func<int>();       // C++11 template explicit instantiation declaration (extern template)
%template(FuncInt) Func<int>;           // SWIG template instantiation

```

### <a name="CPlusPlus11_initializer_lists"></a> 7.2.4 Initializer lists

Initializer lists are very much a C++ compiler construct and are not very accessible from wrappers as
they are intended for compile time initialization of classes using the special `std::initializer_list` type.
SWIG detects usage of initializer lists and will emit a special informative warning each time one is used:

```shell

example.i:33: Warning 476: Initialization using std::initializer_list.

```

Initializer lists usually appear in constructors but can appear in any function or method.
They often appear in constructors which are overloaded with alternative approaches to initializing a class,
such as the std container's push_back method for adding elements to a container.
The recommended approach then is to simply ignore the initializer-list constructor, for example:

```swig

%ignore Container::Container(std::initializer_list<int>);
class Container {
public:
  Container(std::initializer_list<int>); // initializer-list constructor
  Container();
  void push_back(const int &);
  ...
};

```

Alternatively you could modify the class and add another constructor for initialization by some other means,
for example by a `std::vector`:

```swig

%include <std_vector.i>
class Container {
public:
  Container(const std::vector<int>&);
  Container(std::initializer_list<int>); // initializer-list constructor
  Container();
  void push_back(const int &);
  ...
};

```

And then call this constructor from your target language, for example, in Python, the following will call the constructor taking the `std::vector`:

```cplusplus11
>>> c = Container( [1, 2, 3, 4] )

```

If you are unable to modify the class being wrapped, consider ignoring the initializer-list constructor and using
%extend to add in an alternative constructor:

```swig

%include <std_vector.i>
%extend Container {
  Container(const std::vector<int>&elements) {
    Container *c = new Container();
    for (int element : elements)
      c->push_back(element);
    return c;
  }
}

%ignore Container::Container(std::initializer_list<int>);

class Container {
public:
  Container(std::initializer_list<int>); // initializer-list constructor
  Container();
  void push_back(const int &);
  ...
};

```

The above makes the wrappers look is as if the class had been declared as follows:

```swig

%include <std_vector.i>
class Container {
public:
  Container(const std::vector<int>&);
//  Container(std::initializer_list<int>); // initializer-list constructor (ignored)
  Container();
  void push_back(const int &);
  ...
};

```

`std::initializer_list` is simply a container that can only be initialized at compile time.
As it is just a C++ type, it is possible to write typemaps for a target language container to map onto
`std::initializer_list`. However, this can only be done for a fixed number of elements as
initializer lists are not designed to be constructed with a variable number of arguments at runtime.
The example below is a very simple approach which ignores any parameters passed in and merely initializes
with a fixed list of fixed integer values chosen at compile time:

```swig

%typemap(in) std::initializer_list<int> {
  $1 = {10, 20, 30, 40, 50};
}
class Container {
public:
  Container(std::initializer_list<int>); // initializer-list constructor
  Container();
  void push_back(const int &);
  ...
};

```

Any attempt at passing in values from the target language will be ignored and be replaced by `{10, 20, 30, 40, 50}`.
Needless to say, this approach is very limited, but could be improved upon, but only slightly.
A typemap could be written to map a fixed number of elements on to the `std::initializer_list`,
but with values decided at runtime.
The typemaps would be target language specific.

Note that the default typemap for `std::initializer_list` does nothing but issue the warning
and hence any user supplied typemaps will override it and suppress the warning.

### <a name="CPlusPlus11_uniform_initialization"></a> 7.2.5 Uniform initialization

The curly brackets {} for member initialization are fully
supported by SWIG:

```swig

struct BasicStruct {
 int x;
 double y;
};
 
struct AltStruct {
  AltStruct(int x, double y) : x_{x}, y_{y} {}
 
  int x_;
  double y_;
};

BasicStruct var1{5, 3.2}; // only fills the struct components
AltStruct var2{2, 4.3};   // calls the constructor

```

Uniform initialization does not affect usage from the target language, for example in Python:

```cplusplus11
>>> a = AltStruct(10, 142.15)
>>> a.x_
10
>>> a.y_
142.15

```

### <a name="CPlusPlus11_type_inference"></a> 7.2.6 Type inference

`decltype()` is supported with a few limitations.  SWIG can parse
all uses, but can't deduce the type in every situation where a C++ compiler
can.  The cases SWIG can deduce have expanded with time and hopefully will
continue to.  For example, for the code

```swig

int i;
decltype(i) j;
decltype(i+j) k;

```

SWIG is able to deduce that the variable `i` and the expression
`i+j` both have type `int`.

Using an expression for the decltype which SWIG can't handle results in a warning:

```swig

int foo(int);
decltype(foo(0)) k;  // Warning 344: Unable to deduce decltype for 'foo(0)'.

```

This warning should be viewed as a prompt to add in a manual ignore of the variable/function as
in most cases the generated code will not compile.
For the example above, ignore the symbol that is declared using `decltype` and perhaps additionally
suppress the warning as follows:

```swig

#pragma SWIG nowarn=SWIGWARN_CPP11_DECLTYPE
%ignore k;

```

If an ignore is not acceptable, a workaround is to redefine the symbol with the actual type, for example:

```swig

int k; // define k with the actual type
%ignore k; // ignore the real definition of k

```

You would typically put one of these workarounds in your interface file before
using `%include` to get SWIG to parse the header which defines `k`.

SWIG supports `auto` as a type specifier for variables (with the same limitations
for actually deducing the type as for `decltype()`), and for specifying
the return type of [lambdas](#CPlusPlus11_lambda_functions_and_expressions)
and [functions](#CPlusPlus11_alternate_function_syntax).

An `auto` variable can carry a declarator, so the placeholder can be decorated with a
reference, rvalue reference, pointer or cv-qualifier, just like an `auto` function parameter.
The decoration is kept on the wrapped variable:

```swig

int g = 42;
int *pg = &g;

auto& r1 = g;            // int &
const auto& r2 = g;      // const int &
auto&& r3 = 42;          // int &&
auto* p1 = &g;           // int *
auto* const p2 = &g;     // int *const
auto** p3 = &pg;         // int **
auto const* p4 = &g;     // const int * - a cv-qualifier may also follow the placeholder

```

The type is deduced from the initialiser, using the declaration a name in the initialiser refers to,
so the declarator of that declaration is part of the deduced type. Taking the address of something in
scope deduces a pointer to it, and a named cast deduces the type it casts to:

```swig

int fn(int x);

auto v1 = pg;                       // int *
auto v2 = &fn;                      // int (*)(int)
auto v3 = static_cast<double>(g);   // double

```

As C++ requires, the top level cv-qualifiers of the initialiser are dropped unless the variable is a
reference, so `r2` above is a `const int&` while a by value `auto` initialised
from a `const int` is a plain `int`.

A braced initialiser holding a single element deduces the type of that element, which is the C++17
rule for this form:

```swig

auto v4{42};   // int
auto* v5{&g};  // int *

```

A declaration declaring more than one variable is wrapped a variable at a time, each declarator keeping
its own decoration:

```swig

auto v6 = 1, v7 = 2;    // two ints
auto v8 = 3, *v9 = &g;  // an int and an int *

```

C++ requires every declarator in the list to deduce to the same type, so a declarator SWIG cannot
deduce a type from takes the type deduced for the others, whichever of them that was:

```swig

auto v10 = fn(1), v11 = 2;  // both int, deduced from '2'

```

Two declarators deducing different types is not valid C++, and SWIG says so while wrapping each
variable with the type its own initialiser deduces, so that

```swig

auto v12 = 1, v13 = 2.5;

```

gives:

```shell

example.i:28: Warning 348: Inconsistent auto type deduction for variable 'v13': initialiser '2.5' deduces 'double', not 'int'.

```

Only fundamental types are compared this way, because a typedef cannot be resolved while the
declaration is being parsed, so a mismatch involving anything else goes unreported.

The type still has to be deducible from the initialiser. Where no declarator of a declaration deduces
one, the variables are dropped after issuing warning 346, and the warning says which of the two got in
the way. An initialiser SWIG understands but cannot deduce a type from, such as a function call or the
[`nullptr`](#CPlusPlus11_null_pointer_constant) literal, names the initialiser:

```swig

auto v14 = nullptr;

```

```shell

example.i:30: Warning 346: Unable to deduce auto type for variable 'v14' from initialiser 'nullptr' (ignored).

```

while an initialiser in a form SWIG does not support, such as a braced initialiser holding more than
one element or a new expression, says so instead:

```swig

auto v15 = {g, 1};

```

```shell

example.i:32: Warning 346: Unable to deduce auto type for variable 'v15' from an unsupported initialiser (ignored).

```

The usual workaround for either is to ignore the variable, or to declare it with its actual type in
the interface file, in the same way as for a `decltype` SWIG cannot deduce.

### <a name="CPlusPlus11_range_based_for_loop"></a> 7.2.7 Range-based for-loop

This feature is part of the implementation block only. SWIG
ignores it.

### <a name="CPlusPlus11_lambda_functions_and_expressions"></a> 7.2.8 Lambda functions and expressions

SWIG correctly parses most of the Lambda functions syntax. For example:

```swig

auto val = [] { return something; };
auto sum = [](int x, int y) { return x+y; };
auto sum = [](int x, int y) -> int { return x+y; };

```

The explicit trailing return type can be any type, just as it can be for an
[ordinary function](#CPlusPlus11_alternate_function_syntax):

```swig

auto address = [](int &x) -> int * { return &x; };
auto value = [](int &x) -> const int & { return x; };

```

The lambda functions are removed from the wrappers for now, because of the lack of support
for closures (scope of the lambda functions) in the target languages.

Lambda functions used to create variables can also be parsed, but due to limited support of `auto` when
the type is deduced from the expression, the variables are simply ignored.

```swig

auto six = [](int x, int y) { return x+y; }(4, 2);

```

Better support should be available in a later release.

Lambdas are most useful at the SWIG boundary when returned to the target language as a
`std::function` object - see
[Polymorphic wrappers for function objects](#CPlusPlus11_polymorphous_wrappers_for_function_objects).

### <a name="CPlusPlus11_alternate_function_syntax"></a> 7.2.9 Alternate function syntax

SWIG fully supports the new definition of functions. For example:

```swig

struct SomeStruct {
  int FuncName(int x, int y);
};

```

can now be written as in C++11:

```swig

struct SomeStruct {
  auto FuncName(int x, int y) -> int;
};
 
auto SomeStruct::FuncName(int x, int y) -> int {
  return x + y;
}

```

The usage in the target languages remains the same, for example in Python:

```cplusplus11
>>> a = SomeStruct()
>>> a.FuncName(10, 5)
15

```

SWIG will also deal with type inference for the return type, as per the limitations described earlier. For example:

```swig

auto square(float a, float b) -> decltype(a);

```

The trailing return type can be any type, including a pointer, a reference to a primitive type, an array reference or a function pointer:

```swig

struct MoreTrailing {
  auto count() -> const int&;
  auto data() -> int *;
  auto values() -> int (&)[3];
  auto callback() -> int (*)(int);
};

```

SWIG has one restriction that C++ does not: a pointer to member trailing return type has to be written with parentheses, `auto member() -> int (MoreTrailing::*);`.
C++ accepts the unparenthesised `auto member() -> int MoreTrailing::*;` equally well, but SWIG reports a syntax error for that spelling.

**Compatibility note:** SWIG-4.6.0 is the first version to accept a pointer or a reference to a primitive type as a trailing return type.
Earlier versions accepted only a small set of trailing return types and reported a syntax error for the rest.

### <a name="CPlusPlus11_object_construction_improvement"></a> 7.2.10 Object construction improvement

There are three parts to object construction improvement.
The first improvement is constructor delegation such as the following:

```swig

class A {
public:
  int a;
  int b;
  int c;

  A() : A(10) {}
  A(int aa) : A(aa, 20) {}
  A(int aa, int bb) : A(aa, bb, 30) {}
  A(int aa, int bb, int cc) { a=aa; b=bb; c=cc; }
};

```

where peer constructors can be called. SWIG handles this without any issue.

The second improvement is constructor inheritance via a `using` declaration.
The extra constructors provided by the `using` declaration will add the appropriate constructors into the target language proxy derived classes.
In the example below a wrapper for the `DerivedClass(int)` constructor is added to `DerivedClass`:

```swig

class BaseClass {
public:
  BaseClass(int iValue);
};

class DerivedClass: public BaseClass {
  public:
  using BaseClass::BaseClass; // Adds DerivedClass(int) constructor
};

```

**Compatibility note:** SWIG-4.2.0 was the first version to generate wrappers for constructors inherited via `using` declarations.

The final part is member initialization at the site of the declaration.
This kind of initialization is handled by SWIG.

```swig

class SomeClass {
public:
  SomeClass() {}
  explicit SomeClass(int new_value) : value(new_value) {}

  int value = 5;
};

```

### <a name="CPlusPlus11_using_declaration_template_base"></a> 7.2.11 Inheriting members through a template parameter base

A class template that takes a type-template parameter as its base class - a form of the *mixin* idiom -
can pull inherited members into the derived scope with a using-declaration whose qualifier is the template parameter itself:

```swig

struct IntCase {
  std::string call(int v) const;
};

template <typename I>
struct Derived : I {
  using I::call;
};

%template(DerivedInt) Derived<IntCase>;

```

SWIG substitutes the template parameter during instantiation, so the using-declaration
in `DerivedInt` resolves to `IntCase::call` and a `call` wrapper is emitted on the
derived proxy just as if the using-declaration had named `IntCase::call` directly.

The same applies to inheriting constructors, even when the immediate base class is named through a typedef rather
than by its class name. This is common when the base is a template instantiation:

```swig

struct A {
  A();
  A(int a);
};

template <typename Parent>
struct C : Parent {
  using Parent::Parent;
};

%template(CA) C<A>;

struct D : C<A> {
  typedef C<A> base_type;
  using base_type::base_type;     // inherit C<A>'s constructors through the typedef
};

```

SWIG resolves the typedef qualifier to the base class, so both `CA` and `D` wrap the inherited
`int` constructor and can be constructed with an integer argument from the target language.

**Compatibility note:** SWIG-4.5.0 is the first version to resolve a using-declaration whose qualifier is a
bare type-template parameter or a typedef for the base class, including the inheriting-constructor forms.

### <a name="CPlusPlus11_explicit_overrides_final"></a> 7.2.12 Explicit overrides and final

The special identifiers `final` and `override` can be used on methods and destructors,
such as in the following example:

```swig

struct BaseStruct {
  virtual void ab() const = 0;
  virtual void cd();
  virtual void ef();
  virtual ~BaseStruct();
};
struct DerivedStruct : BaseStruct {
  virtual void ab() const override;
  virtual void cd() final;
  virtual void ef() final override;
  virtual ~DerivedStruct() override;
};

```

Classes can also be marked as final, such as

```swig

struct FinalDerivedStruct final : BaseStruct {
  virtual void ab() const override;
};

```

**Compatibility note:** Final methods were supported much earlier than final classes. SWIG-4.1.0 was the first version to support classes marked as final.

### <a name="CPlusPlus11_null_pointer_constant"></a> 7.2.13 Null pointer constant

The `nullptr` constant is mostly unimportant in wrappers. Where it is the default value of a
function parameter and the target language writes default values of its own rather than leaving them to
the C++ layer, `nullptr` becomes that language's null rather than the C++ spelling, so a parameter
defaulted to `nullptr` is generated as defaulted to `None` by Python and is documented as
defaulted to `nil` by Ruby. Elsewhere it is treated like `NULL`.

SWIG does not deduce a type from `nullptr`, so an
[`auto`](#CPlusPlus11_type_inference) variable initialised with it trips warning 346
(*Unable to deduce auto type for variable 'v' from initialiser 'nullptr' (ignored)*) and is dropped,
the same as for any other initialiser SWIG cannot deduce a type from.

### <a name="CPlusPlus11_strongly_typed_enumerations"></a> 7.2.14 Strongly typed enumerations

SWIG supports strongly typed enumerations and parses the new `enum class` syntax and forward declarator for the enums, such as:

```swig

enum class MyEnum : unsigned int;

```

Strongly typed enums are often used to avoid name clashes such as the following:

```swig

struct Color {
  enum class RainbowColors : unsigned int {
    Red, Orange, Yellow, Green, Blue, Indigo, Violet
  };
  
  enum class WarmColors {
    Yellow, Orange, Red
  };

  // Note normal enum
  enum PrimeColors {
    Red=100, Green, Blue
  };
};

```

There are various ways that the target languages handle enums, so it is not possible to precisely state how they are handled in this section.
However, generally, most scripting languages mangle in the strongly typed enumeration's class name,
but do not use any additional mangling for normal enumerations. For example, in Python, the following code

```cplusplus11

print(Color.RainbowColors_Red, Color.WarmColors_Red, Color.Red)

```

results in

```shell

0 2 100

```

The strongly typed languages often wrap normal enums into an enum class and so treat normal enums and strongly typed enums the same.
The equivalent in Java is:

```cplusplus11

System.out.println(Color.RainbowColors.Red.swigValue() + " "
                   + Color.WarmColors.Red.swigValue() + " "
                   + Color.PrimeColors.Red.swigValue());

```

The C++11 enum base type, such as `unsigned int`, in the example above, is used by some language modules and is missing support in others. For example, in C#, the enum base type in the example above is used and converted into a C# `uint` to specify the underlying C# enumeration type as follows:

```cplusplus11

  public enum RainbowColors : uint {
    Red,
    Orange,
    Yellow,
    Green,
    Blue,
    Indigo,
    Violet
  }

```

### <a name="CPlusPlus11_double_angle_brackets"></a> 7.2.15 Double angle brackets

SWIG correctly parses the symbols \>\> as closing the
template block, if found inside it at the top level, or as the right
shift operator \>\> otherwise.

```swig

std::vector<std::vector<int>> myIntTable;

```

### <a name="CPlusPlus11_explicit_conversion_operators"></a> 7.2.16 Explicit conversion operators

SWIG correctly parses the keyword `explicit` for operators in addition to constructors now.
For example:

```swig

class U {
public:
  int u;
};

class V {
public:
  int v;
};

class TestClass {
public:
  //implicit converting constructor
  TestClass(U const &val) { t=val.u; }

  // explicit constructor
  explicit TestClass(V const &val) { t=val.v; }

  int t;
};

struct Testable {
  // explicit conversion operator
  explicit operator bool() const {
    return false;
  }
};

```

The effect of explicit constructors and operators has little relevance for the proxy classes as target
languages don't have the same concepts of implicit conversions as C++.
Conversion operators either with or without `explicit` need renaming to a valid identifier name in order to make
them available as a normal proxy method.

### <a name="CPlusPlus11_type_aliases"></a> 7.2.17 Type aliases

A type alias introduces a new name for an existing type using the C++11 `using` syntax:

```swig

using PFD = void (*)(double); // C++11 type alias

```

which is equivalent to the older `typedef`:

```swig

typedef void (*PFD)(double);  // Equivalent typedef

```

SWIG handles a type alias exactly as it handles the equivalent `typedef`, so no special
treatment is required.

A function type can also be written with the
[alternate function syntax](#CPlusPlus11_alternate_function_syntax), in an alias
declaration or an alias template:

```swig

using alt_callback_t = auto (*)(int) -> int;
using alt_function_t = auto (int) -> int;

template<typename T> using alt_fn_t = auto (*)(T) -> T;

```

**Compatibility note:** SWIG-4.6.0 is the first version to accept a trailing return type in an alias declaration.
The equivalent `typedef` spelling was already accepted.

### <a name="CPlusPlus11_alias_templates"></a> 7.2.18 Alias templates

An alias template is a template whose instantiation yields a type alias - in effect a family of type
aliases parameterised like a class template.  It is written with the `using` syntax and may fix
some of the underlying template's parameters while leaving others open:

```swig

template<typename T1, typename T2, int N>
class SomeType {
public:
  T1 a;
  T2 b;
};

// Alias template: fixes T1 and N, leaves T2 open.
template<typename T2>
using TypedefName = SomeType<char*, T2, 5>;

```

SWIG does not automatically instantiate templates, so an alias template instantiation has to be
registered before it can be wrapped.  This takes two `%template` directives - one for the
underlying template and an empty one for the alias:

```swig

%template(SomeTypeBool) SomeType<char*, bool, 5>; // instantiate the underlying template
%template()             TypedefName<bool>;        // register the alias instantiation

```

The first directive instantiates the underlying template under a name the target language will use, as
for any wrapped template.  The empty `%template()` adds the alias instantiation to the type
system, telling SWIG that `TypedefName<bool>` denotes `SomeType<char*, bool, 5>`.
Once both directives have been processed the alias and the underlying instantiation are
interchangeable: a function returning `TypedefName<bool>`, for example, is wrapped using the
`SomeTypeBool` class.  See the [Templates](SWIGPlus/#SWIGPlus_nn30) section for
more on wrapping templates.

Once registered, the alias can be used wherever the underlying instantiation can: as a base class, and
as the scope qualifier of a using-declaration that imports inherited members or constructors.  For
example, given the following classes:

```swig

template<typename T> struct Adder {
  T add(T a, T b) { return a + b; }
};
template<typename T> using AdderAlias = Adder<T>;

struct Calc : AdderAlias<int> {   // alias template as a base class
  using AdderAlias<int>::add;     // alias template as a using-declaration qualifier
};

```

The underlying `Adder` template needs to be instantiated as usual and the alias instantiation
`AdderAlias<int>` should be registered with an empty `%template()` so that it resolves to
`Adder<int>` both as `Calc`'s base class and as the using-declaration qualifier.  If the
empty `%template()` is omitted SWIG does not recognise the alias instantiation and issues a
'Nothing known about' warning - Warning 401 for the base class, Warning 315 for the using-declaration:

```swig

%template(AdderInt) Adder<int>;
%template()         AdderAlias<int>; // register the alias instantiation used as the base

```

For alias templates whose template parameters carry a C++20 concept constraint, see
[Constrained alias templates](CPlusPlus20/#CPlusPlus20_constrained_alias_templates)
in the C++20 chapter.

### <a name="CPlusPlus11_unrestricted_unions"></a> 7.2.19 Unrestricted unions

SWIG fully supports any type inside a union even if it does not
define a trivial constructor. For example, the wrapper for the following
code correctly provides access to all members in the union:

```swig

struct point {
  point() {}
  point(int x, int y) : x_(x), y_(y) {}
  int x_, y_;
};

#include <new> // For placement 'new' in the constructor below
union P {
  int z;
  double w;
  point p; // Illegal in C++03; legal in C++11.
  // Due to the point member, a constructor definition is required.
  P() {
    new(&p) point();
  }
} p1;

```

### <a name="CPlusPlus11_variadic_templates"></a> 7.2.20 Variadic templates

SWIG supports the variadic templates including the <\>
variadic class inheritance, variadic methods, variadic constructors and
initializers. Example:

```swig

template <typename... BaseClasses> class ClassName : public BaseClasses... {
public:
  ClassName(BaseClasses &&... baseClasses) : BaseClasses(baseClasses)... {}
  void InstanceMethod(const BaseClasses&... baseClasses) {}
};

```

The `%template` directive works as expected for variable template parameters.

```swig

struct A {
  virtual void amethod();
  virtual ~A();
};
struct B {
  virtual void bmethod();
  virtual ~B();
};
%template(ClassName0) ClassName<>
%template(ClassName1) ClassName<A>
%template(ClassName2) ClassName<A, B>
```

Example usage from say Python:

```cplusplus11

cn0 = ClassName0()
cn0.InstanceMethod()

a = A()
cn1 = ClassName1(a)
cn1.amethod()
cn1.InstanceMethod(a)

b = B()
cn2 = ClassName2(a, b)
cn2.InstanceMethod(a, b)
cn2.amethod()
cn2.bmethod()

```

Support for the variadic `sizeof()` function also works:

```swig

const int SIZE = sizeof...(ClassName<A, B>);

```

In the above example `SIZE` is of course wrapped as a constant.

**Compatibility note:** SWIG-4.2.0 was the first version to fully support variadic templates.
SWIG-3.0.0 provided initial support and was limited to only one variadic parameter.

### <a name="CPlusPlus11_new_char_literals"></a> 7.2.21 New character literals

C++11 adds support for UCS-2 and UCS-4 character literals.
These character literals are preceded by either 'u' or 'U'.

```swig

char16_t a = u'a';
char32_t b = U'b';

```

**Compatibility note:** SWIG-4.0.0 was the first version to support these Universal Coded Character Set (UCS) character literals.

### <a name="CPlusPlus11_new_string_literals"></a> 7.2.22 New string literals

SWIG supports wide string and Unicode string constants and raw string literals.

```swig

// New string literals
wstring         aa =  L"Wide string";
const char     *bb = u8"UTF-8 string";
const char16_t *cc =  u"UTF-16 string";
const char32_t *dd =  U"UTF-32 string";

// Raw string literals
const char      *xx =        ")I'm an \"ascii\" \\ string.";
const char      *ee =   R"XXX()I'm an "ascii" \ string.)XXX"; // same as xx
wstring          ff =  LR"XXX(I'm a "raw wide" \ string.)XXX";
const char      *gg = u8R"XXX(I'm a "raw UTF-8" \ string.)XXX";
const char16_t  *hh =  uR"XXX(I'm a "raw UTF-16" \ string.)XXX";
const char32_t  *ii =  UR"XXX(I'm a "raw UTF-32" \ string.)XXX";

```

Non-ASCII string support varies quite a bit among the various target languages though.

Note: There is a bug currently where SWIG's preprocessor incorrectly parses an odd number of double quotes
inside raw string literals.

### <a name="CPlusPlus11_user_defined_literals"></a> 7.2.23 User-defined literals

SWIG parses the declaration of user-defined literals, that is, the `operator "" _mysuffix()` function syntax.

Some examples are the raw literal:

```swig

OutputType operator "" _myRawLiteral(const char * value);

```

numeric cooked literals:

```swig

OutputType operator "" _mySuffixIntegral(unsigned long long);
OutputType operator "" _mySuffixFloat(long double);

```

and cooked string literals:

```swig

OutputType operator "" _mySuffix(const char * string_values, size_t num_chars);
OutputType operator "" _mySuffix(const wchar_t * string_values, size_t num_chars);
OutputType operator "" _mySuffix(const char16_t * string_values, size_t num_chars);
OutputType operator "" _mySuffix(const char32_t * string_values, size_t num_chars);

```

Like other operators that SWIG parses, a warning is given about renaming the operator in order for it to be wrapped:

```shell

example.i:27: Warning 503: Can't wrap 'operator "" _myRawLiteral' unless renamed to a valid identifier.

```

If %rename is used, then it can be called like any other wrapped method.
Currently you need to specify the full declaration including parameters for %rename:

```swig

%rename(MyRawLiteral)  operator"" _myRawLiteral(const char * value);

```

Or if you just wish to ignore it altogether:

```swig

%ignore operator "" _myRawLiteral(const char * value);

```

Note that use of user-defined literals such as the following still give a syntax error:

```swig

OutputType var1 = "1234"_suffix;
OutputType var2 = 1234_suffix;
OutputType var3 = 3.1416_suffix;

```

### <a name="CPlusPlus11_thread_local_storage"></a> 7.2.24 Thread-local storage

SWIG correctly parses the `thread_local` keyword. For example, variables
reachable by the current thread can be defined as:

```swig

struct A {
  static thread_local int val;
};
thread_local int global_val;

```

The use of the `thread_local` storage specifier does not affect the wrapping process; it does not modify
the wrapper code compared to when it is not specified.
A variable will be thread local if accessed from different threads from the target language in the
same way that it will be thread local if accessed from C++ code.

### <a name="CPlusPlus11_defaulted_deleted"></a> 7.2.25 Explicitly defaulted functions and deleted functions

SWIG handles explicitly defaulted functions, that is, `= default` added to a function declaration. Deleted definitions, which are also called deleted functions, have `= delete` added to the function declaration.
For example:

```swig

struct NonCopyable {
  NonCopyable & operator=(const NonCopyable &) = delete; /* Removes operator= */
  NonCopyable(const NonCopyable &) = delete;             /* Removes copy constructor */
  NonCopyable() = default;                               /* Explicitly allows the empty constructor */
};

```

Wrappers for deleted functions will not be available in the target language.
Wrappers for defaulted functions will of course be available in the target language.
Explicitly defaulted functions have no direct effect for SWIG wrapping as the declaration is handled
much like any other method declaration parsed by SWIG.

Deleted functions are also designed to prevent implicit conversions when calling the function.
For example, the C++ compiler will not compile any code which attempts to use an int as the type of the parameter passed to `f` below:

```swig

struct NoInt {
  void f(double i);
  void f(int) = delete;
};

```

This is a C++ compile time check and SWIG does not make any attempt to detect if the target language is using an int instead of a double though,
so in this case it is entirely possible to pass an int instead of a double to `f` from Java, Python etc.

### <a name="CPlusPlus11_type_long_long_int"></a> 7.2.26 Type long long int

SWIG correctly parses and uses the new `long long` type already introduced in C99 some time ago.

### <a name="CPlusPlus11_static_assertions"></a> 7.2.27 Static assertions

SWIG correctly parses the new `static_assert` declarations (though 3.0.12 and earlier
had a bug which meant this wasn't accepted at file scope).
This is a C++ compile time directive so there isn't anything useful that SWIG can do with it.

```swig

template <typename T>
struct Check {
  static_assert(sizeof(int) <= sizeof(T), "not big enough");
};

```

### <a name="CPlusPlus11_sizeof"></a> 7.2.28 Allow sizeof to work on members of classes without an explicit object

SWIG can parse the new sizeof() on types as well as on objects. For example:

```swig

struct A {
  int member;
};

const int SIZE = sizeof(A::member); // does not work with C++03. Okay with C++11

```

In Python:

```cplusplus11
>>> SIZE
8

```

### <a name="CPlusPlus11_noexcept"></a> 7.2.29 Exception specifications and noexcept

C++11 added in the noexcept specification to exception specifications to indicate that a function simply may or may not throw an exception, without actually naming any exception.
SWIG understands these, although there isn't any useful way that this information can be taken advantage of by target languages,
so it is as good as ignored during the wrapping process.
Below are some examples of noexcept in function declarations:

```swig

static void noex1() noexcept;
int noex2(int) noexcept(true);
int noex3(int, bool) noexcept(false);

```

### <a name="CPlusPlus11_alignment"></a> 7.2.30 Control and query object alignment

An `alignof` operator is used mostly within C++ to return alignment in number of bytes, but could be used to initialize a variable as shown below.
The variable's value will be available for access by the target language as any other variable's compile time initialised value.

```swig

const int align1 = alignof(A::member);

```

The `alignas` specifier for variable alignment is not yet supported.
Example usage:

```swig

struct alignas(16) S {
  int num;
};
alignas(double) unsigned char c[sizeof(double)];

```

Use the preprocessor to work around this for now:

```swig

#define alignas(T)

```

### <a name="CPlusPlus11_attributes"></a> 7.2.31 Attributes

Attributes such as those shown below, are supported since SWIG 4.1.0 but are
currently crudely ignored by the parser's tokeniser so they have no effect on
SWIG's code generation.

```swig

int [[attr1]] i [[attr2, attr3]];

[[noreturn, nothrow]] void f [[noreturn]] ();

```

### <a name="CPlusPlus11_ref_qualifiers"></a> 7.2.32 Methods with ref-qualifiers

C++11 non-static member functions can be declared with ref-qualifiers.
Member functions declared with a `&` lvalue ref-qualifiers are wrapped like any other function without ref-qualifiers.
Member functions declared with a `&&` rvalue ref-qualifiers are ignored by default
as they are unlikely to be required from non-C++ languages where the concept of *rvalue-ness*
for the implied *this pointer does not apply.
The warning is hidden by default, but can be displayed as described in the section on [Enabling extra warnings](Warnings/#Warnings_nn4).

Consider:

```swig

struct RQ {
  void m1(int x) &;
  void m2(int x) &&;
};

```

The only wrapped method will be the lvalue ref-qualified method `m1`
and if SWIG is run with the `-Wextra` command-line option, the following warning will be issued indicating `m2` is not wrapped:

```shell

example.i:7: Warning 405: Method with rvalue ref-qualifier m2(int) && ignored.

```

If you unignore the method as follows, wrappers for `m2` will be generated:

```swig

%feature("ignore", "0") RQ::m2(int x) &&;
struct RQ {
  void m1(int x) &;
  void m2(int x) &&;
};

```

Inspection of the generated C++ code, will show that `std::move` is used on the instance
of the `RQ *` class:

```swig

  RQ *arg1 = (RQ *) 0 ;
  int arg2 ;

  arg1 = ...marshalled from target language...
  arg2 = ...marshalled from target language...

  std::move(*arg1).m2(arg2);

```

This will compile but when run, the move effects may not be what you want.
As stated earlier, rvalue ref-qualifiers aren't really applicable outside the world of C++.
However, if you really know what you are doing, full control over the call to the method is
possible via the low-level "action" feature.
This feature completely replaces the call to the underlying function, that is, the last line in the snippet of code above.

```swig

%feature("ignore", "0") RQ::m2(int x) &&;
%feature("action") RQ::m2(int x) && %{
  RQ().m2(arg2);
%}
struct RQ {
  void m1(int x) &;
  void m2(int x) &&;
};

```

resulting in:

```swig

  RQ *arg1 = (RQ *) 0 ;
  int arg2 ;

  arg1 = ...marshalled from target language...
  arg2 = ...marshalled from target language...

  RQ().m2(arg2);

```

**Compatibility note:** SWIG-4.0.0 was the first version to support ref-qualifiers.

## <a name="CPlusPlus11_standard_library_changes"></a> 7.3 Standard library changes

### <a name="CPlusPlus11_threading_facilities"></a> 7.3.1 Threading facilities

SWIG does not currently wrap or use any of the new threading
classes introduced (thread, mutex, locks, condition variables, task). The main reason is that
SWIG target languages offer their own threading facilities so there is limited use for them.

### <a name="CPlusPlus11_tuple_types"></a> 7.3.2 Tuple types

SWIG does not provide library files for the new tuple types yet.
Variadic template support requires further work to provide substantial tuple wrappers.

### <a name="CPlusPlus11_hash_tables"></a> 7.3.3 Hash tables

The new hash tables in the STL are `unordered_set`, `unordered_multiset`, `unordered_map`, `unordered_multimap`.
These are not available in all target languages.
Any missing support can in principle be easily implemented by adapting the current STL containers.

### <a name="CPlusPlus11_regular_expressions"></a> 7.3.4 Regular expressions

While SWIG could provide wrappers for the new C++11 regular expressions classes, there is little need as the target languages have their own regular expression facilities.

### <a name="CPlusPlus11_general_purpose_smart_pointers"></a> 7.3.5 General-purpose smart pointers

SWIG provides special smart pointer handling for `std::shared_ptr` in the same way it has support for `boost::shared_ptr`.
Please see the [shared_ptr smart pointer](Library/#Library_std_shared_ptr)
and [unique_ptr smart pointer](Library/#Library_std_unique_ptr) library sections.
There is no special smart pointer handling available for `std::weak_ptr`.

### <a name="CPlusPlus11_extensible_random_number_facility"></a> 7.3.6 Extensible random number facility

This feature extends and standardizes the standard library only and does not affect the C++ language nor SWIG.

### <a name="CPlusPlus11_wrapper_reference"></a> 7.3.7 Wrapper reference

Wrapper references are similar to normal C++ references but are copy-constructible and copy-assignable.
They could conceivably be used in public APIs.
There is no special support for `std::reference_wrapper` in SWIG though.
Users would need to write their own typemaps if wrapper references are being used and these would be similar to the plain C++ reference typemaps.

### <a name="CPlusPlus11_polymorphous_wrappers_for_function_objects"></a> 7.3.8 Polymorphic wrappers for function objects

SWIG supports functor classes in a few languages in a very natural way.
A plain functor - a class with `operator()` - can be wrapped
directly; from Python the rename to `__call__` makes the wrapped
instance directly invocable as a function:

```swig

%rename(__call__) Test::operator(); // Default renaming used for Python

struct Test {
  bool operator()(int x, int y); // function object
};

```

```cplusplus11

t = Test()
b = t(1, 2) # invoke C++ function object

```

For the polymorphic `std::function` wrapper, SWIG provides
`std_function.i` in the SWIG library. It wraps the partial specialisation
`std::function<RET(ARGS...)>` so that any C++ callable - a
free function, a lambda, a bound member function, or a functor - can be
returned from C++ to the target language and invoked there. See
[std::function](Library/#Library_std_function)
in the SWIG library chapter for the worked example, the supported pattern,
and the list of caveats.

`std::function` moves a callable from C++ *out* to the target
language. To go the other way - have C++ accept a callable defined in
the target language - see
[Pointers to functions and callbacks](SWIG/#SWIG_nn30)
for the C-side `%callback` mechanism, and
[Callbacks to the target language](SWIGPlus/#SWIGPlus_target_language_callbacks)
for the C++ director-based mechanism.

### <a name="CPlusPlus11_type_traits_for_metaprogramming"></a> 7.3.9 Type traits for metaprogramming

The type_traits functions to support C++ metaprogramming is useful at compile time and is aimed specifically at C++ development:

```swig

#include <type_traits>

// First way of operating.
template< bool B > struct algorithm {
  template< class T1, class T2 > static int do_it(T1 &, T2 &)  { /*...*/ return 1; }
};

// Second way of operating.
template<> struct algorithm<true> {
  template< class T1, class T2 > static int do_it(T1, T2)  { /*...*/ return 2; }
};

// Instantiating 'elaborate' will automatically instantiate the correct way to operate, depending on the types used.
template< class T1, class T2 > int elaborate(T1 A, T2 B) {
  // Use the second way only if 'T1' is an integer and if 'T2' is a floating point,
  // otherwise use the first way.
  return algorithm< std::is_integral<T1>::value && std::is_floating_point<T2>::value >::do_it(A, B);
}

```

SWIG correctly parses the template specialization, template types etc.
However, metaprogramming and the additional support in the type_traits header is really for compile time and is not much use at runtime for the target languages.
For example, as SWIG requires explicit instantiation of templates via `%template`, there isn't much that `std::is_integral<int>` is going to provide by itself.
However, template functions using such metaprogramming techniques might be useful to wrap.
For example, the following instantiations could be made:

```swig

%template(Elaborate) elaborate<int, int>;
%template(Elaborate) elaborate<int, double>;

```

Then the appropriate algorithm can be called for the subset of types given by the above `%template` instantiations from a target language, such as Python:

```cplusplus11
>>> Elaborate(0, 0)
1
>>> Elaborate(0, 0.0)
2

```

### <a name="CPlusPlus11_uniform_method_for_computing_return_type_of_function_objects"></a> 7.3.10 Uniform method for computing return type of function objects

The new `std::result_of` class introduced in the <functional\> header provides a generic way to obtain the return type of a function type via `std::result_of::type`.
There isn't any library interface file to support this type.
With a bit of work, SWIG will deduce the return type of functions when used in `std::result_of` using the approach shown below.
The technique basically forward declares the `std::result_of` template class, then partially specializes it for the function types of interest.
SWIG will use the partial specialization and hence correctly use the `std::result_of::type` provided in the partial specialization.

```swig

%inline %{
#include <functional>
typedef double(*fn_ptr)(double);
%}

namespace std {
  // Forward declaration of result_of
  template<typename Func> struct result_of;
  // Add in a partial specialization of result_of
  template<> struct result_of< fn_ptr(double) > {
    typedef double type;
  };
}

%template() std::result_of< fn_ptr(double) >;

%inline %{

double square(double x) {
  return (x * x);
}

template<class Fun, class Arg>
typename std::result_of<Fun(Arg)>::type test_result_impl(Fun fun, Arg arg) {
  return fun(arg);
}
%}

%template(test_result) test_result_impl< fn_ptr, double >;
%constant double (*SQUARE)(double) = square;

```

Note the first use of `%template` which SWIG requires to instantiate the template.
The empty template instantiation suffices as no proxy class is required for `std::result_of<Fun(Arg)>::type` as this type is really just a `double`.
The second `%template` instantiates the template function which is being wrapped for use as a callback.
The `%constant` can then be used for any callback function as described in [Pointers to functions and callbacks](SWIG/#SWIG_nn30).

Example usage from Python should give the not too surprising result:

```cplusplus11
>>> test_result(SQUARE, 5.0)
25.0

```

Phew, that is a lot of hard work to get a callback working.
You could just go with the more attractive option of just using `double` as the return type in the function declaration instead of `result_of`!
