-- Lua implementation of estr
--
-- Copyright (c) 2011-2012 Free Software Foundation, Inc.
--
-- This file is part of GNU Zile.
--
-- This program is free software; you can redistribute it and/or modify it
-- under the terms of the GNU General Public License as published by
-- the Free Software Foundation; either version 3, or (at your option)
-- any later version.
--
-- This program is distributed in the hope that it will be useful, but
-- WITHOUT ANY WARRANTY; without even the implied warranty of
-- MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the GNU
-- General Public License for more details.
--
-- You should have received a copy of the GNU General Public License
-- along with this program.  If not, see <http://www.gnu.org/licenses/>.

AStr = Object {
  _init = function (self, s)
    self.s = s
    return self
  end,

  __tostring = function (self)
    return self.s
  end,

  len = function (self) -- FIXME: In Lua 5.2 use __len metamethod (doesn't work for tables in 5.1)
    return #self.s
  end,

  sub = function (self, from, to)
    return self.s:sub (from, to)
  end,

  move = function (self, to, from, n)
    assert (math.max (from, to) + n <= self.s:len ())
    self.s = self.s:sub (1, to) .. self.s:sub (from + 1, from + n) .. self.s:sub (to + n + 1)
  end,

  set = function (self, from, c, n)
    assert (from + n <= self.s:len ())
    self.s = self.s:sub (1, from) .. string.rep (c, n) .. self.s:sub (from + n + 1)
  end,

  remove = function (self, from, n)
    assert (from + n <= self.s:len ())
    self.s = self.s:sub (1, from) .. self.s:sub (from + n + 1)
  end,

  insert = function (self, from, n)
    self.s = self.s:sub (1, from) .. string.rep ('\0', n) .. self.s:sub (from + 1)
  end,

  replace = function (self, pos, rep)
    self.s = self.s:sub (1, pos) .. rep .. self.s:sub (pos + 1 + #rep)
  end,

  find = function (self, s, from)
    return self.s:find (s, from)
  end,

  rfind = function (self, s, from)
    return find_substr (self.s, "", s, 0, from, false, true, true, false, false)
  end
}

BStr = AStr {
}

-- Formats of end-of-line
coding_eol_lf = "\n"
coding_eol_crlf = "\r\n"
coding_eol_cr = "\r"

-- Maximum number of EOLs to check before deciding EStr type arbitrarily.
local max_eol_check_count = 3

EStr = Object {
  _init = function (self, s, eol)
    self.s = s
    if type (s) == "string" then
      self.s = AStr (s)
    end
    if eol then -- if eol supplied, use it
      self.eol = eol
    else -- otherwise, guess
      local first_eol = true
      local total_eols = 0
      self.eol = coding_eol_lf
      local i = 1
      while i <= #s and total_eols < max_eol_check_count do
        local c = s[i]
        if c == '\n' or c == '\r' then
          local this_eol_type
          total_eols = total_eols + 1
          if c == '\n' then
            this_eol_type = coding_eol_lf
          elseif i == #s or s[i + 1] ~= '\n' then
            this_eol_type = coding_eol_cr
          else
            this_eol_type = coding_eol_crlf
            i = i + 1
          end

          if first_eol then
            -- This is the first end-of-line.
            self.eol = this_eol_type
            first_eol = false
          elseif self.eol ~= this_eol_type then
            -- This EOL is different from the last; arbitrarily choose LF.
            self.eol = coding_eol_lf
            break
          end
        end
        i = i + 1
      end
    end
    return self
  end,

  __tostring = function (self)
    return tostring (self.s)
  end,

  prev_line = function (self, o)
    local so = self:start_of_line (o)
    return so ~= 0 and self:start_of_line (so - #self.eol) or nil
  end,

  next_line = function (self, o)
    local eo = self:end_of_line (o)
    return eo ~= self.s:len () and eo + #self.eol or nil
  end,

  start_of_line = function (self, o)
    local prev = self.s:rfind (self.eol, o)
    return prev and (prev + #self.eol - 1) or 0
  end,

  end_of_line = function (self, o)
    local next = self.s:find (self.eol, o + 1)
    return next and next - 1 or self.s:len ()
  end,

  lines = function (self)
    local lines = 0
    local s = 1
    local next
    repeat
      next = self.s:find (self.eol, s)
      if next then
        lines = lines + 1
        s = next + #self.eol + 1
      end
    until not next
    return lines
  end,

  replace = function (self, pos, src)
    local s = 1
    local len = src.s:len ()
    while len > 0 do
      local next = src.s:find (src.eol, s)
      local line_len = next and next - s or len
      self.s:replace (pos, src.s:sub (s, s + line_len))
      pos = pos + line_len
      len = len - line_len
      s = next
      if len > 0 then
        self.s:replace (pos, self.eol)
        s = s + #src.eol
        len = len - #src.eol
        pos = pos + #self.eol
      end
    end
    return self
  end,

  cat = function (self, src)
    local oldlen = self.s:len ()
    self.s:insert (oldlen, src:len (self.eol))
    return self:replace (oldlen, src)
  end,

  bytes = function (self)
    return self.s:len ()
  end,

  len = function (self, eol_type) -- FIXME in Lua 5.2 use __len metamethod
    return self:bytes () + self:lines () * (#eol_type - #self.eol)
  end,

  sub = function (self, from, to)
    return self.s:sub (from, to)
  end,

  move = function (self, to, from, n)
    self.s:move (to, from, n)
  end,

  set = function (self, from, c, n)
    self.s:set (from, c, n)
  end,

  remove = function (self, from, n)
    self.s:remove (from, n)
  end,

  insert = function (self, from, n)
    self.s:insert (from, n)
  end
}