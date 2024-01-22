import director_min.*;

public class director_min_runme {

  static {
    try {
        System.loadLibrary("director_min");
    } catch (UnsatisfiedLinkError e) {
      System.err.println("Native code library failed to load. See the chapter on Dynamic Linking Problems in the SWIG Java documentation for help.\n" + e);
      System.exit(1);
    }
  }

  public static void main(String argv[]) throws Throwable
  {
    MinCallback callback = new MinCallback();
    Caller caller = new Caller(callback);
    if (!caller.call())
       throw new Exception("Should return true");
  }
}

class MinCallback extends Callback
{
  public boolean run()
  {
    return true;
  }
}
