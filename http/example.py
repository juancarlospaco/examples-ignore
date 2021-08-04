# Simple example demo using HTTP web scraper based on CSS selectors.
import core

def main():
  print("Scraper that collects all links from an URL using Regexes")
  print(core.scraper_regex(list_of_urls=["https://python.org"], list_of_regex=["(www|http:|https:)+[^\s]+[\w]"]))
  print("\nScraper that collects all specific text from an URL using CSS Selectors")
  print(core.scraper_css_selector(url="https://quotes.toscrape.com", css_selector="body > div.container > div.row > div > div.quote span.text"))

if __name__ == "__main__":
  main()
