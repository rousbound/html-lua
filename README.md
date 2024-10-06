# Usage

```lua
local h = require"html"

local mobile = true

local function item(title)
  return h.DIV{
      -- You can use either strings or tables in style key
      style = {
        display = "flex",
        justify_content = mobile and "center" or "left",
        background_color  = mobile and "green" or "gray"
      },
      -- Same for the class key
      class = {
        mobile and "button" or "card"
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
      -- Tables are automatically expanded and concatenated
      items
    }
  }
)
```
