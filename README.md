[![Build Status Travis](https://travis-ci.org/AspireOrg/aspirewallet.svg?branch=develop)](https://travis-ci.org/AspireOrg/aspirewallet)
[![Build Status Circle](https://circleci.com/gh/AspireOrg/aspirewallet.svg?&style=shield)](https://circleci.com/gh/AspireOrg/aspirewallet)

Aspire Wallet
================

Online Web Wallet for [Aspire](http://aspirecrypto.com).

Originally based off of [Carbonwallet](http://www.carbonwallet.com) (however virtually all the original code has been removed or rewritten).


Features
----------

- Deterministic wallet addresses (BIP 32-based)
- Supports the majority of Aspire functionality
- Fully-AJAX driven
- Anonymous
- Runs in the browser, with keys created in memory
- Multi-sig

Browser Support
-------------------

**Desktop**

- Chrome 23+ (preferred browser)
- Firefox 25+
- Safari 7+
- Opera 15+

Notably, Internet Explorer is **not** supported, due to its lack of full Content-Security-Policy support (even with IE 11).

**Mobile**

- IOS Safari 7+
- Android Browser 4.4+
- Chrome for Android 33+
- Chrome for iOS 35+
- Firefox for Android 26+


Ubuntu 16.04 Build Instructions
-------------------

### Initial Setup
```
sudo apt update -y
sudo apt upgrade -y
sudo apt install build-essential libssl-dev nginx -y

sudo adduser aspire --disabled-password
```

### Setup node
```
sudo su aspire

curl -o- https://raw.githubusercontent.com/creationix/nvm/v0.33.8/install.sh | bash
source ~/.profile
nvm install v8.11.3
nvm use v8.11.3
nvm alias default v8.11.3
npm install -g grunt-cli bower
```

## Setup aspire wallet
```
sudo su aspire
cd /home/aspire
git clone https://github.com/AspireOrg/aspirewallet.git
cd aspirewallet/src
bower install
cd ..
npm install
```

### Build static site
```
sudo su aspire
cd /home/aspire
grunt build
```

### To regenerate dependencies hash file (```src/.bowerhashes```):
```
grunt freeze
```

### Running tests from CLI (using phantomjs headless browser)
```
sudo su aspire
cd /home/aspire
npm test
```

### Running in development
- Install serve to deliver site easily
```
npm install -g serve
```
- Copy default conf file
```
cp aspirewallet.conf.json.example aspirewallet.conf.json
```
- Review and change aspirewallet.conf.json accordingly
- Build static site
```
grunt build --dontcheckdeps --dontminify && cp aspirewallet.conf.json build/
```
- Serve static site
```
cd build/; serve
```
- visit `http://localhost:3000`


### To enable localizations (optional):
1. Create an account on [Transifex](https://www.transifex.com/)
2. In your home directory, create a file named `.transifex` and put your Transifex username and password into it in this format: `user:password`
3. Run `grunt build` to download translations
4. Add the languages you want to support to `AVAILABLE_LANGUAGES` in **aspirewallet.conf.json** - you can use **aspirewallet.conf.json.example** as a template. The template file contains **only** the setting relevant to languages and does not replace the rest of variables required in that file (refer to Federeated Node documentation for additional details about `aspirewallet.conf`).


#### Notes:
* the `--dontcheckdeps` speeds up the process and avoids having to do `grunt freeze` everytime you make a change to a dependency during development
* the `--dontminify` makes your debugging life a bit easier
* the `cp` is neccesary because grunt keeps clearing the `build` folder
* If you want to test your local version on another device (or let another person test something) use https://ngrok.com to setup a tunnel to your local environment
* If you want to use HTTPS, refer to additional steps required in the Aspirewallet Docker start script
 
### Note concerning `npm install`
`npm install` triggers a `prepublish` which is configured to do `grunt build` 
and will bork if you haven't done a `grunt freeze` after making changes to dependencies.
You can use `npm update` to circumvent this during development.

### Running tests in browser
You can run tests in your browser by doing the above steps and;
 - open a seperate terminal and [from the root of the project, not from `build/` run `serve -p 3001` (different port)
 - visit `http://localhost:3001/test/test.html`

### Running tests from CLI (using phantomjs headless browser)
 - `npm test`

### Development without a full node

To work on aspirewallet without running a full node and supporting services locally, please see the scripts located in the [local development folder](local-development).


License
-------------------

http://opensource.org/licenses/CDDL-1.0

