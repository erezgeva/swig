

# <a name="Warnings"></a> 21 Warning Messages

<!-- INDEX -->

<!-- INDEX -->

## <a name="Warnings_nn2"></a> 21.1 Introduction

During compilation, SWIG may generate a variety of warning messages.  For example:

```shell

example.i:16: Warning 501: Overloaded declaration ignored.  bar(double)
example.i:15: Warning 501: Previous declaration is bar(int)

```

Typically, warning messages indicate non-fatal problems with the input
where the generated wrapper code will probably compile, but it may not
work like you expect.

## <a name="Warnings_suppression"></a> 21.2 Warning message suppression

All warning messages have a numeric code that is shown in the warning message itself.
To suppress the printing of a warning message, a number of techniques can be used.
First, you can run SWIG with the `-w` command line option. For example:

```shell

% swig -python -w501 example.i
% swig -python -w501,505,401 example.i

```

Alternatively, warnings can be suppressed by inserting a special preprocessor pragma
into the input file:

```swig

%module example
#pragma SWIG nowarn=501
#pragma SWIG nowarn=501,505,401

```

Finally, code-generation warnings can be disabled on a declaration by declaration basis using
the `%warnfilter` directive.  For example:

```swig

%module example
%warnfilter(501) foo;
...
int foo(int);
int foo(double);              // Silently ignored.

```

