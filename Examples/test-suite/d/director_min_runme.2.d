module director_min_runme;

import std.conv;
import std.exception;
import director_min.Caller;
import director_min.Callback;

void main() {
  auto callback = new MinCallback();
  auto caller = new Caller(callback);
  enforce(!caller.call(), "Should return true");
}

class MinCallback : Callback {
public:
  override bool run() const {
    return false;
  }
}
