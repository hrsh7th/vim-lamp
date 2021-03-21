let g:lamp#server#capabilities#symbol_kinds = {
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
" lamp#server#capabilities#get_default_capabilities
"
function! lamp#server#capabilities#get_default_capabilities() abort
  return {
  \   'workspace': {
  \     'applyEdit': v:true,
  \     'workspaceEdit': {
  \       'documentChanges': v:true,
  \       'resourceOperations': [],
  \       'failureHandling': 'abort',
  \       'normalizesLineEndings': v:true,
  \       'changeAnnotationSupport': {
  \         'groupsOnLabel': v:false,
  \       },
  \     },
  \     'didChangeConfiguration': {
  \       'dynamicRegistration': v:false
  \     },
  \     'didChangeWatchedFiles': {
  \       'dynamicRegistration': v:false
  \     },
  \     'symbol': {
  \       'dynamicRegistration': v:false,
  \       'symbolKind': {
  \         'valueSet': values(g:lamp#server#capabilities#symbol_kinds)
  \       },
  \       'tagSupport': {
  \         'valueSet': [],
  \       }
  \     },
  \     'executeCommand': {
  \       'dynamicRegistration': v:false,
  \     },
  \     'workspaceFolders': v:true,
  \     'configuration': v:true,
  \     'semanticTokens': {
  \       'refreshSupport': v:false,
  \     },
  \     'codeLens': {
  \       'refreshSupport': v:false,
  \     },
  \     'fileOperations': {
  \       'dynamicRegistration': v:false,
  \       'didCreate': v:false,
  \       'willCreate': v:false,
  \       'didRename': v:false,
  \       'willRename': v:false,
  \       'didDelete': v:false,
  \       'willDelete': v:false,
  \     }
  \   },
  \   'textDocument': {
  \     'synchronization': {
  \       'dynamicRegistration': v:false,
  \       'willSave': v:true,
  \       'willSaveWaitUntil': v:true,
  \       'didSave': v:true
  \     },
  \     'completion': {
  \       'dynamicRegistration': v:false,
  \       'editsNearCursor': v:true,
  \       'completionItem': {
  \         'snippetSupport': !empty(lamp#config('feature.completion.snippet.expand')) ? v:true : v:false,
  \         'commitCharactersSupport': v:true,
  \         'documentationFormat': ['markdown'],
  \         'deprecatedSupport': v:true,
  \         'preselectSupport': v:true,
  \         'labelDetailsSupport': v:true,
  \         'tagSupport': {
  \           'valueSet': [],
  \         },
  \         'insertReplaceSupport': v:false,
  \         'resolveSupport': {
  \           'properties': ['documentation', 'detail', 'additionalTextEdits']
  \         },
  \         'insertTextModeSupport': {
  \           'valueSet': [],
  \         }
  \       },
  \       'completionItemKind': {
  \         'valueSet': map(keys(lamp#protocol#completion#get_kind_map()), { k, v -> str2nr(v) })
  \       },
  \       'contextSupport': v:true
  \     },
  \     'hover': {
  \       'dynamicRegistration': v:false,
  \       'contentFormat': ['markdown'],
  \     },
  \     'signatureHelp': {
  \       'dynamicRegistration': v:false,
  \       'signatureInformation': {
  \         'documentationFormat': ['markdown'],
  \         'parameterInformation': {
  \           'labelOffsetSupport': v:true
  \         },
  \         'activeParameterSupport': v:true,
  \       },
  \       'contextSupport': v:true,
  \     },
  \     'declaration': {
  \       'dynamicRegistration': v:false,
  \       'linkSupport': v:true,
  \     },
  \     'definition': {
  \       'dynamicRegistration': v:false,
  \       'linkSupport': v:true,
  \     },
  \     'typeDefinition': {
  \       'dynamicRegistration': v:false,
  \       'linkSupport': v:true,
  \     },
  \     'implementation': {
  \       'dynamicRegistration': v:false,
  \       'linkSupport': v:true,
  \     },
  \     'references': {
  \       'dynamicRegistration': v:false,
  \     },
  \     'documentHighlight': {
  \       'dynamicRegistration': v:false,
  \     },
  \     'documentSymbol': {
  \       'dynamicRegistration': v:false,
  \       'symbolKind': {
  \         'valueSet': values(g:lamp#server#capabilities#symbol_kinds)
  \       },
  \       'hierarchicalDocumentSymbolSupport': v:true,
  \       'tagSupport': {
  \         'valueSet': [],
  \       },
  \       'labelSupport': v:false,
  \     },
  \     'codeAction': {
  \       'dynamicRegistration': v:false,
  \       'codeActionLiteralSupport': {
  \         'codeActionKind': {
  \           'valueSet': ['', 'quickfix', 'refactor', 'refactor.extract', 'refactor.inline', 'refactor.rewrite', 'source', 'source.organizeImports']
  \         }
  \       },
  \       'isPreferredSupport': v:true,
  \       'disabledSupport': v:true,
  \       'dataSupport': v:true,
  \       'resolveSupport': {
  \         'properties': [],
  \       },
  \       'honorsChangeAnnotations': v:true
  \     },
  \     'codeLens': {
  \       'dynamicRegistration': v:false,
  \     },
  \     'documentLink': {
  \       'dynamicRegistration': v:false,
  \       'tooltipSupport': v:false,
  \     },
  \     'colorProvider': {
  \       'dynamicRegistration': v:false,
  \     },
  \     'formatting': {
  \       'dynamicRegistration': v:false,
  \     },
  \     'rangeFormatting': {
  \       'dynamicRegistration': v:false,
  \     },
  \     'onTypeFormatting': {
  \       'dynamicRegistration': v:false,
  \     },
  \     'rename': {
  \       'prepareSupport': v:true,
  \       'prepareSupportDefaultBehavior': 1,
  \       'honorsChangeAnnotations': v:true,
  \     },
  \     'publishDiagnostics': {
  \       'relatedInformation': v:true,
  \       'tagSupport': {
  \         'valueSet': [],
  \       },
  \       'versionSupport': v:true,
  \       'codeDescriptionSupport': v:true,
  \       'dataSupport': v:true,
  \     },
  \     'foldingRange': {
  \       'dynamicRegistration': v:false,
  \       'rangeLimit': 100,
  \       'lineFoldingOnly': v:true,
  \     },
  \     'selectionRange': {
  \       'dynamicRegistration': v:false,
  \     },
  \     'linkedEditingRange': {
  \       'dynamicRegistration': v:false,
  \     },
  \     'callHierarchy': {
  \       'dynamicRegistration': v:false,
  \     },
  \     'semanticTokens': {
  \       'dynamicRegistration': v:false,
  \       'requests': {
  \         'range': v:true,
  \         'full': v:true,
  \       },
  \       'tokenTypes': [],
  \       'tokenModifiers': [],
  \       'formats': [],
  \       'overlappingTokenSupport': v:true,
  \       'multilineTokenSupport': v:true,
  \     },
  \     'moniker': {
  \       'dynamicRegistration': v:false,
  \     },
  \   },
  \   'window': {
  \     'workDoneProgress': v:false,
  \     'showMessage': {
  \       'messageActionItem': {
  \         'additionalPropertiesSupport': v:false,
  \       }
  \     },
  \     'showDocument': {
  \       'support': v:false,
  \     },
  \   },
  \   'general': {
  \     'regularExpressions': {
  \       'engine': 'vim',
  \       'version': '0'
  \     },
  \     'markdown': {
  \       'parser': 'vim',
  \       'version': '0'
  \     },
  \   },
  \ }
endfunction

"
" lamp#server#capabilities#import
"
function! lamp#server#capabilities#import() abort
  return s:Capabilities
endfunction

let s:Capabilities = {}

"
" new
"
function! s:Capabilities.new() abort
  return extend(deepcopy(s:Capabilities), {
  \   'capabilities': {},
  \   'dynamics': {}
  \ })
endfunction

"
" merge
"
function! s:Capabilities.merge(capabilities) abort
  let self.capabilities = a:capabilities
endfunction

"
" register
"
function! s:Capabilities.register(capability) abort
  echomsg string(['dynamic registration', a:capability])
endfunction

"
" unregister
"
function! s:Capabilities.unregister(capability) abort
endfunction

"
" supports
"
function! s:Capabilities.supports(path) abort
  return lamp#get(self.capabilities, a:path, v:null) isnot v:null
endfunction

"
" get_completion_commit_characters
"
function! s:Capabilities.get_completion_all_commit_characters() abort
  return lamp#get(self.capabilities, 'capabilities.completionProvider.allCommitCharacters', [])
endfunction

"
" get_completion_trigger_characters
"
function! s:Capabilities.get_completion_trigger_characters() abort
  return lamp#get(self.capabilities, 'capabilities.completionProvider.triggerCharacters', [])
endfunction

"
" get_on_type_formatting_trigger_characters
"
function! s:Capabilities.get_on_type_formatting_trigger_characters() abort
  let l:chars = []
  let l:first = lamp#get(self.capabilities, 'capabilities.documentOnTypeFormattingProvider.firstTriggerCharacter', v:null)
  if l:first isnot# v:null
    let l:chars += [l:first]
  endif
  return l:chars + lamp#get(self.capabilities, 'capabilities.documentOnTypeFormattingProvider.moreTriggerCharacter', [])
endfunction

"
" get_signature_help_trigger_characters
"
function! s:Capabilities.get_signature_help_trigger_characters() abort
  return lamp#get(self.capabilities, 'capabilities.signatureHelpProvider.triggerCharacters', [])
endfunction

"
" get_code_action_kinds
"
function! s:Capabilities.get_code_action_kinds() abort
  return lamp#get(self.capabilities, 'capabilities.codeActionProvider.codeActionKinds', [])
endfunction

"
" get_text_document_sync_kind
"
function! s:Capabilities.get_text_document_sync_kind() abort
  let l:kind_or_option = lamp#get(self.capabilities, 'capabilities.textDocumentSync', 0)
  if type(l:kind_or_option) == type(0)
    return l:kind_or_option
  endif
  return lamp#get(l:kind_or_option, 'change', 0)
endfunction

"
" get_text_document_sync_will_save
"
function! s:Capabilities.get_text_document_sync_will_save() abort
  return lamp#get(self.capabilities, 'capabilities.textDocumentSync.willSave', v:false)
endfunction

"
" get_text_document_sync_will_save_wait_until
"
function! s:Capabilities.get_text_document_sync_will_save_wait_until() abort
  return lamp#get(self.capabilities, 'capabilities.textDocumentSync.willSaveWaitUntil', v:false)
endfunction

"
" get_text_document_sync_save
"
function! s:Capabilities.get_text_document_sync_save() abort
  return lamp#get(self.capabilities, 'capabilities.textDocumentSync.save', v:null) isnot# v:null
endfunction

"
" get_text_document_sync_save_include_text
"
function! s:Capabilities.get_text_document_sync_save_include_text() abort
  return lamp#get(self.capabilities, 'capabilities.textDocumentSync.save.includeText', v:false)
endfunction

"
" is_workspace_folder_supported
"
function! s:Capabilities.is_workspace_folder_supported() abort
  let l:capabilities = get(self, 'capabilities', {})
  let l:is_supported = lamp#get(l:capabilities, 'capabilities.workspace.workspaceFolders.supported', v:false)
  if !l:is_supported
    return v:false
  endif
  let l:change_notifications = lamp#get(l:capabilities, 'capabilities.workspace.workspaceFolders.changeNotifications', v:true)
  return type(l:change_notifications) == type(v:true) || strlen(l:change_notifications) > 0
endfunction

