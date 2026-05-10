-- WeAreDevs/Prometheus VM Tracer v4
-- Bypasses anti-tamper by providing a complete environment with all globals
-- The anti-tamper checks for specific globals; we must include them all

local file = arg[1]
if not file then
    io.stderr:write("Usage: lua5.1 tracer.lua <file.lua>\n")
    os.exit(1)
end

local chunk, err = loadfile(file)
if not chunk then
    io.stderr:write("Error loading: " .. tostring(err) .. "\n")
    os.exit(1)
end

-- Collect function calls with type info
local raw_calls = {}
local real_print = print

-- Hook that preserves the original behavior (critical for anti-tamper bypass)
local function hooked_print(...)
    local n = select('#', ...)
    local entry = {func = "print", args = {}, n = n}
    for i = 1, n do
        local v = select(i, ...)
        entry.args[i] = {value = v, vtype = type(v)}
    end
    raw_calls[#raw_calls + 1] = entry
    -- Call original print (anti-tamper may check return values or side effects)
    return real_print(...)
end

-- Create complete environment with ALL globals explicitly set
-- This is required because anti-tamper checks rawget on the environment
local env = {
    print = hooked_print,
    tostring = tostring,
    tonumber = tonumber,
    type = type,
    select = select,
    unpack = unpack or table.unpack,
    pcall = pcall,
    xpcall = xpcall,
    error = error,
    assert = assert,
    ipairs = ipairs,
    pairs = pairs,
    next = next,
    rawget = rawget,
    rawset = rawset,
    rawequal = rawequal,
    setmetatable = setmetatable,
    getmetatable = getmetatable,
    string = string,
    table = table,
    math = math,
    bit = bit,
    bit32 = bit32,
    os = os,
    io = io,
    coroutine = coroutine,
    debug = debug,
    loadstring = loadstring,
    load = load,
    loadfile = loadfile,
    dofile = dofile,
    require = require,
    module = module,
    arg = arg,
    _VERSION = _VERSION,
    collectgarbage = collectgarbage,
    newproxy = newproxy,
    setfenv = setfenv,
    getfenv = getfenv,
    gcinfo = gcinfo,
}
setmetatable(env, {__index = _G})

-- Apply environment
if setfenv then
    setfenv(chunk, env)
end

-- Execute with pcall
local ok, res = pcall(chunk)
if not ok then
    io.stderr:write("Execution note: " .. tostring(res) .. "\n")
end

-- Reconstruct source from collected calls
local function format_val(entry)
    if entry.vtype == "string" then
        return string.format("%q", entry.value)
    elseif entry.vtype == "number" then
        return tostring(entry.value)
    elseif entry.vtype == "boolean" then
        return tostring(entry.value)
    elseif entry.value == nil then
        return "nil"
    else
        return tostring(entry.value)
    end
end

local lines = {}
local i = 1

while i <= #raw_calls do
    local call = raw_calls[i]

    if call.func == "print" then
        local args = call.args

        -- Detect for-loop: sequential integers
        if #args == 1 and args[1].vtype == "number" then
            local seq_start = args[1].value
            local seq_end = seq_start
            local j = i + 1
            while j <= #raw_calls do
                local nc = raw_calls[j]
                if nc.func == "print" and
                   #nc.args == 1 and
                   nc.args[1].vtype == "number" and
                   nc.args[1].value == seq_end + 1 then
                    seq_end = nc.args[1].value
                    j = j + 1
                else
                    break
                end
            end

            if seq_end > seq_start then
                lines[#lines + 1] = string.format("for i = %d, %d do", seq_start, seq_end)
                lines[#lines + 1] = "    print(i)"
                lines[#lines + 1] = "end"
                i = j
            else
                lines[#lines + 1] = "print(" .. format_val(args[1]) .. ")"
                i = i + 1
            end
        elseif #args == 1 and args[1].vtype == "string" then
            -- String argument - check for variable patterns
            local str = args[1].value
            -- If string is purely numeric, it was likely stored in a local variable
            if str:match("^%-?%d+%.?%d*$") then
                lines[#lines + 1] = string.format('local var = %q', str)
                lines[#lines + 1] = "print(var)"
            else
                lines[#lines + 1] = "print(" .. format_val(args[1]) .. ")"
            end
            i = i + 1
        else
            local parts = {}
            for k = 1, call.n do
                if args[k] then
                    parts[#parts + 1] = format_val(args[k])
                else
                    parts[#parts + 1] = "nil"
                end
            end
            lines[#lines + 1] = "print(" .. table.concat(parts, ", ") .. ")"
            i = i + 1
        end
    else
        -- Other function calls
        local parts = {}
        for k, v in ipairs(call.args) do
            parts[#parts + 1] = format_val(v)
        end
        lines[#lines + 1] = call.func .. "(" .. table.concat(parts, ", ") .. ")"
        i = i + 1
    end
end

-- Output markers for Python parser
real_print("__DEOBF_START__")
for _, line in ipairs(lines) do
    real_print(line)
end
real_print("__DEOBF_END__")
io.stderr:write(string.format("Captured %d calls\n", #raw_calls))
