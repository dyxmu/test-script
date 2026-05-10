# WeAreDevs/Prometheus Lua Deobfuscator

Deobfuscates scripts protected by the WeAreDevs/Prometheus obfuscator. Outputs full source code.

## Usage

```bash
# Direct Lua execution (fastest)
lua5.1 full_tracer.lua obfuscated.lua output.lua

# Via Python wrapper
python3 deobfuscate.py obfuscated.lua output.lua
```

## Requirements

- `lua5.1` (apt install lua5.1)
- Python 3.6+ (for wrapper only)

## What it does

1. Bypasses anti-tamper checks via complete Lua environment
2. Intercepts all API calls (print, game:GetService, Instance.new, etc.)
3. Tracks property assignments and event connections
4. Detects for loops from sequential patterns
5. Outputs reconstructed source code

## Example output

### Simple script (17KB):
```lua
print("TEST")
print("123")
for i = 1, 10 do
    print(i)
end
```

### Roblox script (624KB):
```lua
local Players = game:GetService("Players")
local TweenService = game:GetService("TweenService")
local CoreGui = game:GetService("CoreGui")
local screenGui = Instance.new("ScreenGui")
screenGui.Name = "ArqelRedSystem"
screenGui.Parent = CoreGui
...
```

## Files

- `full_tracer.lua` - Main deobfuscator (Lua 5.1)
- `deobfuscate.py` - Python wrapper with timeout
- `devirtualize.py` - Static VM block analysis (advanced, shows raw VM structure)

## Limitations

- Variable names cannot be recovered (Prometheus strips them)
- `local x = "value"` assignments only visible when the value is used in a tracked call
- Control flow (if/else) inside the VM is partially reconstructed via callback execution
- Requires lua5.1 runtime
