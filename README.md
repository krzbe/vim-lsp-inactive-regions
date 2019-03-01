vim-lsp-inactive-regions
========================
This is a vim-lsp extension to support inactive regions reply from LSP.
Requires vim-lsp (https://github.com/prabirshrestha/vim-lsp).

Supported LSP servers:

 * cquery
 * ccls

Configuration
-------------
g:inactive\_range\_section\_hl - use it to set different highlight group
(default InactiveRangeSection)

Limitations
-----------
Due to vim limitation (or limitation of my vim scripting skills) it is not
possible to remove matches for given window number. Because of that, when having
same buffer opened in split/different window, the script will not update inactive
one, but only current window. Other windows' inactive regions will be updated
just after entering second window.

Current implementation skips whole lines only.
