

# <a name="Library"></a> 14 SWIG library

<!-- INDEX -->

<!-- INDEX -->

To help build extension modules, SWIG is packaged with a library of
support files that you can include in your own interfaces.  These
files often define new SWIG directives or provide utility
functions that can be used to access parts of the standard C and C++ libraries.
This chapter provides a reference to the current set of supported library files.

**Compatibility note:** Older versions of SWIG included a number of
library files for manipulating pointers, arrays, and other structures.  Most
these files are now deprecated and have been removed from the distribution.
Alternative libraries provide similar functionality.  Please read this chapter
carefully if you used the old libraries.

## <a name="Library_nn2"></a> 14.1 The %include directive and library search path

Library files are included using the `%include` directive.
When searching for files, directories are searched in the following order:

1. The current directory
1. Directories specified with the `-I` command line option
1. .`/swig_lib`
1. SWIG library install location as reported by `swig -swiglib`, for example `/usr/local/share/swig/1.3.30`
1. On Windows, a directory `Lib` relative to the location of `swig.exe` is also searched.

Within directories mentioned in points 3-5, SWIG first looks for a subdirectory
corresponding to a target language (e.g., `python`, `tcl`, etc.).
If found, SWIG will search the language specific directory first. This allows
for language-specific implementations of library files.

You can ignore the installed SWIG library by setting the `SWIG_LIB` environment variable.
Set the environment variable to hold an alternative library directory.

The directories that are searched are displayed when using `-verbose` commandline option.

## <a name="Library_nn3"></a> 14.2 C arrays and pointers

This section describes library modules for manipulating low-level C arrays and pointers.
The primary use of these modules is in supporting C declarations that manipulate bare
pointers such as `int *`, `double *`, or `void *`.  The modules can be
used to allocate memory, manufacture pointers, dereference memory, and wrap
pointers as class-like objects.   Since these functions provide direct access to
memory, their use is potentially unsafe and you should exercise caution.

### <a name="Library_argcargv"></a> 14.2.1 argcargv.i

The argcargv.i library is a simple library providing multi-argument typemaps for handling C
argc argv command line argument C string arrays.
The `argc` parameter contains the argument count and `argv` contains the argument vector array.

This library provides the following multi-argument typemap:

**`(int ARGC, char **ARGV)`**

Apply this multi-argument typemap to your use case, for example:

```swig

%apply (int ARGC, char **ARGV) { (size_t argc, const char **argv) }

int mainApp(size_t argc, const char **argv);

```

then from Ruby:

```

$args = ["myarg1", "myarg2"]
mainApp(args);

```

### <a name="Library_nn4"></a> 14.2.2 cpointer.i

The `cpointer.i` module defines macros that can be used
to generate wrappers around simple C pointers.  The primary use of
this module is in generating pointers to primitive datatypes such as
`int` and `double`.

**`%pointer_functions(type, name)`**

Generates a collection of four functions for manipulating a pointer `type *`:

`type *new_name()`

Creates a new object of type `type` and returns a pointer to it.  In C, the
object is created using `calloc()`. In C++, `new` is used.

`type *copy_name(type value)`

Creates a new object of type `type` and returns a pointer to it.
An initial value is set by copying it from `value`. In C, the
object is created using `calloc()`. In C++, `new` is used.

`type *delete_name(type *obj)`

Deletes an object type `type`.

`void name_assign(type *obj, type value)`

Assigns `*obj = value`.

`type name_value(type *obj)`

Returns the value of `*obj`.

When using this macro, `type` may be any type and `name` must be a legal identifier in the target
language.  `name` should not correspond to any other name used in the interface file.

Here is a simple example of using `%pointer_functions()`:

```swig

%module example
%include "cpointer.i"

/* Create some functions for working with "int *" */
%pointer_functions(int, intp);

/* A function that uses an "int *" */
void add(int x, int y, int *result);

```

Now, in Python:

```
>>> import example
>>> c = example.new_intp()     # Create an "int" for storing result
>>> example.add(3, 4, c)       # Call function
>>> example.intp_value(c)      # Dereference
7
>>> example.delete_intp(c)     # Delete

```

**`%pointer_class(type, name)`**

Wraps a pointer of `type *` inside a class-based interface.  This
interface is as follows:

```swig

struct name {
  name();                            // Create pointer object
  ~name();                           // Delete pointer object
  void assign(type value);           // Assign value
  type value();                      // Get value
  type *cast();                      // Cast the pointer to original type
  static name *frompointer(type *);  // Create class wrapper from existing
                                     // pointer
};

```

When using this macro, `type` is restricted to a simple type
name like `int`, `float`, or `Foo`.  Pointers and
other complicated types are not allowed.  `name` must be a
valid identifier not already in use.  When a pointer is wrapped as a class,
the "class"  may be transparently passed to any function that expects the pointer.

If the target language does not support proxy classes, the use of this macro will produce the example
same functions as `%pointer_functions()` macro.

It should be noted that the class interface does introduce a new object or wrap a pointer inside a special
structure.  Instead, the raw pointer is used directly.

Here is the same example using a class instead:

```swig

%module example
%include "cpointer.i"

/* Wrap a class interface around an "int *" */
%pointer_class(int, intp);

/* A function that uses an "int *" */
void add(int x, int y, int *result);

```

Now, in Python (using proxy classes)

```
>>> import example
>>> c = example.intp()         # Create an "int" for storing result
>>> example.add(3, 4, c)       # Call function
>>> c.value()                  # Dereference
7

```

Of the two macros, `%pointer_class` is probably the most convenient when working with simple
pointers.  This is because the pointers are access like objects and they can be easily garbage collected
(destruction of the pointer object destroys the underlying object).

**`%pointer_cast(type1, type2, name)`**

Creates a casting function that converts `type1` to `type2`.  The name of the function is `name`.
For example:

```swig

%pointer_cast(int *, unsigned int *, int_to_uint);

```

In this example,  the function `int_to_uint()` would be used to cast types in the target language.

**Note:** None of these macros can be used to safely work with strings (`char *` or `char **`).

**Note:** When working with simple pointers, typemaps can often be used to provide more seamless operation.

### <a name="Library_carrays"></a> 14.2.3 carrays.i

This module defines macros that assist in wrapping ordinary C pointers as arrays.
The module does not provide any safety or an extra layer of wrapping–it merely
provides functionality for creating, destroying, and modifying the contents of
raw C array data.

**`%array_functions(type, name)`**

Creates four functions.

`type *new_name(size_t nelements)`

Creates a new array of objects of type `type`.   In C, the array is allocated using
`calloc()`.  In C++, `new []` is used.

`type *delete_name(type *ary)`

Deletes an array. In C, `free()` is used.  In C++, `delete []` is used.

`type name_getitem(type *ary, size_t index)`

Returns the value `ary[index]`.

`void name_setitem(type *ary, size_t index, type value)`

Assigns `ary[index] = value`.

When using this macro, `type` may be any type and `name`
must be a legal identifier in the target language.  `name`
should not correspond to any other name used in the interface file.

Here is an example of `%array_functions()`.  Suppose you had a
function like this:

```swig

void print_array(double x[10]) {
  int i;
  for (i = 0; i < 10; i++) {
    printf("[%d] = %g\n", i, x[i]);
  }
}

```