The `%warnfilter` directive has the same semantics as other declaration modifiers like 
`%rename`, `%ignore` and `%feature`, see the 
[%feature directive](Customization/#Customization_features) section.  For example, if you wanted to
suppress a warning for a method in a class hierarchy, you could do this:

```swig

%warnfilter(501) Object::foo;
class Object {
public:
  int foo(int);
  int foo(double);      // Silently ignored
  ...
};

class Derived : public Object {
public:
  int foo(int);
  int foo(double);      // Silently ignored
  ...
};

```

Warnings can be suppressed for an entire class by supplying a class name.  For example:

```swig

%warnfilter(501) Object;

class Object {
public:
  ...                      // All 501 warnings ignored in class
};

```

There is no option to suppress all SWIG warning messages.  The warning messages are there
for a reason—to tell you that something may be *broken* in
your interface.  Ignore the warning messages at your own peril.

## <a name="Warnings_nn4"></a> 21.3 Enabling extra warnings

Some warning messages are disabled by default and are generated only
to provide additional diagnostics.  These warnings can be turned on using the
`-Wextra` option. For example:

```shell

% swig -Wextra -python example.i

```

Preprocessor warning 202 ("Could not evaluate expression *expr*.") was
formally off by default and enabled by `-Wextra`, but since SWIG 4.1.0
this warning is on by default because suppressing it tends to hide genuine
problems.  If you really don't want to see it, you can suppress it with
`-w202` or using `%warnfilter` as described below. Both will work
with older versions of SWIG too.

To selectively turn on extra warning messages, you can use the directives and options in the
previous section–simply add a "+" to all warning numbers.  For example:

```shell

% swig -w+309,+452 example.i

```

or in your interface file use either

```swig

#pragma SWIG nowarn=+309,+452

```

or

```swig

%warnfilter(+309,+452) foo;

```

Note: selective enabling of warnings with `%warnfilter` overrides any global settings you might have
made using `-w` or `#pragma`.

You can of course also enable all warnings and suppress a select few, for example:

```shell

% swig -Wextra -w309,452 example.i

```

The warnings on the right take precedence over the warnings on the left, so in the above example `-Wextra` adds numerous warnings including 452, but then `-w309,452` overrides this and so 452 is suppressed.

If you would like all warnings to appear, regardless of the warning filters used, then use the `-Wall` option.
The `-Wall` option also turns on the extra warnings that `-Wextra` adds, however, it is subtely different. 
When `-Wall` is used, it also disables all other warning filters, 
that is, any warnings suppressed or added in `%warnfilter`, `#pragma SWIG nowarn` 
or the `-w` option.

## <a name="Warnings_nn5"></a> 21.4 Issuing a warning message

Warning messages can be issued from an interface file using a number of directives.  The
`%warn` directive is the most simple:

```swig

%warn "900:This is your last warning!"

```

All warning messages are optionally prefixed by the warning number to use.  If you are generating
your own warnings, make sure you don't use numbers defined in the table at the end of this section.

The `%ignorewarn` directive is the same as `%ignore` except that it issues a
warning message whenever a matching declaration is found. For example:

```swig

%ignorewarn("362:operator= ignored") operator=;

```

Warning messages can be associated with typemaps using the
`warning` attribute of a typemap declaration. For example:

```swig

%typemap(in, warning="901:You are really going to regret this usage of $1_type $1_name") blah * {
  ...
}

```

In this case, the warning message will be printed whenever the typemap is actually used and the [special variables](Typemaps/#Typemaps_special_variables) will be expanded as appropriate, for example:

```shell

example.i:23: Warning 901: You are really going to regret this usage of blah * self
example.i:24: Warning 901: You are really going to regret this usage of blah * stuff

```

## <a name="Warnings_symbolic_symbols"></a> 21.5 Symbolic symbols

The `swigwarn.swg` file that is installed with SWIG contains symbol constants that could also be
used in `%warnfilter` and `#pragma SWIG nowarn`.
For example this file contains the following line:

```swig

%define SWIGWARN_TYPE_UNDEFINED_CLASS 401 %enddef

```

so `SWIGWARN_TYPE_UNDEFINED_CLASS` could be used instead of 401, for example:

```swig

#pragma SWIG nowarn=SWIGWARN_TYPE_UNDEFINED_CLASS

```

or

```swig

%warnfilter(SWIGWARN_TYPE_UNDEFINED_CLASS) Foo;

```

## <a name="Warnings_nn6"></a> 21.6 Commentary

The ability to suppress warning messages is really only provided for
advanced users and is not recommended in normal use.  You are advised
to modify your interface to fix the problems highlighted by the warnings
wherever possible instead of suppressing warnings.

Certain types of SWIG problems are errors.  These usually arise due to
parsing errors (bad syntax) or semantic problems for which there is
no obvious recovery.  There is no mechanism for suppressing error
messages.

## <a name="Warnings_nn7"></a> 21.7 Warnings as errors

Warnings can be handled as errors by using the `-Werror` command line
option. This will cause SWIG to exit with a non successful exit code if a
warning is encountered.

## <a name="Warnings_nn8"></a> 21.8 Message output format

The output format for both warnings and errors can be selected for
integration with your favourite IDE/editor. Editors and IDEs can usually parse 
error messages and if in the appropriate format will easily take you 
directly to the source of the error. The standard format is used by 
default except on Windows where the Microsoft format is used by default.
These can be overridden using command line options, for example:

```shell

$ swig -python -Fstandard example.i
example.i:4: Syntax error in input(1).
$ swig -python -Fmicrosoft example.i
example.i(4) : Syntax error in input(1).

```

## <a name="Warnings_nn9"></a> 21.9 Warning number reference

### <a name="Warnings_nn10"></a> 21.9.1 Deprecated features (100-199)

None currently.

### <a name="Warnings_nn11"></a> 21.9.2 Preprocessor (200-299)

- 201. Unable to find *filename*.
- 202. Could not evaluate expression *expr*.
- 203. Both includeall and importall are defined: using includeall.
- 204. CPP #warning, "*warning*".
- 205. CPP #error, "*error*".
- 206. Unexpected tokens after #*directive* directive.

### <a name="Warnings_nn12"></a> 21.9.3 C/C++ Parser (300-399)

- 301. `class` keyword used, but not in C++ mode.
- 302. Redefinition of identifier '*name*' as *decl* ignored.
- 303. `%extend` defined for an undeclared class '*name*'.
- 304. Unsupported constant value (ignored).
- 305. Bad constant value (ignored).
- 308. Namespace alias '*name*' not allowed here. Assuming '*name*'
- 309. [private | protected] inheritance ignored.
- 312. Unnamed nested class not currently supported (ignored).
- 313. Unrecognized extern type "*name*" (ignored).
- 314. '*identifier*' is a *lang* keyword.
- 315. Nothing known about '*identifier*'.
- 317. Specialization of non-template '*name*'.
- 318. Instantiation of template '*name*' is ambiguous, instantiation *templ* used, instantiation *templ* ignored.
- 319. No access specifier given for base class *name* (ignored).
- 320. Explicit template instantiation ignored.
- 321. *identifier* conflicts with a built-in name.
- 322. Redundant redeclaration of identifier '*name*' as *decl* ignored.
- 323. Recursive scope inheritance of '*name*'.
- 324. Named nested template instantiations not supported. Processing as if no name was given to %template().
- 325. Nested *kind* not currently supported (*name* ignored).
- 326. Deprecated %extend name used - the *kind* name '*name*' should be used instead of the typedef name '*name*'.
- 327. Extern template ignored.
- 328. Value assigned to *name* not used due to limited parsing implementation.
- 329. Using declaration '*name*' for inheriting constructors uses base '*name*' which is not an immediate base of '*name*'.
- 330. Template forward class '*name*' cannot be used to instantiate a full template class with name '*name*'.
- 331. Unsupported template nested class '*name*' cannot be used to instantiate a full template class with name '*name*'.
- 332. Reserved.
<!-- 332. In instantiation of template '<em>name</em>' with name '<em>name</em>', nothing known about type-constraint '<em>name</em>' - treated as 'typename'. -->
- 340. Lambda expressions and closures are not fully supported yet.
- 344. Unable to deduce decltype for '*expr*'.
- 345. Unable to deduce auto return type for '*name*' [without a trailing return type] (ignored).
- 346. Unable to deduce auto type for variable '*name*' from initialiser '*expr*' (ignored).
- 347. Unable to deduce class template arguments for variable '*name*' of type '*name*' (ignored).
- 348. Inconsistent auto type deduction for variable '*name*': initialiser '*expr*' deduces '*type*', not '*type*'.
- 349. Structured binding '*names*' is not supported (ignored).
- 350. operator new ignored.
- 351. operator delete ignored.
- 352. operator+ ignored.
- 353. operator- ignored.
- 354. operator* ignored.
- 355. operator/ ignored.
- 356. operator% ignored.
- 357. operator^ ignored.
- 358. operator& ignored.
- 359. operator| ignored.
- 360. operator~ ignored.
- 361. operator! ignored.
- 362. operator= ignored.
- 363. operator< ignored.
- 364. operator\> ignored.
- 365. operator+= ignored.
- 366. operator-= ignored.
- 367. operator*= ignored.
- 368. operator/= ignored.
- 369. operator%= ignored.
- 370. operator^= ignored.
- 371. operator&= ignored.
- 372. operator|= ignored.
- 373. operator<< ignored.
- 374. operator\>\>ignored.
- 375. operator<<= ignored.
- 376. operator\>\>= ignored.
- 377. operator== ignored.
- 378. operator!= ignored.
- 379. operator<= ignored.
- 380. operator\>= ignored.
- 381. operator&& ignored.
- 382. operator|| ignored.
- 383. operator++ ignored.
- 384. operator-- ignored.
- 385. operator, ignored.
- 386. operator-<* ignored.
- 387. operator-< ignored.
- 388. operator() ignored.
- 389. operator[] ignored.
- 390. operator+ ignored (unary).
- 391. operator- ignored (unary).
- 392. operator* ignored (unary).
- 393. operator& ignored (unary).
- 394. operator new[] ignored.
- 395. operator delete[] ignored.
- 396. operator*() ignored.

### <a name="Warnings_nn13"></a> 21.9.4 Types and typemaps (400-499) 

- 401. Nothing known about class 'name'. Ignored.
- 402. Base class 'name' is incomplete.
- 403. Class 'name' might be abstract.
- 404. Duplicate template instantiation of '*type*' with name '*name*' ignored, previous instantiation of '*type*' with name '*name*'.
- 405. Method with rvalue ref-qualifier *name* ignored.
- 406. Ignoring nspace setting (*setting*) for '*type*', as it conflicts with the nspace setting (*setting*) for outer class '*type*'
- 450. Reserved
- 451. Setting const char * variable may leak memory.
- 452. Reserved
- 453. Can't apply (pattern). No typemaps are defined.
- 454. Setting a pointer/reference variable may leak memory
- 455. Setting a const wchar_t * variable may leak memory.
- 460. Unable to use type *type* as a function argument.
- 461. Unable to use return type *type* in function *name*.
- 462. Unable to set variable of type *type*.
- 463. Unable to read variable of type *type*.
- 464. Unsupported constant value.
- 465. Unable to handle type *type*.
- 466. Unsupported variable type *type*.
- 467. Overloaded *declaration* not supported (incomplete type checking rule - no precedence level in typecheck typemap for '*type*')
- 468. No 'throw' typemap defined for exception type *type*
- 469. No or improper directorin typemap defined for *type*
- 470. Thread/reentrant unsafe wrapping, consider returning by value instead.
- 471. Unable to use return type *type* in director method
- 472. Overloaded method *method* with no explicit typecheck typemap for arg *number* of type '*type*'. Dispatching calls to this method may not work correctly, see the 'Typemaps and Overloading' section in the Typemaps chapter of the SWIG documentation.
- 473. Returning a reference, pointer or pointer wrapper in a director method is not recommended.
- 474. Method *method* usage of the optimal attribute ignored in the out typemap as the following cannot be used to generate optimal code: *code*
- 475. Multiple calls to *method* might be generated due to optimal attribute usage in the out typemap.
- 476. Initialization using std::initializer_list.
- 477. No directorthrows typemap defined for *type*
- 478. The argout typemaps for '*method*' append into different containers, '*container1*' and '*container2*', so the type of the values returned cannot be worked out and a catch-all type is used for the return type instead.
- 490. Fragment '*name*' not found.

### <a name="Warnings_nn14"></a> 21.9.5 Code generation (500-559)

- 501. Overloaded declaration ignored. *decl*. Previous declaration is *decl*.
- 502. Overloaded constructor ignored. *decl*. Previous declaration is *decl*.
- 503. Can't wrap '*identifier*' unless renamed to a valid identifier.
- 504. Function *name* must have a return type. Ignored.
- 505. Variable length arguments discarded.
- 506. Can't wrap varargs with keyword arguments enabled.
- 507. Adding native function *name* not supported (ignored).
- 508. Declaration of '*name*' shadows declaration accessible via operator-\>(), previous declaration of'*declaration*'.
- 509. Overloaded method *declaration* effectively ignored, as it is shadowed by *declaration*.
- 510. Friend function '*name*' ignored.
- 511. Can't use keyword arguments with overloaded functions.
- 512. Overloaded method *declaration* ignored, using non-const method *declaration* instead.
- 513. Can't generate wrappers for unnamed struct/class.
- 514.
- 515.
- 516. Overloaded method *declaration* ignored, using *declaration* instead.
- 517.
- 518. Portability warning: File *file1* will be overwritten by *file2* on case insensitive filesystems such as Windows' FAT32 and NTFS unless the class/module name is renamed.
- 519. %template() contains no name. Template method ignored: *declaration*
- 520. *Base/Derived* class '*classname1*' of '*classname2*' is not similarly marked as a smart pointer.
- 521. Illegal destructor name *name*. Ignored.
- 522. Use of an illegal constructor name '*name*' in %extend is deprecated, the constructor name should be '*name*'.
- 523. Use of an illegal destructor name '*name*' in %extend is deprecated, the destructor name should be '*name*'.
- 524. Experimental target language. Target language *language* specified by *lang* is an experimental language. See the 'Target Languages' section in the Introduction chapter of the SWIG documentation.
- 525. Destructor *declaration* is final, *name* cannot be a director class.
- 526. Using declaration *declaration*, with name '*name*', is not actually using the method from *declaration*, with name '*name*', as the names are different.
- 527. Deprecated target language. Target language *language* specified by *lang* is a deprecated language. It will be removed in the next release of SWIG unless a new maintainer steps forward to bring it up to at least experimental status. See the 'Target Languages' section in the Introduction chapter of the SWIG documentation.

### <a name="Warnings_doxygen"></a> 21.9.6 Doxygen comments (560-599)

- 560: Unknown Doxygen command: *command*.
- 561: Unexpected end of Doxygen comment encountered.
- 562: Expected Doxygen command: *command*
- 563: Doxygen HTML error for tag *tag*: *error text*.
- 564: Error parsing Doxygen command *command*: *error text*. Command ignored."

### <a name="Warnings_nn15"></a> 21.9.7 Language module specific (700-899) 

- 801. Wrong name (corrected to '*name*').  (Ruby).

- 810. No jni typemap defined for *type*  (Java).
- 811. No jtype typemap defined for *type*  (Java).
- 812. No jstype typemap defined for *type*  (Java).
- 813. Warning for *classname*, base *baseclass* ignored. Multiple inheritance is not supported in Java.   (Java).
- 814.
- 815. No javafinalize typemap defined for *type*  (Java).
- 816. No javabody typemap defined for *type*  (Java).
- 817. No javaout typemap defined for *type*  (Java).
- 818. No javain typemap defined for *type*  (Java).
- 819. No javadirectorin typemap defined for *type*  (Java).
- 820. No javadirectorout typemap defined for *type*  (Java).
- 821.
- 822. Covariant return types not supported in Java. Proxy method will return *basetype*  (Java).
- 823. No javaconstruct typemap defined for *type*  (Java).
- 824. Missing JNI descriptor in directorin typemap defined for *type* (Java).
- 825. "directorconnect" attribute missing in *type* "javaconstruct" typemap. (Java).
- 826. The nspace feature is used on '*type*' without -package. The generated code may not compile as Java does not support types declared in a named package accessing types declared in an unnamed package. (Java).

- 830. No ctype typemap defined for *type*  (C#).
- 831. No cstype typemap defined for *type*  (C#).
- 832. No cswtype typemap defined for *type*  (C#).
- 833. Warning for *classname*, base *baseclass* ignored. Multiple inheritance is not supported in C#.   (C#).
- 834.
- 835. No csfinalize typemap defined for *type*  (C#).
- 836. No csbody typemap defined for *type*  (C#).
- 837. No csout typemap defined for *type*  (C#).
- 838. No csin typemap defined for *type*  (C#).
- 839.
- 840.
- 841.
- 842. Covariant return types not supported in C#. Proxy method will return *basetype*  (C#).
- 843. No csconstruct typemap defined for *type*  (C#).
- 844. C# exception may not be thrown - no $excode or excode attribute in *typemap* typemap. (C#).
- 845. Unmanaged code contains a call to a SWIG_CSharpSetPendingException method and C# code does not handle pending exceptions via the canthrow attribute. (C#).

- 870. Warning for *classname*: Base *baseclass* ignored. Multiple inheritance is not supported in PHP.   (Php).
- 871. Unrecognized pragma *pragma*.   (Php).

### <a name="Warnings_nn16"></a> 21.9.8 User defined (900-999)

These numbers can be used by your own application.

## <a name="Warnings_nn17"></a> 21.10 History

The ability to control warning messages was first added to SWIG-1.3.12.
