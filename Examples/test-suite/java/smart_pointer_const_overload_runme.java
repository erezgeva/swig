import smart_pointer_const_overload.*;

public class smart_pointer_const_overload_runme {
  static int CONST_ACCESS = 1;
  static int MUTABLE_ACCESS = 2;

  static {
    System.loadLibrary("smart_pointer_const_overload");
  }
  
  public static void test(Bar b, Foo f) {
    Assert(f.getX1() == 0);

    // Test member variable get
    Assert(b.getX1() == 0);
    Assert(f.getAccess1() == CONST_ACCESS);

    // Test member variable set
    b.setX1(1);
    Assert(f.getX1() == 1);
    Assert(f.getAccess1() == MUTABLE_ACCESS);
    
    // Test const method
    Assert(b.getx1() == 1);
    Assert(f.getAccess1() == CONST_ACCESS);
    
    // Test mutable method
    b.setx1(2);

    Assert(f.getX1() == 2);
    Assert(f.getAccess1() == MUTABLE_ACCESS);
    
    // Test extended const method
    Assert(b.getx2() == 2);
    Assert(f.getAccess1() == CONST_ACCESS);
    
    // Test extended mutable method
    b.setx2(3);

    Assert(f.getX1() == 3);
    Assert(f.getAccess1() == MUTABLE_ACCESS);
      
    // Test static method
    b.statMethod();

    Assert(f.getAccess1() == CONST_ACCESS);

    // Test const member
    f.setAccess1(MUTABLE_ACCESS);
    
    Assert(b.getY() == 0);
    Assert(f.getAccess1() == CONST_ACCESS);
    
    // Test get through mutable pointer to const member
    f.setAccess1(MUTABLE_ACCESS);
    
    Assert(smart_pointer_const_overload.get_int(b.getYp()) == 0);
    Assert(f.getAccess1() == CONST_ACCESS);

    // Test get through const pointer to mutable member
    f.setX1(4);
    f.setAccess1(MUTABLE_ACCESS);
    
    Assert(smart_pointer_const_overload.get_int(b.getXp()) == 4);
    Assert(f.getAccess1() == CONST_ACCESS);
      
    // Test set through const pointer to mutable member
    f.setAccess1(MUTABLE_ACCESS);
    smart_pointer_const_overload.set_int(b.getXp(), 5);
    
    Assert(f.getX1() == 5);
    Assert(f.getAccess1() == CONST_ACCESS);
  
    // Test set pointer to const member
    b.setYp(smart_pointer_const_overload.new_int(6));
  
    Assert(f.getY() == 0);
    Assert(smart_pointer_const_overload.get_int(f.getYp()) == 6);
    Assert(f.getAccess1() == MUTABLE_ACCESS);
  
    smart_pointer_const_overload.delete_int(f.getYp());
  }

  public static void main(String argv[]) {
    Foo f = new Foo();
    Bar b = new Bar(f);

    //Foo f2 = new Foo();
    //Bar b2 = new Bar2(f2);

    test(b, f);
    //test(b2, f2);
  }
  
  public static void Assert(boolean b) {
    if (!b)
      throw new RuntimeException("Assertion failed");
  }
}
