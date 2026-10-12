-- drawio-filter.lua
local function is_windows()
  return package.config:sub(1, 1) == "\\"
end

-- インストール先は環境ごとに異なるため、PATH 上のコマンドだけを使う。
-- Windows のデスクトップ版は draw.io.exe、その他の環境は drawio という名前になる。
local function command_on_path(name)
  local probe
  if is_windows() then
    probe = "where " .. name .. " >nul 2>nul"
  else
    probe = "command -v " .. name .. " >/dev/null 2>&1"
  end
  return os.execute(probe) and true or false
end

local function find_drawio()
  local names = is_windows() and { "drawio", "draw.io" } or { "drawio" }
  for _, name in ipairs(names) do
    if command_on_path(name) then
      return name
    end
  end
end

local function quote_arg(value)
  value = tostring(value)
  if is_windows() then
    return '"' .. value:gsub('"', '""') .. '"'
  end
  return "'" .. value:gsub("'", "'\\''") .. "'"
end

function CodeBlock(cb)
  -- ```drawio のコードブロックを対象にする
  if cb.classes[1] == "drawio" then
    -- ハッシュを使って一意なファイル名を生成
    local hash = pandoc.sha1(cb.text):sub(1, 10)
    local drawio_filename = "diagram_" .. hash .. ".drawio"
    -- SVG はラベルが foreignObject になり、Typst では文字が欠ける
    -- (https://github.com/typst/typst/issues/1421)。PDF ならそのまま埋め込める。
    local pdf_filename = "diagram_" .. hash .. ".pdf"
    
    -- 1. コードの内容を .drawio ファイルとして書き出す
    local file = io.open(drawio_filename, "w")
    if file then
      file:write(cb.text)
      file:close()
    else
      io.stderr:write("Error: Could not create temporary drawio file.\n")
      return cb
    end
    
    -- 2. Draw.io CLI で PDF に変換する
    local drawio = find_drawio()
    if not drawio then
      io.stderr:write("Error: Failed to convert drawio diagram.\n")
      io.stderr:write("drawio was not found on PATH. On Windows, add the directory containing draw.io.exe to PATH.\n")
      return cb
    end

    local cmd = table.concat({
      drawio,
      "-x", "-f", "pdf",
      "--crop",
      quote_arg(drawio_filename),
      "-o", quote_arg(pdf_filename),
    }, " ")
    local success = os.execute(cmd)
    
    if not success then
      io.stderr:write("Error: Failed to convert drawio diagram.\n")
      io.stderr:write("Command: " .. cmd .. "\n")
      return cb
    end
    
    -- 3. コードブロックを画像（Image）要素に置き換える
    -- Typst 0.11 以降は PDF を image() で埋め込める
    return pandoc.Para({ pandoc.Image({}, pdf_filename) })
  end
end
