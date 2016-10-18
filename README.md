GPGMail
=======

GPGMail is a plugin for OS X's Mail.app, which let's you  
send and receive secure, OpenPGP encrypted and signed messages.

Updates
-------

The latest releases of GPGMail can be found on our [official website](https://gpgtools.org/).

For the latest news and updates check our [Twitter](https://twitter.com/gpgtools).

Visit our [support page](https://gpgtools.tenderapp.com) if you have questions or need help setting up your system and using GPGMail.

Localizations are done on [Transifex](https://www.transifex.com/projects/p/GPGMail/).

Prerequisite
------------

In order to use GPGMail you need to have GnuPG installed.
You can either build your own version, use one from [homebrew](http://brew.sh) or find a packaged version for OS X at [gpgtools.org](https://gpgtools.org)

Build
-----

#### Clone the repository
```bash
git clone https://github.com/GPGTools/GPGMail.git
cd GPGMail
```

#### Grab Dependencies

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
Copy Libmacgpg.framework from Dependencies/Libmacgpg/build/Release/ to ~/Library/Frameworks.

After that copy the GPGMail.mailbundle file from build/Releases/GPGMail.mailbundle to ~/Libray/Mail/Bundles, re-start Mail.app and enjoy.


System Requirements
-------------------

* Mac OS X >= 10.9 (not 10.12)
* Libmacgpg
* GnuPG
