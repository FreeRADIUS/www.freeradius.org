---
layout: template
navtitle: Styles
title: Styles
subtitle: Reference document for basic styling
permalink: /styles/
hero: support

subpage: true

subnav:
 - text: A Link
   link: \#the_link
 - text: Another Link
   link: \#the_otherlink

---

##### Pure Markdown elements

# H1 Fast, feature-rich, modular, and scalable.

## H2 Version 3.0.10 has been released.

### H3 Version 3.0.10 has been released.

#### H4 October 7, 2015

##### H5 Full release notes

###### H6 Securing BYOD with smart network access policies, and agentless posture assessment.

Basic paragraph the FreeRADIUS project maintains the following components: a multi protocol policy server (radiusd) that implements RADIUS, DHCP, BFD, and ARP; a BSD licensed RADIUS client library; a RADIUS PAM library; and an Apache RADIUS module.

> Blockquote the FreeRADIUS project maintains the following components: a multi protocol policy server (radiusd) that implements RADIUS, DHCP, BFD, and ARP; a BSD licensed RADIUS client library; a RADIUS PAM library; and an Apache RADIUS module.

**Bold lorem ipsum dolor sit amet,** *italic consectetur adipiscing elit.* [Default body anchor](http://www.freeradius.org) in context. Integer cursus magna eget risus lobortis, `inline code here` non sodales arcu cursus. 

	pre content here
	$ echo "Message-Authenticator = 0x00" | radclient 1922 status s3cr3t
	Sending request to server 1922, port 1812.
	radrecv: Packet from host 1922 code=2, id=140, length=54
		Reply-Message = "FreeRADIUS up 21 days, 02:05"


---

##### Colours

###### Block &amp; Accent Colour Classes

<p>
	<div class="bg_block-dark" style="height: 50px; width: 100px; display: inline-block;"></div>
	<div class="bg_block-navy" style="height: 50px; width: 100px; display: inline-block;"></div>
	<div class="bg_accent-blue" style="height: 50px; width: 100px; display: inline-block;"></div>
	<div class="bg_accent-grey" style="height: 50px; width: 100px; display: inline-block;"></div>
	<div class="bg_stroke-light" style="height: 50px; width: 100px; display: inline-block;"></div>
	<div class="bg_block-light" style="height: 50px; width: 100px; display: inline-block;"></div>
<br>
	<div class="bg_accent-light-blue" style="height: 50px; width: 100px; display: inline-block;"></div>
	<div class="bg_accent-green" style="height: 50px; width: 100px; display: inline-block;"></div>
	<div class="bg_accent-red" style="height: 50px; width: 100px; display: inline-block;"></div>
	<div class="bg_accent-purple" style="height: 50px; width: 100px; display: inline-block;"></div>
	<div class="bg_accent-orange" style="height: 50px; width: 100px; display: inline-block;"></div>
	<div class="bg_accent-yellow" style="height: 50px; width: 100px; display: inline-block;"></div>
</p>

###### Text Colour Classes

| <span class="text-dark h4">Dark Text</span> | <span class="text-mid h4">Mid Text</span> | <span class="text-light h4">Light Text</span> | <span class="text-link h4">Link Text</span> | <span class="text-alert h4">Alert Text</span> |

---

##### Grid

<div class="row">
	<div class="column medium-4">
		<h2>Grid System</h2>
		We've used <a href="http://foundation.zurb.com/sites/docs/grid.html">Foundation Grid</a> to style layout throughout the site. Its a basic 12-column grid system with the ability to nest and build semantically. <a href="http://foundation.zurb.com/sites/docs/grid.html">Documentation available here</a>.
	</div>
	<div class="column medium-4">
		<h2>Column Two</h2>
		Alan Dekok co-founded FreeRADIUS in 1999 and continues to lead the project today. He is recognized as one of the world's leading experts on remote network and AAA frameworks, and he has co-authored numerous AAA and RADIUS related RFCs.
	</div>
	<div class="column medium-4">
		<h2>Column Three</h2>
		Alan Dekok co-founded FreeRADIUS in 1999 and continues to lead the project today. He is recognized as one of the world's leading experts on remote network and AAA frameworks, and he has co-authored numerous AAA and RADIUS related RFCs.
	</div>
</div>

---


##### Buttons

###### Basic buttons

<a class="button bg_accent-blue h5" href="#">Blue Button</a>
<a class="button bg_accent-light-blue h5" href="#">Light Blue Button</a>
<a class="button bg_accent-dark-blue h5" href="#">Dark Blue Button</a>
<a class="button bg_accent-green h5" href="#">Green Button</a>

###### Detailed button - apply any of the colour classes above

<a class="button detailed bg_accent-blue">
	<span class="h4 right-border">freeradius-devel@lists.freeradius.org</span>
	<span class="h5">Subscribe to this list</span>
</a>

###### Link with accent border (accent defined by currentColour)

<a class="link h5"><img class="icon" src="../img/wiki.svg">Inline link <img class="arrow" src="../img/arrow-right.svg"></a> <a class="link h5"><img class="icon" src="../img/support.svg">Inline link <img class="arrow" src="../img/arrow-right.svg"></a>

<a class="link block h5"><img class="icon" src="../img/security.svg">Block link <img class="arrow" src="../img/arrow-right.svg"></a>


---

##### Icon sizing

| <img class="icon_large" src="../img/wiki.svg"> | <img class="icon_medium" src="../img/wiki.svg"> | <img class="icon_small" src="../img/wiki.svg"> | <img class="icon_xsmall" src="../img/wiki.svg"> |
