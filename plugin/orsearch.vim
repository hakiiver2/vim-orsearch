" orsearch.vim - OR/NOT/Phrase search plugin for Vim
" Maintainer:   hakiiver2
" Version:      0.1
" License:      MIT

if exists('g:loaded_orsearch')
  finish
endif
let g:loaded_orsearch = 1

" Default configuration
if !exists('g:orsearch_space_or')
  let g:orsearch_space_or = 1
endif

if !exists('g:orsearch_integrated_mode')
  let g:orsearch_integrated_mode = 0
endif

if !exists('g:orsearch_auto_detect')
  let g:orsearch_auto_detect = 1
endif

" Store the last search query (original, user-friendly format)
let g:orsearch_last_query = ''

" Main command
command! -nargs=? OrSearch call s:OrSearch(<q-args>)

" Default mapping
if !hasmapto('<Plug>OrSearch')
  silent! nmap <unique> <leader>/ <Plug>OrSearch
endif
nnoremap <silent> <Plug>OrSearch :call <SID>OrSearch('')<CR>

" Integrated mode: Replace / with OrSearch
if g:orsearch_integrated_mode
  nnoremap / :call <SID>IntegratedSearch()<CR>
  nnoremap ? :call <SID>IntegratedSearchBackward()<CR>
endif

" Main search function
function! s:OrSearch(query) abort
  let l:q = a:query

  " If no query provided, prompt for input
  if empty(l:q)
    let l:q = input('OR search> ')
  endif

  " Exit if empty
  if empty(l:q)
    return
  endif

  " Normalize spaces (full-width to half-width)
  let l:q = substitute(l:q, '　', ' ', 'g')
  let l:q = substitute(l:q, '\s\+', ' ', 'g')
  let l:q = trim(l:q)

  " Parse query
  let [l:ors, l:nots] = s:ParseQuery(l:q)

  " Check if we have any OR terms
  if empty(l:ors)
    echohl WarningMsg
    echo 'OrSearch: No search terms provided'
    echohl None
    return
  endif

  " Build OR pattern
  let l:pattern = s:BuildOrPattern(l:ors)

  " Execute search
  try
    let @/ = l:pattern
    execute 'normal! n'

    " Apply NOT filter if needed
    if !empty(l:nots)
      call s:SkipNotMatches(l:nots)
    endif

    " Enable search highlighting
    set hlsearch
  catch /E486/
    echohl ErrorMsg
    echo 'OrSearch: Pattern not found'
    echohl None
  endtry
endfunction

" Parse query into OR and NOT terms
function! s:ParseQuery(query) abort
  let l:ors = []
  let l:nots = []
  let l:tokens = s:TokenizeQuery(a:query)

  for l:token in l:tokens
    if l:token =~# '^-"'
      " NOT phrase: -"foo bar"
      let l:phrase = matchstr(l:token, '^-"\zs.\{-}\ze"$')
      if !empty(l:phrase)
        call add(l:nots, l:phrase)
      endif
    elseif l:token =~# '^"'
      " Phrase: "foo bar"
      let l:phrase = matchstr(l:token, '^"\zs.\{-}\ze"$')
      if !empty(l:phrase)
        call add(l:ors, l:phrase)
      endif
    elseif l:token =~# '^-'
      " NOT term: -foo
      let l:term = l:token[1:]
      if !empty(l:term)
        call add(l:nots, l:term)
      endif
    else
      " OR term: foo
      if !empty(l:token)
        call add(l:ors, l:token)
      endif
    endif
  endfor

  return [l:ors, l:nots]
endfunction

" Tokenize query respecting quoted strings
function! s:TokenizeQuery(query) abort
  let l:tokens = []
  let l:current = ''
  let l:in_quote = 0
  let l:i = 0

  while l:i < len(a:query)
    let l:char = a:query[l:i]

    if l:char ==# '"'
      if l:in_quote
        " End of quoted string
        let l:current .= l:char
        call add(l:tokens, l:current)
        let l:current = ''
        let l:in_quote = 0
      else
        " Start of quoted string
        if !empty(l:current)
          call add(l:tokens, l:current)
        endif
        let l:current = l:char
        let l:in_quote = 1
      endif
    elseif l:char ==# ' ' && !l:in_quote
      " Space outside quotes - token separator
      if !empty(l:current)
        call add(l:tokens, l:current)
        let l:current = ''
      endif
    else
      " Regular character
      let l:current .= l:char
    endif

    let l:i += 1
  endwhile

  " Add final token
  if !empty(l:current)
    call add(l:tokens, l:current)
  endif

  return l:tokens
endfunction

