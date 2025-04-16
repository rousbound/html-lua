-----------------------------------------------------------------------------
-- A toolkit for constructing HTML pages.
-- @title HTML-Lua 0.3.
-- HTML-Lua offers a collection of constructors very similar to HTML elements,
-- but with "Lua style".
-- Heavily inspired by tomasguisasola htk: 
-- https://web.tecgraf.puc-rio.br/~tomas/htk/
-- Many thanks to him.
-- @release html-lua-0.3.lua geraldo
-----------------------------------------------------------------------------

-- Internal structure.
-- The field [[valid_tags]] stores the names of the HTML elements that
-- can be built on-demand.
-- All element constructors are named in capital letters.

local getmetatable, pairs, setmetatable, tonumber, type = getmetatable, pairs, setmetatable, tonumber, type
local format, match, strfind, strlen = string.format, string.match, string.find, string.len
local tinsert, tremove = table.insert, table.remove


local _M = {
	_COPYRIGHT = "Copyright (C) 2025 PUC-Rio",
	_DESCRIPTION = "HTML is a library of Lua constructors that create HTML elements.",
	_VERSION = "HTML-Lua 0.3",
}

-- stack of strings.
-- from ltn009 (by Roberto Ierusalimschy)
local function newStack ()
	return { n = 0 }
end

local function addString (stack, s)
	tinsert (stack, s)
	for i = #stack-1, 1, -1 do
		if strlen(stack[i]) > strlen (stack[i+1]) then
			break
		end
		stack[i] = stack[i]..tremove(stack)
	end
end

local function toString (stack)
	for i = #stack-1, 1, -1 do
		stack[i] = stack[i]..tremove(stack)
	end
	return stack[1]
end

local function BOX (obj)
	local separator = obj.separator or ''
	local s = ""
	for k, v in pairs(obj) do
		if type(k) == "number" and type(v) ~= "boolean" and v ~= nil then
			s = format ('%s%s%s', s, v, separator)
		end
	end
	return s
end



local function underscore_to_dash(identifier)
  return identifier:gsub("_", "-")
end

local function style_concat(t)
	local css = {}
    for k, v in pairs(t) do
        if type(v) ~= "boolean" then
						k = underscore_to_dash(k)
            table.insert(css, k .. ":" .. v)
        end
    end
	return table.concat(css, ";")
end


function string.split(str, delimiter)
    local result = {}
    local pattern = "([^" .. delimiter .. "]+)"
    for match in string.gmatch(str, pattern) do
        table.insert(result, match)
    end
    return result
end


local function class_concat(t)
	local classes = {}
    for k,v in ipairs(t) do
    	if type(v) ~= "boolean" then
				classes[k] = v
			end
    end
    for modifier, class_list in pairs(t) do -- recursive part
    		if type(modifier) == "string" then
	        if type(class_list) == "string" then
	        	class_list = string.split(class_list, " ")
	        end
	        if type(class_list) == "table" then
		        for _, class in pairs(class_list) do
		        	if type(class) == "string" then
		        		table.insert(classes, modifier..":"..class)
		        	elseif type(class) == "table" then
		        		-- recursive here
		        	end
		        end
		      end
		    end
    end
	return table.concat(classes, " ")
end

--- Lua doesn't guarantee iteration order of numbered index with pairs
--  So, a security measure is to force-sort them
---@param tbl any
---@return table
local function reindex_table(tbl)
    local new_tbl = {}
    local indices = {}
    -- Collect all numeric indices
    for k, _ in pairs(tbl) do
        table.insert(indices, k)
    end
    -- Sort the indices
    table.sort(indices)
    -- Populate the new table with consecutive indices
    local index = 1
    for _, k in ipairs(indices) do
        new_tbl[index] = tbl[k]
        index = index + 1
    end
    return new_tbl
end



-- Build an HTML element constructor.
-- The resulting function -- the constructor -- will receive a table
-- representing the HTML element.
-- This table can hold the attributes of the element and its content, i.e.,
-- other elements that will be "inside" it.
-- All HTML elements have a special attribute called [[separator]];
-- it can be used to store a string that will be "printed" between
-- every content-element.
-- @param field String with the name of the tag.
-- @return Function that makes an HTML element represented by a table.

local function build_constructor (field)
	return function (obj)
		local separator = obj.separator or ''
		local innerHTML = {}
		local s = newStack ()
		addString (s, '<'..field)

		-- h.H1"Title"
		if type(obj) == "string" then
		  addString (s, '>'..separator)
		  addString(s, obj)
			addString (s, '</'..field..'>')
			return toString(s)
		end
    assert(type(obj)=="table", obj)
		for k, v in pairs (obj) do

			-- h.DIV{ "hello", "world", }
			if type(k) == "number" then
				innerHTML[k] = v

			-- h.H1{style = {color = 'black', background = 'red', justify_content = 'center'}}
			elseif k == "style" and type(v) == "table" then
				addString(s, format (' style ="%s"', style_concat(v)))

			-- h.H1{class = {'text-black', 'bg-red-300', 'justify-center', md = {'w-full'}, lg = "text-lg" }}
			elseif k == 'class' and type(v) == "table" then
				addString(s, format (' class="%s"', class_concat(v)))

			elseif k ~= "separator" then
				if v == true then
				-- h.H1{hidden = true}
					addString (s, format (' %s', underscore_to_dash(k) ))
				else
				-- h.H1{onclick = "alert(1);"}
					local tt = type(v)
					if tt == "string" or tt == "number" then
						addString (s, format (' %s="%s"', underscore_to_dash(k), v))
					end
				end
			end
		end
		addString (s, '>'..separator)
		innerHTML = reindex_table(innerHTML)
		for i,el in ipairs(innerHTML) do
			if type(el) == "table" then
				-- unpack tables "automatically"
				el = BOX(el)
			end
			if type(el) == "string" or type(el) == "number" then
				addString (s, el)
				addString (s, separator)
			end
		end
		if next(obj) then
			-- not all tags need a closing tag, like <BR>
			addString (s, '</'..field..'>')
		end
		return toString (s)
	end
end

-- Implements the "on-demand constructor builder" mechanism.
-- It works like the inheritance mechanism but if the index is a
-- valid tag then the constructor builder is called and the resulting
-- function is returned.
-- @param obj Table representing the object.
-- @param field Index of the table.
-- @return [[ obj[field] ]].
setmetatable (_M, {
	__index = function (obj, field)
		return build_constructor (field)
	end,
})

return _M

