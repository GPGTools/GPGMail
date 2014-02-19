GPGMail
=======

GPGMail is a plugin for OS X's Mail.app, which let's you  
send and receive secure, OpenPGP encrypted and signed messages.

Updates
-------

The latest releases of GPGMail can be found on our [official website](https://gpgtools.org/gpgmail/).

For the latest news and updates check our [Twitter](https://twitter.com/gpgtools).

Visit our [support page](http://support.gpgtools.org) if you have questions or need help setting up your system and using GPGMail.


Build
-----

### Clone the repository
```bash
git clone https://github.com/GPGTools/GPGMail.git
cd GPGMail
```

### Build
```bash
make
```

### Install
To copy GPGMail into Mail's Bundles folder (as root if neccessary):
```bash
make install
```

### More build commands
```bash
make help
```

Don't forget to install [MacGPG2](https://github.com/GPGTools/MacGPG2)
and [Libmacgpg](https://github.com/GPGTools/Libmacgpg).  
Enjoy your custom GPGMail!


System Requirements
-------------------

* Mac OS X >= 10.7
* libmacgpg
* MacGPG2