" Build OR pattern using very nomagic mode
function! s:BuildOrPattern(terms) abort
  let l:escaped_terms = []

  for l:term in a:terms
    " Escape special characters for \V (very nomagic) mode
    let l:escaped = escape(l:term, '\')
    call add(l:escaped_terms, l:escaped)
  endfor

  " Join with \| (OR operator in very nomagic mode)
  if len(l:escaped_terms) == 1
    return '\V' . l:escaped_terms[0]
  else
    return '\V\(' . join(l:escaped_terms, '\|') . '\)'
  endif
endfunction

" Skip matches that contain NOT terms
function! s:SkipNotMatches(nots) abort
  let l:max_iterations = 1000
  let l:iteration = 0
  let l:initial_pos = getpos('.')

  while l:iteration < l:max_iterations
    let l:line = getline('.')
    let l:skip = 0

    " Check if line contains any NOT terms
    for l:not in a:nots
      " Use very nomagic search for NOT terms too
      let l:not_pattern = '\V' . escape(l:not, '\')
      if l:line =~# l:not_pattern
        let l:skip = 1
        break
      endif
    endfor

    if l:skip
      " Save current position
      let l:before_pos = getpos('.')

      " Try to find next match
      try
        execute 'normal! n'
      catch /E385/
        " No more matches
        echohl WarningMsg
        echo 'OrSearch: No matches without excluded terms'
        echohl None
        call setpos('.', l:initial_pos)
        return
      endtry

      let l:after_pos = getpos('.')

      " Check if we wrapped around or didn't move
      if l:before_pos == l:after_pos
        echohl WarningMsg
        echo 'OrSearch: No matches without excluded terms'
        echohl None
        call setpos('.', l:initial_pos)
        return
      endif
    else
      " Found a valid match
      return
    endif

    let l:iteration += 1
  endwhile

  " Safety: max iterations reached
  echohl WarningMsg
  echo 'OrSearch: Maximum iterations reached'
  echohl None
endfunction

" Display user-friendly search message
function! s:DisplaySearchMessage(query, ors, nots) abort
  echohl Search
  echo '/' . a:query
  echohl None
endfunction

" Public function for statusline integration
function! OrSearchStatus() abort
  if !empty(g:orsearch_last_query)
    return '/' . g:orsearch_last_query
  else
    return ''
  endif
endfunction

" ============================================================================
" Integrated Mode Functions
" ============================================================================

" Check if query contains OrSearch syntax
function! s:IsOrSearchQuery(query) abort
  if empty(a:query)
    return 0
  endif

  " Check for OrSearch syntax patterns
  " 1. Contains space (OR search)
  if a:query =~# ' '
    return 1
  endif

  " 2. Contains NOT operator (-)
  if a:query =~# '\(^\| \)-'
    return 1
  endif

  " 3. Contains quoted phrase ("")
  if a:query =~# '"'
    return 1
  endif

  " Otherwise, treat as regular Vim search
  return 0
endfunction

" Integrated search function (forward)
function! s:IntegratedSearch() abort
  let l:query = input('/')

  if empty(l:query)
    echo ''
    return
  endif

  " Check if auto-detect is enabled and query contains OrSearch syntax
  if g:orsearch_auto_detect && s:IsOrSearchQuery(l:query)
    " Use OrSearch
    call s:OrSearchDirect(l:query)
  else
    " Use regular Vim search
    try
      let @/ = l:query
      execute 'normal! n'
      set hlsearch
    catch /E486/
      echohl ErrorMsg
      echo 'Pattern not found: ' . l:query
      echohl None
    endtry
  endif
endfunction

" Integrated search function (backward)
function! s:IntegratedSearchBackward() abort
  let l:query = input('?')

  if empty(l:query)
    echo ''
    return
  endif

  " Check if auto-detect is enabled and query contains OrSearch syntax
  if g:orsearch_auto_detect && s:IsOrSearchQuery(l:query)
    " Use OrSearch (backward search starts from current position)
    call s:OrSearchDirect(l:query)
    " Move backward to simulate backward search
    try
      execute 'normal! N'
    catch
    endtry
  else
    " Use regular Vim backward search
    try
      let @/ = l:query
      execute 'normal! N'
      set hlsearch
    catch /E486/
      echohl ErrorMsg
      echo 'Pattern not found: ' . l:query
      echohl None
    endtry
  endif
endfunction

" Direct OrSearch execution (for integrated mode)
function! s:OrSearchDirect(query) abort
  " Store original query for display
  let g:orsearch_last_query = a:query

  " Normalize spaces (full-width to half-width)
  let l:q = substitute(a:query, '　', ' ', 'g')
  let l:q = substitute(l:q, '\s\+', ' ', 'g')
  let l:q = trim(l:q)

  " Parse query
  let [l:ors, l:nots] = s:ParseQuery(l:q)

  " Check if we have any OR terms
  if empty(l:ors)
    echohl WarningMsg
    echo 'Search: No search terms provided'
    echohl None
    return
  endif

  " Build OR pattern
  let l:pattern = s:BuildOrPattern(l:ors)

  " Execute search
  try
    let @/ = l:pattern
    execute 'normal! n'

    " Apply NOT filter if needed
    if !empty(l:nots)
      call s:SkipNotMatches(l:nots)
    endif

    " Enable search highlighting
    set hlsearch

    " Display user-friendly search message
    call s:DisplaySearchMessage(a:query, l:ors, l:nots)
  catch /E486/
    echohl ErrorMsg
    echo 'Search: Pattern not found: ' . a:query
    echohl None
  endtry
endfunction
