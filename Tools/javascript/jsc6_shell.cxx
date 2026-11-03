#include <cstdio>
#include <jsc/jsc.h>

#include "js_shell.h"

#ifdef __GNUC__
#include <dlfcn.h>
#define LOAD_SYMBOL(handle, name) dlsym(handle, name)
#else
#error "implement dll loading"
#endif

typedef void (*JSC6Init)(JSCContext *context, JSCValue **_module);

class JSC6Shell : public JSShell {
public:
  virtual ~JSC6Shell();

protected:
  virtual bool InitializeEngine();
  virtual bool ExecuteScript(const std::string &source,
                             const std::string &scriptPath);
  virtual bool DisposeEngine();

private:
  JSCValue *Import(JSCContext *context, const char *module_path);
  static JSCValue *require_cb(const char *name, gpointer user_data);
  JSCContext *context = NULL;
};

static bool isNull(JSCValue *v) {
    return v == NULL || jsc_value_is_undefined(v) || jsc_value_is_null(v);
}

JSC6Shell::~JSC6Shell() {
  if (context != NULL)
    g_object_unref(context);
}
bool JSC6Shell::DisposeEngine() {
  if (context != NULL)
    g_object_unref(context);
  context = NULL;
  return true;
}

JSCValue *JSC6Shell::Import(JSCContext *context, const char *module_path) {
  HANDLE library;
  std::string symname = LoadModule(module_path, &library);
  if (library == NULL) {
    printf("Could not load _module.");
    return NULL;
  }
  symname += "_initialize";
  JSC6Init init_function =
      reinterpret_cast<JSC6Init>(LOAD_SYMBOL(library, symname.c_str()));
  if (init_function == NULL) {
    printf("Could not find _module's initializer function.");
    return NULL;
  }
  JSCValue *_module = NULL;
  init_function(context, &_module);
  return _module;
}

// Attention: this feature should not create too high expectations.
// It is only capable of loading things relative to the execution directory
// and not relative to the parent script.
JSCValue *JSC6Shell::require_cb(const char *name, gpointer user_data) {
  JSCContext *context = jsc_context_get_current();
  JSC6Shell *_this = (JSC6Shell *)user_data;
  JSCValue *_module = NULL;
  if (context != NULL && _this != NULL)
    _module = _this->Import(context, name);
  if (_module == NULL) {
    fprintf(stderr, "Ooops.\n");
    return jsc_value_new_undefined(context);
  }
  return _module;
}

static void print_cb(const char *message) { g_print("%s\n", message); }

static void PrintError(JSCException *exception, const std::string &msg = "") {
  if (exception != NULL)
    fprintf(stderr, "%s: %s\n", msg.c_str(),
            jsc_exception_get_message(exception));
  else
    fprintf(stderr, "%s\n", msg.c_str());
}

bool JSC6Shell::InitializeEngine() {
  if (context != NULL)
    g_object_unref(context);

  context = jsc_context_new();
  if (context == NULL)
    return false;

  JSCValue *console_obj = jsc_value_new_object(context, NULL, NULL);
  if (isNull(console_obj))
    return false;

  JSCValue *global = jsc_context_get_global_object(context);
  if (isNull(global))
    return false;

  JSCValue *print_func =
      jsc_value_new_function(context, "print", G_CALLBACK(print_cb), NULL,
                             NULL,        // user_data, destroy_notify
                             G_TYPE_NONE, // return type
                             1,           // n_params
                             G_TYPE_STRING);
  if (isNull(print_func))
    return false;

  JSCValue *require_func =
      jsc_value_new_function(context, "require", G_CALLBACK(require_cb), this,
                             NULL,           // user_data, destroy_notify
                             JSC_TYPE_VALUE, // return type
                             1,              // n_params
                             G_TYPE_STRING);
  if (isNull(require_func))
    return false;

  jsc_context_set_value(context, "console", console_obj);
  jsc_value_object_set_property(console_obj, "log", print_func);
  jsc_value_object_set_property(global, "print", print_func);
  jsc_value_object_set_property(global, "require", require_func);
  return true;
}

bool JSC6Shell::ExecuteScript(const std::string &source,
                              const std::string &scriptPath) {

  JSCException *exception = NULL;
  JSCCheckSyntaxResult ret = jsc_context_check_syntax(context,
      source.c_str(),
      -1, // nul-terminated string
      JSC_CHECK_SYNTAX_MODE_SCRIPT, scriptPath.c_str(),
      1, // first line
      &exception);
  if (ret != JSC_CHECK_SYNTAX_RESULT_SUCCESS) {
    PrintError(exception, "Syntax error");
    return false;
  }

  JSCValue *result = jsc_context_evaluate(context, source.c_str(), -1);
  g_object_unref(result);
  return true;
}

JSShell *JSC6Shell_Create() { return new JSC6Shell(); }
