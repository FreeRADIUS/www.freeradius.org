---
layout: post
title: "FreeRADIUS may crash if database goes down"
# date: 2010-10-08
categories: vul_notifications
tags: security
---

If FreeRADIUS depends on a database, and the database goes down for
extended periods, the server may crash. This issue applies to versions
2.0.0 through 2.1.9. This issue is not externally exploitable.

The CVE notification is
[CVE-2010-3697](http://web.nvd.nist.gov/view/vuln/detail?vulnId=CVE-2010-3697).

As with many such notifications, the issuer did not communicate with
us before releasing the alleged vulnerability. We also disagree with
their description of the problem.

The short description of this problem is that any administrator who
can (a) take the database down, or (b) disrupt communication between
FreeRADIUS and the database can prevent FreeRADIUS from
operating correctly. This result should not be a surprise.

In normal operation, when the server stops responding to
packets (i.e. because the database is down), the NAS will stop
sending it packets, and will fail over to another server. In
addition, our tests indicate that this issue occurs only when the
database is down for extended periods of time, and the server
receives many millions of packets during that time. i.e. the problem
will not occur in most deployments.

There is no possibility for privilege escalation, or access to the
system running FreeRADIUS. The issue is marked "network exploitable"
in the CVE database because it requires the network to be *down* for
the attack to work.

Our recommendation is to upgrade to the latest version of the
server. We also recommend that mission-critical systems
be monitored. If they go offline for extended periods, they should
be restarted.

