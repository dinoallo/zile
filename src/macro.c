/* Macro facility functions
   Copyright (c) 1997-2004 Sandro Sigala.  All rights reserved.

   This file is part of Zile.

   Zile is free software; you can redistribute it and/or modify it under
   the terms of the GNU General Public License as published by the Free
   Software Foundation; either version 2, or (at your option) any later
   version.

   Zile is distributed in the hope that it will be useful, but WITHOUT ANY
   WARRANTY; without even the implied warranty of MERCHANTABILITY or
   FITNESS FOR A PARTICULAR PURPOSE.  See the GNU General Public License
   for more details.

   You should have received a copy of the GNU General Public License
   along with Zile; see the file COPYING.  If not, write to the Free
   Software Foundation, 59 Temple Place - Suite 330, Boston, MA
   02111-1307, USA.  */

/*	$Id: macro.c,v 1.12 2005/01/30 23:24:34 rrt Exp $	*/

#include "config.h"

#include <assert.h>
#include <stdarg.h>
#include <stdio.h>
#include <stdlib.h>
#include <string.h>

#include "zile.h"
#include "extern.h"


static Macro *cur_mp, *head_mp = NULL;

void add_macro_key(size_t key)
{
  cur_mp->keys = zrealloc(cur_mp->keys, sizeof(size_t) * ++cur_mp->nkeys);
  cur_mp->keys[cur_mp->nkeys - 1] = key;
}

void cancel_kbd_macro(void)
{
  free_macros();
  cur_mp = NULL;
  thisflag &= ~FLAG_DEFINING_MACRO;
}

DEFUN("start-kbd-macro", start_kbd_macro)
  /*+
    Record subsequent keyboard input, defining a keyboard macro.
    The commands are recorded even as they are executed.
    Use C-x ) to finish recording and make the macro available.
    Use M-x name-last-kbd-macro to give it a permanent name.
    +*/
{
  if (thisflag & FLAG_DEFINING_MACRO) {
    minibuf_error("Already defining a keyboard macro");
    return FALSE;
  }

  if (cur_mp)
    cancel_kbd_macro();

  minibuf_write("Defining keyboard macro...");

  thisflag |= FLAG_DEFINING_MACRO;
  cur_mp = (Macro *)zmalloc(sizeof(Macro));
  return TRUE;
}

DEFUN("end-kbd-macro", end_kbd_macro)
  /*+
    Finish defining a keyboard macro.
    The definition was started by C-x (.
    The macro is now available for use via C-x e.
    +*/
{
  if (!(thisflag & FLAG_DEFINING_MACRO)) {
    minibuf_error("Not defining a keyboard macro");
    return FALSE;
  }

  thisflag &= ~FLAG_DEFINING_MACRO;
  return TRUE;
}

DEFUN("name-last-kbd-macro", name_last_kbd_macro)
  /*+
    Assign a name to the last keyboard macro defined.
    Argument SYMBOL is the name to define.
    The symbol's function definition becomes the keyboard macro string.
    Such a "function" cannot be called from Lisp, but it is a valid editor command.
    +*/
{
  char *ms;
  Macro *mp;
  size_t size;

  if ((ms = minibuf_read("Name for last kbd macro: ", "")) == NULL) {
    minibuf_error("No command name given");
    return FALSE;
  }

  if (cur_mp == NULL) {
    minibuf_error("No keyboard macro defined");
    return FALSE;
  }

  if ((mp = get_macro(ms))) {
    /* If a macro with this name already exists, update its key list */
    free(mp->keys);
  } else {
    /* Add a new macro to the list */
    mp = zmalloc(sizeof(*mp));
    mp->next = head_mp;
    mp->name = zstrdup(ms);
    head_mp = mp;
  }

  /* Copy the keystrokes from cur_mp. */
  mp->nkeys = cur_mp->nkeys;
  size = sizeof(*(mp->keys)) * mp->nkeys;
  mp->keys = zmalloc(size);
  memcpy(mp->keys, cur_mp->keys, size);

  return TRUE;
}

int call_macro(Macro *mp)
{
  int ret = TRUE;
  int old_thisflag = thisflag;
  int old_lastflag = lastflag;
  size_t i;

  for (i = mp->nkeys - 1; i < mp->nkeys ; i--)
    term_ungetkey(mp->keys[i]);

  if (lastflag & FLAG_GOT_ERROR)
    ret = FALSE;

  thisflag = old_thisflag;
  lastflag = old_lastflag;

  return ret;
}

DEFUN("call-last-kbd-macro", call_last_kbd_macro)
  /*+
    Call the last keyboard macro that you defined with C-x (.
    A prefix argument serves as a repeat count.  Zero means repeat until error.

    To make a macro permanent so you can call it even after
    defining others, use M-x name-last-kbd-macro.
    +*/
{
  int uni, ret = TRUE;

  if (cur_mp == NULL) {
    minibuf_error("No kbd macro has been defined");
    return FALSE;
  }

  undo_save(UNDO_START_SEQUENCE, cur_bp->pt, 0, 0);
  if (uniarg == 0)
    while (call_macro(cur_mp));
  else {
    for (uni = 0; uni < uniarg; ++uni)
      if (!call_macro(cur_mp)) {
        ret = FALSE;
        break;
      }
  }
  undo_save(UNDO_END_SEQUENCE, cur_bp->pt, 0, 0);

  return ret;
}

static void macro_delete(Macro *mp)
{
  assert(mp);
  free(mp->keys);
  free(mp);
}

/*
 * Free all the macros (used at Zile exit).
 */
void free_macros(void)
{
  Macro *mp, *next;

  if (cur_mp)
    macro_delete(cur_mp);

  for (mp = head_mp; mp; mp = next) {
    next = mp->next;
    macro_delete(mp);
  }
}

/*
 * Find a macro given its name.
 */
Macro *get_macro(char *name)
{
  Macro *mp;
  assert(name);
  for (mp = head_mp; mp; mp = mp->next)
    if (!strcmp(mp->name, name))
      return mp;
  return NULL;
}
