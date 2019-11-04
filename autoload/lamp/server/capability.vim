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
" supports.
"
function! s:Capability.supports(path) abort
  return lamp#get(self.capability, a:path, v:null) isnot v:null
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

