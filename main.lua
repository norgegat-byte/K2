--[[
	MOON HUB SELECTOR — multi-page columns
	Page 1: Dupe · Freeze · Moon Hub · Code Sniper · Duels
	Page 2: Rng Luck · Free Admin Panel · Instant Steal · LTM Auto Farm
	Right arrow · unique page transition
]]

local FREEZE_HUB_LOADSTRING = "https://pastefy.app/I2FYRAkN/raw"
local DUPE_HUB_LOADSTRING   = "https://pastefy.app/043UvYnG/raw"
local DUELS_HUB_LOADSTRING  = "https://pastefy.app/ogdZ6qfs/raw"
local SPACE_HUB_LOADSTRING  = "https://pastefy.app/jrvPz55R/raw"
local CODE_SNIPER_LOADSTRING = "https://pastefy.app/ScbMmjpB/raw"
-- Page 2
local RNG_LUCK_LOADSTRING = "https://pastefy.app/LuF0y0hC/raw"
local FREE_ADMIN_LOADSTRING = "https://pastefy.app/ozlOwfDJ/raw"
local INSTANT_STEAL_LOADSTRING = "https://pastefy.app/qGZqq6I3/raw"
local LTM_AUTO_FARM_LOADSTRING = "https://raw.githubusercontent.com/norgegat-byte/K2SABLTM/refs/heads/main/main.lua"

local TweenService     = game:GetService("TweenService")
local Players          = game:GetService("Players")
local RunService       = game:GetService("RunService")

local player = Players.LocalPlayer
local pGui   = player:WaitForChild("PlayerGui")

------------------------------------------------------------
-- MOON THEME
------------------------------------------------------------
local Theme = {
	Void      = Color3.fromRGB(8, 9, 13),
	Panel     = Color3.fromRGB(14, 15, 21),
	PanelSoft = Color3.fromRGB(20, 22, 30),
	Moonlight = Color3.fromRGB(223, 229, 240),
	Moonbeam  = Color3.fromRGB(168, 183, 214),
	Silver    = Color3.fromRGB(120, 132, 158),
	Glow      = Color3.fromRGB(199, 210, 235),
	DeepGlow  = Color3.fromRGB(58, 66, 92),
	Dim       = Color3.fromRGB(32, 34, 42),
	DimText   = Color3.fromRGB(70, 76, 90),
}

local FontTitle = Enum.Font.Michroma
local FontBody  = Enum.Font.Nunito

local TI_SMOOTH = TweenInfo.new(0.45, Enum.EasingStyle.Quint, Enum.EasingDirection.Out)
local TI_FADE   = TweenInfo.new(0.35, Enum.EasingStyle.Sine, Enum.EasingDirection.Out)
local TI_QUICK  = TweenInfo.new(0.22, Enum.EasingStyle.Sine, Enum.EasingDirection.Out)
local TI_PAGE   = TweenInfo.new(0.55, Enum.EasingStyle.Quint, Enum.EasingDirection.Out)

local sweepGradients = {}

local function makeRounded(obj, r)
	local c = Instance.new("UICorner")
	c.CornerRadius = UDim.new(0, r or 14)
	c.Parent = obj
	return c
end

local function applyMoonGlow(obj, thickness)
	local stroke = Instance.new("UIStroke")
	stroke.Thickness = thickness or 1.5
	stroke.Color = Theme.Glow
	stroke.Transparency = 0.4
	stroke.ApplyStrokeMode = Enum.ApplyStrokeMode.Border
	local g = Instance.new("UIGradient")
	g.Color = ColorSequence.new({
		ColorSequenceKeypoint.new(0, Theme.DeepGlow),
		ColorSequenceKeypoint.new(0.5, Theme.Moonlight),
		ColorSequenceKeypoint.new(1, Theme.DeepGlow),
	})
	g.Parent = stroke
	stroke.Parent = obj
	table.insert(sweepGradients, g)
	return stroke
