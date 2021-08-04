import lexbase, json, tables, streams, strutils, os, xmltree, httpclient, nimpy

type CsvParser = object of BaseLexer  # Custom copypasted from Nim stdlib "parsecsv.nim"
  row, headers: seq[string]
  sep, quote, esc: char
  currRow: int

template close(self: var CsvParser) = lexbase.close(self)

template open(self: var CsvParser, input: Stream, separator = ',', quote = '"', escape = '\0') =
  lexbase.open(self, input)
  self.sep = separator
  self.quote = quote
  self.esc = escape

template open(self: var CsvParser, filename: string, separator = ',', quote = '"', escape = '\0') =
  open(self, newFileStream(filename, fmRead), separator, quote, escape)

proc parseField(self: var CsvParser, a: var string) =
  var pos = create int
  pos[] = self.bufpos
  while self.buf[pos[]] in {' ', '\t'}: inc pos[]
  setLen(a, 0) # reuse memory
  if self.buf[pos[]] == self.quote and self.quote != '\0':
    inc pos[]
    while true:
      let c = self.buf[pos[]]
      if c == '\0':
        self.bufpos = pos[]
        raise newException(IOError, "CSV parse error, missing quotes at index " & $pos[])
      elif c == self.quote:
        if self.esc == '\0' and self.buf[pos[] + 1] == self.quote:
          add(a, self.quote)
          inc pos[], 2
        else:
          inc(pos[])
          break
      elif c == self.esc:
        add(a, self.buf[pos[] + 1])
        inc pos[], 2
      else:
        case c
        of '\c':
          pos[] = handleCR(self, pos[])
          add(a, '\n')
        of '\l':
          pos[] = handleLF(self, pos[])
          add(a, '\n')
        else:
          add(a, c)
          inc(pos[])
  else:
    while true:
      let c = self.buf[pos[]]
      if c == self.sep: break
      if c in {'\c', '\l', '\0'}: break
      add(a, c)
      inc pos[]
  self.bufpos = pos[]
  if likely(pos != nil): dealloc pos

proc readRow(self: var CsvParser): bool =
  var col {.noalias.} = create int
  while true:
    case self.buf[self.bufpos]
    of '\c': self.bufpos = handleCR(self, self.bufpos)
    of '\l': self.bufpos = handleLF(self, self.bufpos)
    else: break
  while self.buf[self.bufpos] != '\0':
    let oldlen = self.row.len
    if oldlen < col[] + 1:
      setLen(self.row, col[] + 1)
      self.row[col[]] = ""
    parseField(self, self.row[col[]])
    inc col[]
    if self.buf[self.bufpos] == self.sep: inc(self.bufpos)
    else:
      case self.buf[self.bufpos]
      of '\c', '\l':
        while true:
          case self.buf[self.bufpos]
          of '\c': self.bufpos = handleCR(self, self.bufpos)
          of '\l': self.bufpos = handleLF(self, self.bufpos)
          else: break
      of '\0': discard
      else: raise newException(IOError, "CSV parse error, missing separators at column " & $col[])
      break
  setLen(self.row, col[])
  result = col[] > 0
  inc(self.currRow)
  if likely(col != nil): dealloc col

template rowEntry(self: var CsvParser; entry: var string) =
  let index = create int
  index[] = self.headers.find(entry)
  if likely(index[] >= 0): entry = self.row[index[]] else: echo "ERROR: Key not found: " & entry
  if likely(index != nil): dealloc index

template readHeaderRow(self: var CsvParser) =
  if likely(self.readRow()): self.headers = self.row


# ^ CSV Parser ##################################### v CSV functions for Python


const html_table_header = """<!DOCTYPE html>
<html style="background-color:lightcyan">
<head>
  <meta charset="utf-8">
  <meta name="viewport" content="width=device-width, initial-scale=1">
  <link rel="stylesheet" href="https://cdnjs.cloudflare.com/ajax/libs/bulma/0.9.2/css/bulma.min.css" async defer >
</head>
<body><br><br>
  <div class="container is-fluid">
    <table class="table is-bordered is-striped is-hoverable is-fullwidth">"""

const karax_header = """
include karax/prelude  # nimble install karax http://github.com/pragmagic/karax

proc createDom(): VNode {.discardable.} =
  result = buildHtml(table):
    thead(class="thead"):
      tr(class="has-background-grey-light"):
"""

