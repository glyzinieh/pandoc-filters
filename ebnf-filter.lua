-- ebnf-filter.lua
-- ```ebnf を Typst で色分けする。
-- Typst 0.15 は作業ディレクトリの外にある構文定義を読めないため、
-- 定義をその場へコピーしてから #set raw(syntaxes: ...) を文書先頭へ入れる。

local copied = false

local function copy_syntax()
  if copied then
    return true
  end
  local datadir = pandoc.path.directory(
    pandoc.path.directory(PANDOC_SCRIPT_FILE)
  )
  local source = pandoc.path.join({ datadir, "syntaxes", "ebnf.sublime-syntax" })
  local input = io.open(source, "rb")
  if not input then
    io.stderr:write("Error: EBNF syntax definition was not found: " .. source .. "\n")
    return false
  end
  local output = io.open("ebnf.sublime-syntax", "wb")
  if not output then
    input:close()
    io.stderr:write("Error: Could not copy the EBNF syntax definition.\n")
    return false
  end
  output:write(input:read("a"))
  input:close()
  output:close()
  copied = true
  return true
end

function Pandoc(doc)
  local uses_ebnf = false
  pandoc.walk_block(pandoc.Div(doc.blocks), {
    CodeBlock = function(cb)
      if cb.classes[1] == "ebnf" then
        uses_ebnf = true
      end
    end,
  })
  if not uses_ebnf or not copy_syntax() then
    return nil
  end
  if FORMAT ~= "typst" then
    return nil
  end
  local setup = pandoc.RawBlock(
    "typst",
    '#set raw(syntaxes: "ebnf.sublime-syntax")'
  )
  doc.blocks:insert(1, setup)
  return doc
end
