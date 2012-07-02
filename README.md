# apiary.syntax.js

A javascript library that parses from/into [apiary.io](http://apiary.io/blueprint)'s syntax.
Inspired by [apiary.io's language-templates](https://github.com/apiaryio/language-templates).

Source code is written in [coffee-script](http://coffeescript.org/),
but the javascript counterpart can be compiled with `coffee -c lib/apiary.syntax.coffee`.

The library is a AMD/nodejs module with help from the [UMD patterns](https://github.com/umdjs/umd).

Tests <del>are</del> *will be* run via [nodeunit](https://github.com/caolan/nodeunit/).

# Basic Usage

```js
var apiary = require('apiary');
var raw = [
    'POST /x?qwe=qwe',
    '> Accept: application/json',
    '{"qwe": "qwe"}',
    '< 200',
    '< Content-Type: application/json',
    '{"qwe": "qwe"}',
    '< 500',
    '< 404',
    '< Content-Type: application/json',
    'Not Found'
  ].join('\n');
var apiaryObj = apiary.fromRaw(raw);
```

```js
console.log(apiaryObj);
/*
{
  "in": {
    "body": "{\"qwe\": \"qwe\"}",
    "headers": {
      "Accept": "application/json"
    }
  },
  "method": "POST",
  "outs": [
    {
      "body": "{\"qwe\": \"qwe\"}",
      "headers": {
        "Content-Type": "application/json"
      },
      "status": "200"
    },
    {
      "status": "500"
    },
    {
      "body": "Not Found",
      "headers": {
        "Content-Type": "application/json"
      },
      "status": "404"
    }
  ],
  "URI": "http://localhost/x?qwe=qwe"
}*/
```

```js
console.log(apiary.toRaw(apiaryObj));
/*
POST http://localhost/x?qwe=qwe
> Accept: application/json
{"qwe": "qwe"}
< 200
< Content-Type: application/json
{"qwe": "qwe"}
< 500
< 404
< Content
*/
```

```js
console.log(apiary.toCurl(apiaryObj));
/*
curl\
  --include\
  --request POST\
  --url http://localhost/x?qwe=qwe\
  --header "Accept: application/json"\
  --data "{"qwe": "qwe"}"
*/
```

```js
console.log(apiary.toKurl(apiaryObj));
/*
kurl\
  --include\
  --request POST\
  --url http://localhost/x\
  --query qwe=qwe\
  --header "Accept: application/json"\
  --data-json qwe="qwe"
*/
```

```js
console.log(apiary.toJQuery(apiaryObj));
/*
// jQuery 1.6+
$.ajax({
  "data": "{\"qwe\": \"qwe\"}",
  "headers": {
    "Accept": "application/json",
    "Content-Length": "14"
  },
  "type": "POST",
  "url": "http://localhost/x?qwe=qwe"
}).always(function(data, textStatus, jqXHR){console.log(data, textStatus, jqXHR.statusText, jqXHR.status, jqXHR)});
*/
```

# Comprehensive Usage

TODO
