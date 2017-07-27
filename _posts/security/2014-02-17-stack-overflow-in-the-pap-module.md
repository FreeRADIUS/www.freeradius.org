---
layout: post
title: "Stack overflow in the PAP module"
# date: 2014-02-17
categories: vul_notifications
tags: security
---

The CVE notification is
[CVE-2014-2015](http://cve.mitre.org/cgi-bin/cvename.cgi?name=CVE-2014-2015)

The PAP module takes a "known good" password (e.g. Crypt-Password),
and compares it to the password entered by the user (e.g.
User-Password). In cases where the "known good" password was very
long, insufficient input validation was performed. An administrator
who controlled the password store could enter long passwords, and
cause the server to crash.

