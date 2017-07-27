---
layout: post
title: "Versions of OpenSSL are vulnerable to malformed certificates"
# date: 2012-04-19
categories: vul_in_deps
tags: security
---

The CVE notification is
[CVE-2012-2110](http://web.nvd.nist.gov/view/vuln/detail?vulnId=CVE-2012-2110).

We recommend all administrators using certificates with FreeRADIUS
upgrade their OpenSSL to a secure version. For details, see the
[OpenSSL notification](http://www.openssl.org/news/secadv_20120419.txt)

We emphasize that this is *not* a bug in FreeRADIUS. FreeRADIUS uses
OpenSSL for many of it's cryptographic operations, and as such, is
at the mercy of any problems in OpenSSL.

