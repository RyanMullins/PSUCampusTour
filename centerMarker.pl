#! /usr/bin/perl -w

use strict;
use warnings;
use Math::Trig;

open(STDOUT, "> centers.txt") or 
	die "Unable to redirect STDOUT to centers.txt";
	
my $radius = 0.011373/3;
my $rSinTheta = $radius * sin(deg2rad(60));
my $root3RSinTheta = sqrt(3) * $rSinTheta;
my $twiceRSinTheta = 2 * $rSinTheta;

my $coords = <STDIN>;
my @center = split(",", $coords);

my @center1 = (($center[0] + $twiceRSinTheta), ($center[1]));
my @center2 = (($center[0] + $rSinTheta), ($center[1] + $root3RSinTheta));
my @center3 = (($center[0] - $rSinTheta), ($center[1] + $root3RSinTheta));
my @center4 = (($center[0] - $twiceRSinTheta), ($center[1]));
my @center5 = (($center[0] - $rSinTheta), ($center[1] - $root3RSinTheta));
my @center6 = (($center[0] + $rSinTheta), ($center[1] - $root3RSinTheta));

print "1: $center1[0],$center1[1]\n";
print "2: $center2[0],$center2[1]\n"; 
print "3: $center3[0],$center3[1]\n";
print "4: $center4[0],$center4[1]\n";
print "5: $center5[0],$center5[1]\n";
print "6: $center6[0],$center6[1]\n";

close(STDOUT);
