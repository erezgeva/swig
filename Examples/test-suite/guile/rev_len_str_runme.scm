;; The SWIG modules have "passive" Linkage, i.e., they don't generate
;; Guile modules (namespaces) but simply put all the bindings into the
;; current module.  That's enough for such a simple test.
(dynamic-call "scm_init_rev_len_str_module" (dynamic-link "./librev_len_str"))
(load "testsuite.scm")
(load "../schemerunme/rev_len_str.scm")
