harrogate
=========

The UI for the Link2

Install harrogate from source
=============================
**Requirements:**

* Node.js v 0.10 (node-boyd is not compatible with newer versions!)
* OpenCV (required by node-boyd)

**Install dependencies:**
This will fetch all required npm dependencies.

	cd harrogate
	npm install

**Robot programs requirements:**
These libraries are required to compile a robot program with harrogate.

* zlib v 1.2
* libpng v 1.6
* libbson v 1.1
* daylite
* libaurora

Note: harrogate assumes that those dependencies are installed into `<harrogate-dir>\..\prefix\usr\`

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
harrogate is released under the terms of the GPLv3 license. For more information, see the LICENSE file in the root of this project.
