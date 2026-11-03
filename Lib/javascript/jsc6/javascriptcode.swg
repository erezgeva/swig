/* -----------------------------------------------------------------------------
 * js_ctor:  template for wrapping a ctor.
 *   - $jswrapper:        wrapper of called ctor
 *   - $jslocals:         locals part of wrapper
 *   - $jscode:           code part of wrapper
 *   - $jsargcount:       number of arguments
 *   - $jsargrequired:    required number of arguments
 *   - $jsmangledtype:    mangled type of class
 * ----------------------------------------------------------------------------- */
%fragment ("js_ctor", "templates")
%{ /* TODO js_ctor */
static void* $jswrapper(GPtrArray *args, gpointer user_data)
{
  JSCContext *context = jsc_context_get_current();
  JSCException** exception = &SWIG_main_exception;
  int argc = args->len;
  $jslocals
  if (argc < $jsargrequired || argc > $jsargcount)
    SWIG_exception_fail(SWIG_ERROR, "Illegal number of arguments for $jswrapper.");

  $jscode
  return SWIG_JSC6_NewPointerObj(context, result, SWIGTYPE_$jsmangledtype, SWIG_POINTER_OWN);
 
  fail:
  return NULL;
}
%}

/* -----------------------------------------------------------------------------
 * js_veto_ctor: a vetoing ctor for abstract classes
 *   - $jswrapper:    name of wrapper
 *   - $jsname:       class name
 * ----------------------------------------------------------------------------- */
%fragment ("js_veto_ctor", "templates")
%{ /* TODO js_veto_ctor */
static /* JSCValue* */ void* $jswrapper(GPtrArray *args, gpointer user_data)
{
  JSCContext *context = jsc_context_get_current();
  JSCException** exception = &SWIG_main_exception;
  int argc = args->len;
  SWIG_exception(SWIG_ERROR, "Class $jsname can not be instantiated");

fail:
  return NULL;
}
%}

/* -----------------------------------------------------------------------------
 * js_ctor_dispatcher: dispatcher for overloaded constructors
 *   - $jswrapper:       name of wrapper
 *   - $jsname:          class name
 *   - $jsdispatchcases: part containing code for dispatching
 * ----------------------------------------------------------------------------- */
%fragment ("js_ctor_dispatcher", "templates")
%{ /* TODO js_ctor_dispatcher */
static void* $jswrapper(GPtrArray *args, gpointer user_data)
{
  JSCContext *context = jsc_context_get_current();
  JSCException** exception = &SWIG_main_exception;
  int argc = args->len;
  void* thisObject = NULL;

  // switch all cases by means of series of if-returns.
  $jsdispatchcases

  // default:
  SWIG_exception_fail(SWIG_ERROR, "Illegal arguments for construction of $jsname");

  fail:
  return thisObject;
}
%}

/* -----------------------------------------------------------------------------
 * js_overloaded_ctor: template for wrapping a ctor.
 *   - $jswrapper:     wrapper of called ctor
 *   - $jslocals:      locals part of wrapper
 *   - $jscode:        code part of wrapper
 *   - $jsargcount:    number of arguments
 *   - $jsargrequired: required number of arguments
 *   - $jsmangledtype: mangled type of class
 * ----------------------------------------------------------------------------- */
%fragment ("js_overloaded_ctor", "templates")
%{ /* TODO js_overloaded_ctor */
static void* $jswrapper(GPtrArray *args, gpointer user_data)
{
  JSCContext *context = jsc_context_get_current();
  JSCException** exception = &SWIG_main_exception;
  int argc = args->len;
  $jslocals
  $jscode
  return SWIG_JSC6_NewPointerObj(context, result, SWIGTYPE_$jsmangledtype, SWIG_POINTER_OWN);

  fail:
  return NULL;
}
%}

