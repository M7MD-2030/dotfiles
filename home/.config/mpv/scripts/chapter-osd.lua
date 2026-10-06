-- Shows the chapter title on screen whenever the chapter changes
mp.observe_property("chapter", "number", function(_, c)
  if not c or c < 0 then return end
  local title = mp.get_property("chapter-metadata/title")
  if not title or title == "" then title = "Chapter " .. (c + 1) end
  mp.osd_message(title, 2)
end)
