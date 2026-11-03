/* ----------------------------------------------------------------------------
 *  Errors and exceptions
 *
 * ---------------------------------------------------------------------------*/

#define SWIG_Error(code, msg)     SWIG_JSC_exception(context, exception, code, msg)
#define SWIG_fail                 goto fail

SWIGRUNTIME void SWIG_Javascript_Raise_ValueRef(JSCContext* context, JSCException** exception, JSCValue* value) {
  JSCException *exc;
  char *msg = jsc_value_to_string(value);
  exc = jsc_exception_new(context, msg);
  g_free(msg);

  if (exception != NULL)
    *exception = exc;
  jsc_context_throw_exception(context, exc);
}
SWIGRUNTIME void SWIG_Javascript_Raise(JSCContext* context, JSCException** exception, const char* msg) {
  JSCException *exc = jsc_exception_new(context, msg);
  if (exception != NULL)
    *exception = exc;
  jsc_context_throw_exception(context, exc);
}
SWIGRUNTIME void SWIG_JSC_exception(JSCContext* context, JSCException** exception, int /*code*/, const char* msg) {
  SWIG_Javascript_Raise(context, exception, msg);
}

/* ----------------------------------------------------------------------------
 *  The parent class of all Proxies
 *
 * ---------------------------------------------------------------------------*/

typedef struct {
  int swigCMemOwn;
  void *swigCObject;
  swig_type_info *info;
} SwigPrivData;

SWIGRUNTIME JSCValue* _wrap_SwigObject_disown(void *obj, GPtrArray *args, gpointer user_data)
{
  JSCContext *context = jsc_context_get_current();
  SwigPrivData *cdata = (SwigPrivData *)obj;

  if (cdata != NULL)
    cdata->swigCMemOwn = false;

  return jsc_value_new_undefined(context);
}

SWIGRUNTIME JSCValue* _wrap_SwigObject_getCPtr(void *obj, GPtrArray *args, gpointer user_data)
{
  JSCContext *context = jsc_context_get_current();
  SwigPrivData *cdata = (SwigPrivData*)obj;

  if (cdata == NULL)
    return jsc_value_new_number(context, 0);
  return jsc_value_new_number(context, (long)cdata->swigCObject);
}

SWIGRUNTIME JSCValue* _wrap_SwigObject_equals(void *obj, GPtrArray *args, gpointer user_data)
{
  JSCContext *context = jsc_context_get_current();
  int result = 0;

  if (args->len == 1) {
    SwigPrivData *cdata = (SwigPrivData*)obj;
    JSCValue* obj2 = g_ptr_array_index(args, i);
    if (jsc_value_is_object(obj2) && jsc_value_object_is_instance_of(obj2, "SwigPrivData")) {
      SwigPrivData *cdata2 = value_to_pointer(context, obj2);
      result = cdata->swigCObject == cdata2->swigCObject;
    }
  }
  return jsc_value_new_boolean(context, result);
}

SWIGRUNTIME SWIG_JSC6_Properties _SwigObject_values[] = {
  { NULL, G_TYPE_NONE, NULL, NULL }
};

SWIGRUNTIME SWIG_JSC6_Functions _SwigObject_functions[] = {
  { "disown",_wrap_SwigObject_disown },
  { "equals",_wrap_SwigObject_equals },
  { "getCPtr",_wrap_SwigObject_getCPtr },
  { NULL, NULL }
};

SWIGRUNTIME JSClassDefinition _SwigObject_objectDefinition;

SWIGRUNTIME JSClassRef _SwigObject_classRef;

