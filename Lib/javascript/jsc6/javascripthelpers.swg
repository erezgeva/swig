%insert(wrapper) %{

SWIGINTERN bool JS_registerClass(JSCContext* context, JSCValue* parentObject,
                             const char* className,
                             JSClassDefinition* definition) {

    JSCValue* classObject = JSObjectMake(context, JSClassCreate(definition), NULL);
    jsc_value_object_set_property(parentObject, className, classObject);

    return true;
}

SWIGINTERN bool JS_registerNamespace(JSCContext* context,
                           JSCValue* namespaceObj, JSCValue* parentNamespace,
                           const char* name)
{
    jsc_value_object_set_property(parentNamespace, name, namespaceObj);

    return true;
}

SWIGINTERN bool JS_registerFunction(JSCContext* context, JSCValue* object,
                        const char* functionName, JSObjectCallAsFunctionCallback callback)
{
    JSObjectSetProperty(context, object, functionName, JSObjectMakeFunctionWithCallback(context, functionName, callback), NULL);
    return true;
}

SWIGINTERN bool JS_veto_set_variable(JSCContext* context, JSCValue* thisObject, const char *propertyName, JSCValue* value, JSCValue** exception)
{
    char msg[1024];

    int res = SWIG_snprintf(msg, sizeof(msg), "Tried to write read-only variable: %s.",propertyName);

    if(res<0)
      SWIG_exception(SWIG_ERROR, "Tried to write read-only variable.");
    else
      SWIG_exception(SWIG_ERROR, msg);
fail:
    return false;
}

SWIGINTERN JSCValue* JS_CharPtrToJSValue(JSCContext* context, const char* cstr) {
  return jsc_value_new_string(context, cstr);
}
%}
