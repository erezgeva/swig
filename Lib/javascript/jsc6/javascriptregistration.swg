/* -----------------------------------------------------------------------------
 * javascriptregistration.swg
 *
 * WebKit JavaScriptCore 6.0 GLib C-API
 * functions, properties, classes and methods registration
 * ----------------------------------------------------------------------------- */

JSCValue* swig_jsc6_register_ns(JSCContext *context, const char *name) {
    JSCValue *ns = jsc_value_new_object(context, NULL, NULL);
    if (ns == NULL)
        return NULL;
    jsc_context_set_value(context, name, ns);
    return ns;
}

int swig_jsc6_register_class(JSCContext *context, JSCValue* ns, swig_type_info *info,
    const char *name, SWIG_JSC6_Class_def *cDefs, SWIG_JSC6_Object_def *oDefs) {
    JSCValue *ctor = NULL;
    SWIG_JSC6_Functions *curFunc = NULL;
    SWIG_JSC6_Properties *curVal = NULL;
    SWIG_JSC6_Methods *curMethod = NULL;
    SWIG_JSC6_Class_properties *curProp = NULL;

    /* Register class */
    JSCClass *cls = jsc_context_register_class(context, name, oDefs.parentClass, NULL,
            (GDestroyNotify)oDefs.finalize);
    if (cls == NULL)
        return SWIG_ERROR;

    /* Register constructor */
    ctor = jsc_class_add_constructor_variadic(cls, NULL,
        G_CALLBACK(cDefs.callAsConstructor), context, NULL, G_TYPE_POINTER);

    /* Register static methods */
    for(curFunc = cDefs.staticFunctions;
        curFunc != NULL && curFunc->name != NULL && curFunc->func != NULL; curFunc++) {
        JSCValue *fn = jsc_value_new_function_variadic(context, NULL,
            G_CALLBACK(curFunc->func), NULL, NULL, JSC_TYPE_VALUE);
        jsc_value_object_set_property(ctor, curFunc->name, fn);
    }

    /* Register static properties */
    for(curVal = cDefs.staticValues;
        curVal != NULL && curVal->name != NULL && curVal->getter != NULL; curVal++) {
        GCallback setter = NULL;
        if (curVal->setter != NULL)
            setter = G_CALLBACK(curVal->setter);
        jsc_value_object_define_property_accessor(ctor, curVal->name,
            JSC_VALUE_PROPERTY_CONFIGURABLE | JSC_VALUE_PROPERTY_ENUMERABLE,
            JSC_TYPE_VALUE, G_CALLBACK(curVal->getter), setter, NULL, NULL);
    }


    /* Register methods */
    for(curMethod = pDefs.staticFunctions;
        curMethod != NULL && curMethod->name != NULL && curMethod->method != NULL; curMethod++)
        jsc_class_add_method_variadic(cls, curmethod->name, G_CALLBACK(curMethod->method),
            NULL, NULL, JSC_TYPE_VALUE);


    /* Register properties */



    /* Add constructor to namespace */
    jsc_value_object_set_property(ns, name, ctor);
    g_object_unref(ctor);

    /* Assign clientdata to class */
    info->->clientdata = cls;
    return SWIG_OK;
}
