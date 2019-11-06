let g:lamp#server#capability#symbol_kinds = {
      \   'File': 1,
      \   'Module': 2,
      \   'Namespace': 3,
      \   'Package': 4,
      \   'Class': 5,
      \   'Method': 6,
      \   'Property': 7,
      \   'Field': 8,
      \   'Constructor': 9,
      \   'Enum': 10,
      \   'Interface': 11,
      \   'Function': 12,
      \   'Variable': 13,
      \   'Constant': 14,
      \   'String': 15,
      \   'Number': 16,
      \   'Boolean': 17,
      \   'Array': 18,
      \   'Object': 19,
      \   'Key': 20,
      \   'Null': 21,
      \   'EnumMember': 22,
      \   'Struct': 23,
      \   'Event': 24,
      \   'Operator': 25,
      \   'TypeParameter': 26,
      \ }

let g:lamp#server#capability#definition = {
      \   'workspace': {
      \     'applyEdit': v:true,
      \     'workspaceEdit': {
      \       'documentChanges': v:true,
      \       'resourceOperations': [],
      \       'failureHandling': 'abort',
      \     },
      \     'didChangeConfiguration': {
      \       'dynamicRegistration': v:false
      \     },
      \     'didChangeWatchedFiles': {
      \       'dynamicRegistration': v:false
      \     },
      \     'symbol': {
      \       'dynamicRegistration': v:false,
      \       'valueSet': values(g:lamp#server#capability#symbol_kinds)
      \     },
      \     'executeCommand': {
      \       'dynamicRegistration': v:false,
      \     },
      \     'workspaceFolders': v:false,
      \     'configuration': v:false,
      \   },
      \   'textDocument': {
      \     'synchronization': {
      \       'dynamicRegistration': v:false,
      \       'willSave': v:false,
      \       'willSaveDidUntil': v:false,
      \       'didSave': v:false
      \     },
      \     'rename': {
      \       'prepareSupport': v:true
      \     },
      \     'completion': {
      \       'dynamicRegistration': v:false,
      \       'snippetSupport': v:false,
      \       'commitCharacterSupports': v:false,
      \       'documentationFormat': ['plaintext', 'markdown'],
      \       'deprecatedSupport': v:false,
      \       'preselectSupport': v:false,
      \     },
      \     'hoverSupport': {
      \       'dynamicRegistration': v:false,
      \       'contentFormat': [],
      \     },
      \     'documentSymbol': {
      \       'dynamicRegistration': v:false,
      \       'symbolKind': {
      \         'valueSet': values(g:lamp#server#capability#symbol_kinds)
      \       },
      \       'hierarchicalDocumentSymbolSupport': v:true
      \     }
      \   },
      \   'experimental': {},
      \ }

function! lamp#server#capability#import() abort
  return s:Capability
endfunction

let s:Capability = {}

"
" new.
"
function! s:Capability.new(capability) abort
  return extend(deepcopy(s:Capability), {
        \   'capability': a:capability
        \ })
endfunction

"
" merge.
"
function! s:Capability.merge(capability) abort
  let self.capability = s:merge(self.capability, a:capability)
endfunction

"
" register.
"
function! s:Capability.register(capability) abort
  " TODO: impl
endfunction

"
" unregister.
"
function! s:Capability.register(capability) abort
  " TODO: impl
endfunction

"
" supports.
"
function! s:Capability.supports(path) abort
  return lamp#get(self.capability, a:path, v:null) isnot v:null
endfunction

"
" get completion trigger characters.
"
function! s:Capability.get_completion_trigger_characters() abort
  return lamp#get(self.capability, 'capabilities.completionProvider.triggerCharacters', [])
endfunction

"
" get_text_document_sync_kind.
"
function! s:Capability.get_text_document_sync_kind() abort
  let l:kind_or_option = lamp#get(self.capability, 'capabilities.textDocumentSync', 0)
  if type(l:kind_or_option) == type(0)
    return l:kind_or_option
  endif
  return lamp#get(l:kind_or_option, 'change', 0)
endfunction

"
" merge.
"
function! s:merge(dict1, dict2) abort
  try
    let l:returns = deepcopy(a:dict1)

    " merge same key.
    for l:key in keys(a:dict1)
      if !has_key(a:dict2, l:key)
        continue
      endif

      " both dict.
      if type(a:dict1[l:key]) == type({}) && type(a:dict2[l:key]) == type({})
        let l:returns[l:key] = s:merge(a:dict1[l:key], a:dict2[l:key])
      endif

      " both list.
      if type(a:dict1[l:key]) == type([]) && type(a:dict2[l:key]) == type([])
        let l:returns[l:key] = extend(copy(a:dict1[l:key]), a:dict2[l:key])
      endif
    endfor

    " add new key.
    for l:key in keys(a:dict2)
      " always have key.
      if has_key(a:dict1, l:key)
        continue
      endif
      let l:returns[l:key] = a:dict2[l:key]
    endfor
  catch /.*/
    echomsg string({ 'exception': v:exception, 'throwpoint': v:throwpoint })
  endtry

  return l:returns
endfunction

