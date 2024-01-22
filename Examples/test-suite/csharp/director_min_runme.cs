using System;

namespace director_minNamespace {

public class runme {
  static void Main() {
    MinCallback callback = new MinCallback();
    Caller caller = new Caller(callback);
    if (!caller.call())
       throw new Exception("Should return true");
  }
}

class MinCallback : Callback
{
  public override bool run()
  {
    return true;
  }
}

}
