exports.getURIScheme = (URI) ->
  re = /^((http[s]?|ftp[s]?):\/)?\/?([^:\/\s]+)(:\d+)?((\/[\w\-\.]+)*)\/([\w\-\.]+[^#?\s]*)([^#]*)?(#[\w\-]*)?$/g

  # If URI is already a URIScheme, return it
  if typeof URI is "object" and "hostname" of URI
    return URI
  else
    if typeof URI isnt "string"
      URI = URI.toString()

  matches = re.exec(URI)
  return  unless matches

  protocol = matches[2] + ":"
  port = matches[4] or ""
  host = matches[3] + port
  pathname = matches[5] + "/" + matches[7]

  url: matches[0]
  protocol: protocol
  hostname: matches[3]
  port: port
  host: host
  path: matches[5]
  file: matches[7]
  pathname: pathname
  search: matches[8]
  hash: matches[9]
