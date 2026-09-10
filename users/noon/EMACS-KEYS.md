# Emacs keybindings

Generated from `init.el` by `emacs-cheatsheet.el`. Do not edit by hand.

Only keys this configuration binds itself are listed. Evil's own
motions and the defaults that ship with magit, dired and
evil-collection are not.

## Prefix keys

| Type | Then you are in |
|---|---|
| `TAB` | `noon-tab-map` |
| `TAB p` or `C-c p` | `projectile-command-map` |

## Global (normal state)

| Key | Command | Does |
|---|---|---|
| `.` | *evil-easymotion* | prefix: follow with a motion (w, e, j, f, ...) to jump to a target |
| `SPC` | `save-buffer` | Save current buffer in visited file if modified. |
| `r` | `evil-repeat` | Repeat the last editing command with count replaced by COUNT. |
| `j` | `evil-next-visual-line` | Move the cursor COUNT screen lines down. |
| `k` | `evil-previous-visual-line` | Move the cursor COUNT screen lines up. |
| `, SPC` | `evil-ex-nohighlight` | Disable the active search highlightings. |
| `,p` | keyboard macro `"+p` | replays the keys `"+p` |
| `,y` | keyboard macro `"+y` | replays the keys `"+y` |
| `Y` | *unbound* | removed, so the key falls through |
| `YY` | `noon/copy-buffer` | Copy the entire buffer to the system clipboard. |
| `\\` | `evil-commentary-line` | Comment or uncomment [count] lines. |
| `ga` | `evil-lion-left` | Align the text in the given region using CHAR. |
| `gA` | `evil-lion-right` | Align the text in the given region using CHAR. |
| `,gs` | `magit-status` | Show the status of the current Git repository in a buffer. |
| `TAB` | `noon-tab-map` | prefix map |
| `,oa` | `org-agenda` | Dispatch agenda commands to collect entries to the agenda buffer. |
| `,oc` | `org-capture` | Capture something. |
| `,oo` | `noon/open-notes` | Open the default org notes file. |
| `]c` | `diff-hl-next-hunk` | Go to the beginning of the next hunk in the current buffer. |
| `[c` | `diff-hl-previous-hunk` | Go to the beginning of the previous hunk in the current buffer. |
| `,hh` | `diff-hl-show-hunk` | Show the VC diff hunk at point. |
| `,hr` | `diff-hl-revert-hunk` | Revert the diff hunk with changes at or above the point. |
| `,hs` | `diff-hl-stage-dwim` | Stage the current hunk or choose the hunks to stage. |

> Space saves (S-Space is invisible to a tty; dropped)
>
> r repeats; visual r replaces selection without clobbering the register
>
> j/k move by visual lines
>
> ,<space> clears search highlight
>
> ,p / ,y -- system clipboard
>
> ga/gA align (easy-align); equational reasoning: ga ip /[≤≡≈∎]

## Global (visual state)

| Key | Command | Does |
|---|---|---|
| `.` | *evil-easymotion* | prefix: follow with a motion (w, e, j, f, ...) to jump to a target |
| `r` | keyboard macro `P` | replays the keys `P` |
| `,p` | keyboard macro `"+p` | replays the keys `"+p` |
| `,y` | keyboard macro `"+y` | replays the keys `"+y` |
| `\\` | `evil-commentary` | Comment or uncomment region that {motion} moves over. |
| `ga` | `evil-lion-left` | Align the text in the given region using CHAR. |
| `gA` | `evil-lion-right` | Align the text in the given region using CHAR. |
| `, SPC` | `evil-lion-left` | Align the text in the given region using CHAR. |

> ,p / ,y -- system clipboard
>
> ga/gA align (easy-align); equational reasoning: ga ip /[≤≡≈∎]

## Global (motion state)

| Key | Command | Does |
|---|---|---|
| `C-z` | *unbound* | removed, so the key falls through |
| `;` | `evil-ex` | Enter an Ex command. |
| `'` | `evil-goto-mark` | Go to the marker specified by CHAR. |
| `` ` `` | `evil-switch-to-windows-last-buffer` | Switch to the last open buffer of the current window. |

> `;` -> ex command line
>
> ' -> exact mark; ` -> alternate buffer

