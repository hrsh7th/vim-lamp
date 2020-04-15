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

"
" lamp#server#capability#get_default_capability
"
function! lamp#server#capability#get_default_capability() abort
  return {
        \   'workspace': {
        \     'applyEdit': v:true,
        \     'workspaceEdit': {
        \       'documentChanges': v:true,
        \       'resourceOperations': [],
        \       'failureHandling': 'abort',
        \     },
        \     'didChangeConfiguration': {
        \       'dynamicRegistration': v:true
        \     },
        \     'didChangeWatchedFiles': {
        \       'dynamicRegistration': v:true
        \     },
        \     'symbol': {
        \       'dynamicRegistration': v:true,
        \       'valueSet': values(g:lamp#server#capability#symbol_kinds)
        \     },
        \     'executeCommand': {
        \       'dynamicRegistration': v:true,
        \     },
        \     'workspaceFolders': v:true,
        \     'configuration': v:true,
        \   },
        \   'textDocument': {
        \     'synchronization': {
        \       'dynamicRegistration': v:true,
        \       'willSave': v:true,
        \       'willSaveWaitUntil': v:true,
        \       'didSave': v:true
        \     },
        \     'rename': {
        \       'prepareSupport': v:true
        \     },
        \     'completion': {
        \       'dynamicRegistration': v:true,
        \       'completionItem': {
        \         'snippetSupport': !empty(lamp#config('feature.completion.snippet.expand')) ? v:true : v:false,
        \         'commitCharactersSupport': v:true,
        \         'documentationFormat': ['plaintext', 'markdown'],
        \         'deprecatedSupport': v:true,
        \         'preselectSupport': v:true,
        \       },
        \       'completionItemKind': {
        \         'valueSet': map(keys(lamp#protocol#completion#get_kind_map()), { k, v -> str2nr(v) })
        \       },
        \       'contextSupport': v:true
        \     },
        \     'codeAction': {
        \       'dynamicRegistration': v:true,
        \       'codeActionLiteralSupport': {
        \         'codeActionKind': {
        \           'valueSet': ['', 'quickfix', 'refactor', 'refactor.extract', 'refactor.inline', 'refactor.rewrite', 'source', 'source.organizeImports']
        \         }
        \       }
        \     },
        \     'signatureHelp': {
        \       'dynamicRegistration': v:true,
        \       'signatureInformation': {
        \         'documentationFormat': ['plaintext', 'markdown'],
        \         'parameterInformation': {
        \           'labelOffsetSupport': v:true
        \         }
        \       },
        \     },
        \     'hoverSupport': {
        \       'dynamicRegistration': v:true,
        \       'contentFormat': ['plaintext', 'markdown'],
        \     },
        \     'documentSymbol': {
        \       'dynamicRegistration': v:true,
        \       'symbolKind': {
        \         'valueSet': values(g:lamp#server#capability#symbol_kinds)
        \       },
        \       'hierarchicalDocumentSymbolSupport': v:true
        \     },
        \     'documentHighlight': {
        \       'dynamicRegistration': v:true,
        \     },
        \     'declaration': {
        \       'dynamicRegistration': v:true,
        \       'linkSupport': v:true,
        \     },
        \     'definition': {
        \       'dynamicRegistration': v:true,
        \       'linkSupport': v:true,
        \     },
        \     'typeDefinition': {
        \       'dynamicRegistration': v:true,
        \       'linkSupport': v:true,
        \     },
        \     'implementation': {
        \       'dynamicRegistration': v:true,
        \       'linkSupport': v:true,
        \     },
        \     'onTypeFormatting': {
        \       'dynamicRegistration': v:true,
        \     }
        \   },
        \   'experimental': {},
        \ }
endfunction

"
" lamp#server#capability#import
"
function! lamp#server#capability#import() abort
  return s:Capability
endfunction

let s:Capability = {}

"
" new
"
function! s:Capability.new(capability) abort
  return extend(deepcopy(s:Capability), {
        \   'capability': a:capability
        \ })
endfunction

"
" merge
"
function! s:Capability.merge(capability) abort
  let self.capability = lamp#merge(self.capability, a:capability)
endfunction

"
" register
"
function! s:Capability.register(capability) abort
  " TODO: impl
endfunction

"
" unregister
"
function! s:Capability.register(capability) abort
  " TODO: impl
endfunction

"
" supports
"
function! s:Capability.supports(path) abort
  return lamp#get(self.capability, a:path, v:null) isnot v:null
endfunction

"
" get_completion_commit_characters
"
function! s:Capability.get_completion_all_commit_characters() abort
  return lamp#get(self.capability, 'capabilities.completionProvider.allCommitCharacters', [])
endfunction

"
" get_completion_trigger_characters
"
function! s:Capability.get_completion_trigger_characters() abort
  return lamp#get(self.capability, 'capabilities.completionProvider.triggerCharacters', [])
endfunction

"
" get_on_type_formatting_trigger_characters
"
function! s:Capability.get_on_type_formatting_trigger_characters() abort
  let l:chars = []
  let l:first = lamp#get(self.capability, 'capabilities.documentOnTypeFormattingProvider.firstTriggerCharacter', v:null)
  if l:first isnot# v:null
    let l:chars += [l:first]
  endif
  return l:chars + lamp#get(self.capability, 'capabilities.documentOnTypeFormattingProvider.moreTriggerCharacter', [])
endfunction

"
" get_signature_help_trigger_characters
"
function! s:Capability.get_signature_help_trigger_characters() abort
  return lamp#get(self.capability, 'capabilities.signatureHelpProvider.triggerCharacters', [])
endfunction

"
" get_code_action_kinds
"
function! s:Capability.get_code_action_kinds() abort
  return lamp#get(self.capability, 'capabilities.codeActionProvider.codeActionKinds', [])
endfunction

"
" get_text_document_sync_kind
"
function! s:Capability.get_text_document_sync_kind() abort
  let l:kind_or_option = lamp#get(self.capability, 'capabilities.textDocumentSync', 0)
  if type(l:kind_or_option) == type(0)
    return l:kind_or_option
  endif
  return lamp#get(l:kind_or_option, 'change', 0)
endfunction

"
" get_text_document_sync_will_save
"
function! s:Capability.get_text_document_sync_will_save() abort
  return lamp#get(self.capability, 'capabilities.textDocumentSync.willSave', v:false)
endfunction

"
" get_text_document_sync_will_save_wait_until
"
function! s:Capability.get_text_document_sync_will_save_wait_until() abort
  return lamp#get(self.capability, 'capabilities.textDocumentSync.willSaveWaitUntil', v:false)
endfunction

"
" get_text_document_sync_save
"
function! s:Capability.get_text_document_sync_save() abort
  return lamp#get(self.capability, 'capabilities.textDocumentSync.save', v:null) isnot# v:null
endfunction

"
" get_text_document_sync_save_include_text
"
function! s:Capability.get_text_document_sync_save_include_text() abort
  return lamp#get(self.capability, 'capabilities.textDocumentSync.save.includeText', v:false)
endfunction

"
" is_workspace_folder_supported
"
function! s:Capability.is_workspace_folder_supported() abort
  let l:is_supported = lamp#get(self.capability, 'capabilities.workspace.workspaceFolders.supported', v:false)
  if !l:is_supported
    return v:false
  endif
  let l:change_notifications = lamp#get(self.capability, 'capabilities.workspace.workspaceFolders.changeNotifications', v:true)
  return type(l:change_notifications) == type(v:true) || strlen(l:change_notifications) > 0
endfunction

