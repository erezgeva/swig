/* -----------------------------------------------------------------------------
 * javascriptregstructurs.swg
 *
 * WebKit JavaScriptCore 6.0 GLib C-API
 * Structure for registration
 * ----------------------------------------------------------------------------- */

/* namespace functions and static methods */
typedef struct {
    const char *name;
    JSCValue* (*func)(GPtrArray*, gpointer);
} SWIG_JSC6_Functions;

/* properties of namespace and static properties */
typedef struct {
    const char *name;
    JSCValue* (*getter)(gpointer);
    void (*setter)(JSCValue*, gpointer);
} SWIG_JSC6_Properties;

/* Class methods */
typedef struct {
    const char *name;
    JSCValue* (*method)(void *_this, GPtrArray*, gpointer);
} SWIG_JSC6_Methods;

/* Class properties */
typedef struct {
    const char *name;
    JSCValue* (*getter)(void *_this, gpointer);
    void (*setter)(void *_this, JSCValue*, gpointer);
} SWIG_JSC6_Class_properties;

/* Class definition */
typedef struct {
   SWIG_JSC6_Functions *staticFunctions;
   SWIG_JSC6_Properties *staticValues;
   void *(*callAsConstructor)(GPtrArray *, gpointer);
} SWIG_JSC6_Class_def;

/* Class methods definition */
typedef struct {
   SWIG_JSC6_Methods *staticFunctions;
   SWIG_JSC6_Class_properties *staticValues;
   void (*finalize) (void *);
   JSCClass* parentClass;
} SWIG_JSC6_Object_def;

JSCException* SWIG_main_exception = NULL;
