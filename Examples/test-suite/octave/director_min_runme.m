director_min

function self=MinCallback()
  global director_min;
  self=subclass(director_min.Callback());
  self.run=@MinCallback_run;
end
function ret=MinCallback_run(self)
  ret = true;
end

callback = MinCallback();
caller = director_min.Caller(callback);
if (!caller.call())
  error("Should return true");
end