/* -----------------------------------------------------------------------------
 * js_ctor_dispatch_case:  template for a dispatch case for calling an overloaded ctor.
 *   - $jsargcount:       number of arguments of called ctor
 *   - $jsargrequired:    required number of arguments
 *   - $jswrapper:        wrapper of called ctor
 *
 *  Note: a try-catch-like mechanism is used to switch cases
 * ----------------------------------------------------------------------------- */
%fragment ("js_ctor_dispatch_case", "templates")
%{ /* TODO js_ctor_dispatch_case */
  if(argc >= $jsargrequired && argc <= $jsargcount) {
    thisObject = $jswrapper(args, user_data);
    /* reset exception and return */
    if(thisObject != NULL) {
      *exception = NULL;
      return thisObject;
    }
  }
%}

/* -----------------------------------------------------------------------------
 * js_dtor:  template for a destructor wrapper
 *   - $jsmangledname:  mangled class name
 *   - $jstype:         class type
 * ----------------------------------------------------------------------------- */
%fragment ("js_dtor", "templates")
%{ /* TODO js_dtor */
static void $jswrapper(JSCValue* thisObject)
{
  SwigPrivData* t = (SwigPrivData*) NULL; /* JSObjectGetPrivate(thisObject); TODO */
  if(t) {
    if (t->swigCMemOwn)
      free (($jstype)t->swigCObject);
    /* JSObjectSetPrivate(thisObject, NULL); TODO */
    free(t);
  }
}
%}

/* -----------------------------------------------------------------------------
 * js_dtor:  template for a destructor wrapper
 *   - $jsmangledname:  mangled class name
 *   - $jstype:         class type
 *   - ${destructor_action}: The custom destructor action to invoke.
 * ----------------------------------------------------------------------------- */
%fragment ("js_dtoroverride", "templates")
%{ /* TODO js_dtoroverride */
static void $jswrapper(void* _this)
{
  SwigPrivData* t = (SwigPrivData*)_this;
  if(t != NULL) {
    if (t->swigCMemOwn) {
      $jstype arg1 = ($jstype)t->swigCObject;
      ${destructor_action}
    }
    free(t);
  }
}
%}

/* -----------------------------------------------------------------------------
 * js_getter:  template for getter function wrappers
 *   - $jswrapper:  wrapper function name
 *   - $jslocals:   locals part of wrapper
 *   - $jscode:     code part of wrapper
 * ----------------------------------------------------------------------------- */
%fragment ("js_getter", "templates")
%{ /* TODO js_getter */
static JSCValue* $jswrapper(void *thisObject, gpointer user_data)
{
  JSCContext *context = jsc_context_get_current();
  JSCException** exception = &SWIG_main_exception;
  $jslocals
  JSCValue* jsresult;

  $jscode
  return jsresult;

  fail:
  return jsc_value_new_undefined(context);
}
%}

/* -----------------------------------------------------------------------------
 * js_setter:  template for setter function wrappers
 *   - $jswrapper:  wrapper function name
 *   - $jslocals:   locals part of wrapper
 *   - $jscode:     code part of wrapper
 * ----------------------------------------------------------------------------- */
%fragment ("js_setter", "templates")
%{ /* TODO js_setter */
static void $jswrapper(void *thisObject, JSCValue* value, gpointer user_data)
{
  JSCContext *context = jsc_context_get_current();
  JSCException** exception = &SWIG_main_exception;
  $jslocals
  $jscode

  fail:
}
%}


/* -----------------------------------------------------------------------------
 * js_global_getter:  template for getter function wrappers
 *   - $jswrapper:  wrapper function name
 *   - $jslocals:   locals part of wrapper
 *   - $jscode:     code part of wrapper
 * ----------------------------------------------------------------------------- */
%fragment ("js_global_getter", "templates")
%{ /* TODO js_global_getter */
static JSCValue* $jswrapper(gpointer user_data)
{
  JSCContext *context = jsc_context_get_current();
  JSCException** exception = &SWIG_main_exception;
  $jslocals
  JSCValue* jsresult;

  $jscode
  return jsresult;

  fail:
  return jsc_value_new_undefined(context);
}
%}

