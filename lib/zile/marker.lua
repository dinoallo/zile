-- Marker facility functions
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


-- Marker datatype

local function marker_new (bp, o)
  local marker = {bp = bp, o = o}
  bp.markers[marker] = true
  return marker
end

function copy_marker (m)
  return marker_new (m.bp, m.o)
end

function point_marker ()
  return marker_new (cur_bp, get_buffer_pt (cur_bp))
end

function unchain_marker (marker)
  if marker.bp then
    marker.bp.markers[marker] = nil
  end
end


-- Mark ring

local mark_ring = {} -- Mark ring.

-- Push the current mark to the mark-ring.
function push_mark ()
  -- Save the mark.
  if cur_bp.mark then
    table.insert (mark_ring, copy_marker (cur_bp.mark))
  else
    -- Save an invalid mark.
    table.insert (mark_ring, marker_new (cur_bp, 0))
  end

  set_mark ()
  activate_mark ()
end

-- Pop a mark from the mark-ring and make it the current mark.
function pop_mark ()
  local m = mark_ring[#mark_ring]

  -- Replace the mark.
  if m.bp.mark then
    unchain_marker (m.bp.mark)
  end
  m.bp.mark = copy_marker (m)

  table.remove (mark_ring, #mark_ring)
  unchain_marker (m)
end

-- Set the mark to point.
function set_mark ()
  if cur_bp.mark then
    unchain_marker (cur_bp.mark)
  end
  cur_bp.mark = point_marker ()
end
