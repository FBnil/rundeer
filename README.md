# RunDeer - run scripts remotely on Linux

Welcome to RunDeer, a script that basically runs the following lines:

```
# Wide open to Man-in-the-middle attacks by not verifying keys yourself!
# Ensure the remote server is in the known_hosts file
ssh-keygen -F $RSERVER 1>/dev/null || ssh-keyscan -t rsa,dsa  $RSERVER >> ~/.ssh/known_hosts
# pass the password through an environment variable (not visible through ps -ef)
export SSHPASS=mypassword
# run a single script remotely, log the output
sshpass -e ssh $RUSER@$RSERVER 'bash -s' < ./runthisremotely.sh | tee run.log
# or if it needs files to run, we push a directory, then run:
sshpass -e scp -r -C ./scriptsdir $RUSER@$RSERVER:
sshpass -e ssh -tC $RUSER@$RSERVER './script/runthisremotely.sh ;rm -r ./runthisremotely.sh' | tee run.log

```

It looks simple, why a script?

* most environments do not have sshpass
* sshpass does not work when the server is not in .ssh/known_hosts
* you might have different passwords for each and every server
* You might want to run in parallel
* you might want to have pre and post actions

So it comes with a companion script made in expect, but not everybody has expect, so there is a second companion script in perl, that still requires some CPAN libs.

## Unix Commands used 
In order to run rundeer, you will need to the following unix commands:

- bash
- ssh , scp
- sshpass // expect // perl+cpan
- ssh-keygen, ssh-keyscan
- Unix commands (echo, basename, mkdir, chmod, grep, stat, cut, head, read, export, touch, mv)
- cat /proc/cpuinfo


## How to install and use

untar and you are ready

## Configuration File

rundeer.cfg is the configuration file that needs to be in the same directory as your rundeer script.

`#` In case the user is different than your local username, you can set it here, 
`#` or give it from the commandline with ./rundeer -u $username
`#` You can also give it in the serverfile as:  $username,$remoteserver
```
RUSER=
```

```
# rundeer pushes files remotely before running them. The default (1) is to clean them up
# You can keep the files remotely with CLEANUP=0 or ./rundeer -k
# if you are afraid of deleting things when running as, say, root.
CLEANUP=1
```
```
# Here we select which companion script we will use to input our passwords
# You can select the expect script:
# SSHPASSBIN=./sshpass.exp
# Or the perl script:
# SSHPASSBIN=./sshpass.pl
# Or the official sshpass:
# SSHPASSBIN=/usr/bin/sshpass
# The default is empty and it will autodetect what is available:
SSHPASSBIN=
```
```
# This one is important if you want to keep a papertrail of what happened, 
# as evidence or for post-processing. 
# The files in OUTDIR will have the name $hostname.$scriptname
# I have nothing against relative paths, but, you know, better make it absolute.
OUTDIR=./report
```
```
# The default parameters for the scp command
P_SCP="-r -C"
```
```
# The default parameters for the ssh command
P_SSH="-tC"
```
## PASSWORD FILE ##

The first line is for a default password, keep it empty if you do not want a default password.
The other lines can be in the following 2 forms:
username,remoteserver=password
username=password

## COMPANION SCRIPTS ##

Read their source code if you want to learn more.

sshpass.exp requires "expect", a tcl derivate.

If you want, get to know it:

- [https://www.tcl.tk/about/history.html](https://www.tcl.tk/about/history.html)

Download files from:

- [https://core.tcl-lang.org/expect/index](https://core.tcl-lang.org/expect/index)

sshpass.pl requires **Expect.pm** and a whole bunch more of modules,
if you can get cpan working, it's: `cpan Expect` or download it from 
[https://metacpan.org/pod/release/RGIERSIG/Expect-1.15/Expect.pod](https://metacpan.org/pod/release/RGIERSIG/Expect-1.15/Expect.pod)

Unfortunately, it uses modules that need to be compiled, so ymmv.

## Hints

make aliases to items in the `./modules/` directory. This will allow you to ignore the `-m` setting and run without specifying the module.

```
% ln -s rundeer modules/hostname
% ./hostname -s localhost
```

## Testing / TODO

This software is still alpha.


## Links

*Still Todo*

## License

https://unlicense.org/