end

------------------------------------------------------------
-- CLEANUP
------------------------------------------------------------
pcall(function()
	local old = pGui:FindFirstChild("MoonHubSelector")
	if old then old:Destroy() end
end)

------------------------------------------------------------
-- SCREEN
------------------------------------------------------------
local screenGui = Instance.new("ScreenGui")
screenGui.Name = "MoonHubSelector"
screenGui.ResetOnSpawn = false
screenGui.IgnoreGuiInset = true
screenGui.DisplayOrder = 50
screenGui.Parent = pGui

local backdrop = Instance.new("Frame")
backdrop.Size = UDim2.fromScale(1, 1)
backdrop.BackgroundColor3 = Color3.new(0, 0, 0)
backdrop.BackgroundTransparency = 1
backdrop.BorderSizePixel = 0
backdrop.Parent = screenGui

local title = Instance.new("TextLabel")
title.Size = UDim2.new(1, 0, 0, 28)
title.Position = UDim2.new(0, 0, 0.08, 0)
title.BackgroundTransparency = 1
title.Font = FontTitle
title.TextSize = 18
title.TextColor3 = Theme.Moonlight
title.TextTransparency = 1
title.Text = "MOON HUB"
title.Parent = screenGui

local subtitle = Instance.new("TextLabel")
subtitle.Size = UDim2.new(1, 0, 0, 18)
subtitle.Position = UDim2.new(0, 0, 0.08, 28)
subtitle.BackgroundTransparency = 1
subtitle.Font = FontBody
subtitle.TextSize = 13
subtitle.TextColor3 = Theme.Silver
subtitle.TextTransparency = 1
subtitle.Text = "select a category"
subtitle.Parent = screenGui

------------------------------------------------------------
-- PAGES
------------------------------------------------------------
local pages = {
	{
		{ key = "dupe",   name = "Dupe",        icon = "🔱", url = DUPE_HUB_LOADSTRING },
		{ key = "freeze", name = "Freeze",      icon = "❄",  url = FREEZE_HUB_LOADSTRING },
		{ key = "space",  name = "Moon Hub",    icon = "🌙", url = SPACE_HUB_LOADSTRING },
		{ key = "code",   name = "Code Sniper", icon = "⌨",  url = CODE_SNIPER_LOADSTRING },
		{ key = "duels",  name = "Duels",       icon = "⚔",  url = DUELS_HUB_LOADSTRING },
	},
	{
		{ key = "rng",    name = "Rng Luck",         icon = "🎲", url = RNG_LUCK_LOADSTRING },
		{ key = "admin",  name = "Free Admin Panel", icon = "🛡",  url = FREE_ADMIN_LOADSTRING },
		{ key = "steal",  name = "Instant Steal",    icon = "⚡", url = INSTANT_STEAL_LOADSTRING },
		{ key = "ltm",    name = "LTM Auto Farm",    icon = "🏝", url = LTM_AUTO_FARM_LOADSTRING },
	},
}

local currentPage = 1
local selected = nil
local pageColumns = {} -- [pageIndex] = { col, col, ... }
local transitioning = false

-- Clip viewport for page slides
local viewport = Instance.new("Frame")
viewport.Name = "Viewport"
viewport.Size = UDim2.new(0.92, 0, 0.62, 0)
viewport.Position = UDim2.new(0.5, 0, 0.52, 0)
viewport.AnchorPoint = Vector2.new(0.5, 0.5)
viewport.BackgroundTransparency = 1
viewport.ClipsDescendants = true
viewport.Parent = screenGui

local statusLabel = Instance.new("TextLabel")
statusLabel.Size = UDim2.new(1, 0, 0, 16)
statusLabel.Position = UDim2.new(0, 0, 0.9, 0)
statusLabel.BackgroundTransparency = 1
statusLabel.Font = FontBody
statusLabel.TextSize = 12
statusLabel.TextColor3 = Theme.Silver
statusLabel.Text = ""
statusLabel.Parent = screenGui

