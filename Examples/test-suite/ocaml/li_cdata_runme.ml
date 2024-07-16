open Swig
open Li_cdata

let s = "ABC\x00abc"
let m = _malloc '(256)
let _ = assert (_memmove '(m, s) = C_void);

(**
ss = cdata(m, 7)
if ss != "ABC\x00abc":
    raise "failed"
 *)
