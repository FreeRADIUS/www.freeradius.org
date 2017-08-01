---
layout: post
title: "OpenSSL Heartbleed"
# date: 2014-04-08
categories: vul_in_deps
tags: security
---

[Heartbleed](http://heartbleed.com/) bug.

OpenSSL has a major security issue, seen in to
[CVE-2014-0160](http://cve.mitre.org/cgi-bin/cvename.cgi?name=CVE-2014-0160%0A).
The issue mainly affects servers such as SMTPS or HTTPS, which allow
random IP addresses to connect to them via TLS. Those sites must
assume that all information available to the system using TLS has
been compromised.

Based on further information from Jouni Malinen, it appears that
both Version 2 and Version 3 of FreeRADIUS are vulnerable to
the attack. It is likely that earlier versions of the server are
vulnerable, too.

The problem appears to be that OpenSSL has already allowed invalid
reads by the time that FreeRADIUS detects the invalid heartbeat, and
closes the connection. The benefit of the way FreeRADIUS uses
OpenSSL is that the attack appears to be limited to reading \~1K of
data from the stack, when the server receives the
malicious heartbeat. This limitation mitigates the attack, but does
not remove the possibility of exposing private information.

We recommend that all administrators upgrade OpenSSL immediately.

Administrators can detect "heartbleed" attacks by looking in their
logs for a message containing the text `Invalid ACK received: 24`.
If such a message is seen, it means that the attack has
been attempted. You should upgrade your version of
OpenSSL immediately.

We suggest that all administrators upgrade all of their systems to a
version of OpenSSL which is not vulnerable to this attack. Sites
which allow random IPs to connect to a TLS server (e.g. SMTPS
or HTTPS) should assume that all information available to those
servers has been stolen from those systems. This information
includes user credentials, keys for private certificates, cookies
sent over HTTPS, etc.

We have updated FreeRADIUS (all versions) so that it refuses to
start when it detects the vulnerable versions of OpenSSL.

**v3.0.x** - Administrators can over-ride this check by setting
`allow_vulnerable_openssl = CVE-2014-0160` in the `security`
subsection of radiusd.conf.

**v2.2.x** - Administrators can over-ride this check by setting
`allow_vulnerable_openssl = yes` in the `security` subsection
of radiusd.conf.

