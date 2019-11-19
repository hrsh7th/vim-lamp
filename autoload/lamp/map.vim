"
" lamp#map#confirm
"
function! lamp#map#confirm(default) abort
  if pumvisible() && complete_info(['selected']).selected != -1
    if lamp#feature#completion#should_effect_on_complete_done(v:completed_item)
      let g:lamp#state['feature.completion.is_selected'] = v:true
      return "\<C-y>"
    endif
  endif
  return a:default
endfunction
