harrogate
=========

The UI for the Link2

Requirements
============

* Node.js v 0.10 (node-boyd is not compatible with newer versions!)
* OpenCV (required by node-boyd)

Installing dependencies
=======================

This will fetch all required npm dependencies.

	cd harrogate
	npm install

Launching gulp (development)
============================

Gulp is used to
* Compile the jade sources and browserify the client scripts.
* Start the Express server

```
cd harrogate
gulp
```

Launching express server (production)
=====================================

*Note*: Gulp needs to run before to compile jade source and browserify the client scripts.

	cd harrogate
	node server.js

Open the harrogate web pages
============================
Open a web browser and navigate to `http://<IP of the harrogate server>:8888` (e.g. `http://127.0.0.1:8888`)

Authors
=======

* Braden McDorman
* Stefan Zeltner

License
=======
pcompiler is released under the terms of the GPLv3 license. For more information, see the LICENSE file in the root of this project.
