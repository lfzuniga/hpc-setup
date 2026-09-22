-- Set the remote clipboard provider without changing the shared nvim repo.
-- In remote Neovim, "+y writes to your laptop clipboard over OSC 52.
vim.g.clipboard = 'osc52'
