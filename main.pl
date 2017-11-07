#!/usr/bin/perl
use strict;
use warnings FATAL => 'all';

use Cwd;

my %loadedAliases;
my %loadedEnvironmentVariables;
my $homeDir = $ENV{"HOME"};

# Set env variables
$ENV{"LWD"} = cwd;
$ENV{"CWD"} = cwd;

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
        changeDirectory($newDirectory);

    } elsif (lc ($command) eq "alias") {
        foreach my $key (sort keys %loadedAliases) {
            print "Alias: " . $key . " = " . $loadedAliases{$key} . "\n";
        }
    } elsif (lc ($command) eq "set") {
        foreach my $key (sort keys %loadedEnvironmentVariables) {
            print "Set: " . $key . " = " . $loadedEnvironmentVariables{$key} . "\n";
        }
    } elsif (lc ($command) eq "last") {
        changeDirectory($ENV{"LWD"});
    } elsif (lc ($command) eq "history") {
        my $hushHistoryFileName = $homeDir . "/.hush_history";
        open (my $hushHistoryFile, $hushHistoryFileName) or warn "Could not open " . $hushHistoryFileName .  "\n";

        my $lineNumber = 0;
        while (my $line = <$hushHistoryFile>) {
            print $lineNumber . "    " . $line;
            $lineNumber++;
        }
    } elsif (defined $loadedAliases{$command}) {
        my $unaliasedCommand = $loadedAliases{$command};
        my @inputArray = split(/ /, $input);
        shift @inputArray;
        unshift @inputArray, $unaliasedCommand;
        my $inputWithUnaliasedCommand = join(" ", @inputArray);
        executeCommand($unaliasedCommand, \@arguments, $inputWithUnaliasedCommand);
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

sub changeDirectory {
    my ($newDirectory) = @_;
    my $lastDirectory = cwd;
    my $success = chdir ($newDirectory) or warn $!;
    if ($success) {
        print("CWD: " . cwd . "\n");
        $ENV{"CWD"} = cwd;
        $ENV{"LWD"} = $lastDirectory;
    }
}
