import
  asyncdispatch, db_sqlite, htmlparser, httpclient, json, nimpy, os, sequtils,
  pegs, re, strtabs, strutils, tables, uri, xmltree

template clientify(url: string; userAgent: string; maxRedirects: int; proxyUrl: string; proxyAuth: string;
  timeout: int; http_headers: openArray[tuple[key: string; val: string]]; code: untyped): array[7, string] =
  var
    respons {.inject.}: Response
    cliente {.inject.} = createU HttpClient
  try:
    cliente[] = newHttpClient(
      timeout = timeout,
      userAgent = userAgent,
      maxRedirects = maxRedirects,
      headers = newHttpHeaders(http_headers),
      proxy = (if unlikely(proxyUrl.len > 1): newProxy(proxyUrl, proxyAuth) else: nil),
    )
    {.push, experimental: "implicitDeref".}
    code
    {.pop.}
  finally:
    cliente[].close()
    if cliente != nil:
      dealloc cliente
  [$respons.body, respons.contentType, respons.status, respons.version, url, try: $respons.contentLength except: "0", $respons.headers]

proc scraper_regex*(list_of_urls: seq[string]; list_of_regex: seq[string]; multiline: bool = false; dot: bool = false; extended: bool = false; case_insensitive: bool = true; post_replacement_regex: string = "";
  post_replacement_by: string = ""; re_start: Natural = 0; start_with: string = ""; end_with: string = ""; verbose: bool = true; deduplicate_urls: bool = false; delay: Natural = 0;
  header: seq[(string, string)] = @[("DNT", "1")]; timeout: int = -1; agent: string = defUserAgent; redirects: Positive = 5; proxy_url: string = ""; proxy_auth: string = ""): seq[seq[string]] {.exportpy.} =
  let urls = if unlikely(deduplicate_urls): deduplicate(list_of_urls) else: @(list_of_urls)
  let proxi = if unlikely(proxy_url.len > 0): newProxy(proxy_url, proxy_auth) else: nil
  var cliente = newHttpClient(userAgent = agent, maxRedirects = redirects, proxy = proxi, timeout = timeout)
  cliente.headers = newHttpHeaders(header)
  result = newSeq[seq[string]](urls.len)
  var reflags = {reStudy}
  if case_insensitive: incl(reflags, reIgnoreCase)
  if multiline: incl(reflags, reMultiLine)
  if dot: incl(reflags, reDotAll)
  if extended: incl(reflags, reExtended)
  for i, url in urls:
    if likely(verbose): echo i, "\t", url
    for rege in list_of_regex:
      sleep delay
      for item in findAll(cliente.getContent(url), re(rege, reflags), re_start):
        if start_with.len > 0 and end_with.len > 0:
          if item.startsWith(re(start_with, reflags)) and item.endsWith(re(end_with, reflags)):
            result[i].add(if post_replacement_regex.len > 0 and post_replacement_by.len > 0: replacef(item, re(post_replacement_regex, reflags), post_replacement_by) else: item)
          else: continue
        else: result[i].add(if post_replacement_regex.len > 0 and post_replacement_by.len > 0: replacef(item, re(post_replacement_regex, reflags), post_replacement_by) else: item)


func match(n: XmlNode; s: tuple[id: string; tag: string; combi: char; class: seq[string]]): bool =
  result = (s.tag.len == 0 or s.tag == n.tag)
  if result and s.id.len > 0: result = s.id == n.attr"id"
  if result and s.class.len > 0:
    for class in s.class: result = n.attr("class").len > 0 and class in n.attr("class").split

func find(parent: XmlNode; selector: tuple[id: string; tag: string; combi: char; class: seq[string]]; found: var seq[XmlNode]) =
  for child in parent.items:
    if child.kind == xnElement:
      if match(child, selector): found.add(child)
      if selector.combi != '>': child.find(selector, found)

proc find(parents: var seq[XmlNode]; selector: tuple[id: string; tag: string; combi: char; class: seq[string]]) =
  var found: seq[XmlNode]
  for p in parents: find(p, selector, found)
  parents = found

