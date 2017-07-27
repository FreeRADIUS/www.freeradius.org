---
layout: post
title: "Apple Mac OS X server misconfiguration"
# date: 2010-02-03
categories: vul_notifications
tags: security
---

[CVE-2010-0524](http://web.nvd.nist.gov/view/vuln/detail?vulnId=CVE-2010-0524) -
This issue only affects Mac OS X Server systems.

Apple had apparently configured FreeRADIUS to accept all "well
known" Certificate Authorities as valid for EAP-TLS. This
configuration permitted almost anyone to create a client certificate
for use with EAP-TLS, which would then be accepted by Mac OS X
Server systems.

We recommend that the list of Certificate Authorities configured in
FreeRADIUS be audited, and kept as small as possible.

