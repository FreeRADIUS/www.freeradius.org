---
layout: post
title: "Stack overflow in rlm_smb means admins can write to server config"
# date: 2007-01-02
categories: vul_notifications
tags: security
---

[SMB\_Handle\_Type SMB\_Connect\_Server](http://www.securityfocus.com/archive/1/archive/1/455678/100/0/threaded).

While the summary is superficially correct, and there is a stack
overflow in rlm\_smb, the issue is [less
problematic](http://www.securityfocus.com/archive/1/455812/100/0/threaded)
than it sounds.

[CVE-2007-0080](http://cve.mitre.org/cgi-bin/cvename.cgi?name=2007-0080)
has been updated with our statement.

[SecurityTracker Alert ID: 1017463](http://securitytracker.com/alerts/2007/Jan/1017463.html)
has been updated with our statement.

[freeradius-smbconnectserver-bo (31248)](http://xforce.iss.net/xforce/xfdb/31248)
has been updated to no longer claim the issue is
remotely exploitable. They do not, however, include our [vendor
statement](https://lists.freeradius.org/pipermail/freeradius-devel/2007-January/010717.html),
though they do reference it. They also list the issue as "High
Risk", and "Gain Privileges", which is *NOT TRUE*, for the reasons
outlined below.

In summary, the issue is *not remotely exploitable*. It is
exploitable by local administrators who have write access to the
server configuration files. If an attacker can write to the server
configuration files, they can configure the server to run
arbitrary programs. Exploiting the server via a stack overflow would
be unnecessary.

The solution to this "vulnerability", of course, is to ensure that
only the correct people are given write access to the server
configuration files.

