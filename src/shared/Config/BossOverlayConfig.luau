--!strict

-- Signature-move overlays on the chop bar (ice, croc jaws, stone slabs).
-- Pieces are ImageLabels authored in StarterGui.ChopBar.Bar.Overlays.Templates.
return table.freeze({
	FolderName = "Overlays",
	TemplatesName = "Templates",
	AspectAttribute = "Aspect",

	-- Frost: one ice chunk per frozen patch, wider than the patch so it laps over the bar's outline.
	IceChunks = table.freeze({ "IceChunk1", "IceChunk2" }),
	IceShards = table.freeze({
		"IceShard1",
		"IceShard2",
		"IceShard3",
		"IceShard4",
		"IceShard5",
		"IceShard6",
		"IceShard7",
		"IceShard8",
	}),
	IceWidthScale = 1.2,
	IceTopPixels = -12,
	IceDropScale = 1.2,
	IceDropSeconds = 0.08,
	IceBreakSeconds = 0.12,
	IceShardCount = 5,
	IceShardPixels = 46,

	-- Chomp: jaws over the bar's top and bottom; teeth bite BitePixels into the track.
	BitePixels = 20,
	JawTipPadPixels = 6,
	JawStartPixels = 90,
	JawInSeconds = 0.1,
	JawLandFraction = 0.6,
	JawOutSeconds = 0.25,
	ChompPixels = 14,
	ChompCloseSeconds = 0.06,
	ChompOpenSeconds = 0.12,
	BiteMarkName = "BiteMark",
	BiteMarkHeightScale = 1.25,
	BiteMarkSeconds = 0.5,
	ZoneFlashTransparency = 0.25,
	ZoneFlashSeconds = 0.3,
	ChompBurstName = "ChompBurst",
	ChompBurstPixels = 120,
	ChompBurstSeconds = 0.3,

	-- Shell: slabs cover everything outside the Great window.
	StoneSlabs = table.freeze({ "StoneSlab1", "StoneSlab2", "StoneSlab3" }),
	StoneRubble = table.freeze({
		"StoneRubble1",
		"StoneRubble2",
		"StoneRubble3",
		"StoneRubble4",
		"StoneRubble5",
		"StoneRubble6",
		"StoneRubble7",
		"StoneRubble8",
	}),
	SlabHeightScale = 1.22,
	SlabOverlapPixels = 6,
	SlabMinPixels = 36,
	SlabDropPixels = 40,
	SlabDropSeconds = 0.08,
	SlabStaggerSeconds = 0.012,
	SlabSinkSeconds = 0.12,
	RubblePerSlab = 2,
	RubblePixels = 40,

	-- Debris (shards and rubble) physics, in bar pixels.
	DebrisSpeed = Vector2.new(260, 360),
	DebrisGravity = 1400,
	DebrisSpin = 540,
	DebrisSeconds = 0.6,

	LandShakeSeconds = 0.15,
})
