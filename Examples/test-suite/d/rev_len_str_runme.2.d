module rev_len_str_runme;

import rev_len_str.rev_len_str;
import rev_len_str.Test;
import std.stdio;

void main() {
   Test t = new Test();
   string str = "hile";
   if (t.strlen(str) != 4) {
      writeln(t.strlen(str));
      throw new Exception("bad multi-arg typemap");
   }

   if (t.strlen("hil\000") != 4) {
      throw new Exception("bad multi-arg typemap");
   }
}
