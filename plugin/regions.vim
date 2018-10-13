function! s:is_file_uri(uri) abort
    return stridx(a:uri, 'file:///') == 0
endfunction

highlight link InactiveRangeSection Comment

" set different highlight group for inactive code
let s:inactive_range_section_hl=get(g:, 'inactive_range_section_hl', 'InactiveRangeSection')

" TODO does not work correctly: removes in current window only
function s:ClearMatchGroup(group, id)
    let l:matches = getmatches()
    for l:m in l:matches
        if l:m['group'] == a:group
            " TODO not possible to get matches from all windows
            call matchdelete(l:m['id'])
        endif
    endfor
endfunction

function s:AddMatchGroup(group, from, to, window)
    let l:i = a:from
    while l:i <= a:to
        if (l:i+8 > a:to)
            let l:end = a:to
        else
            let l:end = l:i+8
        endif

        call matchaddpos(a:group, range(l:i, l:end), 1, -1,{'window': a:window})

        let l:i = l:i+8
    endwhile
endfunction

let s:buffer_inactive_region = {}

function ProcessInactiveRegions(server, data)
    if !has_key(a:data['response'], 'params')
        return
    endif

    if '$cquery/setInactiveRegions' != a:data['response']['method']
        return
    endif

    let l:uri = a:data['response']['params']['uri']
    let l:regions = a:data['response']['params']['inactiveRegions']

    if !s:is_file_uri(l:uri)
        return
    endif

    let l:path = lsp#utils#uri_to_path(l:uri)
    let l:bufnr = bufnr(l:path)
    let l:buf_regions = []


    if !empty(l:regions)
        for l:item in l:regions
            if !has_key(l:item, 'start') || !has_key(l:item, 'end')
                continue
            endif

            let l:start = l:item['start']
            let l:end = l:item['end']

            if !has_key(l:start, 'line') || !has_key(l:end, 'line')
                continue
            endif

            call add(l:buf_regions, [l:start['line']+1, l:end['line']+1])
        endfor
    endif

    let s:buffer_inactive_region[l:bufnr]=buf_regions

    " TODO update works for current window only
    if l:bufnr == bufnr('%')
        call s:UpdateRegionsOn(winnr())
    endif
    " TODO for all bufs, but clear is not working as expected
    " for l:winid in win_findbuf(l:bufnr)
    "     call s:UpdateRegionsOn(l:winid)
    " endfor
endfunction

function s:UpdateRegionsOn(id)
    call s:ClearRegionsOn(a:id)
    call s:SetRegionsOn(a:id)
endfunction

function s:ClearRegionsOn(id)
    call s:ClearMatchGroup(s:inactive_range_section_hl, a:id)
endfunction

function s:SetRegionsOn(window)
    let l:cur_buf = bufnr('%')

    if !has_key(s:buffer_inactive_region, l:cur_buf)
        return
    endif

    for l:item in s:buffer_inactive_region[l:cur_buf]
            call s:AddMatchGroup(s:inactive_range_section_hl, l:item[0], l:item[1], a:window)
    endfor
endfunction

function s:OnBufDelete()
    let l:cur_buf = bufnr('%')
    if has_key(s:buffer_inactive_region, l:cur_buf)
        unlet s:buffer_inactive_region[l:cur_buf]
    endif
endfunction

function s:OnBufEnter()
    call s:UpdateRegionsOn(winnr())
endfunction

augroup lspInactiveRegions
  au!
  au BufEnter,BufRead,BufNew,BufAdd,WinEnter,BufWinEnter *	    call s:OnBufEnter()
  au BufDelete * call s:OnBufDelete()
augroup END

call lsp#register_notifications("$cquery/setInactiveRegions", function("ProcessInactiveRegions"))
