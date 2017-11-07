#!/usr/bin/perl
use strict;
use warnings FATAL => 'all';

use Cwd;

my %loadedAliases;
my %loadedEnvironmentVariables;
my $homeDir = $ENV{"HOME"};

loadHushProfile();
runCommandLoop();

sub loadHushProfile {
    my $hushProfileFileName = $homeDir . "/.hush_profile";
    open (my $hushProfileFile, $hushProfileFileName);

    while (my $line = <$hushProfileFile>) {
        chomp($line);
        my ($left, $right) = split(/ = /, $line, 2);
        my ($keyType, $keyValue) = split(/ /, $left, 2);
        if ($keyType eq "alias") {
            $loadedAliases{$keyValue} = $right;
        } elsif ($keyType eq "set") {
            $loadedEnvironmentVariables{$keyValue} = $right;
            $ENV{$keyValue} = $right;
        }
    }
}

sub runCommandLoop {
    my $promptText;

    if (defined $ENV{"PROMPT"}) {
        $promptText = $ENV{"PROMPT"}
    } else {
        $promptText = "[hush:" . $$ . "]\$ ";
    }

    for (;;) {
        print $promptText;
        my $input = <STDIN>;
        chomp($input);
        my @inputArray = split(/ /, $input);

        my $command = shift @inputArray;
        my @arguments = @inputArray;

        if (lc ($command) eq "exit") {
            exit 0;
        } else {
            executeCommand($command, \@arguments, $input);
        }
    }
}

sub executeCommand {
    my ($command, $argumentsReference, $input) = @_;
    my @arguments = @{ $argumentsReference };

    if (lc ($command) eq "cd") {
        my $newDirectory = shift @arguments;
        chdir ($newDirectory) or warn $!;
        print("CWD: " . cwd . "\n");
    } elsif (lc ($command) eq "alias") {
        while (my ($key, $value) = each %loadedAliases) {
            print "Alias: " . $key . " = " . $value . "\n";
        }
    } elsif (lc ($command) eq "set") {

    } elsif (lc ($command) eq "last") {

    } elsif (lc ($command) eq "history") {

    } elsif (defined $loadedAliases{$command}) {
        my $unaliasedCommand = $loadedAliases{$command};
        my @inputArray = split(/ /, $input);
        shift @inputArray;
        unshift @inputArray, $unaliasedCommand;
        my $inputWithUnaliasedCommand = join(" ", @inputArray);
        executeCommand($unaliasedCommand, @arguments, $inputWithUnaliasedCommand);
    } else {
        executeNativeCommand($input);
    }

    logCommand($input);
}

sub executeNativeCommand {
    my ($input) = @_;
    my $pid = fork();
    if ($pid < 0) {
        print "Unable to use fork() function . \n";
        exit 0;
    } elsif ($pid > 0) {
        wait();
    } else {
        exec($input);
        exit 0;
    }
}

sub logCommand {
    my ($input) = @_;
    my $fileName = $homeDir . "/.hush_history";

    open my $historyFile, ">>", $fileName or warn "Could not write to" . $fileName . ": " . $! . "\n";

    print $historyFile $input . "\n";
}
