# apiary.syntax.js

A javascript library that parses from/into [apiary.io](http://apiary.io/blueprint)'s syntax.

Source code is written in [coffee-script](http://coffeescript.org/),
but the javascript counterpart can be compiled with `coffee -c lib/apiary.syntax.coffee`.

The library is a AMD/nodejs module with help from the [UMD patterns](https://github.com/umdjs/umd).

Tests <s>are</s> will be run via [nodeunit](https://github.com/caolan/nodeunit/).

# Basic Usage

```js
var apiary = require('apiary');
var raw = [
    'GET /x',
    '> Accept: text/plain',
    '< 200',
    '< Content-Type: text/plain',
    'qwe',
    '< 500',
    '< 404',
    '< Content-Type: text/plain',
    'Not Found',
  ].join('\n');

var apiaryObj = apiary.fromRaw(raw);
console.log(apiaryObj);
console.log(apiary.toCurl(apiaryObj));
```

# Comprehensive Usage

TODO
