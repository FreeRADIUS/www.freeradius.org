---
layout: post
title: "Bash (Shellshock)"
# date: 2014-09-24
categories: vul_notifications
tags: security
---

[Shellshock](http://en.wikipedia.org/wiki/Shellshock_(software_bug)) bug.

Systems running FreeRADIUS *may be* vulnerable to this bug. The
default configuration does not execute any external programs or
shell scripts. However, administrators who have configured the
server to execute shell scripts **must** upgrade their version of
`bash` to a version which is not vulnerable.

