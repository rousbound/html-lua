package.path = "?.lua"
local h = require"html"


local is_admin = true
local anonymous_user = false
local special_user

local function item(title)
  return h.DIV{
      -- You can use either strings or tables in style key
      style = {
        display = "flex",
        text_align = anonymous_user and "center",
        justify_content = is_admin and "center" or "left",
        color = special_user and "black",
        background_color  = is_admin and "green" or "gray"
      },
      -- you can also use just strings
      -- style = "display: flex; justify-content: center;"
      -- Same for the class key
      class = {
        is_admin and "button" or "card",
        anonymous_user and "bg-gray",
        special_user and "font-serif",
        "justify-center"
      },
      -- or class = "button card"
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
      -- Tables are automatically expanded and concatenated
      items
    }
  }
)
