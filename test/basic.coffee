apiary = require '../lib/apiary.syntax'

exports.parse = (test) ->
  raw = [
    'GET /x'
    '> Accept: text/plain'
    '< 200'
    '< Content-Type: text/plain'
    'qwe'
    '< 500'
    '< 404'
    '< Content-Type: text/plain'
    'Not Found'
  ].join '\n'
  out = apiary.fromRaw(raw)

  console.log JSON.stringify(out, null, 2)
  console.log apiary.toRaw(out)
  console.log apiary.toCurl(out)
  test.done()
