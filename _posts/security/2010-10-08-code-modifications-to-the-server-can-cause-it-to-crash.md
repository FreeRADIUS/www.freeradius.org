---
layout: post
title: "Code modifications to the server can cause it to crash"
# date: 2010-10-08
categories: vul_notifications
tags: security
---

This issue is applicable only to version 2.1.9.

The CVE notification is
[CVE-2010-3696](http://web.nvd.nist.gov/view/vuln/detail?vulnId=CVE-2010-3696).

The issuer did not communicate with us before releasing the alleged vulnerability,
and we disagree with their description of the problem.

The DHCP functionality in 2.1.9 is *not* enabled by default.
Enabling it requires code modifications, a complete re-build and
re-install of the server, and a manual enabling of DHCP in
the configuration. Further, the DHCP functionality is marked
"experimental" in this release. As such, it should be used only on
trusted networks.

This issue is exploitable whenever FreeRADIUS has had DHCP
functionality enabled, and where the administrator has manually
configured the server to accept DHCP packets. Any DHCP packet with a
"Relay Agent" sub-option can cause FreeRADIUS to enter an
infinite loop.

Our recommendation is to run experimental features only in
trusted networks.

