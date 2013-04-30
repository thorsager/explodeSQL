#!/usr/bin/perl
###############################################################################
# Copyright (c) 2013, Michael Thorsager <thorsager@gmail.com>
# All rights reserved.
#
# Redistribution and use in source and binary forms, with or without modification,
# are permitted provided that the following conditions are met:
#
#  * Redistributions of source code must retain the above copyright notice, this
#    list of conditions and the following disclaimer.
#
#  * Redistributions in binary form must reproduce the above copyright notice, this
#    list of conditions and the following disclaimer in the documentation and/or
#    other materials provided with the distribution.
#
#  * Neither the name of Open Solutions nor the names of its contributors may be
#    used to endorse or promote products derived from this software without
#    specific prior written permission.
#
# THIS SOFTWARE IS PROVIDED BY THE COPYRIGHT HOLDERS AND CONTRIBUTORS "AS IS" AND
# ANY EXPRESS OR IMPLIED WARRANTIES, INCLUDING, BUT NOT LIMITED TO, THE IMPLIED
# WARRANTIES OF MERCHANTABILITY AND FITNESS FOR A PARTICULAR PURPOSE ARE DISCLAIMED.
# IN NO EVENT SHALL THE COPYRIGHT HOLDER OR CONTRIBUTORS BE LIABLE FOR ANY DIRECT,
# INDIRECT, INCIDENTAL, SPECIAL, EXEMPLARY, OR CONSEQUENTIAL DAMAGES (INCLUDING,
# BUT NOT LIMITED TO, PROCUREMENT OF SUBSTITUTE GOODS OR SERVICES; LOSS OF USE,
# DATA, OR PROFITS; OR BUSINESS INTERRUPTION) HOWEVER CAUSED AND ON ANY THEORY OF
# LIABILITY, WHETHER IN CONTRACT, STRICT LIABILITY, OR TORT (INCLUDING NEGLIGENCE
# OR OTHERWISE) ARISING IN ANY WAY OUT OF THE USE OF THIS SOFTWARE, EVEN IF ADVISED
# OF THE POSSIBILITY OF SUCH DAMAGE.
###############################################################################
use strict;
use warnings;
use FindBin::Real qw/Script/;
##############################################################################
sub parseLine($);
sub expandLine($);
sub trim($);
sub _fillTemplate($$);
##############################################################################
my %SPECIAL; ## Holds special Variables
my %VARS; ## Holds Variables
my @TMPL; ## Holds Template 
my @KEYWORDS = qw/delimiter/;
##############################################################################
my $inputFile = shift;

if (!$inputFile) {
	print "USAGE: ".Script()." <inputFile>\n";
	exit 2;
}

open(FILE,$inputFile) || die("Unable to open '$inputFile': $!");
my @inputData=<FILE>;
close(FILE);
chomp(@inputData);

## set up environment
foreach my $line (@inputData) {
	last if parseLine($line); 
}

foreach my $line (@inputData) {
	next if ( $line =~ m/^$/ || $line =~ m/^[%#].*$/ );
	print join("\n",expandLine($line))."\n";
}


##############################################################################
sub expandLine($)
{
	my $line = shift;
	my %context;

	my @cols = split(/$SPECIAL{'delimiter'}/,$line);
	for (my $i=0;$i<=$#cols;$i++) {
		$context{"\$\{$i\}"} = $cols[$i];
	}
	foreach my $k (keys %VARS) {
		$context{"\$\{$k\}"} = $VARS{$k};
	}
	return _fillTemplate(\@TMPL,\%context);
}
##############################################################################
sub _fillTemplate($$)
{
	my $tref = shift;
	my $cref = shift;
	my @expanded;
	foreach my $tl ( @$tref ) {
		my $el = $tl;
		foreach my $k ( keys %$cref ) {
			my $v = $cref->{$k};
			$el=~s/\Q$k/$v/g;
		}
		push(@expanded,$el);
	}
	return @expanded;
}
##############################################################################
sub parseLine($) 
{
	my $line = shift;

	# Skip non-meta lines
	return undef if ($line !~ m/^%.*$/);

	# end of meta found
	return 1 if ($line =~ m/^%end.*$/);

	my ($thing,$data) = ( $line =~ /^\%(\w+):?\s+?(.*)$/ )[0,1];

	if ( lc($thing) eq 'tmpl'  ) {
		## Tmplate line
		push(@TMPL, $data );
	} elsif ( lc($thing) eq 'var' ) {
		## VARIABLE
		my ($name,$value) = ( $data =~ /^(\w+)\s+?=(.*)$/ )[0,1];
		$name = lc($name);
		if ( grep(/^$name$/,@KEYWORDS) ) {
			$SPECIAL{$name}=trim($value);
		} else {
			$VARS{$name}=trim($value);
		}
	} 
	return undef;
}

sub trim($)
{
	my $str = shift;
	for ($str) { s/^\s*//; s/\s*$//; }
	return $str;
}
