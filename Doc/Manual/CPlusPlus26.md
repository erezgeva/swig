

# <a name="CPlusPlus26"></a> 12 SWIG and C++26

<!-- INDEX -->

<!-- INDEX -->

## <a name="CPlusPlus26_introduction"></a> 12.1 Introduction

This chapter gives you a brief overview about the SWIG implementation of
the C++26 standard.  C++26 is still a draft standard and SWIG does not
enable it yet: `-std=c++26` is not accepted on the SWIG command
line and the C++26 test cases are not run as part of a normal test suite
run.

The `-std` option only sets the value of `__cplusplus` and
does not gate the grammar, so the C++26 constructs listed below are parsed
whichever standard is selected.  If you are wrapping a header that checks
`__cplusplus` against the value the compilers currently use for
C++26, define the macro at the top of your interface file:

```swig

#undef __cplusplus
#define __cplusplus 202400L

```

See
[Conditional Compilation](Preprocessor/#Preprocessor_condition_compilation)
in the preprocessor chapter for more on the standard macros SWIG defines.

## <a name="CPlusPlus26_core_language_changes"></a> 12.2 Core language changes

### <a name="CPlusPlus26_deleted_function_reason"></a> 12.2.1 Reason for a deleted function

C++26 allows a deleted function to carry an explanatory message, which a
compiler quotes in the error message it emits when an attempt is made to use
the function:

```swig

void oldFreeFunction() = delete("use freeFunction() instead");

struct Widget {
  Widget() = default;
  Widget(const Widget &) = delete("Widget is not copyable");
};

```

SWIG parses the reason and discards it, as the message is diagnostic only.
A function declared this way behaves exactly like one declared with a plain
`= delete`, so it is not wrapped.

**Compatibility note:** SWIG-4.6.0 is the first version to parse the
reason on a deleted function.

## <a name="CPlusPlus26_standard_library_changes"></a> 12.3 Standard library changes

The SWIG library does not yet wrap any of the containers and types added
to the standard library by C++26.
