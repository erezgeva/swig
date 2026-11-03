/* ------------------------------------------------------------
 * Primitive Types
 * ------------------------------------------------------------ */

/* boolean */

%fragment(SWIG_From_frag(bool),"header") {
SWIGINTERNINLINE
JSCValue* SWIG_From_dec(bool)(bool value)
{
  return jsc_value_new_boolean(context, value);
}
}

%fragment(SWIG_AsVal_frag(bool),"header",
          fragment=SWIG_AsVal_frag(long)) {
SWIGINTERN
int SWIG_AsVal_dec(bool)(JSCValue* obj, bool *val)
{
  if(!jsc_value_is_boolean(obj))
    return SWIG_ERROR;
  if (val != NULL)
    *val = jsc_value_to_boolean(obj);
  return SWIG_OK;
}
}

/* int */

%fragment(SWIG_From_frag(int),"header") {
SWIGINTERNINLINE JSCValue*
  SWIG_From_dec(int)(int value)
{
  return jsc_value_new_number(context, value);
}
}

/* long */

%fragment(SWIG_From_frag(long),"header") {
SWIGINTERNINLINE JSCValue*
SWIG_From_dec(long)(long value)
{
  return jsc_value_new_number(context, value);
}
}

%fragment(SWIG_AsVal_frag(long),"header",
          fragment="SWIG_CanCastAsInteger") {
SWIGINTERN int
SWIG_AsVal_dec(long)(JSCValue* obj, long* val)
{
  if (!jsc_value_is_number(obj))
    return SWIG_TypeError;
  if (val)
    *val = (long)jsc_value_to_double(obj);
  return SWIG_OK;
}
}

/* unsigned long */

%fragment(SWIG_From_frag(unsigned long),"header",
          fragment=SWIG_From_frag(long)) {
SWIGINTERNINLINE JSCValue*
SWIG_From_dec(unsigned long)(unsigned long value)
{
  return (value > LONG_MAX) ?
    jsc_value_new_number(context, value) : jsc_value_new_number(context, %numeric_cast(value,long));
}
}

%fragment(SWIG_AsVal_frag(unsigned long),"header",
          fragment="SWIG_CanCastAsInteger") {
SWIGINTERN int
SWIG_AsVal_dec(unsigned long)(JSCValue* obj, unsigned long *val)
{
  long longVal;
  if(!jsc_value_is_number(obj))
    return SWIG_TypeError;
  longVal = (long)jsc_value_to_double(obj);
  if(longVal < 0)
    return SWIG_OverflowError;
  if (val != NULL)
    *val = longVal;
  return SWIG_OK;
}
}

/* long long */
// Note: these are copied from 'long' and probably need fixing

%fragment(SWIG_From_frag(long long),"header",
    fragment=SWIG_From_frag(long),
    fragment="SWIG_LongLongAvailable") {
%#ifdef SWIG_LONG_LONG_AVAILABLE
SWIGINTERNINLINE JSCValue*
SWIG_From_dec(long long)(long long value)
{
  return jsc_value_new_number(context, value);
}
%#endif
}

%fragment(SWIG_AsVal_frag(long long),"header",
    fragment=SWIG_AsVal_frag(long),
    fragment="SWIG_CanCastAsInteger",
    fragment="SWIG_LongLongAvailable") {
%#ifdef SWIG_LONG_LONG_AVAILABLE
SWIGINTERN int
SWIG_AsVal_dec(long long)(JSCValue* obj, long long* val)
{
  if (!jsc_value_is_number(obj))
    return SWIG_TypeError;
  if(val != NULL)
    *val = (long long)jsc_value_to_double(obj);

  return SWIG_OK;
}
%#endif
}

/* unsigned long long */
// Note: these are copied from 'unsigned long' and probably need fixing

%fragment(SWIG_From_frag(unsigned long long),"header",
	  fragment=SWIG_From_frag(long long),
	  fragment="SWIG_LongLongAvailable") {
%#ifdef SWIG_LONG_LONG_AVAILABLE
SWIGINTERN JSCValue*
SWIG_From_dec(unsigned long long)(unsigned long long value)
{
  return (value > LONG_MAX) ?
    jsc_value_new_number(context, value) : jsc_value_new_number(context, %numeric_cast(value,long));
}
%#endif
}

%fragment(SWIG_AsVal_frag(unsigned long long),"header",
    fragment=SWIG_AsVal_frag(unsigned long),
    fragment="SWIG_CanCastAsInteger",
   fragment="SWIG_LongLongAvailable") {
%#ifdef SWIG_LONG_LONG_AVAILABLE
SWIGINTERN int
SWIG_AsVal_dec(unsigned long long)(JSCValue* obj, unsigned long long *val)
{
  long long longVal;
  if(!jsc_value_is_number(obj))
    return SWIG_TypeError;
  longVal = (unsigned long long)jsc_value_to_double(obj);
  if(longVal < 0)
    return SWIG_OverflowError;
  if(val != NULL)
    *val = longVal;
  return SWIG_OK;
}
%#endif
}

/* double */

%fragment(SWIG_From_frag(double),"header") {
SWIGINTERN JSCValue*
SWIG_From_dec(double) (double val)
{
  return jsc_value_new_number(context, val);
}
}

%fragment(SWIG_AsVal_frag(double),"header") {
SWIGINTERN int
SWIG_AsVal_dec(double)(JSCValue* obj, double *val)
{
  if(!jsc_value_is_number(obj))
    return SWIG_TypeError;
  if(val != NULL)
    *val = jsc_value_to_double(obj);
  return SWIG_OK;
}
}
