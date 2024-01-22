<?php

require "tests.php";

// No new functions
check::functions(array());
// New classes
check::classes(array('Callback', 'Caller'));
// No new vars
check::globals(array());

class MinCallback extends Callback {
  function run() {
    return true;
  }
}

$callback = new MinCallback();
$caller = new Caller($callback);
check::is_a($caller->call(), true);
check::done();
