
/* ------------------------------------------------------------
 *  utility methods for Uint8Array
 * ------------------------------------------------------------ */

%fragment("SWIG_FromUint8Array", "header") {
%#define SWIG_FromUint8Array(valRef, cptr, psize, alloc) SWIG_ContextFromUint8Array(context, valRef, cptr, psize, alloc)
SWIGINTERN int
SWIG_ContextFromUint8Array(JSCContext* context, JSCValue* valRef, void** cptr, size_t* psize, int *alloc)
{
  if (alloc == NULL || psize == NULL || cptr == NULL)
    return SWIG_TypeError;
  *alloc = NULL;
  *cptr = NULL;
  *psize = NULL;
  if (JSValueGetTypedArrayType(context, valRef, NULL) == kJSTypedArrayTypeUint8Array) {
    JSObjectRef arr = valRef;
    size_t len = (size_t)SWIGJSC_ArrayLength(context, arr);
    if (len > 0) {
      size_t i;
      unsigned char *cbuf = %new_array(len, unsigned char);
      if (cbuf == NULL) {
        return SWIG_TypeError;
      }
      *alloc = SWIG_NEWOBJ;
      *cptr = (void*)cbuf;
      *psize = len;
      for (i = 0; i < len; i++) {
        JSCValue* val = jsc_value_object_get_property_at_index(arr, i);
        cbuf[i] = (unsigned char)jsc_value_to_double(val);
      }
    }
    return SWIG_OK;
  }
  return jsc_value_is_null(valRef) || jsc_value_is_undefined(valRef) ? SWIG_OK : SWIG_TypeError;
}
}

%fragment("SWIG_ToUint8Array", "header") {
%#define SWIG_ToUint8Array(buf, len) SWIG_ContextToUint8Array(context, buf, len)
SWIGINTERN JSCValue* SWIG_ContextToUint8Array(JSCContext* context, void* buf, size_t len)
{
  if (buf != NULL && len > 0) {
    size_t i;
    unsigned char* cbuf = (unsigned char*)buf;
    JSObjectRef arr = JSObjectMakeTypedArray(context, kJSTypedArrayTypeUint8Array, len, NULL);
    for (i = 0; i < len; i++) {
      JSCValue* val = jsc_value_new_number(context, cbuf[i]);
      jsc_value_object_set_property_at_index(arr, i, val);
    }
    return arr;
  }
  return jsc_value_new_undefined(context);
}
}
