publicsuffix_erlang
===================

This repository contains Perl script and ready to use Erlang module.

Perl script can be used to generate up-to-date module from ruleset:
http://mxr.mozilla.org/mozilla-central/source/netwerk/dns/effective_tld_names.dat?raw=1

More information:
http://publicsuffix.org/learn/

If you don't want to generate Erlang module yourself, feel free to use one from the repository.

Usage:

publicsuffix:domain("www.google.co.uk"). %% google.co.uk
publicsuffix:suffix("www.google.co.uk"). %% co.uk
