

# <a name="Octave"></a> 32 SWIG and Octave

<!-- INDEX -->

<!-- INDEX -->

Octave is a high-level language intended for numerical programming that is mostly compatible with MATLAB.
More information can be found at [Octave web site](https://octave.org/).

This chapter is intended to give an introduction to using the module. You should also read the SWIG documentation that is not specific to Octave.
Also, there are a dozen or so examples in the Examples/octave directory, and hundreds in the test suite (Examples/test-suite and Examples/test-suite/octave).

## <a name="Octave_nn2"></a> 32.1 Preliminaries

SWIG supports Octave 6 and later.  It is regularly tested against the following
versions of Octave: 6.4, 8.4.
SWIG 4.2.1 has also been manually tested with 7.3 and 9.0.  SWIG 4.4.0 has
been manually tested with 10.3.

Every effort is made to maintain backward compatibility with older versions of Octave.
This cannot be guaranteed however, as in recent times new Octave releases have required nontrivial updates to SWIG, which may break backward compatibility for older Octave versions against which SWIG is not regularly tested.

The SWIG runtime exports the function `swig_octave_prereq()` for checking the version of Octave.

## <a name="Octave_nn3"></a> 32.2 Running SWIG

Let's start with a very simple SWIG interface file, example.i:

```swig

%module swigexample
%{
#include "example.h"
%}
int gcd(int x, int y);
extern double Foo; 
```

To build an Octave module when wrapping C code, run SWIG using the `-octave` option:

```shell
$ swig -octave -o example_wrap.cpp example.i 
```

The `-c++` option is also required when wrapping C++ code:

```shell
$ swig -octave -c++ -o example_wrap.cpp example.i 
```

### <a name="Octave_nn4"></a> 32.2.1 Command-line options

The swig command line has a number of options you can use, like to redirect its output. Use `swig -help` to learn about these.
Options specific to the Octave module are:

```shell
$ swig -octave -help
...
Octave Options (available with -octave)
     -globals name - Set name used to access C global variables [default: 'cvar']
                     Use '.' to load C global variables into module namespace
     -opprefix str - Prefix str for global operator functions [default: 'op_']

```

The *-globals* option sets the name of the variable which is the namespace for C global variables exported by the module.
The special name "." loads C global variables into the module namespace, i.e. alongside C functions and structs exported by the module.
The *-opprefix* options sets the prefix of the names of global/friend [operator](#Octave_nn18) functions.

### <a name="Octave_nn5"></a> 32.2.2 Compiling a dynamic module

Octave modules are DLLs/shared objects having the ".oct" suffix.
Building an oct file is usually done with the mkoctfile command (either within Octave itself, or from the shell). For example,

```shell

$ swig -octave -c++ -o example_wrap.cpp example.i
$ mkoctfile example_wrap.cpp example.c

```

where "example.c" is the file containing the gcd() implementation.

mkoctfile can also be used to extract the build parameters required to invoke the compiler and linker yourself. See the Octave manual and mkoctfile man page.

mkoctfile will produce "swigexample.oct", which contains the compiled extension module. Loading it into Octave is then a matter of invoking

```octave
octave:1> swigexample
```

### <a name="Octave_nn6"></a> 32.2.3 Using your module

Assuming all goes well, you will be able to do this:

```octave
$ octave -q
octave:1> swigexample
octave:2> swigexample.gcd(4, 6)
ans =  2
octave:3> swigexample.cvar.Foo
ans =  3
octave:4> swigexample.cvar.Foo=4;
octave:5> swigexample.cvar.Foo
ans =  4 
```

## <a name="Octave_nn7"></a> 32.3 A tour of basic C/C++ wrapping

### <a name="Octave_nn8"></a> 32.3.1 Modules

The SWIG module directive specifies the name of the Octave module. If you specify "module swigexample", then in Octave everything in the module will be accessible under "swigexample", as in the above example. When choosing a module name, make sure you don't use the same name as a built-in Octave command or standard module name.

When Octave is asked to invoke `swigexample`, it will try to find the ".m" or ".oct" file that defines the function "swigexample". You therefore need to make sure that "swigexample.oct" is in Octave's search path, which can be specified with the environment variable "OCTAVE_PATH".

To load an Octave module, simply type its name:

```octave

octave:1> swigexample;
octave:2> gcd(4, 6)
ans =  2
octave:3> cvar.Foo
ans =  3
octave:4> cvar.Foo=4;
octave:5> cvar.Foo
ans =  4

```

Modules can also be loaded from within functions, even before being loaded in the base context.
If the module is also used in the base context, however, it must first be loaded again:

```octave

octave:1> function l = my_lcm(a, b)
> swigexample
> l = abs(a*b)/swigexample.gcd(a, b);
> endfunction
octave:2> my_lcm(4, 6)
ans =  12
octave:3> swigexample.gcd(4, 6)
error: can't perform indexing operations for <unknown type> type
octave:3> swigexample;
octave:4> swigexample.gcd(4, 6)
ans =  2

```

### <a name="Octave_nn9"></a> 32.3.2 Functions

Global functions are wrapped as new Octave built-in functions. For example,

```swig
module swigexample
int fact(int n); 
```

creates a built-in function `swigexample.fact(n)` that works exactly like you think it does:

```octave
octave:1> swigexample.fact(4)
24 
```

### <a name="Octave_nn10"></a> 32.3.3 Global variables

Global variables are a little special in Octave. Given a global variable:

```swig
%module swigexample
extern double Foo;

```

To expose variables, SWIG actually generates two functions, to get and set the value. In this case, Foo_set and Foo_set would be generated. SWIG then automatically calls these functions when you get and set the variable– in the former case creating a local copy in the interpreter of the C variables, and in the latter case copying an interpreter variables onto the C variable.

```octave
octave:1> swigexample;
octave:2> c=swigexample.cvar.Foo
c =  3
octave:3> swigexample.cvar.Foo=4;
octave:4> c
c =  3
octave:5> swigexample.cvar.Foo
ans =  4
```

If a variable is marked with the %immutable directive then any attempts to set this variable will cause an Octave error. Given a global variable:

```swig
%module swigexample
%immutable;
extern double Foo;
%mutable;

```

SWIG will allow the reading of `Foo` but when a set attempt is made, an error function will be called.

```octave
octave:1> swigexample
octave:2> swigexample.Foo=4
error: attempt to set immutable member variable
error: assignment failed, or no method for `swig_type = scalar'
error: evaluating assignment expression near line 2, column 12 
```

It is possible to add new functions or variables to the module. This also allows the user to rename/remove existing functions and constants (but not linked variables, mutable or immutable). Therefore users are recommended to be careful when doing so.

```octave
octave:1> swigexample;
octave:2> swigexample.PI=3.142;
octave:3> swigexample.PI
ans =  3.1420 
```

### <a name="Octave_nn11"></a> 32.3.4 Constants and enums

Because Octave doesn't really have the concept of constants, C/C++ constants are not really constant in Octave. They are actually just a copy of the value into the Octave interpreter. Therefore they can be changed just as any other value. For example given some constants:

```swig
%module swigexample
%constant int ICONST=42;
#define    SCONST      "Hello World"
enum Days{SUNDAY, MONDAY, TUESDAY, WEDNESDAY, THURSDAY, FRIDAY, SATURDAY};

```

This is 'effectively' converted into the following Octave code:

```octave
swigexample.ICONST=42
swigexample.SCONST="Hello World"
swigexample.SUNDAY=0
.... 
```

### <a name="Octave_nn12"></a> 32.3.5 Pointers

C/C++ pointers are fully supported by SWIG. Furthermore, SWIG has no problem working with incomplete type information. Given a wrapping of the <file.h\> interface:
C/C++ pointers are fully supported by SWIG. Furthermore, SWIG has no problem working with incomplete type information. Given a wrapping of the <file.h\> interface:

```swig
%module swigexample
FILE *fopen(const char *filename, const char *mode);
int fputs(const char *, FILE *);
int fclose(FILE *);

```

When wrapped, you will be able to use the functions in a natural way from Octave. For example:

```octave

octave:1> swigexample;
octave:2> f=swigexample.fopen("w", "junk");
octave:3> swigexample.fputs("Hello world", f);
octave:4> swigexample.fclose(f);

```

Simply printing the value of a wrapped C++ type will print its typename. E.g.,

```octave
octave:1> swigexample;
octave:2> f=swigexample.fopen("junk", "w");
octave:3> f
f =

{
  _p_FILE, ptr = 0x9b0cd00
} 
```

As the user of the pointer, you are responsible for freeing it, or closing any resources associated with it (just as you would in a C program). This does not apply so strictly to classes and structs (see below).

```octave
octave:1> swigexample;
octave:2> f=swigexample.fopen("not there", "r");
error: value on right hand side of assignment is undefined
error: evaluating assignment expression near line 2, column 2 
```

NULL C/C++ pointers are represented by the Octave null matrix, `[]`.

### <a name="Octave_nn13"></a> 32.3.6 Structures and C++ classes

SWIG wraps C structures and C++ classes by using a special Octave type called a `swig_ref`. A `swig_ref` contains a reference to one or more instances of C/C++ objects, or just the type information for an object.
For each wrapped structure and class, a `swig_ref` will be exposed that has the name of the type. When invoked as a function, it creates a new object of its type and returns a `swig_ref` that points to that instance. This provides a very natural interface. For example,

```swig
struct Point{
  int x, y;
};

```

is used as follows:

```octave
octave:1> swigexample;
octave:2> p=swigexample.Point();
octave:3> p.x=3;
octave:4> p.y=5;
octave:5> p.x, p.y
ans =  3
ans =  5 

```

In C++, invoking the type object in this way calls the object's constructor.
`swig_ref` objects can also be acquired by having a wrapped function return a pointer, reference, or value of a non-primitive type.

The swig_ref type handles indexing operations such that usage maps closely to what you would have in C/C++. 
Structure members are accessed as in the above example, by calling set and get methods for C++ variables. 

Methods also work as expected. For example, code wrapped in the following way

```swig
class Point{
public:
  int x, y;
  Point(int _x, int _y) : x(_x), y(_y) {}
  double distance(const Point& rhs) {
    return sqrt(pow(x-rhs.x, 2)+pow(y-rhs.y, 2));
  }
  void set(int _x, int _y) {
    x=_x; y=_y;
  }
};

```

can be used from Octave like this

```octave
octave:1> swigexample;
octave:2> p1=swigexample.Point(3, 5);
octave:3> p2=swigexample.Point(1, 2);
octave:4> p1.distance(p2)
ans =  3.6056

```

By using the `swig_this()` and `swig_type()` functions, one can discover the pointers to and types of the underlying C/C++ object.

```octave

octave:5> swig_this(p1)
ans = 162504808
octave:6> swig_type(p1)
ans = Point

```

Note that `swig_ref` is a reference-counted pointer to a C/C++ object/type, and as such has pass-by-reference semantics. For example if one has a allocated a single object but has two `swig_ref`'s pointing to it, modifying the object through either of them will change the single allocated object.
This differs from the usual pass-by-value (copy-on-write) semantics that Octave maintains for built-in types. For example, in the following snippet, modifying `b` does not modify `a`,

```octave

octave:7> a=struct('x', 4)
a =
{
  x =  4
}

octave:8> b=a
b =
{
  x =  4
}

octave:9> b.y=4
b =
{
  x =  4
  y =  4
}

octave:10> a
a =
{
  x =  4
}

```

However, when dealing with wrapped objects, one gets the behavior

```octave

octave:2> a=Point(3, 5)
a =

{
  Point, ptr = 0x9afbbb0
}

octave:3> b=a
b =

{
  Point, ptr = 0x9afbbb0
}

octave:4> b.set(2, 1);
octave:5> b.x, b.y
ans =  2
ans =  1
octave:6> a.x, a.y
ans =  2
ans =  1

```

Depending on the ownership setting of a `swig_ref`, it may call C++ destructors when its reference count goes to zero. See the section on memory management below for details.

### <a name="Octave_nn15"></a> 32.3.7 C++ inheritance

Single and multiple inheritance are fully supported. The `swig_ref` type carries type information along with any C++ object pointer it holds.
This information contains the full class hierarchy. When an indexing operation (such as a method invocation) occurs, 
the tree is walked to find a match in the current class as well as any of its bases. The lookup is then cached in the `swig_ref`.

### <a name="Octave_nn17"></a> 32.3.8 C++ overloaded functions

Overloaded functions are supported, and handled as in other modules. That is, 
each overload is wrapped separately (under internal names), and a dispatch function is also emitted under the external/visible name.
The dispatch function selects which overload to call (if any) based on the passed arguments.
`typecheck` typemaps are used to analyze each argument, as well as assign precedence. See the chapter on typemaps for details.

### <a name="Octave_nn18"></a> 32.3.9 C++ operators

C++ operator overloading is supported, in a way similar to other modules.
The `swig_ref` type supports all unary and binary operators between itself and all other types that exist in the system at module load time. When an operator is used (where one of the operands is a `swig_ref`), the runtime routes the call to either a member function of the given object, or to a global function whose named is derived from the types of the operands (either both or just the lhs or rhs).

For example, if `a` and `b` are SWIG variables in Octave, `a+b` becomes `a.__add__(b)`. The wrapper is then free to implement __add__ to do whatever it wants. A wrapper may define the `__add__` function manually, %rename some other function to it, or %rename a C++ operator to it.

By default the C++ operators are renamed to their corresponding Octave operators. So without doing any work, the following interface

```swig

%inline {
struct A {
  int value;
  A(int _value) : value(_value) {}
  A operator+ (const A& x) {
    return A(value+x.value);
  }
};
}

```

is usable from Octave like this:

```octave

a=A(2), b=A(3), c=a+b
assert(c.value==5);

```

Octave operators are mapped in the following way:

```swig

__brace__      a{args}
__brace_asgn__ a{args} = rhs
__paren__      a(args)
__paren_asgn__ a(args) = rhs
__str__        generates string rep
__not__        !a
__uplus__      +a
__uminus__     -a
__transpose__  a.'
__hermitian__  a'
__incr__       a++
__decr__       a--
__add__        a + b
__sub__        a - b
__mul__        a * b
__div__        a / b
__pow__        a ^ b
__ldiv__       a \ b
__lshift__     a << b
__rshift__     a >> b
__lt__         a < b
__le__         a <= b
__eq__         a == b
__ge__         a >= b
__gt__         a > b
__ne__         a != b
__el_mul__     a .* b
__el_div__     a ./ b
__el_pow__     a .^ b
__el_ldiv__    a .\ b
__el_and__     a & b
__el_or__      a | b

```

On the C++ side, the default mappings are as follows:

```swig

%rename(__add__)       *::operator+;
%rename(__add__)       *::operator+();
%rename(__add__)       *::operator+() const;
%rename(__sub__)       *::operator-;
%rename(__uminus__)    *::operator-();
%rename(__uminus__)    *::operator-() const;
%rename(__mul__)       *::operator*;
%rename(__div__)       *::operator/;
%rename(__mod__)       *::operator%;
%rename(__lshift__)    *::operator<<;
%rename(__rshift__)    *::operator>>;
%rename(__el_and__)    *::operator&&;
%rename(__el_or__)     *::operator||;
%rename(__xor__)       *::operator^;
%rename(__invert__)    *::operator~;
%rename(__lt__)        *::operator<;
%rename(__le__)        *::operator<=;
%rename(__gt__)        *::operator>;
%rename(__ge__)        *::operator>=;
%rename(__eq__)        *::operator==;
%rename(__ne__)        *::operator!=;
%rename(__not__)       *::operator!;
%rename(__incr__)      *::operator++;
%rename(__decr__)      *::operator--;
%rename(__paren__)     *::operator();
%rename(__brace__)     *::operator[];

```

Octave can also utilise friend (i.e. non-member) operators with a simple %rename: see the example in the Examples/octave/operator directory.

Octave has several operators for which no corresponding C++ operators exist. For example, the Octave code

```octave

x=[a,b,c];

```

calls the Octave operator `horzcat` of the class of `a`. Hence, if `a` is of type `swig_ref` you can write an overload for this operator for your wrapped C++ class by placing a file `@swig_ref/horzcat.m` in the Octave load path (like for every Octave class, see [Creating a Class](https://docs.octave.org/latest/Creating-a-Class.html)). This Octave function file is then called whenever the above Octave code is executed for a variable of type `swig_ref`.

### <a name="Octave_nn19"></a> 32.3.10 Class extension with %extend

The %extend directive works the same as in other modules.

You can use it to define special behavior, like for example defining Octave operators not mapped to C++ operators, or defining certain Octave mechanisms such as how an object prints. For example, the `octave_value::{is_string, string_value, print}` functions are routed to a special method `__str__` that can be defined inside an %extend.

```swig

%extend A {
string __str__() {
  stringstream sout;
  sout<<$self->value;
  return sout.str();
}
}

```

Then in Octave one gets,

```octave

octave:1> a=A(4);
octave:2> a
a = 4
octave:3> printf("%s\n", a);
4
octave:4> a.__str__()
4

```

Similarly, Octave can use the `__float__` method to convert an object to a numeric value.

Octave 3.8.0 and later versions will also map unary functions X() to the corresponding `__X__` method, where X includes: abs(), acos(), acosh(), angle(), arg(), asin(), asinh(), atan(), atanh(), cbrt(), ceil(), conj(), cos(), cosh(), dawson(), erf(), erfc(), erfcinv(), erfcx(), erfi(), erfinv(), exp(), expm1(), finite(), fix(), floor(), gamma(), imag(), isalnum(), isalpha(), isascii(), iscntrl(), isdigit(), isgraph(), isinf(), islower(), isna(), isnan(), isprint(), ispunct(), isspace(), isupper(), isxdigit(), lgamma(), log(), log10(), log1p(), log2(), real(), round(), roundb(), signbit(), signum(), sin(), sinh(), sqrt(), tan(), tanh(), toascii(), tolower(), toupper()

### <a name="Octave_nn20"></a> 32.3.11 C++ templates

C++ class and function templates are fully supported as in other modules, in that the %template directive may used to create explicit instantiations of templated types.
For example, function templates can be instantiated as follows:

```swig
%module swigexample
%inline {
  template<class __scalar>
    __scalar mul(__scalar a, __scalar b) {
    return a*b;
  }
}
%include <std_complex.i>
%template(mul) mul<std::complex<double>>
%template(mul) mul<double>
```

and then used from Octave

```octave

octave:1> mul(4, 3)
ans =  12
octave:2> mul(4.2, 3.6)
ans =  15.120
octave:3> mul(3+4i, 10+2i)
ans =  22 + 46i

```

Similarly, class templates can be instantiated as in the following example,

```swig
%module swigexample
%include <std_complex.i>
%include <std_string.i>
%inline {
  #include <sstream>
  template<class __scalar> class sum {
    __scalar s;
  public:
    sum(__scalar _s=0) : s(_s) {}
    sum& add(__scalar _s) {
      s+=_s;
      return *this;
    }
    std::string __str__() const {
      std::stringstream sout;
      sout<<s;
      return sout.str();
    }
  };
}
%template(sum_complex) sum<std::complex<double>>;
%template(sum_double) sum<double>;

```

and then used from Octave

```octave

octave:2> a=sum_complex(2+3i);
octave:3> a.add(2)
ans =

(4, 3)
octave:4> a.add(3+i)
ans =

(7, 4)

```

### <a name="Octave_nn21"></a> 32.3.12 C++ Smart Pointers

#### <a name="Octave_smart_pointers_shared_ptr"></a> 32.3.12.1 The shared_ptr Smart Pointer

The C++11 standard provides `std::shared_ptr` which was derived from the Boost
implementation, `boost::shared_ptr`.
Both of these are available for Octave in the SWIG library and usage is outlined
in the [shared_ptr smart pointer](Library/#Library_std_shared_ptr) library section.

#### <a name="Octave_smart_pointers_generic"></a> 32.3.12.2 Generic Smart Pointers

C++ smart pointers are fully supported as in other modules.

### <a name="Octave_nn22"></a> 32.3.13 Directors (calling Octave from C++ code)

There is full support for SWIG Directors, which permits Octave code to subclass C++ classes, and implement their virtual methods.

Octave has no direct support for object oriented programming, however the `swig_ref` type provides some of this support. You can manufacture a `swig_ref` using the `subclass` function (provided by the SWIG/Octave runtime).

For example,

```octave

octave:1> a=subclass();
octave:2> a.my_var = 4;
octave:3> a.my_method = @(self) printf("my_var = ", self.my_var);
octave:4> a.my_method();
my_var = 4

```

`subclass()` can also be used to subclass one or more C++ types. Suppose you have an interface defined by

```swig

%inline {
class A {
public:
  virtual my_method() {
    printf("c-side routine called\n");
  }
};
void call_your_method(A& a) {
  a.my_method();
}
}

```

Then from Octave you can say:

```octave

octave:1> B=@() subclass(A(), @my_method);
octave:2> function my_method(self)
octave:3>   printf("octave-side routine called\n");
octave:4> end
octave:5> call_your_method(B());
octave-side routine called

```

or more concisely,

```octave

octave:1> B=@() subclass(A(), 'my_method', @(self) printf("octave-side routine called\n"));
octave:2> call_your_method(B());
octave-side routine called

```

Note that you have to enable directors via the %feature directive (see other modules for this).

`subclass()` will accept any number of C++ bases or other `subclass()`'ed objects, `(string, octave_value)` pairs, and `function_handles`. In the first case, these are taken as base classes; in the second case, as named members (either variables or functions, depending on whether the given value is a function handle); in the third case, as member functions whose name is taken from the given function handle. E.g.,

```octave

octave:1> B=@(some_var=2) subclass(A(), 'some_var', some_var, @some_func, 'another_func',
@(self) do_stuff())

```

You can also assign non-C++ member variables and functions after construct time. There is no support for non-C++ static members.

There is limited support for explicitly referencing C++ bases. So, in the example above, we could have

```octave

octave:1> B=@() subclass(A(), @my_method);
octave:2> function my_method(self)
octave:3>   self.A.my_method();
octave:4>   printf("octave-side routine called\n");
octave:5> end
octave:6> call_your_method(B());
c-side routine called
octave-side routine called

```

### <a name="Octave_nn23"></a> 32.3.14 Threads

The use of threads in wrapped Director code is not supported; i.e., an Octave-side implementation of a C++ class must be called from the Octave interpreter's thread. Anything fancier (apartment/queue model, whatever) is left to the user. Without anything fancier, this amounts to the limitation that Octave must drive the module... like, for example, an optimization package that calls Octave to evaluate an objective function.

### <a name="Octave_nn24"></a> 32.3.15 Memory management

As noted above, `swig_ref` represents a reference counted pointer to a C/C++-side object. It also contains a flag indicating whether Octave or the C/C++ code owns the object. If Octave owns it, any destructors will be called when the reference count reaches zero. If the C/C++ side owns the object, then destructors will not be called when the reference count goes to zero.
As noted above, `swig_ref` represents a reference counted pointer to a C/C++-side object. It also contains a flag indicating whether Octave or the C/C++ code owns the object. If Octave owns it, any destructors will be called when the reference count reaches zero. If the C/C++ side owns the object, then destructors will not be called when the reference count goes to zero.

For example,

```swig

%inline {
class A {
public:
  A() { printf("A constructing\n"); }
  ~A() { printf("A destructing\n"); }
};
}

```

Would produce this behavior in Octave:

```octave

octave:1> a=A();
A constructing
octave:2> b=a;
octave:3> clear a;
octave:4> b=4;
A destructing

```

The %newobject directive may be used to control this behavior for pointers returned from functions.

In the case where one wishes for the C++ side to own an object that was created in Octave (especially a Director object), one can use the __disown() method to invert this logic. Then letting the Octave reference count go to zero will not destroy the object, but destroying the object will invalidate the Octave-side object if it still exists (and call destructors of other C++ bases in the case of multiple inheritance/`subclass()`'ing).

### <a name="Octave_nn25"></a> 32.3.16 STL support

Various STL library files are provided for wrapping STL containers.

### <a name="Octave_nn26"></a> 32.3.17 Matrix typemaps

Octave provides a rich set of classes for dealing with matrices. Currently there are no built-in typemaps to deal with those. However, these are relatively straight forward for users to add themselves (see the docs on typemaps). Without much work (a single typemap decl– say, 5 lines of code in the interface file), it would be possible to have a function

```swig

double my_det(const double* mat, int m, int n);

```

that is accessed from Octave as,

```octave

octave:1> my_det(rand(4));
ans = -0.18388

```
```

```