---
layout: post
title: "Overflow in EAP-TLS"
# date: 2012-09-10
categories: vul_notifications
tags: security
---

The CVE notification is
[CVE-2012-3547](http://cve.mitre.org/cgi-bin/cvename.cgi?name=CVE-2012-3547).
The issue was found by Timo Warns, and communicated
to security@freeradius.org. A sample exploit for the issue was
included in the notification.

We recommend all administrators using EAP and 2.1.10, 2.1.11,
2.1.12, or the git "master' branch upgrade immediately.

The vulnerability was created in [commit
a368a6f4f4aaf](https://github.com/FreERADIUS/freeradius-server/commit/a368a6f4f4aaf)
on August 18, 2010. Vulnerable versions include 2.1.10, 2.1.11, and
2.1.12. Also anyone running the git "master" branch after August 18,
2010 is vulnerable.

All sites using TLS-based EAP methods and the above versions
are vulnerable. The only configuration change which can avoid the
issue is to disable EAP-TLS, EAP-TTLS, and PEAP.

An external attacker can use this vulnerability to over-write the
stack frame of the RADIUS server, and cause it to crash. In
addition, more sophisticated attacks may gain additional privileges
on the system running the RADIUS server.

This attack does not require local network access to the
RADIUS server. It can be done by an attacker through a WiFi Access
Point, so long as the Access Point is configured to use 802.1X
authentication with the RADIUS server.

We scanned the rlm\_eap\_tls.c file with the LLVM checker-267, taken
from http://clang-analyzer.llvm.org/. It did not find this issue.
However, a Coverity scan did discover it.

