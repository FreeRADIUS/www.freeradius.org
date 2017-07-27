---
layout: post
title: "Crash upon receipt of Tunnel-Password attribute"
# date: 2003-10-15
categories: vul_notifications
tags: security
---

Anyone who can send packets to the server can crash it by sending a
Tunnel-Password attribute in an Access-Request packet. This vulnerability
is not otherwise exploitable. We have released 0.9.3 to correct
this vulnerability.

