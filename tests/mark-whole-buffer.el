(mark-whole-buffer)
(copy-region-as-kill (point) (mark))
(yank)
(save-buffer)
(save-buffers-kill-zi)
