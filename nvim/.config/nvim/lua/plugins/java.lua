-- Java (nvim-jdtls)
-- Uses nvim-jdtls instead of lspconfig for per-project workspace
-- isolation and IntelliJ-level features (organize imports, code gen, DAP)

local gh = require('config.pack').gh

vim.pack.add { gh 'mfussenegger/nvim-jdtls' }

vim.api.nvim_create_autocmd('FileType', {
  pattern = 'java',
  callback = function()
    local ok, jdtls = pcall(require, 'jdtls')
    if not ok then return end

    local ok_mason, registry = pcall(require, 'mason-registry')
    if not ok_mason or not registry.is_installed 'jdtls' then
      vim.notify('jdtls not installed — run :MasonInstall jdtls', vim.log.levels.WARN)
      return
    end

    local install_path = registry.get_package('jdtls'):get_install_path()
    local launcher = vim.fn.glob(install_path .. '/plugins/org.eclipse.equinox.launcher_*.jar', true)
    local os_config = vim.fn.has 'mac' == 1 and 'mac' or 'linux'

    -- Isolated workspace per project root (prevents cross-project contamination)
    local root_markers = { '.git', 'mvnw', 'gradlew', 'pom.xml', 'build.gradle', 'build.gradle.kts' }
    local root_dir = jdtls.setup.find_root(root_markers) or vim.fn.getcwd()
    local workspace_dir = vim.fn.stdpath 'data' .. '/jdtls-workspace/' .. vim.fn.fnamemodify(root_dir, ':t')

    jdtls.start_or_attach {
      cmd = {
        'java',
        '-Declipse.application=org.eclipse.jdt.ls.core.id1',
        '-Dosgi.bundles.defaultStartLevel=4',
        '-Declipse.product=org.eclipse.jdt.ls.core.product',
        '-Dlog.protocol=true',
        '-Dlog.level=ALL',
        '-Xmx2g',
        '--add-modules=ALL-SYSTEM',
        '--add-opens', 'java.base/java.util=ALL-UNNAMED',
        '--add-opens', 'java.base/java.lang=ALL-UNNAMED',
        '-jar', launcher,
        '-configuration', install_path .. '/config_' .. os_config,
        '-data', workspace_dir,
      },
      root_dir = root_dir,
      settings = {
        java = {
          signatureHelp = { enabled = true },
          completion = { favoriteStaticMembers = {
            'org.junit.Assert.*',
            'org.junit.jupiter.api.Assertions.*',
            'org.mockito.Mockito.*',
          } },
          sources = { organizeImports = { starThreshold = 9999, staticStarThreshold = 9999 } },
          codeGeneration = {
            toString = { template = '${object.className}{${member.name()}=${member.value}, }' },
            useBlocks = true,
          },
        },
      },
      init_options = { bundles = {} },
      -- Java-specific keymaps (active only in Java buffers)
      on_attach = function(_, bufnr)
        local map = function(keys, fn, desc)
          vim.keymap.set('n', keys, fn, { buffer = bufnr, desc = 'Java: ' .. desc })
        end
        map('<leader>co', jdtls.organize_imports, 'Organize imports')
        map('<leader>cv', jdtls.extract_variable, 'Extract variable')
        map('<leader>cm', jdtls.extract_method, 'Extract method')
        -- nvim-jdtls has no generate function: jdtls offers these as source.generate.* code actions
        map('<leader>cg', function() vim.lsp.buf.code_action { context = { only = { 'source.generate' } } } end, 'Generate (constructors / getters / setters)')
      end,
    }
  end,
})
