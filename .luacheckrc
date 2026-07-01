-- luacheck configuration for the Neovim Lua config.
-- Neovim runs LuaJIT (Lua 5.1) and injects `vim` as a global at runtime, which
-- luacheck can't know about — declare it so the config lints cleanly.
std = "luajit"
globals = { "vim" }
