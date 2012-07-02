apiary = require '../lib/apiary.syntax'

exports.parse = (test) ->
  raw = [
    'POST /x?qwe=qwe'
    '> Accept: application/json'
    '{"qwe": "qwe"}'
    '< 200'
    '< Content-Type: application/json'
    '{"qwe": "qwe"}'
    '< 500'
    '< 404'
    '< Content-Type: application/json'
    'Not Found'
  ].join '\n'
  out = apiary.fromRaw(raw)

  console.log JSON.stringify(out, null, 2)
  console.log apiary.toRaw(out)
  console.log apiary.toCurl(out)
  console.log apiary.toKurl(out, {json:true})
  console.log apiary.toJQuery(out)
  test.done()
