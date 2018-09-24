GPGMail
=======

GPGMail is a plugin for OS X's Mail.app, which let's you  
send and receive secure, OpenPGP encrypted and signed messages.


#### Grab Dependencies


TL;DR: this is a temporary fork that removes all DRM (especially Paddle) implementation from GPGMail.

Easiest way to get this is to install the official release from https://gpgtools.org/

and then compile your own GPGMail_14.mailbundle

In order to communicate with GnuPG we use our own Objective-C framework called [Libmacgpg](https://github.com/GPGTools/Libmacgpg).
It's necessary to clone the Libmacgpg repository first, before building GPGMail.

```bash
cd Dependencies
git clone https://github.com/GPGTools/Libmacgpg.git
cd ..
```

#### Build
```bash
make
```

#### Install
Copy build/Release/GPGMail.mailbundle to /Library/Application\ Support/GPGTools/GPGMail/GPGMail_14.mailbundle
(note it has to use the _14 suffix)

System Requirements
-------------------

* Mac OS X Mojave
* Libmacgpg
* GnuPG
