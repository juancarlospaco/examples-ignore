include karax/prelude
import std/sugar

var i = 0
proc example() =
  echo "Clicked ", i
  inc i

proc createDom(): VNode =
  result = buildHtml(tdiv):
    link(rel = "stylesheet", href = "https://cdnjs.cloudflare.com/ajax/libs/bulma/0.9.2/css/bulma.min.css")
    section(class = "hero"):
      section(class = "section"):
        tdiv(class = "container has-text-centered py-4"):
          h2(class = "title"):
            text "Team"
          p(class = "subtitle mb-6"):
            text "Meet the Team"
          tdiv(class = "columns is-centered is-multiline py-5"):
            tdiv(class = "column is-6 is-3-widescreen mb-6"):
              tdiv(class = "level"):
                tdiv(class = "level-item"):
                  figure(class = "image is-128x128"):
                    img(src = "https://source.unsplash.com/128x128/?kitten", width = "128", class = "is-rounded", height = "128", onclick = example)
              h5(class = "title is-5"):
                text "Fatto Catto"
              p(class = "subtitle is-6"):
                text "CEO"
            tdiv(class = "column is-6 is-3-widescreen mb-6"):
              tdiv(class = "level"):
                tdiv(class = "level-item"):
                  figure(class = "image is-128x128"):
                    img(src = "https://source.unsplash.com/128x129/?kitten", width = "128", class = "is-rounded", height = "128", onclick = example)
              h5(class = "title is-5"):
                text "Grumpy Cat"
              p(class = "subtitle is-6"):
                text "COO"
            tdiv(class = "column is-6 is-3-widescreen mb-6"):
              tdiv(class = "level"):
                tdiv(class = "level-item"):
                  figure(class = "image is-128x128"):
                    img(src = "https://source.unsplash.com/128x127/?kitten", width = "128", class = "is-rounded", height = "128", onclick = example)
              h5(class = "title is-5"):
                text "Catovich"
              p(class = "subtitle is-6"):
                text "CFO"
            tdiv(class = "column is-6 is-3-widescreen mb-6"):
              tdiv(class = "level"):
                tdiv(class = "level-item"):
                  figure(class = "image is-128x128"):
                    img(src = "https://source.unsplash.com/129x128/?kitten", width = "128", class = "is-rounded", height = "128", onclick = example)
              h5(class = "title is-5"):
                text "Cat Erine"
              p(class = "subtitle is-6"):
                text "Marketing"
            tdiv(class = "column is-6 is-3-widescreen mb-6"):
              tdiv(class = "level"):
                tdiv(class = "level-item"):
                  figure(class = "image is-128x128"):
                    img(src = "https://source.unsplash.com/127x128/?kitten", width = "128", class = "is-rounded", height = "128", onclick = example)
              h5(class = "title is-5"):
                text "Fluffly Cat"
              p(class = "subtitle is-6"):
                text "Chief"
            tdiv(class = "column is-6 is-3-widescreen mb-6"):
              tdiv(class = "level"):
                tdiv(class = "level-item"):
                  figure(class = "image is-128x128"):
                    img(src = "https://source.unsplash.com/126x128/?kitten", width = "128", class = "is-rounded", height = "128", onclick = example)
              h5(class = "title is-5"):
                text "Puss in Boots"
              p(class = "subtitle is-6"):
                text "Programmer"
            tdiv(class = "column is-6 is-3-widescreen mb-6"):
              tdiv(class = "level"):
                tdiv(class = "level-item"):
                  figure(class = "image is-128x128"):
                    img(src = "https://source.unsplash.com/128x126/?kitten", width = "128", class = "is-rounded", height = "128", onclick = example)
              h5(class = "title is-5"):
                text "Nyan Cat"
              p(class = "subtitle is-6"):
                text "Investor"
          button(class = "button is-rounded", onclick = () => echo "Hello World"):
            text "Say Hello"

setRenderer createDom