/* -----------------------------------------------------------------------------
 * js_global_setter:  template for setter function wrappers
 *   - $jswrapper:  wrapper function name
 *   - $jslocals:   locals part of wrapper
 *   - $jscode:     code part of wrapper
 * ----------------------------------------------------------------------------- */
%fragment ("js_global_setter", "templates")
%{ /* TODO js_global_setter */
static void $jswrapper(JSCValue* value, gpointer user_data)
{
  JSCContext *context = jsc_context_get_current();
  JSCException** exception = &SWIG_main_exception;
  $jslocals
  $jscode

  fail:
}
%}

/* -----------------------------------------------------------------------------
 * js_function:  template for function wrappers
 *   - $jswrapper:     wrapper function name
 *   - $jslocals:      locals part of wrapper
 *   - $jsargcount:    number of arguments
 *   - $jsargrequired: required number of arguments
 *   - $jscode:        code part of wrapper
 * ----------------------------------------------------------------------------- */
%fragment ("js_function", "templates")
%{ /* TODO js_function */
static JSCValue* $jswrapper(void *thisObject, GPtrArray *args, gpointer user_data)
{
  /* js_function */
  JSCContext *context = jsc_context_get_current();
  JSCException** exception = &SWIG_main_exception;
  int argc = args->len;
  $jslocals
  JSCValue* jsresult;

  if (argc < $jsargrequired || argc > $jsargcount)
    SWIG_exception_fail(SWIG_ERROR, "Illegal number of arguments for $jswrapper.");

  $jscode
  return jsresult;

  fail:
  return jsc_value_new_undefined(context);
}
%}

/* -----------------------------------------------------------------------------
 * js_global_function:  template for function wrappers
 *   - $jswrapper:     wrapper function name
 *   - $jslocals:      locals part of wrapper
 *   - $jsargcount:    number of arguments
 *   - $jsargrequired: required number of arguments
 *   - $jscode:        code part of wrapper
 * ----------------------------------------------------------------------------- */
%fragment ("js_global_function", "templates")
%{ /* TODO js_global_function */
static JSCValue* $jswrapper(GPtrArray *args, gpointer user_data)
{
  JSCContext *context = jsc_context_get_current();
  JSCException** exception = &SWIG_main_exception;
  int argc = args->len;
  $jslocals
  JSCValue* jsresult;

  if (argc < $jsargrequired || argc > $jsargcount)
    SWIG_exception_fail(SWIG_ERROR, "Illegal number of arguments for $jswrapper.");

  $jscode
  return jsresult;

  fail:
  return jsc_value_new_undefined(context);
}
%}

/* -----------------------------------------------------------------------------
 * js_function_dispatcher:  template for a function dispatcher for overloaded functions
 *   - $jswrapper:  wrapper function name
 *   - $jsname:     name of the wrapped function
 *   - $jslocals:   locals part of wrapper
 *   - $jscode:     code part of wrapper
 * ----------------------------------------------------------------------------- */
%fragment ("js_function_dispatcher", "templates")
%{ /* TODO js_function_dispatcher */
static JSCValue* $jswrapper(GPtrArray *args, gpointer user_data)
{
  JSCContext *context = jsc_context_get_current();
  JSCException** exception = &SWIG_main_exception;
  int argc = args->len;
  $jslocals
  JSCValue* jsresult;
  int res;
  $jscode

  SWIG_exception_fail(SWIG_ERROR, "Illegal arguments for function $jsname.");
  return jsresult;

  fail:
  return jsc_value_new_undefined(context);
}
%}

/* -----------------------------------------------------------------------------
 * js_overloaded_function:  template for a overloaded function
 *   - $jswrapper:     wrapper function name
 *   - $jslocals:      locals part of wrapper
 *   - $jsargcount:    required number of arguments
 *   - $jsargrequired: required number of arguments
 *   - $jscode:        code part of wrapper
 * ----------------------------------------------------------------------------- */
