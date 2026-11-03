/* ----------------------------------------------------------------------------
 *  Errors and exceptions
 *
 * ---------------------------------------------------------------------------*/

#define SWIG_Error(code, msg)     SWIG_JSC6_exception(context, exception, code, msg)
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
SWIGRUNTIME void SWIG_JSC6_exception(JSCContext* context, JSCException** exception, int /*code*/, const char* msg) {
  SWIG_Javascript_Raise(context, exception, msg);
}

/* ----------------------------------------------------------------------------
 *  The parent class of all Proxies
 *
 * ---------------------------------------------------------------------------*/

typedef struct {
  bool swigCMemOwn;
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

  if (cdata != NULL)
    return jsc_value_new_number(context, (long)cdata->swigCObject);
  return jsc_value_new_number(context, 0);
}

SWIGRUNTIME JSCValue* _wrap_SwigObject_equals(void *obj, GPtrArray *args, gpointer user_data)
{
  JSCContext *context = jsc_context_get_current();
  bool result = false;

  if (args->len == 1) {
    SwigPrivData *cdata = (SwigPrivData*)obj;
    if (cdata != NULL) {
      /* TODO
      JSCValue* obj2 = g_ptr_array_index(args, 0);
      if (jsc_value_is_object(obj2) && jsc_value_object_is_instance_of(obj2, "SwigPrivData")) {
        SwigPrivData* cdata2 = (SwigPrivData*)g_value_get_pointer((const GValue*)obj2);
        result = cdata->swigCObject == cdata2->swigCObject;
      }
      */
    }
  }
  return jsc_value_new_boolean(context, result);
}

SWIGRUNTIME SWIG_JSC6_Class_properties _SwigObject_values[] = {
  { NULL, NULL, NULL }
};

SWIGRUNTIME SWIG_JSC6_Methods _SwigObject_functions[] = {
  { "disown",_wrap_SwigObject_disown },
  { "equals",_wrap_SwigObject_equals },
  { "getCPtr",_wrap_SwigObject_getCPtr },
  { NULL, NULL }
};

SWIGRUNTIME SWIG_JSC6_Object_def _SwigObject_objectDefinition;

SWIGRUNTIME JSCClass* _SwigObject_classRef;

