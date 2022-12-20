#! /usr/bin/perl -w

use strict;

sub ltrim { my $s = shift; $s =~ s/^\s+//;       return $s };
sub rtrim { my $s = shift; $s =~ s/\s+$//;       return $s };
sub  trim { my $s = shift; $s =~ s/^\s+|\s+$//g; return $s };

my @LINES; # store all lines by actual line nr
my %ADDR; # store the code offset and link to the line nr
my %DEFS; # store the defines
my %ADDRS; # common used addresses

sub validate_curr_next($$) {
    my $curr = shift;
    my $next = shift;
    if ($next) { # if we have next defined, we should now actually be at next, if not complain as we have missing data in the file
        if( $next != $curr) {
            print ";;ERR missing data curr: $curr should be next: $next\n";
        }
    }
}

sub analAsm($) {
    my $inst = shift;

    my @ins = split(/\s+/, $inst);

    if( $#ins == 0 ) {
        print  STDERR $ins[0], "\n";
        return $inst;
    }

    # do we have a @, ( , ,X ,Y
    my $imm = 0;
    my $ind = 0;
    my $x = 0;
    my $y = 0;

    if ( $inst =~ m/\(/) {
        $ind = 1;
    }
    if ( $inst =~ m/@/) {
        $imm = 1;
    }

    my $a = "";
    if ($inst =~ m/(#[[:xdigit:]]+)/ ) {
        $a = $1;
        if( $imm == 0 ) {
            $ADDRS{$a} = $a;
        }
    }

    my @q = split(/,/,$ins[1]);
    if( $#q > 0 ) {
        if( $q[1] eq "Y") { $y = 1; }
        if( $q[1] eq "X") { $x = 1; }
    }

    print  STDERR $ins[0]," ", $ins[1], " // imm: $imm, ind: $ind, x: $x, y: $y, a: $a\n";

    return $inst;
}

# main
{
    open(IN,"<combined.txt") || die "Fatal: cannot open in file, $!";

    my $p1 = '^([[:xdigit:]]{4})\s{2} ((?:[[:xdigit:]]{2}\s){1,3}\s{1,7}) (\w{3}(?:\s\S+)?) (.*)';

    my $nr = 0;
    my $curr = 0; # the current address as converted from hex
    my $next = 0; # the next address as converted from hex base + the number of bytes

    while(<IN>) {
        # cleanup the current line
        $_ = trim($_);
        $_ =~ s/ÿ//;

        if( m/^DEFINE\s+(\#\w+)\s+(\w+)/ ) {
            $DEFS{$1} = $2;
        }

        if ( m/$p1/x ) { # a line with a sam statement
            my $base = trim($1); # the base address after compiling the asm statement
            $ADDR{$base} = $nr;

            my $hex_val = hex($base);
            $curr = $hex_val;
            validate_curr_next($curr, $next);

            my $code = trim($2); # the compiled code bytes
            my $inst = trim($3); # the asm instruction
            $inst = analAsm($inst);
            my $rest = trim($4);

            # calculate the next base address for the next instruction
            my @b = split(/\s+/, $code);
            my $nbytes = @b;
            $next = $curr + $nbytes;

            # prepare for printing
            while(length($code) < 10 ) {
                $code = "$code "
            }
            while(length($inst) < 55 ) {
                $inst = "$inst "
            }

            my $p = sprintf("%05d %02d", $hex_val, $nbytes);
            my $z = "$p | $base $code | $inst ; $rest";

            $LINES[$nr] = $z;
            print $z,"\n";

            $nr ++;
            next;
        }

        if ( m/^([[:xdigit:]]{4})((?:\s+[[:xdigit:]]{2})*)(.*)/x) { # a line with a data define
            my $base = trim($1); # the base address after compiling the asm statement
            $ADDR{$base} = $nr;

            my $hex_val = hex($base);
            $curr = $hex_val;
            validate_curr_next($curr, $next);

            my $bytes = trim($2); # the data bytes
            my @b = split(/\s+/, $bytes);
            my $nbytes = @b;
            $next = $curr + $nbytes;

            while(length($bytes) < 68 ) {
                $bytes = "$bytes "
            }
            my $inst = trim($3);
            my $rest = trim($3);

            my $p = sprintf("%05d %02d", $hex_val, $nbytes);
            my $line = "$p | $base $bytes ; $rest";
            my $z = $line;

            $LINES[$nr] = $z;
            print $z,"\n";

            $nr ++;
            next;
        }

        # a line that is most likely just a comment (but it may be a continuation comment)
        my $line = trim($_);
        $line =~ s/^;+//;
        $line = trim($line);

        my $p = ' ' x 85;
        my $z = "$p; $line";

        $LINES[$nr] = $z;
        print "$z\n";

        $nr ++;
        next;
    }

    foreach my $a (sort keys %ADDRS) {
        if( length($a) == 5 ) {
            print ";common referenced address; $a\n";
        }
    }
    foreach my $a (sort keys %ADDRS) {
        if( length($a) == 4 ) {
            print ";common referenced address; $a\n";
        }
    }
    foreach my $a (sort keys %ADDRS) {
        if( length($a) == 3 ) {
            print ";common referenced address; $a\n";
        }
    }
    foreach my $a (sort keys %ADDRS) {
        if( length($a) == 2 ) {
            print ";common referenced address; $a\n";
        }
    }

    close(IN);
}
