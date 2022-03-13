package Lossless::Register {
        require Tie::Scalar;
        our @ISA = qw(Tie::StdScalar);
        sub FETCH { ${$_[0]}->[0](Lossless::UNDEFINED()) }
        sub STORE { ${$_[0]}->[0]($_[1]) }
};

package Lossless;

use v5.16;
use strict;
use warnings;

our $VERSION = '0';

require Exporter;

our @ISA = qw(Exporter);
our @EXPORT = qw(
        NIL FALSE TRUE null_p false_p true_p
        pair_p cons car cdr
        symbol_p sym
        $ACC evaluate
        $REG
        env_search env_define env_set env_unset env_clear
        rope_new
); # Others: Stack? Arrays sym()

require XSLoader;
XSLoader::load('Lossless', $VERSION);

mem_init();

tie our $ACC, 'Lossless::Register', sub { Accumulator(@_) };
tie our $REG, 'Lossless::Register', sub { User_Register(@_) };

1;