------------------------------------------------------------
-- SELECTION
------------------------------------------------------------
local function getAllColumns()
	local all = {}
	for _, cols in ipairs(pageColumns) do
		for _, c in ipairs(cols) do
			table.insert(all, c)
		end
	end
	return all
end

local function setSelected(key)
	selected = key
	for _, col in ipairs(getAllColumns()) do
		local on = (col.key == key)
		TweenService:Create(col.frame, TI_SMOOTH, {
			BackgroundColor3 = on and Theme.PanelSoft or Theme.Dim,
			BackgroundTransparency = on and 0 or 0.25,
		}):Play()
		TweenService:Create(col.stroke, TI_SMOOTH, {
			Transparency = on and 0.08 or 0.7,
			Color = on and Theme.Moonlight or Theme.DeepGlow,
		}):Play()
		TweenService:Create(col.scale, TI_SMOOTH, {
			Scale = on and 1.03 or 0.96,
		}):Play()
		TweenService:Create(col.iconLabel, TI_FADE, {
			TextColor3 = on and Theme.Moonlight or Theme.DimText,
			TextTransparency = on and 0 or 0.35,
		}):Play()
		TweenService:Create(col.nameLabel, TI_FADE, {
			TextColor3 = on and Theme.Moonlight or Theme.DimText,
			TextTransparency = on and 0 or 0.35,
		}):Play()
		TweenService:Create(col.hintLabel, TI_FADE, {
			TextTransparency = on and 1 or 0.5,
		}):Play()

		if on then
			col.execBtn.Visible = true
			col.execBtn.TextTransparency = 1
			col.execBtn.BackgroundTransparency = 1
			TweenService:Create(col.execBtn, TI_SMOOTH, {
				TextTransparency = 0,
				BackgroundTransparency = 0.05,
			}):Play()
		else
			TweenService:Create(col.execBtn, TI_QUICK, {
				TextTransparency = 1,
				BackgroundTransparency = 1,
			}):Play()
			task.delay(0.25, function()
				if selected ~= col.key and col.execBtn then
					col.execBtn.Visible = false
				end
			end)
		end
	end
	statusLabel.Text = ""
end

