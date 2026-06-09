%module(directors="1") director_classes2
%feature("director") Base;
%inline %{
struct DoubleHolder{};
class Base {
public:
  virtual ~Base(){}
  virtual DoubleHolder *const& ConstPtrRef(DoubleHolder *const& cprx){return cprx;}
};
%}
/*
gvim director_classes2_wrap.cxx

make director_classes2.cpptest

*/
