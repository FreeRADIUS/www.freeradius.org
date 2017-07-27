---
layout: post
title: "Two SQL vulnerabilities"
# date: 2005-05-01
categories: vul_notifications
tags: security
---

Two vulnerabilities in the SQL module exist in all versions prior
to 1.0.3. Sites not using the SQL module are not affected by
this issue. However, we still recommend that all sites upgrade to
version 1.0.3.

The issues are:

-   Buffer overflow - A long string could overflow an internal
    buffer in the SQL module, and write two bytes of text \[0-9a-f\]
    past the end of the buffer. The server may exit when this
    happens, resulting in a DoS attack. Depending on the local
    configuration of the server, this may occur before a user
    is authenticated. This vulnerability is externally exploitable,
    but can not result in the execution of arbitrary code.
-   SQL injection attacks - The SQL module suffers from SQL
    injection attacks in the `group_membership_query`,
    `simul_count_query`, and `simul_verify_query`
    configuration entries. The first query is exploitable if your
    site is configured to use the `SQL-Group` attribute in any
    module in the `authorize` section of `radiusd.conf`. The last
    two queries are exploitable only if your site has user names
    that contain a single quote character (`'`).

