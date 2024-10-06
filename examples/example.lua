local h = require"html"


local mobile = false

local function item(title)
  return h.DIV{
      style = {
        display = "flex",
        justify_content = mobile and "center",
        background_color  = mobile and "green"
      },
      class = {
        mobile and "button" or "card"
      },
      onclick = {},
      title
    }
end

local t = {"first", "second", "third"}

local items = {}
for k,v in ipairs(t) do
  table.insert(items, item(v))
end

print(
  h.HTML{
    h.BODY{
      h.DIV{
        mobile and "ok",
        not mobile and "item1",
        not not mobile and "item2",
      },
      items
    }
  }
)
