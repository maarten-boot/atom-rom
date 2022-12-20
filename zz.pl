#! /usr/bin/perl -w

sub ltrim { my $s = shift; $s =~ s/^\s+//;       return $s };
sub rtrim { my $s = shift; $s =~ s/\s+$//;       return $s };
sub  trim { my $s = shift; $s =~ s/^\s+|\s+$//g; return $s };

my @LINES;
my %ADDR;

# main
{
    open(IN,"<combined.txt") || die "Fatal: cannot open in file, $!";

    my $p1 = '^([[:xdigit:]]{4})\s{2} ((?:[[:xdigit:]]{2}\s){1,3}\s{1,7}) (\w{3}(?:\s\S+)?) (.*)';

    my $nr = 0;
    my $curr = 0; # the current address as converted from hex
    my $next = 0; # the next address as converted from hex base + the number of bytes
# ÿ
    while(<IN>) {
        if ( m/$p1/x) {
            my $base = trim($1);
            my $hex_val = hex($base);
            $curr = $hex_val;
            if ($next) { # if we have next defined, we should now actually be at next, if not complain as we have missing data in the file
                if( $next != $curr) {
                    print ";;ERR missing data curr: $curr should be next: $next\n";
                }
            }

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

        if ( m/^([[:xdigit:]]{4})((?:\s+[[:xdigit:]]{2})*)(.*)/x) {
            my $base = trim($1);
            my $hex_val = hex($base);
            $curr = $hex_val;
            if ($next) { # if we have next defined, we should now actually be at next, if not complain as we have missing data in the file
                if( $next != $curr) {
                    print ";;ERR missing data curr: $curr should be next: $next\n";
                }
            }

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