To wrap it, you might write this:

```swig

%module example

%include "carrays.i"
%array_functions(double, doubleArray);

void print_array(double x[10]);

```

Now, in a scripting language, you might write this:

```

a = new_doubleArray(10)               # Create an array
for i in range(0, 10):
    doubleArray_setitem(a, i, 2 * i)  # Set a value
print_array(a)                        # Pass to C
delete_doubleArray(a)                 # Destroy array

```

**`%array_class(type, name)`**

Wraps a pointer of `type *` inside a class-based interface.  This
interface is as follows:

```swig

struct name {
  name(size_t nelements);               // Create an array
  ~name();                              // Delete array
  type getitem(size_t index);           // Return item
  void setitem(size_t index, type value);  // Set item
  type *cast();                         // Cast to original type
  static name *frompointer(type *);     // Create class wrapper from
                                        // existing pointer
};

```

When using this macro, `type` is restricted to a simple type
name like `int` or `float`. Pointers and
other complicated types are not allowed.  `name` must be a
valid identifier not already in use.  When a pointer is wrapped as a class,
it can be transparently passed to any function that expects the pointer.

When combined with proxy classes, the `%array_class()` macro can be especially useful.
For example:

```swig

%module example
%include "carrays.i"
%array_class(double, doubleArray);

void print_array(double x[10]);

```

Allows you to do this:

```

import example
c = example.doubleArray(10)  # Create double[10]
for i in range(0, 10):
    c[i] = 2 * i             # Assign values
example.print_array(c)       # Pass to C

```

**Note:** These macros do not encapsulate C arrays inside a special data structure
or proxy. There is no bounds checking or safety of any kind.   If you want this,
you should consider using a special array object rather than a bare pointer.

**Note:** `%array_functions()` and `%array_class()` should not be
used with types of `char` or `char *`.
SWIG's default handling of these types is to handle them as character strings and the two macros do not do enough to change this.

### <a name="Library_nn6"></a> 14.2.4 cmalloc.i

This module defines macros for wrapping the low-level C memory allocation functions
`malloc()`, `calloc()`, `realloc()`, and `free()`.

**`%malloc(type [, name=type])`**

Creates a wrapper around `malloc()` with the following prototype:

```swig
type *malloc_name(int nbytes = sizeof(type));

```

If `type` is `void`, then the size parameter `nbytes` is required.
The `name` parameter only needs to be specified when wrapping a type that
is not a valid identifier (e.g., "`int *`", "`double **`", etc.).

**`%calloc(type [, name=type])`**

Creates a wrapper around `calloc()` with the following prototype:

```swig
type *calloc_name(int nobj =1, int sz = sizeof(type));

```

If `type` is `void`, then the size parameter `sz` is required.

**`%realloc(type [, name=type])`**

Creates a wrapper around `realloc()` with the following prototype:

```swig
type *realloc_name(type *ptr, int nitems);

```

Note: unlike the C `realloc()`, the wrapper generated by this macro implicitly includes the
size of the corresponding type.   For example, `realloc_int(p, 100)` reallocates `p` so that
it holds 100 integers.

**`%free(type [, name=type])`**

Creates a wrapper around `free()` with the following prototype:

```swig

void free_name(type *ptr);

```

**`%sizeof(type [, name=type])`**

Creates the constant:

```swig

%constant int sizeof_name = sizeof(type);

```

**`%allocators(type [, name=type])`**

Generates wrappers for all five of the above operations.

Here is a simple example that illustrates the use of these macros:

```swig

// SWIG interface
%module example
%include "cmalloc.i"

%malloc(int);
%free(int);

%malloc(int *, intp);
%free(int *, intp);

%allocators(double);

```

Now, in a script:

```
>>> from example import *
>>> a = malloc_int()
>>> a
'_000efa70_p_int'
>>> free_int(a)
>>> b = malloc_intp()
>>> b
'_000efb20_p_p_int'
>>> free_intp(b)
>>> c = calloc_double(50)
>>> c
'_000fab98_p_double'
>>> c = realloc_double(100000)
>>> free_double(c)
>>> print sizeof_double
8
>>>
```

### <a name="Library_nn7"></a> 14.2.5 cdata.i

The `cdata.i` module defines functions for converting raw C data to and from a target language.

The following table describes the specific type per language:

| **Language** | **cdata type** | **mutability** | 
|---|---|---|
| Ruby | string | yes | 
| PHP | string | yes | 
| Guile | string | yes | 
| Lua | string | none | 
| Perl5 | string | none | 
| OCaml | string | none | 
| Octave | string | none | 
| Python | binary string | none | 
| C# | `byte[]` | yes | 
| Java | `byte[]` | yes | 
| D | `ubyte[]` | yes | 
| Go | `[]byte` | yes | 
| Javascript | `Uint8Array` | yes | 
| Scilab | list of `uint8` | yes | 
| Tcl | list of integers | yes | 

**Table:** cdata types

The primary applications of this module would be packing/unpacking of
binary data structures—for instance, if you needed to extract data from a buffer.

The available APIs are:

**`const char *cdata(void *ptr, size_t nbytes)`**

Converts `nbytes` of data at `ptr` into the target language type.   `ptr` can be any
pointer.

**`void memmove(void *ptr, const char *s)`**

This is actually a wrapper of the standard C library `memmove` function,
**`void *memmove(void *ptr, const void *src, size_t n)`**,
which copies `n` bytes of data from `src` into the destination pointed to by `ptr`.
Multi-argument typemaps are used so that the last two parameters, `src` and `n` are replaced by
`s`, a string or byte array target language type, mentioned earlier.
The string/byte array may contain embedded NULL bytes.
Unlike the C library function nothing is returned by the wrapper function.

One use of these functions is packing and unpacking data from memory.
Here is a short example:

```swig

// SWIG interface
%module example
%include "carrays.i"
%include "cdata.i"

%array_class(int, intArray);

```

Python example:

```
>>> a = intArray(10)
>>> for i in range(0, 10):
...    a[i] = i
>>> b = cdata(a, 40)
>>> b
b'\x00\x00\x00\x00\x00\x00\x00\x01\x00\x00\x00\x02\x00\x00\x00\x03\x00\x00\x00\x04
\x00\x00\x00\x05\x00\x00\x00\x06\x00\x00\x00\x07\x00\x00\x00\x08\x00\x00\x00\t'
>>> c = intArray(10)
>>> memmove(c, b)
>>> print c[4]
4
>>>
```

Since the size of data is not always known, the following macro is also defined:

**`%cdata(type [, name=type])`**

Generates the following function for extracting C data for a given type.

```swig

char *cdata_name(type* ptr, int nitems)

```

`nitems` is the number of items of the given type to extract.

**Note:** These functions provide direct access to memory and can be used to overwrite data.
Clearly they are unsafe.

## <a name="Library_nn8"></a> 14.3 C string handling

A common problem when working with C programs is dealing with
functions that manipulate raw character data using `char *`.
In part, problems arise because there are different interpretations of
`char *`—it could be a NULL-terminated string or it could
point to binary data.  Moreover, functions that manipulate raw strings
may mutate data, perform implicit memory allocations, or utilize
fixed-sized buffers.

