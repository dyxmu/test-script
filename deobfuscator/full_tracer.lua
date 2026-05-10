-- WeAreDevs/Prometheus Full Source Reconstructor V2
-- Produces actual runnable Lua source code from obfuscated VM
-- Handles Roblox APIs with proper variable naming

local file = arg[1]
local outfile = arg[2]
if not file then
    io.stderr:write("Usage: lua5.1 full_tracer.lua <file.lua> [output.lua]\n")
    os.exit(1)
end

local chunk, err = loadfile(file)
if not chunk then
    io.stderr:write("Error loading: " .. tostring(err) .. "\n")
    os.exit(1)
end

-- ============================================================================
-- SOURCE RECONSTRUCTION ENGINE
-- ============================================================================
local lines = {}       -- output source lines
local var_counter = 0  -- for generating unique variable names
local obj_names = {}   -- maps proxy objects to their variable names
local obj_types = {}   -- maps proxy objects to their type/class
local pending_value = nil  -- last value that needs assignment
local service_vars = {}   -- maps service name to variable name
local indent = 0
local in_callback = false
local callbacks = {}   -- collected callback functions
local connect_targets = {} -- objects that had :Connect called

local function get_indent()
    return string.rep("    ", indent)
end

local function emit(line)
    lines[#lines + 1] = get_indent() .. line
end

local function emit_raw(line)
    lines[#lines + 1] = line
end

local function gen_var(hint)
    if hint then
        -- Clean the hint for use as variable name
        local clean = hint:gsub("[^%w_]", ""):gsub("^%d", "_")
        if #clean > 0 then
            return clean
        end
    end
    var_counter = var_counter + 1
    return "var_" .. var_counter
end

local function name_from_class(class)
    -- Generate nice variable name from class name
    -- e.g. "ScreenGui" -> "screenGui", "TextLabel" -> "textLabel"
    if not class or class == "" then return nil end
    return class:sub(1,1):lower() .. class:sub(2)
end

local function value_to_str(v)
    if v == nil then return "nil" end
    if type(v) == "string" then return string.format("%q", v) end
    if type(v) == "number" then return tostring(v) end
    if type(v) == "boolean" then return tostring(v) end
    if type(v) == "table" and obj_names[v] then
        return obj_names[v]
    end
    if type(v) == "function" then return "function() end" end
    if type(v) == "table" then return "{}" end
    return tostring(v)
end

-- ============================================================================
-- SMART PROXY SYSTEM
-- ============================================================================
local proxy_mt_cache = {}

local function make_smart_proxy(name, class_name, methods)
    local proxy = {}
    local prop_assignments = {}

    obj_names[proxy] = name
    obj_types[proxy] = class_name or name

    local mt = {
        __index = function(t, k)
            local full = name .. "." .. tostring(k)
            if methods and methods[k] then
                return methods[k]
            end
            -- Handle common Roblox patterns
            if k == "Connect" or k == "connect" then
                return function(self, callback)
                    local event_name = name
                    if type(callback) == "function" then
                        callbacks[#callbacks + 1] = {event = event_name, func = callback}
                        emit(name .. ":Connect(function()")
                        indent = indent + 1
                        in_callback = true
                        local ok, e = pcall(callback)
                        in_callback = false
                        indent = indent - 1
                        emit("end)")
                    end
                    return make_smart_proxy(full .. ":Connect()", nil)
                end
            end
            if k == "WaitForChild" then
                return function(self, child_name)
                    local result_name = name .. ":WaitForChild(\"" .. tostring(child_name) .. "\")"
                    local var = gen_var(tostring(child_name))
                    local result = make_smart_proxy(var, tostring(child_name))
                    emit("local " .. var .. " = " .. name .. ":WaitForChild(" .. string.format("%q", tostring(child_name)) .. ")")
                    return result
                end
            end
            if k == "FindFirstChild" then
                return function(self, child_name)
                    local result = make_smart_proxy(name .. ":FindFirstChild(" .. value_to_str(child_name) .. ")", nil)
                    return result
                end
            end
            if k == "Destroy" then
                return function(self)
                    emit(name .. ":Destroy()")
                end
            end
            if k == "Clone" then
                return function(self)
                    local var = gen_var("clone")
                    local result = make_smart_proxy(var, class_name)
                    emit("local " .. var .. " = " .. name .. ":Clone()")
                    return result
                end
            end
            if k == "GetChildren" or k == "GetDescendants" then
                return function(self)
                    return {}
                end
            end
            if k == "Play" then
                return function(self, ...)
                    emit(name .. ":Play()")
                end
            end
            -- Property read - return a sub-proxy
            return make_smart_proxy(full, nil)
        end,
        __newindex = function(t, k, v)
            -- Property assignment
            local val_str = value_to_str(v)
            emit(name .. "." .. k .. " = " .. val_str)
        end,
        __tostring = function()
            return name
        end,
        __call = function(self, ...)
            local args = {...}
            local arg_strs = {}
            for i, a in ipairs(args) do
                arg_strs[i] = value_to_str(a)
            end
            local call_str = name .. "(" .. table.concat(arg_strs, ", ") .. ")"
            local result = make_smart_proxy(call_str, nil)
            return result
        end,
        __concat = function(a, b)
            return tostring(a) .. tostring(b)
        end,
        __eq = function(a, b) return rawequal(a, b) end,
        __len = function(self) return 0 end,
        __unm = function(self) return 0 end,
        __add = function(a, b) return make_smart_proxy(value_to_str(a) .. " + " .. value_to_str(b)) end,
        __sub = function(a, b) return make_smart_proxy(value_to_str(a) .. " - " .. value_to_str(b)) end,
        __mul = function(a, b) return make_smart_proxy(value_to_str(a) .. " * " .. value_to_str(b)) end,
        __div = function(a, b) return make_smart_proxy(value_to_str(a) .. " / " .. value_to_str(b)) end,
    }
    return setmetatable(proxy, mt)
end

-- ============================================================================
-- ROBLOX STUBS
-- ============================================================================

-- Enum
local enum_mt
enum_mt = {
    __index = function(t, k)
        local name = (rawget(t, '_name') or 'Enum') .. '.' .. k
        local e = setmetatable({_name = name}, enum_mt)
        return e
    end,
    __tostring = function(t) return rawget(t, '_name') or 'Enum' end,
    __eq = function(a, b) return tostring(a) == tostring(b) end,
}
local Enum_stub = setmetatable({_name = 'Enum'}, enum_mt)

-- game:GetService
local game_methods = {}
game_methods.GetService = function(self, svc_name)
    if not service_vars[svc_name] then
        local var = gen_var(svc_name)
        service_vars[svc_name] = var
        local svc = make_smart_proxy(var, svc_name)
        emit("local " .. var .. " = game:GetService(" .. string.format("%q", svc_name) .. ")")
        return svc
    end
    return make_smart_proxy(service_vars[svc_name], svc_name)
end
game_methods.HttpGet = function(self, url)
    var_counter = var_counter + 1
    local var = "httpResult_" .. var_counter
    emit("local " .. var .. " = game:HttpGet(" .. string.format("%q", url) .. ")")
    return ""
end

local game_stub = make_smart_proxy("game", "DataModel", game_methods)

-- Instance.new
local instance_counter = {}
local Instance_stub = {
    new = function(class, parent)
        local base = name_from_class(class) or "instance"
        instance_counter[base] = (instance_counter[base] or 0) + 1
        local var
        if instance_counter[base] == 1 then
            var = base
        else
            var = base .. instance_counter[base]
        end
        local inst = make_smart_proxy(var, class)
        local parent_str = parent and (", " .. value_to_str(parent)) or ""
        emit("local " .. var .. " = Instance.new(" .. string.format("%q", class) .. parent_str .. ")")
        return inst
    end,
}

-- Drawing.new
local drawing_counter = {}
local Drawing_stub = {
    new = function(class)
        local base = "drawing_" .. (class or "obj"):lower()
        drawing_counter[base] = (drawing_counter[base] or 0) + 1
        local var = base .. (drawing_counter[base] > 1 and drawing_counter[base] or "")
        local inst = make_smart_proxy(var, class)
        emit("local " .. var .. " = Drawing.new(" .. string.format("%q", class) .. ")")
        return inst
    end,
}

-- Constructors
local function make_value_constructor(ctor_name)
    return {
        new = function(...)
            local args = {...}
            local arg_strs = {}
            for i, a in ipairs(args) do arg_strs[i] = value_to_str(a) end
            local result = make_smart_proxy(ctor_name .. ".new(" .. table.concat(arg_strs, ", ") .. ")", ctor_name)
            return result
        end,
        fromRGB = function(r, g, b)
            local result = make_smart_proxy(ctor_name .. ".fromRGB(" .. tostring(r) .. ", " .. tostring(g) .. ", " .. tostring(b) .. ")", ctor_name)
            return result
        end,
        fromHSV = function(h, s, v)
            local result = make_smart_proxy(ctor_name .. ".fromHSV(" .. tostring(h) .. ", " .. tostring(s) .. ", " .. tostring(v) .. ")", ctor_name)
            return result
        end,
    }
end

-- task
local task_stub = {
    wait = function(t)
        emit("task.wait(" .. (t and tostring(t) or "") .. ")")
        return t or 0
    end,
    spawn = function(f)
        emit("task.spawn(function()")
        indent = indent + 1
        if type(f) == "function" then pcall(f) end
        indent = indent - 1
        emit("end)")
    end,
    defer = function(f)
        emit("task.defer(function()")
        indent = indent + 1
        if type(f) == "function" then pcall(f) end
        indent = indent - 1
        emit("end)")
    end,
    delay = function(t, f)
        emit("task.delay(" .. tostring(t) .. ", function()")
        indent = indent + 1
        if type(f) == "function" then pcall(f) end
        indent = indent - 1
        emit("end)")
    end,
    cancel = function(t) emit("task.cancel(...)") end,
}

-- ============================================================================
-- UTILITY STUBS
-- ============================================================================
local function stub_func(name)
    return function(...)
        local args = {...}
        local arg_strs = {}
        for i, a in ipairs(args) do arg_strs[i] = value_to_str(a) end
        emit(name .. "(" .. table.concat(arg_strs, ", ") .. ")")
    end
end

local function stub_func_ret(name, ret)
    return function(...)
        local args = {...}
        local arg_strs = {}
        for i, a in ipairs(args) do arg_strs[i] = value_to_str(a) end
        var_counter = var_counter + 1
        local var = "result_" .. var_counter
        emit("local " .. var .. " = " .. name .. "(" .. table.concat(arg_strs, ", ") .. ")")
        return ret
    end
end

-- ============================================================================
-- FULL ENVIRONMENT
-- ============================================================================
local real_print = print

local env = {
    -- Standard Lua (needed for anti-tamper to pass)
    print = function(...)
        local args = {...}
        local arg_strs = {}
        for i, a in ipairs(args) do arg_strs[i] = value_to_str(a) end
        emit("print(" .. table.concat(arg_strs, ", ") .. ")")
    end,
    warn = function(...)
        local args = {...}
        local arg_strs = {}
        for i, a in ipairs(args) do arg_strs[i] = value_to_str(a) end
        emit("warn(" .. table.concat(arg_strs, ", ") .. ")")
    end,
    error = error,
    assert = assert,
    type = type,
    typeof = function(v)
        if type(v) == "table" and obj_types[v] then
            return obj_types[v]
        end
        return type(v)
    end,
    tostring = tostring,
    tonumber = tonumber,
    tonum = tonumber,
    select = select,
    unpack = unpack or table.unpack,
    pcall = pcall,
    xpcall = xpcall,
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
    require = function(m)
        emit("require(" .. string.format("%q", tostring(m)) .. ")")
        return {}
    end,
    _VERSION = _VERSION,
    collectgarbage = collectgarbage,
    newproxy = newproxy,
    setfenv = setfenv,
    getfenv = getfenv,
    gcinfo = gcinfo,

    -- Roblox globals
    game = game_stub,
    workspace = make_smart_proxy("workspace", "Workspace"),
    script = make_smart_proxy("script", "LocalScript"),
    Instance = Instance_stub,
    Drawing = Drawing_stub,
    Enum = Enum_stub,
    Vector2 = make_value_constructor("Vector2"),
    Vector3 = make_value_constructor("Vector3"),
    CFrame = make_value_constructor("CFrame"),
    UDim = make_value_constructor("UDim"),
    UDim2 = make_value_constructor("UDim2"),
    Color3 = make_value_constructor("Color3"),
    BrickColor = make_value_constructor("BrickColor"),
    TweenInfo = make_value_constructor("TweenInfo"),
    NumberSequence = make_value_constructor("NumberSequence"),
    ColorSequence = make_value_constructor("ColorSequence"),
    NumberRange = make_value_constructor("NumberRange"),
    Rect = make_value_constructor("Rect"),
    Region3 = make_value_constructor("Region3"),
    Ray = make_value_constructor("Ray"),
    task = task_stub,
    wait = function(t)
        emit("wait(" .. (t and tostring(t) or "") .. ")")
        return t or 0
    end,
    spawn = function(f)
        emit("spawn(function()")
        indent = indent + 1
        if type(f) == "function" then pcall(f) end
        indent = indent - 1
        emit("end)")
    end,
    delay = function(t, f)
        emit("delay(" .. tostring(t) .. ", function()")
        indent = indent + 1
        if type(f) == "function" then pcall(f) end
        indent = indent - 1
        emit("end)")
    end,
    tick = function() return os.clock() end,
    time = function() return os.clock() end,
    os = {clock = os.clock, time = os.time, date = os.date, difftime = os.difftime},

    -- Exploit APIs
    getgenv = function()
        emit("-- getgenv()")
        return env
    end,
    getrenv = function()
        return {}
    end,
    gethui = function()
        return make_smart_proxy("CoreGui", "CoreGui")
    end,
    syn = make_smart_proxy("syn", "SynX"),
    fluxus = make_smart_proxy("fluxus", "Fluxus"),
    request = function(opts)
        emit("request(" .. value_to_str(opts) .. ")")
        return {StatusCode = 200, Body = ""}
    end,
    http_request = function(opts)
        emit("http_request(" .. value_to_str(opts) .. ")")
        return {StatusCode = 200, Body = ""}
    end,
    writefile = stub_func("writefile"),
    readfile = function(path)
        emit("readfile(" .. string.format("%q", tostring(path)) .. ")")
        return ""
    end,
    isfile = function(path)
        emit("-- isfile(" .. string.format("%q", tostring(path)) .. ")")
        return false
    end,
    delfile = stub_func("delfile"),
    isfolder = function(path) return false end,
    makefolder = stub_func("makefolder"),
    listfiles = function(path) return {} end,
    setclipboard = stub_func("setclipboard"),
    getexecutorname = function() return "Devin" end,
    identifyexecutor = function() return "Devin", "1.0" end,
    rconsoleprint = stub_func("rconsoleprint"),
    rconsoleinfo = stub_func("rconsoleinfo"),
    rconsolewarn = stub_func("rconsolewarn"),
    rconsoleerr = stub_func("rconsoleerr"),
    rconsoleclear = stub_func("rconsoleclear"),
    rconsolename = stub_func("rconsolename"),
    WebSocket = make_smart_proxy("WebSocket", "WebSocket"),
    crypt = make_smart_proxy("crypt", "crypt"),
    settings = function() return make_smart_proxy("settings()", "Settings") end,

    -- Anti-kick/detection
    hookfunction = function(old, new) return old end,
    hookmetamethod = function(obj, method, new) return function() end end,
    getnamecallmethod = function() return "" end,
    checkcaller = function() return true end,
    newcclosure = function(f) return f end,
    islclosure = function(f) return type(f) == "function" end,
    iscclosure = function(f) return false end,
    getinfo = debug.getinfo,
    firesignal = stub_func("firesignal"),
    fireclickdetector = stub_func("fireclickdetector"),
    fireproximityprompt = stub_func("fireproximityprompt"),
    firetouchinterest = stub_func("firetouchinterest"),
}
setmetatable(env, {__index = _G})

-- Apply environment
if setfenv then
    setfenv(chunk, env)
end

-- ============================================================================
-- EXECUTE
-- ============================================================================
local ok, res = pcall(chunk)
if not ok then
    io.stderr:write("Execution note: " .. tostring(res) .. "\n")
end

-- ============================================================================
-- OUTPUT
-- ============================================================================
local output = table.concat(lines, "\n")
local header = [[-- ============================================================================
-- Deobfuscated by WeAreDevs/Prometheus Deobfuscator
-- Full source reconstruction via runtime tracing + Roblox API stubs
-- ============================================================================

]]

output = header .. output

if outfile then
    local f = io.open(outfile, "w")
    f:write(output)
    f:close()
    real_print("Written to: " .. outfile)
    real_print("Lines: " .. #lines)
else
    real_print(output)
end