## Global (insert state)

| Key | Command | Does |
|---|---|---|
| `C-z` | *unbound* | removed, so the key falls through |

## Global (Emacs state)

| Key | Command | Does |
|---|---|---|
| `C-z` | *unbound* | removed, so the key falls through |

## Global (all states)

| Key | Command | Does |
|---|---|---|
| `M-f` | *unbound* | removed, so the key falls through |

> xmonad's modMask is mod1 (Alt), which a terminal delivers as Meta, so anything xmonad binds never reaches here. Alt-b is one of those, and a working M-f next to a dead M-b is worse than neither: editing is vim's job in this configuration anyway.

## agda2-mode-map (normal state)

| Key | Command | Does |
|---|---|---|
| `,l` | `agda2-load` |  |
| `,r` | `agda2-refine` |  |
| `,d` | `agda2-make-case` |  |
| `,,` | `agda2-goal-and-context` |  |
| `,.` | `agda2-goal-and-context-and-inferred` |  |
| `,n` | `agda2-solve-maybe-all` |  |
| `,a` | `agda2-mimer-maybe-all` |  |
| `,g` | `agda2-give` |  |
| `gd` | `agda2-goto-definition-keyboard` |  |

*(No descriptions: this package cannot be loaded headlessly, so its docstrings are unavailable here.)*

> localleader bindings mirroring cornelis

## dired-mode-map (normal state)

| Key | Command | Does |
|---|---|---|
| `;` | `evil-ex` | Enter an Ex command. |

## eglot-mode-map (normal state)

| Key | Command | Does |
|---|---|---|
| `gd` | `noon/eglot-find-definitions` | Jump to the definition at point, without blocking Emacs. |
| `gr` | `noon/eglot-find-references` | List references to the symbol at point, without blocking Emacs. |
| `K` | `eldoc-doc-buffer` | Get or display ElDoc documentation buffer. |
| `,ld` | `flymake-show-buffer-diagnostics` | Show listing of Flymake diagnostics for current buffer. |
| `,lc` | `eglot-code-actions` | Find LSP code actions of type ACTION-KIND between BEG and END. |
| `,ln` | `flymake-goto-next-error` | Go to Nth next Flymake diagnostic that matches FILTER. |
| `,lp` | `flymake-goto-prev-error` | Go to Nth previous Flymake diagnostic that matches FILTER. |
| `,lr` | `eglot-rename` | Rename the current symbol to NEWNAME. |
| `,lf` | `eglot-format` | Format region BEG END. |

> D and C used to be here, which cost `evil-delete-line' and `evil-change-line' in every managed buffer. A bare `hd'/`hc' would be worse still: it turns `h' into a prefix, so plain left-motion stalls waiting for a second key. `,' is the leader everywhere else here (,gs magit, ,o* org, ,h* diff-hl hunks), so LSP takes ,l*.

## noon-tab-map (the `TAB` prefix)

| Key | Command | Does |
|---|---|---|
| `TAB e` | `noon/find-file-rg` | Open a file under the launch directory, like :Files. |
| `TAB s` | `noon/find-git-modified-file` | Open a git-modified file, like :GFiles?. |
| `TAB h` | `evil-window-left` | Move the cursor to new COUNT-th window left of the current one. |
| `TAB j` | `evil-window-down` | Move the cursor to new COUNT-th window below the current one. |
| `TAB k` | `evil-window-up` | Move the cursor to new COUNT-th window above the current one. |
| `TAB l` | `evil-window-right` | Move the cursor to new COUNT-th window right of the current one. |
| `TAB TAB` | `evil-window-mru` | Move the cursor to the previous (last accessed) buffer in another window. |
| `TAB p` | `projectile-command-map` | prefix map |

## projectile-mode-map

| Key | Command | Does |
|---|---|---|
| `C-c p` | `projectile-command-map` | prefix map |

## Ex commands

| Key | Command | Does |
|---|---|---|
| `:cd` | `noon/cd` | Vim-like :cd -- change this frame's working directory (the root used by the pickers). |
| `:pwd` | `noon/pwd` | Vim-like :pwd -- show this frame's working directory. |

---

