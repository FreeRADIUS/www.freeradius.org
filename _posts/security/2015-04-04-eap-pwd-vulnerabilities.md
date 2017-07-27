---
layout: post
title: "EAP-PWD Vulnerabilities"
# date: 2015-04-04
categories: vul_notifications
tags: security
---

The EAP-PWD module performed insufficient validation on packets
received from an EAP peer. This module is *not* enabled in the
default configuration. Administrators must manually enable it for
their server to be vulnerable. Only versions 3.0 up to 3.0.8
are affected.

These issues were found by Jouni Malinen as part of investigating
[2015-4](http://w1.fi/security/2015-4/) for HostAP.

-   The EAP-PWD packet length is not checked before the first byte
    is dereferenced. A zero-length EAP-PWD packet will cause the
    module to dereference a NULL pointer, and will cause the server
    to crash.
-   The commit message payload length is not validated before the
    packet is decoded. This can result in a read overflow in
    the server.
-   The confirm message payload length is not validated before the
    packet is decoded. This can result in a read overflow in
    the server.
-   A strcpy() was used to pack a C string into an EAP-PWD packet.
    This would result in an over-run of the destination buffer by
    one byte.

