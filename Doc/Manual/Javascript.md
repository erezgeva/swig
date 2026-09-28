

<h1 id="Javascript">30 SWIG and Javascript</h1>

<!-- INDEX -->

<!-- INDEX -->

This chapter describes SWIG's support of Javascript. It does not cover SWIG basics, but only information that is specific to this module.

<h2 id="Javascript_overview">30.1 Overview</h2>

Javascript is a prototype-based scripting language that is dynamic, weakly typed and has first-class functions. Its arguably the most popular language for web development.
Javascript has gone beyond being a browser-based scripting language and can be used as a backend development language with [node.js](https://nodejs.org).

Native Javascript extensions can be used for applications that embed a web-browser view or that embed a Javascript engine (such as *node.js*). Extending a general purpose web-browser is not possible as this would be a severe security issue.

SWIG/Javascript currently supports:

- **Node.js** 12 or later.  SWIG can optionally generate Node-API code, which needs Node.js 12.17 or later.
- **JavascriptCore** 4.0 or later.  JavascriptCore is used by Safari/Webkit
- [**v8**](https://v8.dev/) 7.4 or later (we currently CI test with 7.8 and 10.2).  v8 is used by Chromium and Node.js.

[WebKit](https://webkit.org/) is a modern browser implementation available as open-source which can be embedded into an application.
[NW.jst](https://github.com/nwjs/nw.js) provides an app runtime which uses Google's Chromium as Web-Browser widget and node.js for javascript extensions.

<h2 id="Javascript_preliminaries">30.2 Preliminaries</h2>

<h3 id="Javascript_running_swig">30.2.1 Running SWIG</h3>

Suppose that you defined a SWIG module such as the following:

```swig

%module example
%{
#include "example.h"
%}
int gcd(int x, int y);
extern double Foo;
```

To build a Javascript module, run SWIG using the `-javascript` option and a desired target engine `-jsc`, `-v8`, `-node` or `-napi`. `-v8` allows for interfacing with a raw embedded version of V8. In this case, it is up to the user to implement a binary module loading protocol. There are two generators supporting Node.js. The older generator for `node` is essentially delegating to the `v8` generator and adds some necessary preprocessor definitions. The more recent `-napi` generator produces `node-addon-api` that interfaces to Node.js through Node-API. The V8 generator is more mature, while the Node-API generator offers a number of advantages such as binary stable ABI allowing for publishing of universal binary modules on npm, Electron support and automatic multi-threading.

```shell

$ swig -javascript -jsc example.i
```

If building a C++ extension, add the -c++ option:

```shell

$ swig -c++ -javascript -jsc example.i
```

To generate code for V8, you would run swig like so:

```shell

$ swig -c++ -javascript -v8 example.i
```

This creates a C/C++ source file `example_wrap.c` or `example_wrap.cxx`. The generated C source file contains the low-level wrappers that need to be compiled and linked with the rest of your C/C++ application to create an extension module.

The name of the wrapper file is derived from the name of the input file. For example, if the input file is `example.i`, the name of the wrapper file is `example_wrap.c`. To change this, you can use the -o option. The wrapped module will export one function which must be called to register the module with the Javascript interpreter. For example, if your module is named `example` the corresponding initializer for JavascriptCore would be

```swig

bool example_initialize(JSGlobalContextRef context, JSObjectRef *exports)
```

and for v8:

```swig

void example_initialize(v8::Handle<v8::Object> exports)
```

**Note**: be aware that `v8` has a C++ API, and thus, the generated modules must be compiled as C++.

<h3 id="Javascript_running_tests_examples">30.2.2 Running Tests and Examples</h3>

The configuration for tests and examples currently supports Linux and Mac only and not MinGW (Windows) yet.

The default interpreter is `node.js` as it is available on all platforms and convenient to use.

Running the examples with JavascriptCore requires `libjavascriptcoregtk-1.0` to be installed, e.g., under Ubuntu with

```shell

$ sudo apt-get install libjavascriptcoregtk-1.0-dev
```

Running with `V8` requires `libv8`:

```shell

$ sudo apt-get install libnode-dev
```

Running with Node-API requires `node-addon-api`:

```shell

$ sudo npm install -g node-addon-api
```

Examples can be run using

```shell

$ make check-javascript-examples ENGINE=jsc
```

`ENGINE` can be `node`, `jsc`, `v8`, or `napi`.

The test-suite can be run using

```shell

$ make check-javascript-test-suite ENGINE=jsc
```

<h3 id="Javascript_known_issues">30.2.3 Known Issues</h3>

At the moment, the Javascript generators pass all tests syntactically, i.e., the generated source code compiles. However, there are still remaining runtime issues.

- Default optional arguments do not work for all targeted interpreters except Node-API
- Multiple output arguments do not work for JSC
- C89 incompatibility: the JSC generator might still generate C89 violating code
- `long long` is not supported except with Node-API
- Javascript callbacks are not supported
- `instanceOf` does not work under JSC

The primary development environment has been Linux (Ubuntu 22.04). Windows and Mac OS X have been tested sporadically. Therefore, the generators might have more issues on those platforms. Please report back any problem you observe to help us improving this module quickly.

<h2 id="Javascript_integration">30.3 Integration</h2>

This chapter gives a short introduction how to use a native Javascript extension: as a `node.js` module, and as an extension for an embedded Webkit.

<h3 id="Javascript_node_extensions">30.3.1 Creating node.js Extensions</h3>

To install `node.js` you can download an installer from their [web-site](https://launchpad.net/~chris-lea/+archive/node.js) for Mac OS X and Windows. For Linux you can either build the source yourself and run `sudo checkinstall` or keep to the (probably stone-age) packaged version. For Ubuntu there is a [PPA](https://launchpad.net/~chris-lea/+archive/ubuntu/node.js/) available.

```shell

$ sudo add-apt-repository ppa:chris-lea/node.js
$ sudo apt-get update
$ sudo apt-get install nodejs
```

As `v8` is written in C++ and comes as a C++ library it is crucial to compile your module using the same compiler flags as used for building v8. To make things easier, `node.js` provides a build tool called `node-gyp`.

You have to install it using `npm`:

```shell

$ sudo npm install -g node-gyp
```

`node-gyp` expects a configuration file named `binding.gyp` which is basically in JSON format and conforms to the same format that is used with Google's build-tool `gyp`.

`binding.gyp`:

```swig

{
  "targets": [
    {
      "target_name": "example",
      "sources": [ "example.cxx", "example_wrap.cxx" ]
    }
  ]
}
```

First create the wrapper using SWIG:

```shell

$ swig -javascript -node -c++ example.i
```

Then run `node-gyp build` to actually create the module:

```shell

$ node-gyp build
```

This will create a `build` folder containing the native module. To use the extension you need to 'require' it in your Javascript source file:

```swig

require("./build/Release/example")
```

A more detailed explanation is given in the [Examples](#Javascript_examples) section.

<h4 id="Javascript_using_yeoman">30.3.1.1 Using `yeoman` to generate a Node-API skeleton</h4>

If targeting Node-API, the easiest way to bootstrap a project is by using the `yeoman` generator:

```shell

$ sudo npm install -g yo
$ sudo npm install -g generator-napi-module
$ mkdir example
$ cd example
$ yo napi-module                     # the choice of template is irrelevant, SWIG will replace the C++ code
$ npm install node-addon-api@latest  # the yeoman version is outdated
$ swig -javascript -napi -c++ -o src/example.cc example.i
$ node-gyp configure
$ node-gyp build

```

There is also the [`node-magickwand`](https://github.com/mmomtchev/node-magickwand) project that can be used as a tutorial for building and publishing a complex C++ library to
npm as a ready-to-use real-world binary module.

<h4 id="Javascript_troubleshooting">30.3.1.2 Troubleshooting</h4>

- *'module' object has no attribute 'script_main'*

This error happens when `gyp` is installed as a distribution package. It seems to be outdated. Removing it resolves the problem.

```shell

$ sudo apt-get remove gyp
```

<h3 id="Javascript_embedded_webkit">30.3.2 Embedded Webkit</h3>

Webkit is pre-installed on Mac OS X and available as a library for GTK.

<h4 id="Javascript_osx">30.3.2.1 Mac OS X</h4>

There is general information about programming with WebKit on [Apple Developer Documentation](https://developer.apple.com/library/mac/documentation/cocoa/conceptual/DisplayWebContent/DisplayWebContent.html). Details about `Cocoa` programming are not covered here.

An integration of a native extension 'example' would look like this:

```swig

#import "appDelegate.h"

extern bool example_initialize(JSGlobalContextRef context, JSObjectRef* exports);

@implementation ExampleAppDelegate

@synthesize webView;

- (void)addGlobalObject:(JSContextRef) context:(NSString *)objectName:(JSObjectRef) theObject {
  JSObjectRef global = JSContextGetGlobalObject(context);
  JSStringRef objectJSName = JSStringCreateWithCFString( (CFStringRef) objectName )
  if ( objectJSName != NULL ) {
    JSObjectSetProperty(context, global, objectJSName, theObject, kJSPropertyAttributeReadOnly, NULL);
    JSStringRelease( objectJSName );
  }
}

- (void)applicationDidFinishLaunching:(NSNotification *)aNotification {

  // Start a webview with the bundled index.html file
  NSString *path = [[NSBundle mainBundle] bundlePath];
  NSString *url =  [NSString stringWithFormat: @"file://%@/Contents/Assets/index.html", path];

  WebFrame *webframe = [webView mainFrame];
  JSGlobalContextRef context = [webframe globalContext];

  JSObjectRef example;
  example_initialize(context, &example);
  [self addGlobalObject:context:@"example":example]

  JSObjectSetProperty(context, global, JSStringRef propertyName, example, JSPropertyAttributes attributes, NULL);

  [ [webView mainFrame] loadRequest:
    [NSURLRequest requestWithURL: [NSURL URLWithString:url] ]
  ];
}

@end
```

<h4 id="Javascript_gtk">30.3.2.2 GTK</h4>

There is general information about programming GTK at [GTK documentation](https://developer.gnome.org/gtk2/) and in the [GTK tutorial](https://developer.gnome.org/gtk-tutorial/), and for Webkit there is a [Webkit GTK+ API Reference](https://webkitgtk.org/reference/webkitgtk/stable/index.html).

An integration of a native extension 'example' would look like this:

```swig

#include <gtk/gtk.h>
#include <webkit/webkit.h>

extern bool example_initialize(JSGlobalContextRef context);

int main(int argc, char* argv[])
{
  // Initialize GTK+
  gtk_init(&argc, &argv);

  ...

  // Create a browser instance
  WebKitWebView *webView = WEBKIT_WEB_VIEW(webkit_web_view_new());
  WebFrame *webframe = webkit_web_view_get_main_frame(webView);
  JSGlobalContextRef context = webkit_web_frame_get_global_context(webFrame);
  JSObjectRef global = JSContextGetGlobalObject(context);

  JSObjectRef exampleModule;
  example_initialize(context, &exampleModule);
  JSStringRef jsName = JSStringCreateWithUTF8CString("example");
  JSObjectSetProperty(context, global, jsName, exampleModule, kJSPropertyAttributeReadOnly, NULL);
  JSStringRelease(jsName);

  ...

  // Load a web page into the browser instance
  webkit_web_view_load_uri(webView, "https://www.webkitgtk.org/");

  ...

  // Run the main GTK+ event loop
  gtk_main();

  return 0;
}
```

<h3 id="Javascript_applications_webkit">30.3.3 Creating Applications with node-webkit</h3>

To get started with `node-webkit` there is a very informative set of [wiki pages](https://github.com/rogerwang/node-webkit/wiki).

Similar to `node.js`, `node-webkit` is started from command line within a `node.js` project directory.
Native extensions are created in the very same way as for `node.js`, except that a customized `gyp` derivate has to be used: [nw-gyp](https://github.com/rogerwang/nw-gyp).

A simple example would have the following structure:

```swig

- package.json
- app.html
- app.js
- node_modules
  / example
  ... (as known from node.js)

```

The configuration file essentially conforms to `node.js` syntax.
It has some extras to configure `node-webkit`. See the [Manifest](https://github.com/rogerwang/node-webkit/wiki/Manifest-format) specification for more details.

`package.json`:

```swig

{
  "name": "example",
  "main": "app.html",
  "window": {
    "show": true,
    "width": 800,
    "height": 600
  }
}
```

The `'main'` property of `package.json` specifies a web-page to be rendered in
the main window.

`app.html`:

```swig
<html><head><script src="app.js"></script></head><body><div>
      The greatest common divisor of
      <span id="x"></span> and
      <span id="y"></span> is
      <span id="z"></span>.
    </div></body></html>
```

As known from `node.js` one can use `require` to load javascript modules.
Additionally, `node-webkit` provides an API that allows manipulating the window's menu,
open new windows, and many more things.

`app.js`:

```swig
window.onload = function() {
  var example = require("example");
  var x = 18;
  var y = 24;
  var z = example.gcd(x, y);
  document.querySelector('#x').innerHTML = x;
  document.querySelector('#y').innerHTML = y;
  document.querySelector('#z').innerHTML = z;
};
```

<h2 id="Javascript_examples">30.4 Examples</h2>

Some basic examples are shown here in more detail.

<h3 id="Javascript_simple_example">30.4.1 Simple</h3>

The common example `simple` looks like this:

```swig

/* File : example.i */
%module example

%inline %{
extern int    gcd(int x, int y);
extern double Foo;
%}
```

To make this available as a node extension a `binding.gyp` has to be created:

```swig

{
  "targets": [
    {
      "target_name": "example",
      "sources": [ "example.cxx", "example_wrap.cxx" ]
    }
  ]
}
```

Then `node-gyp` is used to build the extension:

```shell

$ node-gyp configure build
```

From a 'nodejs` application the extension would be used like this:

```swig

// import the extension via require
var example = require("./build/Release/example");

// calling the global method
var x = 42;
var y = 105;
var g = example.gcd(x, y);

// Accessing the global variable
var f = example.Foo;
example.Foo = 3.1415926;
```

First the module `example` is loaded from the previously built extension. Global methods and variables are available in the scope of the module.

**Note**: ECMAScript 5, the currently implemented Javascript standard, does not have modules. `node.js` and other implementations provide this mechanism defined by the [CommonJS](https://wiki.commonjs.org/wiki/CommonJS) group. For browsers this is provided by [Browserify](https://browserify.org), for instance.

<h3 id="Javascript_class_example">30.4.2 Class</h3>

The common example `class` defines three classes, `Shape`, `Circle`, and `Square`:

```swig

class Shape {
public:
  Shape() {
    nshapes++;
  }
  virtual ~Shape() {
    nshapes--;
  }
  double  x, y;
  void    move(double dx, double dy);
  virtual double area(void) = 0;
  virtual double perimeter(void) = 0;
  static  int nshapes;
};

class Circle : public Shape {
private:
  double radius;
public:
  Circle(double r) : radius(r) { }
  virtual double area(void);
  virtual double perimeter(void);
};

class Square : public Shape {
private:
  double width;
public:
  Square(double w) : width(w) { }
  virtual double area(void);
  virtual double perimeter(void);
};
```

`Circle` and `Square` inherit from `Shape`. `Shape` has a static variable `nshapes`, a function `move` that can't be overridden (non-virtual), and two abstract functions `area` and `perimeter` (pure virtual) that must be overridden by the sub-classes.

A `nodejs` extension is built the same way as for the `simple` example.

In Javascript it can be used as follows:

```swig

var example = require("./build/Release/example");

// local aliases for convenience
var Shape = example.Shape;
var Circle = example.Circle;
var Square = example.Square;

// creating new instances using the 'new' operator
var c = new Circle(10);
var s = new Square(10);

// accessing a static member
Shape.nshapes;

// accessing member variables
c.x = 20;
c.y = 30;
s.x = -10;
s.y = 5;

// calling some methods
c.area();
c.perimeter();
s.area();
s.perimeter();

// instantiation of Shape is not permitted
new Shape();
```

Running these commands in an interactive node shell results in the following output:

```shell

$ node -i
& var example = require("./build/Release/example");
undefined
& var Shape = example.Shape;
undefined
& var Circle = example.Circle;
undefined
& var Square = example.Square;
undefined
& var c = new Circle(10);
undefined
& var s = new Square(10);
undefined
& Shape.nshapes;
2
& c.x = 20;
20
& c.y = 30;
30
& s.x = -10;
-10
& s.y = 5;
5
& c.area();
314.1592653589793
& c.perimeter();
62.83185307179586
& s.area();
100
& s.perimeter();
40
& c.move(40, 40)
undefined
& c.x
60
& c.y
70
& new Shape()
Error: Class Shape can not be instantiated
at repl:1:2
at REPLServer.self.eval (repl.js:110:21)
at Interface.<anonymous> (repl.js:239:12)
at Interface.EventEmitter.emit (events.js:95:17)
at Interface._onLine (readline.js:202:10)
at Interface._line (readline.js:531:8)
at Interface._ttyWrite (readline.js:760:14)
at ReadStream.onkeypress (readline.js:99:10)
at ReadStream.EventEmitter.emit (events.js:98:17)
at emitKey (readline.js:1095:12)
```

**Note**: In ECMAScript 5 there is no concept for classes. Instead each function can be used as a constructor function which is executed by the 'new' operator. Furthermore, during construction the key property `prototype` of the constructor function is used to attach a prototype instance to the created object. A prototype is essentially an object itself that is the first-class delegate of a class used whenever the access to a property of an object fails. The very same prototype instance is shared among all instances of one type. Prototypal inheritance is explained in more detail on in [Inheritance and the prototype chain](https://developer.mozilla.org/en-US/docs/Web/JavaScript/Inheritance_and_the_prototype_chain), for instance.

<h2 id="Javascript_implementation">30.5 Implementation</h2>

The Javascript Module implementation has taken a very different approach compared to other language modules in order to support different Javascript interpreters.

<h3 id="Javascript_source_code">30.5.1 Source Code</h3>

The Javascript module is implemented in `Source/Modules/javascript.cxx`. It dispatches the code generation to a `JSEmitter` instance, `V8Emitter`, `JSCEmitter` or `NAPIEmitter`. Additionally there are some helpers: `Template`, for templated code generation, and `JSEmitterState`, which is used to manage state information during AST traversal. This rough map shall make it easier to find a way through this huge source file:

```swig

// module wide defines

#define NAME "name"
...

// ###############################
// #  Helper class declarations

class JSEmitterState { ... };

class Template { ... };

// ###############################
// # JSEmitter declaration

class JSEmitter { ... };

// Emitter factory declarations

JSEmitter *swig_javascript_create_JSCEmitter();
JSEmitter *swig_javascript_create_V8Emitter();
JSEmitter *swig_javascript_create_NAPIEmitter();

// ###############################
// # Javascript module

// Javascript module declaration

class JAVASCRIPT:public Language { ... };

// Javascript module implementation

int JAVASCRIPT::functionWrapper(Node *n) { ... }
...

// Module factory implementation

static Language *new_swig_javascript() { ... }

extern "C" Language *swig_javascript(void) { ... }

// ###############################
// # JSEmitter base implementation

JSEmitter::JSEmitter() { ... }

Template JSEmitter::getTemplate(const String *name) { ... }
...

// ###############################
// # JSCEmitter

// JSCEmitter declaration

class JSCEmitter: public JSEmitter { ... };

// JSCEmitter implementation

JSCEmitter::JSCEmitter() { ... }

void JSCEmitter::marshalInputArgs(Node *n, ParmList *parms, Wrapper *wrapper,
                                  MarshallingMode mode, bool is_member, bool is_static) { ... }
...

// JSCEmitter factory

JSEmitter *swig_javascript_create_JSCEmitter() { ... }

// ###############################
// # V8Emitter

// V8Emitter declaration

class V8Emitter: public JSEmitter { ... };

// V8Emitter implementation

V8Emitter::V8Emitter() { ... }

int V8Emitter::initialize(Node *n) { ... }

// V8Emitter factory

JSEmitter *swig_javascript_create_V8Emitter() { ... }

// ###############################
// # Helper implementation (JSEmitterState, Template)

JSEmitterState::JSEmitterState() { ... }
...

Template::Template(const String *code_) { ... }
...
```

<h3 id="Javascript_code_templates">30.5.2 Code Templates</h3>

All generated code is created on the basis of code templates. The templates for *JavascriptCore* can be found in `Lib/javascript/jsc/javascriptcode.swg`, for *v8* in `Lib/javascript/v8/javascriptcode.swg` and for *Node-API* in `Lib/javascript/napi/javascriptcode.swg`.

To track the originating code template for generated code you can run

```shell

$ swig -javascript -jsc -debug-codetemplates
```

which wraps generated code with a descriptive comment

```swig

/* begin fragment("template_name") */

...generated code ...

/* end fragment("template_name") */
```

The Template class is used like this:

```swig

Template t_register = getTemplate("jsv8_register_static_variable");
t_register.replace("$jsparent", state.clazz(NAME_MANGLED))
    .replace("$jsname", state.variable(NAME))
    .replace("$jsgetter", state.variable(GETTER))
    .replace("$jssetter", state.variable(SETTER))
    .trim().
    print(f_init_static_wrappers);
```

A code template is registered with the *JSEmitter* via `fragment(name, "template")`, e.g.,

```swig

%fragment ("jsc_variable_declaration", "templates")
%{
  {"$jsname", $jsgetter, $jssetter, kJSPropertyAttributeNone},
%}
```

`Template` creates a copy of that string and `Template::replace` uses Swig's `Replaceall` to replace variables in the template. `Template::trim` can be used to eliminate leading and trailing whitespaces. `Template::print` is used to write the final template string to a Swig `DOH` (based on `Printv`). All methods allow chaining.

<h3 id="Javascript_emitter">30.5.3 Emitter</h3>

The Javascript module delegates code generation to a `JSEmitter` instance. The following extract shows the essential interface:

```swig

class JSEmitter {
  ...

  /**
   * Opens output files and temporary output DOHs.
   */
  virtual int initialize(Node *n);

  /**
   * Writes all collected code into the output file(s).
   */
  virtual int dump(Node *n) = 0;

  /**
   * Cleans up all open output DOHs.
   */
  virtual int close() = 0;

  ...

  /**
   * Invoked at the beginning of the classHandler.
   */
  virtual int enterClass(Node *);

  /**
   * Invoked at the end of the classHandler.
   */
  virtual int exitClass(Node *) {
    return SWIG_OK;
  }

  /**
   * Invoked at the beginning of the variableHandler.
   */
  virtual int enterVariable(Node *);

  /**
   * Invoked at the end of the variableHandler.
   */
  virtual int exitVariable(Node *) {
    return SWIG_OK;
  }

  /**
   * Invoked at the beginning of the functionHandler.
   */
  virtual int enterFunction(Node *);

  /**
   * Invoked at the end of the functionHandler.
   */
  virtual int exitFunction(Node *) {
    return SWIG_OK;
  }

  /**
   * Invoked by functionWrapper callback after call to Language::functionWrapper.
   */
  virtual int emitWrapperFunction(Node *n);

  /**
   * Invoked from constantWrapper after call to Language::constantWrapper.
   **/
  virtual int emitConstant(Node *n);

  /**
   * Registers a given code snippet for a given key name.
   *
   * This method is called by the fragmentDirective handler
   * of the JAVASCRIPT language module.
   **/
  int registerTemplate(const String *name, const String *code);

  /**
   * Retrieve the code template registered for a given name.
   */
  Template getTemplate(const String *name);

  State &getState();

  ...

}
```

The module calls `initialize`, `dump`, and `close` from within the `top` method:

```swig

int JAVASCRIPT::top(Node *n) {
  emitter->initialize(n);

  Language::top(n);

  emitter->dump(n);
  emitter->close();

  return SWIG_OK;
}
```

The methods `enterClass` and `exitClass` are called from within the `classHandler` method:

```swig

int JAVASCRIPT::classHandler(Node *n) {

  emitter->enterClass(n);
  Language::classHandler(n);
  emitter->exitClass(n);

  return SWIG_OK;
}
```

In `enterClass` the emitter stores state information that is necessary when processing class members. In `exitClass` the wrapper code for the whole class is generated.

<h3 id="Javascript_emitter_states">30.5.4 Emitter states</h3>

For storing information during the AST traversal the emitter provides a `JSEmitterState` with different slots to store data representing the scopes global, class, function, and variable.

```swig

class JSEmitterState {

public:

  JSEmitterState();

  ~JSEmitterState();

  DOH *global();

  DOH *global(const char* key, DOH *initial = 0);

  DOH *clazz(bool reset = false);

  DOH *clazz(const char* key, DOH *initial = 0);

  DOH *function(bool reset = false);

  DOH *function(const char* key, DOH *initial = 0);

  DOH *variable(bool reset = false);

  DOH *variable(const char* key, DOH *initial = 0);

  static int IsSet(DOH *val);

  ...
};
```

When entering a scope, such as in `enterClass`, the corresponding state is reset and new data is stored:

```swig

state.clazz(RESET);
state.clazz(NAME, Getattr(n, "sym:name"));
```

State information can be retrieved using `state.clazz(NAME)` or with `Getattr` on `state.clazz()` which actually returns a `Hash` instance.

<h3 id="Javascript_jsc_exceptions">30.5.5 Handling Exceptions in JavascriptCore</h3>

Applications with an embedded JavascriptCore should be able to present detailed exception messages that occur in the Javascript engine. Below is an example derived from code provided by Brian Barnes on how these exception details can be extracted.

```swig

void script_exception_to_string(JSContextRef js_context, JSValueRef exception_value_ref,
                                char* return_error_string, int return_error_string_max_length)
{
  JSObjectRef exception_object;
  JSValueRef value_ref;
  JSStringRef jsstring_property_name = NULL;
  JSValueRef temporary_exception = NULL;
  JSStringRef js_return_string = NULL;
  size_t bytes_needed;
  char* c_result_string = NULL;
  exception_object = JSValueToObject(js_context, exception_value_ref, NULL);

  /* source url */
  strcpy(return_error_string, "[");
  jsstring_property_name = JSStringCreateWithUTF8CString("sourceURL");
  value_ref = JSObjectGetProperty(js_context, exception_object, jsstring_property_name, &temporary_exception);
  JSStringRelease(jsstring_property_name);
  js_return_string = JSValueToStringCopy(js_context, value_ref, NULL);
  bytes_needed = JSStringGetMaximumUTF8CStringSize(js_return_string);
  c_result_string = (char*)calloc(bytes_needed, sizeof(char));
  JSStringGetUTF8CString(js_return_string, c_result_string, bytes_needed);
  JSStringRelease(js_return_string);
  strncat(return_error_string, c_result_string, return_error_string_max_length-1);
  free(c_result_string);

  strncat(return_error_string, ":", return_error_string_max_length-1);

  /* line number */

  jsstring_property_name = JSStringCreateWithUTF8CString("line");
  value_ref = JSObjectGetProperty(js_context, exception_object, jsstring_property_name, &temporary_exception);
  JSStringRelease(jsstring_property_name);
  js_return_string = JSValueToStringCopy(js_context, value_ref, NULL);
  bytes_needed = JSStringGetMaximumUTF8CStringSize(js_return_string);
  c_result_string = (char*)calloc(bytes_needed, sizeof(char));
  JSStringGetUTF8CString(js_return_string, c_result_string, bytes_needed);
  JSStringRelease(js_return_string);
  strncat(return_error_string, c_result_string, return_error_string_max_length-1);
  free(c_result_string);

  strncat(return_error_string, "]", return_error_string_max_length-1);

  /* error message */

  jsstring_property_name = JSStringCreateWithUTF8CString("message");
  value_ref = JSObjectGetProperty(js_context, exception_object, jsstring_property_name, &temporary_exception);
  JSStringRelease(jsstring_property_name);
  if(NULL == value_ref)
  {
    strncat(return_error_string, "Unknown Error", return_error_string_max_length-1);
  }
  else
  {
    js_return_string = JSValueToStringCopy(js_context, value_ref, NULL);
    bytes_needed = JSStringGetMaximumUTF8CStringSize(js_return_string);
    c_result_string = (char*)calloc(bytes_needed, sizeof(char));
    JSStringGetUTF8CString(js_return_string, c_result_string, bytes_needed);
    JSStringRelease(js_return_string);
    strncat(return_error_string, c_result_string, return_error_string_max_length-1);
    free(c_result_string);
  }
}
```

It would be used in the following way:

```swig

if(js_exception)
{
  char return_error_string[256];
  script_exception_to_string(js_context, js_exception, return_error_string, 256);
  printf("Compile error is %s", return_error_string);
}
```

<h3 id="Javascript_napi_exceptions">30.5.6 Handling Exceptions in Node-API</h3>

Node-API is the only generator that provides fully automatic conversion of C++ exceptions to JavaScript exceptions when building with C++ exceptions enabled in `binding.gyp`:

```swig

'conditions': [
  ['OS=="mac"',
    {
      'xcode_settings': {
        'GCC_ENABLE_CPP_RTTI': 'YES',
        'GCC_ENABLE_CPP_EXCEPTIONS' : 'YES'
      }
    }
  ],
  ['OS=="linux" or OS=="freebsd" or OS=="openbsd" or OS=="solaris"',
    {
      'cflags!': [ '-fno-exceptions' ],
      'cflags_cc!': [ '-fno-exceptions', '-fno-rtti' ]
    }
  ]
]

```

In this case, nothing else is needed for the C++ exceptions to be passed to JavaScript.
