-- Callbacks required by Zile.
--
-- Copyright (c) 2010-2013 Free Software Foundation, Inc.
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

local lisp = require "zmacs.eval"

-- Used to process keyboard macros, and to maintain identical behaviour
-- between the user typing and a keyboard macro sending keys, also used
-- for the main loop after initialization.
function get_and_run_command ()
  local keys = get_key_sequence ()
  local name = get_function_by_keys (keys)
  minibuf_clear ()

  if lisp.function_exists (name) then
    lisp.call_command (name, lastflag.set_uniarg and (prefix_arg or 1))
  else
    minibuf_error (tostring (keys) .. " is undefined")
  end
end


-- Read a function name from the minibuffer.
local functions_history = history_new ()

function minibuf_read_function_name (fmt)
  local cp = completion_new ()

  for name, func in lisp.commands () do
    if func.interactive then
      table.insert (cp.completions, name)
    end
  end

  return minibuf_vread_completion (fmt, "", cp, functions_history,
                                   "No function name given",
                                   "Undefined function name `%s'")
end