The problems (and perils) of using `char *` are
well-known. However, SWIG is not in the business of enforcing
morality.  The modules in this section provide basic functionality
for manipulating raw C strings.

### <a name="Library_nn9"></a> 14.3.1 Default string handling

Suppose you have a C function with this prototype:

```swig

char *foo(char *s);

```

The default wrapping behavior for this function is to set `s`
to a raw `char *` that refers to the internal string data in the
target language.  In other words, if you were using a language like Tcl,
and you wrote this,

```

% foo Hello

```

then `s` would point to the representation of "Hello" inside
the Tcl interpreter.  When returning a `char *`, SWIG assumes
that it is a NULL-terminated string and makes a copy of it.  This
gives the target language its own copy of the result.

There are obvious problems with the default behavior.  First, since
a `char *` argument points to data inside the target language, it is
**NOT** safe for a function to modify this data (doing so may corrupt the
interpreter and lead to a crash).  Furthermore, the default behavior does
not work well with binary data. Instead, strings are assumed to be NULL-terminated.

### <a name="Library_nn10"></a> 14.3.2 Passing a string with length

If you have a function that expects string with a length,

```swig

size_t parity(char *str, size_t len, size_t initial);

```

you can wrap the parameters `(char *str, size_t len)` as a single
argument using a typemap.   Just do this:

```swig

%apply (char *STRING, size_t LENGTH) { (char *str, size_t len) };
...
size_t parity(char *str, size_t len, size_t initial);

```

Now, in the target language, you can use the string like this:

```
>>> s = "H\x00\x15eg\x09\x20"
>>> parity(s, 0)

```

In the wrapper function, the passed string will be expanded to a pointer and length parameter.
The `(char *STRING, int LENGTH)` multi-argument typemap is also available in addition to `(char *STRING, size_t LENGTH)`.

SWIG also supports passing these parameters but in reverse order, for example:

```swig

%apply (size_t LENGTH, char *STRING) { (size_t len, char *str) };
...
size_t parity(size_t len, char *str, size_t initial);

```

The usage from target language will be identical.
In the wrapper function, the supplied string will be expanded to a length parameter and pointer.

### <a name="Library_nn11"></a> 14.3.3 Using %newobject to release memory

If you have a function that allocates memory like this,

```swig

char *foo() {
  char *result = (char *) malloc(...);
  ...
  return result;
}

```

then the SWIG generated wrappers will have a memory leak–the returned data will be copied
into a string object and the old contents ignored.

To fix the memory leak, use the `%newobject` directive.

```swig

%newobject foo;
...
char *foo();

```

