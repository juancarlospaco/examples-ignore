import std/macros

macro unrollStringOps(loop: ForLoopStmt) =
  result = newStmtList()
  for chara in loop[^2][^2].strVal:
    result.add nnkAsgn.newTree(loop[^2][^1], chara.newLit)
    result.add loop[^1]



var it: char
var output: string

expandMacros:
  for _ in unrollStringOps("simple example", it):
    output.add it

assert output == "simple example"
