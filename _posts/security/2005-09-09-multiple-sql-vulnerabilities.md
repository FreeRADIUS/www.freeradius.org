---
layout: post
title: "Multiple SQL vulnerabilities"
# date: 2005-09-09
categories: vul_notifications
tags: security
---

Multiple issues exist with version 1.0.4, and all prior versions of
the server. Externally exploitable vulnerabilities exist only for
sites that use the `rlm_sqlcounter` module. Those sites may be
vulnerable to SQL injection attacks, similar to the issues
noted below. All sites that have not deployed the `rlm_sqlcounter`
module are not vulnerable to external exploits. However, we still
recommend that all sites upgrade to version 1.0.5.

The issues are:

-   SQL Injection attack in the `rlm_sqlcounter` module.
-   Buffer overflow in the `rlm_sqlcounter` module, that may cause a
    server crash.
-   Buffer overflow while expanding %t, that may cause a
    server crash.

These issues were found by Primoz Bratanic. As the `rlm_sqlcounter`
module is marked "experimental" in the server source, it is not
enabled or configured in most sites. As a result, we believe that
the number of vulnerable sites is low.

Additional issues, not externally exploitable, were found by Suse. A
full response to their report is available
[here](/security/20050909-response-to-suse.txt). A related post to
the `vendor-sec` mailing list is found
[here](/security/20050909-vendor-sec.txt).

