let g:deoplete_vim_lsc#clear_on_insert_leave = get(g:, 'deoplete_vim_lsc#clear_on_insert_leave', v:false)
let g:deoplete_vim_lsc#request_cache_count = get(g:, 'deoplete_vim_lsc#request_cache_count', 5)

let s:requests = []
function! deoplete_vim_lsc#clear()
  if g:deoplete_vim_lsc#clear_on_insert_leave
    let s:requests = []
  endif
endfunction

function! deoplete_vim_lsc#is_completable()
  for server in lsc#server#current()
    if !empty(s:get(server, ['capabilities', 'completion'], v:null))
      return v:true
    endif
  endfor
  return v:false
endfunction

function! deoplete_vim_lsc#is_completable_context(deoplete_input)
  let output = v:false
  for server in lsc#server#current()
    let chars = s:get(server, ['capabilities', 'completion', 'triggerCharacters'], [])
    let chars = map(copy(chars), { k, v -> escape(v, '<.[]') }) + ['\w']
    let output = output || match(a:deoplete_input, '^\_.\{-}\%(' . join(chars, '\|') . '\)$') >= 0
    if output
      return v:true
    endif
  endfor
  return v:false
endfunction

function! deoplete_vim_lsc#find_request(deoplete_input)
  for request in s:requests
    let input1 = substitute(a:deoplete_input, '\w\zs\w\+$', '', 'g')
    let input2 = substitute(request.input, '\w\zs\w\+$', '', 'g')
    if input1 ==# input2
      return request
    endif
  endfor
  return v:null
endfunction

function! deoplete_vim_lsc#request_completion(deoplete_input)
  " skip if context is not completion target
  if !deoplete_vim_lsc#is_completable_context(a:deoplete_input)
    return
  endif

  " skip request if match current context
  if !empty(deoplete_vim_lsc#find_request(a:deoplete_input))
    return
  endif

  " request completion
  call add(s:requests, {
        \   'input': a:deoplete_input,
        \   'response': v:null
        \ })
  if len(s:requests) > g:deoplete_vim_lsc#request_cache_count
    call remove(s:requests, 0, -g:deoplete_vim_lsc#request_cache_count - 1)
  endif

  call lsc#file#flushChanges()
  call lsc#server#userCall('textDocument/completion',
        \ lsc#params#documentPosition(),
        \ function('s:on_response', [a:deoplete_input]))
endfunction

function! s:on_response(deoplete_input, response)
  if empty(a:response)
    return
  endif

  let request = deoplete_vim_lsc#find_request(a:deoplete_input)
  if empty(request)
    return
  endif
  let request.response = type(a:response) == v:t_list ? a:response : get(a:response, 'items', [])

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

