# Simple example demo using CSV to generate HTML, Markdown, XML, JavaScript Frontends.
import core

def main():
  filename = "covid.csv"
  core.csv2htmltable(filename, "out.html")
  core.csv2markdowntable(filename, "out.md")
  core.csv2xml(filename, "out.xml")
  core.csv2karax(filename, "out.nim")

if __name__ == "__main__":
  main()
