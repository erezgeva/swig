import director_min

class MinCallback(director_min.Callback):
    def run(self):
        return True

callback = MinCallback()
caller = director_min.Caller(callback)
if not caller.call():
    raise RuntimeError("Should return true")
