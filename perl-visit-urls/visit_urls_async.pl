#!/usr/bin/env perl
use Modern::Perl;
use autodie;
use warnings;

use threads;
use Thread::Queue qw/ /;
use Getopt::Long;
use LWP::Simple;
use Benchmark;

my $numThreads = 4;
my $logFile = undef;
GetOptions(
	"threads=i" => \$numThreads,
	"logfile=s" => \$logFile
);

# Open logfile is not undefined
open (STDOUT, '>>', $logFile) or die 'cant open logfile' if defined $logFile;
say '=== UPDATE START ===';

# visit url and log results
sub visit_url {
	my ($url) = @_;

	sub logStatus {
		my $message = shift;
		my $id = threads->tid();
		say "<thread $id:" . localtime() . ">\t$message";
	}

	my $contents = get($url);
	if (!$contents || length ($contents) == 0) {
		logStatus "[SUCCESS] $url";
	}
	else {
		logStatus "[FAILURE] $url";
	}
}

{
	my $q = Thread::Queue->new();
	my @threads;

	for (1..$numThreads) {
		push @threads, async {
			while (my $url = $q->dequeue()) {
				visit_url($url);
			}
		};
	}

	while (<>) {
		chomp;
		next if /^\s*$/;
		$q->enqueue($_);
	}

	# clear threads
	$q->enqueue(undef) for 1..$numThreads;
	$_->join() foreach @threads;
}

say '=== UPDATE END ===';
say '';