---
layout: template
navtitle:
navorder:
title: Sample Template Page
subtitle: Sample content using the template layout
permalink: /sample/
hero: support

subpage: true

subnav:
 - text: A Link
   link: \#the_link
 - text: Another Link
   link: \#the_otherlink

---

##Getting Started

This page describes how to perform the initial configuration of FreeRADIUS. It assumes a basic knowledge of Unix system administration. No RADIUS knowledge is required.

####Installing the Server

Where possible, we recommend using the packaging system that is used by your operating system. The version that is supplied by your OS might be out of date, but it is likely to work "out of the box".

If you need to install it yourself, the Wiki installation page contains detailed instructions for a number of platforms.

Otherwise, we assume that you can install the server via something like `yum install freeradius`, or `apt-get install freeradius`.

Note that in Debian-based systems, the server daemon is called `freeradius` instead of `radiusd` The configuration files are also located in `/etc/freeradius` instead of `/etc/raddb/`. We use radiusd and /etc/raddb/ in this guide, and trust that Debian administrators can translate to their system.

####Some background

Once the server has been installed, the first thing to do is *change as little as possible*. The default configuration is designed to work everywhere, and to perform nearly every authentication method.

---

*Do not edit the default configuration files until you understand what they do. This means reading the documentation contained in the comments of the configuration files.*

---

Many common configurations are documented as suggestions or examples in the configuration files. Many common problems are discussed in the configuration files, along with suggested solutions.

We recommend reading the configuration files, in large part because most of the configuration items are documented only in the comments in the configuration files.

We recommend *reading the debug output of the server*. While it contains a lot of text, it usually contains error messages which describe exactly what went wrong, and how to fix it.

####Starting the server

When the server has been installed on a new machine, the first step is to start it in debugging mode, as user `root`:

	$ radiusd -X

This step demonstrates that the server is installed and configured properly. If the output says `Ready to process requests`, then all is well.

Otherwise, typical errors include `Address already in use`, which means that there is another radius server already running. You will need to find that one and stop it before running the server in debugging mode.

####Initial Tests

Testing authentication is simple. Edit the users file (in v3 this has been moved to `raddb/mods-config/files/authorize`), and add the following line of text at the top of the file, before anything else:

	testing Cleartext-Password := "password"

Start the server in debugging mode (`radiusd -X`), and run `radtest` from another terminal window:

	$ radtest testing password 127.0.0.1 0 testing123

You *should* see the server respond with an Access-Accept. If it doesn't, the debug log will show why. In version 2, you can paste the output into the debug form, and a colorized HTML version will be produced. In version 3, the output will be colorized. Look for red or yellow text, and read the relvant messages. They should describe exactly what went wrong, and how to fix the problem.

If you do see an `Access-Accept`, then congratulations, the following authentication methods now work for the `testing` user:

	PAP, CHAP, MS-CHAPv1, MS-CHAPv2, PEAP, EAP-TTLS, EAP-GTC, EAP-MD5.

The next step is to add more users, and to configure databases. Those steps are outside of the scope of this short web page, but the general method to use is important, and is outlined in the next section.

####Adding a client

The above test runs `radtest` from localhost. It is useful to add a new client, which can be done by editing the `clients.conf` file. Add the following contets:

	client new {
		ipaddr = 192.0.2.1
		secret = testing123
	}

You should change the IP address `192.0.2.1` to be the address of the client which will be sending Access-Request packets.

The client should also be configured to talk to the RADIUS server, by using the IP address of the maching running the RADIUS server. The client should use the same secret as configured above in the `client` section.

Then restart the server in debugging mode, and run a simple test using the testing user. You should see an Access-Accept in the server output

---

The following steps outline the best known method for configuring the server. Following them lets you create complex configurations with a minimm of effort. Failure to follow them leads to days of frustration and wasted effort.

---

####Configuring the Server

Changing the server configuration should be done via the following steps:

1. Start with a "known working" configuration, such as supplied by the default installation.
2. Make one small change to the configuration files.
3. Start the server in debugging mode (radiusd -X).
4. Verify that the results are what you expect
- The debug output shows any configuration changes you have made.
- Databases (if used) are connected and operating.
- Test packets are accepted by the server.
- The debug output shows that the packets are being processed as you expect.
- The response packets are contain the attributes you expect to see.
5. If everything is OK, save a copy of the configuration, go back to step (2), and make another change.
6. If anything goes wrong,
- double-check the configuration
- read the entire debug output, looking for words like error or warning. These messages usually contain descriptions of what went wrong, and suggestions for how it can be fixed. (see also the debug form)
- Try replace your configuration with a saved copy of a "known working" configuration, and start again. This process can clean up errors caused by temporary edits, or edits that you have forgotten about.
- Ask for help on the freeradius-users mailing list. Include a description of what you are trying to do, and the entire debugging output, especially output showing the server receiving and processing test packets. You may want to scrub "secret" information from the output before posting it. (Shared secrets, passwords, etc.)

####Other Resources

A number of guides are available from Network RADIUS. In particular, we recommend the Technical Guide, which should be read by every new RADIUS administrator. It explains RADIUS concepts, and covers how to perform introductory administation and maintenance. More in-depth guides are available on the same page.
