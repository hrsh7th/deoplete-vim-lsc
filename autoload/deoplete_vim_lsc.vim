let g:deoplete_vim_lsc#request = {
      \   'context': {},
      \   'responsed': v:false,
      \   'response': []
      \ }

function! deoplete_vim_lsc#clear()
  let g:deoplete_vim_lsc#request = {
        \   'context': {},
        \   'responsed': v:false,
        \   'response': []
        \ }
endfunction

function! deoplete_vim_lsc#is_completable()
  for server in lsc#server#current()
    return !empty(s:get(server, ['capabilities', 'completion'], v:null))
  endfor
  return v:false
endfunction

function! deoplete_vim_lsc#is_completable_context(deoplete_context)
  for server in lsc#server#current()
    let chars = s:get(server, ['capabilities', 'completion', 'triggerCharacters'], [])
    let chars = map(copy(chars), { k, v -> escape(v, '<.[]') }) + ['\w']
    let output = match(a:deoplete_context.input, '^\_.\{-}\%(' . join(chars, '\|') . '\)$') >= 0
    return output
  endfor
  return v:false
endfunction

function! deoplete_vim_lsc#match_context(deoplete_context1, deoplete_context2)
  if empty(a:deoplete_context1) || empty(a:deoplete_context2)
    return v:false
  endif
  return a:deoplete_context1.input ==# a:deoplete_context2.input
endfunction

function! deoplete_vim_lsc#request_completion(deoplete_context)
  " skip if context is not completion target
  if !deoplete_vim_lsc#is_completable_context(a:deoplete_context)
    return
  endif

  " skip request if match current context
  if deoplete_vim_lsc#match_context(a:deoplete_context, g:deoplete_vim_lsc#request.context)
    return
  endif

  " request completion
  let g:deoplete_vim_lsc#request.context = a:deoplete_context
  let g:deoplete_vim_lsc#request.responsed = v:false
  let g:deoplete_vim_lsc#request.response = []
  call lsc#file#flushChanges()
  call lsc#server#userCall('textDocument/completion',
        \ lsc#params#documentPosition(),
        \ function('s:on_response', [a:deoplete_context]))
endfunction

function! s:on_response(deoplete_context, response)
  if !deoplete_vim_lsc#match_context(a:deoplete_context, g:deoplete_vim_lsc#request.context)
    return
  endif

  if empty(a:response)
    return
  endif

  let g:deoplete_vim_lsc#request.context = a:deoplete_context
  let g:deoplete_vim_lsc#request.responsed = v:true
  let g:deoplete_vim_lsc#request.response = type(a:response) == v:t_list
        \ ? a:response
        \ : get(a:response, 'items', [])

  if mode() ==# 'i'
    call deoplete#auto_complete()
  endif
endfunction

function! s:get(dict, keys, def)
  let target = a:dict
  for key in a:keys
    if type(target) != v:t_dict | return a:def | endif
    let _ = get(target, key, v:null)
    unlet! target
    let target = _
    if target is v:null | return a:def | endif
  endfor
  return target
endfunction

