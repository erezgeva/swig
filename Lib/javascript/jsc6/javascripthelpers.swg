%insert(wrapper) %{

/* -----------------------------------------------------------------------------
 * WebKit JavaScriptCore 6.0 GLib C-API
 * functions, properties, classes and methods registration
 * ----------------------------------------------------------------------------- */

SWIGINTERN JSCValue* swig_jsc6_create_ns(JSCContext *context,
  SWIG_JSC6_Functions* funcs, SWIG_JSC6_Properties* props) {
  SWIG_JSC6_Functions *curFunc = NULL;
  SWIG_JSC6_Properties *curVal = NULL;
  JSCValue *ns = jsc_value_new_object(context, NULL, NULL);
  if (ns == NULL)
    return NULL;

  /* Register functions */
  for(curFunc = funcs;
    curFunc != NULL && curFunc->name != NULL && curFunc->func != NULL; curFunc++) {
    JSCValue *fn = jsc_value_new_function_variadic(context, NULL,
      G_CALLBACK(curFunc->func), NULL, NULL, JSC_TYPE_VALUE);
    jsc_value_object_set_property(ns, curFunc->name, fn);
  }

  /* Register properties */
  for(curVal = props;
    curVal != NULL && curVal->name != NULL && curVal->getter != NULL; curVal++) {
    GCallback setter = NULL;
    if (curVal->setter != NULL)
      setter = G_CALLBACK(curVal->setter);
    jsc_value_object_define_property_accessor(ns, curVal->name,
      (JSCValuePropertyFlags)(JSC_VALUE_PROPERTY_CONFIGURABLE | JSC_VALUE_PROPERTY_ENUMERABLE),
      JSC_TYPE_VALUE, G_CALLBACK(curVal->getter), setter, NULL, NULL);
  }
  return ns;
}
SWIGINTERN void swig_jsc6_register_ns(JSCContext* context, JSCValue* namespaceObj,
        JSCValue* parentNamespace, const char* name)
{
    jsc_value_object_set_property(parentNamespace, name, namespaceObj);
}
SWIGINTERN JSCClass* swig_jsc6_create_class(JSCContext *context, JSCValue* ns,
  const char *name, SWIG_JSC6_Class_def *cDefs, SWIG_JSC6_Object_def *oDefs) {
  SWIG_JSC6_Class_properties *curProp = NULL;
  SWIG_JSC6_Methods *curMethod = NULL;
  SWIG_JSC6_Functions *curFunc = NULL;
  SWIG_JSC6_Properties *curVal = NULL;
  GCallback setter = NULL;
  JSCValue *ctor = NULL;

  /* Register class */
  JSCClass *cls = jsc_context_register_class(context, name, oDefs->parentClass, NULL,
          (GDestroyNotify)oDefs->finalize);
  if (cls == NULL)
    return NULL;

  /* Register constructor */
  if (cDefs != NULL && cDefs->callAsConstructor != NULL)
    ctor = jsc_class_add_constructor_variadic(cls, NULL,
      G_CALLBACK(cDefs->callAsConstructor), context, NULL, G_TYPE_POINTER);

  if (cDefs != NULL && ctor != NULL) {
    /* Register static methods */
    for(curFunc = cDefs->staticFunctions;
      curFunc != NULL && curFunc->name != NULL && curFunc->func != NULL; curFunc++) {
      JSCValue *fn = jsc_value_new_function_variadic(context, NULL,
        G_CALLBACK(curFunc->func), NULL, NULL, JSC_TYPE_VALUE);
      if (fn != NULL)
        jsc_value_object_set_property(ctor, curFunc->name, fn);
    }

    /* Register static properties */
    for(curVal = cDefs->staticValues;
      curVal != NULL && curVal->name != NULL && curVal->getter != NULL; curVal++) {
      setter = NULL;
      if (curVal->setter != NULL)
        setter = G_CALLBACK(curVal->setter);
      jsc_value_object_define_property_accessor(ctor, curVal->name,
        (JSCValuePropertyFlags)(JSC_VALUE_PROPERTY_CONFIGURABLE | JSC_VALUE_PROPERTY_ENUMERABLE),
        JSC_TYPE_VALUE, G_CALLBACK(curVal->getter), setter, NULL, NULL);
    }
  }

  /* Register methods */
  for(curMethod = oDefs->staticFunctions;
    curMethod != NULL && curMethod->name != NULL && curMethod->method != NULL; curMethod++)
    jsc_class_add_method_variadic(cls, curMethod->name, G_CALLBACK(curMethod->method),
      NULL, NULL, JSC_TYPE_VALUE);

  /* Register properties */
  for(curProp = oDefs->staticValues;
    curProp != NULL && curProp->name != NULL && curProp->getter != NULL; curProp++) {
    setter = NULL;
    if (curProp->setter != NULL)
      setter = G_CALLBACK(curProp->setter);
    jsc_class_add_property(cls, curProp->name,
      JSC_TYPE_VALUE, G_CALLBACK(curProp->getter), setter, NULL, NULL);
  }

  /* Add constructor to namespace */
  if (ctor != NULL) {
    if (ns != NULL && name != NULL)
      jsc_value_object_set_property(ns, name, ctor);
    g_object_unref(ctor);
  }

  return cls;
}
SWIGINTERN JSCClass* swig_jsc6_create_class_only(JSCContext *context, const char *name, SWIG_JSC6_Object_def *oDefs) {
  return swig_jsc6_create_class(context, NULL, name, NULL, &_SwigObject_objectDefinition);
}

SWIGINTERN JSCValue* JS_CharPtrToJSValue(JSCContext* context, const char* cstr) {
  return jsc_value_new_string(context, cstr);
}

%}
