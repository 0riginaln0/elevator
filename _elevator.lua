-- mod-version:3
--
-- Go to next/previous symbol in the current document.
-- Language support is defined in the `langs` table below; each entry
-- provides file extensions and a list of line patterns that count as
-- symbol declarations.

local core = require "core"
local command = require "core.command"
local keymap = require "core.keymap"
local DocView = require "core.docview"

-------------------
-- Configuration --
-------------------

local langs = {
  {
    extensions = { "c3", "c3i" },
    patterns = {
      "^%s*fn%s",
      "^%s*struct%s",
      "^%s*enum%s",
      "^%s*macro%s",
      "^%s*fault%s",
      "^%s*interface%s",
    },
  },
}

-----------------------
-- Configuration end --
-----------------------

local function get_doc()
  if getmetatable(core.active_view) == DocView then
    return core.active_view.doc
  end
end

local function table_contains(t, element)
  for _, value in pairs(t) do
    if value == element then return true end
  end
  return false
end

-- Returns the lang config matching the current file's extension, or nil.
local function get_lang(doc)
  local filename = doc:get_name()
  local extension = filename and filename:match("%.([^%.]+)$") or ""
  for _, lang in ipairs(langs) do
    if table_contains(lang.extensions, extension) then
      return lang
    end
  end
end

local function is_symbol_line(lang, text)
  for _, pattern in ipairs(lang.patterns) do
    if text:match(pattern) then return true end
  end
  return false
end

local function goto_symbol(direction)
  local doc = get_doc()
  if not doc then return end

  local lang = get_lang(doc)
  if not lang then
    core.status_view:show_message("No symbol patterns for this file type")
    return
  end

  local line = doc:get_selection()
  local n = #doc.lines
  local i = line + direction

  while i >= 1 and i <= n do
    if is_symbol_line(lang, doc.lines[i] or "") then
      local col = (doc.lines[i]:find("%S")) or 1
      doc:set_selection(i, col, i, col)
      core.active_view:scroll_to_make_visible(i, col)
      return
    end
    i = i + direction
  end

  core.status_view:show_message("No more symbols " ..
    (direction > 0 and "below" or "above"))
end

command.add("core.docview", {
  ["_elevator:down"]     = function() goto_symbol(1) end,
  ["_elevator:up"] = function() goto_symbol(-1) end,
})

keymap.add {
  ["ctrl+down"] = "_elevator:down",
  ["ctrl+up"]   = "_elevator:up",
}
