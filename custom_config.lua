return {
	LuaVersion = "LuaU",
	VarNamePrefix = "",
	NameGenerator = "MangledShuffled",
	PrettyPrint = false,
	Seed = 1124151591,
	Steps = {
		{ Name = "EncryptStrings", Settings = {} },
		{
			Name = "SplitStrings",
			Settings = {
				Threshold = 1,
				MinLength = 3,
				MaxLength = 6,
				ConcatenationType = "custom",
				CustomFunctionType = "global",
			},
		},
		{ Name = "AddVararg", Settings = {} },
		{ Name = "Vmify", Settings = {} },
		{
			Name = "ConstantArray",
			Settings = {
				Threshold = 1,
				StringsOnly = true,
				Shuffle = true,
				Rotate = true,
				LocalWrapperThreshold = 0,
				Encoding = "mixed",
			},
		},
		{ Name = "WrapInFunction", Settings = {} },
		{
			Name = "Watermark",
			Settings = {
				Content = "Paradise OBF",
				CustomVariable = "_WATERMARK",
			},
		},
	},
}
