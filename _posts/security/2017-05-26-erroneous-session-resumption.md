---
layout: post
title: "Erroneous Session Resumption"
# date: 2017-05-26
categories: vul_notifications
tags: security
---

We discovered that the server could be convinced to permit TLS
session resumption before the authentication finished. A partial fix
was put into 3.0.13. Pavel Kankovsky verified that the fix was
insufficient, and provided a tool to test the issue. A better fix
was put into the server, and was released in version 3.0.14.

The original EAP-TLS code would refuse to resume sessions unless
there were policy attributes in the session cache. This check was
put in place to work around this issue with the OpenSSL API. At some
point, the code was changed to cache policy attributes by default,
which opened up the vulnerability. Given the long history of the
server, it is not clear when that change was made.

**FIX:** The short-term fix is to disable session resumption in the
`cache` subsection of the `eap` module.

We believe that this issue affects version 2.1.1 through
2.1.7 inclusive. Other versions seem to be unaffected. We remind
users that versions 1.0.x, 1.1.x, 2.0.x, 2.1.x, and 2.2.x are old
and unsupported. Patches for those versions will not be released, as
the issue can be corrected with a minor configuration change. We
also note that prior to version 3, the session cache was disabled by
default, and required administrator intervention to enable it.

The v4.0.x branch is not vulnerable to this issue. The underlying
code has been refactored to hide the TLS session data until the
final EAP Success is sent, in the Access-Accept. This change means
that the issue is impossible to reoccur in the future.

At this time, we have not had reports of the issue being exploited
in the wild.

