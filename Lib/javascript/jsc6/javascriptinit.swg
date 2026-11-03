%insert(init) %{
SWIGRUNTIME bool SWIG_JSC6_SetModule(JSCContext* context, swig_module_info* swig_module) {
  JSCValue* globalObject = NULL;
  JSCValue* val = NULL;

  if (context == NULL || swig_module == NULL)
    return false;

  globalObject = jsc_context_get_global_object(context);
  if (globalObject == NULL)
    return false;

  val = jsc_value_new_number(context, (double)(guintptr)swig_module);
  jsc_value_object_define_property_data(globalObject, "swig_module_info_data",
    (JSCValuePropertyFlags)0, val);
  g_object_unref(val);
  return true;
}
SWIGRUNTIME swig_module_info* SWIG_JSC6_GetModule(JSCContext* context) {
  JSCValue* globalObject = NULL;
  JSCValue* val = NULL;
  swig_module_info* ret = NULL;

  if(context == NULL)
      return NULL;

  globalObject = jsc_context_get_global_object(context);
  if (globalObject == NULL)
    return NULL;

  val = jsc_value_object_get_property(globalObject, "swig_module_info_data");
  if (val == NULL)
    return NULL;
  if (jsc_value_is_number(val)) {
    double d = jsc_value_to_double(val);
    ret = (swig_module_info*)(guintptr)d;
  }
  g_object_unref(val);
  return ret;
}

#define SWIG_GetModule(clientdata)                SWIG_JSC6_GetModule(clientdata)
#define SWIG_SetModule(clientdata, pointer)       SWIG_JSC6_SetModule(clientdata, pointer)
#define SWIG_INIT_CLIENT_DATA_TYPE                JSCContext*
%}

%insert(init) "swiginit.swg"

%fragment ("js_initializer_define", "templates") %{ /* TODO js_initializer_define */
#define SWIGJSC_INIT $jsname_initialize
%}

// Open the initializer function
%insert(init)
%{

#ifdef __cplusplus
extern "C" {
#endif

bool SWIGJSC_INIT (JSCContext* context, JSCValue** exports) {
    SWIG_InitializeModule(context);
%}

/* -----------------------------------------------------------------------------
 * js_initializer: template for the module initializer function
 *   - $jsname:                   module name
 *   - $jscreatenamespaces:       part with code for creating namespace objects
 *   - $jscreateclasses:          part with code for creating classes
 *   - $jsregisternamespaces:     part with code for registration of namespaces
 * ----------------------------------------------------------------------------- */
%fragment ("js_initializer", "templates") %{ /* TODO js_initializer */

    /* Create objects for namespaces */
    $jscreatenamespaces

    /* Initialize the base swig type object */
    _SwigObject_objectDefinition.staticFunctions = _SwigObject_functions;
    _SwigObject_objectDefinition.staticValues = _SwigObject_values;
    _SwigObject_classRef = swig_jsc6_create_class_only(context, "SwigObject",
      &_SwigObject_objectDefinition);

    /* Initialize the PackedData class */
    _SwigPackedData_objectDefinition.staticFunctions = _SwigPackedData_functions;
    _SwigPackedData_objectDefinition.staticValues = _SwigPackedData_values;
    _SwigPackedData_objectDefinition.finalize = _wrap_SwigPackedData_delete;
    _SwigPackedData_classRef = swig_jsc6_create_class_only(context, "SwigPackedData",
      &_SwigPackedData_objectDefinition);

    /* Register classes */
    $jsregisterclasses

    /* Register namespaces */
    $jsregisternamespaces

    *exports = exports_object;

    return true;
}
#ifdef __cplusplus
}
#endif
%}
