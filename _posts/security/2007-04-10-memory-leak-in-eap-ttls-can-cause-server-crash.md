---
layout: post
title: "Memory leak in EAP-TTLS can cause server crash"
# date: 2007-04-10
categories: vul_notifications
tags: security
---

This issue affects version 1.1.5 and earlier.

A malicous 802.1x supplicant could send malformed Diameter format
attributes inside of an EAP-TTLS tunnel. The server would reject the
authentication request, but would leak one `VALUE_PAIR` data
structure, of approximately 300 bytes. If an attacker performed the
attack many times (e.g. thousands or more over a period of minutes
to hours), the server could leak megabytes of memory, potentially
leading to an "out of memory" condition, and early process exit.

We recommend that administrators using EAP-TTLS upgrade immediately.

This bug was found as part of the
[Coverity](http://www.coverity.com/)
[Scan](http://scan.coverity.com) project.

