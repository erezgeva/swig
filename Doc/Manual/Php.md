

<h1 id="Php">34 SWIG and PHP</h1>

<!-- INDEX -->

<!-- INDEX -->

In this chapter, we discuss SWIG's support of PHP.  Currently any PHP8
release should work.

Support for PHP8 was added in SWIG 4.1.0.
Support for PHP7 was added in SWIG 3.0.11 and removed in 4.2.0.
Support for PHP5 was removed in SWIG 4.0.0 and support for PHP4 was removed in
SWIG 1.3.37.  There never was a PHP6 release.

C++ PHP extensions should to be compiled as C++11 or newer - this is
a requirement of current versions of PHP (apparently undocumented but
confirmed by the PHP developers).  Modern C++ compilers have defaulted
to C++11 or newer since sufficiently long ago that this should just
work unless you are deliberately using an old compiler version or
you specifically tell the compiler to compile as C++98.

In order to use this module, you will need to have a copy of the PHP
include files to compile the SWIG generated C/C++ sources.  If you installed
PHP from a binary package, you may need to install a "php-dev" or "php-devel"
package for these to be installed.  You can find out where these files are
by running `php-config --includes`.  To use the built PHP module you
will need either the php binary or the Apache php module. If you want to build
your extension into php directly, you will need the complete PHP source tree
available.

<h2 id="Php_nn1">34.1 Generating PHP Extensions</h2>

To build a PHP extension, run swig using the `-php` option
(you can also use `-php7` - PHP7 and PHP8 have a largely compatible C
extension API, hence the same option name has been used for both).  For
example:

```swig

swig -php example.i

```

This will produce 2 files: example_wrap.c and php_example.h.
The first file, `example_wrap.c` contains all of
the C code needed to build a PHP extension. The second file,
`php_example.h` contains the header information needed if
you wish to statically link the extension into the php interpreter.

