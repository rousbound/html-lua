package.path = "?.lua"
local h = require"html"


local is_admin = true
local anonymous_user = false
local special_user
local mobile = false

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
      -- or style = "display: flex; justify-content: center;"

      class = {
        is_admin and "button" or "card",
        anonymous_user and "bg-gray",
        special_user and "font-serif",
        "justify-center",
        md = {"text-lg", "w-full"},
        lg = {
          false and "text-2lg",
          "shadow-md",
          nil,
          active = { -- not working yet
            "text-red-600"
          },
          'hover:text-blue-500'
         }
      },
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
      h.BR{},
      h.BR{},
      h.BR{},
      -- h.H1{
      --  style = {} 
      -- },
      h.DIV{
        mobile and "ok",
        not mobile and "item1",
        not not mobile and "item2",
        "item3",
        "item4",
        not not mobile and "item5",
        "item6",
        "item7",
      },
      items
    }
  }
)
