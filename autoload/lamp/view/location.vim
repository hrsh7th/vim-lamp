function! lamp#view#location#handle(command, position, locations, ...) abort
  let l:option = get(a:000, 0, {})

  " multiple locations.
  if len(a:locations) > 1
    call lamp#config('view.location.on_location')(a:locations)

  " single locations.
  elseif len(a:locations) == 1
    if get(l:option, 'always_listing', v:false)
      call lamp#config('view.location.on_location')(a:locations)
    else
      call lamp#view#buffer#open(a:command, a:locations[0])
    endif

  " no locations found.
  else
    if get(l:option, 'no_fallback', v:false)
      call lamp#view#notice#add({ 'lines': ['`Location`: no locations found.'] })
    else
      call lamp#config('view.location.on_fallback')(a:command, a:position)
    endif
  endif
endfunction