proc csv2htmltable*(csv_file_path, html_file_path: string = "",
    separator: char = ',', quote: char = '"', escape: char = '\x00';
    header_html: string = html_table_header): string {.exportpy.} =
  ## Stream Read CSV to HTML Table file and string.
  result.add header_html
  result.add "<thead class='thead'>\n<tr>\n"
  let parser {.noalias.} = create(CsvParser)
  parser[].open(csv_file_path, separator, quote, escape)
  parser[].readHeaderRow()
  for column in parser[].headers.items:
    result.add "<th class='has-background-grey-light'>"
    result.add $column
    result.add "</th>"
  result.add "</tr>\n</thead>\n<tfoot class='tfoot has-text-primary'>\n<tr>\n"
  for column in parser[].headers.items:
    result.add "<th class='has-background-grey-light'>"
    result.add $column
    result.add "</th>"
  result.add "</tr>\n</tfoot>\n<tbody class='tbody'>\n"
  while parser[].readRow():
    result.add "<tr>"
    for column in parser[].headers.mitems:
      result.add "<td>"
      parser[].rowEntry(column)
      result.add column
      result.add "</td>"
    result.add "</tr>\n"
  result.add "</tbody>\n</table>\n</div>\n</body>\n</html>\n"
  parser[].close()
  if html_file_path.len > 0: writeFile(html_file_path , result)
  if parser != nil: dealloc parser

proc csv2markdowntable*(csv_file_path, md_file_path: string = "",
    separator: char = ',', quote: char = '"', escape: char = '\x00'): string {.exportpy.} =
  ## CSV to MarkDown Table file and string.
  let parser {.noalias.} = create(CsvParser)
  parser[].open(csv_file_path, separator, quote, escape)
  parser[].readHeaderRow()
  for column in parser[].headers.items:
    result.add '|'
    result.add ' '
    result.add $column
    result.add ' '
  result.add "|\n| "
  result.add "---- | ".repeat(parser[].headers.len)
  result.add '\n'
  while parser[].readRow():
    for column in parser[].headers.mitems:
      result.add '|'
      result.add ' '
      parser[].rowEntry(column)
      result.add column
      result.add ' '
    result.add '|'
    result.add '\n'
  parser[].close()
  if md_file_path.len > 0: writeFile(md_file_path , result)
  if parser != nil: dealloc parser

proc csv2karax*(csv_file_path, nim_file_path: string = "", separator: char = ',',
  quote: char = '"', escape: char = '\x00'): string {.exportpy.} =
  ## CSV to Karax HTML Table.
  result.add karax_header
  let parser {.noalias.} = create(CsvParser)
  parser[].open(csv_file_path, separator, quote, escape)
  parser[].readHeaderRow()
  for column in parser[].headers.items:
    result.add "        th:\n          text(\"\"\"" & $column & "\"\"\")\n"
  result.add "    tfoot(class=\"tfoot has-text-primary\"):\n      tr(class=\"has-background-grey-light\"):\n"
  for column in parser[].headers.items:
    result.add "        th:\n         text(\"\"\"" & $column & "\"\"\")\n"
  result.add "    tbody(class=\"tbody\"):\n"
  while parser[].readRow():
    result.add "      tr:\n"
    for column in parser[].headers.mitems:
      parser[].rowEntry(column)
      result.add "        td:\n          text(\"\"\"" & column & "\"\"\")\n"
  result.add "\n\nsetRenderer(createDom)\n"
  parser[].close()
  if nim_file_path.len > 0: writeFile(nim_file_path, result)
  if parser != nil: dealloc parser

proc csv2xml*(csv_file_path, xml_file_path: string, columns: Natural = 32767; separator: char = ',',
    quote: char = '"', escape: char = '\x00'; header_xml: string = xmlHeader): string {.exportpy.} =
  ## Stream Read CSV to XML.
  result.add header_xml
  let parser {.noalias.} = create(CsvParser)
  let temp = create(seq[XmlNode])
  let e = create(XmlNode)
  parser[].open(csv_file_path, separator, quote, escape)
  parser[].readHeaderRow()
  while parser[].readRow():
    for column in parser[].headers.mitems:
      e[] = newElement(column)
      parser[].rowEntry(column)
      e[].add newText(column)
      temp[].add e[]
  parser[].close()
  result.add $newXmlTree("csv", temp[])
  if xml_file_path.len > 0: writeFile(xml_file_path, result)
  if parser != nil: dealloc parser
  if temp != nil: dealloc temp
  if e != nil: dealloc e
