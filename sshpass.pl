#!/usr/bin/perl

use Expect;

my $USAGE="sshpass.ext <command and params>\nYou also need exported environment variables: SSHPASS\n";

my $lepassword = $ENV{SSHPASS} || die $USAGE;

my $timeout = $ENV{TIMEOUT} || 30;
my $ledebug = $ENV{DEBUG} || 0;
my $leverbose= $ENV{VERBOSE} || $ENV{DEBUG} || 0;

die $USAGE if($#ARGV eq -1);

my $cmd = shift @ARGV;
my @arguments = @ARGV;

if($ledebug) {
	print "# DEBUG: Running $cmd @arguments\n"
}


# Create an Expect object
$exp = Expect->new;

# To disable echo:
#$exp->raw_pty(1);
#$exp->slave->stty(qw(-echo));
# sleep 1; # only for old IO-Tty

# Spawn another process
$exp->spawn($cmd, @arguments)
  or die "Cannot spawn $cmd: $!\n";
print "spawn $cmd @arguments\n" if $leverbose;

# Deep debugging
#$Expect::Exp_Internal = 1;
#$exp->debug(2);

my $has_stdin=0; # to know if we need to send CTRL+D
my $passworded=0;

$exp->expect($timeout,
    [ qr/continue connecting \(yes\/no\)\?.*/ => sub { my $xp = shift;
        print "READ: continue\n" if $ledebug;
        $xp->send("yes\n");
        exp_continue; } ],
    [ qr/.*to the list of known hosts.*$/ => sub { my $xp = shift;
        print "READ: added to the list.\n" if $ledebug;
        exp_continue; } ],
	[ qr/.*assword:.*/ => sub { my $exp = shift;
		print "READ: password_field\n" if $ledebug;
		$exp->send("$lepassword\n");
        $passworded=1;
		exp_continue; } ],
	[ qr/\r\n?/ => sub { my $exp = shift;
		print "READ: enters. cmd=$cmd passworded=$passworded\n" if $ledebug;
        if ($passworded == 0){
            # Not passworded yet, looping back
            exp_continue;
        }else{
		    return 1 if($cmd=~/scp/); # skip the rest when using scp
	    	$SIG{ALRM} = sub { die 'STDIN' }; # there is no -s STDIN !
    		eval {
			    alarm(1);
		    	while (my $l =<STDIN>){
	    			print "SENDING $l for execution\n" if $ledebug;
    				alarm(0); # disable alarm, we have input in STDIN
				    $exp->send($l);
			    	++$has_stdin;
		    	}
	    		alarm(0);
    		};
		    print "no STDIN\n" if $@ =~ /STDIN/ && $ledebug;

	    	#print "Sending CTRL+D\n" if $ledebug;
    		# Send Ctrl+D
		    print "has_stdin=$has_stdin\n" if $ledebug;
	    	$exp->send("\cD") if $has_stdin;
    		#exp_continue;
        }
	}],
              [
               eof =>
               sub {
                 if ($spawn_ok) {
                   die "ERROR: EOF: premature EOF in login.\n";
                 } else {
                   die "ERROR: EOF: could not spawn.\n";
                 }
               }
              ],
             [
              timeout =>
              sub {
                die "No login.\n";
              }
             ],
#             '-re', qr'[#>:] $', #' wait for shell prompt, then exit expect

		
);

# if no longer needed, do a soft_close to nicely shut down
$exp->soft_close();

exit 0;
