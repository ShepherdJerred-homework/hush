#!/usr/bin/perl
use strict;
use warnings FATAL => 'all';

my %aliases;
my %envVars;
my ($command, $inLine, $pid);
my $homeDir = $ENV{"HOME"};

getProfile();
runLoop();

sub getProfile {

    my $file = $homeDir . "/.hush_profile";
    open my $info, $file or die "Could not open $file: $!";

    # TODO Don't include end line when reading in
    while (my $line = <$info>) {
        my ($key, $value) = split(/ = /, $line, 2);
        my ($type, $typeValue) = split(/ /, $key, 2);
        if ($type eq "alias") {
            $aliases{$typeValue} = $value;
        }
        elsif ($type eq "set") {
            $envVars{$typeValue} = $value;
            $ENV{$typeValue} = $value;
            print $ENV{$typeValue};
        }
    }
}

sub runLoop {
    do {
        my $prompt;

        if (defined $ENV{"PROMPT"}) {
            $prompt = $ENV{"PROMPT"}
        }
        else {
            $prompt = "[hush:" . $$ . "]\$ ";
        }

        print $prompt;
        $inLine = <STDIN>;
        chomp($inLine);
        # Insert code here to extract the 1st word of $inLine and store it in $command
        # TODO Check for cd, alias, set, last, history
        unless (lc($command) eq "exit") {
            executeLinuxCommand($inLine);
            appendCommand($inLine);
        }
    } while (lc($command) ne "exit");
}

sub executeLinuxCommand {
    my $commandLine = shift(@_);
    $pid = fork();
    if ($pid < 0) {
        print "Unable to use fork() function . \n";
        exit 0;
    }
    elsif ($pid > 0) {
        # parent process will execute this branch of the if statement:
        wait();
    }
    else {
        # child process will execute this branch:
        exec($commandLine);
        # Make absolutely SURE that child doesn’t get past this point!
        exit 0;
    }
}

sub appendCommand {
    my $lastCommand = shift(@_);
    my $fileName = $homeDir . "/.hush_history";

    open my $historyFile, "<" ,$homeDir or die "Could not open $fileName: $!";

    print $historyFile $lastCommand . "\n";
}
