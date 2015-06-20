harrogate
=========

The UI for the Link2

Requirements
============

* Node.js v 0.10 (node-boyd is not compatible with newer versions!)
* OpenCV (required by node-boyd)

Installing dependencies
=======================

	cd harrogate
	npm install

Launching gulp (development)
============================

	cd harrogate
	gulp

Launching express server (production)
=====================================

*Note*: Gulp needs to run before to compile jade source and browserify the client scripts.

	cd harrogate
	node server.js

Authors
=======

* Braden McDorman
* Stefan Zeltner

License
=======
pcompiler is released under the terms of the GPLv3 license. For more information, see the LICENSE file in the root of this project.
