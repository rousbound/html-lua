-----------------------------------------------------------------------------
-- A toolkit for constructing HTML pages.
-- @title HTML-Lua 0.4.
-- HTML-Lua offers a DSL in Lua to generate HTML tags.
-- Heavily inspired by tomasguisasola htk: 
-- https://web.tecgraf.puc-rio.br/~tomas/htk/
-- Many thanks to him.
-- @release html-lua-0.4.lua geraldo
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
	_VERSION = "HTML-Lua 0.4",
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

			elseif k == "style" and type(v) == "table" then
				addString(s, format (' style ="%s"', v))

			elseif k == 'class' and type(v) == "table" then
				addString(s, format (' class="%s"', v))

			elseif k ~= "separator" then
				if v == true then
				-- h.H1{hidden = true}
					addString (s, format (' %s', k ))
				else
				-- h.H1{onclick = "alert(1);"}
					local tt = type(v)
					if tt == "string" or tt == "number" then
						addString (s, format (' %s="%s"', k, v))
					end
				end
			end
		end
		addString (s, '>'..separator)
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

