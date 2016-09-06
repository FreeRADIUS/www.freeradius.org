---
layout: post
title:  "Revoked intermediate certificates are not properly validated. oCert-CVE 2015-4680."
# date:   2015-09-18
categories: vul_in_deps
tags: security
---

Denis Andzakovic found issues with the decryption of very long Tunnel-Passwords. The decryption routines could walk off of the end of a buffer, and write to adjacent addresses. The data being written is not under control of an attacker. The end result is usually a crash of the server.

The initial report was for version 3.0. We determined that the v3.1.x branch in git is also vulnerable. Version 2 has similar code for Tunnel-Password, which we were not able to exploit. However, for safety, all currently supported versions of the server were fixed.

The packet decoder in FreeRADIUS ensures that the only time this issue is exploitable is when a proxy server receives a long Tunnel-Password attribute in the reply from a home server. The attack cannot be performed by a RADIUS client, or an end user. As such, the exploitability of the attack is limited to systems within the trusted RADIUS environment. We are releasing version 2.2.9 and version 3.0.10 to correct the issue.