%fragment ("js_overloaded_function", "templates")
%{ /* TODO js_overloaded_function */
static int $jswrapper(JSCContext *context, int argc, GPtrArray *args,
  JSCException** exception,  JSCValue** p_result)
{
  JSCValue* jsresult = NULL;
  $jslocals

  if (argc < $jsargrequired || argc > $jsargcount)
    SWIG_exception_fail(SWIG_ERROR, "Illegal number of arguments for $jswrapper.");

  $jscode
  *p_result = jsresult;
  return SWIG_OK;

  fail:
  return SWIG_TypeError;
}
%}

/* -----------------------------------------------------------------------------
 * js_function_dispatch_case:  template for a case used in the function dispatcher
 *   - $jswrapper:     wrapper function name
 *   - $jsargcount:    number of arguments of overloaded function
 *   - $jsargrequired: required number of arguments
 *   - $jscode:        code part of wrapper
 * ----------------------------------------------------------------------------- */
%fragment ("js_function_dispatch_case", "templates")
%{ /* TODO js_function_dispatch_case */
  if(argc >= $jsargrequired && argc <= $jsargcount) {
    res = $jswrapper(context, argc, args, exception, &jsresult);
    if (res == SWIG_OK) {
      *exception = NULL;
      return jsresult;
    }
  }
%}

/* -----------------------------------------------------------------------------
 * js_check_arg:  template for checking if an argument exists
 *   - $jsarg: number of argument
 * ----------------------------------------------------------------------------- */
%fragment ("js_check_arg", "templates")
%{if(argc > $jsarg)%}

/* -----------------------------------------------------------------------------
 * jsc_variable_declaration:  template for a variable table entry
 *   - $jsname:       name of the variable
 *   - $jsgetter:     wrapper of getter function
 *   - $jssetter:     wrapper of setter function
 * ----------------------------------------------------------------------------- */
%fragment ("jsc_variable_declaration", "templates")
%{ /* TODO jsc_variable_declaration */
  {"$jsname", $jsgetter, $jssetter},
%}

/* -----------------------------------------------------------------------------
 * jsc_function_declaration:  template for a function table entry
 *   - $jsname:       name of the variable
 *   - $jswrapper:    wrapper function
 * ----------------------------------------------------------------------------- */
%fragment ("jsc_function_declaration", "templates")
%{ /* TODO jsc_function_declaration */
  {"$jsname", $jswrapper},
%}

/* -----------------------------------------------------------------------------
 * jsc_classtemplate_declaration:  template for a namespace declaration
 *   - $jsmangledname:      mangled class name
 * ----------------------------------------------------------------------------- */
%fragment ("jsc_class_declaration", "templates")
%{ /* TODO jsc_class_declaration */
static SWIG_JSC6_Class_def $jsmangledname_classDefinition;
static SWIG_JSC6_Object_def $jsmangledname_objectDefinition;
static JSCClass* $jsmangledname_classRef;
%}

/* -----------------------------------------------------------------------------
 * jsc_class_tables:  template for a namespace declaration
 *   - $jsmangledname:            mangled class name
 *   - $jsstaticclassvariables:   list of static variable entries
 *   - $jsstaticclassfunctions:   list of static function entries
 *   - $jsclassvariables:         list of member variable entries
 *   - $jsclassfunctions:         list of member function entries
 * ----------------------------------------------------------------------------- */
%fragment ("jsc_class_tables", "templates")
%{ /* TODO jsc_class_tables */
static SWIG_JSC6_Properties $jsmangledname_staticValues[] = {
  $jsstaticclassvariables
  { NULL, NULL, NULL }
};

static SWIG_JSC6_Functions $jsmangledname_staticFunctions[] = {
  $jsstaticclassfunctions
  { NULL, NULL }
};

static SWIG_JSC6_Class_properties $jsmangledname_values[] = {
  $jsclassvariables
  { NULL, NULL, NULL }
};

static SWIG_JSC6_Methods $jsmangledname_functions[] = {
  $jsclassfunctions
  { NULL, NULL }
};
%}

