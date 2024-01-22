require("import")       -- the import fn
import("director_min")  -- import code

Base = {}
function Base:run0()
  print("Base:run0")
  return true
end
function Base:run()
  print("Base:run")
  return false
end
function Base:new(msg)
  local obj = {}
  setmetatable(obj, self)
  self.__index = self
  print("Base:new ==")
  print("obj", obj, "travs: getmetatable(obj)")
  for k,v in pairs(getmetatable(obj)) do
    print (k, "=>", v)
  end
  print("self", self, "travs: self")
  for k,v in pairs(self) do
    print (k, "=>", v)
  end
  print("+++++++++++")
  return obj
end
Derv = {} -- Inherit from Base
function Derv:new()
  local obj = Base:new()
  setmetatable(self, {__index = Base})
  setmetatable(obj, self)
  self.__index = self
  print("Derv:new ==")
  print("obj", obj, "travs: getmetatable(obj)")
  for k,v in pairs(getmetatable(obj)) do
    print (k, "=>", v)
  end
  print("self", self, "travs: self")
  for k,v in pairs(self) do
    print (k, "=>", v)
  end
  print("self", self, "travs: getmetatable(self)")
  for k,v in pairs(getmetatable(self)) do
    print (k, "=>", v)
  end
  print("+++++++++++")
  return obj
end
function Derv:run()
  print("Derv:run")
  return true
end
function Derv:run1()
  print("Derv:run1")
  return self.run0()
end


d = Derv:new()
print("call run ====")
d:run()
print("call run0 ===")
d:run0()
print("call run1 ===")
d:run1()

c = director_min.Callback()
print("Callback ==")
print("c", c, "travs: getmetatable(c)")
t = getmetatable(c)
for k,v in pairs(t) do
  print (k, "=>", v)
end
print("t", t, "travs: getmetatable(c)[.fn]")
for k,v in pairs(t['.fn']) do
  print (k, "=>", v)
end
--print("self", self, "travs: getmetatable(self)")
--for k,v in pairs(getmetatable(self)) do
--  print (k, "=>", v)
--end
c:run()
print("+++++++++++")

--[[

type MinCallback struct{}

func (p *MinCallback) Run() bool {
  return true
}
]]

print("MinCallback ===========")


MinCallback = {} -- Inherit from Base
function MinCallback:new()
  local obj = director_min.Callback()
--setmetatable(self, {__index = obj.__index})
  setmetatable(self, {__index = MinCallback})
--setmetatable(obj, self)
  self.__index = self
  return obj
end
function MinCallback:run1()
  print("MinCallback:run1")
  return self.run()
end

--[[
d = MinCallback:new()
d:run()
d:run1()
]]

print("+++++++++++")

--[[
callback = director_min.NewDirectorCallback(&MinCallback{})
caller = director_min.NewCaller(callback)
assert(!caller.Call())
]]


--[[
i
Base:new ==
obj     table: 0x56384035c690   travs: getmetatable(obj)
__index =>      table: 0x56384035c520
new     =>      function: 0x56384035c600
run     =>      function: 0x56384035c590
run0    =>      function: 0x56384035c560
self    table: 0x56384035c520   travs: self
__index =>      table: 0x56384035c520
new     =>      function: 0x56384035c600
run     =>      function: 0x56384035c590
run0    =>      function: 0x56384035c560
+++++++++++
Derv:new ==
obj     table: 0x56384035c690   travs: getmetatable(obj)
__index =>      table: 0x56384035c5c0
new     =>      function: 0x56384035c630
run     =>      function: 0x56384035c660
run1    =>      function: 0x56384035c6d0
self    table: 0x56384035c5c0   travs: self
__index =>      table: 0x56384035c5c0
new     =>      function: 0x56384035c630
run     =>      function: 0x56384035c660
run1    =>      function: 0x56384035c6d0
self    table: 0x56384035c5c0   travs: getmetatable(self)
__index =>      table: 0x56384035c520
+++++++++++

call run ====
Derv:run
call run0 ===
Base:run0
call run1 ===
Derv:run1
Base:run0

c  <userdata of type 'Callback *' at 0x55e21cd13b90>  travs: getmetatable(c)
__index         =>      function: 0x7f5bb84e14cc
__eq            =>      function: 0x7f5bb84e1bf2
__tostring      =>      function: 0x7f5bb84e1af2
__gc            =>      function: 0x7f5bb84e1a4a
__newindex      =>      function: 0x7f5bb84e1956
.static =>      table: 0x55e21cd162c0
.type   =>      Callback
.set    =>      table: 0x55e21cd16110
.fn     =>      table: 0x55e21cd16190
.get    =>      table: 0x55e21cd16150
.bases  =>      table: 0x55e21cd160d0
+++++++++++


  SWIG_Lua_add_function(L,"__index",SWIG_Lua_class_get);
  SWIG_Lua_add_function(L,"__newindex",SWIG_Lua_class_set);
  SWIG_Lua_add_function(L,"__gc",SWIG_Lua_class_destruct);


]]


--[[

make director_min.cpptest

cp director_min_wrap.cxx director_mio_wrap.cxx

diff -u director_mio_wrap.cxx director_min_wrap.cxx | sed '/^[+-][+-][+-]/ { s/director_mio_wrap.cxx/director_min_wrap.cxx/;s/[[:space:]]202.*// }' > director_min_wrap.patch

patch -p0 < director_min_wrap.patch

g++ -c -fpic -std=c++20 director_min_wrap.cxx -I/usr/include/lua5.4
g++ -shared -std=c++20 director_min_wrap.o -llua5.4 -pthread -o director_min.so

LUA_PATH="./?.lua;" lua5.4 ./director_min_runme.lua

]]