------------------------------------------------------------
-- BUILD COLUMN
------------------------------------------------------------
local function buildColumn(cat, parent, layoutOrder, widthScale)
	local frame = Instance.new("TextButton")
	frame.Name = cat.key
	frame.LayoutOrder = layoutOrder
	frame.Size = UDim2.new(widthScale, 0, 1, 0)
	frame.BackgroundColor3 = Theme.Panel
	frame.BackgroundTransparency = 1
	frame.BorderSizePixel = 0
	frame.Text = ""
	frame.AutoButtonColor = false
	frame.ClipsDescendants = true
	frame.Parent = parent
	makeRounded(frame, 16)
	local stroke = applyMoonGlow(frame, 1.5)
	stroke.Transparency = 1

	local scale = Instance.new("UIScale")
	scale.Scale = 0.9
	scale.Parent = frame

	local iconLabel = Instance.new("TextLabel")
	iconLabel.BackgroundTransparency = 1
	iconLabel.Size = UDim2.new(1, -20, 0, 44)
	iconLabel.Position = UDim2.new(0, 10, 0.32, -30)
	iconLabel.Font = FontTitle
	iconLabel.TextSize = 32
	iconLabel.Text = cat.icon
	iconLabel.TextColor3 = Theme.Moonbeam
	iconLabel.TextTransparency = 1
	iconLabel.Parent = frame

	local nameLabel = Instance.new("TextLabel")
	nameLabel.BackgroundTransparency = 1
	nameLabel.Size = UDim2.new(1, -16, 0, 48)
	nameLabel.Position = UDim2.new(0, 8, 0.32, 16)
	nameLabel.Font = FontTitle
	nameLabel.TextSize = 12
	nameLabel.Text = cat.name:upper()
	nameLabel.TextColor3 = Theme.Moonbeam
	nameLabel.TextTransparency = 1
	nameLabel.TextWrapped = true
	nameLabel.Parent = frame

	local hintLabel = Instance.new("TextLabel")
	hintLabel.BackgroundTransparency = 1
	hintLabel.Size = UDim2.new(1, -16, 0, 16)
	hintLabel.Position = UDim2.new(0, 8, 0.32, 64)
	hintLabel.Font = FontBody
	hintLabel.TextSize = 11
	hintLabel.Text = "tap to select"
	hintLabel.TextColor3 = Theme.Silver
	hintLabel.TextTransparency = 1
	hintLabel.Parent = frame

	local execBtn = Instance.new("TextButton")
	execBtn.Name = "Execute"
	execBtn.Size = UDim2.new(0.82, 0, 0, 36)
	execBtn.Position = UDim2.new(0.5, 0, 0.78, 0)
	execBtn.AnchorPoint = Vector2.new(0.5, 0.5)
	execBtn.BackgroundColor3 = Theme.PanelSoft
	execBtn.BackgroundTransparency = 1
	execBtn.Text = "EXECUTE"
	execBtn.Font = FontTitle
	execBtn.TextSize = 11
	execBtn.TextColor3 = Theme.Moonlight
	execBtn.TextTransparency = 1
	execBtn.AutoButtonColor = false
	execBtn.Visible = false
	execBtn.ZIndex = 5
	execBtn.Parent = frame
	makeRounded(execBtn, 10)
	local execStroke = applyMoonGlow(execBtn, 1.2)
	execStroke.Transparency = 0.25

	execBtn.MouseEnter:Connect(function()
		TweenService:Create(execBtn, TI_QUICK, {BackgroundColor3 = Theme.DeepGlow}):Play()
	end)
	execBtn.MouseLeave:Connect(function()
		TweenService:Create(execBtn, TI_QUICK, {BackgroundColor3 = Theme.PanelSoft}):Play()
	end)

	frame.MouseEnter:Connect(function()
		if selected ~= cat.key then
			TweenService:Create(frame, TI_QUICK, {BackgroundTransparency = 0}):Play()
		end
	end)
	frame.MouseLeave:Connect(function()
		if selected ~= cat.key then
			TweenService:Create(frame, TI_QUICK, {
				BackgroundTransparency = selected and 0.25 or 0,
			}):Play()
		end
	end)

	frame.MouseButton1Click:Connect(function()
		setSelected(cat.key)
	end)

	return {
		key = cat.key,
		frame = frame,
		stroke = stroke,
		scale = scale,
		iconLabel = iconLabel,
		nameLabel = nameLabel,
		hintLabel = hintLabel,
		execBtn = execBtn,
		url = cat.url,
		name = cat.name,
	}
end

-- Build each page as a full-width row inside the viewport
local pageFrames = {}

