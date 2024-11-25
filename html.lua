-----------------------------------------------------------------------------
-- A toolkit for constructing HTML pages.
-- @title HTML-Lua 0.1.
-- HTML-Lua offers a collection of constructors very similar to HTML elements,
-- but with "Lua style".
-- Heavily inspired by tomasguisasola htk: 
-- https://web.tecgraf.puc-rio.br/~tomas/htk/
-- Many thanks to him.
-- @release html-lua-0.1.lua geraldo
-----------------------------------------------------------------------------

-- Internal structure.
-- The field [[valid_tags]] stores the names of the HTML elements that
-- can be built on-demand.
-- All element constructors are named in capital letters.

local getmetatable, pairs, setmetatable, tonumber, type = getmetatable, pairs, setmetatable, tonumber, type
local format, match, strfind, strlen = string.format, string.match, string.find, string.len
local tinsert, tremove = table.insert, table.remove


local _M = {
	_COPYRIGHT = "Copyright (C) 2024 PUC-Rio",
	_DESCRIPTION = "HTML is a library of Lua constructors that create HTML elements.",
	_VERSION = "HTML-Lua 0.1",
}

_M.class_defaults = {}

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

function _M.CSS(obj)
	local atts = {}
	for k,v in pairs(obj) do
		if type(v) ~= "boolean" then
			table.insert(atts, k .. ":" .. v .. "; ")
		end
	end
	return table.concat(atts, "")
end

function _M.BOX (obj)
	local separator = obj.separator or ''
	local s = ""
	for k, v in pairs(obj) do
		if type(k) == "number" and type(v) ~= "boolean" and v ~= nil then
			s = format ('%s%s%s', s, v, separator)
		end
	end
	return s
end



local function hash_table_concat(t, sep)
    local elements = {}
    sep = sep or ""
    local i = 1
    for _,v in ipairs(t) do
    	if type(v) ~= "boolean" then
				elements[i] = v
				i = i + 1
			end
    end
    for k, v in pairs(t) do
        if not elements[k] and type(v) ~= "boolean" then
            table.insert(elements, tostring(v))
        end
    end
    return table.concat(elements, sep)
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
		local contain = {}
		local s = newStack ()
		addString (s, '<'..field)
		if type(obj) == "string" then
		  addString (s, '>'..separator)
		  addString(s, obj)
			addString (s, '</'..field..'>')
			return toString(s)
		end
    assert(type(obj)=="table", obj)
    local idx = 0
		for i, v in pairs (obj) do
			if type(i) == "number" then
				idx = idx + 1
				contain[idx] = v
			elseif i == "style" and type(v) == "table" then
				local new_v = {}
				for att, value in pairs(v) do
					local new_att = att:gsub("_", "-")
					new_v[new_att] = value
				end
				local el = _M.CSS(new_v)
				addString(s, format (' %s="%s"', "style", el ))
			elseif i == 'class' and type(v) == "table" then
				addString(s, format (' %s="%s"', "class", hash_table_concat(v, " ")))
			elseif i ~= "separator" then
				if v == true then -- Ex: 'hidden = true' turns into just 'hidden'
					addString (s, format (' %s', i:gsub("_", "-") ))
				else
					local tt = type(v)
					if tt == "string" or tt == "number" then
						addString (s, format (' %s="%s"', i:gsub("_", "-"), v))
					end
				end
			end
		end
		if not obj.class and _M.class_defaults[field] then
			addString (s, format (' class="%s"', _M.class_defaults[field]))
		end
		addString (s, '>'..separator)
		local n = false
		-- table.sort(contain)
		for i,el in ipairs(contain) do
			n = true
			if type(el) == "table" then
				el = _M.BOX(el)
			end
			if type(el) == "string" or type(el) == "number" then
				addString (s, el)
				addString (s, separator)
			end
		end
		if n or (true) then
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
		if true then
			-- On-demand constructor builder
			local c = build_constructor (field)
			_M[field] = c
			return c
		elseif old_index then
			return old_index (obj, field)
		end
	end,
})

return _M
