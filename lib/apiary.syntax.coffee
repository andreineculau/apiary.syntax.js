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
        statusLiteral: undefined

      defaultFromOptions:
        apiURI: "http://localhost"
        CORS: true
        defaultInHeaders: undefined
        defaultOutHeaders: undefined
        xHTTPMethodOverride: false
        sortHeaders: true

      defaultToOptions:
        inOnly: false
        lineInSeparator: "\n"
        lineInOutSeparator: "\n"
        lineOutSeparator: "\n"
        lineOutsSeparator: "\n"
        separateInOuts: false

      statusCodeToLiteral:
        "100": "Continue"
        "101": "Switching Protocols"
        "102": "Processing"
        "200": "OK"
        "201": "Created"
        "202": "Accepted"
        "203": "Non-Authoritative Information"
        "204": "No Content"
        "205": "Reset Content"
        "206": "Partial Content"
        "207": "Multi-Status"
        "208": "Already Reported"
        "226": "IM Used"
        "300": "Multiple Choices"
        "301": "Moved Permanently"
        "302": "Found"
        "303": "See Other"
        "304": "Not Modified"
        "305": "Use Proxy"
        "306": "Reserved"
        "307": "Temporary Redirect"
        "308": "Permanent Redirect"
        "400": "Bad Request"
        "401": "Unauthorized"
        "402": "Payment Required"
        "403": "Forbidden"
        "404": "Not Found"
        "405": "Method Not Allowed"
        "406": "Not Acceptable"
        "407": "Proxy Authentication Required"
        "408": "Request Timeout"
        "409": "Conflict"
        "410": "Gone"
        "411": "Length Required"
        "412": "Precondition Failed"
        "413": "Request Entity Too Large"
        "414": "Request-URI Too Long"
        "415": "Unsupported Media Type"
        "416": "Requested Range Not Satisfiable"
        "417": "Expectation Failed"
        "422": "Unprocessable Entity"
        "423": "Locked"
        "424": "Failed Dependency"
        "425": "Reserved for WebDAV advanced collections expired proposal"
        "426": "Upgrade Required"
        "427": "Unassigned"
        "428": "Precondition Required"
        "429": "Too Many Requests"
        "430": "Unassigned"
        "431": "Request Header Fields Too Large"
        "500": "Internal Server Error"
        "501": "Not Implemented"
        "502": "Bad Gateway"
        "503": "Service Unavailable"
        "504": "Gateway Timeout"
        "505": "HTTP Version Not Supported"
        "506": "Variant Also Negotiates (Experimental)"
        "507": "Insufficient Storage"
        "508": "Loop Detected"
        "509": "Unassigned"
        "510": "Not Extended"
        "511": "Network Authentication Required"

    # From wrapper
    fromWrapper: (apiary, options) ->
      sort = (obj) ->
        keys = Object.keys(obj).sort()
        result = {}
        for key in keys
          result[key] = obj[key]
        return result

      # Add CORS out headers
      if options.CORS
        for out in apiary.outs
          out.headers ?= {}
          out.headers["Access-Control-Allow-Methods"] ?= "OPTIONS,GET,HEAD,POST,PUT,DELETE,TRACE,CONNECT"
          out.headers["Access-Control-Allow-Origin"] ?= "*"
      # Add default in headers
      if options.defaultInHeaders
        if typeof options.defaultInHeaders is "function"
          apiary.in.headers = options.defaultInHeaders apiary.in.headers
        else
          aug apiary.in.headers, options.defaultInHeaders
      # Add default out headers
      if options.defaultOutHeaders
        if typeof options.defaultOutHeaders is "function"
          for out of apiary.outs
            out.headers = options.defaultOutHeaders out.headers
        else
          aug out.headers, options.defaultOutHeaders
      # Add Content-Length header
      # TODO not sure if this is 100% correct
      if apiary.in.body
        apiary.in.headers["Content-Length"] ?= apiary.in.body.length.toString()
        for out in apiary.outs
          if out.body
            out.headers["Content-Length"] ?= out.body.length.toString()
      # Add X-HTTP-Method-Override header
      if options.xHTTPMethodOverride and ["GET", "CONNECT", "HEAD", "OPTIONS", "POST", "TRACE"].indexOf(apiary.method) isnt -1
        apiary.in.headers["X-HTTP-Method-Override"] = apiary.method
        apiary.method = "POST"

      # Sort in and out headers
      if options.sortHeaders
        apiary.in.headers = sort apiary.in.headers
        for out in apiary.outs
          out.headers = sort out.headers

      apiary

    # Raw to Apiary
    fromRaw: (raw, options = {}) ->
      options = aug {}, self.utils.defaultFromOptions, options
      apiary = aug {}, self.utils.defaultApiary

      reInHeader = new RegExp "^> " + self.utils.reHeaderKey.source + ": " + self.utils.reHeaderValue.source + "$"
      reOutStatus = new RegExp "^< " + self.utils.reStatus.source + " ?(.*)$"
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
        [status, out.status, out.statusLiteral] = reOutStatus.exec status
        out.statusLiteral = (self.utils.statusCodeToLiteral[out.status]) || out.statusLiteral || ""

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

      self.fromWrapper apiary, options
      apiary

    # To wrapper
    toWrapper: (result, options) ->
      result.in = result.in.join options.lineInSeparator
      for index of result.outs
        result.outs[index] = result.outs[index].join options.lineOutSeparator
      unless options.separateInOuts
        result.outs = result.outs.join options.lineOutsSeparator
        result = [result.in, result.outs].join options.lineInOutSeparator
      result

    # Convert apiary to raw text
    toRaw: (apiary, options = {}) ->
      options = aug {}, self.utils.defaultToOptions, options
      result =
        in: []
        outs: []

      method = apiary.method
      URI = apiary.URI
      if options.baseURI
        URI = URI.replace options.baseURI, ""
      result.in.push "#{method} #{URI}"

      for headerKey, headerValue of apiary.in.headers
        result.in.push "> #{headerKey}: #{headerValue}"
      if apiary.in.body
        result.in.push apiary.in.body

      unless options.inOnly
        for out in apiary.outs
          partialResult = []
          partialResult.push "< #{out.status}"
          for headerKey, headerValue of out.headers
            partialResult.push "< #{headerKey}: #{headerValue}"
          if out.body
            partialResult.push out.body
          result.outs.push partialResult

      result = self.toWrapper result, options
      result

    # Convert apiary to curl command
    toCurl: (apiary, options = {}) ->
      options = aug {}, self.utils.defaultToOptions, options
      result =
        in: [
          "curl"
          "--include"
          "--request #{apiary.method}"
          "--url #{apiary.URI}"
        ]
        outs: []

      for headerKey, headerValue of apiary.in.headers
        headerValue = headerValue.replace '"', '\"'
        result.in.push "--header \"#{headerKey}: #{headerValue}\""
      if apiary.in.body
        body = apiary.in.body.replace '"', '\"'
        result.in.push "--data \"#{body}\""

      unless options.inOnly
        for out in apiary.outs
          partialResult = []
          partialResult.push "HTTP/1.1 #{out.status} #{out.statusLiteral}"
          for headerKey, headerValue of out.headers
            partialResult.push "#{headerKey}: #{headerValue}"
          if out.body
            partialResult.push ""
            partialResult.push out.body
          result.outs.push partialResult

      options.lineInSeparator = "\\\n  "
      options.lineOutsSeparator = "\n----\n"
      result = self.toWrapper result, options
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

      options = aug {}, self.utils.defaultToOptions, options
      result =
        in: [
          "kurl"
          "--include"
          "--request #{apiary.method}"
          "--url #{apiary.URI}"
        ],
        outs: []

      for q in query
        result.in.push "--query #{q}"
      for headerKey, headerValue of apiary.in.headers
        headerValue = headerValue.replace '"', '\"'
        result.in.push "--header \"#{headerKey}: #{headerValue}\""
      if apiary.in.body
        if options.json
          body = JSON.parse(apiary.in.body)
          for bodyKey, bodyValue of body
            bodyValue = JSON.stringify(bodyValue)
            result.in.push "--data-json #{bodyKey}=#{bodyValue}"
        else
          body = apiary.in.body.replace '"', '\"'
          result.in.push "--data \"#{body}\""

      unless options.inOnly
        for out in apiary.outs
          partialResult = []
          partialResult.push "HTTP/1.1 #{out.status} #{out.statusLiteral}"
          for headerKey, headerValue of out.headers
            partialResult.push "#{headerKey}: #{headerValue}"
          if out.body
            partialResult.push ""
            partialResult.push out.body
          result.outs.push partialResult

      options.lineInSeparator = "\\\n  "
      options.lineOutsSeparator = "\n----\n"
      result = self.toWrapper result, options
      result

    # Convert apiary to javascript block
    # TODO
    toJavascript: (apiary, options = {}) ->
      headers = []
      apiary

    # Convert apiary to jQuery block
    # TODO
    toJQuery: (apiary, options = {}) ->
      options = aug {}, self.utils.defaultToOptions, options

      ajax =
        data: apiary.in.body
        headers: apiary.in.headers
        type: apiary.method
        url: apiary.URI

      ajax = JSON.stringify ajax, null, 2
      result =
        in: [
          "// jQuery 1.6+"
          "$.ajax(#{ajax}).always(function(data, textStatus, jqXHR){console.log(data, textStatus, jqXHR.statusText, jqXHR.status, jqXHR)});"
        ]
        outs: []
      result = self.toWrapper result, options
      result

    # Convert apiary to ruby block
    # TODO
    toRuby: (apiary, options = {}) ->
      apiary

    # Convert apiary to python block
    # TODO
    toRuby: (apiary, options = {}) ->
      apiary

    # Convert apiary to php block
    # TODO
    toRuby: (apiary, options = {}) ->
      apiary

  self
