import std/[jsconsole, sugar], nodejs/jshttp
requireHttp()

func listener(request: HttpClientRequest, response: HttpServerResponse) =
  response.write_head 200, cstring"OK", {cstring"Content-Type": cstring"text/html"}
  response.write cstring"<h1> Hello World </h1>"
  response.ends cstring"<hr>"

let on_listen = () => console.log "on_listen"

let server = create_server listener
server.on_request () => console.log "on_request"
server.listen 8_000, "127.0.0.1", on_listen
