---
layout: post
title: "Unix module allows expired passwords"
# date: 2012-11-10
categories: vul_notifications
tags: security
---

The CVE notification is
[CVE-2011-4966](http://cve.mitre.org/cgi-bin/cvename.cgi?name=CVE-2011-4966).

It was found that the "unix" module ignored the password expiration
setting in "/etc/shadow". The default configuration does not use the
"unix" module, so there is no issue for most deployments. However,
if the server was configured to use this module for authentication,
users with an expired password could successfully authenticate, even
though their access should have been denied. We recommend managing
users in a database, instead of leveraging /etc/passwd. The fact
that a user has login access to a machine does not necessarily mean
that they can use RADIUS for other kinds of network access.

