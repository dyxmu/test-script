-- This Script is Part of the Prometheus Obfuscator by Levno_710
--
-- cli.lua
--
-- This Script contains the Code for the Prometheus CLI.

-- Configure package.path for requiring Prometheus.
local function script_path()
	local str = debug.getinfo(2, "S").source:sub(2)
	return str:match("(.*[/%\\])")
end
package.path = script_path() .. "?.lua;" .. package.path
---@diagnostic disable-next-line: different-requires
local Prometheus = require("prometheus")
Prometheus.Logger.logLevel = Prometheus.Logger.LogLevel.Info

-- Check if the file exists
local function file_exists(file)
	local f = io.open(file, "rb")
	if f then
		f:close()
	end
	return f ~= nil
end

string.split = function(str, sep)
	local fields = {}
	local pattern = string.format("([^%s]+)", sep)
	str:gsub(pattern, function(c)
		fields[#fields + 1] = c
	end)
	return fields
end

-- get all lines from a file, returns an empty
-- list/table if the file does not exist
local function lines_from(file)
	if not file_exists(file) then
		return {}
	end
	local lines = {}
	for line in io.lines(file) do
		lines[#lines + 1] = line
	end
	return lines
end

local function load_chunk(content, chunkName, environment)
	if type(loadstring) == "function" then
		local func, err = loadstring(content, chunkName)
		if not func then
			return nil, err
		end
		if environment and type(setfenv) == "function" then
			setfenv(func, environment)
		elseif environment and type(load) == "function" then
			return load(content, chunkName, "t", environment)
		end
		return func
	end

	if type(load) ~= "function" then
		return nil, "No load function available"
	end

	return load(content, chunkName, "t", environment)
end

-- CLI
local config, outFile, outDir, luaVersion, prettyPrint, saveErrors
local sourceFiles = {}

Prometheus.colors.enabled = true

-- Parse Arguments
local i = 1
while i <= #arg do
	local curr = arg[i]
	if curr:sub(1, 2) == "--" then
		if curr == "--preset" or curr == "--p" then
			if config then
				Prometheus.Logger:warn("The config was set multiple times")
			end

			i = i + 1
			local preset = Prometheus.Presets[arg[i]]
			if not preset then
				Prometheus.Logger:error(string.format('A Preset with the name "%s" was not found!', tostring(arg[i])))
			end

			config = preset
		elseif curr == "--config" or curr == "--c" then
			i = i + 1
			local filename = tostring(arg[i])
			if not file_exists(filename) then
				Prometheus.Logger:error(string.format('The config file "%s" was not found!', filename))
			end

			local content = table.concat(lines_from(filename), "\n")
			local func, err = load_chunk(content, "@" .. filename, {})
			if not func then
				Prometheus.Logger:error(string.format('Failed to parse config file "%s": %s', filename, tostring(err)))
			end
			config = func()
		elseif curr == "--out" or curr == "--o" then
			i = i + 1
			if outFile then
				Prometheus.Logger:warn("The output file was specified multiple times!")
			end
			outFile = arg[i]
		elseif curr == "--outdir" or curr == "--d" then
			i = i + 1
			outDir = arg[i]
		elseif curr == "--nocolors" then
			Prometheus.colors.enabled = false
		elseif curr == "--Lua51" then
			luaVersion = "Lua51"
		elseif curr == "--LuaU" then
			luaVersion = "LuaU"
		elseif curr == "--pretty" then
			prettyPrint = true
		elseif curr == "--saveerrors" then
			saveErrors = true
		else
			Prometheus.Logger:warn(string.format('The option "%s" is not valid and therefore ignored', curr))
		end
	else
		sourceFiles[#sourceFiles + 1] = tostring(arg[i])
	end
	i = i + 1
end

if #sourceFiles == 0 then
	Prometheus.Logger:error("No input file(s) specified! Usage: lua cli.lua [options] file1.lua [file2.lua ...]")
end

if not config then
	Prometheus.Logger:warn("No config was specified, falling back to Minify preset")
	config = Prometheus.Presets.Minify
end

-- Add Option to override Lua Version
config.LuaVersion = luaVersion or config.LuaVersion
config.PrettyPrint = prettyPrint ~= nil and prettyPrint or config.PrettyPrint

-- --out is only valid for single file mode
if outFile and #sourceFiles > 1 then
	Prometheus.Logger:warn("--out is ignored when multiple input files are specified. Use --outdir instead.")
	outFile = nil
end

-- Helper: generate output path for a given source file
local function get_out_path(srcFile)
	local base
	if srcFile:sub(-4) == ".lua" then
		base = srcFile:sub(1, -5) .. ".obfuscated.lua"
	else
		base = srcFile .. ".obfuscated.lua"
	end

	if outDir then
		local name = base:match("[/\\]([^/\\]+)$") or base
		local sep = package.config:sub(1, 1)
		if outDir:sub(-1) ~= sep and outDir:sub(-1) ~= "/" and outDir:sub(-1) ~= "\\" then
			outDir = outDir .. sep
		end
		return outDir .. name
	end

	return base
end

-- Process each input file
local totalFiles = #sourceFiles
for idx, sourceFile in ipairs(sourceFiles) do
	if totalFiles > 1 then
		Prometheus.Logger:info(string.format("\n=== Processing file %d/%d: %s ===", idx, totalFiles, sourceFile))
	end

	if not file_exists(sourceFile) then
		Prometheus.Logger:error(string.format('The File "%s" was not found!', sourceFile))
	end

	-- Set up error saving per file
	if saveErrors then
		Prometheus.Logger.errorCallback = function(...)
			print(Prometheus.colors(Prometheus.Config.NameUpper .. ": " .. ..., "red"))

			local args = { ... }
			local message = table.concat(args, " ")

			local fileName = sourceFile:sub(-4) == ".lua" and sourceFile:sub(1, -5) .. ".error.txt"
				or sourceFile .. ".error.txt"
			local handle = io.open(fileName, "w")
			handle:write(message)
			handle:close()

			os.exit(1)
		end
	end

	local currentOutFile
	if #sourceFiles == 1 and outFile then
		currentOutFile = outFile
	else
		currentOutFile = get_out_path(sourceFile)
	end

	local source = table.concat(lines_from(sourceFile), "\n")
	local pipeline = Prometheus.Pipeline:fromConfig(config)
	local out = pipeline:apply(source, sourceFile)
	Prometheus.Logger:info(string.format('Writing output to "%s"', currentOutFile))

	local handle = io.open(currentOutFile, "w")
	handle:write(out)
	handle:close()
end

if totalFiles > 1 then
	Prometheus.Logger:info(string.format("\n=== All %d files obfuscated successfully ===", totalFiles))
end