SWIGRUNTIME int SWIG_JSC6_ConvertPtr(JSCContext* context, void* _this, void** ptr, swig_type_info *info, int flags) {
  SwigPrivData* cdata = NULL;
  if (ptr == NULL)
    return SWIG_ERROR;
  if (_this == NULL)
    return (flags & SWIG_POINTER_NO_NULL) ? SWIG_NullReferenceError : SWIG_OK;
  cdata = (SwigPrivData*)_this;
  if (cdata == NULL)
    return SWIG_ERROR;
  *ptr = NULL;
  if (info == NULL || cdata->info == info) {
    *ptr = cdata->swigCObject;
  } else {
    swig_cast_info *tc = SWIG_TypeCheckStruct(cdata->info, info);
    if (tc != NULL) {
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

SWIGRUNTIME void* SWIG_JSC6_NewPointerObj(JSCContext* context, void *ptr, swig_type_info *info, int flags) {
  SwigPrivData *cdata;

  if (ptr == NULL)
    return NULL;

  cdata = (SwigPrivData*) malloc(sizeof(SwigPrivData));
  if (cdata == NULL)
      return NULL;
  cdata->swigCObject = ptr;
  cdata->swigCMemOwn = (flags & SWIG_POINTER_OWN) > 0;
  cdata->info = info;
  return cdata;
}

#define SWIG_ConvertPtr(obj, ptr, info, flags)    SWIG_JSC6_ConvertPtr(context, obj, ptr, info, flags)
#define SWIG_NewPointerObj(ptr, info, flags)      SWIG_JSC6_NewPointerObj(context, ptr, info, flags)

#define SWIG_ConvertInstance(obj, pptr, type, flags)    SWIG_JSC6_ConvertInstancePtr(context, obj, pptr, type, flags)
#define SWIG_NewInstanceObj(thisvalue, type, flags)     SWIG_JSC6_NewPointerObj(context, thisvalue, type, flags)

#define SWIG_ConvertFunctionPtr(obj, pptr, type)        SWIG_JSC6_ConvertPtr(context, obj, pptr, type, 0)
#define SWIG_NewFunctionPtrObj(ptr, type)               SWIG_JSC6_NewPointerObj(context, ptr, type, 0)

/* ----------------------------------------------------------------------------
 *  A class for packed data
 *
 * ---------------------------------------------------------------------------*/

typedef struct {
  void *data;
  size_t size;
  swig_type_info *type;
} SwigPackedData;

SWIGRUNTIME SWIG_JSC6_Class_properties _SwigPackedData_values[] = {
  { NULL, NULL, NULL }
};
SWIGRUNTIME SWIG_JSC6_Methods _SwigPackedData_functions[] = {
  { NULL, NULL }
};
SWIGRUNTIME SWIG_JSC6_Object_def _SwigPackedData_objectDefinition;
SWIGRUNTIME JSCClass* _SwigPackedData_classRef;

SWIGRUNTIMEINLINE
int SwigJSCPacked_Check(JSCContext* context, JSCValue* valRef) {
  return 0; /* JSValueIsObjectOfClass(context, valRef, _SwigPackedData_classRef); TODO */
}

SWIGRUNTIME
swig_type_info* SwigJSCPacked_UnpackData(JSCContext* context, JSCValue* valRef, void *ptr, size_t size) {
  if (SwigJSCPacked_Check(context, valRef)) {
    JSCValue* objRef = valRef;
    SwigPackedData *sobj = (SwigPackedData *) NULL; /* JSObjectGetPrivate(objRef); */
    if (sobj->size != size)
        return NULL;
    memcpy(ptr, sobj->data, size);
    return sobj->type;
  } else {
    return NULL;
  }
}

SWIGRUNTIME
int SWIG_JSC6_ConvertPacked(JSCContext* context, JSCValue* valRef, void *ptr, size_t sz, swig_type_info *ty) {
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
JSCValue* SWIG_JSC6_NewPackedObj(JSCContext* context, void *data, size_t size, swig_type_info *type) {

  JSCClass* classRef = _SwigPackedData_classRef;
  JSCValue* result = NULL; /* JSObjectMake(context, classRef, NULL); */

  SwigPackedData* cdata = (SwigPackedData*) malloc(sizeof(SwigPackedData));
  cdata->data = malloc(size);
  memcpy(cdata->data, data, size);
  cdata->size = size;
  cdata->type = type;

  /* JSObjectSetPrivate(result, cdata); TODO */

  return result;
}

/* SwigPackedData wrappers */
SWIGRUNTIME
void _wrap_SwigPackedData_delete(void* obj)
{
  SwigPackedData* cdata = (SwigPackedData*) obj;/* JSObjectGetPrivate(obj); TODO */
  if (cdata) {
    free(cdata->data);
  }
}

/* for C++ member pointers, ie, member methods */

#define SWIG_ConvertMember(obj, ptr, sz, ty)            SWIG_JSC6_ConvertPacked(context, obj, ptr, sz, ty)
#define SWIG_NewMemberObj(ptr, sz, type)                SWIG_JSC6_NewPackedObj(context, ptr, sz, type)


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

    array = jsc_value_object_get_property(jsc_context_get_global_object(context), "Array");
    isArray = jsc_value_object_get_property(array, "isArray");
    retval = NULL; /* JSObjectCallAsFunction(context, isArray, NULL, 1, &value, NULL); TODO */

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
    arr = NULL; /* JSObjectMakeArray(context, 0, 0, 0); */
  else if (!SWIGJSC_ValueIsArray(context, value))
    arr = NULL; /* JSObjectMakeArray(context, 1, &value, 0); */
  else
    arr = value;

  length = SWIGJSC_ArrayLength(context, arr);
  jsc_value_object_set_property_at_index(arr, length, obj);
  return arr;
}
