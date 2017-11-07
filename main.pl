#!/usr/bin/perl
use strict;
use warnings FATAL => 'all';

my %loadedAliases;
my %loadedEnvironmentVariables;
my $homeDir = $ENV{"HOME"};

loadHushProfile();
runCommandLoop();

sub loadHushProfile {
    my $hushProfileFileName = $homeDir . "/.hush_profile";
    open my $hushProfileFile, $hushProfileFileName or die "Could not open $hushProfileFileName: $!";

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

        if (lc ($command) eq "exit") {
            exit 0;
        } else {
            executeCommand($command, $input);
        }
    }
}

sub executeCommand {
    my ($command, $input) = @_;

    if (lc ($command) eq "cd") {

    } elsif (lc ($command) eq "alias") {
        while (my ($key, $value) = each %loadedAliases) {
            print "Alias: " . $key . " = " . $value . "\n";
        }
    } elsif (lc ($command) eq "set") {

    } elsif (lc ($command) eq "last") {

    } elsif (lc ($command) eq "history") {

    } elsif (defined $loadedAliases{$command}) {
        executeCommand($loadedAliases{$command});
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

    open my $historyFile, ">>", $fileName or die "Could not open $fileName: $!";

    print $historyFile $input . "\n";
}
