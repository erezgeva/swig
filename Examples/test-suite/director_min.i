%module(directors="1") director_min;

%feature("director") Callback;

%inline %{

class Callback {
public:
  virtual bool run() const { return false; }
  virtual ~Callback() {}
};

class Caller {
private:
  Callback *_callback;
public:
  Caller(Callback *cb): _callback(cb) { }
  bool call() { return _callback->run(); }
};

%}