SWIGRUNTIME int SWIG_JSC_ConvertInstancePtr(JSCContext* context, JSCValue* objRef, void** ptr, swig_type_info *info, int flags) {
  SwigPrivData *cdata;

  cdata = (SwigPrivData *) JSObjectGetPrivate(objRef);
  if (cdata == NULL) {
    return SWIG_ERROR;
  }
  assert(ptr);
  *ptr = NULL;
  if (!info || cdata->info == info) {
    *ptr = cdata->swigCObject;
  } else {
    swig_cast_info *tc = SWIG_TypeCheckStruct(cdata->info, info);
    if (tc) {
      int newmemory = 0;
      *ptr = SWIG_TypeCast(tc, cdata->swigCObject, &newmemory);
      assert(!newmemory); /* newmemory handling not yet implemented */
    } else {
      return SWIG_ERROR;
    }
  }

  if ((flags & SWIG_POINTER_RELEASE) == SWIG_POINTER_RELEASE && !cdata->swigCMemOwn) {
    return SWIG_ERROR_RELEASE_NOT_OWNED;
  } else {
    if (flags & SWIG_POINTER_DISOWN)
      cdata->swigCMemOwn = false;
    if (flags & SWIG_POINTER_CLEAR)
      cdata->swigCObject = NULL;
  }

  return SWIG_OK;
}

SWIGRUNTIME int SWIG_JSC_ConvertPtr(JSCContext* context, JSCValue* valRef, void** ptr, swig_type_info *info, int flags) {
  /* special case: JavaScript null => C NULL pointer */
  if(jsc_value_is_null(valRef)) {
    *ptr = NULL;
    return (flags & SWIG_POINTER_NO_NULL) ? SWIG_NullReferenceError : SWIG_OK;
  }

  if(!jsc_value_is_object(valRef))
    return SWIG_TypeError;

  return SWIG_JSC_ConvertInstancePtr(context, valRef, ptr, info, flags);
}

SWIGRUNTIME JSCValue* SWIG_JSC_NewPointerObj(JSCContext* context, void *ptr, swig_type_info *info, int flags) {
  JSClassRef classRef;
  JSCValue* result;
  SwigPrivData *cdata;

  if (ptr == NULL)
    return jsc_value_new_null(context);

  if(info->clientdata == NULL) {
    classRef = _SwigObject_classRef;
  } else {
    classRef = (JSClassRef) info->clientdata;
  }

  result = JSObjectMake(context, classRef, NULL);

  cdata = (SwigPrivData*) malloc(sizeof(SwigPrivData));
  cdata->swigCObject = ptr;
  cdata->swigCMemOwn = (flags & SWIG_POINTER_OWN) ? 1 : 0;
  cdata->info = info;

  JSObjectSetPrivate(result, cdata);

  return result;
}

#define SWIG_ConvertPtr(obj, ptr, info, flags)    SWIG_JSC_ConvertPtr(context, obj, ptr, info, flags)
#define SWIG_NewPointerObj(ptr, info, flags)      SWIG_JSC_NewPointerObj(context, ptr, info, flags)

#define SWIG_ConvertInstance(obj, pptr, type, flags)    SWIG_JSC_ConvertInstancePtr(context, obj, pptr, type, flags)
#define SWIG_NewInstanceObj(thisvalue, type, flags)     SWIG_JSC_NewPointerObj(context, thisvalue, type, flags)

#define SWIG_ConvertFunctionPtr(obj, pptr, type)        SWIG_JSC_ConvertPtr(context, obj, pptr, type, 0)
#define SWIG_NewFunctionPtrObj(ptr, type)               SWIG_JSC_NewPointerObj(context, ptr, type, 0)

/* ----------------------------------------------------------------------------
 *  A class for packed data
 *
 * ---------------------------------------------------------------------------*/

typedef struct {
  void *data;
  size_t size;
  swig_type_info *type;
} SwigPackedData;

SWIGRUNTIME SWIG_JSC6_Properties _SwigPackedData_values[] = {
  { NULL, G_TYPE_NONE, NULL, NULL }
};
SWIGRUNTIME SWIG_JSC6_Functions _SwigPackedData_functions[] = {
  { NULL, NULL }
};
SWIGRUNTIME JSClassDefinition _SwigPackedData_objectDefinition;
SWIGRUNTIME JSClassRef _SwigPackedData_classRef;

SWIGRUNTIMEINLINE
int SwigJSCPacked_Check(JSCContext* context, JSCValue* valRef) {
  return JSValueIsObjectOfClass(context, valRef, _SwigPackedData_classRef);
}

