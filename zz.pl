#! /usr/bin/perl -w

sub ltrim { my $s = shift; $s =~ s/^\s+//;       return $s };
sub rtrim { my $s = shift; $s =~ s/\s+$//;       return $s };
sub  trim { my $s = shift; $s =~ s/^\s+|\s+$//g; return $s };

my @LINES; # store all lines by actual line nr
my %ADDR; # store the code offset and link to the line nr
my %DEFS; # store the defines

sub validate_curr_next($$) {
    my $curr = shift;
    my $next = shift;
    if ($next) { # if we have next defined, we should now actually be at next, if not complain as we have missing data in the file
        if( $next != $curr) {
            print ";;ERR missing data curr: $curr should be next: $next\n";
        }
    }
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
            my $base = trim($1);
            $ADDR{$base} = $nr;

            my $hex_val = hex($base);
            $curr = $hex_val;
            validate_curr_next($curr, $next);

            my $code = trim($2);
            my @b = split(/\s+/, $code);
            my $nbytes = @b;
            $next = $curr + $nbytes;

            while(length($code) < 10 ) {
                $code = "$code "
            }

            my $inst = trim($3);
            while(length($inst) < 55 ) {
                $inst = "$inst "
            }

            my $rest = trim($4);
            my $p = sprintf("%05d %02d", $hex_val, $nbytes);
            my $z = "$p | $base $code | $inst ; $rest";

            $LINES[$nr] = $z;
            print $z,"\n";

            $nr ++;
            next;
        }

        if ( m/^([[:xdigit:]]{4})((?:\s+[[:xdigit:]]{2})*)(.*)/x) { # a line with a data define
            my $base = trim($1);
            $ADDR{$base} = $nr;

            my $hex_val = hex($base);
            $curr = $hex_val;
            validate_curr_next($curr, $next);

            my $bytes = trim($2);
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

        $p = ' ' x 85;
        my $z = "$p; $line";
        $LINES[$nr] = $z;
        print "$z\n";
        $nr ++;
        next;
    }

    close(IN);
}