/* -----------------------------------------------------------------------------
 * jsc_define_class_template:  template for defining a class template
 *   - $jsmangledname:            mangled class name
 *   - $jsmangledtype:            mangled class type
 *   - $jsctor:                   wrapper of ctor
 *   - $jsbaseclass:              mangled name of base class
 * ----------------------------------------------------------------------------- */
%fragment ("jsc_class_definition", "templates")
%{ /* TODO jsc_class_definition */
  $jsmangledname_classDefinition.staticFunctions = $jsmangledname_staticFunctions;
  $jsmangledname_classDefinition.staticValues = $jsmangledname_staticValues;
  $jsmangledname_classDefinition.callAsConstructor = $jsctor;
  $jsmangledname_objectDefinition.finalize = $jsdtor;
  $jsmangledname_objectDefinition.staticValues = $jsmangledname_values;
  $jsmangledname_objectDefinition.staticFunctions = $jsmangledname_functions;
  $jsclass_inheritance
%}

%fragment ("jsc_class_inherit", templates)
%{ /* TODO jsc_class_inherit */
    if (SWIGTYPE_p$jsbaseclassmangled != NULL) {
      $jsmangledname_objectDefinition.parentClass = (JSCClass*)SWIGTYPE_p$jsbaseclassmangled->clientdata;
    }
%}

%fragment ("jsc_class_noinherit", templates)
%{ /* TODO jsc_class_inherit */
    $jsmangledname_objectDefinition.parentClass = _SwigObject_classRef;
%}

/* -----------------------------------------------------------------------------
 * jsc_register_class:  template for registration of a class
 *   - $jsname:                   class name
 *   - $jsmangledname:            mangled class name
 *   - $jsmangledtype:            mangled class type
 *   - $jsnspace:                 mangled name of namespace
 * ----------------------------------------------------------------------------- */
%fragment ("jsc_class_registration", "templates")
%{  /* TODO jsc_class_registration */
  $jsmangledname_classRef = swig_jsc6_create_class(context, $jsnspace_object,
  "$jsname", &$jsmangledname_classDefinition, &$jsmangledname_objectDefinition);
  SWIGTYPE_$jsmangledtype->clientdata = $jsmangledname_classRef;
%}

/* -----------------------------------------------------------------------------
 * jsc_nspace_declaration:  template for a namespace declaration
 *   - $jsnspace:           mangled name of the namespace
 *   - $jsglobalvariables:  list of variable entries
 *   - $jsglobalfunctions:  list of function entries
 * ----------------------------------------------------------------------------- */
%fragment ("jsc_nspace_declaration", "templates")
%{ /* TODO jsc_nspace_declaration */
static SWIG_JSC6_Properties $jsnspace_values[] = {
  $jsglobalvariables
  { NULL, NULL, NULL }
};

static SWIG_JSC6_Functions $jsnspace_functions[] = {
  $jsglobalfunctions
  { NULL, NULL }
};

static JSCValue* $jsmangledname_object;
%}

/* -----------------------------------------------------------------------------
 * jsc_nspace_definition:  template for definition of a namespace object
 *   - $jsmangledname:            mangled name of namespace
 * ----------------------------------------------------------------------------- */
%fragment ("jsc_nspace_definition", "templates")
%{ /* TODO jsc_nspace_definition */
  $jsmangledname_object = swig_jsc6_create_ns(context, $jsmangledname_functions, $jsmangledname_values);
%}

/* -----------------------------------------------------------------------------
 * jsc_nspace_registration:  template for registration of a namespace object
 *   - $jsname:                   name of namespace
 *   - $jsmangledname:            mangled name of namespace
 *   - $jsparent:                 mangled name of parent namespace
 * ----------------------------------------------------------------------------- */
%fragment ("jsc_nspace_registration", "templates")
%{ /* TODO jsc_nspace_registration */
  swig_jsc6_register_ns(context, $jsmangledname_object, $jsparent_object, "$jsname");
%}
