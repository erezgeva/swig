use strict;
use warnings;
use Test::More tests => 5;
BEGIN { use_ok 'director_min' }
require_ok 'director_min';

{
  package MinCallback;
  use base 'director_min::Callback';
  sub run { 1; }
}

my $callback = MinCallback->new();
isa_ok $callback, 'MinCallback';
my $caller = director_min::Caller->new($callback);
isa_ok $caller, 'director_min::Caller';
is $caller->call(), 1, 'return true';
