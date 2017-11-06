#!/usr/bin/perl
use strict;
use warnings FATAL => 'all';

my $homeDir = $ENV{"HOME"};

my $file = $homeDir . "/.hush_profile";
open my $info, $file or die "Could not open $file: $!";

while (my $line = <$info>) {
    print $line;
}

my ($command, $inLine, $pid);
do {
    print "[hush:" . $$ . "]\$ ";
    $inLine = <STDIN>;
    chomp($inLine);
    # Insert code here to extract the 1st word of $inLine and store it in $command
    unless (lc($command) eq "exit") {
        executeLinuxCommand($inLine);
    }
} while (lc($command) ne "exit");

sub executeLinuxCommand {
    my $commandLine = shift(@_);
    $pid = fork();
    if ($pid < 0) {
        print "Unable to use fork() function . \n";
        exit 0;
    }
    elsif ($pid > 0) {# parent process will execute this branch of the if statement:
        wait();
    }
    else {
        # child process will execute this branch:
        exec($commandLine);
        exit 0; # Make absolutely SURE that child doesn’t get past this point!
    }
}