This will release the result if the appropriate target language support is available.
SWIG provides the appropriate "newfree" typemap for `char *` so that the memory is released,
however, you may need to provide your own "newfree" typemap for other types.
See [Object ownership and %newobject](Customization/#Customization_ownership) for more details.

### <a name="Library_nn12"></a> 14.3.4 cstring.i

The `cstring.i` library file provides a collection of macros
for dealing with functions that either mutate string arguments or
which try to output string data through their arguments.  An
example of such a function might be this rather questionable
implementation:

```swig

void get_path(char *s) {
  // Potential buffer overflow---uh, oh.
  sprintf(s, "%s/%s", base_directory, sub_directory);
}
...
// Somewhere else in the C program
{
  char path[1024];
  ...
  get_path(path);
  ...
}

```

(Off topic rant: If your program really has functions like this, you
would be well-advised to replace them with safer alternatives
involving bounds checking).

The macros defined in this module all expand to various combinations of
typemaps.  Therefore, the same pattern matching rules and ideas apply.

**%cstring_bounded_output(parm, maxsize)**

Turns parameter `parm` into an output value.  The
output string is assumed to be NULL-terminated and smaller than
`maxsize` characters.  Here is an example:

```swig

%cstring_bounded_output(char *path, 1024);
...
void get_path(char *path);

```

In the target language:

```
>>> get_path()
/home/beazley/packages/Foo/Bar
>>>
```

Internally, the wrapper function allocates a small buffer (on the stack) of the
requested size and passes it as the pointer value.  Data stored in the buffer is then
returned as a function return value.
If the function already returns a value, then the return value and the output string
are returned together (multiple return values).  **If more than`maxsize`
bytes are written, your program will crash with a buffer overflow!**

**%cstring_chunk_output(parm, chunksize)**

Turns parameter `parm` into an output value.  The
output string is always `chunksize` and may contain
binary data.  Here is an example:

```swig

%cstring_chunk_output(char *packet, PACKETSIZE);
...
void get_packet(char *packet);

```

In the target language:

```
>>> get_packet()
'\xa9Y:\xf6\xd7\xe1\x87\xdbH;y\x97\x7f\xd3\x99\x14V\xec\x06\xea\xa2\x88'
>>>
```

This macro is essentially identical to `%cstring_bounded_output`.  The
only difference is that the result is always `chunksize` characters.
Furthermore, the result can contain binary data.
**If more than`maxsize`
bytes are written, your program will crash with a buffer overflow!**

**%cstring_bounded_mutable(parm, maxsize)**

Turns parameter `parm` into a mutable string argument.
The input string is assumed to be NULL-terminated and smaller than
`maxsize` characters. The output string is also assumed
to be NULL-terminated and less than `maxsize` characters.

```swig

%cstring_bounded_mutable(char *ustr, 1024);
...
void make_upper(char *ustr);

```

In the target language:

```
>>> make_upper("hello world")
'HELLO WORLD'
>>>
```

Internally, this macro is almost exactly the same as
`%cstring_bounded_output`.  The only difference is that the
parameter accepts an input value that is used to initialize the
internal buffer. It is important to emphasize that this function
does not mutate the string value passed—instead it makes a copy of the
input value, mutates it, and returns it as a result.
**If more than`maxsize` bytes are
written, your program will crash with a buffer overflow!**

**%cstring_mutable(parm [, expansion])**

Turns parameter `parm` into a mutable string argument.
The input string is assumed to be NULL-terminated.  An optional
parameter `expansion` specifies the number of
extra characters by which the string might grow when it is modified.
The output string is assumed to be NULL-terminated and less than
the size of the input string plus any expansion characters.

```swig

%cstring_mutable(char *ustr);
...
void make_upper(char *ustr);

%cstring_mutable(char *hstr, HEADER_SIZE);
...
void attach_header(char *hstr);

```

In the target language:

```
>>> make_upper("hello world")
'HELLO WORLD'
>>> attach_header("Hello world")
'header: Hello world'
>>>
```

This macro differs from `%cstring_bounded_mutable()` in that a
buffer is dynamically allocated (on the heap using
`malloc/new`).  This buffer is always large enough to store a
copy of the input value plus any expansion bytes that might have been
requested.
It is important to emphasize that this function
does not directly mutate the string value passed—instead it makes a copy of the
input value, mutates it, and returns it as a result.
**If the function expands the result by more than`expansion` extra
bytes, then the program will crash with a buffer overflow!**

**%cstring_output_maxsize(parm, maxparm)**

This macro is used to handle bounded character output functions where
both a `char *` and a maximum length parameter are provided.
As input, a user simply supplies the maximum length.
The return value is assumed to be a NULL-terminated string.

```swig

%cstring_output_maxsize(char *path, int maxpath);
...
void get_path(char *path, int maxpath);

```

In the target language:

```
>>> get_path(1024)
'/home/beazley/Packages/Foo/Bar'
>>>
```

This macro provides a safer alternative for functions that need to
write string data into a buffer.  User supplied buffer size is
used to dynamically allocate memory on heap.  Results are placed
into that buffer and returned as a string object.

**%cstring_output_withsize(parm, maxparm)**

This macro is used to handle bounded character output functions where
both a `char *` and a pointer `int *` are passed.  Initially,
the `int *` parameter points to a value containing the maximum size.
On return, this value is assumed to contain the actual number of bytes.
As input, a user simply supplies the maximum length.  The output value is a
string that may contain binary data.

```swig

%cstring_output_withsize(char *data, int *maxdata);
...
void get_data(char *data, int *maxdata);

```

In the target language:

```
>>> get_data(1024)
'x627388912'
>>> get_data(1024)
'xyzzy'
>>>
```

This macro is a somewhat more powerful version of `%cstring_output_chunk()`.  Memory
is dynamically allocated and can be arbitrary large.  Furthermore, a function can control
how much data is actually returned by changing the value of the `maxparm` argument.

**%cstring_output_allocate(parm, release)**

This macro is used to return strings that are allocated within the program and
returned in a parameter of type `char **`.  For example:

```swig

void foo(char **s) {
  *s = (char *) malloc(64);
  sprintf(*s, "Hello world\n");
}

```

The returned string is assumed to be NULL-terminated.  `release`
specifies how the allocated memory is to be released (if applicable).  Here is an
example:

```swig

%cstring_output_allocate(char **s, free(*$1));
...
void foo(char **s);

```

In the target language:

```
>>> foo()
'Hello world\n'
>>>
```

**%cstring_output_allocate_size(parm, szparm, release)**

This macro is used to return strings that are allocated within the program and
returned in two parameters of type `char **` and `int *`.  For example:

```swig

void foo(char **s, int *sz) {
  *s = (char *) malloc(64);
  *sz = 64;
  // Write some binary data
  ...
}

```

The returned string may contain binary data. `release`
specifies how the allocated memory is to be released (if applicable).  Here is an
example:

```swig

%cstring_output_allocate_size(char **s, int *slen, free(*$1));
...
void foo(char **s, int *slen);

```

In the target language:

```
>>> foo()
'\xa9Y:\xf6\xd7\xe1\x87\xdbH;y\x97\x7f\xd3\x99\x14V\xec\x06\xea\xa2\x88'
>>>
```

This is the safest and most reliable way to return binary string data in
SWIG.  If you have functions that conform to another prototype, you might
consider wrapping them with a helper function.   For example, if you had this:

```swig

char  *get_data(int *len);

```

You could wrap it with a function like this:

```swig

void my_get_data(char **result, int *len) {
  *result = get_data(len);
}

```

**Comments:**

- Support for the `cstring.i` module depends on the target language. Not all
SWIG modules currently support this library.
- Reliable handling of raw C strings is a delicate topic.  There are many ways
to accomplish this in SWIG.  This library provides support for a few common techniques.
- If used in C++, this library uses `new` and `delete []` for memory
allocation.  If using C, the library uses `malloc()` and `free()`.
- Rather than manipulating `char *` directly, you might consider using a special string
structure or class instead.

## <a name="Library_c_standard_library"></a> 14.4 C standard library

### <a name="Library_complex"></a> 14.4.1 Complex floating types

SWIG has some support for complex floating types.  By default the keyword
`_Complex` is understood by the parser but `complex` is not
treated as a keyword because it may be used as an identifier.

SWIG is only able to fully wrap complex floating types for some target
languages.  If you are using such a target language for complex floating types,
you should include `complex.i` to enable this support:

```swig

%include "complex.i"

```

If SWIG is in C++ code this will actually include `std_complex.i`
for you; otherwise it will include `ccomplex.i`.

For target languages without support this will fail to find a file to
include.  In this case, if you are wrapping headers which use `complex`
then you'll need to add a define to your SWIG interface file to get SWIG to
parse the headers:

```swig

#define complex _Complex

```

Then if wrapping as opaque types is not useful to you, you can use
[`%ignore`](SWIG/#SWIG_ignore) to tell SWIG not to wrap
the functions and/or variables which use complex floating types.

## <a name="Library_stl_cpp_library"></a> 14.5 STL/C++ library

The library modules in this section provide access to parts of the standard C++ library including the STL.
SWIG support for the STL is an ongoing effort. Support is quite comprehensive for some language modules
but some of the lesser used modules do not have quite as much library code written.

The following table shows which C++ classes are supported and the equivalent SWIG interface library file for the C++ library.

| **C++ class** | **C++ Library file** | **SWIG Interface library file** | 
|---|---|---|
| std::array (C++11) | array | std_array.i | 
| std::auto_ptr | memory | std_auto_ptr.i | 
| std::complex | complex | std_complex.i | 
| std::deque | deque | std_deque.i | 
| std::list | list | std_list.i | 
| std::map | map | std_map.i | 
| std::multimap (C++11) | multimap | std_multimap.i | 
| std::multiset (C++11) | multiset | std_multiset.i | 
| std::pair | utility | std_pair.i | 
| std::set | set | std_set.i | 
| std::shared_ptr (C++11) | shared_ptr | std_shared_ptr.i | 
| std::string | string | std_string.i | 
| std::string_view (C++17) | string_view | std_string_view.i | 
| std::unordered_map (C++11) | unordered_map | std_unordered_map.i | 
| std::unordered_multimap (C++11) | unordered_multimap | std_unordered_multimap.i | 
| std::unordered_multiset (C++11) | unordered_multiset | std_unordered_multiset.i | 
| std::unordered_set (C++11) | unordered_set | std_unordered_set.i | 
| std::vector | vector | std_vector.i | 
| std::wstring | wstring | std_wstring.i | 

**Table:** SWIG C++ library files

The list is by no means complete; some language modules support a subset of the above and some support additional STL classes.
Please look for the library files in the appropriate language library directory.

### <a name="Library_std_string"></a> 14.5.1 std::string

The `std_string.i` library provides typemaps for converting C++ `std::string`
objects to and from strings in the target scripting language.  For example:

```swig

%module example
%include "std_string.i"

std::string foo();
void        bar(const std::string &x);

```

In the target language:

```

x = foo();                # Returns a string object
bar("Hello World");       # Pass string as std::string

```

A common problem that people encounter is that of classes/structures
containing a `std::string`. This can be overcome by defining a typemap.
For example:

```swig

%module example
%include "std_string.i"

%apply const std::string& {std::string* foo};

struct my_struct
{
  std::string foo;
};

```

In the target language:

```

x = my_struct();
x.foo = "Hello World";    # assign with string
print x.foo;              # print as string

```

This module only supports types `std::string` and
`const std::string&`.    Pointers and non-const references
are left unmodified and returned as SWIG pointers.

This library file is fully aware of C++ namespaces.  If you export `std::string` or rename
it with a typedef, make sure you include those declarations in your interface.  For example:

```swig

%module example
%include "std_string.i"

using namespace std;
typedef std::string String;
...
void foo(string s, const String &t);     // std_string typemaps still applied

```

### <a name="Library_std_string_view"></a> 14.5.2 std::string_view

The `std_string_view.i` library provides typemaps for converting C++17 `std::string_view`
objects to and from strings in the target scripting language.  For example:

```swig

%module example
%include "std_string_view.i"

std::string_view foo();
void        bar(std::string_view x);

```

In the target language:

```

x = foo();                # Returns a string object
bar("Hello World");       # Pass string as std::string_view

```

For target languages for which SWIG supports directors, `directorout`
typemaps are provided for `std::string_view`, but these require extra
care to use safely.  The issue is that returning `std::string_view`
effectively returns a pointer to string data but doesn't own the pointed to
data.  For target languages where there isn't a native narrow string
representation (e.g. C#, Java) a `static std::string` is used to cache
the data, which works but isn't thread/reentrant safe.  For target languages
where there is a native narrow string representation SWIG will return a
`std::string_view` pointing to that data, so you need to store the
string to return somewhere which will persist for the lifetime the caller
needs (e.g. put it in a member variable) - you can't return a temporary target
language string.  In both cases SWIG will issue a warning by default.

### <a name="Library_std_vector"></a> 14.5.3 std::vector

The `std_vector.i` library provides support for the C++ `std::vector` class in the STL.
Using this library involves the use of the `%template` directive.  All you need to do is to
instantiate different versions of `vector` for the types that you want to use.  For example:

```swig

%module example
%include "std_vector.i"

namespace std {
  %template(vectori) vector<int>;
  %template(vectord) vector<double>;
};

```

When a template `vector<X>` is instantiated a number of things happen:

- A class that exposes the C++ API is created in the target language .
This can be used to create objects, invoke methods, etc.  This class is
currently a subset of the real STL vector class.
- Input typemaps are defined for `vector<X>`, `const vector<X>&`, and
`const vector<X> *`.  For each of these, a pointer `vector<X> *` may be passed or
a native list object in the target language.
- An output typemap is defined for `vector<X>`.  In this case, the values in the
vector are expanded into a list object in the target language.
- For all other variations of the type, the wrappers expect to receive a `vector<X> *`
object in the usual manner.
- An exception handler for `std::out_of_range` is defined.
- Optionally, special methods for indexing, item retrieval, slicing, and element assignment
may be defined.  This depends on the target language.

To illustrate the use of this library, consider the following functions:

```swig

/* File : example.h */

#include <vector>
#include <algorithm>
#include <functional>
#include <numeric>

double average(std::vector<int> v) {
  return std::accumulate(v.begin(), v.end(), 0.0)/v.size();
}

std::vector<double> half(const std::vector<double>& v) {
  std::vector<double> w(v);
  for (unsigned int i=0; i<w.size(); i++)
    w[i] /= 2.0;
  return w;
}

void halve_in_place(std::vector<double>& v) {
  for (std::vector<double>::iterator it = v.begin(); it != v.end(); ++it)
    *it /= 2.0;
}

```

To wrap with SWIG, you might write the following:

```swig

%module example
%{
#include "example.h"
%}

%include "std_vector.i"
// Instantiate templates used by example
namespace std {
  %template(IntVector) vector<int>;
  %template(DoubleVector) vector<double>;
}

// Include the header file with above prototypes
%include "example.h"

```

Now, to illustrate the behavior in the scripting interpreter, consider this Python example:

```
>>> from example import *
>>> iv = IntVector(4)         # Create an vector<int>>>> for i in range(0, 4):
...      iv[i] = i
>>> average(iv)               # Call method
1.5
>>> average([0, 1, 2, 3])        # Call with list
1.5
>>> half([1, 2, 3])             # Half a list
(0.5, 1.0, 1.5)
>>> halve_in_place([1, 2, 3])   # Oops
Traceback (most recent call last):
  File "<stdin>", line 1, in ?
TypeError: Type error. Expected _p_std__vectorTdouble_t
>>> dv = DoubleVector(4)
>>> for i in range(0, 4):
...       dv[i] = i
>>> halve_in_place(dv)       # Ok
>>> for i in dv:
...       print i
...
0.0
0.5
1.0
1.5
>>> dv[20] = 4.5
Traceback (most recent call last):
  File "<stdin>", line 1, in ?
  File "example.py", line 81, in __setitem__
    def __setitem__(*args): return apply(examplec.DoubleVector___setitem__, args)
IndexError: vector index out of range
>>>
```

This library module is fully aware of C++ namespaces.  If you use vectors with other names,
make sure you include the appropriate `using` or typedef directives.  For example:

```swig

%include "std_vector.i"

namespace std {
  %template(IntVector) vector<int>;
}

using namespace std;
typedef std::vector Vector;

void foo(vector<int> *x, const Vector &x);

```

**Note:** This module makes use of several advanced SWIG features including templatized typemaps
and template partial specialization.  If you are trying to wrap other C++ code with templates, you
might look at the code contained in `std_vector.i`.  Alternatively, you can show them the code
if you want to make their head explode.

**Note:** This module is defined for all SWIG target languages.  However argument conversion
details and the public API exposed to the interpreter vary.

### <a name="Library_stl_exceptions"></a> 14.5.4 STL exceptions

Many of the STL wrapper functions add parameter checking and will throw a language dependent error/exception
should the values not be valid. The classic example is array bounds checking.
The library wrappers are written to throw a C++ exception in the case of error.
The C++ exception in turn gets converted into an appropriate error/exception for the target language.
By and large this handling should not need customising, however, customisation can easily be achieved by supplying appropriate "throws" typemaps.
For example:

```swig

%module example
%include "std_vector.i"
%typemap(throws) std::out_of_range {
  // custom exception handler
}
%template(VectInt) std::vector<int>;

```

The custom exception handler might, for example, log the exception then convert it into a specific error/exception for the target language.

When using the STL it is advisable to add in an exception handler to catch all STL exceptions.
The `%exception` directive can be used by placing the following code before any other methods or libraries to be wrapped:

```swig

%include "exception.i"

%exception {
  try {
    $action
  } catch (const std::exception& e) {
    SWIG_exception(SWIG_RuntimeError, e.what());
  }
}

```

Any thrown STL exceptions will then be gracefully handled instead of causing a crash.

### <a name="Library_std_shared_ptr"></a> 14.5.5 shared_ptr smart pointer

#### <a name="Library_shared_ptr_basics"></a> 14.5.5.1 shared_ptr basics

Some target languages have support for handling the shared_ptr reference counted smart pointer.
This smart pointer is available in the standard C++11 library as `std::shared_ptr`.
It was also in TR1 as `std::tr1::shared_ptr` before it was fully standardized.
Support for the widely used `boost::shared_ptr` is also available.

In order to use `std::shared_ptr`, the `std_shared_ptr.i` library file should be included:

```swig

%include <std_shared_ptr.i>
```

The pre-standard `std::tr1::shared_ptr` can be used by including the following macro before including the `std_shared_ptr.i` library file:

```swig

#define SWIG_SHARED_PTR_SUBNAMESPACE tr1
%include <std_shared_ptr.i>
```

In order to use `boost::shared_ptr`, the `boost_shared_ptr.i` library file should be included:

```swig

%include <boost_shared_ptr.i>
```

You can only use one of these variants of shared_ptr in your interface file at a time
(also SWIG doesn't currently support using both `%shared_ptr(T)` and
`%unique_ptr<T>` on the same type `T`).
All three variants must be used in conjunction with the `%shared_ptr(T)` macro,
where `T` is the underlying pointer type equating to usage `shared_ptr<T>`.
The type `T` must be non-primitive.
A simple example demonstrates usage:

```swig

%module example
%include <boost_shared_ptr.i>
%shared_ptr(IntValue)

%inline %{
#include <boost/shared_ptr.hpp>

struct IntValue {
  int value;
  IntValue(int v) : value(v) {}
};

static int extractValue(const IntValue &t) {
  return t.value;
}

static int extractValueSmart(boost::shared_ptr<IntValue> t) {
  return t->value;
}
%}

```

Note that the `%shared_ptr(IntValue)` declaration occurs after the inclusion of the `boost_shared_ptr.i`
library which provides the macro and, very importantly, before any usage or declaration of the type, `IntValue`.
The `%shared_ptr` macro provides, a few things for handling this smart pointer, but mostly a number of
typemaps. These typemaps override the default typemaps so that the underlying proxy class is stored and passed around
as a pointer to a `shared_ptr` instead of a plain pointer to the underlying type.
This approach means that any instantiation of the type can be passed to methods taking the type by value, reference, pointer
or as a smart pointer.
The interested reader might want to look at the generated code, however, usage is simple and no different
handling is required from the target language.
For example, a simple use case of the above code from Java would be:

```

IntValue iv = new IntValue(1234);
int val1 = example.extractValue(iv);
int val2 = example.extractValueSmart(iv);
System.out.println(val1 + " " + val2);

```

#### <a name="Library_shared_ptr_inheritance"></a> 14.5.5.2 shared_ptr and inheritance

The shared_ptr library works quite differently to SWIG's normal, but somewhat limited, 
[smart pointer handling](SWIGPlus/#SWIGPlus_smart_pointers).
The shared_ptr library does not generate extra wrappers, just for smart pointer handling, in addition to the proxy class.
The normal proxy class including inheritance relationships is generated as usual.
The only real change introduced by the `%shared_ptr` macro is that the proxy class stores a pointer to the shared_ptr instance instead of a raw pointer to the instance.
A proxy class derived from a base which is being wrapped with shared_ptr can and **must** be wrapped as a shared_ptr too.
In other words all classes in an inheritance hierarchy must all be used with the `%shared_ptr` macro.
For example the following code can be used with the base class shown earlier:

```swig

%shared_ptr(DerivedIntValue)
%inline %{
struct DerivedIntValue : IntValue {
  DerivedIntValue(int value) : IntValue(value) {}
  ...
};
%}

```

A shared_ptr of the derived class can now be passed to a method where the base is expected in the target language, just as it can in C++:

```

DerivedIntValue div = new DerivedIntValue(5678);
int val3 = example.extractValue(div);
int val4 = example.extractValueSmart(div);

```

If the `%shared_ptr` macro is omitted for any class in the inheritance hierarchy, SWIG will warn about this and the generated code may or may not result in a C++ compilation error.
For example, the following input:

```swig

%include "boost_shared_ptr.i"
%shared_ptr(Parent);

%inline %{
  #include <boost/shared_ptr.hpp>
  struct GrandParent {
    virtual ~GrandParent() {}
  };

  struct Parent : GrandParent {
    virtual ~Parent() {}
  };

  struct Child : Parent {
    virtual ~Child() {}
  };
%}

```

warns about the missing smart pointer information:

```shell

example.i:12: Warning 520: Base class 'GrandParent' of 'Parent' is not similarly marked as a smart pointer.
example.i:16: Warning 520: Derived class 'Child' of 'Parent' is not similarly marked as a smart pointer.

```

Adding the missing `%shared_ptr` macros will fix this:

```swig

%include <boost_shared_ptr.i>
%shared_ptr(GrandParent);
%shared_ptr(Parent);
%shared_ptr(Child);

... as before ...

```

#### <a name="Library_shared_ptr_overloading"></a> 14.5.5.3 shared_ptr and method overloading

A C++ compiler can disambiguate a method overloaded by a shared_ptr and one using the raw underlying type.
For example, either one of these methods can be called in C++:

```swig

int age(std::shared_ptr<GrandParent> num);
int age(GrandParent& num);

```

When wrapped by SWIG, disambiguation is not possible using the overloaded names as there is just one equivalent type (`GrandParent`) in the target language.
SWIG will choose to wrap just the first method by default.
[Ambiguity in overloading](SWIGPlus/#SWIGPlus_nn25) discusses ways to control which method(s) gets wrapped using `%ignore` or `%rename`.
For the interested reader, SWIG detects that they are equivalent types via the [typecheck typemaps](Typemaps/#Typemaps_typecheck_pointer) in the shared_ptr library.

#### <a name="Library_shared_ptr_templates"></a> 14.5.5.4 shared_ptr and templates

The `%shared_ptr` macro should be used for all the required instantiations
of the template before each of the `%template` instantiations.
For example, consider `number.h` containing the following illustrative template:

```swig

#include <memory>

template<int N> struct Number {
  int num;
  Number() : num(N) {}
  static std::shared_ptr<Number<N>> make() { return std::make_shared<Number<N>>(); }
};

```

The SWIG code below shows the required ordering:

```swig

%include <std_shared_ptr.i>

%shared_ptr(Number<10>);
%shared_ptr(Number<42>);

%{
  #include "number.h"
%}
%include "number.h"

%template(Number10) Number<10>;
%template(Number42) Number<42>;

```

#### <a name="Library_shared_ptr_directors"></a> 14.5.5.5 shared_ptr and directors

The languages that support shared_ptr also have support for using shared_ptr with directors.

### <a name="Library_std_unique_ptr"></a> 14.5.6 unique_ptr smart pointer

The `std_unique_ptr.i` library file provides SWIG's unique_ptr support.
It provides move semantics for the smart pointer's underlying object,
both from C++ to the target language and vice versa.

The library defines typemaps and a macro, `%unique_ptr(T)`, to use for handling
`std::unique_ptr<T>` for a type `T`.
The type `T` must be non-primitive.
This macro should be used before any code declaring or using type `T`.
Ordering requirements for using this smart pointer macro are the same as the
equivalent `%shared_ptr(T)` macro covered in the previous section.
The ownership and move semantics described here can of course be modified if not suitable
by copying and customising the typemaps in the appropriate `std_unique_ptr.i` library file.

Note that SWIG doesn't currently support using both `%shared_ptr(T)` and
`%unique_ptr<T>` on the same type `T`.

#### <a name="Library_std_unique_ptr_by_value"></a> 14.5.6.1 unique_ptr passed by value

Example usage of a `std::unique_ptr` being returned from a function by value is shown below.

```swig

%include <std_unique_ptr.i>

%unique_ptr(Klass)
%inline %{
#include <memory>
class Klass {
public:
  // Factory function creating objects of this class:
  static std::unique_ptr<Klass> Create(int value) {
    return std::unique_ptr<Klass>(new Klass(value));
  }

  int getValue() const { return m_value; }

private:
  Klass(int value) : m_value(value) {}
  int m_value;
};
%}

```

The returned objects can be used naturally from the target language, e.g. from
C#:

```

Klass k = Klass.Create(17);
int value = k.getValue();

```

The implementation simply calls `std::unique_ptr::release()` to obtain
the underlying raw pointer. The pointer is then used to create a target language
proxy class in the same way that SWIG handles a C++ function returning a class by value.
The target language proxy class then owns the memory pointed to by the raw pointer
and memory handling is identical to normal SWIG proxy class handling of the underlying C++ memory.
Note that an object returned by value is first copied/moved from the stack onto the heap in order to obtain
a raw pointer on the heap, whereas the underlying raw pointer in `std::unique_ptr` already points to an object on the heap.

Note that the implementation is quite different to the `std::shared_ptr` smart pointer,
where the proxy class manages the underlying C++ memory as a pointer to a shared_ptr instead of a plain raw pointer.

A possibly less common usage of this smart pointer is as a parameter to a function.
When used like this it indicates that memory usage of the object pointed to by the underlying pointer
is transferred to the function being called.
The code that SWIG generates assumes this happens.
First, it is assumed that a proxy class already owns the underlying C++ object and is used to pass the object to the C++ function being called.
Second, the ownership is transferred from the proxy class to the C++ function being called and
lifetime is then controlled by the function.
Finally, it is assumed the lifetime of the object may not last beyond returning from the C++ function
and hence the proxy class can no longer be used.

Consider expanding the example above with a function that takes a `std::unique_ptr` as follows:

```swig

void take(std::unique_ptr<Klass>);

```

and use from C#:

```

Klass k = Klass.Create(17); // create an instance of Klass any way you like
int value = k.getValue();   // ok
example.take(k);            // memory ownership passes from C# layer to C++ layer
int v = k.getValue();       // don't do this - invalid use of k

```

Attempts to use `k` after the ownership has been passed into the `take` function
should not be attempted.
The implementation sets the proxy class to an invalid state by setting the class's underlying
C++ pointer to null after the return from the `take` function.
Subsequent use of an invalid proxy class instance is very much dependent on the implementation
in the target language and ranges from a segfault to giving a nice error.
Consider implementing additional checks via the 'check' typemap.

Attempts to pass ownership from a proxy class to a `std::unique` parameter more than once will result
in a "Cannot release ownership as memory is not owned" exception. For example, if `example.take(k)` in the example above is called twice.

#### <a name="Library_std_unique_ptr_by_ref"></a> 14.5.6.2 unique_ptr passed by reference

The effect of passing a `std::unique_ptr` by rvalue reference into a function is identical to passing it by value.
The ownership of the memory of the object being pointed to by the underyling pointer is transferred from the proxy class to the C++ function being called. Example:

```swig

void grab(std::unique_ptr<Klass>&&);

```

Passing non-const lvalue references into a function is a bit quirky and not perfect due to ambiguities as
to what the function may do.
The approach taken is the ownership is transferred out of the target language from the proxy class
into C++ space and the proxy class can then no longer be used after the wrapped function returns.
In summary it works much like passing a `std::unique_ptr` by value into a function.
The assumption is the function will not modify the `std::unique_ptr`.
If this is not true and the underlying pointer is changed, such as calling the member functions, `swap`, `reset` or `release`, then the modified `std::unique_ptr` will effectively be ignored.
It is destroyed when the function exits C++ space on return to the target language.
Example:

```swig

void process(std::unique_ptr<Klass>&);

```

Passing const lvalue references into a function works much like passing any wrapped class.
The proxy class owning the underling C++ object continues to own the underying C++ object
after calling the function, the function cannot modify the `std::unique_ptr` or take ownership.
Example:

```swig

void use(const std::unique_ptr<Klass>&);

```

Move semantics are not provided when wrapping a C++ function that returns a `std::unique_ptr` by reference.
The target language proxy class wrapper that is returned does not own the underlying C++ object.
This applies to all reference types, such as:

```swig

std::unique_ptr<Klass>& LvalueRefReturn();
std::unique_ptr<Klass>&& RvalueRefReturn();

```

**Compatibility note:** Support for `std::unique_ptr` was first added in SWIG-4.1.0.
This initial support contained the move semantics when passing a `std::unique_ptr` around by value. Support for passing a `std::unique_ptr` around by reference was added in SWIG-4.3.0.

### <a name="Library_std_auto_ptr"></a> 14.5.7 auto_ptr smart pointer

While `std::auto_ptr` is deprecated in C++11, some existing code may
still be using it. SWIG provides support for this class which is nearly identical
to `std::unique_ptr`.

The `std_auto_ptr.i` library file provides SWIG's auto_ptr support.
It defines typemaps and a macro, `%auto_ptr(T)`, to use for handling
`std::auto_ptr<T>` for a type `T`.
The type `T` must be non-primitive.
This macro should be used before any code declaring or using type `T`.
Ordering requirements for using this smart pointer macro are the same as the
equivalent `%shared_ptr(T)` and `%unique_ptr` macros covered in
the previous two sections.

Example usage of a `std::auto_ptr` being returned from a function is shown below.

```swig

%include <std_auto_ptr.i>

%auto_ptr(Klass)
%inline %{
#include <memory>
class Klass {
public:
  // Factory function creating objects of this class:
  static std::auto_ptr<Klass> Create(int value) {
    return std::auto_ptr<Klass>(new Klass(value));
  }

  int getValue() const { return m_value; }

private:
  Klass(int value) : m_value(value) {}
  int m_value;
};
%}

```

The returned objects can be used naturally from the target language, e.g. from
C#:

```

Klass k = Klass.Create(17);
int value = k.getValue();

```

The implementation simply calls `std::auto_ptr::release()` to obtain the underlying raw pointer.
That is, it works the same way covered in the previous section for `std::unique_ptr`.

Input parameters also work the same way as `std::unique_ptr` covered in the previous section.

### <a name="Library_std_function"></a> 14.5.8 std::function

The `std_function.i` library file wraps the C++11 `std::function`
polymorphic function-object template. It exposes the partial specialisation
`std::function<RET(ARGS...)>` so that any C++ callable -
a free function, a lambda, a bound member function, or a functor (a class with
`operator()`) - can be returned from C++ to the target language
and invoked there.

Two conventions are baked into the library:

- `operator()` is renamed to `call` so that target languages
which cannot wrap `operator()` as an identifier still get a usable
method name.
- The default constructor is suppressed (`%ignore`d), so
`std::function` instances always originate on the C++ side -
typically returned from a factory function. They are not default-constructible
from the target language.

A typical use is a factory function that captures state in a lambda and
returns it as a `std::function`:

```swig

%include <std_string.i>
%include <std_function.i>

std::function<bool(int, const std::string &)> MakeLambda(int pass) {
  return [pass](int passcode, const std::string &name) -> bool {
    return passcode == pass && name == "magic";
  };
}

%template(MyLambda) std::function<bool(int, const std::string &)>;

```

One `%template` is required for each distinct
`RET(ARGS...)` signature being wrapped. From Java the wrapped
C++ lambda is invoked via the renamed `call` method:

```

MyLambda fn = MakeLambda(10);
boolean ok = fn.call(10, "magic");   // true
boolean no = fn.call(11, "magic");   // false

```

Similarly one can use the other functors defined in `<functional>`, such as `std::plus`:

```swig

%include <std_function.i>

std::function<int(int, int)> MakePlusFunctor() {
  return std::plus<int>();
}

%template(Plus) std::function<int(int, int)>;

```

Usage from Java:

```

Plus plus = MakePlusFunctor();
int sum = plus.call(3, 4); // returns 7

```

Limitations and notes:

- Only the function-typed partial specialisation is wrapped. A
`%template` instantiation with a non-function template argument falls
through to the empty primary template and produces no useful interface.
- The wrapper does not let target-language code construct a
`std::function` from a target-language callable. `std::function`
moves a C++ callable *out* to the target language; to go the other way,
see
[Pointers to functions and callbacks](SWIG/#SWIG_nn30)
or
[Callbacks to the target language](SWIGPlus/#SWIGPlus_target_language_callbacks).

**Compatibility note:** SWIG-4.5.0 is the first version to add
`std_function.i` so that
`std::function` can be usefully used.

## <a name="Library_nn16"></a> 14.6 Utility Libraries

### <a name="Library_nn17"></a> 14.6.1 exception.i

The `exception.i` library provides a language-independent function for raising a run-time
exception in the target language. This library is largely used by the SWIG library writers.
If possible, use the error handling scheme available to your target language as there is greater
flexibility in what errors/exceptions can be thrown.

**`SWIG_exception(int code, const char *message)`**

Raises an exception in the target language.  `code` is one of the following symbolic
constants:

```swig

SWIG_MemoryError
SWIG_IOError
SWIG_RuntimeError
SWIG_IndexError
SWIG_TypeError
SWIG_DivisionByZero
SWIG_OverflowError
SWIG_SyntaxError
SWIG_ValueError
SWIG_SystemError
SWIG_NullReferenceError

```

`message` is a string indicating more information about the problem.

The primary use of this module is in writing language-independent exception handlers.
For example:

```swig

%include "exception.i"
%exception std::vector::getitem {
  try {
    $action
  } catch (std::out_of_range& e) {
    SWIG_exception(SWIG_IndexError, const_cast<char*>(e.what()));
  }
}

```

### <a name="Library_attributes"></a> 14.6.2 attribute.i

The attribute library contains a set of macros to convert a pair of set/get methods
into a "native" attribute/property.

Use `%attribute` when you have a pair of get/set methods to a
primitive type like:

```swig

%include "attribute.i"
%attribute(A, int, a, get_a, set_a);

struct A {
  int get_a() const;
  void set_a(int aa);
};

```

and you want to provide that variable as an attribute in the target
language. This example only works for primitive types, not derived
types.
Now you can use the attributes like so (in Python):

```

x = A()
x.a = 3        # calls A::set_a(3)
print(x.a)     # calls A::get_a() const

```

If you don't provide a 'set' method, a 'read-only' attribute
is generated, ie, like:

```swig

%attribute(A, int, c, get_c);

```

Use `%attributeref` when you have const/non-const reference
access methods for primitive types or class/structs, like:

```swig

%attributeref(A, int, b);

struct A {
  const int & b() const;
  int & b();
};

%attributeref(B, int, c);

struct B {
  int & c();
};

```

Use the attributes like so (in Python):

```

x = A()
x.b = 3        # calls A::b()
print(x.b)     # calls A::b() const

```

You can also use

```swig

%attributeref(Class, AttributeType, AttributeName, AccessorMethod)

```

if the internal C++ reference methods have a different name from the
attribute you want, so

```swig

%attributeref(B, int, d, c);

```

is the same as the last example, but instead of the attribute 'c' being
called 'c', it is called 'd'.

Use `%attribute2` instead of `%attribute` to indicate
that reference-pointer translation is required.
Use `%attribute2` instead of `%attribute` in cases like
this:

```swig

%attribute2(MyClass, MyFoo, Foo, GetFoo, SetFoo);
%inline %{
  struct MyFoo {
    int x;
  };
  class MyClass {
    MyFoo foo;
  public:
    MyFoo & GetFoo() { return foo; }
    void SetFoo(const MyFoo &other) { foo = other; }
  };
%}

```

Here, the data type of the property is a wrapped type `MyFoo` and on
the C++ side it is passed by reference. The problem is that the SWIG
wrapper will pass around a pointer (MyFoo *) which is not compatible
with the reference type of the accessors (MyFoo &). Therefore, if you
use `%attribute`, you'll get an error from your C/C++
compiler. `%attribute2` translates between a pointer and a
reference to eliminate the error. In case you're confused, let's make
it simple: just use `%attribute` at first, but if the C/C++
compiler gives an error while compiling the wrapper,
try `%attribute2` instead.

NOTE: remember that if the type contains commas, such as
`std::pair<int, int>`, you need to use the macro like:

```swig

%attributeref(A, %arg(std::pair<int, int>), pval);

```

where `%arg()` 'normalizes' the type to be understood as a single
argument, otherwise the macro will get confused by the comma.

The `%attributeval` is the same as `%attribute`, but
should be used when the type is a class/struct (ie a non-primitive
type) and when the get and set methods return/pass by value. The
following is very similar to the above example, but note that the
access is by value rather than reference.

```swig

%attributeval(MyClassVal, MyFoo, ReadWriteFoo, GetFoo, SetFoo);
%attributeval(MyClassVal, MyFoo, ReadOnlyFoo, GetFoo);
%inline %{
  class MyClassVal {
    MyFoo foo;
  public:
    MyFoo GetFoo() { return foo; }
    void SetFoo(MyFoo other) { foo = other; }
  };
%}

```

The `%attributestring` is the same as `%attributeval`,
but should be used for string class types, which are unusual as they
are a class on the C++ side, but normally an immutable/primitive type
in the target language. Example usage for `std::string`:

```swig

%include <std_string.i>
%attributestring(MyStringyClass, std::string, ReadWriteString, GetString, SetString);
%attributestring(MyStringyClass, std::string, ReadOnlyString, GetString);
%inline %{
  class MyStringyClass {
    std::string str;
  public:
    MyStringyClass(const std::string &val) : str(val) {}
    std::string GetString() { return str; }
    void SetString(std::string other) { str = other; }
  };
%}

```

The `%attributestring` also works for class types that
have `%naturalvar` turned on and so is also useful for
shared_ptr which has `%naturalvar` turned on in
`%shared_ptr`.

#### <a name="Library_attribute_templates"></a> 14.6.2.1 %attribute and C++ templates

`%attribute` and friends have to be used on fully specified classes. For example

```swig

%attributeref(A<int>, int, a);
%inline %{
  template <class T> struct A {
    T a() const;
    void a(T &);
  };
%}

```

Note the use of a template-id (i.e., `A<int>` not `A<T>` or just `A`).
This means that `%attribute` statements have to be repeated for any template-id that you want to use with `%template`.
