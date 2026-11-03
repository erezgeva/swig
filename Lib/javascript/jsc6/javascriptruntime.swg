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

/* All methods use the same prototype! */
typedef struct {
    const char *name;
    JSCValue* (*func)(void *, GPtrArray*, gpointer);
} SWIG_JSC6_Functions;

typedef struct {
    const char *name;
    GType type;
    JSCValue* (*getter)(void *obj, gpointer);
    void (*setter)(void *obj, JSCValue*, gpointer);
} SWIG_JSC6_Properties;
%}

%insert(runtime) "swigrun.swg";       /* SWIG API */

%insert(runtime) "javascriptrun.swg"; /* SWIG errors */