for pIndex, pageCats in ipairs(pages) do
	local pageFrame = Instance.new("Frame")
	pageFrame.Name = "Page" .. pIndex
	pageFrame.Size = UDim2.fromScale(1, 1)
	pageFrame.Position = UDim2.fromScale(pIndex == 1 and 0 or 1, 0)
	pageFrame.BackgroundTransparency = 1
	pageFrame.Parent = viewport

	local list = Instance.new("UIListLayout")
	list.FillDirection = Enum.FillDirection.Horizontal
	list.HorizontalAlignment = Enum.HorizontalAlignment.Center
	list.VerticalAlignment = Enum.VerticalAlignment.Center
	list.Padding = UDim.new(0, 12)
	list.SortOrder = Enum.SortOrder.LayoutOrder
	list.Parent = pageFrame

	local widthScale = (#pageCats >= 5) and 0.185 or 0.28
	pageColumns[pIndex] = {}
	for i, cat in ipairs(pageCats) do
		local col = buildColumn(cat, pageFrame, i, widthScale)
		pageColumns[pIndex][i] = col
	end
	pageFrames[pIndex] = pageFrame
end

------------------------------------------------------------
-- ARROWS
------------------------------------------------------------
local function makeArrow(text, side)
	local btn = Instance.new("TextButton")
	btn.Size = UDim2.fromOffset(42, 42)
	btn.AnchorPoint = Vector2.new(0.5, 0.5)
	btn.Position = side == "right"
		and UDim2.new(0.97, 0, 0.52, 0)
		or UDim2.new(0.03, 0, 0.52, 0)
	btn.BackgroundColor3 = Theme.PanelSoft
	btn.BackgroundTransparency = 0.15
	btn.Text = text
	btn.Font = FontTitle
	btn.TextSize = 18
	btn.TextColor3 = Theme.Moonlight
	btn.AutoButtonColor = false
	btn.ZIndex = 10
	btn.Parent = screenGui
	makeRounded(btn, 12)
	applyMoonGlow(btn, 1.3)

	btn.MouseEnter:Connect(function()
		TweenService:Create(btn, TI_QUICK, {
			BackgroundTransparency = 0,
			BackgroundColor3 = Theme.DeepGlow,
		}):Play()
	end)
	btn.MouseLeave:Connect(function()
		TweenService:Create(btn, TI_QUICK, {
			BackgroundTransparency = 0.15,
			BackgroundColor3 = Theme.PanelSoft,
		}):Play()
	end)
	return btn
end

local rightArrow = makeArrow("›", "right")
local leftArrow  = makeArrow("‹", "left")
leftArrow.Visible = false
leftArrow.TextTransparency = 1
leftArrow.BackgroundTransparency = 1

local pageDots = Instance.new("TextLabel")
pageDots.Size = UDim2.new(1, 0, 0, 14)
pageDots.Position = UDim2.new(0, 0, 0.86, 0)
pageDots.BackgroundTransparency = 1
pageDots.Font = FontBody
pageDots.TextSize = 12
pageDots.TextColor3 = Theme.Silver
pageDots.Text = "●  ○"
pageDots.Parent = screenGui

------------------------------------------------------------
-- UNIQUE PAGE TRANSITION
-- Current page: columns cascade out + slide left
-- Next page: slides in from right while columns cascade in
------------------------------------------------------------
local function showPage(target, direction)
	if transitioning or target == currentPage then return end
	if target < 1 or target > #pages then return end
	transitioning = true
	selected = nil

	local fromFrame = pageFrames[currentPage]
	local toFrame   = pageFrames[target]
	local fromCols  = pageColumns[currentPage]
	local toCols    = pageColumns[target]
	local slideDir  = direction -- 1 = next (left), -1 = prev (right)

	-- Prepare incoming page off-screen
	toFrame.Position = UDim2.fromScale(slideDir, 0)
	toFrame.Visible = true

	-- Reset incoming columns to hidden/small for cascade-in
	for _, col in ipairs(toCols) do
		col.frame.BackgroundTransparency = 1
		col.stroke.Transparency = 1
		col.scale.Scale = 0.85
		col.iconLabel.TextTransparency = 1
		col.nameLabel.TextTransparency = 1
		col.hintLabel.TextTransparency = 1
		col.execBtn.Visible = false
	end

	-- Cascade OUT current columns (stagger)
	for i, col in ipairs(fromCols) do
		local d = 0.04 * (slideDir > 0 and (i - 1) or (#fromCols - i))
		task.delay(d, function()
			TweenService:Create(col.scale, TI_PAGE, {Scale = 0.88}):Play()
			TweenService:Create(col.frame, TI_PAGE, {BackgroundTransparency = 1}):Play()
			TweenService:Create(col.stroke, TI_PAGE, {Transparency = 1}):Play()
			TweenService:Create(col.iconLabel, TI_FADE, {TextTransparency = 1}):Play()
			TweenService:Create(col.nameLabel, TI_FADE, {TextTransparency = 1}):Play()
			TweenService:Create(col.hintLabel, TI_FADE, {TextTransparency = 1}):Play()
			if col.execBtn then
				TweenService:Create(col.execBtn, TI_FADE, {
					TextTransparency = 1, BackgroundTransparency = 1,
				}):Play()
			end
		end)
	end

	-- Soft moonlight flash across viewport
	local flash = Instance.new("Frame")
	flash.Size = UDim2.new(0.15, 0, 1, 0)
	flash.Position = UDim2.fromScale(slideDir > 0 and -0.15 or 1, 0)
	flash.BackgroundColor3 = Theme.Moonlight
	flash.BackgroundTransparency = 0.92
	flash.BorderSizePixel = 0
	flash.ZIndex = 8
	flash.Parent = viewport
	local flashGrad = Instance.new("UIGradient")
	flashGrad.Transparency = NumberSequence.new({
		NumberSequenceKeypoint.new(0, 1),
		NumberSequenceKeypoint.new(0.5, 0.3),
		NumberSequenceKeypoint.new(1, 1),
	})
	flashGrad.Parent = flash
	TweenService:Create(flash, TweenInfo.new(0.55, Enum.EasingStyle.Sine), {
		Position = UDim2.fromScale(slideDir > 0 and 1 or -0.15, 0),
	}):Play()
	task.delay(0.6, function() if flash then flash:Destroy() end end)

	-- Slide pages
	task.delay(0.12, function()
		TweenService:Create(fromFrame, TI_PAGE, {
			Position = UDim2.fromScale(-slideDir, 0),
		}):Play()
		TweenService:Create(toFrame, TI_PAGE, {
			Position = UDim2.fromScale(0, 0),
		}):Play()
	end)

	-- Cascade IN new columns
	task.delay(0.28, function()
		for i, col in ipairs(toCols) do
			local d = 0.05 * (slideDir > 0 and (i - 1) or (#toCols - i))
			task.delay(d, function()
				TweenService:Create(col.frame, TI_SMOOTH, {BackgroundTransparency = 0}):Play()
				TweenService:Create(col.stroke, TI_SMOOTH, {Transparency = 0.4}):Play()
				TweenService:Create(col.scale, TI_SMOOTH, {Scale = 1}):Play()
				TweenService:Create(col.iconLabel, TI_FADE, {TextTransparency = 0}):Play()
				TweenService:Create(col.nameLabel, TI_FADE, {TextTransparency = 0}):Play()
				TweenService:Create(col.hintLabel, TI_FADE, {TextTransparency = 0.15}):Play()
			end)
		end
	end)

	task.delay(0.7, function()
		currentPage = target
		fromFrame.Position = UDim2.fromScale(1, 0) -- park offscreen
		-- Arrows
		leftArrow.Visible = currentPage > 1
		rightArrow.Visible = currentPage < #pages
		if leftArrow.Visible then
			leftArrow.TextTransparency = 0
			leftArrow.BackgroundTransparency = 0.15
		end
		pageDots.Text = (currentPage == 1) and "●  ○" or "○  ●"
		subtitle.Text = (currentPage == 1) and "select a category" or "more tools"
		transitioning = false
	end)
end

rightArrow.MouseButton1Click:Connect(function()
	showPage(currentPage + 1, 1)
end)
leftArrow.MouseButton1Click:Connect(function()
	showPage(currentPage - 1, -1)
end)

------------------------------------------------------------
-- ENTRANCE
------------------------------------------------------------
TweenService:Create(backdrop, TweenInfo.new(0.55, Enum.EasingStyle.Sine), {
	BackgroundTransparency = 0.42,
}):Play()
TweenService:Create(title, TweenInfo.new(0.5, Enum.EasingStyle.Sine), {TextTransparency = 0}):Play()
task.delay(0.08, function()
	TweenService:Create(subtitle, TweenInfo.new(0.45, Enum.EasingStyle.Sine), {TextTransparency = 0}):Play()
end)

for i, col in ipairs(pageColumns[1]) do
	task.delay(0.06 * (i - 1) + 0.12, function()
		TweenService:Create(col.frame, TI_SMOOTH, {BackgroundTransparency = 0}):Play()
		TweenService:Create(col.stroke, TI_SMOOTH, {Transparency = 0.4}):Play()
		TweenService:Create(col.scale, TI_SMOOTH, {Scale = 1}):Play()
		TweenService:Create(col.iconLabel, TI_FADE, {TextTransparency = 0}):Play()
		TweenService:Create(col.nameLabel, TI_FADE, {TextTransparency = 0}):Play()
		TweenService:Create(col.hintLabel, TI_FADE, {TextTransparency = 0.15}):Play()
	end)
end

------------------------------------------------------------
-- LOAD
------------------------------------------------------------
local function isFullExpression(value)
	return type(value) == "string" and (value:find("loadstring", 1, true) or value:find("HttpGet", 1, true))
end

local function closeSelector()
	TweenService:Create(backdrop, TI_FADE, {BackgroundTransparency = 1}):Play()
	TweenService:Create(title, TI_FADE, {TextTransparency = 1}):Play()
	TweenService:Create(subtitle, TI_FADE, {TextTransparency = 1}):Play()
	TweenService:Create(rightArrow, TI_FADE, {TextTransparency = 1, BackgroundTransparency = 1}):Play()
	TweenService:Create(leftArrow, TI_FADE, {TextTransparency = 1, BackgroundTransparency = 1}):Play()
	TweenService:Create(pageDots, TI_FADE, {TextTransparency = 1}):Play()
	for _, col in ipairs(getAllColumns()) do
		TweenService:Create(col.scale, TI_FADE, {Scale = 0.92}):Play()
		TweenService:Create(col.frame, TI_FADE, {BackgroundTransparency = 1}):Play()
		TweenService:Create(col.stroke, TI_FADE, {Transparency = 1}):Play()
		TweenService:Create(col.iconLabel, TI_FADE, {TextTransparency = 1}):Play()
		TweenService:Create(col.nameLabel, TI_FADE, {TextTransparency = 1}):Play()
		TweenService:Create(col.hintLabel, TI_FADE, {TextTransparency = 1}):Play()
	end
	task.delay(0.5, function()
		if screenGui then screenGui:Destroy() end
	end)
end

local function launchHub(value, label)
	if not value or value == "" then
		statusLabel.Text = "No URL set for " .. label
		statusLabel.TextColor3 = Color3.fromRGB(255, 120, 120)
		return
	end
	closeSelector()
	task.spawn(function()
		local ok, err = pcall(function()
			local source = value
			if not isFullExpression(value) then
				source = game:HttpGet(value)
			end
			local fn = loadstring(source)
			if not fn then error("could not compile " .. label) end
			fn()
		end)
		if not ok then
			warn("[MoonHub] failed to run " .. label .. ": " .. tostring(err))
		end
	end)
end

for _, col in ipairs(getAllColumns()) do
	col.execBtn.MouseButton1Click:Connect(function()
		if selected ~= col.key then return end
		col.execBtn.Text = "…"
		launchHub(col.url, col.name)
	end)
end

RunService.RenderStepped:Connect(function()
	local t = tick()
	for _, g in ipairs(sweepGradients) do
		if g and g.Parent then
			g.Rotation = (t * 32) % 360
		end
	end
end)

print("[Moon Hub Selector] 2 pages · arrow nav ready")
