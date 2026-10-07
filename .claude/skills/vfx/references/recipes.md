# VFX recipes

Layer skeletons with starting values (from Roqer's VFX craft reference by S4US, measured on published effects), and the Luau to build them in Studio. R is the effect's radius in studs. Fill each role with a texture drawn for the effect; add or drop roles as the idea needs.

## Impact or burst

| Time | Role | Make |
| --- | --- | --- |
| -0.15 s | Anticipation (reward beats only) | Glow shrinking from 1.5R to 0 over 0.1 to 0.15 s, `RotSpeed` -700 to -500 |
| 0 | Flash | Spiky star or soft ball, size 0 to 2.5R, Lifetime 0.06 to 0.1, Brightness 10+, `ZOffset` in front |
| +0.03 s | Impact stars | Spiky 4x4 sheet, Lifetime 0.075 to 0.15, `EmitCount` 2 to 6: colour (z), black twin (z to z + 0.25), white copy (z + 1) |
| +0.03 s | Backing | Soft black blob behind, 2 to 4R |
| +0.05 s | Streaks | `VelocityParallel`, `Squash` 3 to 1, Speed 60 to 200, Drag 8 to 12 |
| +0.05 s | Ring | Flat `VelocityPerpendicular` ring (Speed 0.001) growing to 2 to 3R over 0.2 to 0.4 s |
| +0.05 s | Chips / debris | Rock-coloured shards, Speed 30 to 60, `Acceleration` (0, -20, 0), size pop |
| +0.05 s | Dust | 4x4 OneShot puffs, Speed 50 to 120, Drag 8, Lifetime 1 to 1.5, `TimeScale` 0.7, Transparency to above 1 |
| +0.05 s | Sparkles | Dots at `LightEmission` 1, Speed 10 to 120, Drag 10, Lifetime 0.75 to 2 |
| 0 | Light | PointLight Brightness 7 to 16, Range 7 to 15, `EmitDuration` 0.5 |

A frequent chop hit uses the flash, a few stars, chips and a little dust. A perfect or master break adds anticipation, the ring, streaks, sparkles, a light and a mesh shockwave.

## Mesh shockwave

A Model with `Duration` 0.3 to 0.5, `Easing` "Cubic", `EasingDirection` "Out", `EmitDelay`, optional `Spin` 120 to 170, holding `Start` and `End` parts. A thin Neon ring (or flat Neon cylinder) goes from small and Transparency 0 to 2 to 7 times wider, flatter (height x0.1 to 0.3) and Transparency 1. Set `RenderFidelity` Precise and `DoubleSided` on imported shape meshes, and keep `Color` white under vertex colours.

## Wind and residue

- Wind: 3 to 6 faint grey crescents or rings, flat, growing to 25 to 35 studs by 60% of life, Transparency 0.45 to 0.85 rising past 1, `LightEmission` 1, `RotSpeed` 15 to 20.
- Ground skirt: a squashed flat copy of the dust.

## Building in Studio

Run with `execute_luau` (Edit, Play stopped). `make` sets properties from plain values (numbers or `{min, max}` ranges, colours as `{r, g, b}` 0 to 1 or keypoint lists, sequences as `{{time, value}, ...}`) so a layer list reads like the tables above.

```lua
local folder = game.ReplicatedStorage.Assets.VFX
local name = "VFX_Example"
if folder:FindFirstChild(name) then folder[name]:Destroy() end

local model = Instance.new("Model")
model.Name = name
local root = Instance.new("Part")
root.Name = "Root"
root.Size = Vector3.new(1, 1, 1)
root.Transparency = 1
root.Anchored = true
root.CanCollide = false
root.CanQuery = false
root.CanTouch = false
root.CastShadow = false
root.Parent = model
model.PrimaryPart = root
local center = Instance.new("Attachment")
center.Name = "Center"
center.Parent = root

local function number(v)
	if typeof(v) == "table" and typeof(v[1]) == "table" then
		local keys = {}
		for _, k in v do table.insert(keys, NumberSequenceKeypoint.new(k[1], k[2], k[3] or 0)) end
		return NumberSequence.new(keys)
	end
	return v
end
local function convert(prop, v)
	if typeof(v) ~= "table" and prop ~= "Size" and prop ~= "Transparency" and prop ~= "Squash"
		and prop ~= "Lifetime" and prop ~= "Speed" and prop ~= "Rotation" and prop ~= "RotSpeed" then
		if typeof(v) == "string" and prop == "Orientation" then return Enum.ParticleOrientation[v] end
		if typeof(v) == "string" and prop == "EmissionDirection" then return Enum.NormalId[v] end
		if typeof(v) == "string" and prop == "FlipbookLayout" then return Enum.ParticleFlipbookLayout[v] end
		if typeof(v) == "string" and prop == "FlipbookMode" then return Enum.ParticleFlipbookMode[v] end
		return v
	end
	if prop == "Color" then
		if typeof(v[1]) == "table" then
			local keys = {}
			for _, k in v do table.insert(keys, ColorSequenceKeypoint.new(k[1], Color3.new(k[2], k[3], k[4]))) end
			return ColorSequence.new(keys)
		end
		return ColorSequence.new(Color3.new(v[1], v[2], v[3]))
	elseif prop == "Size" or prop == "Transparency" or prop == "Squash" then
		return if typeof(v) == "number" then NumberSequence.new(v) else number(v)
	elseif prop == "Lifetime" or prop == "Speed" or prop == "Rotation" or prop == "RotSpeed" then
		return if typeof(v) == "number" then NumberRange.new(v) else NumberRange.new(v[1], v[2])
	elseif prop == "SpreadAngle" then
		return Vector2.new(v[1], v[2])
	elseif prop == "Acceleration" then
		return Vector3.new(v[1], v[2], v[3])
	elseif prop == "Orientation" then
		return Enum.ParticleOrientation[v]
	elseif prop == "EmissionDirection" then
		return Enum.NormalId[v]
	elseif prop == "FlipbookLayout" then
		return Enum.ParticleFlipbookLayout[v]
	elseif prop == "FlipbookMode" then
		return Enum.ParticleFlipbookMode[v]
	end
	return v
end
local function make(parent, className, layerName, props, attributes)
	local item = Instance.new(className)
	item.Name = layerName
	if className == "ParticleEmitter" then
		item.Enabled = false
		item.Rate = 0
		item.LightInfluence = 0
	end
	for prop, v in props do item[prop] = convert(prop, v) end
	for key, v in attributes or {} do item:SetAttribute(key, v) end
	item.Parent = parent
	return item
end

make(center, "ParticleEmitter", "Flash", {
	Texture = "rbxasset://textures/particles/sparkles_main.dds",
	Lifetime = { 0.06, 0.1 }, Speed = 0.001, LockedToPart = true,
	LightEmission = 1, Brightness = 10, ZOffset = 3, Rotation = { 0, 360 },
	Color = { 1, 0.95, 0.85 },
	Size = { { 0, 4 }, { 0.3, 16 }, { 1, 18 } },
	Transparency = { { 0, 0 }, { 1, 1 } },
}, { EmitCount = 1 })

make(center, "ParticleEmitter", "Chips", {
	Lifetime = { 0.5, 0.9 }, Speed = { 30, 60 }, SpreadAngle = { 60, 60 }, Drag = 2,
	Acceleration = { 0, -20, 0 }, Rotation = { 0, 360 }, RotSpeed = { -200, 200 },
	Color = { 0.55, 0.55, 0.6 }, Size = { { 0, 0 }, { 0.1, 0.8 }, { 1, 0 } },
}, { EmitCount = 8, EmitDelay = 0.05 })

make(center, "PointLight", "Light", { Brightness = 10, Range = 12, Color = Color3.new(1, 0.8, 0.5), Shadows = false },
	{ EmitDuration = 0.5 })

model.Parent = folder
```

After building, add `VFX_<Name> = { Category = "VFX", InstanceName = "VFX_<Name>" }` to `src/shared/AssetRegistry.luau` and run `./scripts/check.ps1`.

## Built-in stand-in textures

Fine while blocking out; replace with drawn textures before calling an effect done.

| Texture | Looks like |
| --- | --- |
| `rbxasset://textures/particles/explosion01_implosion_main.dds` | Soft white glow |
| `rbxasset://textures/particles/explosion01_shockwave_main.dds` | Soft ring |
| `rbxasset://textures/particles/explosion01_core_main.dds` | Orange fiery puff |
| `rbxasset://textures/particles/smoke_main.dds` | Grey cloudy puff |
| `rbxasset://textures/particles/sparkles_main.dds` | Four-point star |
| `rbxasset://textures/particles/fire_main.dds` | Wispy flames |

## Engine notes

- `Drag` is the half-life of speed in seconds.
- `Shape` (Box, Sphere, Cylinder, Disc) only applies when the emitter sits directly under a sized part; under an Attachment it emits from a point. `ShapeInOut` Inward gathers particles for anticipation.
- `ZOffset` moves a layer toward the camera without resizing it: about ±1 for a small effect, 0 to 3 for an impact.
- `LockedToPart` for auras and held effects; off for anything thrown.
- Particles can't be seen inside a ViewportFrame (vault [[ViewportFrame Gotchas]]); hatch-scene effects must live in the world.
