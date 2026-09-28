

# <a name="Tcl"></a> 39 SWIG and Tcl

<!-- INDEX -->

<!-- INDEX -->

**Caution: This chapter is under repair!**

This chapter discusses SWIG's support of Tcl. Since SWIG 4.1.0, Tcl 8.4 or a
later release is required.  Prior to that earlier Tcl 8.x releases were also
supported.  Tcl 9.0 is supported since SWIG 4.2.1.

## <a name="Tcl_nn2"></a> 39.1 Preliminaries

To build a Tcl module, run SWIG using the `-tcl` or `-tcl8` option :

```swig

$ swig -tcl example.i

```

If building a C++ extension, add the `-c++` option:

```swig

$ swig -c++ -tcl example.i

```

This creates a file `example_wrap.c` or
`example_wrap.cxx` that contains all of the code needed to
build a Tcl extension module.  To finish building the module, you 
need to compile this file and link it with the rest of your program.

### <a name="Tcl_nn3"></a> 39.1.1 Getting the right header files

In order to compile the wrapper code, the compiler needs the `tcl.h` header file.
This file is usually contained in the directory

```swig

/usr/local/include

```

Be aware that some Tcl versions install this header file with a version number attached to it.  If
this is the case, you should probably make a symbolic link so that `tcl.h` points to the correct
header file.

### <a name="Tcl_nn4"></a> 39.1.2 Compiling a dynamic module

The preferred approach to building an extension module is to compile it into
a shared object file or DLL. Assuming you have code you need to link to in a file
called `example.c`, you will need to compile your program
using commands like this (shown for Linux):

```swig

$ swig -tcl example.i
$ gcc -fPIC -c example.c
$ gcc -fPIC -c example_wrap.c -I/usr/local/include
$ gcc -shared example.o example_wrap.o -o example.so

```

