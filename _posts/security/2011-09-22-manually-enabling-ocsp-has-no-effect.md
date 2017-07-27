---
layout: post
title: "Manually enabling OCSP has no effect"
# date: 2011-09-22
categories: vul_notifications
tags: security
---

This issue is applicable only to version 2.1.11.

The CVE notification is
[CVE-2011-2701](http://web.nvd.nist.gov/view/vuln/detail?vulnId=CVE-2011-2701).
The discoverer notified us and sent a patch.

The OCSP functionality in 2.1.11 could be enabled manually, but it
would never mark certificates as revoked. As such, it did not behave
as expected.

Since this issue requires manually enabling OCSP, it's severity
is low. The recommended solution is to upgrade to version 2.1.12.

