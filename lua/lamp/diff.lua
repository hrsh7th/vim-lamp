local attached = {}

local function attach(id, bufnr)
  if attached[id] == nil then
    attached[id] = {}
  end
  attached[id][bufnr] = true

  vim.api.nvim_buf_attach(bufnr, false, {
    on_lines=function(_, bufnr, changedtick, firstline, lastline, new_lastline, old_byte_size, old_utf32_size, old_utf16_size)
      if attached[id] == nil then
        return true
      end
      if attached[id][bufnr] == nil then
        return true
      end
      vim.api.nvim_call_function('lamp#view#diff#nvim#on_lines', { {
        id = id,
        bufnr = bufnr,
        changedtick = changedtick,
        firstline = firstline,
        lastline = lastline,
        new_lastline = new_lastline,
        old_byte_size = old_byte_size,
        old_utf32_size = old_utf32_size,
        old_utf16_size = old_utf16_size
      } })
      return false
    end;
    utf_sizes = true;
  })
end

local function detach(id, bufnr)
  if attached[id] == nil then
    attached[id] = {}
  end
  attached[id][bufnr] = nil
end


return {
  attach = attach,
  detach = detach,
}