The exact commands for doing this vary from platform to platform. 
SWIG tries to guess the right options when it is installed.  Therefore, 
you may want to start with one of the examples in the `SWIG/Examples/tcl` 
directory.   If that doesn't work, you will need to read the man-pages for
your compiler and linker to get the right set of options.  You might also
check the [SWIG Wiki](https://github.com/swig/swig/wiki) for
additional information.

When linking the module, the name of the output file has to match the name
of the module.  If the name of your SWIG module is "`example`", the
name of the corresponding object file should be
"`example.so`".
The name of the module is specified using the `%module` directive or the 
`-module` command line option.

### <a name="Tcl_nn5"></a> 39.1.3 Static linking

An alternative approach to dynamic linking is to rebuild the Tcl
interpreter with your extension module added to it.  In the past,
this approach was sometimes necessary due to limitations in dynamic loading
support on certain machines.  However, the situation has improved greatly
over the last few years and you should not consider this approach 
unless there is really no other option.

The usual procedure for adding a new module to Tcl involves writing a
special function `Tcl_AppInit()` and using it to initialize the interpreter and
your module.  With SWIG, the `tclsh.i` and `wish.i` library files
can be used to rebuild the `tclsh` and `wish` interpreters respectively.
For example:

```swig

%module example

%inline %{
extern int fact(int);
extern int mod(int, int);
extern double My_variable;
%}

%include "tclsh.i"       // Include code for rebuilding tclsh

```

The `tclsh.i` library file includes supporting code that
contains everything needed to rebuild tclsh. To rebuild the interpreter,
you simply do something like this:

```swig

$ swig -tcl example.i
$ gcc example.c example_wrap.c \
        -Xlinker -export-dynamic \
        -DHAVE_CONFIG_H -I/usr/local/include/ \
        -L/usr/local/lib -ltcl -lm -ldl \
        -o mytclsh

```

You will need to supply the same libraries that were used to build Tcl the first
time.  This may include system libraries such as `-lsocket`, `-lnsl`,
and `-lpthread`.  If this actually works, the new version of Tcl
should be identical to the default version except that your extension module will be
a built-in part of the interpreter.

**Comment:** In practice, you should probably try to avoid static
linking if possible. Some programmers may be inclined
to use static linking in the interest of getting better performance.
However, the performance gained by static linking tends to be rather
minimal in most situations (and quite frankly not worth the extra
hassle in the opinion of this author).

### <a name="Tcl_nn6"></a> 39.1.4 Using your module

To use your module, simply use the Tcl `load` command.  If
all goes well, you will be able to this:

```swig

$ tclsh
% load ./example.so
% fact 4
24
%

```

A common error received by first-time users is the following:

```swig

% load ./example.so
couldn't find procedure Example_Init
% 

```

This error is almost always caused when the name of the shared object file doesn't
match the name of the module supplied using the SWIG `%module` directive.
Double-check the interface to make sure the module name and the shared object
file match.  Another possible cause of this error is forgetting to link the SWIG-generated
wrapper code with the rest of your application when creating the extension module.

Another common error is something similar to the following:

```swig

% load ./example.so
couldn't load file "./example.so": ./example.so: undefined symbol: fact
% 

```

This error usually indicates that you forgot to include some object
files or libraries in the linking of the shared library file.  Make
sure you compile both the SWIG wrapper file and your original program
into a shared library file.  Make sure you pass all of the required libraries
to the linker.

Sometimes unresolved symbols occur because a wrapper has been created
for a function that doesn't actually exist in a library.  This usually
occurs when a header file includes a declaration for a function that
was never actually implemented or it was removed from a library
without updating the header file.  To fix this, you can either edit
the SWIG input file to remove the offending declaration or you can use
the `%ignore` directive to ignore the declaration.

Finally, suppose that your extension module is linked with another library like this:

```swig

$ gcc -shared example.o example_wrap.o -L/home/beazley/projects/lib -lfoo \
      -o example.so

```

If the `foo` library is compiled as a shared library, you might get the following
problem when you try to use your module:

```swig

% load ./example.so
couldn't load file "./example.so": libfoo.so: cannot open shared object file:
No such file or directory
%        

```

This error is generated because the dynamic linker can't locate the
`libfoo.so` library.  When shared libraries are loaded, the
system normally only checks a few standard locations such as
`/usr/lib` and `/usr/local/lib`.   To fix this problem,
there are several things you can do.  First, you can recompile your extension
module with extra path information. For example, on Linux you can do this:

```swig

$ gcc -shared example.o example_wrap.o -L/home/beazley/projects/lib -lfoo \
      -Xlinker -rpath /home/beazley/projects/lib \
      -o example.so

```

Alternatively, you can set the `LD_LIBRARY_PATH` environment variable to
include the directory with your shared libraries. 
If setting `LD_LIBRARY_PATH`, be aware that setting this variable can introduce
a noticeable performance impact on all other applications that you run.
To set it only for Tcl, you might want to do this instead:

```swig

$ env LD_LIBRARY_PATH=/home/beazley/projects/lib tclsh

```

Finally, you can use a command such as `ldconfig` to add additional search paths
to the default system configuration (this requires root access and you will need to read
the man pages).

### <a name="Tcl_nn7"></a> 39.1.5 Compilation of C++ extensions

Compilation of C++ extensions has traditionally been a tricky problem.
Since the Tcl interpreter is written in C, you need to take steps to
make sure C++ is properly initialized and that modules are compiled
correctly.

On most machines, C++ extension modules should be linked using the C++
compiler.  For example:

```swig

% swig -c++ -tcl example.i
% g++ -fPIC -c example.cxx
% g++ -fPIC -c example_wrap.cxx -I/usr/local/include
% g++ -shared example.o example_wrap.o -o example.so

```

In addition to this, you may need to include additional library
files to make it work.  For example, if you are using the Sun C++ compiler on
Solaris, you often need to add an extra library `-lCrun` like this:

```swig

% swig -c++ -tcl example.i
% CC -KPIC -c example.cxx
% CC -KPIC -c example_wrap.cxx -I/usr/local/include
% CC -G example.o example_wrap.o -L/opt/SUNWspro/lib -o example.so -lCrun

```

Of course, the extra libraries to use are completely non-portable—you will 
probably need to do some experimentation.

Sometimes people have suggested that it is necessary to relink the
Tcl interpreter using the C++ compiler to make C++ extension modules work.
In the experience of this author, this has never actually appeared to be
necessary.   Relinking the interpreter with C++ really only includes the 
special run-time libraries described above—as long as you link your extension 
modules with these libraries, it should not be necessary to rebuild Tcl.

If you aren't entirely sure about the linking of a C++ extension, you
might look at an existing C++ program.  On many Unix machines, the
`ldd` command will list library dependencies.  This should give
you some clues about what you might have to include when you link your
extension module. For example:

```swig

$ ldd swig
        libstdc++-libc6.1-1.so.2 => /usr/lib/libstdc++-libc6.1-1.so.2 (0x40019000)
        libm.so.6 => /lib/libm.so.6 (0x4005b000)
        libc.so.6 => /lib/libc.so.6 (0x40077000)
        /lib/ld-linux.so.2 => /lib/ld-linux.so.2 (0x40000000)
$

```

As a final complication, a major weakness of C++ is that it does not
define any sort of standard for binary linking of libraries.  This
means that C++ code compiled by different compilers will not link
together properly as libraries nor is the memory layout of classes and
data structures implemented in any kind of portable manner.  In a
monolithic C++ program, this problem may be unnoticed.  However, in Tcl, it
is possible for different extension modules to be compiled with
different C++ compilers.  As long as these modules are self-contained,
this probably won't matter.  However, if these modules start sharing data,
you will need to take steps to avoid segmentation faults and other
erratic program behavior.   If working with lots of software components, you
might want to investigate using a more formal standard such as COM.

### <a name="Tcl_nn8"></a> 39.1.6 Compiling for 64-bit platforms

On platforms that support 64-bit applications (Solaris, Irix, etc.),
special care is required when building extension modules.  On these
machines, 64-bit applications are compiled and linked using a different
set of compiler/linker options.  In addition, it is not generally possible to mix 
32-bit and 64-bit code together in the same application.

To utilize 64-bits, the Tcl executable will need to be recompiled
as a 64-bit application.  In addition, all libraries, wrapper code,
and every other part of your application will need to be compiled for
64-bits.  If you plan to use other third-party extension modules, they
will also have to be recompiled as 64-bit extensions.

If you are wrapping commercial software for which you have no source
code, you will be forced to use the same linking standard as used by
that software.  This may prevent the use of 64-bit extensions.  It may
also introduce problems on platforms that support more than one
linking standard (e.g., -o32 and -n32 on Irix).

### <a name="Tcl_nn9"></a> 39.1.7 Setting a package prefix

To avoid namespace problems, you can instruct SWIG to append a package
prefix to all of your functions and variables. This is done using the
-prefix option as follows :

```swig

swig -tcl -prefix Foo example.i

```

If you have a function "`bar`" in the SWIG file, the prefix
option will append the prefix to the name when creating a command and
call it "`Foo_bar`".

### <a name="Tcl_nn10"></a> 39.1.8 Using namespaces

Alternatively, you can have SWIG install your module into a Tcl
namespace by specifying the `-namespace` option :

```swig

swig -tcl -namespace example.i

```

By default, the name of the namespace will be the same as the module
name, but you can override it using the `-prefix` option.

When the `-namespace` option is used, objects in the module
are always accessed with the namespace name such as `Foo::bar`.

## <a name="Tcl_nn11"></a> 39.2 Building Tcl/Tk Extensions under Windows 95/NT

Building a SWIG extension to Tcl/Tk under Windows 95/NT is roughly
similar to the process used with Unix.  Normally, you will want to
produce a DLL that can be loaded into tclsh or wish.  This section
covers the process of using SWIG with Microsoft Visual C++.
although the procedure may be similar with other compilers.

### <a name="Tcl_nn12"></a> 39.2.1 Running SWIG from Developer Studio

If you are developing your application within Microsoft developer
studio, SWIG can be invoked as a custom build option.  The process
roughly follows these steps :

- Open up a new workspace and use the AppWizard to select a DLL project.
- Add both the SWIG interface file (the .i file), any supporting C
files, and the name of the wrapper file that will be created by SWIG
(ie. `example_wrap.c`).  Note : If using C++, choose a
different suffix for the wrapper file such as
`example_wrap.cxx`. Don't worry if the wrapper file doesn't
exist yet--Developer studio will keep a reference to it around.
- Select the SWIG interface file and go to the settings menu.  Under
settings, select the "Custom Build" option.
- Enter "SWIG" in the description field.
- Enter "```
swig -tcl -o $(ProjDir)\$(InputName)_wrap.c
$(InputPath)
```" in the "Build command(s) field"
- Enter "`$(ProjDir)\$(InputName)_wrap.c`" in the "Output files(s) field".
- Next, select the settings for the entire project and go to
"C++:Preprocessor". Add the include directories for your Tcl
installation under "Additional include directories".
- Finally, select the settings for the entire project and go to
"Link Options".  Add the Tcl library file to your link libraries.  For
example "`tcl80.lib`".  Also, set the name of the output file
to match the name of your Tcl module (ie. example.dll).
- Build your project.

Now, assuming all went well, SWIG will be automatically invoked when
you build your project.  Any changes made to the interface file will
result in SWIG being automatically invoked to produce a new version of
the wrapper file.  To run your new Tcl extension, simply run
`tclsh` or `wish` and use the `load` command.
For example :

```swig

MSDOS > tclsh80
% load example.dll
% fact 4
24
%

```

### <a name="Tcl_nn13"></a> 39.2.2 Using NMAKE

Alternatively, SWIG extensions can be built by writing a Makefile for
NMAKE.  To do this, make sure the environment variables for MSVC++ are
available and the MSVC++ tools are in your path.  Now, just write a
short Makefile like this :

```swig

# Makefile for building various SWIG generated extensions

SRCS          = example.c
IFILE         = example
INTERFACE     = $(IFILE).i
WRAPFILE      = $(IFILE)_wrap.c

# Location of the Visual C++ tools (32 bit assumed)

TOOLS         = c:\msdev
TARGET        = example.dll
CC            = $(TOOLS)\bin\cl.exe
LINK          = $(TOOLS)\bin\link.exe
INCLUDE32     = -I$(TOOLS)\include
MACHINE       = IX86

# C Library needed to build a DLL

DLLIBC        = msvcrt.lib oldnames.lib  

# Windows libraries that are apparently needed
WINLIB        = kernel32.lib advapi32.lib user32.lib gdi32.lib comdlg32.lib 
winspool.lib

# Libraries common to all DLLs
LIBS          = $(DLLIBC) $(WINLIB) 

# Linker options
LOPT      = -debug:full -debugtype:cv /NODEFAULTLIB /RELEASE /NOLOGO /
MACHINE:$(MACHINE) -entry:_DllMainCRTStartup@12 -dll

# C compiler flags

CFLAGS    = /Z7 /Od /c /nologo
TCL_INCLUDES  = -Id:\tcl8.0a2\generic -Id:\tcl8.0a2\win
TCLLIB        = d:\tcl8.0a2\win\tcl80.lib

tcl:
        ..\..\swig -tcl -o $(WRAPFILE) $(INTERFACE)
        $(CC) $(CFLAGS) $(TCL_INCLUDES) $(SRCS) $(WRAPFILE)
        set LIB=$(TOOLS)\lib
        $(LINK) $(LOPT) -out:example.dll $(LIBS) $(TCLLIB) example.obj example_wrap.obj

```

To build the extension, run NMAKE (you may need to run vcvars32
first).  This is a pretty minimal Makefile, but hopefully it's enough
to get you started.  With a little practice, you'll be making lots of
Tcl extensions.

## <a name="Tcl_nn14"></a> 39.3 A tour of basic C/C++ wrapping

By default, SWIG tries to build a very natural Tcl interface to your
C/C++ code.  Functions are wrapped as functions, classes are wrapped
in an interface that mimics the style of Tk widgets and [incr Tcl]
classes.  This section briefly covers the essential aspects of this
wrapping.

### <a name="Tcl_nn15"></a> 39.3.1 Modules

The SWIG `%module` directive specifies the name of the Tcl
module. If you specify ``%module example`', then everything is
compiled into an extension module `example.so`. When choosing a
module name, make sure you don't use the same name as a built-in
Tcl command.

One pitfall to watch out for is module names involving numbers.  If
you specify a module name like `%module md5`, you'll find that the
load command no longer seems to work:

```swig

% load ./md5.so
couldn't find procedure Md_Init

```

To fix this, supply an extra argument to `load` like this:

```swig

% load ./md5.so md5

```

### <a name="Tcl_nn16"></a> 39.3.2 Functions

Global functions are wrapped as new Tcl built-in commands.  For example,

```swig

%module example
int fact(int n);

```

creates a built-in function `fact` that works exactly
like you think it does:

```swig

% load ./example.so
% fact 4
24
% set x [fact 6]
%

```

### <a name="Tcl_nn17"></a> 39.3.3 Global variables

C/C++ global variables are wrapped by Tcl global variables.  For example:

```swig

// SWIG interface file with global variables
%module example
...
%inline %{
extern double density;
%}
...

```

Now look at the Tcl interface:

```swig

% puts $density          # Output value of C global variable
1.0
% set density 0.95       # Change value

```

If you make an error in variable assignment, you will get an
error message.  For example:

```swig

% set density "hello"
can't set "density": Type error. expected a double.
%

```

If a variable is declared as `const`, it is wrapped as a
read-only variable.  Attempts to modify its value will result in an
error.

To make ordinary variables read-only, you can use the `%immutable` directive. For example:

```swig

%{
extern char *path;
%}
%immutable;
extern char *path;
%mutable;

```

The `%immutable` directive stays in effect until it is explicitly disabled or cleared using
`%mutable`.
See the [Creating read-only variables](SWIG/#SWIG_readonly_variables) section for further details.

If you just want to make a specific variable immutable, supply a declaration name.  For example:

```swig

%{
extern char *path;
%}
%immutable path;
...
extern char *path;      // Read-only (due to %immutable)

```

### <a name="Tcl_nn18"></a> 39.3.4 Constants and enums

C/C++ constants are installed as global Tcl variables containing the
appropriate value.  To create a constant, use `#define`, `enum`, or the
`%constant` directive.  For example:

```swig

#define PI 3.14159
#define VERSION "1.0"

enum Beverage { ALE, LAGER, STOUT, PILSNER };

%constant int FOO = 42;
%constant const char *path = "/usr/local";

```

For enums, make sure that the definition of the enumeration actually appears in a header
file or in the wrapper file somehow—if you just stick an enum in a SWIG interface without
also telling the C compiler about it, the wrapper code won't compile.

Note:  declarations declared as `const` are wrapped as read-only variables and
will be accessed using the `cvar` object described in the previous section.  They
are not wrapped as constants.   For further discussion about this, see the [SWIG Basics](SWIG/#SWIG) chapter.

Constants are not guaranteed to remain constant in Tcl—the value
of the constant could be accidentally reassigned. You will just have to be careful.

A peculiarity of installing constants as variables is that it is necessary to use the Tcl `global` statement to
access constants in procedure bodies.  For example:

```swig

proc blah {} {
  global FOO
  bar $FOO
}

```

### <a name="Tcl_nn19"></a> 39.3.5 Pointers

C/C++ pointers are fully supported by SWIG.  Furthermore, SWIG has no problem working with
incomplete type information.  Here is a rather simple interface:

```swig

%module example

FILE *fopen(const char *filename, const char *mode);
int fputs(const char *, FILE *);
int fclose(FILE *);

```

When wrapped, you will be able to use the functions in a natural way from Tcl. 
For example:

```swig

% load ./example.so
% set f [fopen junk w]
% fputs "Hello World\n" $f
% fclose $f

```

If this makes you uneasy, rest assured that there is no
deep magic involved.  Underneath the covers, pointers to C/C++ objects are
simply represented as opaque values–normally an encoded character
string like this:

```swig

% puts $f
_c0671108_p_FILE
% 

```

This pointer value can be freely passed around to different C functions that
expect to receive an object of type `FILE *`.  The only thing you can't do is 
dereference the pointer from Tcl.

The NULL pointer is represented by the string `NULL`.

As much as you might be inclined to modify a pointer value directly
from Tcl, don't.  The hexadecimal encoding is not necessarily the
same as the logical memory address of the underlying object.  Instead
it is the raw byte encoding of the pointer value.  The encoding will
vary depending on the native byte-ordering of the platform (i.e.,
big-endian vs. little-endian).  Similarly, don't try to manually cast
a pointer to a new type by simply replacing the type-string.  This
may not work like you expect and it is particularly dangerous when
casting C++ objects. If you need to cast a pointer or
change its value, consider writing some helper functions instead.  For
example:

```swig

%inline %{
/* C-style cast */
Bar *FooToBar(Foo *f) {
  return (Bar *) f;
}

/* C++-style cast */
Foo *BarToFoo(Bar *b) {
  return dynamic_cast<Foo*>(b);
}

Foo *IncrFoo(Foo *f, int i) {
  return f+i;
}
%}

```

Also, if working with C++, you should always try
to use the new C++ style casts.  For example, in the above code, the
C-style cast may return a bogus result whereas as the C++-style cast will return
`None` if the conversion can't be performed.

### <a name="Tcl_nn20"></a> 39.3.6 Structures

If you wrap a C structure, it is wrapped by a Tcl interface that somewhat resembles a Tk widget.
This provides a very natural interface.  For example,

```swig

struct Vector {
  double x, y, z;
};

```

is used as follows:

```swig

% Vector v
% v configure -x 3.5 -y 7.2
% puts "[v cget -x] [v cget -y] [v cget -z]"
3.5 7.2 0.0
% 

```

Similar access is provided for unions and the data members of C++ classes.

In the above example, `v` is a name that's used for the object.  However,
underneath the covers, there's a pointer to a raw C structure.  This can be obtained
by looking at the `-this` attribute.  For example:

```swig

% puts [v cget -this]
_88e31408_p_Vector

```

Further details about the relationship between the Tcl and the underlying C structure
are covered a little later.

`const` members of a structure are read-only. Data members
can also be forced to be read-only using the `%immutable` directive. For example:

```swig

struct Foo {
  ...
  %immutable;
  int x;        /* Read-only members */
  char *name;
  %mutable;
  ...
};

```

When `char *` members of a structure are wrapped, the contents are assumed to be
dynamically allocated using `malloc` or `new` (depending on whether or not
SWIG is run with the -c++ option).   When the structure member is set, the old contents will be 
released and a new value created.   If this is not the behavior you want, you will have to use
a typemap (described later).

If a structure contains arrays, access to those arrays is managed through pointers.  For
example, consider this:

```swig

struct Bar {
  int  x[16];
};

```

If accessed in Tcl, you will see behavior like this:

```swig

% Bar b
% puts [b cget -x]
_801861a4_p_int
% 

```

This pointer can be passed around to functions that expect to receive
an `int *` (just like C).   You can also set the value of an array member using
another pointer.  For example:

```swig

% Bar c
% c configure -x [b cget -x]   # Copy contents of b.x to c.x

```

For array assignment, SWIG copies the entire contents of the array starting with the data pointed
to by `b.x`.   In this example, 16 integers would be copied.  Like C, SWIG makes
no assumptions about bounds checking—if you pass a bad pointer, you may get a segmentation
fault or access violation.

When a member of a structure is itself a structure, it is handled as a
pointer.  For example, suppose you have two structures like this:

```swig

struct Foo {
  int a;
};

struct Bar {
  Foo f;
};

```

Now, suppose that you access the `f` attribute of `Bar` like this:

```swig

% Bar b
% set x [b cget -f]

```

In this case, `x` is a pointer that points to the `Foo` that is inside `b`.
This is the same value as generated by this C code:

```swig

Bar b;
Foo *x = &b->f;       /* Points inside b */

```

However, one peculiarity of accessing a substructure like this is that the returned
value does work quite like you might expect.  For example:

```swig

% Bar b
% set x [b cget -f]
% x cget -a
invalid command name "x"

```

This is because the returned value was not created in a normal way from the interpreter (x is 
not a command object). To make it function normally, just
evaluate the variable like this:

```swig

% Bar b
% set x [b cget -f]
% $x cget -a
0
%

```

In this example, `x` points inside the original structure.  This means that modifications
work just like you would expect.  For example:

```swig

% Bar b
% set x [b cget -f]
% $x configure -a 3            # Modifies contents of f (inside b)
% [b cget -f] -configure -a 3  # Same thing

```

In many of these structure examples, a simple name like "v" or "b" has been given
to wrapped structures.  If necessary, this name can be passed to functions
that expect to receive an object.  For example, if you have a function like this,

```swig

void blah(Foo *f);

```

you can call the function in Tcl as follows:

```swig

% Foo x            # Create a Foo object 
% blah x           # Pass the object to a function

```

It is also possible to call the function using the raw pointer value. For
instance:

```swig

% blah [x cget -this]   # Pass object to a function

```

It is also possible to create and use objects using variables.  For example:

```swig

% set b [Bar]            # Create a Bar
% $b cget -f             # Member access
% puts $b
_108fea88_p_Bar
%

```

Finally, to destroy objects created from Tcl, you can either let the object
name go out of scope or you can explicitly delete the object as shown below.
Objects won't get automatically destroyed when the Tcl program exits, so if
it's important that the C++ destructor is called for a class you'll need to
make sure that you explicitly do this for objects of that class before program
exit.

For example:

```swig

% Foo f                 # Create object f
% rename f ""

```

or

```swig

% Foo f                 # Create object f
% f -delete

```

Note: Tcl only destroys the underlying object if it has ownership.  See the
memory management section that appears shortly.

### <a name="Tcl_nn21"></a> 39.3.7 C++ classes

C++ classes are wrapped as an extension of structure wrapping. For example, if you have this class,

```swig

class List {
public:
  List();
  ~List();
  int  search(char *item);
  void insert(char *item);
  void remove(char *item);
  char *get(int n);
  int  length;
};

```

you can use it in Tcl like this:

```swig

% List x
% x insert Ale
% x insert Stout
% x insert Lager
% x get 1
Stout
% puts [x cget -length]
3
%

```

Class data members are accessed in the same manner as C structures.

Static class members are accessed as global functions or variables.
To illustrate, suppose you have a class like this:

```swig

class Spam {
public:
  static void foo();
  static int bar;
};

```

In Tcl, the static member is accessed as follows:

```swig

% Spam_foo        # Spam::foo()
% puts $Spam_bar  # Spam::bar

```

### <a name="Tcl_nn22"></a> 39.3.8 C++ inheritance

SWIG is fully aware of issues related to C++ inheritance.  Therefore, if you have
classes like this

```swig

class Foo {
...
};

class Bar : public Foo {
...
};

```

An object of type `Bar` can be used where a `Foo` is expected.  For
example, if you have this function:

```swig

void spam(Foo *f);

```

then the function `spam()` accepts a `Foo *` or a pointer to any class derived from `Foo`.
For instance:

```swig

% Foo f      # Create a Foo
% Bar b      # Create a Bar
% spam f     # OK
% spam b     # OK

```

It is safe to use multiple inheritance with SWIG.

### <a name="Tcl_nn23"></a> 39.3.9 Pointers, references, values, and arrays

In C++, there are many different ways a function might receive
and manipulate objects.  For example:

```swig

void spam1(Foo *x);      // Pass by pointer
void spam2(Foo &x);      // Pass by reference
void spam3(Foo x);       // Pass by value
void spam4(Foo x[]);     // Array of objects

```

In Tcl, there is no detailed distinction like this.
Because of this, SWIG unifies all of these types
together in the wrapper code.  For instance, if you actually had the
above functions, it is perfectly legal to do this:

```swig

% Foo f             # Create a Foo
% spam1 f           # Ok. Pointer
% spam2 f           # Ok. Reference
% spam3 f           # Ok. Value.
% spam4 f           # Ok. Array (1 element)

```

Similar behavior occurs for return values.  For example, if you had
functions like this,

```swig

Foo *spam5();
Foo &spam6();
Foo  spam7();

```

then all three functions will return a pointer to some `Foo` object.
Since the third function (spam7) returns a value, newly allocated memory is used 
to hold the result and a pointer is returned (Tcl will release this memory 
when the return value is garbage collected).

### <a name="Tcl_nn24"></a> 39.3.10 C++ overloaded functions

C++ overloaded functions, methods, and constructors are mostly supported by SWIG.  For example,
if you have two functions like this:

```swig

void foo(int);
void foo(char *c);

```

You can use them in Tcl in a straightforward manner:

```swig

% foo 3            # foo(int)
% foo Hello        # foo(char *c)

```

Similarly, if you have a class like this,

```swig

class Foo {
public:
  Foo();
  Foo(const Foo &);
  ...
};

```

you can write Tcl code like this:

```swig

% Foo f                # Create a Foo
% Foo g f              # Copy f

```

Overloading support is not quite as flexible as in C++. Sometimes there are methods that SWIG
can't disambiguate. For example:

```swig

void spam(int);
void spam(short);

```

or

```swig

void foo(Bar *b);
void foo(Bar &b);

```

If declarations such as these appear, you will get a warning message like this:

```swig

example.i:12: Warning 509: Overloaded method spam(short) effectively ignored,
example.i:11: Warning 509: as it is shadowed by spam(int).

```

To fix this, you either need to ignore or rename one of the methods.  For example:

```swig

%rename(spam_short) spam(short);
...
void spam(int);    
void spam(short);   // Accessed as spam_short

```

or

```swig

%ignore spam(short);
...
void spam(int);    
void spam(short);   // Ignored

```

SWIG resolves overloaded functions and methods using a disambiguation scheme that ranks and sorts
declarations according to a set of type-precedence rules.    The order in which declarations appear
in the input does not matter except in situations where ambiguity arises–in this case, the
first declaration takes precedence.

Please refer to the "SWIG and C++" chapter for more information about overloading.

### <a name="Tcl_nn25"></a> 39.3.11 C++ operators

Certain C++ overloaded operators can be handled automatically by SWIG.  For example,
consider a class like this:

```swig

class Complex {
private:
  double rpart, ipart;
public:
  Complex(double r = 0, double i = 0) : rpart(r), ipart(i) { }
  Complex(const Complex &c) : rpart(c.rpart), ipart(c.ipart) { }
  Complex &operator=(const Complex &c);
  Complex operator+(const Complex &c) const;
  Complex operator-(const Complex &c) const;
  Complex operator*(const Complex &c) const;
  Complex operator-() const;
  
  double re() const { return rpart; }
  double im() const { return ipart; }
};

```

When wrapped, it works like this:

```swig

% Complex c 3 4
% Complex d 7 8
% set e [c + d]
% $e re
10.0
% $e im
12.0

```

It should be stressed that operators in SWIG have no relationship to operators
in Tcl.  In fact, the only thing that's happening here is that an operator like
`operator +` has been renamed to a method `+`.    Therefore, the
statement `[c + d]` is really just invoking the `+` method on `c`.
When more than operator is defined (with different arguments), the standard
method overloading facilities are used.  Here is a rather odd looking example:

```swig

% Complex c 3 4
% Complex d 7 8
% set e [c - d]       # operator-(const Complex &)
% puts "[$e re] [$e im]"
10.0 12.0
% set f [c -]         # operator-()
% puts "[$f re] [$f im]"
-3.0 -4.0
%

```

One restriction with operator overloading support is that SWIG is not
able to fully handle operators that aren't defined as part of the class.
For example, if you had code like this

```swig

class Complex {
...
friend Complex operator+(double, const Complex &c);
...
};

```

then SWIG doesn't know what to do with the friend function–in fact,
it simply ignores it and issues a warning.   You can still wrap the operator,
but you may have to encapsulate it in a special function.  For example:

```swig

%rename(Complex_add_dc) operator+(double, const Complex &);
...
Complex operator+(double, const Complex &c);

```

There are ways to make this operator appear as part of the class using the `%extend` directive.
Keep reading.

### <a name="Tcl_nn26"></a> 39.3.12 C++ namespaces

SWIG is aware of C++ namespaces, but namespace names do not appear in
the module nor do namespaces result in a module that is broken up into
submodules or packages.  For example, if you have a file like this,

```swig

%module example

namespace foo {
  int fact(int n);
  struct Vector {
    double x, y, z;
  };
};

```

it works in Tcl as follows:

```swig

% load ./example.so
% fact 3
6
% Vector v
% v configure -x 3.4

```

If your program has more than one namespace, name conflicts (if any) can be resolved using `%rename`
For example:

```swig

%rename(Bar_spam) Bar::spam;

namespace Foo {
  int spam();
}

namespace Bar {
  int spam();
}

```

If you have more than one namespace and your want to keep their
symbols separate, consider wrapping them as separate SWIG modules.
For example, make the module name the same as the namespace and create
extension modules for each namespace separately.  If your program
utilizes thousands of small deeply nested namespaces each with
identical symbol names, well, then you get what you deserve.

### <a name="Tcl_nn27"></a> 39.3.13 C++ templates

C++ templates don't present a huge problem for SWIG.  However, in order
to create wrappers, you have to tell SWIG to create wrappers for a particular
template instantiation.  To do this, you use the `%template` directive.
For example:

```swig

%module example
%{
#include "pair.h"
%}

template<class T1, class T2>
struct pair {
  typedef T1 first_type;
  typedef T2 second_type;
  T1 first;
  T2 second;
  pair();
  pair(const T1&, const T2&);
  ~pair();
};

%template(pairii) pair<int, int>;

```

In Tcl:

```swig

% pairii p 3 4
% p cget -first
3
% p cget -second
4

```

Obviously, there is more to template wrapping than shown in this example.
More details can be found in the [SWIG and C++](SWIGPlus/#SWIGPlus) chapter.   Some more complicated
examples will appear later.

### <a name="Tcl_nn28"></a> 39.3.14 C++ Smart Pointers

In certain C++ programs, it is common to use classes that have been wrapped by
so-called "smart pointers."   Generally, this involves the use of a template class
that implements `operator->()` like this:

```swig

template<class T> class SmartPtr {
  ...
  T *operator->();
  ...
}

```

Then, if you have a class like this,

```swig

class Foo {
public:
  int x;
  int bar();
};

```

A smart pointer would be used in C++ as follows:

```swig

SmartPtr<Foo> p = CreateFoo();   // Created somehow (not shown)
...
p->x = 3;                        // Foo::x
int y = p->bar();                // Foo::bar

```

To wrap this in Tcl, simply tell SWIG about the `SmartPtr` class and the low-level
`Foo` object.  Make sure you instantiate `SmartPtr` using `%template` if necessary.
For example:

```swig

%module example
...
%template(SmartPtrFoo) SmartPtr<Foo>;
...

```

Now, in Tcl, everything should just "work":

```swig

% set p [CreateFoo]                  # Create a smart-pointer somehow
% $p configure -x 3                  # Foo::x
% $p bar                             # Foo::bar

```

If you ever need to access the underlying pointer returned by `operator->()` itself,
simply use the `__deref__()` method.  For example:

```swig

% set f [$p __deref__]    # Returns underlying Foo *

```

## <a name="Tcl_nn29"></a> 39.4 Further details on the Tcl class interface

In the previous section, a high-level view of Tcl wrapping was
presented.  A key component of this wrapping is that structures and
classes are wrapped by Tcl class-like objects. This provides a very
natural Tcl interface and allows SWIG to support a number of
advanced features such as operator overloading.   However, a number
of low-level details were omitted.  This section provides a brief overview
of how the proxy classes work.

### <a name="Tcl_nn30"></a> 39.4.1 Proxy classes

In the ["SWIG basics"](SWIG/#SWIG) and ["SWIG and C++"](SWIGPlus/#SWIGPlus) chapters,
details of low-level structure and class wrapping are described.  To summarize those chapters, if you
have a class like this

```swig

class Foo {
public:
  int x;
  int spam(int);
  ...

```

then SWIG transforms it into a set of low-level procedural wrappers. For example:

```swig

Foo *new_Foo() {
  return new Foo();
}
void delete_Foo(Foo *f) {
  delete f;
}
int Foo_x_get(Foo *f) {
  return f->x;
}
void Foo_x_set(Foo *f, int value) {
  f->x = value;
}
int Foo_spam(Foo *f, int arg1) {
  return f->spam(arg1);
}

```

These wrappers are actually found in the Tcl extension module.  For example, you can certainly do this:

```swig

% load ./example.so
% set f [new_Foo]
% Foo_x_get $f
0
% Foo_spam $f 3
1
%

```

However, in addition to this, the classname `Foo` is used as an object constructor
function.   This allows objects to be encapsulated objects that look a lot like Tk widgets
as shown in the last section.

### <a name="Tcl_nn31"></a> 39.4.2 Memory management

Associated with each wrapped object, is an ownership flag `thisown`   The value of this
flag determines who is responsible for deleting the underlying C++ object.  If set to 1,
the Tcl interpreter destroys the C++ object when the proxy class is 
garbage collected.   If set to 0 (or if the attribute is missing), then the destruction
of the proxy class has no effect on the C++ object.

When an object is created by a constructor or returned by value, Tcl automatically takes
ownership of the result.  For example:

```swig

class Foo {
public:
  Foo();
  Foo bar();
};

```

In Tcl:

```swig

% Foo f
% f cget -thisown
1
% set g [f bar]
% $g cget -thisown
1

```

On the other hand, when pointers are returned to Tcl, there is often no way to know where
they came from.  Therefore, the ownership is set to zero.  For example:

```swig

class Foo {
public:
  ...
  Foo *spam();
  ...
};

```

```swig

% Foo f
% set s [f spam]
% $s cget -thisown
0
% 

```

This behavior is especially important for classes that act as
containers.  For example, if a method returns a pointer to an object
that is contained inside another object, you definitely don't want
Tcl to assume ownership and destroy it!

Related to containers, ownership issues can arise whenever an object is assigned to a member
or global variable.  For example, consider this interface:

```swig

%module example

struct Foo {
  int  value;
  Foo  *next;
};

Foo *head = 0;

```

When wrapped in Tcl, careful observation will reveal that ownership changes whenever an object
is assigned to a global variable.  For example:

```swig

% Foo f
% f cget -thisown
1
% set head f
% f cget -thisown
0

```

In this case, C is now holding a reference to the object—you probably don't want Tcl to destroy it.
Similarly, this occurs for members.  For example:

```swig

% Foo f
% Foo g
% f cget -thisown
1
% g cget -thisown
1
% f configure -next g
% g cget -thisown 
0
%

```

For the most part, memory management issues remain hidden.  However,
there are occasionally situations where you might have to manually
change the ownership of an object.  For instance, consider code like this:

```swig

class Node {
  Object *value;
public:
  void set_value(Object *v) { value = v; }
  ...
};

```

Now, consider the following Tcl code:

```swig

% Object v                 # Create an object
% Node n                   # Create a node
% n setvalue v             # Set value
% v cget -thisown
1
% 

```

In this case, the object `n` is holding a reference to
`v` internally.  However, SWIG has no way to know that this
has occurred.  Therefore, Tcl still thinks that it has ownership of the
object.  Should the proxy object be destroyed, then the C++ destructor
will be invoked and `n` will be holding a stale-pointer.  If
you're lucky, you will only get a segmentation fault.

To work around this, it is always possible to flip the ownership flag. For example,

```swig

% v -disown              # Give ownership to C/C++
% v -acquire             # Acquire ownership

```

It is also possible to deal with situations like this using
typemaps–an advanced topic discussed later.

## <a name="Tcl_nn32"></a> 39.5 Input and output parameters

A common problem in some C programs is handling parameters passed as simple pointers.  For
example:

```swig

void add(int x, int y, int *result) {
  *result = x + y;
}

```

or perhaps

```swig

int sub(int *x, int *y) {
  return *x+*y;
}

```

The easiest way to handle these situations is to use the `typemaps.i` file.  For example:

```swig

%module example
%include "typemaps.i"

void add(int, int, int *OUTPUT);
int  sub(int *INPUT, int *INPUT);

```

In Tcl, this allows you to pass simple values instead of pointer.  For example:

```swig

set a [add 3 4]
puts $a
7

```

Notice how the `INPUT` parameters allow integer values to be passed instead of pointers
and how the `OUTPUT` parameter creates a return result.

If you don't want to use the names `INPUT` or `OUTPUT`, use the `%apply`
directive.  For example:

```swig

%module example
%include "typemaps.i"

%apply int *OUTPUT { int *result };
%apply int *INPUT  { int *x, int *y};

void add(int x, int y, int *result);
int  sub(int *x, int *y);

```

If a function mutates one of its parameters like this,

```swig

void negate(int *x) {
  *x = -(*x);
}

```

you can use `INOUT` like this:

```swig

%include "typemaps.i"
...
void negate(int *INOUT);

```

In Tcl, a mutated parameter shows up as a return value.  For example:

```swig

set a [negate 3]
puts $a
-3

```

The most common use of these special typemap rules is to handle functions that
return more than one value.   For example, sometimes a function returns a result
as well as a special error code:

```swig

/* send message, return number of bytes sent, along with success code */
int send_message(char *text, int *success);

```

To wrap such a function, simply use the `OUTPUT` rule above. For example:

```swig

%module example
%include "typemaps.i"
%apply int *OUTPUT { int *success };
...
int send_message(char *text, int *success);

```

When used in Tcl, the function will return multiple values as a list.

```swig

set r [send_message "Hello World"]
set bytes [lindex $r 0]
set success [lindex $r 1]

```

Another common use of multiple return values are in query functions.  For example:

```swig

void get_dimensions(Matrix *m, int *rows, int *columns);

```

To wrap this, you might use the following:

```swig

%module example
%include "typemaps.i"
%apply int *OUTPUT { int *rows, int *columns };
...
void get_dimensions(Matrix *m, int *rows, *columns);

```

Now, in Perl:

```swig

set dim [get_dimensions $m]
set r  [lindex $dim 0]
set c  [lindex $dim 1]

```

## <a name="Tcl_nn33"></a> 39.6 Exception handling 

The `%exception` directive can be used to create a user-definable
exception handler in charge of converting exceptions in your C/C++
program into Tcl exceptions.  The chapter on customization features
contains more details, but suppose you extended the array example into
a C++ class like the following :

```swig

class RangeError {};   // Used for an exception

class DoubleArray {
  private:
    int n;
    double *ptr;
  public:
    // Create a new array of fixed size
    DoubleArray(int size) {
      ptr = new double[size];
      n = size;
    }
    // Destroy an array
    ~DoubleArray() {
      delete ptr;
    }
    // Return the length of the array
    int   length() {
      return n;
    }

    // Get an item from the array and perform bounds checking.
    double getitem(int i) {
      if ((i >= 0) && (i < n))
        return ptr[i];
      else
        throw RangeError();
    }

    // Set an item in the array and perform bounds checking.
    void setitem(int i, double val) {
      if ((i >= 0) && (i < n))
        ptr[i] = val;
      else {
        throw RangeError();
      }
    }
  };

```

The functions associated with this class can throw a C++ range
exception for an out-of-bounds array access.  We can catch this in our
Tcl extension by specifying the following in an interface file :

```swig

%exception {
  try {
    $action                // Gets substituted by actual function call
  }
  catch (RangeError) {
    Tcl_SetResult(interp, (char *)"Array index out-of-bounds", TCL_STATIC);
    return TCL_ERROR;
  }
}

```

As shown, the exception handling code will be added to every wrapper function.
Since this is somewhat inefficient.  You might consider refining the 
exception handler to only apply to specific methods like this:

```swig

%exception getitem {
  try {
    $action
  }
  catch (RangeError) {
    Tcl_SetResult(interp, (char *)"Array index out-of-bounds", TCL_STATIC);
    return TCL_ERROR;
  }
}

%exception setitem {
  try {
    $action
  }
  catch (RangeError) {
    Tcl_SetResult(interp, (char *)"Array index out-of-bounds", TCL_STATIC);
    return TCL_ERROR;
  }
}

```

In this case, the exception handler is only attached to methods and functions
named `getitem` and `setitem`.

If you had a lot of different methods, you can avoid extra typing by using a macro.
For example:

```swig

%define RANGE_ERROR
{
  try {
    $action
  }
  catch (RangeError) {
    Tcl_SetResult(interp, (char *)"Array index out-of-bounds", TCL_STATIC);
    return TCL_ERROR;
  }
}
%enddef

%exception getitem RANGE_ERROR;
%exception setitem RANGE_ERROR;

```

Since SWIG's exception handling is user-definable, you are not limited to C++ exception handling.
See the chapter on "[Customization Features](Customization/#Customization)" for more examples.

## <a name="Tcl_nn34"></a> 39.7 Typemaps

This section describes how you can modify SWIG's default wrapping behavior
for various C/C++ datatypes using the `%typemap` directive.   This
is an advanced topic that assumes familiarity with the Tcl C API as well
as the material in the "[Typemaps](Typemaps/#Typemaps)" chapter.

Before proceeding, it should be stressed that typemaps are not a required 
part of using SWIG—the default wrapping behavior is enough in most cases.
Typemaps are only used if you want to change some aspect of the primitive
C-Tcl interface.

### <a name="Tcl_nn35"></a> 39.7.1 What is a typemap?

A typemap is nothing more than a code generation rule that is attached to 
a specific C datatype.   For example, to convert integers from Tcl to C,
you might define a typemap like this:

```swig

%module example

%typemap(in) int {
  if (Tcl_GetIntFromObj(interp, $input, &$1) == TCL_ERROR)
    return TCL_ERROR;
  printf("Received an integer : %d\n", $1);
}
%inline %{
extern int fact(int n);
%}

```

Typemaps are always associated with some specific aspect of code generation.
In this case, the "in" method refers to the conversion of input arguments
to C/C++.  The datatype `int` is the datatype to which the typemap
will be applied.  The supplied C code is used to convert values.  In this
code a number of special variable prefaced by a `$` are used.  The
`$1` variable is placeholder for a local variable of type `int`.
The `$input` variable is the input object of type `Tcl_Obj *`.

When this example is compiled into a Tcl module, it operates as follows:

```swig

% load ./example.so
% fact 6
Received an integer : 6
720

```

In this example, the typemap is applied to all occurrences of the `int` datatype.
You can refine this by supplying an optional parameter name.  For example:

```swig

%module example

%typemap(in) int n {
  if (Tcl_GetIntFromObj(interp, $input, &$1) == TCL_ERROR)
    return TCL_ERROR;
  printf("n = %d\n", $1);
}
%inline %{
extern int fact(int n);
%}

```

In this case, the typemap code is only attached to arguments that exactly match `int n`.

The application of a typemap to specific datatypes and argument names involves
more than simple text-matching–typemaps are fully integrated into the
SWIG type-system.   When you define a typemap for `int`, that typemap
applies to `int` and qualified variations such as `const int`.  In addition,
the typemap system follows `typedef` declarations.  For example:

```swig

%typemap(in) int n {
  if (Tcl_GetIntFromObj(interp, $input, &$1) == TCL_ERROR)
    return TCL_ERROR;
  printf("n = %d\n", $1);
}
%inline %{
typedef int Integer;
extern int fact(Integer n);    // Above typemap is applied
%}

```

However, the matching of `typedef` only occurs in one direction.  If you
defined a typemap for `Integer`, it is not applied to arguments of
type `int`.

Typemaps can also be defined for groups of consecutive arguments.  For example:

```swig

%typemap(in) (char *str, int len) {
    $1 = Tcl_GetStringFromObj($input, &$2);
};

int count(char c, char *str, int len);

```

When a multi-argument typemap is defined, the arguments are always handled as a single
Tcl object.  This allows the function to be used like this (notice how the length
parameter is omitted):

```swig

% count e "Hello World"
1

```

### <a name="Tcl_nn36"></a> 39.7.2 Tcl typemaps

The previous section illustrated an "in" typemap for converting Tcl objects to C.
A variety of different typemap methods are defined by the Tcl module.  For example,
to convert a C integer back into a Tcl object, you might define an "out" typemap
like this:

```swig

%typemap(out) int {
  Tcl_SetObjResult(interp, Tcl_NewIntObj($1));
}

```

The following list details all of the typemap methods that can be used by the Tcl module:

`%typemap(in)`

Converts Tcl objects to input function arguments

`%typemap(out)`

Converts return value of a C function to a Tcl object

`%typemap(varin)`

Assigns a C global variable from a Tcl object

`%typemap(varout)`

Returns a C global variable as a Tcl object

`%typemap(freearg)`

Cleans up a function argument (if necessary)

`%typemap(argout)`

Output argument processing

`%typemap(ret)`

Cleanup of function return values

`%typemap(consttab)`

Creation of Tcl constants (constant table)

`%typemap(constcode)`

Creation of Tcl constants (init function)

`%typemap(memberin)`

Setting of structure/class member data

`%typemap(globalin)`

Setting of C global variables

`%typemap(check)`

Checks function input values.

`%typemap(default)`

Set a default value for an argument (making it optional).

`%typemap(arginit)`

Initialize an argument to a value before any conversions occur.

Examples of these methods will appear shortly.

### <a name="Tcl_nn37"></a> 39.7.3 Typemap variables

Within typemap code, a number of special variables prefaced with a `$` may appear.
A full list of variables can be found in the "[Typemaps](Typemaps/#Typemaps)" chapter.
This is a list of the most common variables:

`$1`

A C local variable corresponding to the actual type specified in the
`%typemap` directive.  For input values, this is a C local variable
that's supposed to hold an argument value.  For output values, this is
the raw result that's supposed to be returned to Tcl.

`$input`

 A `Tcl_Obj *` holding a raw Tcl object with an argument or variable value.

`$result`

A `Tcl_Obj *` that holds the result to be returned to Tcl.

`$1_name`

The parameter name that was matched. 

`$1_type`

The actual C datatype matched by the typemap.

`$1_ltype`

An assignable version of the datatype matched by the typemap (a type that can appear on the left-hand-side of
a C assignment operation).  This type is stripped of qualifiers and may be an altered version of `$1_type`.
All arguments and local variables in wrapper functions are declared using this type so that their values can be
properly assigned.

`$symname`

The Tcl name of the wrapper function being created.

### <a name="Tcl_nn38"></a> 39.7.4 Converting  a Tcl list to a char ** 

A common problem in many C programs is the processing of command line
arguments, which are usually passed in an array of NULL terminated
strings.  The following SWIG interface file allows a Tcl list to be
used as a `char **` object.

```swig

%module argv

// This tells SWIG to treat char ** as a special case
%typemap(in) char ** {
  Tcl_Obj **listobjv;
  int       nitems;
  int       i;
  if (Tcl_ListObjGetElements(interp, $input, &nitems, &listobjv) == TCL_ERROR) {
    return TCL_ERROR;
  }
  $1 = (char **) malloc((nitems+1)*sizeof(char *));
  for (i = 0; i < nitems; i++) {
    $1[i] = Tcl_GetString(listobjv[i]);
  }
  $1[i] = 0;
}

// This gives SWIG some cleanup code that will get called after the function call
%typemap(freearg) char ** {
  free($1);
}

// Now a test functions
%inline %{
  int print_args(char **argv) {
    int i = 0;
    while (argv[i]) {
      printf("argv[%d] = %s\n", i, argv[i]);
      i++;
    }
    return i;
  }
%}
%include "tclsh.i"

```

In Tcl:

```swig

% print_args {John Guido Larry}
argv[0] = John
argv[1] = Guido
argv[2] = Larry
3

```

### <a name="Tcl_nn39"></a> 39.7.5 Returning values in arguments

The "argout" typemap can be used to return a value originating from a
function argument. For example :

```swig

// A typemap defining how to return an argument by appending it to the result
%typemap(argout) double *outvalue {
  Tcl_Obj *o = Tcl_NewDoubleObj($1);
  Tcl_ListObjAppendElement(interp, $result, o);
}

// A typemap telling SWIG to ignore an argument for input
// However, we still need to pass a pointer to the C function
%typemap(in, numinputs=0) double *outvalue (double temp) {
  $1 = &temp;
}

// Now a function returning two values
int mypow(double a, double b, double *outvalue) {
  if ((a < 0) || (b < 0)) return -1;
  *outvalue = pow(a, b);
  return 0;
};

```

When wrapped, SWIG matches the `argout` typemap to the
"`double *outvalue`" argument. The numinputs=0 specification tells SWIG
to simply ignore this argument when generating wrapper code.  As a
result, a Tcl function using these typemaps will work like this :

```swig

% mypow 2 3     # Returns two values, a status value and the result
0 8
%

```

### <a name="Tcl_nn40"></a> 39.7.6 Useful functions

The following tables provide some functions that may be useful in
writing Tcl typemaps.

**Integers**

```swig

Tcl_Obj   *Tcl_NewIntObj(int Value);
void       Tcl_SetIntObj(Tcl_Obj *obj, int Value);
int        Tcl_GetIntFromObj(Tcl_Interp *, Tcl_Obj *obj, int *ip);

```

**Floating Point**

```swig

Tcl_Obj  *Tcl_NewDoubleObj(double Value);
void      Tcl_SetDoubleObj(Tcl_Obj *obj, double value);
int       Tcl_GetDoubleFromObj(Tcl_Interp *, Tcl_Obj *o, double *dp);

```

**Strings**

```swig

Tcl_Obj  *Tcl_NewStringObj(char *str, int len);
char     *Tcl_GetStringFromObj(Tcl_Obj *obj, int *len);
void      Tcl_AppendToObj(Tcl_Obj *obj, char *str, int len);

```

**Lists**

```swig

Tcl_Obj  *Tcl_NewListObj(int objc, Tcl_Obj *objv);
int       Tcl_ListObjAppendList(Tcl_Interp *, Tcl_Obj *listPtr, Tcl_Obj *elemListPtr);
int       Tcl_ListObjAppendElement(Tcl_Interp *, Tcl_Obj *listPtr, Tcl_Obj *element);
int       Tcl_ListObjGetElements(Tcl_Interp *, Tcl_Obj *listPtr, int *objcPtr,
                                 Tcl_Obj ***objvPtr);
int       Tcl_ListObjLength(Tcl_Interp *, Tcl_Obj *listPtr, int *intPtr);
int       Tcl_ListObjIndex(Tcl_Interp *, Tcl_Obj *listPtr, int index,
                           Tcl_Obj_Obj **objptr);
int       Tcl_ListObjReplace(Tcl_Interp *, Tcl_Obj *listPtr, int first, int count,
                             int objc, Tcl_Obj *objv);

```

**Objects**

```swig

Tcl_Obj *Tcl_DuplicateObj(Tcl_Obj *obj);
void     Tcl_IncrRefCount(Tcl_Obj *obj);
void     Tcl_DecrRefCount(Tcl_Obj *obj);
int      Tcl_IsShared(Tcl_Obj *obj);

```

### <a name="Tcl_nn41"></a> 39.7.7 Standard  typemaps

The following typemaps show how to convert a few common kinds of
objects between Tcl and C (and to give a better idea of how typemaps
work)

**Integer conversion**

```swig

%typemap(in) int, short, long {
  int temp;
  if (Tcl_GetIntFromObj(interp, $input, &temp) == TCL_ERROR)
    return TCL_ERROR;
  $1 = ($1_ltype) temp;
}

```

```swig

%typemap(out) int, short, long {
  Tcl_SetIntObj($result, (int) $1);
}

```

**Floating point conversion**

```swig

%typemap(in) float, double {
  double temp;
  if (Tcl_GetDoubleFromObj(interp, $input, &temp) == TCL_ERROR)
    return TCL_ERROR;
  $1 = ($1_ltype) temp;
}

```

```swig

%typemap(out) float, double {
  Tcl_SetDoubleObj($result, $1);
}

```

**String Conversion**

```swig

%typemap(in) char * {
  int len;
  $1 = Tcl_GetStringFromObj(interp, &len);
}

```

```swig

%typemap(out, noblock=1, fragment="SWIG_FromCharPtr") char *, const char * {
  Tcl_SetObjResult(interp, SWIG_FromCharPtr((const char *)$1));
}

```

### <a name="Tcl_nn42"></a> 39.7.8 Pointer handling

SWIG pointers are mapped into Tcl strings containing the
hexadecimal value and type.  The following functions can be used to
create and read pointer values.

```
int SWIG_ConvertPtr(Tcl_Obj *obj, void **ptr, swig_type_info *ty, int flags)
```

Converts a Tcl object `obj` to a C pointer.  The result of the conversion is placed
into the pointer located at `ptr`.  `ty` is a SWIG type descriptor structure.
`flags` is used to handle error checking and other aspects of conversion.  It is currently
reserved for future expansion. Returns 0 on success and -1 on error.

```
Tcl_Obj *SWIG_NewPointerObj(void *ptr, swig_type_info *ty, int flags)
```

Creates a new Tcl pointer object.  `ptr` is the pointer to convert, `ty` is the SWIG type descriptor structure that
describes the type, and `own` is a flag reserved for future expansion.

Both of these functions require the use of a special SWIG
type-descriptor structure.  This structure contains information about
the mangled name of the datatype, type-equivalence information, as
well as information about converting pointer values under C++
inheritance.   For a type of `Foo *`, the type descriptor structure
is usually accessed as follows:

```

Foo *f;
if (!SWIG_IsOK(SWIG_ConvertPtr($input, (void **) &f, SWIGTYPE_p_Foo, 0))) {
  SWIG_exception_fail(SWIG_TypeError, "in method '$symname', expecting type Foo");
}

Tcl_Obj *;
obj = SWIG_NewPointerObj(f, SWIGTYPE_p_Foo, 0);

```

In a typemap, the type descriptor should always be accessed using the special typemap
variable `$1_descriptor`.  For example:

```

%typemap(in) Foo * {
  if (!SWIG_IsOK(SWIG_ConvertPtr($input, (void **) &$1, $1_descriptor, 0))) {
    SWIG_exception_fail(SWIG_TypeError, "in method '$symname', expecting type Foo");
  }
}

```

If necessary, the descriptor for any type can be obtained using the `$descriptor()` macro in a typemap.
For example:

```

%typemap(in) Foo * {
  if (!SWIG_IsOK(SWIG_ConvertPtr($input, (void **) &$1, $descriptor(Foo *), 0))) {
    SWIG_exception_fail(SWIG_TypeError, "in method '$symname', expecting type Foo");
  }
}

```

## <a name="Tcl_nn43"></a> 39.8 Turning a SWIG module into a Tcl Package.

SWIG generates all of the code necessary to create a Tcl extension package.
To set the package version use the `-pkgversion` option. For example:

```swig

% swig -tcl -pkgversion 2.3 example.i

```

After building the SWIG generated module, you need to execute
the `pkg_mkIndex` command inside tclsh.  For example :

```swig

unix > tclsh
% pkg_mkIndex . example.so
% exit

```

This creates a file "`pkgIndex.tcl`" with information about the
package.  To use your package, you now need to move it to its own
subdirectory which has the same name as the package. For example :

```swig

./example/
           pkgIndex.tcl           # The file created by pkg_mkIndex
           example.so             # The SWIG generated module

```

Finally, assuming that you're not entirely confused at this point,
make sure that the example subdirectory is visible from the
directories contained in either the `tcl_library` or
`auto_path` variables.  At this point you're ready to use the
package as follows :

```swig

unix > tclsh
% package require example
% fact 4
24
%

```

If  you're working with an example in the current directory and this doesn't work, do this instead :

```swig

unix > tclsh
% lappend auto_path .
% package require example
% fact 4
24

```

As a final note, most SWIG examples do not yet use the
`package` commands. For simple extensions it may be easier just
to use the `load` command instead.

## <a name="Tcl_nn44"></a> 39.9 Building new kinds of Tcl interfaces (in Tcl)

One of the most interesting aspects of Tcl and SWIG is that you can
create entirely new kinds of Tcl interfaces in Tcl using the low-level
SWIG accessor functions.  For example, suppose you had a library of
helper functions to access arrays :

```swig

/* File : array.i */
%module array

%inline %{
double *new_double(int size) {
  return (double *) malloc(size*sizeof(double));
}
void delete_double(double *a) {
  free(a);
}
double get_double(double *a, int index) {
  return a[index];
}
void set_double(double *a, int index, double val) {
  a[index] = val;
}
int *new_int(int size) {
  return (int *) malloc(size*sizeof(int));
}
void delete_int(int *a) {
  free(a);
}
int get_int(int *a, int index) {
  return a[index];
}
int set_int(int *a, int index, int val) {
  a[index] = val;
}
%}

```

While these could be called directly, we could also write a Tcl script
like this :

```swig

proc Array {type size} {
    set ptr [new_$type $size]
    set code {
        set method [lindex $args 0]
        set parms [concat $ptr [lrange $args 1 end]]
        switch $method {
            get {return [eval "get_$type $parms"]}
            set {return [eval "set_$type $parms"]}
            delete {eval "delete_$type $ptr; rename $ptr {}"}
        }
    }
    # Create a procedure
    uplevel "proc $ptr args {set ptr $ptr; set type $type;$code}"
    return $ptr
}

```

Our script allows easy array access as follows :

```swig

set a [Array double 100]                   ;# Create a double [100]
for {set i 0} {$i < 100} {incr i 1} {      ;# Clear the array
        $a set $i 0.0
}
$a set 3 3.1455                            ;# Set an individual element
set b [$a get 10]                          ;# Retrieve an element

set ia [Array int 50]                      ;# Create an int[50]
for {set i 0} {$i < 50} {incr i 1} {       ;# Clear it
        $ia set $i 0
}
$ia set 3 7                                ;# Set an individual element
set ib [$ia get 10]                        ;# Get an individual element

$a delete                                  ;# Destroy a
$ia delete                                 ;# Destroy ia

```

The cool thing about this approach is that it makes a common interface
for two different types of arrays.  In fact, if we were to add more C
datatypes to our wrapper file, the Tcl code would work with those as
well–without modification.  If an unsupported datatype was requested,
the Tcl code would simply return with an error so there is very little
danger of blowing something up (although it is easily accomplished
with an out of bounds array access).

### <a name="Tcl_nn45"></a> 39.9.1 Proxy classes

A similar approach can be applied to proxy classes (also known as
shadow classes).  The following
example is provided by Erik Bierwagen and Paul Saxe.  To use it, run
SWIG with the `-noobject` option (which disables the builtin
object oriented interface).  When running Tcl, simply source this
file.  Now, objects can be used in a more or less natural fashion.

```swig

# swig_c++.tcl
# Provides a simple object oriented interface using
# SWIG's low level interface.
#

proc new {objectType handle_r args} {
    # Creates a new SWIG object of the given type,
    # returning a handle in the variable "handle_r".
    #
    # Also creates a procedure for the object and a trace on
    # the handle variable that deletes the object when the
    # handle variable is overwritten or unset
    upvar $handle_r handle
    #
    # Create the new object
    #
    eval set handle \[new_$objectType $args\]
    #
    # Set up the object procedure
    #
    proc $handle {cmd args} "eval ${objectType}_\$cmd $handle \$args"
    #
    # And the trace ...
    #
    uplevel trace variable $handle_r uw "{deleteObject $objectType $handle}"
    #
    # Return the handle so that 'new' can be used as an argument to a procedure
    #
    return $handle
}

proc deleteObject {objectType handle name element op} {
    #
    # Check that the object handle has a reasonable form
    #
    if {![regexp {_[0-9a-f]*_(.+)_p} $handle]} {
        error "deleteObject: not a valid object handle: $handle"
    }
    #
    # Remove the object procedure
    #
    catch {rename $handle {}}
    #
    # Delete the object
    #
    delete_$objectType $handle
}

proc delete {handle_r} {
    #
    # A synonym for unset that is more familiar to C++ programmers
    #
    uplevel unset $handle_r
}

```

To use this file, we simply source it and execute commands such as
"new" and "delete" to manipulate objects.  For example :

```swig

// list.i
%module List
%{
#include "list.h"
%}

// Very simple C++ example

class List {
public:
  List();  // Create a new list
  ~List(); // Destroy a list
  int  search(char *value);
  void insert(char *);  // Insert a new item into the list
  void remove(char *);  // Remove item from list
  char *get(int n);     // Get the nth item in the list
  int  length;          // The current length of the list
static void print(List *l);  // Print out the contents of the list
};

```

Now a Tcl script using the interface...

```swig

load ./list.so list       ; # Load the module
source swig_c++.tcl       ; # Source the object file

new List l
$l insert Dave
$l insert John
$l insert Guido
$l remove Dave
puts $l length_get

delete l

```

The cool thing about this example is that it works with any C++ object
wrapped by SWIG and requires no special compilation.  Proof that a
short, but clever Tcl script can be combined with SWIG to do many
interesting things.

## <a name="Tcl_nn46"></a> 39.10 Tcl/Tk Stubs

For background information about the Tcl Stubs feature, see
[https://www.tcl.tk/doc/howto/stubs.html](https://www.tcl.tk/doc/howto/stubs.html).

As of SWIG 1.3.10, the generated C/C++ wrapper will use the Tcl Stubs
feature if compiled with `-DUSE_TCL_STUBS`.

As of SWIG 1.3.40, the generated C/C++ wrapper will use the Tk Stubs
feature if compiled with `-DUSE_TK_STUBS`.

By default SWIG sets the minimum Tcl version to support to the 8.4
as that's the minimum Tcl version we aim to support (since SWIG 4.1.0; before
this SWIG set it to 8.1, which was the first Tcl version with the stubs
mechanism). This minimum version is passed to `Tcl_InitStubs()` and
`Tk_InitStubs()`. You can override with a specific version using
`-DSWIG_TCL_STUBS_VERSION="8.5"` or set it to the Tcl version being
compiled with using `-DSWIG_TCL_STUBS_VERSION=TCL_VERSION`.
