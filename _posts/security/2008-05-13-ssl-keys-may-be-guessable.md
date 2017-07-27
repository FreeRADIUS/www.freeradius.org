---
layout: post
title: "SSL keys may be guessable"
# date: 2008-05-13
categories: vul_in_deps
tags: security
---

A bug added to OpenSSL on
[Debian](http://lists.debian.org/debian-security-announce/2008/msg00152.html)
and
[Ubuntu](https://lists.ubuntu.com/archives/ubuntu-security-announce/2008-May/000705.html)
systems means that SSL keys on those systems may be guessable.

We recommend that administrators using OpenSSL on Debian or Ubuntu
upgrade immediately. We also recommend re-generating any SSL
certificates used in RADIUS systems, if those certificates were
created on a Debian or Ubuntu system since 2006.

We emphasize that this is *not* a bug in FreeRADIUS. FreeRADIUS uses
OpenSSL for many of it's cryptographic operations, and as such, is
at the mercy of any problems in OpenSSL.

