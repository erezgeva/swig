package main

import . "swigtests/rev_len_str"

func main() {
	t := NewTest()
	if t.Strlen("hile") != 4 {
		panic("bad multi-arg typemap")
	}

	if t.Strlen("hil\000") != 4 {
		panic("bad multi-arg typemap")
	}
}
