#!perl

use strict;
use warnings;

open my $fh, "<", "publicsuffix.dat";

my $tree = {};

while (<$fh>) {
	chomp;
	next if m{^//};
	next if /^\s+$/;
	next if /[^a-z\.]/; # skipping non latin1 domains
	my @parts = reverse split /\./, $_;
	my $head = $tree;
	for my $p (@parts) {
		if ( ! $head->{$p} ) {
			$head->{$p} = {};
		}
		$head = $head->{$p};
	}
}

use Data::Dumper;

my $res = <<EOF;
-module(publicsuffix).

-export([suffix/1, domain/1]).

%% This is autogenerated by script from 
%% http://mxr.mozilla.org/mozilla-central/source/netwerk/dns/effective_tld_names.dat?raw=1

suffix(Domain) ->
	Parts = lists:reverse(string:tokens(Domain, ".")),
	[First | Rest] = Parts,
	parts(First, Rest).

domain(Domain) ->
	Suffix = suffix(Domain),
	case Suffix == Domain of 
		true ->
    		Domain;
    	false ->
		    Subdomains = string:tokens(string:sub_string(Domain, 1, string:rstr(Domain, Suffix) - 2), "."),
		    Subdomain = lists:last(Subdomains),
		    Subdomain ++ "." ++ Suffix
	end.

EOF

my $subres;

for (keys %$tree) {
	if ( %{$tree->{$_}} ) {
        $res .= <<EOF;
parts("$_", []) ->
    undefined;
parts("$_", Parts) ->
   [First | Rest] = Parts,
   $_(First, Rest);	
EOF
	} else {
	    $res .= <<EOF;
parts("$_", _Any) ->
    "$_";
EOF
	}
	
	my $head = $tree->{$_};
	if ( %$head ) {
		$subres .= generate_for_node($_, $head);
	}
}

$res .= <<EOF;
parts(First, _) ->
	First;

EOF

$res =~ s/(;)\s+$/./; ## closing fun cases
$res .= $subres;

sub generate_for_node {
	my ($name, $head) = @_;
	my $res;
	## getting exception rules first
	my $tmp;
	(my $fun_name = $name) =~ s/[\.\-]/_/g;
	for my $k ( keys %$head ) {
		if ($k =~ /^!/) {
			$k =~ s/!//;
			$tmp .= <<EOF;
$fun_name("$k", _Parts) ->
    "$name";
EOF
		}
	}
	if ( $tmp ) {
		$res .= "\n\n    %% exception rules\n";
		$res .= $tmp; 
	}

	$tmp = '';
	for my $k1 ( keys %$head ) {
		(my $k1_fun = $k1) =~ s/-/_/g;
		if ($k1 !~ /^!/ and $k1 ne '*' ) {
			if ( %{$head->{$k1}} ) {
			    $tmp .= <<EOF;
$fun_name("$k1", []) ->
    "$k1.$name";
$fun_name("$k1", Parts) ->
    [First | Rest] = Parts,
    ${k1_fun}_$fun_name(First, Rest);

EOF
	        } else {
		        $tmp .= <<EOF;
$fun_name("$k1", _Any) ->
    "$k1.$name";

EOF
	        }
	    }
	}
	if ( $tmp ) {
		$res .= "\n\n%% regular rules\n";
		$res .= $tmp;
		$res .= "\n$fun_name(_, _) ->\n    \"$name\"; ";
	}

	if ( $head->{"*"} ) {
		$res .= <<EOF;
%% star rule
$fun_name(Any, _Parts) ->
    Any ++ ".$name";
EOF
	}
 

	$res =~ s/(;)\s+$/./; ## closing fun cases

	## collecting subrules
	my $subrules;
	for my $k2 ( keys %$head ) {
		if ( $k2 !~ /^!/ and $k2 ne '*' and keys %{$head->{$k2}} ) {
			$subrules .= generate_for_node($k2.".".$name, $head->{$k2});
		}
	}
	if ( $subrules ) {
		$res .= $subrules;
	}

	return $res;
}


$res .= <<EOF;

-ifdef(TEST).
-include_lib("eunit/include/eunit.hrl").

rules_test() ->
	?assertEqual(publicsuffix:domain("google.com"), "google.com"),
	?assertEqual(publicsuffix:domain("fr.google.com"), "google.com"),
	?assertEqual(publicsuffix:domain("fr.google.google"), "google.google"),
	?assertEqual(publicsuffix:domain("foo.google.co.uk"), "google.co.uk"),
	?assertEqual(publicsuffix:domain("t.co"), "t.co"),
	?assertEqual(publicsuffix:domain("fr.t.co"), "t.co").

-endif.

EOF

print $res;