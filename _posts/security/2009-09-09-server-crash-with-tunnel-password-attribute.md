---
layout: post
title: "Server crash with Tunnel-Password attribute"
# date: 2009-09-09
categories: vul_notifications
tags: security
---

Anyone who can send packets to the server can crash it by sending
a Tunnel-Password attribute in an Access-Request packet. This
vulnerability is not otherwise exploitable. We have released 1.1.8
to correct this vulnerability.

This issue is similar to the previous Tunnel-Password issue
noted below. The vulnerable versions are 1.1.3 through 1.1.7.
Version 2.x is not affected.

