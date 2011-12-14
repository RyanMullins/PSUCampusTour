#! /usr/bin/perl -w
# This script creates a KML file filled with hexagons 

use strict;
use warnings;
use Math::Trig;

# File Parameters
open(STDOUT, "> hexagons.kml") or
	die "Unable to redirect STDOUT to hexagons.kml";

# Static variables for manipulation
my $radius = 0.0113703/3;
my $rCosTheta = $radius * cos(deg2rad(60));
my $rSinTheta = $radius * sin(deg2rad(60));

# Print the header info
print "<?xml version=\"1.0\" encoding=\"UTF-8\"?>\n";
print "<kml xmlns=\"http://www.opengis.net/kml/2.2\">\n";
print "<Document>\n";
print "<Style id=\"transBluePoly\">\n";
print "    <LineStyle>\n";
print "        <width>4</width>\n";
print "    </LineStyle>\n";
print "    <PolyStyle>\n";
print "        <color>7dff0000</color>\n";
print "    </PolyStyle>\n";
print "</Style>\n";

my $count = 1;
while (<>) {
	my @centers = split(' ', $_);
	
	foreach my $center (@centers) {
		chomp($center);
		my @latlon = split(",", $center);	# lat = [0] lon = [1] 
		my $lat = $latlon[0];
		my $lon = $latlon[1];
		
		my @p1 = (($lat + $rSinTheta), ($lon + $rCosTheta));
		my @p2 = (($lat), ($lon + $radius));
		my @p3 = (($lat - $rSinTheta), ($lon + $rCosTheta));
		my @p4 = (($lat - $rSinTheta), ($lon - $rCosTheta));
		my @p5 = (($lat), ($lon - $radius));
		my @p6 = (($lat + $rSinTheta), ($lon - $rCosTheta));
		
		print "<Placemark>\n";
		print "    <name>Hexagon$count</name>\n";
		print "    <styleUrl>#transBluePoly</styleUrl>\n";
		print "    <Polygon>\n";
		print "        <altitudeMode>clampToGround</altitudeMode>\n";
		print "        <outerBoundaryIs><LinearRing><coordinates>\n";
		print "            $p1[1],$p1[0] $p2[1],$p2[0] $p3[1],$p3[0] $p4[1],$p4[0] $p5[1],$p5[0] $p6[1],$p6[0] $p1[1],$p1[0]\n";
		print "        </coordinates></LinearRing></outerBoundaryIs>\n";
		print "    </Polygon>\n";
		print "</Placemark>\n";
		$count++;
	}
}

print "</Document>";
print "</kml>";

close(STDOUT);
