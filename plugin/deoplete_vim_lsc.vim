if exists('g:deoplete_vim_lsc_loaded')
  finish
endif
let g:deoplete_vim_lsc_loaded = 1

augroup deoplete_vim_lsc
  autocmd!
  autocmd! InsertLeave * call deoplete_vim_lsc#clear()
augroup END