proc multiFind(parent: XmlNode; selectors: seq[tuple[id: string; tag: string; combi: char; class: seq[string]]]; found: var seq[XmlNode]) =
  var matches: seq[int]
  var start: seq[int]
  start = @[0]
  for i in 0 ..< selectors.len:
    var selector = selectors[i]
    matches = @[]
    for j in start:
      for k in j ..< parent.len:
        var child = parent[k]
        if child.kind == xnElement and match(child, selector):
          if i < selectors.len - 1: matches.add(k + 1)
          else: found.add(child)
          if selector.combi == '+': break
    start = matches

proc multiFind(parents: var seq[XmlNode]; selectors: seq[tuple[id: string; tag: string; combi: char; class: seq[string]]]) =
  var found: seq[XmlNode]
  for p in parents: multiFind(p, selectors, found)
  parents = found

proc parseSelector(token: string): tuple[id: string; tag: string; combi: char; class: seq[string]] =
  result = (id: "", tag: "", combi: ' ', class: @[])
  if token == "*": result.tag = "*"
  elif token =~ peg"""\s*{\ident}?({'#'\ident})? ({\.[a-zA-Z0-9_][a-zA-Z0-9_\-]*})* {\[[a-zA-Z][a-zA-Z0-9_\-]*\s*([\*\^\$\~]?\=\s*[\'""]?(\s*\ident\s*)+[\'""]?)?\]}*""":
    for i in 0 ..< matches.len:
      if matches[i].len == 0: continue
      case matches[i][0]:
      of '#': result.id = matches[i][1..^1]
      of '.': result.class.add(matches[i][1..^1])
      else: result.tag = matches[i]

proc findCssImpl(node: var seq[XmlNode]; cssSelector: string) {.noinline.} =
  assert cssSelector.len > 0, "cssSelector must not be empty string"
  var tokens = cssSelector.strip.split
  for pos in 0 ..< tokens.len:
    var isSimple = true
    if pos > 0 and (tokens[pos - 1] == "+" or tokens[pos - 1] == "~"): continue
    if tokens[pos] in [">", "~", "+"]: continue
    var selector = parseSelector(tokens[pos])
    if pos > 0 and tokens[pos-1] == ">": selector.combi = '>'
    var selectors = @[selector]
    var i = 1
    while true:
      if pos + i >= tokens.len: break
      var nextCombi = tokens[pos + i]
      if nextCombi == "+" or nextCombi == "~":
        if pos + i + 1 >= tokens.len: assert false, "Selector not found"
      else: break
      isSimple = false
      var nextToken = tokens[pos + i + 1]
      inc i, 2
      var temp = parseSelector(nextToken)
      temp.combi = nextCombi[0]
      selectors.add(temp)
    if isSimple: node.find(selectors[0]) else: node.multiFind(selectors)

proc scraper_css_selector*(url: string; css_selector: string; user_agent: string = defUserAgent; max_redirects: int = 9; proxy_url: string = ""; proxy_auth: string = ""; timeout: int = -1; http_headers: openArray[tuple[key: string; val: string]] = @[("dnt", "1")]): seq[string] {.exportpy.} =
  assert url.len > 0, "url must not be empty string"
  var clien = create HttpClient
  var temp = create(seq[XmlNode])
  try:
    clien[] = newHttpClient(
        timeout = timeout,
        userAgent = userAgent,
        maxRedirects = maxRedirects,
        headers = newHttpHeaders(http_headers),
        proxy = (if unlikely(proxyUrl.len > 1): newProxy(proxyUrl, proxyAuth) else: nil),
      )
    temp[] = @[htmlparser.parseHtml(clien[].getContent(url))]
    findCssImpl(temp[], cssSelector)
    for item in temp[]:
      result.add $item
  finally:
    if temp != nil:
      dealloc temp
    clien[].close()
    if clien != nil:
      dealloc clien
