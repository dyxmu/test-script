# WeAreDevs / Prometheus Lua Deobfuscator

Deobfuscator for Lua scripts obfuscated with [WeAreDevs Obfuscator](https://wearedevs.net/obfuscator), which is based on [Prometheus](https://github.com/prometheus-lua/Prometheus).

## Features

- **String table decoding**: Extracts and decodes the custom base64-encoded string table
- **Swap/shuffle reversal**: Reverses the array shuffling applied to the string table
- **Anti-tamper bypass**: Uses a complete environment technique to bypass Prometheus anti-tamper
- **Type-aware tracing**: Preserves type information (distinguishes `"123"` from `123`)
- **Pattern detection**: Detects `for` loops, variable assignments, and function calls
- **Large file analysis**: For files that don't produce console output (UI frameworks, etc.), provides structural analysis

## Requirements

- Python 3.6+
- Lua 5.1 (`lua5.1`) - for runtime tracing

```bash
# Install Lua 5.1 on Ubuntu/Debian
sudo apt-get install lua5.1
```

## Usage

```bash
# Basic usage (outputs to stdout)
python3 deobfuscate.py obfuscated.lua

# Save to file
python3 deobfuscate.py obfuscated.lua output.lua
```

## How it works

### 1. String Table Extraction
The obfuscator stores all string constants (API names, identifiers) in a table using octal escape sequences. The deobfuscator parses these and decodes them.

### 2. Swap Operations
The obfuscator applies reversals to portions of the string table. We extract and replay these operations.

### 3. Custom Base64 Decoding
Prometheus uses a shuffled base64 alphabet (64 unique characters mapped to values 0-63). We extract the mapping and decode all strings.

### 4. Runtime Tracing (tracer.lua)
The main reconstruction uses `tracer.lua` which:
- Creates a complete Lua environment with all globals explicitly set (bypasses anti-tamper)
- Hooks `print` while preserving type information
- Calls the original print to satisfy any return-value checks
- Detects patterns in the output (for loops, variable assignments)

### 5. Structural Analysis
For code that doesn't produce output (like Roblox scripts), the tool provides:
- List of all Lua/Roblox API calls
- Metamethods used
- All user string constants
- Exploit environment detection patterns

## Limitations

- **Variable names are not preserved**: Prometheus strips all local variable names. Reconstructed code uses generic names (`var`, `i`)
- **Complex control flow**: `while` loops, `if/else` branches, and nested functions are only partially reconstructed from runtime traces
- **Non-output code**: For code that doesn't call `print`/`io.write`, only string analysis is available (no full source reconstruction)
- **One-time execution**: The tracer captures one execution path. Code with branching may not trace all paths

## Example

**Original:**
```lua
print("TEST")
local pOPA = "123"
print(pOPA)
for i = 1, 10 do
    print(i)
end
```

**Deobfuscated output:**
```lua
print("TEST")
local var = "123"
print(var)
for i = 1, 10 do
    print(i)
end
```

## Files

- `deobfuscate.py` - Main Python deobfuscator (string table + orchestration)
- `tracer.lua` - Lua runtime tracer with anti-tamper bypass
