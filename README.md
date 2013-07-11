publicsuffix_erlang
===================

This repository contains Perl script and ready to use Erlang module.



Information
-----------

Perl script can be used to generate up-to-date module from ruleset:
http://mxr.mozilla.org/mozilla-central/source/netwerk/dns/effective_tld_names.dat?raw=1

http://publicsuffix.org/learn/

If you don't want to generate Erlang module yourself, feel free to use one from the repository.

Usage
-----

To get domain part:

    publicsuffix:domain("www.google.co.uk"). %% google.co.uk
    
To get public suffix:  

    publicsuffix:suffix("www.google.co.uk"). %% co.uk
