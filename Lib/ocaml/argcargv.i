/* -------------------------------------------------------------
 * SWIG library containing argc and argv multi-argument typemaps
 * ------------------------------------------------------------- */

%typemap(in) (int ARGC, char **ARGV) {
  size_t i, nitems = caml_array_len($input);
  $1 = ($1_ltype) nitems;
  $2 = (char **) malloc((nitems+1)*sizeof(char *));
  if ($2 == NULL) {
    SWIG_exception(SWIG_TypeError, "memory allocation failed");
  }
  for (i = 0; i < nitems; i++) {
    $2[i] = caml_string_val(caml_array_nth($input, i));
  }
  $2[i] = NULL;
}

/*
%typemap(typecheck, precedence=SWIG_TYPECHECK_STRING_ARRAY) (int ARGC, char **ARGV) {
}
*/

%typemap(freearg) (int ARGC, char **ARGV) {
  free((void *)$2);
}

/*
%typemap(in, fragment="<memory>")
%typemap(in, noblock=1)
%typemap(in, numinputs=0)
%typemap(argout)
%typemap(directorin)
%typemap(directorout)
%typemap(free)
%typemap(how)
%typemap(out)
%typemap(throws)
%typemap(type)
%typemap(varin)
%typemap(varout)
*/
