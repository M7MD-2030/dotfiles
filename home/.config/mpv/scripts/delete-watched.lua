-- Permanently deletes a video after it has been watched to the very end.
-- Only touches files inside ~/Youtube. Skipping, quitting, or errors never delete.
local utils = require "mp.utils"
local root = os.getenv("HOME") .. "/Youtube/"
local current = nil

mp.register_event("file-loaded", function()
  local p = mp.get_property("path")
  current = nil
  if not p or p:match("^%a+://") then return end
  if p:sub(1, 1) ~= "/" then
    p = utils.join_path(mp.get_property("working-directory"), p)
  end
  current = p
end)

mp.register_event("end-file", function(e)
  local p = current
  current = nil
  if e.reason ~= "eof" or not p or p:sub(1, #root) ~= root then return end

  local ok, err = os.remove(p)
  if ok then
    mp.commandv("delete-watch-later-config", p)
    local dir = p:match("^(.*)/[^/]+$")
    if dir and dir .. "/" ~= root then os.remove(dir) end -- removes the folder only if it's now empty
    mp.msg.info("deleted watched video: " .. p)
  else
    mp.msg.warn("could not delete: " .. tostring(err))
  end
end)
