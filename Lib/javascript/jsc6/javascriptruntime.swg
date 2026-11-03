/* -----------------------------------------------------------------------------
 * javascriptruntime.swg
 *
 * Javascript support code
 * ----------------------------------------------------------------------------- */

%insert(runtime) %{
#include <jsc/jsc.h>
#include <stdio.h>
#include <stdlib.h>
#include <string.h>
#include <limits.h>
#include <assert.h>
#if !defined __cplusplus && (!defined __STDC_VERSION__ || __STDC_VERSION__ < 202311L)
#include <stdbool.h>
#endif
%}

%insert(runtime) "swigrun.swg";       /* SWIG API */

/* SWIG structures for registration */
%insert(runtime) "javascriptregstructurs.swg";

%insert(runtime) "javascriptrun.swg"; /* SWIG errors */