If the interface file uses `%pragma(php) include=`... or
`%pragma(php) code=`... then SWIG will also generate a third file,
`example.php` to contain what these specify.  In SWIG < 4.1.0,
this third file was always generated as it defined the PHP classes, etc
(but this is now done via C code in `example_wrap.c`) and also
contained code to dynamically load the extension (but this used the
PHP `dl()` function, which isn't recommended nowadays).

SWIG can generate PHP extensions from C++ libraries as well when
given the `-c++` option.  The support for C++ is discussed in
more detail in [section 27.2.6](#Php_nn2_6).  The generated
C++ wrapper will be called example_wrap.cxx.  You can specify a
different extension for the C++ wrapper using `-cppext` -
e.g. if you want example_wrap.cc use `-cppext cc`.

The usual (and recommended) way is to build the extension as a separate
dynamically loaded module (which is supported by all modern operating
systems).

It is also possible to rebuild PHP from source so that your module is
statically linked into the php executable/library.  This is a lot more
work, and also requires a full rebuild of PHP to update your module,
and it doesn't play nicely with package system.  We don't recommend
this approach, or provide explicit support for it.

<h3 id="Php_nn1_1">34.1.1 Building a loadable extension</h3>

To build your module as a dynamically loadable extension, use compilation
commands like these (if you aren't using GCC, the commands will be different,
and there may be some variation between platforms - these commands should at
least work for Linux though):

```shell

$ gcc `php-config --includes` -fPIC -c example_wrap.c example.c
$ gcc -shared example_wrap.o example.o -o example.so

```

<h3 id="Php_nn1_3">34.1.2 Using PHP Extensions</h3>

To test the extension from a PHP script, you first need to tell PHP to
load it.  The recommended (and simplest!) way to do this is to copy it to
PHP's default extension directory and add a line like this to the
`[PHP]` section of `php.ini`:

```swig

        extension=modulename

```

If the module is not in PHP's default extension directory, you also need to
specify the path, in which case you'll also need to deal with platform-specific
naming - for example, on Linux:

```swig

        extension=/path/to/modulename.so

```

but on Microsoft Windows you'd need to use:

```swig

        extension=/path/to/php_modulename.dll

```

If you're using the PHP CLI SAPI it's possible (but not recommended) to use the
[dl() function](https://www.php.net/manual/en/function.dl.php) to
load an extension at run time, by adding a line like this to the start of each
PHP script which uses your extension:

```swig

        dl("modulename"); // Load the module

```

Again, if the module isn't in PHP's default extension directory you'll also
need to specify the path and deal with that varying by platform.

For security reasons PHP no longer supports `dl()` when running PHP
through a webserver, so this isn't an option there.

<h2 id="Php_nn2">34.2 Basic PHP interface</h2>

It is important to understand that PHP uses a single global namespace
into which all symbols from extension modules are loaded.  It is quite
possible for names of symbols in one extension module to clash with
other symbols unless care is taken to `%rename` them.  At present
SWIG doesn't have support for generating wrappers which make use of PHP's
namespace feature.

<h3 id="Php_nn2_1">34.2.1 Constants</h3>

These work in much the same way as in C/C++.  Constants can be defined
by using either the normal C pre-processor declarations, or the
`%constant` SWIG directive.  These will then be available from
your PHP script as a PHP constant, (i.e. no dollar sign is needed to
access them.) For example, with a swig interface file like this,

```swig

%module example

#define PI 3.14159

%constant int E  = 2.71828

```

you can access the constants in your PHP script like this,

```swig

echo "PI = " . PI . "\n";
echo "E = " . E . "\n";

```

<h3 id="Php_nn2_2">34.2.2 Global Variables</h3>

Because PHP does not provide a mechanism to intercept access and
assignment of global variables, global variables are supported through
the use of automatically generated accessor functions.

```swig

%module example;

%inline %{
  double seki = 2;
  void print_seki() {
    zend_printf("seki is now %f\n", seki);
  }
%}

```

is accessed as follows:

```swig

print seki_get();
seki_set( seki_get() * 2); # The C variable is now 4.
print seki_get();

```

SWIG supports global variables of all C datatypes including pointers
and complex objects.  To support additional types, you just need to
supply the standard `in` and `out` typemaps, which get
used because of the wrapping as `_get()` and `_set()`
functions.

SWIG honors the `%immutable` modifier by not generating a
`_set` method (so attempting to call it will give a PHP fatal
error).  A `_get` method is still generated so this provides read-only
access to the variable from the PHP script.

At this time SWIG does not support custom accessor methods.

<h3 id="Php_nn2_3">34.2.3 Functions</h3>

C functions are converted into PHP functions. Default/optional arguments are
also allowed. An interface file like this :

```swig

%module example
int foo(int a);
double bar(double, double b = 3.0);
...

```

Will be accessed in PHP like this :

```swig

$a = foo(2);
$b = bar(3.5, -1.5);
$c = bar(3.5);  # Use default argument for 2nd parameter

```

SWIG generates PHP type declarations for function parameters and return
types for PHP 8 and later.

You can control the generation of PHP type declarations using
the "php:type" %feature.  This has three settings:

- If unset or set to "0" then no type declarations are generated, e.g.: `%feature("php:type", "0");`
- If set to "1" then type declarations are generated for both parameters and return types, e.g.: `%feature("php:type", "1");`
- The default setting is "compat", which is the same as "1" except no
return type declarations are generated for virtual methods for which
directors are enabled.  This provides better compatibility for PHP
subclasses of wrapped virtual methods in existing SWIG-generated bindings, e.g.: `%feature("php:type", "compat");`

If you have an existing PHP interface and are upgrading to SWIG \>= 4.1.0
then the default "compat" setting should work well.

If you're writing a new set of bindings and **only targeting PHP8 or newer**
then enabling type declarations everywhere probably makes sense.  It will
only actually make a difference if you enable directors and are wrapping C++
classes with virtual methods, but doing it anyway means you won't forget to if
the code you are wrapping later evolves to have such classes and methods.

The type declaration information will make the generated source code and
compiler extension module larger, so you might want to turn off type
declarations if keeping these small is important to you.  If you find you
need to turn off type declarations to fix a problem, please let us know
via our github issue tracker.

Note that being a SWIG feature this can be specified globally (like above) or
per class, per method, etc.  See the [%feature directives](Customization/#Customization_features)
section for full details of how to control at a fine-grained level.

The PHP type information is specified via a "phptype" attribute on "in" and
"out" typemaps, and these have been added for all the typemaps we supply for
PHP.  We don't currently support this for "argout" templates, but probably
will in a future version.

If you have written custom SWIG typemaps for PHP and want to add PHP type
declarations, then the syntax is very like how you'd specify the type in
PHP code, e.g. `%typemap(in, phptype="int|string|Foo")` means the
typemap accepts a PHP int or string or an object of class Foo,
`%typemap(in, phptype="?int")` means a PHP int or NULL, etc.
As well as the standard PHP type declaration types, SWIG also understands the
special type "SWIGTYPE" as an entry in phptype, which means the PHP type
corresponding to the type that this typemap matched on - for a object this
will give you the PHP class for the object, and for a pointer to a non-class
type it will give you the name of the PHP class SWIG created for that
pointer type.
<!-- This isn't correct for 1.3.30 and needs rewriting to reflect reality
<p>
Because PHP is a dynamically typed language, the default typemaps
used for simple types will attempt to coerce the arguments into the appropriate type.  That is the following invocations are equivalent:
</p>

<div class="code"><pre>
$a = foo(2);
$a = foo("2");
$a = foo(2.0);
</pre></div>

<p>
Functions are invoked using pass by value semantics like all of PHP.
This means the conversion which automatically takes place when
invoking a swig wrapped method does not change the native type of the
argument variable.
</p>
<div class="code"><pre>
$s = "2 A string representing two";
$a = foo($s);  # invokes 'foo(2)';
print $s;      # The value of $s was not changed.
</pre></div>
-->

<h3 id="Php_nn2_4">34.2.4 Overloading</h3>

Although PHP does not support overloading functions natively, swig
will generate dispatch functions which will use `%typecheck`
typemaps to allow overloading.  This dispatch function's operation and
precedence is described in [Overloaded functions and methods](SWIGPlus/#SWIGPlus_overloaded_methods).
<!-- This isn't correct for 1.3.30 and needs rewriting to reflect reality
<p>
Because PHP is a dynamically typed language, simple values can be
silently converted from one type to another.  For example, integers,
doubles and strings silently convert to each other depending on
context.  This situation make overloading slightly problematic because
given the following function:
</p>

<div class="code"><pre>
void doit( int i );
void doit( double i );
</pre></div>

<p>
it is questionable which to invoke when <tt>doit("2");</tt> is used in
PHP.  The string <tt>"2"</tt> simultaneously represents the integer
<tt>2</tt> and the double <tt>2.0</tt>.
</p>

<p>
In order to provide the most natural experience to PHP programmers,
the default <tt>%typecheck</tt> implemented in <tt>php.swg</tt>
allows any simple type (integer, double, string) in PHP to be used for
any simple C type (int, double, char *).  The function selected then
depends only on the argument type precedence defined by SWIG.
</p>

<p>
It should be noted that <tt>SWIGTYPE</tt> references and pointers will
not be silently converted.  So these two functions:
</p>

<div class="code"><pre>
void doit( const Vector &amp; );
void doit( int i );
</pre></div>

<p>
Cause less confusion and <tt>doit("2");</tt> will invoke the function
taking the integer argument.
</p>
-->

<h3 id="Php_nn2_5">34.2.5 Pointers and References</h3>

Since SWIG 4.1.0, SWIG wraps C/C++ classes directly with PHP objects.
Pointers to other types are also wrapped as PHP objects - mostly this is an
implementation detail, but it's visible from PHP via `is_object()` and
similar.  In earlier SWIG versions, PHP resources were used to wrap both
classes and pointers to other types.

There are multiple ways to wrap pointers to simple types.  Given the
following C method:

```swig

  void add( int *in1, int *in2, int *result);

```

One can include **cpointer.i** to generate PHP wrappers to ```
int
*
```.

```swig

%module example
%include "cpointer.i"
%pointer_functions(int, intp)

void add( int *in1, int *in2, int *result);

```

This will result in the following usage in PHP:

```swig
<?php

$in1=copy_intp(3);
$in2=copy_intp(5);
$result=new_intp();

add( $in1, $in2, $result );

echo "The sum " . intp_value($in1) . " + " . intp_value($in2) . " = " . intp_value( $result) . "\n";

```

An alternative would be to use the include **typemaps.i** which
defines named typemaps for INPUT, OUTPUT and INOUT variables.  One
needs to either `%apply` the appropriate typemap or adjust the
parameter names as appropriate.

```swig

%module example
%include "typemaps.i"

void add( int *INPUT, int *INPUT, int *OUTPUT);

```

This will result in the following usage in PHP:

```swig
<?php

$in1 = 3;
$in2 = 5;
$result= add($in1, $in2);  # Note using variables for the input is unnecessary.

echo "The sum $in1 + $in2 = $result\n";

```

Because PHP has a native concept of reference, it may seem more natural
to the PHP developer to use references to pass pointers.  To enable
this, one needs to include **phppointers.i** which defines the
named typemap REF.

In case you write your own typemaps, SWIG supports an attribute called
`byref`: if you set that, then SWIG will make sure that the generated
wrapper function will want the input parameter as a reference.

```swig

%module example
%include "phppointers.i"

void add( int *REF, int *REF, int *REF);

```

This will result in the following usage in PHP:

```swig
<?php

$in1 = 3;
$in2 = 5;
$result = 0;
add($in1, $in2, $result);

echo "The sum $in1 + $in2 = $result\n";

```

It is important to note that a php variable which is NULL when passed
by reference would end up passing a NULL pointer into the function.
In PHP, an unassigned variable (i.e. where the first reference to the
variable is not an assignment) is
NULL.  In the above example, if any of the three variables had not
been assigned, a NULL pointer would have been passed into
`add`.  Depending on the implementation of the function, this
may or may not be a good thing.

We chose to allow passing NULL pointers into functions because that is
sometimes required in C libraries.  A NULL pointer can be created in
PHP in a number of ways: by using `unset` on an existing
variable, or assigning `NULL` to a variable.

<h3 id="Php_nn2_6">34.2.6 Structures and C++ classes</h3>

SWIG wraps C++ structs and classes with PHP classes.
Since SWIG 4.1.0, this is done entirely via PHP's C API - earlier SWIG
versions generated a PHP wrapper script which defined proxy classes
which called a set of flat functions which actually wrapped the C++ class.

This interface file

```swig

%module vector

class Vector {
public:
  double x, y, z;
  Vector();
  ~Vector();
  double magnitude();
};

struct Complex {
 double re, im;
};

```

Would be used in the following way from PHP:

```swig
<?php

  $v = new Vector();
  $v->x = 3;
  $v->y = 4;
  $v->z = 5;

  echo "Magnitude of ($v->x, $v->y, $v->z) = " . $v->magnitude() . "\n";

  $v = NULL;   # destructor called.

  $c = new Complex();

  $c->re = 0;
  $c->im = 0;

  # $c destructor called when $c goes out of scope.

```

Member variables and methods are accessed using the `->` operator.

<h4 id="Php_nn2_6_1">34.2.6.1 Using -noproxy</h4>

SWIG/PHP used to support a `-noproxy` option to flatten the class
structure and generate collections of named flat functions.  This is no
longer supported as of SWIG 4.1.0.

<h4 id="Php_nn2_6_2">34.2.6.2 Constructors and Destructors</h4>

The constructor is called when `new Object()` is used to create an
instance of the object. If multiple constructors are defined for an
object, function overloading will be used to determine which
constructor to execute.

Because PHP uses reference counting, simple assignment of one variable to
another such as:

```swig

$ref = $v;

```

causes the symbol `$ref` to refer to the same underlying object
as `$v`.  This does not result in a call to the C++ copy
constructor or copy assignment operator.

One can force execution of the copy constructor by using:

```swig

$o_copy = new Object($o);

```

Destructors are automatically called when all variables referencing
the instance are reassigned or go out of scope.  The destructor is not
available to be called manually.  To force a destructor to be called
the programmer can either reassign the variable or call
`unset($v)`

<h4 id="Php_nn2_6_3">34.2.6.3 Static Member Variables</h4>

Static member variables in C++ are not wrapped as such in PHP
as it does not appear to be possible to intercept accesses to such variables.
Therefore, static member variables are
wrapped using a class function with the same name, which
returns the current value of the class variable. For example

```swig

%module example

class Ko {
  static int threats;
};

```

would be accessed in PHP as,

```swig

echo "There have now been " . Ko::threats() . " threats\n";

```

To set the static member variable, pass the value as the argument to the class
function, e.g.

```swig

Ko::threats(10);

echo "There have now been " . Ko::threats() . " threats\n";

```

<h4 id="Php_nn2_6_4">34.2.6.4 Static Member Functions</h4>

Static member functions are supported in PHP using the
`class::function()` syntax.  For example

```swig

%module example
class Ko {
  static void threats();
};

```

would be executed in PHP as

```swig

Ko::threats();

```

<h4 id="Php_nn2_6_5">34.2.6.5 Specifying Implemented Interfaces</h4>

PHP supports the concept of abstract interfaces which a class can implement.
Since SWIG 3.0.3, you can tell SWIG that a wrapped class (for example
`MyIterator`) implements the `Iterator` interface like
so:

```swig

%typemap("phpinterfaces") MyIterator "Iterator"

```

If there are multiple interfaces, just list them separated by commas.

<h4 id="Php_nn2_6_6">34.2.6.6 Dynamic Properties</h4>

Historically PHP has supported dynamic class properties and SWIG
has implemented them too (because we implement the magic `__get()`,
`__set()` and `__isset()` methods we need to include explicit
handling).

PHP 8.2 [deprecates dynamic class properties](https://wiki.php.net/rfc/deprecate_dynamic_properties) - initially they'll warn, and apparently they'll
not work by default in PHP 9.0.

In PHP code dynamic properties can be enabled for a class by
marking that class with the attribute `#[AllowDynamicProperties]`.

To follow this PHP change, as of SWIG 4.1.0 you now need enable dynamic
properties for any classes you want to support them.  To enable for class
`Foo`:

```swig

%feature("php:allowdynamicproperties", 1) Foo;

```

or to enable them for all wrapped classes:

```swig

%feature("php:allowdynamicproperties", 1);

```

Note that unknown features are ignored, so you can add use these
unconditionally in your interface file and it'll work with older SWIG too.

There was a bug in SWIG 4.1.0 where setting this feature to any value enabled
it - SWIG 4.2.0 fixed this and you can now set it to 0 to turn it off (for
example, you might want to enabled it for everything and then selectively turn
it off for specific classes).

<h3 id="Php_nn2_7">34.2.7 PHP Pragmas, Startup and Shutdown code</h3>

You can get SWIG to generate an "example.php" file by specifying
the code to put in it using the **code** pragma.

```swig

%module example
%pragma(php) code="
# This code is inserted into example.php
echo \"example.php execution\\n\";
"

```

Results in the following in "example.php"

```swig

# This code is inserted into example.php
echo "example.php execution\n";

```

The **version** pragma can be used to add version to generated PHP extension module. The version is inserted in the zend_module_entry block.

```swig

%module example
%pragma(php) version="1.5"

```

The **include** pragma is a short cut to add include statements to
the example.php file.

```swig

%module example
%pragma(php) code="
include \"include.php\";
"
%pragma(php) include="include.php"   // equivalent.

```

The **phpinfo** pragma inserts code in the
`PHP_MINFO_FUNCTION` which is called from PHP's
phpinfo() function.

```swig

%module example;
%pragma(php) phpinfo="
  zend_printf(\"An example of PHP support through SWIG\\n\");
  php_info_print_table_start();
  php_info_print_table_header(2, \"Directive\", \"Value\");
  php_info_print_table_row(2, \"Example support\", \"enabled\");
  php_info_print_table_end();
"

```

To insert code into the `PHP_MINIT_FUNCTION`, one can use
either `%init` or `%minit`.

```swig

%module example;
%init {
  zend_printf("Inserted into PHP_MINIT_FUNCTION\n");
}
%minit {
  zend_printf("Inserted into PHP_MINIT_FUNCTION\n");
}

```

To insert code into the `PHP_MSHUTDOWN_FUNCTION`, one can use
either `%shutdown` or `%mshutdown`.

```swig

%module example;
%mshutdown {
  zend_printf("Inserted into PHP_MSHUTDOWN_FUNCTION\n");
}

```

The `%rinit` and `%rshutdown` statements are very similar but insert code
into the request init (PHP_RINIT_FUNCTION) and request shutdown (PHP_RSHUTDOWN_FUNCTION) code respectively.

<h2 id="Php_nn3">34.3 Cross language polymorphism</h2>

Proxy classes provide a more natural, object-oriented way to access
extension classes. As described above, each proxy instance has an
associated C++ instance, and method calls to the proxy are passed to the
C++ instance transparently.

This arrangement is asymmetric in the sense that no corresponding
mechanism exists to pass method calls down the inheritance chain from
C++ to PHP. In particular, if a C++ class has been extended in PHP
(by extending the proxy class), these extensions will not be visible
from C++ code. Virtual method calls from C++ are thus not able access
the lowest implementation in the inheritance chain.

Changes have been made to SWIG 1.3.18 to address this problem and make
the relationship between C++ classes and proxy classes more symmetric.
To achieve this goal, new classes called directors are introduced at the
bottom of the C++ inheritance chain. Support for generating PHP classes
has been added in SWIG 1.3.40. The job of the directors is to route
method calls correctly, either to C++ implementations higher in the
inheritance chain or to PHP implementations lower in the inheritance
chain. The upshot is that C++ classes can be extended in PHP and from
C++ these extensions look exactly like native C++ classes. Neither C++
code nor PHP code needs to know where a particular method is
implemented: the combination of proxy classes, director classes, and C
wrapper functions takes care of all the cross-language method routing
transparently.

<h3 id="Php_nn3_1">34.3.1 Enabling directors</h3>

The director feature is disabled by default.  To use directors you
must make two changes to the interface file.  First, add the "directors"
option to the %module directive, like this:

```swig

%module(directors="1") modulename

```

Without this option no director code will be generated.  Second, you
must use the %feature("director") directive to tell SWIG which classes 
and methods should get directors.  The %feature directive can be applied 
globally, to specific classes, and to specific methods, like this:

```swig

// generate directors for all classes that have virtual methods
%feature("director");         

// generate directors for the virtual methods in class Foo
%feature("director") Foo;      

```

You can use the %feature("nodirector") directive to turn off
directors for specific classes or methods.  So for example,

```swig

%feature("director") Foo;
%feature("nodirector") Foo::bar;

```

will generate directors for the virtual methods of class Foo except
bar().

Directors can also be generated implicitly through inheritance. 
In the following, class Bar will get a director class that handles
the methods one() and two() (but not three()):

```swig

%feature("director") Foo;
class Foo {
public:
  Foo(int foo);
  virtual void one();
  virtual void two();
};

class Bar: public Foo {
public:
  virtual void three();
};

```

then at the PHP side you can define

```php

class MyFoo extends Foo {
  function one() {
    print "one from php\n";
  }
}

```

<h3 id="Php_nn3_2">34.3.2 Director classes</h3>

For each class that has directors enabled, SWIG generates a new class
that derives from both the class in question and a special
`Swig::Director` class. These new classes, referred to as director
classes, can be loosely thought of as the C++ equivalent of the PHP
proxy classes. The director classes store a pointer to their underlying
PHP object.  Indeed, this is quite similar to `struct swig_object_wrapper`
which is used to implement the PHP proxy classes.

For simplicity let's ignore the `Swig::Director` class and refer to the
original C++ class as the director's base class. By default, a director
class extends all virtual methods in the inheritance chain of its base
class (see the preceding section for how to modify this behavior).
Virtual methods that have a final specifier are unsurprisingly excluded.
Thus the virtual method calls, whether they originate in C++ or in
PHP via proxy classes, eventually end up in at the implementation in the
director class. The job of the director methods is to route these method
calls to the appropriate place in the inheritance chain. By "appropriate
place" we mean the method that would have been called if the C++ base
class and its extensions in PHP were seamlessly integrated. That
seamless integration is exactly what the director classes provide,
transparently skipping over all the messy extension API glue that binds
the two languages together.

In reality, the "appropriate place" is one of only two possibilities:
C++ or PHP. Once this decision is made, the rest is fairly easy. If the
correct implementation is in C++, then the lowest implementation of the
method in the C++ inheritance chain is called explicitly. If the correct
implementation is in PHP, the Zend API is used to call the method of the
underlying PHP object (after which the usual virtual method resolution
in PHP automatically finds the right implementation).

Now how does the director decide which language should handle the method call?
The basic rule is to handle the method in PHP, unless there's a good
reason not to. The reason for this is simple: PHP has the most
"extended" implementation of the method. This assertion is guaranteed,
since at a minimum the PHP proxy class implements the method. If the
method in question has been extended by a class derived from the proxy
class, that extended implementation will execute exactly as it should.
If not, the proxy class will route the method call into a C wrapper
function, expecting that the method will be resolved in C++. The wrapper
will call the virtual method of the C++ instance, and since the director
extends this the call will end up right back in the director method. Now
comes the "good reason not to" part. If the director method were to blindly
call the PHP method again, it would get stuck in an infinite loop. We avoid this
situation by adding special code to the C wrapper function that tells
the director method to not do this.  The C wrapper function compares the
called and the declaring class name of the given method.  If these are
not the same, then the C wrapper function tells the director to resolve
the method by calling up the C++ inheritance chain, preventing an
infinite loop.

One more point needs to be made about the relationship between director
classes and proxy classes. When a proxy class instance is created in
PHP, SWIG creates an instance of the original C++ class and stores it
in the `struct swig_object_wrapper`. This is true whether or not
directors are enabled for the particular class in question. However
when a class *derived* from a proxy class is created, SWIG instead
creates an instance of the corresponding C++ director class.
The reason for this difference is that user-defined subclasses
may override or extend methods of the original class, so the director
class is needed to route calls to these methods correctly. For
unmodified proxy classes, all methods are ultimately implemented in C++
so there is no need for the extra overhead involved with routing the
calls through PHP.

<h3 id="Php_nn3_3">34.3.3 Ownership and object destruction</h3>

Memory management issues are slightly more complicated with directors
than for proxy classes alone. PHP instances hold a pointer to the
associated C++ director object, and the director in turn holds a pointer
back to the PHP object. By default, proxy classes own their C++ director
object and take care of deleting it when they are garbage collected.

This relationship can be reversed by calling the special
`->thisown` property of the proxy class. After setting this
property to `0`, the director class no longer destroys the PHP
object.  Assuming no outstanding references to the PHP object remain,
the PHP object will be destroyed at the same time. This is a good thing,
since directors and proxies refer to each other and so must be created
and destroyed together. Destroying one without destroying the other will
likely cause your program to segfault.

Here is an example:

```swig

class Foo {
public:
  ...
};
class FooContainer {
public:
  void addFoo(Foo *);
  ...
};

```

```php

$c = new FooContainer();
$a = new Foo();
$a->thisown = 0;
$c->addFoo($a);

```

In this example, we are assuming that FooContainer will take care of
deleting all the Foo pointers it contains at some point.

<h3 id="Php_nn3_4">34.3.4 Exception unrolling</h3>

With directors routing method calls to PHP, and proxies routing them
to C++, the handling of exceptions is an important concern. By default, an
exception thrown in PHP code called from C++ causes the PHP interpreter
to flag that an exception is thrown, then return passes to C++ as if
the PHP function had returned `Null`.  Assuming the directorout
typemaps handle this (those SWIG defines by default should) then once
control returns to PHP code again, the PHP exception will actually propagate.

Sometimes this control flow is problematic, and you want to skip any
handling in the C++ code.  To achieve this, it is necessary
to temporarily translate the PHP exception into a C++ exception. This can be
achieved using the %feature("director:except") directive. The following code
should suffice in most cases:

```swig

%feature("director:except") {
#if SWIG_VERSION >= 0x040100
  if ($error != NULL)
#else
  if ($error == FAILURE)
#endif
  {
    throw Swig::DirectorMethodException();
  }
}

```

If you only need to support SWIG \>= 4.1.0, you can just use the
`($error != NULL)` condition.

In SWIG 4.1.0, `$error` was changed in the SWIG/PHP director
implementation to make it work more like how it does for other languages.
Previously, `$error` didn't actually indicate an exception, but instead
was only set to `FAILURE` if there was a problem calling the PHP method.
Now `$error` indicates if the PHP method threw a PHP exception, and
directorout typemaps for PHP no longer need to be gated by `if (EG(exception))`.

This code will check the PHP error state after each method call from a
director into PHP, and throw a C++ exception if an error occurred.  This
exception can be caught in C++ to implement an error handler.
Currently no information about the PHP error is stored in the
Swig::DirectorMethodException object, but this will likely change in the
future.

It may be the case that a method call originates in PHP, travels up to
C++ through a proxy class, and then back into PHP via a director method.
If an exception occurs in PHP at this point, it would be nice for that
exception to find its way back to the original caller. This can be done
by combining a normal %exception directive with the
`director:except` handler shown above. Here is an example of a
suitable exception handler:

```swig

%exception {
  try { $action }
  catch (Swig::DirectorException &e) { SWIG_fail; }
}

```

The class Swig::DirectorException used in this example is actually a
base class of Swig::DirectorMethodException, so it will trap this
exception. Because the PHP error state is still set when
Swig::DirectorMethodException is thrown, PHP will register the exception
as soon as the C wrapper function returns.

<h3 id="Php_nn3_5">34.3.5 Overhead and code bloat</h3>

Enabling directors for a class will generate a new director method for
every virtual method in the class' inheritance chain. This alone can
generate a lot of code bloat for large hierarchies. Method arguments
that require complex conversions to and from target language types can
result in large director methods. For this reason it is recommended that
you selectively enable directors only for specific classes that are
likely to be extended in PHP and used in C++.

Compared to classes that do not use directors, the call routing in the
director methods does add some overhead. In particular, at least one
dynamic cast and one extra function call occurs per method call from
PHP. Relative to the speed of PHP execution this is probably completely
negligible. For worst case routing, a method call that ultimately
resolves in C++ may take one extra detour through PHP in order to ensure
that the method does not have an extended PHP implementation. This could
result in a noticeable overhead in some cases.

Although directors make it natural to mix native C++ objects with PHP
objects (as director objects) via a common base class pointer, one
should be aware of the obvious fact that method calls to PHP objects
will be much slower than calls to C++ objects. This situation can be
optimized by selectively enabling director methods (using the %feature
directive) for only those methods that are likely to be extended in PHP.

<h3 id="Php_nn3_6">34.3.6 Typemaps</h3>

Typemaps for input and output of most of the basic types from director
classes have been written. These are roughly the reverse of the usual
input and output typemaps used by the wrapper code. The typemap
operation names are 'directorin', 'directorout', and 'directorargout'.
The director code does not currently use any of the other kinds of
typemaps.  It is not clear at this point which kinds are appropriate and
need to be supported.

<h3 id="Php_nn3_7">34.3.7 Miscellaneous</h3>

Director typemaps for STL classes are mostly in place, and hence you
should be able to use std::string, etc., as you would any other type.
