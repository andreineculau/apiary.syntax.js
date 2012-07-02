if typeof exports is "object" and typeof define isnt "function"
  define = (factory) ->
    module.exports = factory(require, exports, module)

define (require, exports, module) ->
  aug = require "../node_modules/aug/lib/aug"

  self =
    utils:
      getURIScheme: (URI) ->
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

      reHead: /([A-Z]+) ([A-Za-z0-9\-\.\_\~\:\/\?\#\[\]\@\!\$\&\"\(\)\*\+\,\;\=]+)/
      reHeaderKey: /([A-Za-z0-9\-]+)/
      reHeaderValue: /(.+)/
      reStatus: /([1-9][0-9]{2,2})/

      defaultApiary:
        in:
          body: undefined
          headers: undefined
        method: undefined
        outs: undefined
        URI: undefined

      defaultApiaryOut:
        body: undefined
        headers: undefined
        status: undefined

      defaultOptions:
        apiURI: "http://localhost"

    fromRaw: (raw, options = {}) ->
      options = aug {}, self.utils.defaultOptions, options
      apiary = aug {}, self.utils.defaultApiary

      reInHeader = new RegExp "^> " + self.utils.reHeaderKey.source + ": " + self.utils.reHeaderValue.source + "$"
      reOutStatus = new RegExp "^< " + self.utils.reStatus.source + "$"
      reOutHeader = new RegExp "^< " + self.utils.reHeaderKey.source + ": " + self.utils.reHeaderValue.source + "$"

      lines = raw.trim().replace("\r\n", "\n").split("\n")

      # Parse Head
      head = lines.shift().trim()
      unless self.utils.reHead.test head
        throw new Error "\"#{head}\" does NOT describe a HTTP method and an URI"
      [head, apiary.method, apiary.URI] = self.utils.reHead.exec head
      if apiary.URI[0] is "/"
        apiary.URI = options.apiURI + apiary.URI

      # Parse In Headers
      while lines.length
        line = lines[0].trim()
        break  unless reInHeader.test line
        [line, headerKey, headerValue] = reInHeader.exec line
        apiary.in.headers ?= {}
        apiary.in.headers[headerKey] = headerValue
        lines.shift()

      # Parse In Body
      while lines.length
        line = lines[0].trim()
        break  if reOutStatus.test line
        apiary.in.body ?= []
        apiary.in.body.push line
        lines.shift()
      if apiary.in.body and apiary.in.body.length
        apiary.in.body = apiary.in.body.join "\n"

      outs = []
      while lines.length
        break  if lines[0].length is 0
        # Intentionally not lines[0].trim().length

        out = aug {}, self.utils.defaultApiaryOut

        # Parse Out Status
        status = lines.shift().trim()
        unless reOutStatus.test status
          throw new Error "\"#{status}\" does NOT describe a HTTP status"
        [status, out.status] = reOutStatus.exec status

        # Parse Out Headers
        while lines.length
          line = lines[0].trim()
          break  unless reOutHeader.test line
          [line, headerKey, headerValue] = reOutHeader.exec line
          out.headers ?= {}
          out.headers[headerKey] = headerValue
          lines.shift()

        # Parse Out Body
        while lines.length
          line = lines[0].trim()
          break  if reOutStatus.test line
          out.body ?= []
          out.body.push line
          lines.shift()
        if out.body and out.body.length
          out.body = out.body.join "\n"

        if out.status
          outs.push out
      if outs.length
        apiary.outs = outs

      apiary

    # Convert apiary to raw text
    toRaw: (apiary, options = {}) ->
      result = []

      method = apiary.method
      URI = apiary.URI
      if options.baseURI
        URI = URI.replace options.baseURI, ""
      result.push "#{method} #{URI}"

      for headerKey, headerValue of apiary.in.headers
        result.push "> #{headerKey}: #{headerValue}"
      if apiary.in.body
        result.push apiary.in.body

      for out in apiary.outs
        result.push "< #{out.status}"
        for headerKey, headerValue of out.headers
          result.push "< #{headerKey}: #{headerValue}"
        if out.body
          result.push out.body

      result = result.join "\n"
      result

    # Convert apiary to curl command
    toCurl: (apiary, options = {}) ->
      result = [
        "curl"
        "--include"
        "--request #{apiary.method}"
        "--url #{apiary.URI}"
      ]

      for headerKey, headerValue of apiary.in.headers
        headerValue = headerValue.replace '"', '\"'
        result.push "--header \"#{headerKey}: #{headerValue}\""
      if apiary.in.body
        body = apiary.in.body.replace '"', '\"'
        result.push "--data \"#{body}\""

      result = result.join "\\\n  "
      result

    # Convert apiary to kurl command
    toKurl: (apiary, options = {}) ->
      apiary = aug {}, apiary
      URIScheme = self.utils.getURIScheme apiary.URI
      query = (if URIScheme.search then URIScheme.search.substr(1).split('&') else [])
      apiary.URI = [
        URIScheme.protocol
        '//'
        URIScheme.host
        URIScheme.pathname
      ].join('')

      result = [
        "kurl"
        "--include"
        "--request #{apiary.method}"
        "--url #{apiary.URI}"
      ]

      for q in query
        result.push "--query #{q}"
      for headerKey, headerValue of apiary.in.headers
        headerValue = headerValue.replace '"', '\"'
        result.push "--header \"#{headerKey}: #{headerValue}\""
      if apiary.in.body
        if options.json
          body = JSON.parse(apiary.in.body)
          for bodyKey, bodyValue of body
            bodyValue = JSON.stringify(bodyValue)
            result.push "--data-json #{bodyKey}=#{bodyValue}"
        else
          body = apiary.in.body.replace '"', '\"'
          result.push "--data \"#{body}\""

      result = result.join "\\\n  "
      result

  self
