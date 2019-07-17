# gpg-contract-fork: GPGMail fork, minus contract dialog, plus working build instructions

I love open source. Let's go.

For general information, see the [upstream README](https://github.com/GPGTools/GPGMail/blob/mojave/README.md).

## Build

* Give "Full Disk Access" to your Terminal or iTerm app in System Preferences > Security & Privacy > Privacy > Full Disk Access (don't forget to tick the box once the application is added). [ref](http://osxdaily.com/2018/10/09/fix-operation-not-permitted-terminal-error-macos/)
* Install GPG. [Homebrew](https://brew.sh) makes this easy: `brew install gnupg`
* Clone this repo. `git clone https://github.com/kivikakk/GPGMail && cd GPGMail`
* Make sure you have submodules cloned. `git submodule update --init --recursive`
* Build and install Libmacgpg. `(cd Dependencies/Libmacgpg && make && mkdir -p ~/Library/Frameworks && cp -r build/Release/Libmacgpg.framework ~/Library/Frameworks/)`
* If you receive an Xcode error about Command line tools, this can help `sudo xcode-select -s /Applications/Xcode.app/Contents/Developer`. [ref](https://github.com/nodejs/node-gyp/issues/569#issuecomment-94917337)
* Build, sign and install GPGTools. `make && codesign -s - --deep --force build/Release/GPGMail.mailbundle && mkdir -p ~/Library/Mail/Bundles && cp -r build/Release/GPGMail.mailbundle ~/Library/Mail/Bundles/`
* Enable Mail Plug-ins: `sudo defaults write "/Library/Preferences/com.apple.mail" EnableBundles 1`
* Open Mail.app, open its Preferences, click "Manage Plugins..." at the bottom of the General pane, check the box next to "GPGMail.mailbundle", click "Apply and Restart Mail".
* Baby, you've got yourself a stew.

If these steps don't work for you, [open an issue](https://github.com/kivikakk/GPGMail/issues/new) and let's work it out.
