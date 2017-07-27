---
layout: post
title: "Insufficient input validation in MS-CHAP"
# date: 2006-03-20
categories: vul_notifications
tags: security
---

A validation issue exists with the EAP-MSCHAPv2 module in all versions
from 1.0.0 (where the module first appeared) to 1.1.0. Insufficient
input validation was being done in the EAP-MSCHAPv2 state machine. A
malicious attacker could manipulate their EAP-MSCHAPv2 client state
machine to potentially convince the server to bypass
authentication checks. This bypassing could also result in the
server crashing. We recommend that administrators
upgrade immediately.

