/*
 * A test case for reverse length string typemap
 */

%module rev_len_str

#ifndef SWIGC
%apply (size_t LENGTH, const char *STRING) { (size_t len, const char *str, ) }
#endif

%inline %{
struct Test {
  size_t strlen(size_t len, const char *str) {
    return len;
  }
};
%}
