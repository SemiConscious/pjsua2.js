# pjsua2.js
Native node module for pjsua2 library
## Build

### Prerequisites

- swig. maps the binding definition into a C++ file for the native javascript bindings. For the moment use `https://github.com/mmomtchev/swig.git`. clone, autoconf.sh, configure, make, make install
- node. 20+ recommended
- node-gyp. This builds the native bindings. `npm install -g node-gyp`

### build

`node-gyp rebuild`

### test

`npm run test`

