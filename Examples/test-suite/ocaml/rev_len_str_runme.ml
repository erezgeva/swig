open Swig
open Rev_len_str

let _ =
  let t = new_Test '() in
  assert (t -> strlen ("hile") as int = 4);
  assert (t -> strlen ("hil\x00") as int = 4);
;;
