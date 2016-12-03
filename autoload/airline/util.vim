" MIT License. Copyright (c) 2013-2016 Bailey Ling.
" vim: et ts=2 sts=2 sw=2

scriptencoding utf-8

call airline#init#bootstrap()
let s:spc = g:airline_symbols.space

function! airline#util#shorten(text, winwidth, minwidth)
  if winwidth(0) < a:winwidth && len(split(a:text, '\zs')) > a:minwidth
    return matchstr(a:text, '^.\{'.a:minwidth.'}').'…'
  else
    return a:text
  endif
endfunction

function! airline#util#wrap(text, minwidth)
  if a:minwidth > 0 && winwidth(0) < a:minwidth
    return ''
  endif
  return a:text
endfunction

function! airline#util#append(text, minwidth)
  if a:minwidth > 0 && winwidth(0) < a:minwidth
    return ''
  endif
  let prefix = s:spc == "\ua0" ? s:spc : s:spc.s:spc
  return empty(a:text) ? '' : prefix.g:airline_left_alt_sep.s:spc.a:text
endfunction

function! airline#util#warning(msg)
  echohl WarningMsg
  echomsg "airline: ".a:msg
  echohl Normal
endfunction

function! airline#util#prepend(text, minwidth)
  if a:minwidth > 0 && winwidth(0) < a:minwidth
    return ''
  endif
  return empty(a:text) ? '' : a:text.s:spc.g:airline_right_alt_sep.s:spc
endfunction

if v:version >= 704
  function! airline#util#getwinvar(winnr, key, def)
    return getwinvar(a:winnr, a:key, a:def)
  endfunction
else
  function! airline#util#getwinvar(winnr, key, def)
    let winvals = getwinvar(a:winnr, '')
    return get(winvals, a:key, a:def)
  endfunction
endif

if v:version >= 704
  function! airline#util#exec_funcrefs(list, ...)
    for Fn in a:list
      let code = call(Fn, a:000)
      if code != 0
        return code
      endif
    endfor
    return 0
  endfunction
else
  function! airline#util#exec_funcrefs(list, ...)
    " for 7.2; we cannot iterate the list, hence why we use range()
    " for 7.3-[97, 328]; we cannot reuse the variable, hence the {}
    for i in range(0, len(a:list) - 1)
      let Fn{i} = a:list[i]
      let code = call(Fn{i}, a:000)
      if code != 0
        return code
      endif
    endfor
    return 0
  endfunction
endif

" Define a wrapper over system() that uses nvim's async job control if
" available. This way we avoid overwriting v:shell_error, which might
" potentially disrupt other plugins.
if has('nvim')
  function! s:system_job_handler(job_id, data, event)
    if a:event == 'stdout'
      let self.buf .=  join(a:data)
    endif
  endfunction

  function! airline#util#system(cmd)
    let l:config = {
    \ 'buf': '',
    \ 'on_stdout': function('s:system_job_handler'),
    \ }
    let l:id = jobstart(a:cmd, l:config)
    if l:id < 1
      return system(a:cmd)
    endif
    call jobwait([l:id])
    return l:config.buf
  endfunction
else
  function! airline#util#system(cmd)
    return system(a:cmd)
  endfunction
endif

function! airline#util#getcharcode()
  " Get the output of :ascii
  redir => ascii
  silent! ascii
  redir END

  if match(ascii, 'NUL') != -1
    return '∅  EMPTY  ⏚ '
  endif

  " Zero pad hex values
  let nrformat = '0x%02x'

  let encoding = (&fenc == '' ? &enc : &fenc)

  if encoding == 'utf-8'
    " Zero pad with 4 zeroes in unicode files
    let nrformat = '0x%04x'
  endif

  " Get the character and the numeric value from the return value of :ascii
  " This matches the two first pieces of the return value, e.g.
  " "<F>  70" => char: 'F', nr: '70'
  let [str, char, nr; rest] = matchlist(ascii, '\v\<(.{-1,})\>\s*([0-9]+)')

  " Format the numeric value
  let nr = printf(nrformat, nr)

  return "➤ '". char ."' ". nr
endfunction

