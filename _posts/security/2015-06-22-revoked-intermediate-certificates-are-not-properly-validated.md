---
layout: post
title: "Revoked intermediate certificates are not properly validated"
# date: 2015-06-22
categories: vul_notifications
tags: security
---

oCert-CVE 2015-4680

All versions which implement EAP-TLS, prior to 2.2.8 and 3.0.9 do
not check intermediate CAs for revocation. We have put patches into
the version 2 and version 3 branches to fix these issues.

We expect that this issue has minimal effect on the majority of
RADIUS systems. If you are using a self-signed CA for 802.1X, this
issue does not seriously affect you, as only you can issue
intermediate certificates. If you are using certificates from a
public CA, then your configuration already permits third parties to
issue certificates which will be accepted by your RADIUS server.

i.e. The act of using a public CA cert in RADIUS can open your
systems to security issues which are larger, and much worse than
this one. The fix for this particular issue does not change the
underlying security problem behind using a public CA.

Our analysis of the issue led us to disagree with the analysis done
by oCert, and the (alleged) original vendor who made the report. We
a requested a response to our analysis, and oCert refused. We
requested that the public notice contain an accurate description of
the issue and it's impact. oCert again refused. After repeated
messages, the response from Andrea Barisani of oCert was:

    The reporter disagrees with your assessment yet cannot share details
    about their setup, oCERT has no wishes to do technical support on
    their setup as we just care about the reported bug.

Which is missing the point. We never asked to do "technical support
on their setup". We asked for an accurate description of the issue
and it's impact. oCert refused, whichs means that they do not, in
fact, "care about the reported bug".

We wanted to work together to come up with an accurate description
of the issue, including it's impact. It was clear that oCert was had
no such goal. They saw their work as simply taking the original
report, and forwarding it to a wider audience (including us).

We can only conclude that our analysis is correct, and that the
original report, and the summary published by oCert is largely
wrong. We can also recommend that people avoid oCert, as they are
unwilling to work with authors to publish accurate reports.