SWIGRUNTIME
swig_type_info* SwigJSCPacked_UnpackData(JSCContext* context, JSCValue* valRef, void *ptr, size_t size) {
  if (SwigJSCPacked_Check(context, valRef)) {
    JSCValue* objRef = valRef;
    SwigPackedData *sobj = (SwigPackedData *) JSObjectGetPrivate(objRef);
    if (sobj->size != size)
        return NULL;
    memcpy(ptr, sobj->data, size);
    return sobj->type;
  } else {
    return NULL;
  }
}

SWIGRUNTIME
int SWIG_JSC_ConvertPacked(JSCContext* context, JSCValue* valRef, void *ptr, size_t sz, swig_type_info *ty) {
  swig_type_info *to = SwigJSCPacked_UnpackData(context, valRef, ptr, sz);
  if (to == NULL)
      return SWIG_ERROR;
  if (ty != NULL) {
    if (to != ty) {
      /* check type cast? */
      swig_cast_info *tc = SWIG_TypeCheck(to->name,ty);
      if (tc != NULL)
          return SWIG_ERROR;
    }
  }
  return SWIG_OK;
}

SWIGRUNTIME
JSCValue* SWIG_JSC_NewPackedObj(JSCContext* context, void *data, size_t size, swig_type_info *type) {

  JSClassRef classRef = _SwigPackedData_classRef;
  JSCValue* result = JSObjectMake(context, classRef, NULL);

  SwigPackedData* cdata = (SwigPackedData*) malloc(sizeof(SwigPackedData));
  cdata->data = malloc(size);
  memcpy(cdata->data, data, size);
  cdata->size = size;
  cdata->type = type;

  JSObjectSetPrivate(result, cdata);

  return result;
}

/* SwigPackedData wrappers */
SWIGRUNTIME
void _wrap_SwigPackedData_delete(JSCValue* obj)
{
  SwigPackedData* cdata = (SwigPackedData*) JSObjectGetPrivate(obj);
  if (cdata) {
    free(cdata->data);
  }
}

/* for C++ member pointers, ie, member methods */

#define SWIG_ConvertMember(obj, ptr, sz, ty)            SWIG_JSC_ConvertPacked(context, obj, ptr, sz, ty)
#define SWIG_NewMemberObj(ptr, sz, type)                SWIG_JSC_NewPackedObj(context, ptr, sz, type)


/* ---------------------------------------------------------------------------
 * Support for IN/OUTPUT typemaps (see Lib/typemaps/inoutlist.swg)
 *
 * ---------------------------------------------------------------------------*/
SWIGRUNTIME
unsigned int SWIGJSC_ArrayLength(JSCContext* context, JSCValue* arr) {
  JSCValue* js_length = jsc_value_object_get_property(arr, "length");
  return jsc_value_is_number(js_length) ? (unsigned int)jsc_value_to_double(js_length) : 0;
}

SWIGRUNTIME
bool SWIGJSC_ValueIsArray(JSCContext* context, JSCValue* value) {
  if (jsc_value_is_object(value)) {
    JSCValue* array = NULL;
    JSCValue* isArray = NULL;
    JSCValue* retval = NULL;

    array = jsc_value_object_get_property(JSContextGetGlobalObject(context), "Array");
    isArray = jsc_value_object_get_property(array, "isArray");
    retval = JSObjectCallAsFunction(context, isArray, NULL, 1, &value, NULL);

    if (jsc_value_is_boolean(retval))
      return jsc_value_to_boolean(retval);
  }
  return false;
}

SWIGRUNTIME
JSCValue* SWIGJSC_AppendOutput(JSCContext* context, JSCValue* value, JSCValue* obj) {
  JSCValue* arr;
  unsigned int length;

  if (jsc_value_is_undefined(value))
    arr = JSObjectMakeArray(context, 0, 0, 0);
  else if (!SWIGJSC_ValueIsArray(context, value))
    arr = JSObjectMakeArray(context, 1, &value, 0);
  else
    arr = value;

  length = SWIGJSC_ArrayLength(context, arr);
  jsc_value_object_set_property_at_index(arr, length, obj);
  return arr;
}
