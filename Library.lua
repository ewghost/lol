--// Services
local UserInputService = game:GetService("UserInputService");
local WorkspaceService = game:GetService("Workspace");
local HttpService = game:GetService("HttpService");
local GuiService = game:GetService("GuiService");
local RunService = game:GetService("RunService");
local CoreGui = game:GetService("CoreGui");
local TweenService = game:GetService("TweenService");
local TextService = game:GetService("TextService");
local PlayersService = game:GetService("Players");
local LocalPlayer = PlayersService.LocalPlayer;

local camera = WorkspaceService.CurrentCamera;
local GuiInset = GuiService:GetGuiInset().Y;

--// Aliases
local NewVector2 = Vector2.new;
local NewUdim2 = UDim2.new;
local NewUdim = UDim.new;
local NewColorSequence = ColorSequence.new;
local NewColorSequenceKeypoint = ColorSequenceKeypoint.new;
local NewNumberSequence = NumberSequence.new;
local NewNumberSequenceKeypoint = NumberSequenceKeypoint.new;
local FromOffset = UDim2.fromOffset;
local FromRgb = Color3.fromRGB;
local hex = Color3.fromHex;
local FromHsv = Color3.fromHSV;
local InstanceNew = Instance.new;
local FontNew = Font.new;
local NewTweenInfo = TweenInfo.new;
local RectNew = Rect.new;

local MathMax = math.max;
local MathFloor = math.floor;
local MathCeil = math.ceil;
local MathMin = math.min;
local MathAbs = math.abs;
local MathClamp = math.clamp;
local insert = table.insert;
local concat = table.concat;

local HttpGet = function(url) return game:HttpGet(url) end;
local JsonEncode = function(value) return HttpService:JSONEncode(value) end;
local JsonDecode = function(value) return HttpService:JSONDecode(value) end;
local SourceSans = FontNew("rbxasset://fonts/families/SourceSansPro.json", Enum.FontWeight.Regular, Enum.FontStyle.Normal);

--// Library
local Library = {
	Flags = {};
	Toggles = {};
	Options = {};
	Connections = {};
	Directory = "LandryHaxx";
	Folders = { "/Fonts", "/Configs", "/Logs" };
	CurrentWindow = nil;
	AnimationSpeed = 1;
	LogFile = "LandryHaxx/Logs/Session.log";
	AccentTargets = {};
};


--// Palette
local Palette = {
	Default = {
		Background = hex("0E0E10");
		Surface = hex("141416");
		Header = hex("18181B");
		Border = hex("232327");
		Accent = hex("9AE600");
		Text = FromRgb(255, 255, 255);
		Muted = hex("8A8A92");
	};
};
Library.Palette = Palette;

--// Folders
for _, FolderPath in Library.Folders do
	makefolder(Library.Directory .. FolderPath);
end;

--// Logging
if isfile(Library.LogFile) then
	delfile(Library.LogFile);
end;

writefile(Library.LogFile, Library.Directory .. " has started\n");

local LogStart = tick();

function Library:Log(text)
	local stamp = string.format("%.3f", tick() - LogStart);
	appendfile(self.LogFile, "[" .. stamp .. "s] " .. tostring(text) .. "\n");
end;

--// Console sinks (output routing for the lua executor)
Library.ConsoleSinks = {};
function Library:ConsolePush(text, kind)
	kind = kind or "output";
	for _, sink in self.ConsoleSinks do
		if typeof(sink.Push) == "function" then
			pcall(sink.Push, sink, tostring(text), kind);
		end;
	end;
end;
function Library:AddConsoleSink(sink)
	if typeof(sink) ~= "table" then return end;
	insert(self.ConsoleSinks, sink);
	return sink;
end;
function Library:RemoveConsoleSink(sink)
	for i, s in self.ConsoleSinks do
		if s == sink then
			table.remove(self.ConsoleSinks, i);
			break;
		end;
	end;
end;

--// Key names
Library.KeyNames = {
	[Enum.UserInputType.MouseButton1] = "MB1";
	[Enum.UserInputType.MouseButton2] = "MB2";
	[Enum.UserInputType.MouseButton3] = "MB3";

	[Enum.KeyCode.LeftShift] = "LS";
	[Enum.KeyCode.RightShift] = "RS";
	[Enum.KeyCode.LeftControl] = "LC";
	[Enum.KeyCode.RightControl] = "RC";
	[Enum.KeyCode.LeftAlt] = "LA";
	[Enum.KeyCode.RightAlt] = "RA";
	[Enum.KeyCode.CapsLock] = "CAPS";
	[Enum.KeyCode.Insert] = "INS";
	[Enum.KeyCode.Backspace] = "BS";
	[Enum.KeyCode.Return] = "Ent";
	[Enum.KeyCode.Escape] = "ESC";
	[Enum.KeyCode.Space] = "SPC";
};

function Library:OnAccentChange(cb)
	if typeof(cb) ~= "function" then return end;
	self.AccentTargets[#self.AccentTargets + 1] = cb;
end;

function Library:NotifyAccentChange()
	for _, cb in self.AccentTargets do cb() end;
end;

function Library:RegisterFont(name, url, weight, style)
	local folder = self.Directory .. "/Fonts";
	local TtfPath = folder .. "/" .. name .. ".ttf";
	local DescPath = folder .. "/" .. name .. ".font";
	if not isfile(TtfPath) then
		local Ok, Data = pcall(HttpGet, url);
		if not Ok or not Data or #Data == 0 then
			return nil;
		end;
		writefile(TtfPath, Data);
	end;
	if isfile(DescPath) then
		delfile(DescPath);
	end;
	writefile(DescPath, JsonEncode({
		name = name;
		faces = {
			{ name = "Regular", weight = weight or 400, style = style or "normal", assetId = getcustomasset(TtfPath) };
		};
	}));
	return getcustomasset(DescPath);
end;

local SmallestPixelAsset = Library:RegisterFont("SmallestPixel7", "https://yvyx.cc/fonts/smallest_pixel-7.ttf", 400, "normal");

Library.Fonts = {
	title = SmallestPixelAsset and FontNew(SmallestPixelAsset, Enum.FontWeight.Regular, Enum.FontStyle.Normal) or SourceSans;
};

do
	local Sources = {
		{ "ProggyTiny", "https://github.com/mainstreamed/clones/raw/refs/heads/main/vanity/ProggyTiny.ttf" };
		{ "SmallestPixel7", "https://yvyx.cc/fonts/smallest_pixel-7.ttf" };
		{ "Minecraftia", "https://github.com/mainstreamed/clones/raw/refs/heads/main/vanity/Minecraftia-Regular.ttf" };
	};
	Library.UIFonts = {};
	Library.UIFontNames = {};
	for _, Entry in ipairs(Sources) do
		local Name, Url = Entry[1], Entry[2];
		local Asset = (Name == "SmallestPixel7" and SmallestPixelAsset) or Library:RegisterFont(Name, Url, 400, "normal");
		if Asset then
			Library.UIFonts[Name] = FontNew(Asset, Enum.FontWeight.Regular, Enum.FontStyle.Normal);
			insert(Library.UIFontNames, Name);
		end;
	end;
	if not Library.UIFonts["SmallestPixel7"] then
		Library.UIFonts["SmallestPixel7"] = Library.Fonts.title;
		insert(Library.UIFontNames, "SmallestPixel7");
	end;
end;

Library.ESPFont = Library.Fonts.title;
Library.ESPFontSize = 9;

function Library:MenuGuis()
	local guis = {};
	local function add(g)
		if typeof(g) == "Instance" and g:IsA("LayerCollector") then insert(guis, g); end;
	end;
	add(self.ScreenGui);
	add(self.MenuDimGui);
	for _, holder in ipairs({
		self.CurrentWindow, self.CurrentDock, self.CurrentEspPreview, self.CurrentConfigs,
		self.CurrentPlayerList, self.CurrentKeybindList, self.CurrentWatermark,
		self.CurrentAppearance, self.CurrentLuaEditor, self.CurrentActivity, self.CurrentMapPanel, self.CurrentArrayList, self.CurrentNotif,
	}) do
		if typeof(holder) == "table" then add(holder.Gui) end;
	end;
	for _, name in ipairs({ "ArrayListGui", "NotifGui", "NotifAnchor", "TooltipGui" }) do
		add(self[name]);
	end;
	return guis;
end;

function Library:ApplyMenuFont(font)
	if not font then return end;
	self.Fonts.title = font;
	for _, gui in ipairs(self:MenuGuis()) do
		for _, obj in ipairs(gui:GetDescendants()) do
			if (obj:IsA("TextLabel") or obj:IsA("TextButton") or obj:IsA("TextBox")) and not obj:GetAttribute("NoFontScale") then
				obj.FontFace = font;
			end;
		end;
	end;
end;

function Library:SetMenuFontSize(scale)
	scale = tonumber(scale) or 1;
	self.UIFontScale = scale;
	for _, gui in ipairs(self:MenuGuis()) do
		for _, obj in ipairs(gui:GetDescendants()) do
			if (obj:IsA("TextLabel") or obj:IsA("TextButton") or obj:IsA("TextBox")) and not obj:GetAttribute("NoFontScale") then
				local base = obj:GetAttribute("BaseTextSize");
				if not base then base = obj.TextSize; obj:SetAttribute("BaseTextSize", base); end;
				obj.TextSize = MathMax(1, MathFloor(base * scale + 0.5));
			end;
		end;
	end;
end;

if getgenv().Library then getgenv().Library:Unload() end;
getgenv().Library = Library;

--// Util
function Library:Connection(signal, callback)
	local conn = signal:Connect(callback);
	insert(self.Connections, conn);
	return conn;
end;

local function color_close(a, b)
	return MathAbs(a.R - b.R) < 0.004 and MathAbs(a.G - b.G) < 0.004 and MathAbs(a.B - b.B) < 0.004;
end;

local THEME_DEFAULTS = {
	{ default = hex("98BCFF"); field = "AccentColor" };
	{ default = hex("6E8CC8"); field = "ShadeColor" };
	{ default = hex("94B7F8"); field = "AccentGradColor" };
	{ default = hex("6B84B3"); field = "ShadeGradColor" };
	{ default = hex("101114"); field = "WindowBgColor" };
	{ default = hex("07080A"); field = "WindowOuterColor" };
	{ default = hex("24262D"); field = "WindowInnerColor" };
	{ default = hex("1C1D23"); field = "BgControlColor" };
	{ default = hex("131418"); field = "BgGradTopColor" };
	{ default = hex("17181D"); field = "BgGradBotColor" };
};

function Library:RemapColor(c)
	if typeof(c) ~= "Color3" then return c end;
	for _, entry in THEME_DEFAULTS do
		if color_close(c, entry.default) then
			local cur = self[entry.field];
			if cur and not color_close(cur, entry.default) then return cur end;
			return c;
		end;
	end;
	return c;
end;

function Library:RemapColorSequence(seq)
	if typeof(seq) ~= "ColorSequence" then return seq end;
	local kps = seq.Keypoints;
	local new_kps = {};
	local changed = false;
	for i, k in kps do
		local remapped = self:RemapColor(k.Value);
		if remapped ~= k.Value then
			new_kps[i] = NewColorSequenceKeypoint(k.Time, remapped);
			changed = true;
		else
			new_kps[i] = k;
		end;
	end;
	if changed then return NewColorSequence(new_kps) end;
	return seq;
end;

function Library:CreateInstance(ClassName, properties)
	local inst = InstanceNew(ClassName);
	local noScale = false;
	if properties then
		if properties.NoFontScale ~= nil then noScale = properties.NoFontScale; properties.NoFontScale = nil; end;
		for k, v in properties do
			if typeof(v) == "Color3" then
				v = self:RemapColor(v);
			elseif typeof(v) == "ColorSequence" then
				v = self:RemapColorSequence(v);
			end;
			inst[k] = v;
		end;
	end;
	if ClassName == "TextLabel" or ClassName == "TextButton" or ClassName == "TextBox" then
		if noScale then
			inst:SetAttribute("NoFontScale", true);
		else
			local scale = self.UIFontScale or 1;
			if scale ~= 1 then
				if inst:GetAttribute("BaseTextSize") == nil then
					inst:SetAttribute("BaseTextSize", inst.TextSize);
				end;
				inst.TextSize = MathMax(1, MathFloor(inst.TextSize * scale + 0.5));
			end;
		end;
	end;
	return inst;
end;

function Library:Tween(inst, info, props)
	return TweenService:Create(inst, info, props);
end;

Library.SliderTickers = Library.SliderTickers or {};

function Library:RegisterSliderTicker(ticker)
	insert(self.SliderTickers, ticker);
	if not self.SliderHeartbeat then
		self.SliderHeartbeat = RunService.Heartbeat:Connect(function(dt)
			local list = self.SliderTickers;
			for i = #list, 1, -1 do
				local t = list[i];
				if t.Alive() then
					t.Tick(dt);
				else
					list[i] = list[#list];
					list[#list] = nil;
				end;
			end;
			if #list == 0 and self.SliderHeartbeat then
				self.SliderHeartbeat:Disconnect();
				self.SliderHeartbeat = nil;
			end;
		end);
		insert(self.Connections, self.SliderHeartbeat);
	end;
end;

Library.UIScales = Library.UIScales or {};
Library.BaseResolution = Library.BaseResolution or Vector2.new(1920, 1080);
Library.MinUIScale = 0.8;
Library.MaxUIScale = 1.0;
Library.WidgetDisplayOrder = 1002;

function Library:ComputeUIScale()
	local vp = camera.ViewportSize;
	local base = self.BaseResolution;
	local s = MathMin(vp.X / base.X, vp.Y / base.Y);
	s = MathClamp(s, self.MinUIScale, self.MaxUIScale);
	return MathMax(1, MathFloor(s + 0.5));
end;

function Library:UpdateUIScales()
	local s = self:ComputeUIScale();
	for i = #self.UIScales, 1, -1 do
		local sc = self.UIScales[i];
		if sc and sc.Parent then
			sc.Scale = s;
		else
			table.remove(self.UIScales, i);
		end;
	end;
end;

function Library:ApplyScale(gui)
	if not gui or not gui:IsA("ScreenGui") then return end;
	local sc = self:CreateInstance("UIScale", {
		Parent = gui;
		Scale = self:ComputeUIScale();
	});
	insert(self.UIScales, sc);
	return sc;
end;

function Library:ScaledPoint(x, y)
	local scale = self:ComputeUIScale();
	return (tonumber(x) or 0) / scale, (tonumber(y) or 0) / scale, scale;
end;

function Library:GuiPoint(gui, x, y)
	local scale = 1;
	if gui then
		local sc = gui:FindFirstChildOfClass("UIScale");
		if sc then
			scale = sc.Scale;
		end;
	end;
	return (tonumber(x) or 0) / scale, (tonumber(y) or 0) / scale, scale;
end;

function Library:MousePoint(gui, input)
	local x, y;
	if input then
		local pos = input.Position;
		x, y = pos.X, pos.Y;
	else
		local m = UserInputService:GetMouseLocation();
		x, y = m.X, m.Y;
	end;
	return x, y;
end;

function Library:PointInObject(Object, X, Y, Padding)
	if not Object or not Object.Parent then
		return false;
	end;
	Padding = tonumber(Padding) or 0;
	local Position = Object.AbsolutePosition;
	local Size = Object.AbsoluteSize;
	return X >= Position.X - Padding
		and X <= Position.X + Size.X + Padding
		and Y >= Position.Y - Padding
		and Y <= Position.Y + Size.Y + Padding;
end;

if not Library.UIScaleConn then
	Library.UIScaleConn = camera:GetPropertyChangedSignal("ViewportSize"):Connect(function()
		Library:UpdateUIScales();
	end);
end;

Library.KeybindRegistry = Library.KeybindRegistry or {};
Library.KeybindIdCounter = Library.KeybindIdCounter or 0;
Library.FlagMeta = Library.FlagMeta or {};

function Library:RegisterKeybind(entry)
	self.KeybindIdCounter = self.KeybindIdCounter + 1;
	entry.Id = "kb_" .. tostring(self.KeybindIdCounter);
	insert(self.KeybindRegistry, entry);
	if typeof(self.CurrentKeybindList) == "table" and self.CurrentKeybindList.Register then
		local active = entry.Active;
		if active == nil then active = true end;
		self.CurrentKeybindList:Register(entry.Id, entry.Name, entry.Key, active == true, entry.Mode, entry.ShowInList ~= false);
	end;
end;

function Library:UpdateKeybind(entry)
	if typeof(self.CurrentKeybindList) == "table" and self.CurrentKeybindList.Update then
		local active = entry.Active;
		if active == nil then active = true end;
		self.CurrentKeybindList:Update(entry.Id, entry.Name, entry.Key == nil and false or entry.Key, active == true, entry.Mode, entry.ShowInList ~= false);
	end;
end;

Library.ModeOptions = { "Toggle", "Hold", "Always" };

function Library:ModePopup(anchor, current, apply, showInList)
	if not anchor or not anchor.Parent then return end;
	if self.ModePopupCloseConn then self.ModePopupCloseConn:Disconnect(); self.ModePopupCloseConn = nil end;
	if typeof(self.ModePopupGui) == "Instance" and self.ModePopupGui.Parent then self.ModePopupGui:Destroy() end;

	local gui = self:CreateInstance("ScreenGui", {
		Name = "\0";
		Parent = (gethui and gethui()) or CoreGui;
		DisplayOrder = 1500;
		IgnoreGuiInset = true;
		ResetOnSpawn = false;
		ZIndexBehavior = Enum.ZIndexBehavior.Global;
	});
	self.ModePopupGui = gui;
	self:ApplyScale(gui);

	local ROW_H = 14;
	local count = #self.ModeOptions;
	if showInList ~= nil then count = count + 1 end;
	local W = showInList ~= nil and 84 or 60;
	local H = count * ROW_H + (count - 1) * 1 + 4;

	local Outline = self:CreateInstance("Frame", {
		Parent = gui;
		BackgroundColor3 = hex("07080A"); BorderSizePixel = 0;
		Size = FromOffset(W, 0); ZIndex = 1500;
		ClipsDescendants = true;
	});
	local Mid = self:CreateInstance("Frame", {
		Parent = Outline;
		Position = NewUdim2(0, 1, 0, 1); Size = NewUdim2(1, -2, 1, -2);
		BackgroundColor3 = hex("24262D"); BorderSizePixel = 0; ZIndex = 1501;
	});
	local Body = self:CreateInstance("Frame", {
		Parent = Mid;
		Position = NewUdim2(0, 1, 0, 1); Size = NewUdim2(1, -2, 1, -2);
		BackgroundColor3 = hex("1C1D23"); BorderSizePixel = 0; ZIndex = 1502;
	});
	self:CreateInstance("UIListLayout", {
		Parent = Body;
		FillDirection = Enum.FillDirection.Vertical;
		SortOrder = Enum.SortOrder.LayoutOrder;
		Padding = NewUdim(0, 1);
	});
	self:CreateInstance("UIPadding", {
		Parent = Body;
		PaddingTop = NewUdim(0, 1); PaddingBottom = NewUdim(0, 1);
		PaddingLeft = NewUdim(0, 1); PaddingRight = NewUdim(0, 1);
	});

	local function Close()
		if Library.ModePopupCloseConn then Library.ModePopupCloseConn:Disconnect(); Library.ModePopupCloseConn = nil end;
		if gui and gui.Parent then
			local Tween = Library:Tween(Outline, NewTweenInfo(0.12, Enum.EasingStyle.Quad, Enum.EasingDirection.Out), { Size = FromOffset(W, 0) });
			Tween:Play();
			Tween.Completed:Once(function()
				if gui and gui.Parent then gui:Destroy() end;
				if Library.ModePopupGui == gui then Library.ModePopupGui = nil end;
			end);
		end;
	end;

	local CurrentMode = current;
	local CurrentShow = showInList ~= false;
	for i, mode in self.ModeOptions do
		local IsCurrent = (mode == current);
		local btn = self:CreateInstance("TextButton", {
			Parent = Body;
			Size = NewUdim2(1, 0, 0, ROW_H);
			BackgroundTransparency = 1;
			BorderSizePixel = 0; AutoButtonColor = false;
			Text = mode;
			FontFace = Library.Fonts.title;
			TextColor3 = IsCurrent and (Library.AccentColor or hex("98BCFF")) or FromRgb(255, 255, 255);
			TextSize = 9;
			ZIndex = 1503;
			LayoutOrder = i;
		});
		Library:Connection(btn.MouseButton1Click, function()
			CurrentMode = mode;
			Close();
			if typeof(apply) == "function" then apply(mode, CurrentShow) end;
		end);
	end;

	if showInList ~= nil then
		local ToggleRow = self:CreateInstance("Frame", {
			Parent = Body;
			Size = NewUdim2(1, 0, 0, ROW_H);
			BackgroundTransparency = 1;
			BorderSizePixel = 0;
			ZIndex = 1503;
			LayoutOrder = #self.ModeOptions + 1;
		});
		local BoxOutline = self:CreateInstance("Frame", {
			Parent = ToggleRow;
			AnchorPoint = NewVector2(0, 0.5);
			Position = NewUdim2(0, 0, 0.5, 0);
			Size = FromOffset(12, 12);
			BackgroundColor3 = hex("24262D");
			BorderSizePixel = 0;
			ZIndex = 1504;
		});
		local BoxBody = self:CreateInstance("Frame", {
			Parent = BoxOutline;
			Position = NewUdim2(0, 1, 0, 1);
			Size = NewUdim2(1, -2, 1, -2);
			BackgroundColor3 = hex("1C1D23");
			BorderSizePixel = 0;
			ZIndex = 1505;
		});
		local BoxFill = self:CreateInstance("Frame", {
			Parent = BoxBody;
			Size = NewUdim2(1, 0, 1, 0);
			BackgroundColor3 = FromRgb(255, 255, 255);
			BackgroundTransparency = CurrentShow and 0 or 1;
			BorderSizePixel = 0;
			ZIndex = 1506;
		});
		self:CreateInstance("UIGradient", {
			Parent = BoxFill;
			Rotation = 90;
			Color = NewColorSequence(hex("94B7F8"), hex("6B84B3"));
		});
		local ToggleLabel = self:CreateInstance("TextLabel", {
			Parent = ToggleRow;
			AnchorPoint = NewVector2(0, 0.5);
			Position = NewUdim2(0, 18, 0.5, -1);
			Size = NewUdim2(1, -18, 1, 0);
			BackgroundTransparency = 1;
			FontFace = Library.Fonts.title;
			Text = "Show In List";
			TextColor3 = CurrentShow and (Library.AccentColor or hex("98BCFF")) or hex("646464");
			TextSize = 9;
			TextXAlignment = Enum.TextXAlignment.Left;
			TextYAlignment = Enum.TextYAlignment.Center;
			ZIndex = 1504;
		});
		local hit = self:CreateInstance("TextButton", {
			Parent = ToggleRow;
			Size = NewUdim2(1, 0, 1, 0);
			BackgroundTransparency = 1;
			AutoButtonColor = false;
			Text = "";
			ZIndex = 1507;
		});
		Library:Connection(hit.MouseButton1Click, function()
			CurrentShow = not CurrentShow;
			local ToggleTween = NewTweenInfo(0.15, Enum.EasingStyle.Quad, Enum.EasingDirection.Out);
			Library:Tween(BoxFill, ToggleTween, { BackgroundTransparency = CurrentShow and 0 or 1 }):Play();
			Library:Tween(ToggleLabel, ToggleTween, { TextColor3 = CurrentShow and (Library.AccentColor or hex("98BCFF")) or hex("646464") }):Play();
			if typeof(apply) == "function" then apply(CurrentMode, CurrentShow) end;
		end);
	end;

	local ap = anchor.AbsolutePosition;
	local az = anchor.AbsoluteSize;
	local _, _, sc = self:GuiPoint(gui, 0, 0);
	local px, py = self:GuiPoint(gui, ap.X + az.X - W * sc, ap.Y + az.Y + 2);
	Outline.Position = NewUdim2(0, px, 0, py);
	self:Tween(Outline, NewTweenInfo(0.14, Enum.EasingStyle.Quad, Enum.EasingDirection.Out), { Size = FromOffset(W, H) }):Play();

	self.ModePopupCloseConn = UserInputService.InputBegan:Connect(function(input)
		local ut = input.UserInputType;
		if ut ~= Enum.UserInputType.MouseButton1 and ut ~= Enum.UserInputType.MouseButton2 then return end;
		local mp = input.Position;
		local op = Outline.AbsolutePosition; local os = Outline.AbsoluteSize;
		if mp.X < op.X or mp.X > op.X + os.X or mp.Y < op.Y or mp.Y > op.Y + os.Y then
			Close();
		end;
	end);
	insert(self.Connections, self.ModePopupCloseConn);
end;

function Library:FixDim() -- lol
	if not self.MenuDimGui then
		self.MenuDimGui = self:CreateInstance("ScreenGui", {
			Name = "\0";
			Parent = (gethui and gethui()) or CoreGui;
			Enabled = false;
			DisplayOrder = 990;
			IgnoreGuiInset = true;
			ResetOnSpawn = false;
			ZIndexBehavior = Enum.ZIndexBehavior.Global;
		});
		self:CreateInstance("Frame", {
			Parent = self.MenuDimGui;
			Size = NewUdim2(1, 0, 1, 0);
			BackgroundColor3 = FromRgb(0, 0, 0);
			BackgroundTransparency = 1;
			BorderSizePixel = 0;
			ZIndex = 1;
		});
	end;
	local f = self.MenuDimGui:FindFirstChildOfClass("Frame");
	local visible = self.MenuDim == true and self.CurrentWindow and self.CurrentWindow.Visible == true;
	local target = visible and (1 - (self.MenuDimOpacity or 0.55)) or 1;

	if self.MenuDimTween then
		self.MenuDimTween:Cancel();
		self.MenuDimTween = nil;
	end;

	if visible then
		self.MenuDimGui.Enabled = true;
		if f then
			self.MenuDimTween = self:Tween(f, NewTweenInfo(0.16, Enum.EasingStyle.Quad, Enum.EasingDirection.Out), { BackgroundTransparency = target });
			self.MenuDimTween:Play();
		end;
	elseif f then
		local Tween = self:Tween(f, NewTweenInfo(0.16, Enum.EasingStyle.Quad, Enum.EasingDirection.Out), { BackgroundTransparency = 1 });
		self.MenuDimTween = Tween;
		Tween:Play();
		Tween.Completed:Once(function()
			if self.MenuDimTween == Tween then
				self.MenuDimTween = nil;
			end;
			if self.MenuDimGui and not (self.MenuDim == true and self.CurrentWindow and self.CurrentWindow.Visible == true) then
				self.MenuDimGui.Enabled = false;
			end;
		end);
	else
		self.MenuDimGui.Enabled = visible == true;
	end;
end;

function Library:ConfirmClick(label, action)
	local original = label.Text;
	local primed = false;
	local token = 0;
	return function()
		if primed then
			primed = false;
			label.Text = original;
			action();
		else
			primed = true;
			label.Text = "are you sure?";
			token = token + 1;
			local MyToken = token;
			task.delay(3, function()
				if MyToken == token and primed then
					primed = false;
					label.Text = original;
				end;
			end);
		end;
	end;
end;

Library.OpenPopups = Library.OpenPopups or {};
function Library:RegisterPopup(closer)
	self.OpenPopups[#self.OpenPopups + 1] = closer;
end;
function Library:CloseAllPopups()
	for _, closer in ipairs(self.OpenPopups) do
		pcall(closer);
	end;
end;
function Library:Tooltip(anchor, opts)
	if typeof(anchor) == "table" and opts == nil then
		opts = anchor;
		anchor = opts.Path or opts.Target or opts.Anchor;
	end;
	if not anchor or not anchor.Parent then return end;
	opts = typeof(opts) == "table" and opts or { Text = tostring(opts or "") };
	local Text = tostring(opts.Text or opts.text or "");
	local Title = tostring(opts.Title or opts.title or "Info");
	local Width = tonumber(opts.Width or opts.width) or 190;

	local Mark = anchor;
	if opts.NoMark ~= true and opts.noMark ~= true then
		local MarkParent = (anchor:IsA("TextLabel") and anchor.Parent) or anchor;
		Mark = self:CreateInstance("TextLabel", {
			Name = "Tooltip";
			Parent = MarkParent;
			AnchorPoint = NewVector2(1, 0.5);
			Position = NewUdim2(1, -2, 0.5, 0);
			Size = FromOffset(12, 12);
			BackgroundTransparency = 1;
			FontFace = Library.Fonts.title;
			Text = "(?)";
			TextColor3 = self.AccentColor or hex("98BCFF");
			TextSize = 9;
			TextXAlignment = Enum.TextXAlignment.Center;
			TextYAlignment = Enum.TextYAlignment.Center;
			ZIndex = (MarkParent.ZIndex or anchor.ZIndex or 3) + 1;
		});
	end;

	local gui = self:CreateInstance("ScreenGui", {
		Name = "\0";
		Parent = (gethui and gethui()) or CoreGui;
		Enabled = false;
		DisplayOrder = 1600;
		IgnoreGuiInset = true;
		ResetOnSpawn = false;
		ZIndexBehavior = Enum.ZIndexBehavior.Global;
	});
	self:ApplyScale(gui);

	local Outer = self:CreateInstance("Frame", {
		Parent = gui;
		Size = FromOffset(Width, 0);
		BackgroundColor3 = self.WindowOuterColor or hex("07080A");
		BorderSizePixel = 0;
		ClipsDescendants = true;
		ZIndex = 1600;
	});
	local Inner = self:CreateInstance("Frame", {
		Parent = Outer;
		Position = NewUdim2(0, 1, 0, 1);
		Size = NewUdim2(1, -2, 1, -2);
		BackgroundColor3 = self.WindowInnerColor or hex("24262D");
		BorderSizePixel = 0;
		ZIndex = 1601;
	});
	local Body = self:CreateInstance("Frame", {
		Parent = Inner;
		Position = NewUdim2(0, 1, 0, 1);
		Size = NewUdim2(1, -2, 1, -2);
		BackgroundColor3 = self.WindowBgColor or hex("101114");
		BorderSizePixel = 0;
		ZIndex = 1602;
	});
	local TitleLabel = self:CreateInstance("TextLabel", {
		Parent = Body;
		Position = NewUdim2(0, 6, 0, 5);
		Size = NewUdim2(1, -12, 0, 12);
		BackgroundTransparency = 1;
		FontFace = Library.Fonts.title;
		Text = Title;
		TextColor3 = self.AccentColor or hex("98BCFF");
		TextSize = 9;
		TextXAlignment = Enum.TextXAlignment.Left;
		TextYAlignment = Enum.TextYAlignment.Top;
		ZIndex = 1603;
	});
	local TextLabel = self:CreateInstance("TextLabel", {
		Parent = Body;
		Position = NewUdim2(0, 6, 0, 19);
		Size = NewUdim2(1, -12, 0, 0);
		AutomaticSize = Enum.AutomaticSize.Y;
		BackgroundTransparency = 1;
		FontFace = Library.Fonts.title;
		Text = Text;
		TextColor3 = FromRgb(235, 235, 235);
		TextSize = 9;
		TextWrapped = true;
		TextXAlignment = Enum.TextXAlignment.Left;
		TextYAlignment = Enum.TextYAlignment.Top;
		ZIndex = 1603;
	});

	local Open = false;
	local TooltipTween = NewTweenInfo(0.14, Enum.EasingStyle.Quad, Enum.EasingDirection.Out);
	local Height;
	local function Position(input)
		local ap = Mark.AbsolutePosition;
		local sz = Mark.AbsoluteSize;
		local vp = camera.ViewportSize;
		local _, _, sc = self:GuiPoint(gui, 0, 0);
		local x = MathMin(ap.X + sz.X + 8, vp.X - Width * sc - 4);
		local y = MathMin(ap.Y + sz.Y + 4, vp.Y - Height() * sc - 4);
		local sx, sy = self:GuiPoint(gui, MathMax(4, x), MathMax(4, y));
		Outer.Position = FromOffset(sx, sy);
	end;
	Height = function()
		local _, _, sc = self:GuiPoint(gui, 0, 0);
		return MathMax(38, TextLabel.AbsoluteSize.Y / sc + 30);
	end;
	self:Connection(TextLabel:GetPropertyChangedSignal("AbsoluteSize"), function()
		if Open then
			Position();
			self:Tween(Outer, TooltipTween, { Size = FromOffset(Width, Height()) }):Play();
		end;
	end);
	local function SetOpen(Bool, input)
		Open = Bool == true;
		if Open then
			gui.Enabled = true;
			Outer.Size = FromOffset(Width, 0);
			Position(input);
			task.defer(function()
				if not Open then return end;
				Position(input);
				self:Tween(Outer, TooltipTween, { Size = FromOffset(Width, Height()) }):Play();
			end);
		else
			local Tween = self:Tween(Outer, TooltipTween, { Size = FromOffset(Width, 0) });
			Tween:Play();
			Tween.Completed:Once(function()
				if not Open then gui.Enabled = false end;
			end);
		end;
	end;

	Library:RegisterPopup(function() if Open then SetOpen(false) end end);
	self:Connection(Mark.InputBegan, function(input)
		if input.UserInputType == Enum.UserInputType.MouseMovement then SetOpen(true, input) end;
	end);
	self:Connection(Mark.MouseEnter, function() SetOpen(true) end);
	self:Connection(Mark.MouseLeave, function() SetOpen(false) end);
	self:Connection(UserInputService.InputChanged, function(input)
		if Open and input.UserInputType == Enum.UserInputType.MouseMovement then Position(input) end;
	end);

	return { Mark = Mark; Gui = gui; SetOpen = SetOpen };
end;

function Library:Risky(anchor, text)
	if not anchor or not anchor.Parent then return end;
	local Mark = self:CreateInstance("TextLabel", {
		Name = "Risky";
		Parent = anchor;
		AnchorPoint = NewVector2(1, 0.5);
		Position = NewUdim2(1, -16, 0.5, 0);
		Size = FromOffset(12, 12);
		BackgroundTransparency = 1;
		FontFace = Library.Fonts.title;
		Text = "!";
		TextColor3 = hex("FF6767");
		TextSize = 9;
		TextXAlignment = Enum.TextXAlignment.Center;
		TextYAlignment = Enum.TextYAlignment.Center;
		ZIndex = (anchor.ZIndex or 3) + 1;
	});
	self:Tooltip(Mark, { Title = "Risky"; Text = text or "This option requires confirmation before it runs."; Width = 190; NoMark = true });
	return Mark;
end;

function Library:AnimateButton(btn, scaleTarget)
	if not btn or not btn.Parent then return end;
	local Scale = scaleTarget or btn:FindFirstChildOfClass("UIScale") or self:CreateInstance("UIScale", {
		Parent = btn;
		Scale = 1;
	});
	local Hover = NewTweenInfo(0.12, Enum.EasingStyle.Quad, Enum.EasingDirection.Out);
	self:Connection(btn.MouseEnter, function()
		self:Tween(Scale, Hover, { Scale = 1.04 }):Play();
	end);
	self:Connection(btn.MouseLeave, function()
		self:Tween(Scale, Hover, { Scale = 1 }):Play();
	end);
	self:Connection(btn.MouseButton1Down, function()
		self:Tween(Scale, NewTweenInfo(0.07, Enum.EasingStyle.Quad, Enum.EasingDirection.Out), { Scale = 0.95 }):Play();
	end);
	self:Connection(btn.MouseButton1Up, function()
		self:Tween(Scale, Hover, { Scale = 1.04 }):Play();
	end);
	return Scale;
end;

--// Shared drag dispatcher
Library.ActiveDraggers = {};

function Library:RegisterDragger(handler)
	if typeof(handler) ~= "function" then return end;
	local SelfRef = self;
	if not SelfRef.DispatcherConn then
		SelfRef.DispatcherConn = UserInputService.InputChanged:Connect(function(input)
			local ut = input.UserInputType;
			if ut ~= Enum.UserInputType.MouseMovement and ut ~= Enum.UserInputType.Touch then
				return;
			end;
			local list = SelfRef.ActiveDraggers;
			for i = 1, #list do
				list[i](input);
			end;
		end);
		insert(SelfRef.Connections, SelfRef.DispatcherConn);
	end;
	insert(SelfRef.ActiveDraggers, handler);
	return handler;
end;

function Library:UnregisterDragger(handler)
	if not handler then return end;
	local list = self.ActiveDraggers;
	if not list then return end;
	for i = #list, 1, -1 do
		if list[i] == handler then
			list[i] = list[#list];
			list[#list] = nil;
			return;
		end;
	end;
end;

Library.WidgetStates = Library.WidgetStates or {};
Library.Widgets = Library.Widgets or {};

function Library:WidgetStateKey(frame)
	if not frame or not frame.GetAttribute then return end;
	local ok, key = pcall(function() return frame:GetAttribute("NhWidgetKey") end);
	if ok then return key end;
end;

function Library:SerializeWidget(panel)
	if typeof(panel) ~= "table" then return {} end;
	local frame = panel.Frame or panel.Outer;
	local gui = panel.Gui;
	local Visible;
	if panel.Visible ~= nil then
		Visible = panel.Visible == true;
	else
		Visible = (not gui) or gui.Enabled == true;
	end;
	local out = { Visible = Visible };
	if frame then
		out.Position = {
			XScale = frame.Position.X.Scale;
			X = frame.Position.X.Offset;
			YScale = frame.Position.Y.Scale;
			Y = frame.Position.Y.Offset;
		};
		out.Size = {
			XScale = frame.Size.X.Scale;
			X = frame.Size.X.Offset;
			YScale = frame.Size.Y.Scale;
			Y = frame.Size.Y.Offset;
		};
	end;
	return out;
end;

function Library:ApplyWidgetState(panel, state)
	if typeof(panel) ~= "table" or typeof(state) ~= "table" then return end;
	local frame = panel.Frame or panel.Outer;
	if frame then
		if typeof(state.Position) == "table" then
			frame.Position = NewUdim2(
				tonumber(state.Position.XScale) or frame.Position.X.Scale,
				tonumber(state.Position.X) or frame.Position.X.Offset,
				tonumber(state.Position.YScale) or frame.Position.Y.Scale,
				tonumber(state.Position.Y) or frame.Position.Y.Offset
			);
		end;
		if typeof(state.Size) == "table" then
			frame.Size = NewUdim2(
				tonumber(state.Size.XScale) or frame.Size.X.Scale,
				tonumber(state.Size.X) or frame.Size.X.Offset,
				tonumber(state.Size.YScale) or frame.Size.Y.Scale,
				tonumber(state.Size.Y) or frame.Size.Y.Offset
			);
		end;
	end;
	if state.Visible ~= nil and panel.Gui then
		local Visible = state.Visible == true;
		panel.Gui.Enabled = Visible;
		panel.Visible = Visible;
		if panel.ManualVisible ~= nil then
			panel.ManualVisible = Visible;
		end;
	end;
end;

function Library:SaveWidgetState(panel)
	if typeof(panel) ~= "table" or not panel.WidgetFlag then return end;
	self.Flags[panel.WidgetFlag] = self:SerializeWidget(panel);
end;

function Library:SetWidgetVisible(panel, on, noSave)
	if typeof(panel) ~= "table" or not panel.Gui then return end;
	on = on == true;
	panel.Visible = on;
	local scale = panel.Scale;
	if on then
		panel.Gui.Enabled = true;
		if scale then
			scale.Scale = 0.96;
			self:Tween(scale, NewTweenInfo(0.14, Enum.EasingStyle.Quad, Enum.EasingDirection.Out), { Scale = 1 }):Play();
		end;
	else
		if scale then
			local Tween = self:Tween(scale, NewTweenInfo(0.14, Enum.EasingStyle.Quad, Enum.EasingDirection.Out), { Scale = 0.96 });
			Tween:Play();
			Tween.Completed:Once(function()
				if not panel.Visible then panel.Gui.Enabled = false end;
			end);
		else
			panel.Gui.Enabled = false;
		end;
	end;
	if not noSave then self:SaveWidgetState(panel); end;
	if self.CurrentDock and self.CurrentDock ~= panel and self.CurrentDock.RefreshBtns then
		self.CurrentDock:RefreshBtns();
	end;
end;

function Library:TrackWidget(panel, key)
	if typeof(panel) ~= "table" then return panel end;
	local frame = panel.Frame or panel.Outer;
	local flag = "widgets." .. tostring(key);
	panel.WidgetKey = tostring(key);
	panel.WidgetFlag = flag;
	self.Widgets[panel.WidgetKey] = panel;
	if frame and frame.SetAttribute then
		pcall(function() frame:SetAttribute("NhWidgetKey", flag) end);
	end;
	if frame and not panel.Scale then
		panel.Scale = self:CreateInstance("UIScale", {
			Parent = frame;
			Scale = 1;
		});
	end;
	local Existing = self.Flags[flag];
	self:RegisterFlag(flag, Existing or self:SerializeWidget(panel), function(v)
		Library:ApplyWidgetState(panel, v);
	end);
	self:ApplyWidgetState(panel, self.Flags[flag]);
	return panel;
end;

--// Search registry
Library.SearchItems = {};
Library.SearchSections = {};
Library.PopupSections = {};
Library.SettingsRegistry = Library.SettingsRegistry or {};

function Library:RefreshSettings()
	for i = #(self.SettingsRegistry or {}), 1, -1 do
		local Settings = self.SettingsRegistry[i];
		if Settings and Settings.Row and Settings.Row.Parent then
			if Settings.Refresh then Settings:Refresh() end;
		else
			table.remove(self.SettingsRegistry, i);
		end;
	end;
end;

function Library:RegisterSearchable(name, frame, section)
	insert(self.SearchItems, { name = string.lower(tostring(name)); Frame = frame; section = section });
end;

function Library:ApplySearch(query)
	query = string.lower(tostring(query or ""));
	local popup = self.PopupSections or {};
	local SectionNameMatch = {};
	for section in self.SearchSections do
		if not popup[section] then
			local header = section:FindFirstChild("Header");
			local title = header and header:FindFirstChild("Title");
			local name = title and string.lower(title.Text) or "";
			SectionNameMatch[section] = (query == "" or string.find(name, query, 1, true) ~= nil);
		end;
	end;
	local SectionHasVisible = {};
	for _, item in self.SearchItems do
		if item.section and popup[item.section] then
			if item.Frame and item.Frame.Parent then
				item.Frame.Visible = true;
			end;
		elseif item.Frame and item.Frame.Parent then
			local match = query == "" or string.find(item.name, query, 1, true) ~= nil or (item.section and SectionNameMatch[item.section]);
			item.Frame.Visible = match;
			if match and item.section then
				SectionHasVisible[item.section] = true;
			end;
		end;
	end;
	for section in self.SearchSections do
		if not popup[section] then
			local wrap = section.Parent;
			if wrap then
				wrap.Visible = query == "" or SectionHasVisible[section] == true or SectionNameMatch[section];
			end;
		end;
	end;
end;

--// Window helpers
function Library:Draggable(TargetFrame, DragHandle)
	local handle = DragHandle or TargetFrame;
	local dragging = false;
	local DragStart, StartPosition;
	local DragHandler;

	DragHandler = function(input)
		if not DragStart or not StartPosition then return end;
		local delta = input.Position - DragStart;
		local vp = camera.ViewportSize;
		local gui = TargetFrame:FindFirstAncestorOfClass("ScreenGui");
		local _, _, scale = self:GuiPoint(gui, 0, 0);
		local NewX = MathClamp(StartPosition.X.Offset + delta.X / scale, 0, vp.X / scale - TargetFrame.AbsoluteSize.X / scale);
		local NewY = MathClamp(StartPosition.Y.Offset + delta.Y / scale, 0, vp.Y / scale - TargetFrame.AbsoluteSize.Y / scale);
		TargetFrame.Position = NewUdim2(0, NewX, 0, NewY);
	end;

	self:Connection(handle.InputBegan, function(input)
		if input.UserInputType ~= Enum.UserInputType.MouseButton1
			and input.UserInputType ~= Enum.UserInputType.Touch
		then
			return;
		end;
		if dragging then return end;
		local ap = TargetFrame.AnchorPoint;
		local pos = TargetFrame.Position;
		if ap.X ~= 0 or ap.Y ~= 0 or pos.X.Scale ~= 0 or pos.Y.Scale ~= 0 then
			local AbsP = TargetFrame.AbsolutePosition;
			local gui = TargetFrame:FindFirstAncestorOfClass("ScreenGui");
			local X, Y = self:GuiPoint(gui, AbsP.X, AbsP.Y);
			TargetFrame.AnchorPoint = NewVector2(0, 0);
			TargetFrame.Position = NewUdim2(0, X, 0, Y);
		end;
		dragging = true;
		DragStart = input.Position;
		StartPosition = TargetFrame.Position;
		self:RegisterDragger(DragHandler);
	end);

	self:Connection(handle.InputEnded, function(input)
		if input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.Touch then
			if dragging then
				dragging = false;
				self:UnregisterDragger(DragHandler);
				local key = self:WidgetStateKey(TargetFrame);
				if key then self.Flags[key] = self:SerializeWidget({ Frame = TargetFrame; Gui = TargetFrame:FindFirstAncestorOfClass("ScreenGui") }) end;
			end;
		end;
	end);
end;

function Library:Resizable(TargetFrame, opts)
	opts = typeof(opts) == "table" and opts or {};
	local GripPx = tonumber(opts.GripPx) or 12;
	local MinX = tonumber(opts.MinX) or TargetFrame.Size.X.Offset;
	local MinY = tonumber(opts.MinY) or TargetFrame.Size.Y.Offset;
	local AspectRatio = tonumber(opts.AspectRatio);

	local grip = self:CreateInstance("TextButton", {
		Name = "ResizeGrip";
		Parent = TargetFrame;
		AnchorPoint = NewVector2(1, 1);
		Position = NewUdim2(1, 0, 1, 0);
		Size = NewUdim2(0, GripPx, 0, GripPx);
		BackgroundTransparency = 1;
		AutoButtonColor = false;
		BorderSizePixel = 0;
		Text = "";
		ZIndex = 999;
	});

	local resizing = false;
	local StartPos, StartSize;
	local ResizeHandler;

	ResizeHandler = function(input)
		if not StartPos or not StartSize then return end;
		local vp = camera.ViewportSize;
		local dx = input.Position.X - StartPos.X;
		local dy = input.Position.Y - StartPos.Y;
		if AspectRatio and AspectRatio > 0 then
			local width = MathAbs(dx) >= MathAbs(dy) and StartSize.X.Offset + dx or (StartSize.Y.Offset + dy) * AspectRatio;
			width = MathClamp(width, MathMax(MinX, MinY * AspectRatio), MathMin(vp.X, vp.Y * AspectRatio));
			TargetFrame.Size = NewUdim2(StartSize.X.Scale, width, StartSize.Y.Scale, width / AspectRatio);
			return;
		end;
		TargetFrame.Size = NewUdim2(
			StartSize.X.Scale,
			MathClamp(StartSize.X.Offset + dx, MinX, vp.X),
			StartSize.Y.Scale,
			MathClamp(StartSize.Y.Offset + dy, MinY, vp.Y)
		);
	end;

	self:Connection(grip.InputBegan, function(input)
		if input.UserInputType ~= Enum.UserInputType.MouseButton1 and input.UserInputType ~= Enum.UserInputType.Touch then
			return;
		end;
		if resizing then return end;
		resizing = true;
		StartPos = input.Position;
		StartSize = TargetFrame.Size;
		self:RegisterDragger(ResizeHandler);
	end);

	self:Connection(grip.InputEnded, function(input)
		if input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.Touch then
			if resizing then
				resizing = false;
				self:UnregisterDragger(ResizeHandler);
				local key = self:WidgetStateKey(TargetFrame);
				if key then self.Flags[key] = self:SerializeWidget({ Frame = TargetFrame; Gui = TargetFrame:FindFirstAncestorOfClass("ScreenGui") }) end;
			end;
		end;
	end);

	return grip;
end;

--// Context menu (shared by Activity + file manager)
function Library:ContextMenu(parentGui)
	local MENU_W = 170;
	local frame = self:CreateInstance("Frame", {
		Name = "ContextMenu"; Parent = parentGui;
		Position = NewUdim2(0, 0, 0, 0);
		Size = NewUdim2(0, MENU_W, 0, 0);
		BackgroundColor3 = hex("07080A");
		BorderSizePixel = 0;
		Visible = false;
		Active = true;
		ClipsDescendants = true;
		ZIndex = 50;
	});
	local mid = self:CreateInstance("Frame", {
		Name = "Mid"; Parent = frame;
		Position = NewUdim2(0, 1, 0, 1); Size = NewUdim2(1, -2, 1, -2);
		BackgroundColor3 = hex("24262D");
		BorderSizePixel = 0; ZIndex = 50;
	});
	local body = self:CreateInstance("Frame", {
		Name = "Body"; Parent = mid;
		Position = NewUdim2(0, 1, 0, 1); Size = NewUdim2(1, -2, 1, -2);
		BackgroundColor3 = FromRgb(255, 255, 255);
		BorderSizePixel = 0; ZIndex = 51;
		ClipsDescendants = true;
	});
	self:CreateInstance("UIGradient", {
		Parent = body; Rotation = 90;
		Color = NewColorSequence(hex("131418"), hex("17181D"));
	});
	local AccentBar = self:CreateInstance("Frame", {
		Name = "Accent"; Parent = body;
		Size = NewUdim2(1, 0, 0, 1);
		BackgroundColor3 = self.AccentColor or hex("98BCFF");
		BorderSizePixel = 0; ZIndex = 52;
	});
	self:CreateInstance("Frame", {
		Name = "AccentShade"; Parent = body;
		Position = NewUdim2(0, 0, 0, 1); Size = NewUdim2(1, 0, 0, 1);
		BackgroundColor3 = self.ShadeColor or hex("6E8CC8");
		BorderSizePixel = 0; ZIndex = 52;
	});
	local List = self:CreateInstance("Frame", {
		Name = "List"; Parent = body;
		Position = NewUdim2(0, 5, 0, 6);
		Size = NewUdim2(1, -10, 1, -12);
		BackgroundTransparency = 1;
		ZIndex = 52;
	});
	self:CreateInstance("UIListLayout", {
		Parent = List;
		FillDirection = Enum.FillDirection.Vertical;
		SortOrder = Enum.SortOrder.LayoutOrder;
		Padding = NewUdim(0, 2);
	});

	local CloseConn;
	local OpenTween;
	local MenuTween = NewTweenInfo(0.16, Enum.EasingStyle.Quad, Enum.EasingDirection.Out);
	local function Close()
		if not frame.Visible then
			frame.Parent = nil;
			if CloseConn then CloseConn:Disconnect(); CloseConn = nil; end;
			return;
		end;
		if OpenTween then OpenTween:Cancel(); OpenTween = nil; end;
		local t = TweenService:Create(frame, MenuTween, { Size = NewUdim2(0, MENU_W, 0, 0) });
		OpenTween = t;
		t:Play();
		t.Completed:Once(function()
			frame.Visible = false;
			frame.Parent = nil;
		end);
		if CloseConn then CloseConn:Disconnect(); CloseConn = nil; end;
	end;

	local function Open(x, y, items)
		for _, ch in List:GetChildren() do
			if ch:IsA("TextButton") or ch:IsA("Frame") or ch:IsA("TextLabel") then ch:Destroy() end;
		end;
		local height = 7;
		local LayoutOrder = 0;
		local function AddEntry(item)
			LayoutOrder += 1;
			local row = self:CreateInstance("TextButton", {
				Name = "Item"; Parent = List;
				Size = NewUdim2(1, 0, 0, 18);
				BackgroundTransparency = 1; AutoButtonColor = false;
				Text = "";
				LayoutOrder = LayoutOrder; ZIndex = 53;
			});
			local lbl = self:CreateInstance("TextLabel", {
				Name = "Label"; Parent = row;
				Position = NewUdim2(0, 5, 0, 0);
				Size = NewUdim2(1, -10, 1, 0);
				BackgroundTransparency = 1;
				FontFace = self.Fonts.title;
				Text = item.Text or "Item";
				TextColor3 = item.Disabled and hex("5F636C") or hex("DADADA");
				TextSize = 9;
				TextXAlignment = Enum.TextXAlignment.Left;
				TextYAlignment = Enum.TextYAlignment.Center;
				TextTruncate = Enum.TextTruncate.AtEnd;
				ZIndex = 54;
			});
			row.MouseEnter:Connect(function()
				if not item.Disabled then
					row.BackgroundColor3 = self.AccentColor or hex("2E5E9E");
					Library:Tween(row, MenuTween, { BackgroundTransparency = 0.75 }):Play();
				end;
			end);
			row.MouseLeave:Connect(function()
				Library:Tween(row, MenuTween, { BackgroundTransparency = 1 }):Play();
			end);
			if item.Disabled then
				row.Active = false;
			else
				row.MouseButton1Click:Connect(function()
					Close();
					if typeof(item.OnClick) == "function" then pcall(item.OnClick); end;
				end);
			end;
			height += 18 + 2;
			return row;
		end;
		for _, item in items do
			if item == "Divider" then
				LayoutOrder += 1;
				self:CreateInstance("Frame", {
					Name = "Divider"; Parent = List;
					Size = NewUdim2(1, 0, 0, 1);
					BackgroundColor3 = hex("24262D");
					BorderSizePixel = 0;
					LayoutOrder = LayoutOrder; ZIndex = 53;
				});
				height += 4;
			elseif typeof(item) == "table" then
				AddEntry(item);
			end;
		end;
		local guiW, guiH = parentGui.AbsoluteSize.X, parentGui.AbsoluteSize.Y;
		local menuScale = 1;
		local ms = parentGui:FindFirstChildOfClass("UIScale");
		if ms then menuScale = ms.Scale end;
		local px, py = x, y;
		if px + MENU_W * menuScale > guiW then px = MathMax(0, px - MENU_W * menuScale); end;
		if py + height * menuScale > guiH then py = MathMax(0, py - height * menuScale); end;
		local lx, ly = self:GuiPoint(parentGui, px, py);
		frame.Position = NewUdim2(0, lx, 0, ly);
		frame.Size = NewUdim2(0, MENU_W, 0, 0);
		frame.Parent = parentGui;
		frame.Visible = true;
		if OpenTween then OpenTween:Cancel(); end;
		local t = TweenService:Create(frame, MenuTween, { Size = NewUdim2(0, MENU_W, 0, height) });
		OpenTween = t;
		t:Play();
		if CloseConn then CloseConn:Disconnect(); end;
		CloseConn = UserInputService.InputBegan:Connect(function(input)
			pcall(function()
				if input.UserInputType ~= Enum.UserInputType.MouseButton1 and input.UserInputType ~= Enum.UserInputType.MouseButton2 then return end;
				if frame.Visible and frame.Parent then
					local mp = input.Position;
					local ax, ay = frame.AbsolutePosition.X, frame.AbsolutePosition.Y;
					if mp.X < ax or mp.X > ax + frame.AbsoluteSize.X or mp.Y < ay or mp.Y > ay + height then
						Close();
					end;
				end;
			end);
		end);
	end;

	return { Frame = frame, Open = Open, Close = Close };
end;

function Library:SetClipboard(text)
	text = tostring(text or "");
	pcall(function()
		if setclipboard then setclipboard(text);
		elseif toclipboard then toclipboard(text);
		elseif Clipboard and Clipboard.set then Clipboard.set(text); end;
	end);
	self:Notify({ Text = "Copied" });
end;

--// Window
function Library:Window(opts)
	opts = typeof(opts) == "table" and opts or {};

	if typeof(self.CurrentWindow) == "table" and typeof(self.CurrentWindow.Gui) == "Instance" and self.CurrentWindow.Gui.Parent then
		self.CurrentWindow.Gui:Destroy();
	end;
	self.CurrentWindow = nil;
	self.SearchItems = {};
	self.SearchSections = {};
	self.PopupSections = {};

	local w, h
	if typeof(opts.size) == "UDim2" then
		w = opts.size.X.Offset;
		h = opts.size.Y.Offset;
	else
		w = tonumber(opts.width) or 600;
		h = tonumber(opts.height) or 500;
	end;

	local vp = camera.ViewportSize;
	local UiScale = self:ComputeUIScale();
	local SpawnX = MathClamp(tonumber(opts.x) or 35, 0, MathMax(0, vp.X / UiScale - w));
	local SpawnY = MathClamp(tonumber(opts.y) or 70, 0, MathMax(0, vp.Y / UiScale - h));

	local gui = self:CreateInstance("ScreenGui", {
		Name = "\0";
		Parent = (gethui and gethui()) or CoreGui;
		Enabled = true;
		DisplayOrder = 1000;
		IgnoreGuiInset = true;
		ResetOnSpawn = false;
		ZIndexBehavior = Enum.ZIndexBehavior.Global;
	});
	self:ApplyScale(gui);

	local pickerGui = self:CreateInstance("ScreenGui", {
		Name = "\0";
		Parent = (gethui and gethui()) or CoreGui;
		Enabled = true;
		DisplayOrder = 1400;
		IgnoreGuiInset = true;
		ResetOnSpawn = false;
		ZIndexBehavior = Enum.ZIndexBehavior.Global;
	});
	self:ApplyScale(pickerGui);

	local outer = self:CreateInstance("Frame", {
		Name = "Outer";
		Parent = gui;
		Position = NewUdim2(0, SpawnX, 0, SpawnY);
		Size = FromOffset(w, h);
		BackgroundColor3 = hex("07080A");
		BorderSizePixel = 0;
		Active = true;
	});
	self.ScreenGui = gui;
	local WindowScale = self:CreateInstance("UIScale", {
		Parent = outer;
		Scale = 1;
	});

	self:CreateInstance("ImageLabel", {
		Name = "Glow";
		Parent = outer;
		AnchorPoint = NewVector2(0.5, 0.5);
		Position = NewUdim2(0.5, 0, 0.5, 0);
		Size = NewUdim2(1, 30, 1, 30);
		BackgroundTransparency = 1;
		Image = "rbxassetid://18245826428";
		ImageColor3 = hex("98BCFF");
		ImageTransparency = 0.86;
		ScaleType = Enum.ScaleType.Slice;
		SliceCenter = Rect.new(21, 21, 79, 79);
		ZIndex = -1;
	});

	local inner = self:CreateInstance("Frame", {
		Name = "Inner";
		Parent = outer;
		Position = NewUdim2(0, 1, 0, 1);
		Size = NewUdim2(1, -2, 1, -2);
		BackgroundColor3 = hex("24262D");
		BorderSizePixel = 0;
	});

	local main = self:CreateInstance("Frame", {
		Name = "Main";
		Parent = inner;
		Position = NewUdim2(0, 1, 0, 1);
		Size = NewUdim2(1, -2, 1, -2);
		BackgroundColor3 = hex("101114");
		BorderSizePixel = 0;
	});

	self:CreateInstance("Frame", {
		Name = "TopAccent";
		Parent = main;
		Position = NewUdim2(0, 0, 0, 0);
		Size = NewUdim2(1, 0, 0, 1);
		BackgroundColor3 = hex("98BCFF");
		BorderSizePixel = 0;
		ZIndex = 2;
	});
	self:CreateInstance("Frame", {
		Name = "TopAccentShade";
		Parent = main;
		Position = NewUdim2(0, 0, 0, 1);
		Size = NewUdim2(1, 0, 0, 1);
		BackgroundColor3 = hex("6E8CC8");
		BorderSizePixel = 0;
		ZIndex = 2;
	});

	local WindowTitle = self:CreateInstance("TextLabel", {
		Name = "WindowTitle";
		Parent = main;
		Position = NewUdim2(0, 10, 0, 5);
		Size = NewUdim2(0, 0, 0, 14);
		AutomaticSize = Enum.AutomaticSize.X;
		BackgroundTransparency = 1;
		FontFace = Library.Fonts.title;
		Text = "Panel";
		TextColor3 = FromRgb(255, 255, 255);
		TextSize = 9;
		TextXAlignment = Enum.TextXAlignment.Left;
		TextYAlignment = Enum.TextYAlignment.Top;
		ZIndex = 5;
	});
	self:CreateInstance("UIGradient", {
		Parent = WindowTitle;
		Color = NewColorSequence(hex("98BCFF"), hex("6E8CC8"));
		Rotation = 90;
	});

	local InnerBox = self:CreateInstance("Frame", {
		Name = "InnerBox";
		Parent = main;
		Position = NewUdim2(0, 10, 0, 24);
		Size = NewUdim2(1, -20, 1, -34);
		BackgroundColor3 = hex("07080A");
		BorderSizePixel = 0;
		ZIndex = 2;
	});

	local InnerBoxInner = self:CreateInstance("Frame", {
		Name = "Inner";
		Parent = InnerBox;
		Position = NewUdim2(0, 1, 0, 1);
		Size = NewUdim2(1, -2, 1, -2);
		BackgroundColor3 = hex("24262D");
		BorderSizePixel = 0;
		ZIndex = 2;
	});

	local InnerBody = self:CreateInstance("Frame", {
		Name = "Body";
		Parent = InnerBoxInner;
		Position = NewUdim2(0, 1, 0, 1);
		Size = NewUdim2(1, -2, 1, -2);
		BackgroundColor3 = hex("101114");
		BorderSizePixel = 0;
		ZIndex = 2;
	});

	self:CreateInstance("Frame", {
		Name = "TopAccent";
		Parent = InnerBody;
		Position = NewUdim2(0, 0, 0, 0);
		Size = NewUdim2(1, 0, 0, 1);
		BackgroundColor3 = hex("98BCFF");
		BorderSizePixel = 0;
		ZIndex = 3;
	});
	self:CreateInstance("Frame", {
		Name = "TopAccentShade";
		Parent = InnerBody;
		Position = NewUdim2(0, 0, 0, 1);
		Size = NewUdim2(1, 0, 0, 1);
		BackgroundColor3 = hex("6E8CC8");
		BorderSizePixel = 0;
		ZIndex = 3;
	});

	local TabBar = self:CreateInstance("Frame", {
		Name = "TabBar";
		Parent = InnerBody;
		Position = NewUdim2(0, 0, 0, 2);
		Size = NewUdim2(1, 0, 0, 22);
		BackgroundColor3 = hex("101114");
		BorderSizePixel = 0;
		ZIndex = 3;
	});

	self:CreateInstance("Frame", {
		Name = "TabMergeLine";
		Parent = InnerBody;
		Position = NewUdim2(0, 0, 0, 24);
		Size = NewUdim2(1, 0, 0, 1);
		BackgroundColor3 = hex("24262D");
		BorderSizePixel = 0;
		ZIndex = 3;
	});
	self:CreateInstance("Frame", {
		Name = "TabOutlineLine";
		Parent = InnerBody;
		Position = NewUdim2(0, 0, 0, 25);
		Size = NewUdim2(1, 0, 0, 1);
		BackgroundColor3 = hex("07080A");
		BorderSizePixel = 0;
		ZIndex = 3;
	});

	local TabStrip = self:CreateInstance("Frame", {
		Name = "TabStrip";
		Parent = TabBar;
		Size = NewUdim2(1, 0, 1, 0);
		BackgroundTransparency = 1;
		BorderSizePixel = 0;
		ZIndex = 4;
	});
	self:CreateInstance("UIPadding", {
		Parent = TabStrip;
		PaddingTop = NewUdim(0, 0);
		PaddingBottom = NewUdim(0, 1);
	});
	self:CreateInstance("UIListLayout", {
		Parent = TabStrip;
		FillDirection = Enum.FillDirection.Horizontal;
		SortOrder = Enum.SortOrder.LayoutOrder;
		VerticalAlignment = Enum.VerticalAlignment.Top;
		Padding = NewUdim(0, 0);
	});

	self:Draggable(outer);
	self:Resizable(outer, { MinX = 480; MinY = 360 });

	local window = { Gui = gui, Outer = outer, Inner = inner, Main = main, TabStrip = TabStrip, Tabs = {}, ActiveTab = nil, Scale = WindowScale, Visible = true };

	local function BindScrollCanvas(scroll, layout)
		local function Refresh()
			local pad = scroll:FindFirstChildOfClass("UIPadding");
			local top = pad and pad.PaddingTop.Offset or 0;
			local bottom = pad and pad.PaddingBottom.Offset or 0;
			scroll.CanvasSize = NewUdim2(0, 0, 0, layout.AbsoluteContentSize.Y + top + bottom + 8);
		end;
		Library:Connection(layout:GetPropertyChangedSignal("AbsoluteContentSize"), Refresh);
		Library:Connection(scroll:GetPropertyChangedSignal("AbsoluteSize"), Refresh);
		Library:Connection(scroll.ChildAdded, function()
			task.defer(Refresh);
		end);
		Library:Connection(scroll.ChildRemoved, function()
			task.defer(Refresh);
		end);
		task.defer(Refresh);
		return Refresh;
	end;

	local function SubKeyText(k)
		if k == nil then return "-" end;
		local mapped = Library.KeyNames[k];
		if mapped then return mapped end;
		local raw = tostring(k);
		return (raw:gsub("Enum.KeyCode.", "")):gsub("Enum.UserInputType.", "");
	end;

	local function BuildSubKeybind(ParentRow, KeyName, DefaultKey, sub_callback, FlagOpt, RightOffset)
		local flag = Library:AutoFlag(FlagOpt or KeyName);
		local ModeFlag = flag .. ".Mode";
		local ShowFlag = flag .. ".ShowInList";
		local btn = Library:CreateInstance("TextButton", {
			Name = "SubKeybind_" .. KeyName;
			Parent = ParentRow;
			AnchorPoint = NewVector2(1, 0.5);
			Position = NewUdim2(1, RightOffset or -2, 0.5, 0);
			Size = NewUdim2(0, 36, 0, 14);
			BackgroundColor3 = hex("07080A");
			BorderSizePixel = 0; AutoButtonColor = false; Text = "";
			ZIndex = 5;
		});
		Library:CreateInstance("Frame", {
			Parent = btn;
			Position = NewUdim2(0, 1, 0, 1); Size = NewUdim2(1, -2, 1, -2);
			BackgroundColor3 = hex("24262D"); BorderSizePixel = 0; ZIndex = 6;
		});
		local KeyLabel = Library:CreateInstance("TextLabel", {
			Parent = btn;
			Position = NewUdim2(0, 1, 0, 1); Size = NewUdim2(1, -2, 1, -2);
			BackgroundColor3 = hex("1C1D23");
			BorderSizePixel = 0;
			FontFace = Library.Fonts.title;
			Text = DefaultKey and ("[" .. SubKeyText(DefaultKey) .. "]") or "[-]";
			TextColor3 = hex("B4B4B4");
			TextSize = 9;
			TextXAlignment = Enum.TextXAlignment.Center;
			TextYAlignment = Enum.TextYAlignment.Center;
			ZIndex = 7;
		});
		Library:CreateInstance("UIPadding", {
			Parent = KeyLabel;
			PaddingBottom = NewUdim(0, 2);
		});

		local kb = { Btn = btn, KeyLabel = KeyLabel, Name = KeyName, Flag = flag, Key = DefaultKey, Listening = false, Mode = "Toggle", Active = false, ShowInList = true };
		function kb:Set(k)
			self.Key = k;
			Library.Flags[self.Flag] = k;
			if k == nil then
				self.KeyLabel.Text = "[-]";
			else
				self.KeyLabel.Text = "[" .. SubKeyText(k) .. "]";
			end;
			Library:UpdateKeybind(self);
		end;
		function kb:Get() return self.Key end;
		function kb:SetMode(mode)
			if mode ~= "Toggle" and mode ~= "Hold" and mode ~= "Always" then return end;
			local prev = self.Mode;
			self.Mode = mode;
			Library.Flags[ModeFlag] = mode;
			if mode == "Always" and prev ~= "Always" then
				self.Active = true;
				if typeof(sub_callback) == "function" then sub_callback(true, self.Key) end;
			end;
			Library:UpdateKeybind(self);
		end;

		Library:RegisterKeybind(kb);
		Library:RegisterFlag(flag, DefaultKey, function(v) kb:Set(v) end);
		Library:RegisterFlag(ModeFlag, kb.Mode, function(v) kb:SetMode(v) end);
		Library:RegisterFlag(ShowFlag, kb.ShowInList, function(v)
			kb.ShowInList = v ~= false;
			Library:UpdateKeybind(kb);
		end);

		local ListenConn;
		Library:Connection(btn.MouseButton1Click, function()
			if kb.Listening then return end;
			kb.Listening = true;
			KeyLabel.Text = "[...]";
			if ListenConn then ListenConn:Disconnect() end;
			ListenConn = UserInputService.InputBegan:Connect(function(input, gpe)
				if UserInputService:GetFocusedTextBox() ~= nil then return end;
				local kc, ut = input.KeyCode, input.UserInputType;
				local NewKey;
				if kc ~= Enum.KeyCode.Unknown then NewKey = kc;
				elseif ut == Enum.UserInputType.MouseButton1 or ut == Enum.UserInputType.MouseButton2 or ut == Enum.UserInputType.MouseButton3 then NewKey = ut end;
				if NewKey == nil then return end;
				if kc == Enum.KeyCode.Escape or kc == Enum.KeyCode.Backspace then kb:Set(nil) else kb:Set(NewKey) end;
				kb.Listening = false;
				if ListenConn then ListenConn:Disconnect(); ListenConn = nil end;
			end);
		end);
		Library:Connection(btn.MouseButton2Click, function()
			Library:ModePopup(btn, kb.Mode, function(m, show)
				kb.ShowInList = show ~= false;
				Library.Flags[ShowFlag] = kb.ShowInList;
				kb:SetMode(m);
				Library:UpdateKeybind(kb);
			end, kb.ShowInList);
		end);
		Library:Connection(UserInputService.InputBegan, function(input, gpe)
			if (UserInputService:GetFocusedTextBox() ~= nil) or kb.Listening or kb.Key == nil then return end;
			if kb.Mode == "Always" then return end;
			local match = (typeof(kb.Key) == "EnumItem") and (input.KeyCode == kb.Key or input.UserInputType == kb.Key);
			if not match then return end;
			if kb.Mode == "Hold" then
				kb.Active = true;
				Library:UpdateKeybind(kb);
				if typeof(sub_callback) == "function" then sub_callback(true, kb.Key) end;
			else
				kb.Active = not kb.Active;
				Library:UpdateKeybind(kb);
				if typeof(sub_callback) == "function" then sub_callback(kb.Active, kb.Key) end;
			end;
		end);
		Library:Connection(UserInputService.InputEnded, function(input, gpe)
			if (UserInputService:GetFocusedTextBox() ~= nil) or kb.Listening or kb.Key == nil then return end;
			if kb.Mode ~= "Hold" then return end;
			local match = (typeof(kb.Key) == "EnumItem") and (input.KeyCode == kb.Key or input.UserInputType == kb.Key);
			if not match then return end;
			kb.Active = false;
			Library:UpdateKeybind(kb);
			if typeof(sub_callback) == "function" then sub_callback(false, kb.Key) end;
		end);
		return kb;
	end;

	local function BuildSubColorpicker(ParentRow, PickerName, DefaultColor, DefaultAlpha, sub_callback, FlagOpt, RightOffset, PickerGui)
		PickerGui = PickerGui or pickerGui;
		local color = typeof(DefaultColor) == "Color3" and DefaultColor or FromRgb(255, 255, 255);
		local h, s, v = color:ToHSV();
		local a = MathClamp(tonumber(DefaultAlpha) or 1, 0, 1);
		local flag = Library:AutoFlag(FlagOpt or PickerName);

		local swatch = Library:CreateInstance("TextButton", {
			Name = "SubColorpicker_" .. PickerName;
			Parent = ParentRow;
			AnchorPoint = NewVector2(1, 0.5);
			Position = NewUdim2(1, RightOffset or -2, 0.5, 0);
			Size = NewUdim2(0, 24, 0, 14);
			BackgroundColor3 = hex("07080A");
			BorderSizePixel = 0; AutoButtonColor = false; Text = "";
			ZIndex = 5;
		});
		Library:CreateInstance("Frame", {
			Parent = swatch;
			Position = NewUdim2(0, 1, 0, 1); Size = NewUdim2(1, -2, 1, -2);
			BackgroundColor3 = hex("24262D"); BorderSizePixel = 0; ZIndex = 6;
		});
		local SwFill = Library:CreateInstance("Frame", {
			Parent = swatch;
			Position = NewUdim2(0, 2, 0, 2); Size = NewUdim2(1, -4, 1, -4);
			BackgroundColor3 = color;
			BackgroundTransparency = 1 - a;
			BorderSizePixel = 0; ZIndex = 7;
		});

		local PICKER_W, PICKER_H = 190, 180;
		local picker = Library:CreateInstance("Frame", {
			Name = "Picker_" .. PickerName;
			Parent = PickerGui;
			Size = FromOffset(PICKER_W, PICKER_H);
			BackgroundColor3 = hex("07080A"); BorderSizePixel = 0;
			Active = true;
			Visible = false; ClipsDescendants = true; ZIndex = 50;
		});
		Library:CreateInstance("Frame", {
			Parent = picker;
			Position = NewUdim2(0, 1, 0, 1); Size = NewUdim2(1, -2, 1, -2);
			BackgroundColor3 = hex("24262D"); BorderSizePixel = 0; ZIndex = 51;
		});
		local PickerBody = Library:CreateInstance("Frame", {
			Parent = picker;
			Position = NewUdim2(0, 2, 0, 2); Size = NewUdim2(1, -4, 1, -4);
			BackgroundColor3 = hex("101114"); BorderSizePixel = 0; ZIndex = 52;
		});
		Library:CreateInstance("UIPadding", {
			Parent = PickerBody;
			PaddingTop = NewUdim(0, 8); PaddingBottom = NewUdim(0, 8);
			PaddingLeft = NewUdim(0, 8); PaddingRight = NewUdim(0, 8);
		});

		local SatVal = Library:CreateInstance("Frame", {
			Name = "PickerUI"; Parent = PickerBody;
			Size = NewUdim2(1, -30, 1, 0);
			BackgroundColor3 = FromRgb(255, 0, 0); BorderSizePixel = 0; ZIndex = 53;
		});
		local SatLayer = Library:CreateInstance("TextButton", {
			Parent = SatVal; Size = NewUdim2(1, 0, 1, 0);
			BackgroundColor3 = FromRgb(255, 255, 255); BorderSizePixel = 0;
			AutoButtonColor = false; Text = ""; ZIndex = 54;
		});
		Library:CreateInstance("UIGradient", {
			Parent = SatLayer;
			Transparency = NewNumberSequence({
				NewNumberSequenceKeypoint(0, 0); NewNumberSequenceKeypoint(1, 1);
			});
			Color = NewColorSequence(FromRgb(255, 255, 255), FromRgb(255, 255, 255));
		});
		local ValLayer = Library:CreateInstance("TextButton", {
			Parent = SatVal; Size = NewUdim2(1, 0, 1, 0);
			BackgroundColor3 = FromRgb(0, 0, 0); BorderSizePixel = 0;
			AutoButtonColor = false; Text = ""; ZIndex = 55;
		});
		Library:CreateInstance("UIGradient", {
			Parent = ValLayer; Rotation = 90;
			Transparency = NewNumberSequence({
				NewNumberSequenceKeypoint(0, 1); NewNumberSequenceKeypoint(1, 0);
			});
			Color = NewColorSequence(FromRgb(0, 0, 0), FromRgb(0, 0, 0));
		});
		local SvMarker = Library:CreateInstance("Frame", {
			Name = "Marker"; Parent = SatVal;
			Size = FromOffset(2, 2);
			BorderSizePixel = 1; BorderColor3 = FromRgb(0, 0, 0);
			BackgroundColor3 = FromRgb(255, 255, 255); ZIndex = 56;
		});
		local hue = Library:CreateInstance("TextButton", {
			Name = "PickerUI"; Parent = PickerBody;
			AnchorPoint = NewVector2(1, 0);
			Position = NewUdim2(1, -14, 0, 0); Size = NewUdim2(0, 12, 1, 0);
			BackgroundColor3 = FromRgb(255, 255, 255); BorderSizePixel = 0;
			AutoButtonColor = false; Text = ""; ZIndex = 53;
		});
		Library:CreateInstance("UIGradient", {
			Parent = hue; Rotation = 270;
			Color = NewColorSequence({
				NewColorSequenceKeypoint(0.00, FromRgb(255, 0, 0));
				NewColorSequenceKeypoint(0.17, FromRgb(255, 255, 0));
				NewColorSequenceKeypoint(0.33, FromRgb(0, 255, 0));
				NewColorSequenceKeypoint(0.50, FromRgb(0, 255, 255));
				NewColorSequenceKeypoint(0.67, FromRgb(0, 0, 255));
				NewColorSequenceKeypoint(0.83, FromRgb(255, 0, 255));
				NewColorSequenceKeypoint(1.00, FromRgb(255, 0, 0));
			});
		});
		local HueMarker = Library:CreateInstance("Frame", {
			Name = "Marker"; Parent = hue;
			Size = NewUdim2(1, 0, 0, 2);
			BorderSizePixel = 1; BorderColor3 = FromRgb(0, 0, 0);
			BackgroundColor3 = FromRgb(255, 255, 255); ZIndex = 54;
		});
		local alpha = Library:CreateInstance("TextButton", {
			Name = "Alpha"; Parent = PickerBody;
			AnchorPoint = NewVector2(1, 0);
			Position = NewUdim2(1, 0, 0, 0); Size = NewUdim2(0, 12, 1, 0);
			BackgroundColor3 = color; BorderSizePixel = 0;
			AutoButtonColor = false; Text = ""; ZIndex = 53;
		});
		local AlphaCheckers = Library:CreateInstance("ImageLabel", {
			Name = "Checkers"; Parent = alpha;
			Size = NewUdim2(1, 0, 1, 0);
			BackgroundTransparency = 1; BorderSizePixel = 0;
			Image = "rbxassetid://18274452449";
			ScaleType = Enum.ScaleType.Tile;
			TileSize = FromOffset(6, 6);
			ZIndex = 54;
		});
		Library:CreateInstance("UIGradient", {
			Parent = AlphaCheckers; Rotation = 270;
			Transparency = NewNumberSequence({
				NewNumberSequenceKeypoint(0, 0); NewNumberSequenceKeypoint(1, 1);
			});
		});
		local AlphaMarker = Library:CreateInstance("Frame", {
			Name = "Marker"; Parent = alpha;
			Size = NewUdim2(1, 0, 0, 2);
			BorderSizePixel = 1; BorderColor3 = FromRgb(0, 0, 0);
			BackgroundColor3 = FromRgb(255, 255, 255); ZIndex = 55;
		});

		local cp = { Swatch = swatch, Picker = picker, Name = PickerName, Flag = flag, Color = color, Transparency = 1 - a };
		local function ApplyState()
			local c = FromHsv(h, s, v);
			color = c;
			local t = 1 - a;
			cp.Color = c;
			cp.Transparency = t;
			Library.Flags[flag] = { Color = c, Transparency = t };
			SwFill.BackgroundColor3 = c;
			SwFill.BackgroundTransparency = t;
			alpha.BackgroundColor3 = c;
			SatVal.BackgroundColor3 = FromHsv(h, 1, 1);
			local SOff = (s < 1) and 0 or -3;
			local VOff = ((1 - v) < 1) and 0 or -3;
			SvMarker.Position = NewUdim2(s, SOff, 1 - v, VOff);
			local HOff = ((1 - h) < 1) and 0 or -2;
			HueMarker.Position = NewUdim2(0, 0, 1 - h, HOff);
			local AOff = ((1 - a) < 1) and 0 or -2;
			AlphaMarker.Position = NewUdim2(0, 0, 1 - a, AOff);
			if typeof(sub_callback) == "function" then sub_callback(c, a) end;
		end;
		function cp:Get() return color, a end;
		function cp:Set(NewColor, NewAlpha)
			if typeof(NewColor) == "table" and NewColor.Color ~= nil then
				if typeof(NewColor.Color) == "Color3" then h, s, v = NewColor.Color:ToHSV() end;
				if NewColor.Transparency ~= nil then a = 1 - MathClamp(tonumber(NewColor.Transparency) or (1 - a), 0, 1) end;
			else
				if typeof(NewColor) == "Color3" then h, s, v = NewColor:ToHSV() end;
				if NewAlpha ~= nil then a = MathClamp(tonumber(NewAlpha) or a, 0, 1) end;
			end;
			ApplyState();
		end;
		ApplyState();
		Library:RegisterFlag(flag, { Color = color, Transparency = 1 - a }, function(val) cp:Set(val) end);

		local open = false;
		local PickerTween;
		local PICKER_ANIM = NewTweenInfo(0.15, Enum.EasingStyle.Quad, Enum.EasingDirection.Out);
		local function SetOpen(b)
			open = b;
			if PickerTween then PickerTween:Cancel() end;
			if b then
				local p = swatch.AbsolutePosition;
				local _, _, sc = Library:GuiPoint(PickerGui, 0, 0);
				local sw = swatch.AbsoluteSize;
				local px, py = Library:GuiPoint(PickerGui, p.X - PICKER_W * sc + sw.X, p.Y + sw.Y + 2);
				picker.Position = NewUdim2(0, px, 0, py);
				picker.Size = FromOffset(PICKER_W, 0);
				picker.Visible = true;
				PickerTween = TweenService:Create(picker, PICKER_ANIM, { Size = FromOffset(PICKER_W, PICKER_H) });
				PickerTween:Play();
			else
				PickerTween = TweenService:Create(picker, PICKER_ANIM, { Size = FromOffset(PICKER_W, 0) });
				PickerTween:Play();
				PickerTween.Completed:Once(function() if not open then picker.Visible = false end end);
			end;
		end;
		local DragSv, DragH, DragA = false, false, false;
		Library:Connection(swatch.MouseButton1Click, function() SetOpen(not open) end);
		Library:RegisterPopup(function() if open then SetOpen(false) end end);
		Library:Connection(swatch.MouseButton2Click, function()
			if (UserInputService:IsKeyDown(Enum.KeyCode.LeftControl) or UserInputService:IsKeyDown(Enum.KeyCode.RightControl)) and Library.CopiedColor then
				cp:Set(Library.CopiedColor);
			else
				Library.CopiedColor = { Color = color; Transparency = 1 - a };
			end;
		end);
		Library:Connection(SatLayer.InputBegan, function(input)
			if input.UserInputType == Enum.UserInputType.MouseButton1 then DragSv = true end;
		end);
		Library:Connection(ValLayer.InputBegan, function(input)
			if input.UserInputType == Enum.UserInputType.MouseButton1 then DragSv = true end;
		end);
		Library:Connection(hue.InputBegan, function(input)
			if input.UserInputType == Enum.UserInputType.MouseButton1 then DragH = true end;
		end);
		Library:Connection(alpha.InputBegan, function(input)
			if input.UserInputType == Enum.UserInputType.MouseButton1 then DragA = true end;
		end);
		Library:Connection(UserInputService.InputEnded, function(input)
			if input.UserInputType == Enum.UserInputType.MouseButton1 then DragSv = false; DragH = false; DragA = false end;
		end);
		Library:Connection(UserInputService.InputChanged, function(input)
			if input.UserInputType ~= Enum.UserInputType.MouseMovement then return end;
			if not (DragSv or DragH or DragA) then return end;
			local mx, my = Library:MousePoint(PickerGui, input);
			if DragSv then
				local ap, sz = SatVal.AbsolutePosition, SatVal.AbsoluteSize;
				s = sz.X > 0 and MathClamp((mx - ap.X) / sz.X, 0, 1) or 0;
				v = sz.Y > 0 and 1 - MathClamp((my - ap.Y) / sz.Y, 0, 1) or 0;
			elseif DragH then
				local ap, sz = hue.AbsolutePosition, hue.AbsoluteSize;
				h = sz.Y > 0 and 1 - MathClamp((my - ap.Y) / sz.Y, 0, 1) or 0;
			elseif DragA then
				local ap, sz = alpha.AbsolutePosition, alpha.AbsoluteSize;
				a = sz.Y > 0 and 1 - MathClamp((my - ap.Y) / sz.Y, 0, 1) or 0;
			end;
			ApplyState();
		end);
		Library:Connection(UserInputService.InputBegan, function(input)
			if input.UserInputType ~= Enum.UserInputType.MouseButton1 or not open then return end;
			local mx, my = Library:MousePoint(PickerGui, input);
			if not Library:PointInObject(picker, mx, my, 2) and not Library:PointInObject(swatch, mx, my, 2) then SetOpen(false) end;
		end);
		return cp;
	end;
	function Library:AttachColorpicker(ParentRow, PickerName, DefaultColor, DefaultAlpha, callback, FlagOpt, RightOffset, PickerGui)
		return BuildSubColorpicker(ParentRow, PickerName, DefaultColor, DefaultAlpha, callback, FlagOpt, RightOffset, PickerGui);
	end;

	function window:SetActiveTab(tab)
		if self.ActiveTab == tab then return end;
		Library:CloseAllPopups();
		local prev = self.ActiveTab;
		self.ActiveTab = tab;
		if prev then prev:SetActive(false) end;
		if tab then tab:SetActive(true) end;
	end;

	function window:Tab(name)
		local order = #self.Tabs + 1;

		local LabelText = tostring(name or "Tab");

		local TabOuter = Library:CreateInstance("Frame", {
			Name = "Tab_" .. order;
			Parent = self.TabStrip;
			Size = NewUdim2(0, 0, 1, 0);
			AutomaticSize = Enum.AutomaticSize.X;
			BackgroundTransparency = 1;
			BorderSizePixel = 0;
			LayoutOrder = order;
			ZIndex = 3;
		});

		local TabLabel = Library:CreateInstance("TextLabel", {
			Name = "Label";
			Parent = TabOuter;
			AnchorPoint = NewVector2(0, 0);
			Position = NewUdim2(0, 0, 0, 6);
			Size = NewUdim2(0, 0, 0, 9);
			AutomaticSize = Enum.AutomaticSize.X;
			BackgroundTransparency = 1;
			FontFace = Library.Fonts.title;
			Text = LabelText;
			TextColor3 = hex("8A8A92");
			TextSize = 9;
			TextXAlignment = Enum.TextXAlignment.Center;
			TextYAlignment = Enum.TextYAlignment.Top;
			ZIndex = 5;
		});
		Library:CreateInstance("UIPadding", {
			Parent = TabLabel;
			PaddingLeft = NewUdim(0, 8);
			PaddingRight = NewUdim(0, 8);
		});

		local TabButton = Library:CreateInstance("TextButton", {
			Name = "Hit";
			Parent = TabOuter;
			Size = NewUdim2(1, 0, 1, 0);
			BackgroundTransparency = 1;
			BorderSizePixel = 0;
			AutoButtonColor = false;
			Text = "";
			ZIndex = 6;
		});

		local content = Library:CreateInstance("Frame", {
			Name = "Content_" .. order;
			Parent = InnerBody;
			Position = NewUdim2(0, 10, 0, 31);
			Size = NewUdim2(1, -20, 1, -41);
			BackgroundTransparency = 1;
			BorderSizePixel = 0;
			Visible = false;
			ZIndex = 2;
		});
		Library:CreateInstance("UIListLayout", {
			Parent = content;
			FillDirection = Enum.FillDirection.Horizontal;
			SortOrder = Enum.SortOrder.LayoutOrder;
			Padding = NewUdim(0, 8);
		});

		local LeftCol = Library:CreateInstance("ScrollingFrame", {
			Name = "LeftCol";
			Parent = content;
			Size = NewUdim2(0.5, -4, 1, 0);
			BackgroundTransparency = 1;
			BorderSizePixel = 0;
			CanvasSize = NewUdim2(0, 0, 0, 0);
			AutomaticCanvasSize = Enum.AutomaticSize.Y;
			ScrollingDirection = Enum.ScrollingDirection.Y;
			ScrollBarThickness = 2;
			ScrollBarImageColor3 = Library.AccentColor or hex("98BCFF");
			ScrollBarImageTransparency = 0.15;
			ClipsDescendants = true;
			Active = true;
			LayoutOrder = 1;
			ZIndex = 2;
		});
		Library:CreateInstance("UIPadding", {
			Parent = LeftCol;
			PaddingTop = NewUdim(0, 8);
			PaddingBottom = NewUdim(0, 8);
			PaddingRight = NewUdim(0, 4);
		});
		local LeftLayout = Library:CreateInstance("UIListLayout", {
			Parent = LeftCol;
			FillDirection = Enum.FillDirection.Vertical;
			SortOrder = Enum.SortOrder.LayoutOrder;
			Padding = NewUdim(0, 10);
		});
		local RefreshLeftCanvas = BindScrollCanvas(LeftCol, LeftLayout);

		local RightCol = Library:CreateInstance("ScrollingFrame", {
			Name = "RightCol";
			Parent = content;
			Size = NewUdim2(0.5, -4, 1, 0);
			BackgroundTransparency = 1;
			BorderSizePixel = 0;
			CanvasSize = NewUdim2(0, 0, 0, 0);
			AutomaticCanvasSize = Enum.AutomaticSize.Y;
			ScrollingDirection = Enum.ScrollingDirection.Y;
			ScrollBarThickness = 2;
			ScrollBarImageColor3 = Library.AccentColor or hex("98BCFF");
			ScrollBarImageTransparency = 0.15;
			ClipsDescendants = true;
			Active = true;
			LayoutOrder = 2;
			ZIndex = 2;
		});
		Library:CreateInstance("UIPadding", {
			Parent = RightCol;
			PaddingTop = NewUdim(0, 8);
			PaddingBottom = NewUdim(0, 8);
			PaddingRight = NewUdim(0, 4);
		});
		local RightLayout = Library:CreateInstance("UIListLayout", {
			Parent = RightCol;
			FillDirection = Enum.FillDirection.Vertical;
			SortOrder = Enum.SortOrder.LayoutOrder;
			Padding = NewUdim(0, 10);
		});
		local RefreshRightCanvas = BindScrollCanvas(RightCol, RightLayout);

		local tab = { Outer = TabOuter, Label = TabLabel, Content = content, LeftCol = LeftCol, RightCol = RightCol, Sections = {}, Name = name, Active = false };
		function tab:RefreshCanvases()
			RefreshLeftCanvas();
			RefreshRightCanvas();
		end;

		local TabFadeInfo = NewTweenInfo(0.2, Enum.EasingStyle.Quad, Enum.EasingDirection.Out);
		local TabColorInfo = NewTweenInfo(0.15, Enum.EasingStyle.Linear);
		local FadeConn;
		local BasePos = NewUdim2(0, 10, 0, 31);
		local OffPos = NewUdim2(0, 10, 0, 31 + 8);
		function tab:SetActive(active)
			if self.Active == active then return end;
			self.Active = active;
			if FadeConn then FadeConn:Disconnect(); FadeConn = nil; end;
			local ContentRef = self.Content;
			if active then
				local LabelRef = self.Label;
				local ColorTween = Library:Tween(LabelRef, TabColorInfo, { TextColor3 = Library.AccentColor or hex("98BCFF") });
				ColorTween:Play();
				ColorTween.Completed:Once(function()
					LabelRef.TextColor3 = Library.AccentColor or hex("98BCFF");
				end);
				ContentRef.Position = OffPos;
				ContentRef.Visible = true;
				task.defer(function()
					Library:RefreshSettings();
					self:RefreshCanvases();
				end);
				task.delay(0.05, function()
					Library:RefreshSettings();
					self:RefreshCanvases();
				end);
				local StartT = tick();
				local duration = 0.22;
				FadeConn = RunService.RenderStepped:Connect(function()
					local p = MathClamp((tick() - StartT) / duration, 0, 1);
					local e = 1 - (1 - p) * (1 - p);
					ContentRef.Position = NewUdim2(0, 10, 0, 31 + MathFloor(8 * (1 - e) + 0.5));
					if p >= 1 then
						if FadeConn then FadeConn:Disconnect(); FadeConn = nil; end;
					end;
				end);
			else
				Library:Tween(self.Label, TabColorInfo, { TextColor3 = hex("8A8A92") }):Play();
				ContentRef.Visible = false;
				ContentRef.Position = BasePos;
			end;
		end;

		Library:Connection(TabButton.MouseButton1Down, function()
			window:SetActiveTab(tab);
		end);
		Library:Connection(TabButton.MouseEnter, function()
			if not tab.Active then
				Library:Tween(TabLabel, TabColorInfo, { TextColor3 = FromRgb(255, 255, 255) }):Play();
			end;
		end);
		Library:Connection(TabButton.MouseLeave, function()
			if not tab.Active then
				Library:Tween(TabLabel, TabColorInfo, { TextColor3 = hex("8A8A92") }):Play();
			end;
		end);

		function tab:Section(SectionName, side)
			local Host = self;
			local col = (side == "Right" or side == "right") and self.RightCol or self.LeftCol;
			local SectionNames = typeof(SectionName) == "table" and SectionName or { SectionName };
			local IsMulti = #SectionNames > 1;
			local PrimaryName = tostring(SectionNames[1] or "Section");
			local SectionOuter = Library:CreateInstance("Frame", {
				Name = "Section_" .. PrimaryName;
				Parent = col;
				Size = NewUdim2(1, 0, 0, 0);
				AutomaticSize = Enum.AutomaticSize.Y;
				BackgroundColor3 = hex("24262D");
				BorderSizePixel = 0;
				LayoutOrder = #self.Sections + 1;
				ZIndex = 2;
			});

			local SectionBody = Library:CreateInstance("Frame", {
				Name = "Body";
				Parent = SectionOuter;
				Position = NewUdim2(0, 1, 0, 1);
				Size = NewUdim2(1, -2, 0, 0);
				AutomaticSize = Enum.AutomaticSize.Y;
				BackgroundColor3 = FromRgb(255, 255, 255);
				BorderSizePixel = 0;
				ZIndex = 2;
			});
			Library:CreateInstance("UIGradient", {
				Parent = SectionBody; Rotation = 90;
				Color = NewColorSequence(hex("131418"), hex("17181D"));
			});

			Library:CreateInstance("Frame", {
				Name = "TopAccent";
				Parent = SectionBody;
				Position = NewUdim2(0, 0, 0, 0);
				Size = NewUdim2(1, 0, 0, 1);
				BackgroundColor3 = hex("98BCFF");
				BorderSizePixel = 0;
				ZIndex = 3;
			});
			Library:CreateInstance("Frame", {
				Name = "TopAccentShade";
				Parent = SectionBody;
				Position = NewUdim2(0, 0, 0, 1);
				Size = NewUdim2(1, 0, 0, 1);
				BackgroundColor3 = hex("6E8CC8");
				BorderSizePixel = 0;
				ZIndex = 3;
			});
			Library:CreateInstance("Frame", {
				Name = "BottomBorder";
				Parent = SectionBody;
				AnchorPoint = NewVector2(0, 1);
				Position = NewUdim2(0, 0, 1, 0);
				Size = NewUdim2(1, 0, 0, 1);
				BackgroundColor3 = hex("24262D");
				BorderSizePixel = 0;
				ZIndex = 4;
			});

			local TitleButtons = {};
			local SubContents = {};
			local ActiveSubIdx = 1;

			local function MakeContent()
				local content = Library:CreateInstance("Frame", {
					Name = "Content";
					Parent = SectionBody;
					Position = NewUdim2(0, 0, 0, 22);
					Size = NewUdim2(1, 0, 0, 0);
					AutomaticSize = Enum.AutomaticSize.Y;
					BackgroundTransparency = 1;
					BorderSizePixel = 0;
					ZIndex = 2;
				});
				Library:CreateInstance("UIPadding", {
					Parent = content;
					PaddingTop = NewUdim(0, 4);
					PaddingBottom = NewUdim(0, 8);
					PaddingLeft = NewUdim(0, 10);
					PaddingRight = NewUdim(0, 10);
				});
				Library:CreateInstance("UIListLayout", {
					Parent = content;
					FillDirection = Enum.FillDirection.Vertical;
					SortOrder = Enum.SortOrder.LayoutOrder;
					Padding = NewUdim(0, 6);
				});
				return content;
			end;

			if IsMulti then
				local TitlesRow = Library:CreateInstance("Frame", {
					Name = "TitlesRow";
					Parent = SectionBody;
					Position = NewUdim2(0, 6, 0, 7);
					Size = NewUdim2(0, 0, 0, 12);
					AutomaticSize = Enum.AutomaticSize.X;
					BackgroundTransparency = 1;
					BorderSizePixel = 0;
					ZIndex = 4;
				});
				Library:CreateInstance("UIPadding", {
					Parent = TitlesRow;
					PaddingLeft = NewUdim(0, 4);
					PaddingRight = NewUdim(0, 4);
				});
				Library:CreateInstance("UIListLayout", {
					Parent = TitlesRow;
					FillDirection = Enum.FillDirection.Horizontal;
					SortOrder = Enum.SortOrder.LayoutOrder;
					Padding = NewUdim(0, 10);
				});

				for i, sn in SectionNames do
					local ContentI = MakeContent();
					ContentI.Visible = (i == 1);
					SubContents[i] = ContentI;

					local lbl = Library:CreateInstance("TextLabel", {
						Name = "Title_" .. tostring(sn);
						Parent = TitlesRow;
						Position = NewUdim2(0, 0, 0, 0);
						Size = NewUdim2(0, 0, 0, 12);
						AutomaticSize = Enum.AutomaticSize.X;
						BackgroundTransparency = 1;
						FontFace = Library.Fonts.title;
						Text = tostring(sn);
						TextColor3 = (i == 1) and FromRgb(255, 255, 255) or FromRgb(140, 140, 140);
						TextSize = 9;
						LayoutOrder = i;
						ZIndex = 5;
					});
					local hit = Library:CreateInstance("TextButton", {
						Name = "Hit"; Parent = lbl;
						Size = NewUdim2(1, 0, 1, 0);
						BackgroundTransparency = 1; AutoButtonColor = false; Text = "";
						ZIndex = 6;
					});
					TitleButtons[i] = lbl;

				Library:Connection(hit.MouseButton1Click, function()
					if ActiveSubIdx == i then return end;
					SubContents[ActiveSubIdx].Visible = false;
					TitleButtons[ActiveSubIdx].TextColor3 = FromRgb(140, 140, 140);
					ActiveSubIdx = i;
					SubContents[i].Visible = true;
					lbl.TextColor3 = FromRgb(255, 255, 255);
					task.defer(function()
						local layout = col:FindFirstChildOfClass("UIListLayout");
						if layout then
							col.CanvasSize = NewUdim2(0, 0, 0, layout.AbsoluteContentSize.Y + 16);
						end;
					end);
				end);
				end;
			else
				local title = Library:CreateInstance("TextLabel", {
					Name = "Title";
					Parent = SectionBody;
					Position = NewUdim2(0, 6, 0, 7);
					Size = NewUdim2(0, 0, 0, 12);
					AutomaticSize = Enum.AutomaticSize.X;
					BackgroundTransparency = 1;
					BorderSizePixel = 0;
					FontFace = Library.Fonts.title;
					Text = PrimaryName;
					TextColor3 = FromRgb(255, 255, 255);
					TextSize = 9;
					TextXAlignment = Enum.TextXAlignment.Left;
					TextYAlignment = Enum.TextYAlignment.Center;
					ZIndex = 4;
				});
				Library:CreateInstance("UIPadding", {
					Parent = title;
					PaddingLeft = NewUdim(0, 4);
					PaddingRight = NewUdim(0, 4);
				});
				SubContents[1] = MakeContent();
			end;

			local SectionContent = SubContents[1];
			local SectionObj = { Outer = SectionOuter, Body = SectionBody, Content = SectionContent, Name = PrimaryName };

			function SectionObj:Settings(Match)
				local SettingsRow = Library:CreateInstance("Frame", {
					Name = "Settings_" .. tostring(Match or self.Name);
					Parent = self.Content;
					Size = NewUdim2(1, 0, 0, 0);
					BackgroundTransparency = 1;
					BorderSizePixel = 0;
					ClipsDescendants = true;
					Visible = false;
					ZIndex = 2;
				});

				local Rail = Library:CreateInstance("Frame", {
					Name = "Rail";
					Parent = SettingsRow;
					Position = NewUdim2(0, 5, 0, 0);
					Size = NewUdim2(0, 1, 0, 0);
					BackgroundColor3 = hex("3A3D45");
					BorderSizePixel = 0;
					ZIndex = 2;
				});
				Library:CreateInstance("Frame", {
					Name = "RailEnd";
					Parent = Rail;
					AnchorPoint = NewVector2(0.5, 1);
					Position = NewUdim2(0.5, 0, 1, 0);
					Size = FromOffset(3, 3);
					BackgroundColor3 = hex("3A3D45");
					BorderSizePixel = 0;
					ZIndex = 2;
				});

				local Content = Library:CreateInstance("Frame", {
					Name = "Content";
					Parent = SettingsRow;
					Position = NewUdim2(0, 18, 0, 0);
					Size = NewUdim2(1, -18, 0, 0);
					AutomaticSize = Enum.AutomaticSize.Y;
					BackgroundTransparency = 1;
					BorderSizePixel = 0;
					ZIndex = 2;
				});

				local Layout = Library:CreateInstance("UIListLayout", {
					Parent = Content;
					FillDirection = Enum.FillDirection.Vertical;
					SortOrder = Enum.SortOrder.LayoutOrder;
					Padding = NewUdim(0, 4);
				});
				Library:CreateInstance("UIPadding", {
					Parent = Content;
					PaddingTop = NewUdim(0, 2);
					PaddingBottom = NewUdim(0, 2);
				});

				local SettingsTween = NewTweenInfo(0.16, Enum.EasingStyle.Quad, Enum.EasingDirection.Out);
				local Settings = {
					Row = SettingsRow;
					Content = Content;
					Match = Match;
					Open = false;
					Animating = false;
				};
				insert(Library.SettingsRegistry, Settings);

				function Settings:Check()
					if self.Match == nil then return true end;
					if typeof(self.Match) == "function" then
						local Ok, Result = pcall(self.Match, Library.Flags);
						return Ok and Result == true;
					elseif typeof(self.Match) == "table" then
						for _, Flag in self.Match do
							if Library.Flags[Flag] == true then return true end;
						end;
						return false;
					end;
					return Library.Flags[self.Match] == true;
				end;

				function Settings:SetOpen(Bool)
					Bool = Bool == true;
					self.Open = Bool;
					self.Animating = true;
					if Bool then SettingsRow.Visible = true end;
					local Scale = Library:ComputeUIScale();
					local Height = Bool and ((Layout.AbsoluteContentSize.Y + 2) / Scale + 4) or 0;
					Library:Tween(SettingsRow, SettingsTween, { Size = NewUdim2(1, 0, 0, Height) }):Play();
					Library:Tween(Content, SettingsTween, { Size = NewUdim2(1, -18, 0, Height) }):Play();
					local RailTween = Library:Tween(Rail, SettingsTween, { Size = NewUdim2(0, 1, 0, Height) });
					RailTween:Play();
					RailTween.Completed:Once(function()
						self.Animating = false;
						if self.Open and SettingsRow and SettingsRow.Parent then
							local NewHeight = (Layout.AbsoluteContentSize.Y + 2) / Library:ComputeUIScale() + 4;
							SettingsRow.Size = NewUdim2(1, 0, 0, NewHeight);
							Content.Size = NewUdim2(1, -18, 0, NewHeight);
							Rail.Size = NewUdim2(0, 1, 0, NewHeight);
						end;
						if Host and Host.RefreshCanvases then Host:RefreshCanvases() end;
					end);
					if Host and Host.RefreshCanvases then task.defer(function() Host:RefreshCanvases() end) end;
					if not Bool then
						task.delay(0.16, function()
							if not self.Open and SettingsRow and SettingsRow.Parent then
								SettingsRow.Visible = false;
							end;
						end);
					end;
				end;

				function Settings:Refresh()
					self:SetOpen(self:Check());
				end;

				Library:Connection(Layout:GetPropertyChangedSignal("AbsoluteContentSize"), function()
					if Settings.Open and not Settings.Animating then
						local Height = (Layout.AbsoluteContentSize.Y + 2) / Library:ComputeUIScale() + 4;
						SettingsRow.Size = NewUdim2(1, 0, 0, Height);
						Content.Size = NewUdim2(1, -18, 0, Height);
						Rail.Size = NewUdim2(0, 1, 0, Height);
						if Host and Host.RefreshCanvases then task.defer(function() Host:RefreshCanvases() end) end;
					end;
				end);

				for Name, Method in SectionObj do
					if typeof(Method) == "function" then
						Settings[Name] = Method;
					end;
				end;

				if typeof(Match) == "string" then
					Library.FlagSettings = Library.FlagSettings or {};
					Library.FlagSettings[Match] = Library.FlagSettings[Match] or {};
					insert(Library.FlagSettings[Match], Settings);
				elseif typeof(Match) == "table" then
					Library.FlagSettings = Library.FlagSettings or {};
					for _, Flag in Match do
						if typeof(Flag) == "string" then
							Library.FlagSettings[Flag] = Library.FlagSettings[Flag] or {};
							insert(Library.FlagSettings[Flag], Settings);
						end;
					end;
				end;

				Settings:Refresh();
				return Settings;
			end;

			function SectionObj:Toggle(Data, default, callback, FlagOpt)
				if typeof(Data) ~= "table" then
					Data = { Name = Data, Default = default, Callback = callback, Flag = FlagOpt };
				end;
				local ToggleName = Data.Name or Data.name or "Toggle";
				default = Data.Default;
				if default == nil then default = Data.default end;
				callback = Data.Callback or Data.callback;
				FlagOpt = Data.Flag or Data.flag;
				local Tooltip = Data.Tooltip or Data.tooltip;
				local Risky = Data.Risky == true or Data.risky == true;
				local flag = Library:AutoFlag(FlagOpt or ToggleName);
				local row = Library:CreateInstance("Frame", {
					Name = "Toggle_" .. ToggleName;
					Parent = self.Content;
					Size = NewUdim2(1, 0, 0, 12);
					BackgroundTransparency = 1;
					BorderSizePixel = 0;
					ZIndex = 2;
				});

				local BoxOutline = Library:CreateInstance("Frame", {
					Name = "Box";
					Parent = row;
					AnchorPoint = NewVector2(0, 0.5);
					Position = NewUdim2(0, 0, 0.5, 0);
					Size = NewUdim2(0, 12, 0, 12);
					BackgroundColor3 = hex("24262D");
					BorderSizePixel = 0;
					ZIndex = 2;
				});

				local BoxBody = Library:CreateInstance("Frame", {
					Name = "Body";
					Parent = BoxOutline;
					Position = NewUdim2(0, 1, 0, 1);
					Size = NewUdim2(1, -2, 1, -2);
					BackgroundColor3 = hex("1C1D23");
					BorderSizePixel = 0;
					ZIndex = 3;
				});

				local BoxFill = Library:CreateInstance("Frame", {
					Name = "Fill";
					Parent = BoxBody;
					Size = NewUdim2(1, 0, 1, 0);
					BackgroundColor3 = FromRgb(255, 255, 255);
					BackgroundTransparency = 1;
					BorderSizePixel = 0;
					ZIndex = 4;
				});
				Library:CreateInstance("UIGradient", {
					Parent = BoxFill;
					Rotation = 90;
					Color = NewColorSequence(hex("94B7F8"), hex("6B84B3"));
				});

				local label = Library:CreateInstance("TextLabel", {
					Name = "Label";
					Parent = row;
					AnchorPoint = NewVector2(0, 0.5);
					Position = NewUdim2(0, 18, 0.5, -1);
					Size = NewUdim2(1, -18, 1, 0);
					BackgroundTransparency = 1;
					FontFace = Library.Fonts.title;
					Text = tostring(ToggleName);
					TextColor3 = FromRgb(255, 255, 255);
					TextSize = 9;
					TextXAlignment = Enum.TextXAlignment.Left;
					TextYAlignment = Enum.TextYAlignment.Center;
					TextTruncate = Enum.TextTruncate.AtEnd;
					ZIndex = 3;
				});

				local hit = Library:CreateInstance("TextButton", {
					Name = "Hit";
					Parent = row;
					Size = NewUdim2(1, 0, 1, 0);
					BackgroundTransparency = 1;
					AutoButtonColor = false;
					Text = "";
					ZIndex = 5;
				});

				local state = default == true;
				BoxFill.BackgroundTransparency = state and 0 or 1;
				label.TextColor3 = state and (Library.AccentColor or hex("98BCFF")) or hex("646464");

				local Toggle = {
					Row = row;
					Box = BoxOutline;
					Body = BoxBody;
					Fill = BoxFill;
					Label = label;
					Name = ToggleName;
					Flag = flag;
					State = state;
					RightOffset = 0;
					SettingsParentContent = self.Content;
				};

				Library.ToggleRegistry = Library.ToggleRegistry or {};
				Library.ToggleByFlag = Library.ToggleByFlag or {};
				if not Library.ToggleByFlag[flag] then
					Library.ToggleByFlag[flag] = ToggleName;
					insert(Library.ToggleRegistry, { Name = ToggleName, Flag = flag });
				end;

				local ToggleTween = NewTweenInfo(0.15, Enum.EasingStyle.Quad, Enum.EasingDirection.Out);
				function Toggle:Set(v)
					v = v == true;
					if self.State == v then
						Library.Flags[self.Flag] = v;
						if self.SettingsItem then self.SettingsItem:Refresh() end;
						if Library.FlagSettings and Library.FlagSettings[self.Flag] then
							for _, Settings in Library.FlagSettings[self.Flag] do
								if Settings and Settings.Refresh then Settings:Refresh() end;
							end;
						end;
						return;
					end;
					self.State = v;
					Library.Flags[self.Flag] = v;
					if Library.FlagSettings and Library.FlagSettings[self.Flag] then
						for _, Settings in Library.FlagSettings[self.Flag] do
							if Settings and Settings.Refresh then Settings:Refresh() end;
						end;
					end;
					Library:Tween(self.Fill, ToggleTween, { BackgroundTransparency = v and 0 or 1 }):Play();
					local LabelRef = self.Label;
					local LabelTween = Library:Tween(LabelRef, ToggleTween, { TextColor3 = v and (Library.AccentColor or hex("98BCFF")) or hex("646464") });
					LabelTween:Play();
					LabelTween.Completed:Once(function()
						if LabelRef and LabelRef.Parent then
							LabelRef.TextColor3 = self.State and (Library.AccentColor or hex("98BCFF")) or hex("646464");
						end;
					end);
					if self.SubKeybinds then
						for _, kb in self.SubKeybinds do
							kb.Active = v;
							Library:UpdateKeybind(kb);
						end;
					end;
					if self.SettingsItem then
						self.SettingsItem:SetOpen(v);
					end;
					if typeof(callback) == "function" then callback(v) end;
				end;
				Library:RegisterFlag(flag, state, function(v) Toggle:Set(v) end);

				function Toggle:Get() return self.State end;
				if Tooltip then
					Library:Tooltip(label, { Title = ToggleName; Text = Tooltip });
				end;
				if Risky then
					Library:Risky(row);
				end;

				local RiskyClick = Library:ConfirmClick(label, function()
					Toggle:Set(not Toggle.State);
				end);
				Library:Connection(hit.MouseButton1Click, function()
					if Risky and not Toggle.State then
						RiskyClick();
					else
						Toggle:Set(not Toggle.State);
					end;
				end);
				Library:Connection(hit.MouseButton2Click, function()
					if not Toggle.SubKeybinds or #Toggle.SubKeybinds == 0 then return end;
					Library:ModePopup(BoxOutline, Toggle.Mode or "Toggle", function(m)
						Toggle.Mode = m;
						for _, kb in Toggle.SubKeybinds do
							kb:SetMode(m);
						end;
					end);
				end);

				function Toggle:Colorpicker(PickerName, DefaultColor, DefaultAlpha, sub_callback, SubFlagOpt)
					if typeof(PickerName) == "table" then
						local Data = PickerName;
						PickerName = Data.Name or Data.name or "Colorpicker";
						DefaultColor = Data.Default or Data.default;
						DefaultAlpha = Data.Alpha or Data.alpha;
						sub_callback = Data.Callback or Data.callback;
						SubFlagOpt = Data.Flag or Data.flag;
					end;
					local cp = BuildSubColorpicker(self.Row, PickerName, DefaultColor, DefaultAlpha, sub_callback, SubFlagOpt, self.RightOffset);
					self.RightOffset = self.RightOffset - 26;
					return cp;
				end;
				function Toggle:Keybind(KeybindName, DefaultKey, sub_callback, SubFlagOpt)
					local Mode;
					if typeof(KeybindName) == "table" then
						local Data = KeybindName;
						KeybindName = Data.Name or Data.name or "Keybind";
						DefaultKey = Data.Default or Data.default;
						sub_callback = Data.Callback or Data.callback;
						SubFlagOpt = Data.Flag or Data.flag;
						Mode = Data.Mode or Data.mode;
					end;
					local ToggleRef = self;
					local kb = BuildSubKeybind(self.Row, KeybindName, DefaultKey, function(active, key)
						ToggleRef:Set(active);
						if typeof(sub_callback) == "function" then sub_callback(active, key) end;
					end, SubFlagOpt, self.RightOffset);
					self.RightOffset = self.RightOffset - 38;
					kb.Active = self.State;
					if Mode then kb:SetMode(Mode)
					elseif self.Mode then kb:SetMode(self.Mode) end;
					Library:UpdateKeybind(kb);
					if not self.SubKeybinds then self.SubKeybinds = {} end;
					insert(self.SubKeybinds, kb);
					return kb;
				end;

				function Toggle:Settings()
					if self.SettingsItem then return self.SettingsItem end;

					local SettingsRow = Library:CreateInstance("Frame", {
						Name = "Settings_" .. tostring(self.Name);
						Parent = self.SettingsParentContent or SectionObj.Content;
						Size = NewUdim2(1, 0, 0, 0);
						BackgroundTransparency = 1;
						BorderSizePixel = 0;
						ClipsDescendants = true;
						Visible = false;
						ZIndex = 2;
					});

					local Rail = Library:CreateInstance("Frame", {
						Name = "Rail";
						Parent = SettingsRow;
						Position = NewUdim2(0, 5, 0, 0);
						Size = NewUdim2(0, 1, 0, 0);
						BackgroundColor3 = hex("3A3D45");
						BorderSizePixel = 0;
						ZIndex = 2;
					});
					Library:CreateInstance("Frame", {
						Name = "RailEnd";
						Parent = Rail;
						AnchorPoint = NewVector2(0.5, 1);
						Position = NewUdim2(0.5, 0, 1, 0);
						Size = FromOffset(3, 3);
						BackgroundColor3 = hex("3A3D45");
						BorderSizePixel = 0;
						ZIndex = 2;
					});

					local Content = Library:CreateInstance("Frame", {
						Name = "Content";
						Parent = SettingsRow;
						Position = NewUdim2(0, 18, 0, 0);
						Size = NewUdim2(1, -18, 0, 0);
						AutomaticSize = Enum.AutomaticSize.Y;
						BackgroundTransparency = 1;
						BorderSizePixel = 0;
						ZIndex = 2;
					});

					local Layout = Library:CreateInstance("UIListLayout", {
						Parent = Content;
						FillDirection = Enum.FillDirection.Vertical;
						SortOrder = Enum.SortOrder.LayoutOrder;
						Padding = NewUdim(0, 4);
					});
					Library:CreateInstance("UIPadding", {
						Parent = Content;
						PaddingTop = NewUdim(0, 2);
						PaddingBottom = NewUdim(0, 2);
					});

					local SettingsTween = NewTweenInfo(0.16, Enum.EasingStyle.Quad, Enum.EasingDirection.Out);
					local Settings = {
						Row = SettingsRow;
						Content = Content;
						ParentToggle = self;
						Open = false;
						Animating = false;
					};
					insert(Library.SettingsRegistry, Settings);

					function Settings:SetOpen(Bool)
						Bool = Bool == true;
						self.Open = Bool;
						self.Animating = true;
						if Bool then SettingsRow.Visible = true end;
						local Scale = Library:ComputeUIScale();
					local Height = Bool and ((Layout.AbsoluteContentSize.Y + 2) / Scale + 4) or 0;
						Library:Tween(SettingsRow, SettingsTween, { Size = NewUdim2(1, 0, 0, Height) }):Play();
						Library:Tween(Content, SettingsTween, { Size = NewUdim2(1, -18, 0, Height) }):Play();
						local RailTween = Library:Tween(Rail, SettingsTween, { Size = NewUdim2(0, 1, 0, Height) });
						RailTween:Play();
						RailTween.Completed:Once(function()
							self.Animating = false;
							if self.Open and SettingsRow and SettingsRow.Parent then
								local NewHeight = (Layout.AbsoluteContentSize.Y + 2) / Library:ComputeUIScale() + 4;
								SettingsRow.Size = NewUdim2(1, 0, 0, NewHeight);
								Content.Size = NewUdim2(1, -18, 0, NewHeight);
								Rail.Size = NewUdim2(0, 1, 0, NewHeight);
							end;
							if Host and Host.RefreshCanvases then Host:RefreshCanvases() end;
						end);
						if Host and Host.RefreshCanvases then task.defer(function() Host:RefreshCanvases() end) end;
						if not Bool then
							task.delay(0.16, function()
								if not self.Open and SettingsRow and SettingsRow.Parent then
									SettingsRow.Visible = false;
								end;
							end);
						end;
					end;

					function Settings:Refresh()
						self:SetOpen(self.ParentToggle and self.ParentToggle.State == true);
					end;

					Library:Connection(Layout:GetPropertyChangedSignal("AbsoluteContentSize"), function()
						if Settings.Open and not Settings.Animating then
							local Height = (Layout.AbsoluteContentSize.Y + 2) / Library:ComputeUIScale() + 4;
							SettingsRow.Size = NewUdim2(1, 0, 0, Height);
							Content.Size = NewUdim2(1, -18, 0, Height);
							Rail.Size = NewUdim2(0, 1, 0, Height);
							if Host and Host.RefreshCanvases then task.defer(function() Host:RefreshCanvases() end) end;
						end;
					end);

					for Name, Method in SectionObj do
						if typeof(Method) == "function" then
							Settings[Name] = Method;
						end;
					end;

					self.SettingsItem = Settings;
					Settings:SetOpen(self.State);
					return Settings;
				end;

				return Toggle;
			end;

			local function MakeButtonVisual(parent, ButtonSize, ButtonName, ButtonCallback, ButtonOrder, ConfirmNeeded)
				local BtnOuter = Library:CreateInstance("Frame", {
					Name = "Button_" .. ButtonName;
					Parent = parent;
					Size = ButtonSize;
					BackgroundColor3 = hex("07080A");
					BorderSizePixel = 0;
					LayoutOrder = ButtonOrder;
					ZIndex = 2;
				});

				local BtnInner = Library:CreateInstance("Frame", {
					Name = "Inner";
					Parent = BtnOuter;
					Position = NewUdim2(0, 1, 0, 1);
					Size = NewUdim2(1, -2, 1, -2);
					BackgroundColor3 = hex("24262D");
					BorderSizePixel = 0;
					ZIndex = 3;
				});

				local BtnBody = Library:CreateInstance("Frame", {
					Name = "Body";
					Parent = BtnInner;
					Position = NewUdim2(0, 1, 0, 1);
					Size = NewUdim2(1, -2, 1, -2);
					BackgroundColor3 = FromRgb(255, 255, 255);
					BorderSizePixel = 0;
					ZIndex = 4;
				});
				Library:CreateInstance("UIGradient", {
					Parent = BtnBody;
					Rotation = 90;
					Color = NewColorSequence(hex("131418"), hex("17181D"));
				});

				local BtnLabel = Library:CreateInstance("TextLabel", {
					Name = "Label";
					Parent = BtnBody;
					Size = NewUdim2(1, 0, 1, 0);
					BackgroundTransparency = 1;
					FontFace = Library.Fonts.title;
					Text = tostring(ButtonName);
					TextColor3 = hex("B4B4B4");
					TextSize = 9;
					TextXAlignment = Enum.TextXAlignment.Center;
					TextYAlignment = Enum.TextYAlignment.Center;
					ZIndex = 5;
				});

				local BtnScale = Library:CreateInstance("UIScale", {
					Parent = BtnOuter;
					Scale = 1;
				});

				local hit = Library:CreateInstance("TextButton", {
					Name = "Hit";
					Parent = BtnOuter;
					Size = NewUdim2(1, 0, 1, 0);
					BackgroundTransparency = 1;
					AutoButtonColor = false;
					Text = "";
					ZIndex = 6;
				});

				local PressIn = NewTweenInfo(0.08, Enum.EasingStyle.Quad, Enum.EasingDirection.Out);
				local PressOut = NewTweenInfo(0.16, Enum.EasingStyle.Back, Enum.EasingDirection.Out);
				Library:Connection(hit.MouseButton1Down, function()
					Library:Tween(BtnScale, PressIn, { Scale = 0.94 }):Play();
				end);
				Library:Connection(hit.MouseButton1Up, function()
					Library:Tween(BtnScale, PressOut, { Scale = 1 }):Play();
				end);
				Library:Connection(hit.MouseLeave, function()
					Library:Tween(BtnScale, PressOut, { Scale = 1 }):Play();
				end);

				if typeof(ButtonCallback) == "function" then
					local handler = ConfirmNeeded and Library:ConfirmClick(BtnLabel, ButtonCallback) or ButtonCallback;
					Library:Connection(hit.MouseButton1Click, handler);
				end;

				return { outer = BtnOuter, inner = BtnInner, body = BtnBody, label = BtnLabel, hit = hit, name = ButtonName };
			end;

			function SectionObj:Button(Data, callback, opts)
				local ButtonName;
				if typeof(Data) == "table" then
					ButtonName = Data.Name or Data.name or "Button";
					callback = Data.Callback or Data.callback;
					opts = Data;
				else
					ButtonName = Data or "Button";
				end;
				opts = typeof(opts) == "table" and opts or {};
				local Tooltip = opts.Tooltip or opts.tooltip;
				local ConfirmNeeded = opts.ConfirmNeeded == true or opts.confirm_needed == true or opts.Risky == true or opts.risky == true;
				local row = Library:CreateInstance("Frame", {
					Name = "ButtonRow_" .. ButtonName;
					Parent = self.Content;
					Size = NewUdim2(1, 0, 0, 22);
					BackgroundTransparency = 1;
					BorderSizePixel = 0;
					ZIndex = 2;
				});
				local Button = MakeButtonVisual(row, NewUdim2(1, 0, 1, 0), ButtonName, callback, 1, ConfirmNeeded);
				if Tooltip then Library:Tooltip(Button.label, { Title = ButtonName; Text = Tooltip }) end;
				if ConfirmNeeded then Library:Risky(row) end;
				return Button;
			end;

			function SectionObj:MultiButton(buttons)
				buttons = typeof(buttons) == "table" and buttons or {};
				local n = #buttons;
				local row = Library:CreateInstance("Frame", {
					Name = "MultiButtonRow";
					Parent = self.Content;
					Size = NewUdim2(1, 0, 0, 22);
					BackgroundTransparency = 1;
					BorderSizePixel = 0;
					ZIndex = 2;
				});
				Library:CreateInstance("UIListLayout", {
					Parent = row;
					FillDirection = Enum.FillDirection.Horizontal;
					SortOrder = Enum.SortOrder.LayoutOrder;
					Padding = NewUdim(0, 4);
				});
				local out = {};
				local TotalGap = 4 * (n - 1);
				local size = NewUdim2(1 / n, MathFloor(-TotalGap / n), 1, 0);
				for i, def in buttons do
					local BtnName = tostring(def[1] or def.name or def.Name or "Button");
					local RawCb = def[2] or def.callback or def.Callback;
					local BtnCb = typeof(RawCb) == "function" and function() RawCb() end or nil;
					local ConfirmNeeded = def.ConfirmNeeded == true or def.confirm_needed == true or def.Risky == true or def.risky == true;
					out[i] = MakeButtonVisual(row, size, BtnName, BtnCb, i, ConfirmNeeded);
					if def.Tooltip or def.tooltip then Library:Tooltip(out[i].label, { Title = BtnName; Text = def.Tooltip or def.tooltip }) end;
					if ConfirmNeeded then Library:Risky(out[i].outer) end;
				end;
				return out;
			end;

			function SectionObj:Label(Data)
				if typeof(Data) ~= "table" then
					Data = { Text = tostring(Data or "") };
				end;
				local Text = tostring(Data.Text or Data.text or Data.Name or Data.name or "");
				local Tooltip = Data.Tooltip or Data.tooltip;
				local Height = tonumber(Data.Height or Data.height) or 14;
				local row = Library:CreateInstance("Frame", {
					Name = "LabelRow";
					Parent = self.Content;
					Size = NewUdim2(1, 0, 0, Height);
					BackgroundTransparency = 1;
					BorderSizePixel = 0;
					ZIndex = 2;
				});
				local Label = Library:CreateInstance("TextLabel", {
					Name = "Label";
					Parent = row;
					Size = NewUdim2(1, 0, 1, 0);
					BackgroundTransparency = 1;
					FontFace = Library.Fonts.title;
					Text = Text;
					TextColor3 = Data.Color or hex("B4B4B4");
					TextSize = tonumber(Data.TextSize or Data.textSize) or 11;
					TextWrapped = Data.Wrapped == true or Data.wrapped == true;
					TextXAlignment = Enum.TextXAlignment.Left;
					TextYAlignment = Enum.TextYAlignment.Center;
					ZIndex = 3;
				});
				if Tooltip then Library:Tooltip(Label, { Title = Text; Text = Tooltip }) end;
				return { Row = row; Label = Label };
			end;

			function SectionObj:ImageLabel(Data)
				if typeof(Data) ~= "table" then
					Data = { Name = tostring(Data or "") };
				end;
				local Name = tostring(Data.Name or Data.name or "");
				local Image = tostring(Data.Image or Data.image or "");
				local Callback = Data.Callback or Data.callback;
				local Ratio = tonumber(Data.Ratio or Data.ratio) or 1;

				local row = Library:CreateInstance("Frame", {
					Name = "ImageLabelRow_" .. Name;
					Parent = self.Content;
					Size = NewUdim2(1, 0, 0, 0);
					AutomaticSize = Enum.AutomaticSize.Y;
					BackgroundTransparency = 1;
					BorderSizePixel = 0;
					ClipsDescendants = false;
					ZIndex = 2;
				});

				Library:CreateInstance("TextLabel", {
					Name = "Label";
					Parent = row;
					Size = NewUdim2(1, 0, 0, 12);
					BackgroundTransparency = 1;
					FontFace = Library.Fonts.title;
					Text = Name;
					TextColor3 = hex("B4B4B4");
					TextSize = 9;
					TextXAlignment = Enum.TextXAlignment.Left;
					TextYAlignment = Enum.TextYAlignment.Top;
					ZIndex = 2;
				});

				local ImgContainer = Library:CreateInstance("Frame", {
					Name = "ImageContainer";
					Parent = row;
					Position = NewUdim2(0, 0, 0, 14);
					Size = NewUdim2(1, 0, 0, 100);
					BackgroundTransparency = 1;
					BorderSizePixel = 0;
					ZIndex = 2;
				});

				local Img = Library:CreateInstance("ImageLabel", {
					Name = "Image";
					Parent = ImgContainer;
					Size = NewUdim2(1, 0, 1, 0);
					Position = NewUdim2(0, 0, 0, 0);
					BackgroundTransparency = 1;
					BorderSizePixel = 0;
					Image = Image;
					ScaleType = Enum.ScaleType.Fit;
					ZIndex = 2;
				});

				task.defer(function()
					RunService.Heartbeat:Wait();
					local w = row.AbsoluteSize.X;
					if w > 0 then
						ImgContainer.Size = NewUdim2(1, 0, 0, w * Ratio);
						if Host and Host.RefreshCanvases then task.defer(function() Host:RefreshCanvases() end) end;
					end;
				end);
				Library:Connection(row:GetPropertyChangedSignal("AbsoluteSize"), function()
					local w = row.AbsoluteSize.X;
					if w > 0 then
						ImgContainer.Size = NewUdim2(1, 0, 0, w * Ratio);
						if Host and Host.RefreshCanvases then task.defer(function() Host:RefreshCanvases() end) end;
					end;
				end);

				local Obj = {
					Row = row;
					ImageLabel = Img;
					SetImage = function(newImage)
						Img.Image = newImage;
						if typeof(Callback) == "function" then
							pcall(Callback, newImage);
						end;
					end;
				};

				return Obj;
			end;
			function SectionObj:Preview(Data)
				if typeof(Data) ~= "table" then
					Data = { Name = tostring(Data or "") };
				end;
				local Name = tostring(Data.Name or Data.name or "");
				local Ratio = tonumber(Data.Ratio or Data.ratio) or 0.5;

				local row = Library:CreateInstance("Frame", {
					Name = "PreviewRow_" .. Name;
					Parent = self.Content;
					Size = NewUdim2(1, 0, 0, 0);
					AutomaticSize = Enum.AutomaticSize.Y;
					BackgroundTransparency = 1;
					BorderSizePixel = 0;
					ClipsDescendants = false;
					ZIndex = 2;
				});

				local topOffset = 0;
				if Name ~= "" then
					Library:CreateInstance("TextLabel", {
						Name = "Label";
						Parent = row;
						Size = NewUdim2(1, 0, 0, 12);
						BackgroundTransparency = 1;
						FontFace = Library.Fonts.title;
						Text = Name;
						TextColor3 = hex("B4B4B4");
						TextSize = 9;
						TextXAlignment = Enum.TextXAlignment.Left;
						TextYAlignment = Enum.TextYAlignment.Top;
						ZIndex = 2;
					});
					topOffset = 14;
				end;

				local Container = Library:CreateInstance("Frame", {
					Name = "PreviewContainer";
					Parent = row;
					Position = NewUdim2(0, 0, 0, topOffset);
					Size = NewUdim2(1, 0, 0, 100);
					BackgroundColor3 = hex("101114");
					BackgroundTransparency = (Data.Background == false) and 1 or 0;
					BorderSizePixel = 0;
					ClipsDescendants = true;
					ZIndex = 2;
				});
				Library:CreateInstance("UICorner", {
					Parent = Container;
					CornerRadius = NewUdim(0, 4);
				});

				local function resize()
					local w = row.AbsoluteSize.X;
					if w > 0 then
						Container.Size = NewUdim2(1, 0, 0, w * Ratio);
						if Host and Host.RefreshCanvases then task.defer(function() Host:RefreshCanvases() end) end;
					end;
				end;
				task.defer(function()
					RunService.Heartbeat:Wait();
					resize();
				end);
				Library:Connection(row:GetPropertyChangedSignal("AbsoluteSize"), resize);

				return {
					Row = row;
					Container = Container;
				};
			end;
			function SectionObj:Slider(SliderName, opts)
				if typeof(SliderName) == "table" then
					opts = SliderName;
					SliderName = opts.Name or opts.name;
				end;
				opts = typeof(opts) == "table" and opts or {};
				local HasName = SliderName ~= nil and tostring(SliderName) ~= "";
				local DisplayName = HasName and tostring(SliderName) or "";
				local InternalName = HasName and DisplayName or tostring(opts.flag or opts.Flag or "Slider");
				local min = tonumber(opts.min or opts.Min) or 0;
				local max = tonumber(opts.max or opts.Max) or 100;
				local step = tonumber(opts.step or opts.Step) or 1;
				if max < min then
					min, max = max, min;
				elseif max == min then
					max = min + (step > 0 and step or 1);
				end;
				local default = tonumber(opts.default or opts.Default) or min;
				default = MathClamp(default, min, max);
				local suffix = tostring(opts.suffix or opts.Suffix or "");
				local callback = opts.callback or opts.Callback;
				local Tooltip = opts.Tooltip or opts.tooltip;
				local flag = Library:AutoFlag(opts.flag or opts.Flag or InternalName);

				local row = Library:CreateInstance("Frame", {
					Name = "Slider_" .. InternalName;
					Parent = self.Content;
					Size = NewUdim2(1, 0, 0, HasName and 30 or 16);
					BackgroundTransparency = 1;
					BorderSizePixel = 0;
					ZIndex = 2;
				});

				local Label;
				if HasName then
					Label = Library:CreateInstance("TextLabel", {
						Name = "Label";
						Parent = row;
						Position = NewUdim2(0, 0, 0, 0);
						Size = NewUdim2(1, 0, 0, 12);
						BackgroundTransparency = 1;
						FontFace = Library.Fonts.title;
						Text = DisplayName;
						TextColor3 = FromRgb(255, 255, 255);
						TextSize = 9;
						TextXAlignment = Enum.TextXAlignment.Left;
						TextYAlignment = Enum.TextYAlignment.Top;
						ZIndex = 3;
					});
				end;
				if Tooltip and Label then
					Library:Tooltip(Label, { Title = DisplayName; Text = Tooltip });
				end;

				local track = Library:CreateInstance("TextButton", {
					Name = "Track";
					Parent = row;
					Position = NewUdim2(0, 0, 0, HasName and 14 or 0);
					Size = NewUdim2(1, 0, 0, 8);
					BackgroundColor3 = hex("07080A");
					BorderSizePixel = 0;
					AutoButtonColor = false;
					Text = "";
					ZIndex = 2;
				});

				local TrackBody = Library:CreateInstance("Frame", {
					Name = "Body";
					Parent = track;
					Position = NewUdim2(0, 1, 0, 1);
					Size = NewUdim2(1, -2, 1, -2);
					BackgroundColor3 = hex("1C1D23");
					BorderSizePixel = 0;
					ZIndex = 3;
				});

				local fill = Library:CreateInstance("Frame", {
					Name = "Fill";
					Parent = TrackBody;
					Size = NewUdim2(0, 0, 1, 0);
					BackgroundColor3 = FromRgb(255, 255, 255);
					BorderSizePixel = 0;
					ZIndex = 4;
				});
				Library:CreateInstance("UIGradient", {
					Parent = fill;
					Rotation = 90;
					Color = NewColorSequence(hex("94B7F8"), hex("6B84B3"));
				});

				local ValueLabel = Library:CreateInstance("TextLabel", {
					Name = "Value";
					Parent = track;
					AnchorPoint = NewVector2(0, 0);
					Position = NewUdim2(0, 0, 1, 0);
					Size = NewUdim2(0, 0, 0, 8);
					AutomaticSize = Enum.AutomaticSize.X;
					BackgroundTransparency = 1;
					FontFace = Library.Fonts.title;
					Text = "";
					TextColor3 = FromRgb(255, 255, 255);
					TextStrokeColor3 = FromRgb(0, 0, 0);
					TextStrokeTransparency = 0;
					TextSize = 9;
					TextXAlignment = Enum.TextXAlignment.Center;
					TextYAlignment = Enum.TextYAlignment.Top;
					ZIndex = 5;
				});

				local value = default;
				local function FormatValue(v)
					if step >= 1 then return tostring(MathFloor(v + 0.5)) .. suffix end;
					return string.format("%.2f", v) .. suffix;
				end;

				--// Visual fill lerps toward TargetT via exponential decay so the
				--// bar slides smoothly to its new value instead of snapping.
				local TargetT = 0;
				local VisualT = 0;
				if max > min then TargetT = MathClamp((default - min) / (max - min), 0, 1) end;
				VisualT = TargetT;
				local function ApplyVisual()
					fill.Size = NewUdim2(VisualT, 0, 1, 0);
					ValueLabel.AnchorPoint = NewVector2(VisualT, 0);
					ValueLabel.Position = NewUdim2(VisualT, 0, 1, 0);
				end;
				ApplyVisual();
				ValueLabel.Text = FormatValue(default);
				Library:RegisterSliderTicker({
					Alive = function() return row.Parent ~= nil end;
					Tick = function(dt)
						if MathAbs(TargetT - VisualT) < 0.0005 then
							if VisualT ~= TargetT then
								VisualT = TargetT;
								ApplyVisual();
							end;
							return;
						end;
						local alpha = 1 - math.exp(-dt * 12);
						VisualT = VisualT + (TargetT - VisualT) * alpha;
						ApplyVisual();
					end;
				});

				local slider = {
					Row = row;
					Track = track;
					Fill = fill;
					Value = value;
					Name = HasName and DisplayName or nil;
					Label = Label;
					Flag = flag;
					Min = min;
					Max = max;
					Step = step;
					Suffix = suffix;
				};
				Library.FlagMeta[flag] = {
					Type = "Slider";
					Min = min;
					Max = max;
					Step = step;
					Suffix = suffix;
				};

				function slider:Set(v)
					v = tonumber(v) or min;
					if step > 0 then v = MathFloor((v - min) / step + 0.5) * step + min end;
					v = MathClamp(v, min, max);
					self.Value = v;
					Library.Flags[self.Flag] = v;
					if max > min then TargetT = MathClamp((v - min) / (max - min), 0, 1) else TargetT = 0 end;
					ValueLabel.Text = FormatValue(v);
					if typeof(callback) == "function" then callback(v) end;
				end;
				function slider:Get() return self.Value end;
				slider:Set(default);
				Library:RegisterFlag(flag, default, function(v) slider:Set(v) end);

				local dragging = false;
				local DragHandler;
				DragHandler = function(input)
					local abs = track.AbsolutePosition.X;
					local wide = MathMax(1, track.AbsoluteSize.X);
					local MouseX = UserInputService:GetMouseLocation().X;
					if input and input.UserInputType == Enum.UserInputType.Touch then
						MouseX = input.Position.X;
					end;
					local pct = MathClamp((MouseX - abs) / wide, 0, 1);
					slider:Set(min + pct * (max - min));
				end;
				Library:Connection(track.InputBegan, function(input)
					if input.UserInputType ~= Enum.UserInputType.MouseButton1 and input.UserInputType ~= Enum.UserInputType.Touch then return end;
					if dragging then return end;
					dragging = true;
					DragHandler(input);
					Library:RegisterDragger(DragHandler);
				end);
				Library:Connection(UserInputService.InputEnded, function(input)
					if input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.Touch then
						if dragging then
							dragging = false;
							Library:UnregisterDragger(DragHandler);
						end;
					end;
				end);

				return slider;
			end;

			function SectionObj:RangeSlider(SliderName, opts)
				if typeof(SliderName) == "table" then
					opts = SliderName;
					SliderName = opts.Name or opts.name;
				end;
				opts = typeof(opts) == "table" and opts or {};
				local DisplayName = tostring(SliderName or opts.Flag or opts.flag or "Range Slider");
				local min = tonumber(opts.Min or opts.min) or 0;
				local max = tonumber(opts.Max or opts.max) or 100;
				local step = tonumber(opts.Step or opts.step) or 1;
				local defaultMin = tonumber(opts.DefaultMin or opts.defaultMin or opts.Default or opts.default) or min;
				local defaultMax = tonumber(opts.DefaultMax or opts.defaultMax) or max;
				local suffix = tostring(opts.Suffix or opts.suffix or "");
				local callback = opts.Callback or opts.callback;
				local Tooltip = opts.Tooltip or opts.tooltip;
				local flag = Library:AutoFlag(opts.Flag or opts.flag or DisplayName);

				local row = Library:CreateInstance("Frame", {
					Name = "RangeSlider_" .. DisplayName;
					Parent = self.Content;
					Size = NewUdim2(1, 0, 0, 32);
					BackgroundTransparency = 1;
					BorderSizePixel = 0;
					ZIndex = 2;
				});
				local Label = Library:CreateInstance("TextLabel", {
					Name = "Label";
					Parent = row;
					Position = NewUdim2(0, 0, 0, 0);
					Size = NewUdim2(1, 0, 0, 12);
					BackgroundTransparency = 1;
					FontFace = Library.Fonts.title;
					Text = DisplayName;
					TextColor3 = FromRgb(255, 255, 255);
					TextSize = 9;
					TextXAlignment = Enum.TextXAlignment.Left;
					TextYAlignment = Enum.TextYAlignment.Top;
					ZIndex = 3;
				});
				if Tooltip then Library:Tooltip(Label, { Title = DisplayName; Text = Tooltip }) end;

				local track = Library:CreateInstance("TextButton", {
					Name = "Track";
					Parent = row;
					Position = NewUdim2(0, 0, 0, 14);
					Size = NewUdim2(1, 0, 0, 8);
					BackgroundColor3 = hex("07080A");
					BorderSizePixel = 0;
					AutoButtonColor = false;
					Text = "";
					ZIndex = 2;
				});
				local body = Library:CreateInstance("Frame", {
					Name = "Body";
					Parent = track;
					Position = NewUdim2(0, 1, 0, 1);
					Size = NewUdim2(1, -2, 1, -2);
					BackgroundColor3 = hex("1C1D23");
					BorderSizePixel = 0;
					ZIndex = 3;
				});
				local fill = Library:CreateInstance("Frame", {
					Name = "Fill";
					Parent = body;
					BackgroundColor3 = FromRgb(255, 255, 255);
					BorderSizePixel = 0;
					ZIndex = 4;
				});
				Library:CreateInstance("UIGradient", {
					Parent = fill;
					Rotation = 90;
					Color = NewColorSequence(hex("94B7F8"), hex("6B84B3"));
				});
				local ValueLabel = Library:CreateInstance("TextLabel", {
					Name = "Value";
					Parent = track;
					Position = NewUdim2(0, 0, 1, 0);
					Size = NewUdim2(1, 0, 0, 8);
					BackgroundTransparency = 1;
					FontFace = Library.Fonts.title;
					Text = "";
					TextColor3 = FromRgb(255, 255, 255);
					TextStrokeColor3 = FromRgb(0, 0, 0);
					TextStrokeTransparency = 0;
					TextSize = 9;
					TextXAlignment = Enum.TextXAlignment.Center;
					TextYAlignment = Enum.TextYAlignment.Top;
					ZIndex = 5;
				});
				local TrackTween = NewTweenInfo(0.12, Enum.EasingStyle.Quad, Enum.EasingDirection.Out);
				local TrackScale = Library:CreateInstance("UIScale", {
					Parent = track;
					Scale = 1;
				});
				Library:Connection(track.MouseEnter, function()
					Library:Tween(TrackScale, TrackTween, { Scale = 1.01 }):Play();
					Library:Tween(body, TrackTween, { BackgroundColor3 = hex("24262D") }):Play();
				end);
				Library:Connection(track.MouseLeave, function()
					Library:Tween(TrackScale, TrackTween, { Scale = 1 }):Play();
					Library:Tween(body, TrackTween, { BackgroundColor3 = hex("1C1D23") }):Play();
				end);
				Library:Connection(track.MouseButton1Down, function()
					Library:Tween(TrackScale, NewTweenInfo(0.07, Enum.EasingStyle.Quad, Enum.EasingDirection.Out), { Scale = 0.99 }):Play();
				end);
				Library:Connection(track.MouseButton1Up, function()
					Library:Tween(TrackScale, TrackTween, { Scale = 1.01 }):Play();
				end);

				local range = { Row = row; Track = track; Fill = fill; Label = Label; Flag = flag; Min = defaultMin; Max = defaultMax; Floor = min; Ceiling = max; Step = step; Suffix = suffix };
				Library.FlagMeta[flag] = { Type = "RangeSlider"; Min = min; Max = max; Step = step; Suffix = suffix };
				local function FormatValue(v)
					if step >= 1 then return tostring(MathFloor(v + 0.5)) .. suffix end;
					return string.format("%.2f", v) .. suffix;
				end;
				local TargetMinT = 0;
				local TargetMaxT = 0;
				local VisualMinT = 0;
				local VisualMaxT = 0;
				if max > min then
					TargetMinT = MathClamp((defaultMin - min) / (max - min), 0, 1);
					TargetMaxT = MathClamp((defaultMax - min) / (max - min), 0, 1);
				end;
				VisualMinT = TargetMinT;
				VisualMaxT = TargetMaxT;
				local function ApplyVisual()
					fill.Position = NewUdim2(VisualMinT, 0, 0, 0);
					fill.Size = NewUdim2(VisualMaxT - VisualMinT, 0, 1, 0);
				end;
				ApplyVisual();
				ValueLabel.Text = FormatValue(defaultMin) .. " - " .. FormatValue(defaultMax);
				Library:RegisterSliderTicker({
					Alive = function() return row.Parent ~= nil end;
					Tick = function(dt)
						local dirty = false;
						if MathAbs(TargetMinT - VisualMinT) >= 0.0005 then
							local alpha = 1 - math.exp(-dt * 12);
							VisualMinT = VisualMinT + (TargetMinT - VisualMinT) * alpha;
							dirty = true;
						elseif VisualMinT ~= TargetMinT then
							VisualMinT = TargetMinT;
							dirty = true;
						end;
						if MathAbs(TargetMaxT - VisualMaxT) >= 0.0005 then
							local alpha = 1 - math.exp(-dt * 12);
							VisualMaxT = VisualMaxT + (TargetMaxT - VisualMaxT) * alpha;
							dirty = true;
						elseif VisualMaxT ~= TargetMaxT then
							VisualMaxT = TargetMaxT;
							dirty = true;
						end;
						if dirty then ApplyVisual() end;
					end;
				});
				local function SetVisual()
					TargetMinT = max > min and MathClamp((range.Min - min) / (max - min), 0, 1) or 0;
					TargetMaxT = max > min and MathClamp((range.Max - min) / (max - min), 0, 1) or 0;
					ValueLabel.Text = FormatValue(range.Min) .. " - " .. FormatValue(range.Max);
				end;
				function range:Set(a, b)
					if typeof(a) == "table" then
						b = a.Max or a.max or a[2];
						a = a.Min or a.min or a[1];
					end;
					a = tonumber(a) or min;
					b = tonumber(b) or max;
					if step > 0 then
						a = MathFloor((a - min) / step + 0.5) * step + min;
						b = MathFloor((b - min) / step + 0.5) * step + min;
					end;
					a = MathClamp(a, min, max);
					b = MathClamp(b, min, max);
					if a > b then a, b = b, a end;
					self.Min = a;
					self.Max = b;
					Library.Flags[self.Flag] = { Min = a; Max = b };
					SetVisual();
					if typeof(callback) == "function" then callback(a, b) end;
				end;
				function range:Get() return self.Min, self.Max end;
				range:Set(defaultMin, defaultMax);
				Library:RegisterFlag(flag, { Min = range.Min; Max = range.Max }, function(v) range:Set(v) end);

				local dragging;
				local DragHandler;
				DragHandler = function(input)
					local MouseX = UserInputService:GetMouseLocation().X;
					if input and input.UserInputType == Enum.UserInputType.Touch then MouseX = input.Position.X end;
					local pct = MathClamp((MouseX - track.AbsolutePosition.X) / MathMax(1, track.AbsoluteSize.X), 0, 1);
					local value = min + pct * (max - min);
					local minT = max > min and MathClamp((range.Min - min) / (max - min), 0, 1) or 0;
					local maxT = max > min and MathClamp((range.Max - min) / (max - min), 0, 1) or 0;
					if dragging == nil then
						dragging = MathAbs(pct - minT) <= MathAbs(pct - maxT) and "Min" or "Max";
					end;
					if dragging == "Min" then
						range:Set(value, range.Max);
					else
						range:Set(range.Min, value);
					end;
				end;
				Library:Connection(track.InputBegan, function(input)
					if input.UserInputType ~= Enum.UserInputType.MouseButton1 and input.UserInputType ~= Enum.UserInputType.Touch then return end;
					dragging = nil;
					DragHandler(input);
					Library:RegisterDragger(DragHandler);
				end);
				Library:Connection(UserInputService.InputEnded, function(input)
					if input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.Touch then
						dragging = nil;
						Library:UnregisterDragger(DragHandler);
					end;
				end);
				return range;
			end;

			function SectionObj:Textbox(InputName, default, opts, callback)
				if typeof(InputName) == "table" then
					local Data = InputName;
					InputName = Data.Name or Data.name or "Textbox";
					default = Data.Default or Data.default;
					callback = Data.Callback or Data.callback;
					opts = Data;
				end;
				opts = typeof(opts) == "table" and opts or {};
				local placeholder = opts.Placeholder or opts.placeholder or "...";
				local Tooltip = opts.Tooltip or opts.tooltip;
				local flag = Library:AutoFlag(opts.flag or opts.Flag or InputName);

				local row = Library:CreateInstance("Frame", {
					Name = "TextInputRow_" .. InputName;
					Parent = self.Content;
					Size = NewUdim2(1, 0, 0, 30);
					BackgroundTransparency = 1;
					BorderSizePixel = 0;
					ZIndex = 2;
				});

				local Label = Library:CreateInstance("TextLabel", {
					Name = "Label";
					Parent = row;
					Position = NewUdim2(0, 0, 0, 0);
					Size = NewUdim2(1, 0, 0, 9);
					BackgroundTransparency = 1;
					FontFace = Library.Fonts.title;
					Text = tostring(InputName);
					TextColor3 = hex("B4B4B4");
					TextSize = 9;
					TextXAlignment = Enum.TextXAlignment.Left;
					TextYAlignment = Enum.TextYAlignment.Top;
					ZIndex = 3;
				});
				if Tooltip then Library:Tooltip(Label, { Title = InputName; Text = Tooltip }) end;

				local BoxOuter = Library:CreateInstance("Frame", {
					Name = "Outer";
					Parent = row;
					Position = NewUdim2(0, 0, 0, 12);
					Size = NewUdim2(1, 0, 0, 16);
					BackgroundColor3 = hex("07080A");
					BorderSizePixel = 0;
					ZIndex = 2;
				});
				local BoxMid = Library:CreateInstance("Frame", {
					Name = "Mid";
					Parent = BoxOuter;
					Position = NewUdim2(0, 1, 0, 1);
					Size = NewUdim2(1, -2, 1, -2);
					BackgroundColor3 = hex("24262D");
					BorderSizePixel = 0;
					ZIndex = 3;
				});
				local BoxBody = Library:CreateInstance("Frame", {
					Name = "Body";
					Parent = BoxMid;
					Position = NewUdim2(0, 1, 0, 1);
					Size = NewUdim2(1, -2, 1, -2);
					BackgroundColor3 = FromRgb(255, 255, 255);
					BorderSizePixel = 0;
					ClipsDescendants = true;
					ZIndex = 4;
				});
				Library:CreateInstance("UIGradient", {
					Parent = BoxBody; Rotation = 90;
					Color = NewColorSequence(hex("131418"), hex("17181D"));
				});

				local textbox = Library:CreateInstance("TextBox", {
					Name = "Input";
					Parent = BoxBody;
					Position = NewUdim2(0, 0, 0, 0);
					Size = NewUdim2(1, 0, 1, 0);
					BackgroundTransparency = 1;
					BorderSizePixel = 0;
					ClearTextOnFocus = false;
					FontFace = Library.Fonts.title;
					Text = tostring(default or "");
					PlaceholderText = tostring(placeholder);
					PlaceholderColor3 = hex("646464");
					TextColor3 = FromRgb(255, 255, 255);
					TextSize = 9;
					TextXAlignment = Enum.TextXAlignment.Left;
					TextYAlignment = Enum.TextYAlignment.Center;
					ClipsDescendants = true;
					ZIndex = 5;
				});
				Library:CreateInstance("UIPadding", {
					Parent = textbox;
					PaddingLeft = NewUdim(0, 4);
					PaddingRight = NewUdim(0, 4);
				});

				local InputObj = { Row = row, Outer = BoxOuter, Mid = BoxMid, Body = BoxBody, Box = textbox, Name = InputName, Flag = flag };
				local FocusTween = NewTweenInfo(0.12, Enum.EasingStyle.Linear);

				function InputObj:Get() return self.Box.Text end;
				function InputObj:Set(v)
					self.Box.Text = tostring(v or "");
					Library.Flags[self.Flag] = self.Box.Text;
					if typeof(callback) == "function" then callback(self.Box.Text, false) end;
				end;
				Library.Flags[flag] = textbox.Text;
				Library:RegisterFlag(flag, textbox.Text, function(v) InputObj:Set(v) end);

				Library:Connection(textbox.Focused, function()
					Library:Tween(BoxOuter, FocusTween, { BackgroundColor3 = Library.ShadeColor or hex("6E8CC8") }):Play();
				end);
				Library:Connection(textbox.FocusLost, function(enter)
					Library:Tween(BoxOuter, FocusTween, { BackgroundColor3 = Library.WindowOuterColor or hex("07080A") }):Play();
					Library.Flags[flag] = textbox.Text;
					if typeof(callback) == "function" then callback(textbox.Text, enter == true) end;
				end);

				return InputObj;
			end;

			function SectionObj:Dropdown(DropdownName, options, default, callback, FlagOpt, MultiOpt)
				local Tooltip, Multi;
				if typeof(DropdownName) == "table" then
					local Data = DropdownName;
					DropdownName = Data.Name or Data.name or "Dropdown";
					options = Data.Items or Data.items or {};
					default = Data.Default or Data.default;
					callback = Data.Callback or Data.callback;
					FlagOpt = Data.Flag or Data.flag;
					Tooltip = Data.Tooltip or Data.tooltip;
					Multi = Data.Multi or Data.multi;
				end;
				options = typeof(options) == "table" and options or {};
				local IsMulti = Multi == true or MultiOpt == true;
				if IsMulti and typeof(default) ~= "table" then
					default = default ~= nil and { default } or {};
				end;
				local flag = Library:AutoFlag(FlagOpt or DropdownName);

				local row = Library:CreateInstance("Frame", {
					Name = "DropdownRow_" .. DropdownName;
					Parent = self.Content;
					Size = NewUdim2(1, 0, 0, 30);
					BackgroundTransparency = 1;
					BorderSizePixel = 0;
					ZIndex = 2;
				});

				local Label = Library:CreateInstance("TextLabel", {
					Name = "Label";
					Parent = row;
					Position = NewUdim2(0, 0, 0, 0);
					Size = NewUdim2(1, 0, 0, 9);
					BackgroundTransparency = 1;
					FontFace = Library.Fonts.title;
					Text = tostring(DropdownName);
					TextColor3 = hex("B4B4B4");
					TextSize = 9;
					TextXAlignment = Enum.TextXAlignment.Left;
					TextYAlignment = Enum.TextYAlignment.Top;
					ZIndex = 3;
				});
				if Tooltip then Library:Tooltip(Label, { Title = DropdownName; Text = Tooltip }) end;

				local BoxOutline = Library:CreateInstance("Frame", {
					Name = "Outer";
					Parent = row;
					Position = NewUdim2(0, 0, 0, 12);
					Size = NewUdim2(1, 0, 0, 16);
					BackgroundColor3 = hex("07080A");
					BorderSizePixel = 0;
					ZIndex = 2;
				});
				local BoxMid = Library:CreateInstance("Frame", {
					Name = "Mid";
					Parent = BoxOutline;
					Position = NewUdim2(0, 1, 0, 1);
					Size = NewUdim2(1, -2, 1, -2);
					BackgroundColor3 = hex("24262D");
					BorderSizePixel = 0;
					ZIndex = 3;
				});
				local BoxBody = Library:CreateInstance("Frame", {
					Name = "Body";
					Parent = BoxMid;
					Position = NewUdim2(0, 1, 0, 1);
					Size = NewUdim2(1, -2, 1, -2);
					BackgroundColor3 = FromRgb(255, 255, 255);
					BorderSizePixel = 0;
					ZIndex = 4;
				});
				Library:CreateInstance("UIGradient", {
					Parent = BoxBody; Rotation = 90;
					Color = NewColorSequence(hex("131418"), hex("17181D"));
				});

				local ValueLabel = Library:CreateInstance("TextLabel", {
					Name = "Value";
					Parent = BoxBody;
					Position = NewUdim2(0, 4, 0, -1);
					Size = NewUdim2(1, -16, 1, 0);
					BackgroundTransparency = 1;
					FontFace = Library.Fonts.title;
					Text = IsMulti and "None" or tostring(default or "None");
					TextColor3 = FromRgb(255, 255, 255);
					TextSize = 9;
					TextXAlignment = Enum.TextXAlignment.Left;
					TextYAlignment = Enum.TextYAlignment.Center;
					TextTruncate = Enum.TextTruncate.AtEnd;
					ZIndex = 4;
				});

				local arrow = Library:CreateInstance("TextLabel", {
					Name = "Arrow";
					Parent = BoxBody;
					AnchorPoint = NewVector2(1, 0.5);
					Position = NewUdim2(1, -4, 0.5, 0);
					Size = NewUdim2(0, 8, 0, 9);
					BackgroundTransparency = 1;
					FontFace = Library.Fonts.title;
					Text = "v";
					TextColor3 = hex("B4B4B4");
					TextSize = 9;
					TextXAlignment = Enum.TextXAlignment.Center;
					TextYAlignment = Enum.TextYAlignment.Center;
					ZIndex = 4;
				});

				local hit = Library:CreateInstance("TextButton", {
					Name = "Hit";
					Parent = BoxOutline;
					Size = NewUdim2(1, 0, 1, 0);
					BackgroundTransparency = 1;
					AutoButtonColor = false;
					Text = "";
					ZIndex = 5;
				});

				local OPT_ROW_H = 14;
				local ListOutline = Library:CreateInstance("Frame", {
					Name = "ListOuter";
					Parent = BoxOutline;
					Position = NewUdim2(0, 0, 1, 1);
					Size = NewUdim2(1, 0, 0, 0);
					BackgroundColor3 = hex("07080A");
					BorderSizePixel = 0;
					Visible = false;
					ClipsDescendants = true;
					Active = true;
					ZIndex = 10;
				});
				local ListMid = Library:CreateInstance("Frame", {
					Name = "ListMid";
					Parent = ListOutline;
					Position = NewUdim2(0, 1, 0, 1);
					Size = NewUdim2(1, -2, 1, -2);
					BackgroundColor3 = hex("24262D");
					BorderSizePixel = 0;
					ZIndex = 11;
				});
				local ListBody = Library:CreateInstance("Frame", {
					Name = "ListBody";
					Parent = ListMid;
					Position = NewUdim2(0, 1, 0, 1);
					Size = NewUdim2(1, -2, 1, -2);
					BackgroundColor3 = FromRgb(255, 255, 255);
					BorderSizePixel = 0;
					Active = true;
					ZIndex = 12;
				});
				Library:CreateInstance("UIGradient", {
					Parent = ListBody; Rotation = 90;
					Color = NewColorSequence(hex("131418"), hex("17181D"));
				});
				Library:CreateInstance("UIListLayout", {
					Parent = ListBody;
					FillDirection = Enum.FillDirection.Vertical;
					SortOrder = Enum.SortOrder.LayoutOrder;
					Padding = NewUdim(0, 3);
				});
				Library:CreateInstance("UIPadding", {
					Parent = ListBody;
					PaddingTop = NewUdim(0, 3);
					PaddingBottom = NewUdim(0, 3);
					PaddingLeft = NewUdim(0, 2);
				});

				local dropdown = {
					Row = row;
					Outline = BoxOutline;
					Body = BoxBody;
					ValueLabel = ValueLabel;
					List = ListOutline;
					ListBody = ListBody;
					Arrow = arrow;
					Name = DropdownName;
					Value = default;
					Multi = IsMulti;
					Options = options;
					OptionRows = {};
					Open = false;
					SettingsItems = {};
					SettingsParentContent = self.Content;
				};

				local DROPDOWN_ANIM_TIME = 0.15;
				local DropdownTween;
				local ClosedRowHeight = 30;
				local function CloseList()
					dropdown.Open = false;
					arrow.Text = "v";
					if DropdownTween then DropdownTween:Cancel() end;
					DropdownTween = TweenService:Create(ListOutline, NewTweenInfo(DROPDOWN_ANIM_TIME, Enum.EasingStyle.Quad, Enum.EasingDirection.Out), { Size = NewUdim2(1, 0, 0, 0) });
					DropdownTween:Play();
					TweenService:Create(row, NewTweenInfo(DROPDOWN_ANIM_TIME, Enum.EasingStyle.Quad, Enum.EasingDirection.Out), { Size = NewUdim2(1, 0, 0, ClosedRowHeight) }):Play();
					DropdownTween.Completed:Once(function()
						if not dropdown.Open then
							ListOutline.Visible = false;
						end;
					end);
				end;
					local function OpenList()
						dropdown.Open = true;
						arrow.Text = "^";
						local TargetH = #dropdown.Options * OPT_ROW_H + MathMax(0, #dropdown.Options - 1) * 3 + 10;
						ListOutline.Size = NewUdim2(1, 0, 0, 0);
						ListOutline.Visible = true;
						if DropdownTween then DropdownTween:Cancel() end;
						DropdownTween = TweenService:Create(ListOutline, NewTweenInfo(DROPDOWN_ANIM_TIME, Enum.EasingStyle.Quad, Enum.EasingDirection.Out), { Size = NewUdim2(1, 0, 0, TargetH) });
						DropdownTween:Play();
						TweenService:Create(row, NewTweenInfo(DROPDOWN_ANIM_TIME, Enum.EasingStyle.Quad, Enum.EasingDirection.Out), { Size = NewUdim2(1, 0, 0, ClosedRowHeight + TargetH + 1) }):Play();
					end;

				dropdown.CloseList = CloseList;
				dropdown.OpenList = OpenList;
				Library:RegisterPopup(function() if dropdown.Open then CloseList() end end);
				dropdown.Flag = flag;
				function dropdown:Get() return self.Value end;
				function dropdown:Selected(Value)
					if not self.Multi then
						return self.Value == Value;
					end;

					for _, Selected in (self.Value or {}) do
						if Selected == Value or tostring(Selected) == tostring(Value) then
							return true;
						end;
					end;

					return false;
				end;
				function dropdown:Text()
					if not self.Multi then
						return tostring(self.Value or "None");
					end;

					local Parts = {};
					for _, Value in (self.Value or {}) do
						Parts[#Parts + 1] = tostring(Value);
					end;

					if #Parts == 0 then
						return "None";
					end;

					local Text = table.concat(Parts, ", ");
					if #Text > 42 then
						Text = string.sub(Text, 1, 39) .. "...";
					end;

					return Text;
				end;
				function dropdown:RefreshOptions()
					for Value, Row in self.OptionRows do
						local Label = Row:FindFirstChild("OptionLabel");
						local Selected = self:Selected(Value);

						Row.BackgroundTransparency = Selected and 0.35 or 1;
						if Label then
							Label.TextColor3 = Selected and (Library.AccentColor or hex("98BCFF")) or hex("B4B4B4");
						end;
					end;
				end;
				function dropdown:SetOptions(newOptions)
					newOptions = typeof(newOptions) == "table" and newOptions or {};
					for _, Row in self.OptionRows do
						if Row then Row:Destroy() end;
					end;
					self.OptionRows = {};
					self.Options = newOptions;

					local Body = self.ListBody;
					if not Body then return end;

					for i, opt in newOptions do
						local OptRow = Library:CreateInstance("TextButton", {
							Name = "Option_" .. tostring(opt);
							Parent = Body;
							Size = NewUdim2(1, 0, 0, 14);
							BackgroundColor3 = hex("1C1D23");
							BackgroundTransparency = 1;
							BorderSizePixel = 0;
							AutoButtonColor = false;
							Text = "";
							LayoutOrder = i;
							ZIndex = 12;
						});
						Library:CreateInstance("TextLabel", {
							Name = "OptionLabel";
							Parent = OptRow;
							Position = NewUdim2(0, 4, 0, 0);
							Size = NewUdim2(1, -8, 1, 0);
							BackgroundTransparency = 1;
							FontFace = Library.Fonts.title;
							Text = tostring(opt);
							TextColor3 = hex("B4B4B4");
							TextSize = 9;
							TextXAlignment = Enum.TextXAlignment.Left;
							TextYAlignment = Enum.TextYAlignment.Center;
							TextTruncate = Enum.TextTruncate.AtEnd;
							ZIndex = 13;
						});
						Library:Connection(OptRow.MouseEnter, function()
							OptRow.BackgroundTransparency = self:Selected(opt) and 0.35 or 0.7;
						end);
						Library:Connection(OptRow.MouseLeave, function()
							OptRow.BackgroundTransparency = self:Selected(opt) and 0.35 or 1;
						end);
						Library:Connection(OptRow.MouseButton1Click, function()
							if self.Multi then
								self:Toggle(opt);
							else
								self:Set(opt);
								if self.CloseList then self:CloseList() end;
							end;
						end);
						self.OptionRows[opt] = OptRow;
					end;

					self:RefreshOptions();
					if not self.Multi then
						local Valid = false;
						for _, opt in newOptions do
							if opt == self.Value then Valid = true; break; end;
						end;
						if not Valid then
							self:Set(nil);
						end;
					end;
					if Host and Host.RefreshCanvases then task.defer(function() Host:RefreshCanvases() end) end;
				end;
				function dropdown:Set(v)
					if self.Multi then
						local Values = {};
						if typeof(v) == "table" then
							for Key, Value in v do
								if Value == true then
									Values[#Values + 1] = Key;
								elseif Value ~= false and Value ~= nil then
									Values[#Values + 1] = Value;
								end;
							end;
						elseif v ~= nil then
							Values[1] = v;
						end;
						self.Value = Values;
					else
						self.Value = v;
					end;

					Library.Flags[self.Flag] = self.Value;
					if Library.FlagSettings and Library.FlagSettings[self.Flag] then
						for _, Settings in Library.FlagSettings[self.Flag] do
							if Settings and Settings.Refresh then Settings:Refresh() end;
						end;
					end;
					ValueLabel.Text = self:Text();
					self:RefreshOptions();
					for _, Settings in self.SettingsItems do
						Settings:SetOpen(Settings:Check(self.Value));
					end;
					if typeof(callback) == "function" then callback(self.Value) end;
				end;
				function dropdown:Toggle(Value)
					if not self.Multi then
						self:Set(Value);
						return;
					end;

					local Values = {};
					local Removed = false;
					for _, Selected in (self.Value or {}) do
						if Selected == Value or tostring(Selected) == tostring(Value) then
							Removed = true;
						else
							Values[#Values + 1] = Selected;
						end;
					end;

					if not Removed then
						Values[#Values + 1] = Value;
					end;

					self:Set(Values);
				end;
				function dropdown:Settings(Match)
					local SettingsRow = Library:CreateInstance("Frame", {
						Name = "Settings_" .. tostring(self.Name) .. "_" .. tostring(Match);
						Parent = self.SettingsParentContent or SectionObj.Content;
						Size = NewUdim2(1, 0, 0, 0);
						BackgroundTransparency = 1;
						BorderSizePixel = 0;
						ClipsDescendants = true;
						Visible = false;
						ZIndex = 2;
					});

					local Rail = Library:CreateInstance("Frame", {
						Name = "Rail";
						Parent = SettingsRow;
						Position = NewUdim2(0, 5, 0, 0);
						Size = NewUdim2(0, 1, 0, 0);
						BackgroundColor3 = hex("3A3D45");
						BorderSizePixel = 0;
						ZIndex = 2;
					});
					Library:CreateInstance("Frame", {
						Name = "RailEnd";
						Parent = Rail;
						AnchorPoint = NewVector2(0.5, 1);
						Position = NewUdim2(0.5, 0, 1, 0);
						Size = FromOffset(3, 3);
						BackgroundColor3 = hex("3A3D45");
						BorderSizePixel = 0;
						ZIndex = 2;
					});

					local Content = Library:CreateInstance("Frame", {
						Name = "Content";
						Parent = SettingsRow;
						Position = NewUdim2(0, 18, 0, 0);
						Size = NewUdim2(1, -18, 0, 0);
						AutomaticSize = Enum.AutomaticSize.Y;
						BackgroundTransparency = 1;
						BorderSizePixel = 0;
						ZIndex = 2;
					});

					local Layout = Library:CreateInstance("UIListLayout", {
						Parent = Content;
						FillDirection = Enum.FillDirection.Vertical;
						SortOrder = Enum.SortOrder.LayoutOrder;
						Padding = NewUdim(0, 4);
					});
					Library:CreateInstance("UIPadding", {
						Parent = Content;
						PaddingTop = NewUdim(0, 2);
						PaddingBottom = NewUdim(0, 2);
					});

					local SettingsTween = NewTweenInfo(0.16, Enum.EasingStyle.Quad, Enum.EasingDirection.Out);
					local Settings = {
						Row = SettingsRow;
						Content = Content;
						ParentDropdown = self;
						Match = Match;
						Open = false;
						Animating = false;
					};
					insert(Library.SettingsRegistry, Settings);

					function Settings:Check(Value)
						local Current = Value;
						if typeof(self.Match) == "function" then
							local Ok, Result = pcall(self.Match, Current, Library.Flags[dropdown.Flag]);
							return Ok and Result == true;
						elseif typeof(self.Match) == "table" then
							if dropdown.Multi and typeof(Current) == "table" then
								for _, Selected in Current do
									for _, Allowed in self.Match do
										if Selected == Allowed or tostring(Selected) == tostring(Allowed) then
											return true;
										end;
									end;
								end;
							else
								for _, Allowed in self.Match do
									if Current == Allowed or tostring(Current) == tostring(Allowed) then
										return true;
									end;
								end;
							end;
							return false;
						elseif self.Match == nil then
							if dropdown.Multi and typeof(Current) == "table" then
								return #Current > 0;
							end;
							return Current ~= nil;
						end;
						if dropdown.Multi and typeof(Current) == "table" then
							for _, Selected in Current do
								if Selected == self.Match or tostring(Selected) == tostring(self.Match) then
									return true;
								end;
							end;
							return false;
						end;
						return Current == self.Match or tostring(Current) == tostring(self.Match);
					end;

					function Settings:SetOpen(Bool)
						Bool = Bool == true;
						self.Open = Bool;
						self.Animating = true;
						if Bool then SettingsRow.Visible = true end;
						local Scale = Library:ComputeUIScale();
					local Height = Bool and ((Layout.AbsoluteContentSize.Y + 2) / Scale + 4) or 0;
						Library:Tween(SettingsRow, SettingsTween, { Size = NewUdim2(1, 0, 0, Height) }):Play();
						Library:Tween(Content, SettingsTween, { Size = NewUdim2(1, -18, 0, Height) }):Play();
						local RailTween = Library:Tween(Rail, SettingsTween, { Size = NewUdim2(0, 1, 0, Height) });
						RailTween:Play();
						RailTween.Completed:Once(function()
							self.Animating = false;
							if self.Open and SettingsRow and SettingsRow.Parent then
								local NewHeight = (Layout.AbsoluteContentSize.Y + 2) / Library:ComputeUIScale() + 4;
								SettingsRow.Size = NewUdim2(1, 0, 0, NewHeight);
								Content.Size = NewUdim2(1, -18, 0, NewHeight);
								Rail.Size = NewUdim2(0, 1, 0, NewHeight);
							end;
							if Host and Host.RefreshCanvases then Host:RefreshCanvases() end;
						end);
						if Host and Host.RefreshCanvases then task.defer(function() Host:RefreshCanvases() end) end;
						if not Bool then
							task.delay(0.16, function()
								if not self.Open and SettingsRow and SettingsRow.Parent then
									SettingsRow.Visible = false;
								end;
							end);
						end;
					end;

					function Settings:Refresh()
						local Parent = self.ParentDropdown;
						self:SetOpen(self:Check(Parent and Parent.Value));
					end;

					Library:Connection(Layout:GetPropertyChangedSignal("AbsoluteContentSize"), function()
						if Settings.Open and not Settings.Animating then
							local Height = (Layout.AbsoluteContentSize.Y + 2) / Library:ComputeUIScale() + 4;
							SettingsRow.Size = NewUdim2(1, 0, 0, Height);
							Content.Size = NewUdim2(1, -18, 0, Height);
							Rail.Size = NewUdim2(0, 1, 0, Height);
							if Host and Host.RefreshCanvases then task.defer(function() Host:RefreshCanvases() end) end;
						end;
					end);

					for Name, Method in SectionObj do
						if typeof(Method) == "function" then
							Settings[Name] = Method;
						end;
					end;

					insert(self.SettingsItems, Settings);
					Settings:SetOpen(Settings:Check(self.Value));
					return Settings;
				end;
				Library:RegisterFlag(flag, default, function(v) dropdown:Set(v) end);

				for i, opt in options do
					local OptRow = Library:CreateInstance("TextButton", {
						Name = "Option_" .. tostring(opt);
						Parent = ListBody;
						Size = NewUdim2(1, 0, 0, 14);
						BackgroundColor3 = hex("1C1D23");
						BackgroundTransparency = 1;
						BorderSizePixel = 0;
						AutoButtonColor = false;
						Text = "";
						LayoutOrder = i;
						ZIndex = 12;
					});
					Library:CreateInstance("TextLabel", {
						Name = "OptionLabel";
						Parent = OptRow;
						Position = NewUdim2(0, 4, 0, 0);
						Size = NewUdim2(1, -8, 1, 0);
						BackgroundTransparency = 1;
						FontFace = Library.Fonts.title;
						Text = tostring(opt);
						TextColor3 = hex("B4B4B4");
						TextSize = 9;
						TextXAlignment = Enum.TextXAlignment.Left;
						TextYAlignment = Enum.TextYAlignment.Center;
						TextTruncate = Enum.TextTruncate.AtEnd;
						ZIndex = 13;
					});
					Library:Connection(OptRow.MouseEnter, function()
						OptRow.BackgroundTransparency = dropdown:Selected(opt) and 0.35 or 0.7;
					end);
					Library:Connection(OptRow.MouseLeave, function()
						OptRow.BackgroundTransparency = dropdown:Selected(opt) and 0.35 or 1;
					end);
					Library:Connection(OptRow.MouseButton1Click, function()
						if dropdown.Multi then
							dropdown:Toggle(opt);
						else
							dropdown:Set(opt);
							CloseList();
						end;
					end);
					dropdown.OptionRows[opt] = OptRow;
				end;

				Library:Connection(hit.MouseButton1Click, function()
					if dropdown.Open then CloseList() else OpenList() end;
				end);

				if default ~= nil then dropdown:Set(default) end;
				ValueLabel.Text = dropdown:Text();
				dropdown:RefreshOptions();

				return dropdown;
			end;

			function SectionObj:Keybind(KeybindName, DefaultKey, callback, FlagOpt)
				local Mode = "Toggle";
				local Tooltip;
				if typeof(KeybindName) == "table" then
					local Data = KeybindName;
					KeybindName = Data.Name or Data.name or "Keybind";
					DefaultKey = Data.Default or Data.default;
					callback = Data.Callback or Data.callback;
					FlagOpt = Data.Flag or Data.flag;
					Mode = Data.Mode or Data.mode or "Toggle";
					Tooltip = Data.Tooltip or Data.tooltip;
				end;
				local flag = Library:AutoFlag(FlagOpt or KeybindName);
				local ModeFlag = flag .. ".Mode";
				local ShowFlag = flag .. ".ShowInList";
				local row = Library:CreateInstance("Frame", {
					Name = "KeybindRow_" .. KeybindName;
					Parent = self.Content;
					Size = NewUdim2(1, 0, 0, 16);
					BackgroundTransparency = 1;
					BorderSizePixel = 0;
					ZIndex = 2;
				});
				local label = Library:CreateInstance("TextLabel", {
					Name = "Label";
					Parent = row;
					AnchorPoint = NewVector2(0, 0.5);
					Position = NewUdim2(0, 0, 0.5, -1);
					Size = NewUdim2(1, -44, 1, 0);
					BackgroundTransparency = 1;
					FontFace = Library.Fonts.title;
					Text = tostring(KeybindName);
					TextColor3 = hex("B4B4B4");
					TextSize = 9;
					TextXAlignment = Enum.TextXAlignment.Left;
					TextYAlignment = Enum.TextYAlignment.Center;
					ZIndex = 3;
				});
				if Tooltip then Library:Tooltip(label, { Title = KeybindName; Text = Tooltip }) end;

				local hit = Library:CreateInstance("TextButton", {
					Name = "Hit";
					Parent = row;
					AnchorPoint = NewVector2(1, 0.5);
					Position = NewUdim2(1, 0, 0.5, 0);
					Size = NewUdim2(0, 36, 0, 14);
					BackgroundColor3 = hex("07080A");
					BorderSizePixel = 0; AutoButtonColor = false; Text = "";
					ZIndex = 4;
				});
				Library:CreateInstance("Frame", {
					Parent = hit;
					Position = NewUdim2(0, 1, 0, 1); Size = NewUdim2(1, -2, 1, -2);
					BackgroundColor3 = hex("24262D"); BorderSizePixel = 0; ZIndex = 5;
				});
				local KeyLabel = Library:CreateInstance("TextLabel", {
					Name = "Key";
					Parent = hit;
					Position = NewUdim2(0, 1, 0, 1); Size = NewUdim2(1, -2, 1, -2);
					BackgroundColor3 = hex("1C1D23");
					BorderSizePixel = 0;
					FontFace = Library.Fonts.title;
					Text = "[-]";
					TextColor3 = hex("B4B4B4");
					TextSize = 9;
					TextXAlignment = Enum.TextXAlignment.Center;
					TextYAlignment = Enum.TextYAlignment.Center;
					ZIndex = 6;
				});
				Library:CreateInstance("UIPadding", {
					Parent = KeyLabel;
					PaddingBottom = NewUdim(0, 2);
				});

				local keybind = { Row = row, Label = label, KeyLabel = KeyLabel, Name = KeybindName, Flag = flag, Key = nil, Listening = false, Mode = Mode, Active = (Mode == "Always"), ShowInList = true };

				local function KeyDisplay(k)
					if k == nil then return "-" end;
					local mapped = Library.KeyNames[k];
					if mapped then return mapped end;
					local raw = tostring(k);
					return (raw:gsub("Enum.KeyCode.", "")):gsub("Enum.UserInputType.", "");
				end;

				function keybind:Set(k)
					self.Key = k;
					Library.Flags[self.Flag] = k;
					if k == nil then
						self.KeyLabel.Text = "[-]";
					else
						self.KeyLabel.Text = "[" .. KeyDisplay(k) .. "]";
					end;
					Library:UpdateKeybind(self);
				end;
				function keybind:Get() return self.Key end;
				function keybind:SetMode(mode)
					if mode ~= "Toggle" and mode ~= "Hold" and mode ~= "Always" then return end;
					local prev = self.Mode;
					self.Mode = mode;
					Library.Flags[ModeFlag] = mode;
					if mode == "Always" and prev ~= "Always" then
						self.Active = true;
						if typeof(callback) == "function" then callback(true, self.Key) end;
					elseif mode ~= "Always" and prev == "Always" then
						self.Active = false;
					end;
					Library:UpdateKeybind(self);
				end;

				Library:RegisterKeybind(keybind);
				Library:RegisterFlag(flag, DefaultKey, function(v) keybind:Set(v) end);
				Library:RegisterFlag(ModeFlag, Mode, function(v) keybind:SetMode(v) end);
				Library:RegisterFlag(ShowFlag, keybind.ShowInList, function(v)
					keybind.ShowInList = v ~= false;
					Library:UpdateKeybind(keybind);
				end);

				local ListenConn;
				Library:Connection(hit.MouseButton1Click, function()
					if keybind.Listening then return end;
					keybind.Listening = true;
					keybind.KeyLabel.Text = "[...]";
					if ListenConn then ListenConn:Disconnect() end;
					ListenConn = UserInputService.InputBegan:Connect(function(input, gpe)
						if UserInputService:GetFocusedTextBox() ~= nil then return end;
						local ut = input.UserInputType;
						local kc = input.KeyCode;
						local NewKey;
						if kc ~= Enum.KeyCode.Unknown then
							NewKey = kc;
						elseif ut == Enum.UserInputType.MouseButton1 or ut == Enum.UserInputType.MouseButton2 or ut == Enum.UserInputType.MouseButton3 then
							NewKey = ut;
						end;
						if NewKey == nil then return end;
						if kc == Enum.KeyCode.Escape or kc == Enum.KeyCode.Backspace then
							keybind:Set(nil);
						else
							keybind:Set(NewKey);
						end;
						keybind.Listening = false;
						if ListenConn then ListenConn:Disconnect(); ListenConn = nil; end;
					end);
				end);

				Library:Connection(hit.MouseButton2Click, function()
					Library:ModePopup(hit, keybind.Mode or "Toggle", function(m, show)
						keybind.ShowInList = show ~= false;
						Library.Flags[ShowFlag] = keybind.ShowInList;
						keybind:SetMode(m);
						Library:UpdateKeybind(keybind);
					end, keybind.ShowInList);
				end);

				Library:Connection(UserInputService.InputBegan, function(input, gpe)
					if (UserInputService:GetFocusedTextBox() ~= nil) or keybind.Listening or keybind.Key == nil then return end;
					if keybind.Mode == "Always" then return end;
					local match = (typeof(keybind.Key) == "EnumItem") and (input.KeyCode == keybind.Key or input.UserInputType == keybind.Key);
					if not match then return end;
					if keybind.Mode == "Toggle" then
						keybind.Active = not keybind.Active;
						Library:UpdateKeybind(keybind);
						if typeof(callback) == "function" then callback(keybind.Active, keybind.Key) end;
					elseif keybind.Mode == "Hold" then
						keybind.Active = true;
						Library:UpdateKeybind(keybind);
						if typeof(callback) == "function" then callback(true, keybind.Key) end;
					else
						if typeof(callback) == "function" then callback(keybind.Key) end;
					end;
				end);
				Library:Connection(UserInputService.InputEnded, function(input, gpe)
					if (UserInputService:GetFocusedTextBox() ~= nil) or keybind.Listening or keybind.Key == nil then return end;
					if keybind.Mode ~= "Hold" then return end;
					local match = (typeof(keybind.Key) == "EnumItem") and (input.KeyCode == keybind.Key or input.UserInputType == keybind.Key);
					if not match then return end;
					keybind.Active = false;
					Library:UpdateKeybind(keybind);
					if typeof(callback) == "function" then callback(false, keybind.Key) end;
				end);

				if DefaultKey ~= nil then keybind:Set(DefaultKey) end;

				return keybind;
			end;

			function SectionObj:Colorpicker(PickerName, DefaultColor, DefaultAlpha, callback, FlagOpt)
				local Tooltip;
				if typeof(PickerName) == "table" then
					local Data = PickerName;
					PickerName = Data.Name or Data.name or "Colorpicker";
					DefaultColor = Data.Default or Data.default;
					DefaultAlpha = Data.Alpha or Data.alpha;
					callback = Data.Callback or Data.callback;
					FlagOpt = Data.Flag or Data.flag;
					Tooltip = Data.Tooltip or Data.tooltip;
				end;
				local color = typeof(DefaultColor) == "Color3" and DefaultColor or FromRgb(255, 255, 255);
				local h, s, v = color:ToHSV();
				local a = MathClamp(tonumber(DefaultAlpha) or 1, 0, 1);
				local flag = Library:AutoFlag(FlagOpt or PickerName);

				local row = Library:CreateInstance("Frame", {
					Name = "Colorpicker_" .. PickerName;
					Parent = self.Content;
					Size = NewUdim2(1, 0, 0, 14);
					BackgroundTransparency = 1;
					BorderSizePixel = 0;
					ZIndex = 2;
				});

				local Label = Library:CreateInstance("TextLabel", {
					Name = "Label";
					Parent = row;
					AnchorPoint = NewVector2(0, 0.5);
					Position = NewUdim2(0, 0, 0.5, 0);
					Size = NewUdim2(1, -32, 1, 0);
					BackgroundTransparency = 1;
					FontFace = Library.Fonts.title;
					Text = tostring(PickerName);
					TextColor3 = FromRgb(255, 255, 255);
					TextSize = 9;
					TextXAlignment = Enum.TextXAlignment.Left;
					TextYAlignment = Enum.TextYAlignment.Center;
					ZIndex = 3;
				});
				if Tooltip then Library:Tooltip(Label, { Title = PickerName; Text = Tooltip }) end;

				local swatch = Library:CreateInstance("TextButton", {
					Name = "Swatch";
					Parent = row;
					AnchorPoint = NewVector2(1, 0.5);
					Position = NewUdim2(1, 0, 0.5, 0);
					Size = NewUdim2(0, 24, 0, 14);
					BackgroundColor3 = hex("07080A");
					BorderSizePixel = 0;
					AutoButtonColor = false;
					Text = "";
					ZIndex = 3;
				});
				local SwInline = Library:CreateInstance("Frame", {
					Name = "Inline";
					Parent = swatch;
					Position = NewUdim2(0, 1, 0, 1);
					Size = NewUdim2(1, -2, 1, -2);
					BackgroundColor3 = hex("24262D");
					BorderSizePixel = 0;
					ZIndex = 4;
				});
				local SwHandle = Library:CreateInstance("Frame", {
					Name = "Handle";
					Parent = SwInline;
					Position = NewUdim2(0, 1, 0, 1);
					Size = NewUdim2(1, -2, 1, -2);
					BackgroundColor3 = FromRgb(255, 255, 255);
					BorderSizePixel = 0;
					ZIndex = 5;
				});
				Library:CreateInstance("ImageLabel", {
					Name = "Checkers";
					Parent = SwHandle;
					Size = NewUdim2(1, 0, 1, 0);
					BackgroundTransparency = 1;
					BorderSizePixel = 0;
					Image = "rbxassetid://18274452449";
					ScaleType = Enum.ScaleType.Tile;
					TileSize = FromOffset(6, 6);
					ZIndex = 6;
				});
				local SwFill = Library:CreateInstance("Frame", {
					Name = "Fill";
					Parent = SwHandle;
					Size = NewUdim2(1, 0, 1, 0);
					BackgroundColor3 = color;
					BackgroundTransparency = 1 - a;
					BorderSizePixel = 0;
					ZIndex = 7;
				});
				Library:CreateInstance("UIGradient", {
					Parent = SwFill;
					Rotation = 90;
					Color = NewColorSequence(FromRgb(255, 255, 255), FromRgb(167, 167, 167));
				});

				local PICKER_W, PICKER_H = 190, 180;
				local picker = Library:CreateInstance("Frame", {
					Name = "Picker_" .. PickerName;
					Parent = pickerGui;
					Size = FromOffset(PICKER_W, PICKER_H);
					BackgroundColor3 = hex("07080A");
					BorderSizePixel = 0;
					Active = true;
					Visible = false;
					ClipsDescendants = true;
					ZIndex = 50;
				});
				local PickerMid = Library:CreateInstance("Frame", {
					Name = "Mid";
					Parent = picker;
					Position = NewUdim2(0, 1, 0, 1);
					Size = NewUdim2(1, -2, 1, -2);
					BackgroundColor3 = hex("24262D");
					BorderSizePixel = 0;
					ZIndex = 51;
				});
				local PickerBody = Library:CreateInstance("Frame", {
					Name = "Body";
					Parent = PickerMid;
					Position = NewUdim2(0, 1, 0, 1);
					Size = NewUdim2(1, -2, 1, -2);
					BackgroundColor3 = hex("101114");
					BorderSizePixel = 0;
					ZIndex = 52;
				});
				Library:CreateInstance("UIPadding", {
					Parent = PickerBody;
					PaddingTop = NewUdim(0, 8);
					PaddingBottom = NewUdim(0, 8);
					PaddingLeft = NewUdim(0, 8);
					PaddingRight = NewUdim(0, 8);
				});

				local SatVal = Library:CreateInstance("Frame", {
					Name = "PickerUI";
					Parent = PickerBody;
					Size = NewUdim2(1, -30, 1, 0);
					BackgroundColor3 = FromRgb(255, 0, 0);
					BorderSizePixel = 0;
					ZIndex = 53;
				});
				local SatLayer = Library:CreateInstance("TextButton", {
					Name = "Sat";
					Parent = SatVal;
					Size = NewUdim2(1, 0, 1, 0);
					BackgroundColor3 = FromRgb(255, 255, 255);
					BorderSizePixel = 0;
					AutoButtonColor = false;
					Text = "";
					ZIndex = 54;
				});
				Library:CreateInstance("UIGradient", {
					Parent = SatLayer;
					Transparency = NewNumberSequence({
						NewNumberSequenceKeypoint(0, 0);
						NewNumberSequenceKeypoint(1, 1);
					});
					Color = NewColorSequence(FromRgb(255, 255, 255), FromRgb(255, 255, 255));
				});
				local ValLayer = Library:CreateInstance("TextButton", {
					Name = "Val";
					Parent = SatVal;
					Size = NewUdim2(1, 0, 1, 0);
					BackgroundColor3 = FromRgb(0, 0, 0);
					BorderSizePixel = 0;
					AutoButtonColor = false;
					Text = "";
					ZIndex = 55;
				});
				Library:CreateInstance("UIGradient", {
					Parent = ValLayer;
					Rotation = 90;
					Color = NewColorSequence(FromRgb(0, 0, 0), FromRgb(0, 0, 0));
					Transparency = NewNumberSequence({
						NewNumberSequenceKeypoint(0, 1);
						NewNumberSequenceKeypoint(1, 0);
					});
				});
				local SatValMarker = Library:CreateInstance("Frame", {
					Name = "Marker";
					Parent = SatVal;
					Size = FromOffset(2, 2);
					BorderSizePixel = 1;
					BorderColor3 = FromRgb(0, 0, 0);
					BackgroundColor3 = FromRgb(255, 255, 255);
					ZIndex = 56;
				});

				local hue = Library:CreateInstance("TextButton", {
					Name = "PickerUI";
					Parent = PickerBody;
					AnchorPoint = NewVector2(1, 0);
					Position = NewUdim2(1, -14, 0, 0);
					Size = NewUdim2(0, 12, 1, 0);
					BackgroundColor3 = FromRgb(255, 255, 255);
					BorderSizePixel = 0;
					AutoButtonColor = false;
					Text = "";
					ZIndex = 53;
				});
				Library:CreateInstance("UIGradient", {
					Parent = hue;
					Rotation = 270;
					Color = NewColorSequence({
						NewColorSequenceKeypoint(0.00, FromRgb(255, 0, 0));
						NewColorSequenceKeypoint(0.17, FromRgb(255, 255, 0));
						NewColorSequenceKeypoint(0.33, FromRgb(0, 255, 0));
						NewColorSequenceKeypoint(0.50, FromRgb(0, 255, 255));
						NewColorSequenceKeypoint(0.67, FromRgb(0, 0, 255));
						NewColorSequenceKeypoint(0.83, FromRgb(255, 0, 255));
						NewColorSequenceKeypoint(1.00, FromRgb(255, 0, 0));
					});
				});
				local HueMarker = Library:CreateInstance("Frame", {
					Name = "Marker";
					Parent = hue;
					Size = NewUdim2(1, 0, 0, 2);
					BorderSizePixel = 1;
					BorderColor3 = FromRgb(0, 0, 0);
					BackgroundColor3 = FromRgb(255, 255, 255);
					ZIndex = 54;
				});

				local alpha = Library:CreateInstance("TextButton", {
					Name = "Alpha";
					Parent = PickerBody;
					AnchorPoint = NewVector2(1, 0);
					Position = NewUdim2(1, 0, 0, 0);
					Size = NewUdim2(0, 12, 1, 0);
					BackgroundColor3 = color;
					BorderSizePixel = 0;
					AutoButtonColor = false;
					Text = "";
					ZIndex = 53;
				});
				local AlphaCheckers = Library:CreateInstance("ImageLabel", {
					Name = "Checkers";
					Parent = alpha;
					Size = NewUdim2(1, 0, 1, 0);
					BackgroundTransparency = 1;
					BorderSizePixel = 0;
					Image = "rbxassetid://18274452449";
					ScaleType = Enum.ScaleType.Tile;
					TileSize = FromOffset(6, 6);
					ZIndex = 54;
				});
				Library:CreateInstance("UIGradient", {
					Parent = AlphaCheckers;
					Rotation = 270;
					Transparency = NewNumberSequence({
						NewNumberSequenceKeypoint(0, 0);
						NewNumberSequenceKeypoint(1, 1);
					});
				});
				local AlphaMarker = Library:CreateInstance("Frame", {
					Name = "Marker";
					Parent = alpha;
					Size = NewUdim2(1, 0, 0, 2);
					BackgroundColor3 = FromRgb(255, 255, 255);
					BorderSizePixel = 1;
					BorderColor3 = FromRgb(0, 0, 0);
					ZIndex = 55;
				});

				local cp = { Swatch = swatch, Picker = picker, Name = PickerName, Flag = flag, Color = color, Transparency = 1 - a };
				local function ApplyState()
					local c = FromHsv(h, s, v);
					color = c;
					local t = 1 - a;
					cp.Color = c;
					cp.Transparency = t;
					Library.Flags[flag] = { Color = c, Transparency = t };
					SwFill.BackgroundColor3 = c;
					SwFill.BackgroundTransparency = t;
					alpha.BackgroundColor3 = c;
					SatVal.BackgroundColor3 = FromHsv(h, 1, 1);
					local SOff = (s < 1) and 0 or -3;
					local VOff = ((1 - v) < 1) and 0 or -3;
					SatValMarker.Position = NewUdim2(s, SOff, 1 - v, VOff);
					local HOff = ((1 - h) < 1) and 0 or -2;
					HueMarker.Position = NewUdim2(0, 0, 1 - h, HOff);
					local AOff = ((1 - a) < 1) and 0 or -2;
					AlphaMarker.Position = NewUdim2(0, 0, 1 - a, AOff);
					if typeof(callback) == "function" then callback(c, a) end;
				end;

				function cp:Get() return color, a end;
				function cp:Set(NewColor, NewAlpha)
					if typeof(NewColor) == "table" and NewColor.Color ~= nil then
						if typeof(NewColor.Color) == "Color3" then h, s, v = NewColor.Color:ToHSV() end;
						if NewColor.Transparency ~= nil then a = 1 - MathClamp(tonumber(NewColor.Transparency) or (1 - a), 0, 1) end;
					else
						if typeof(NewColor) == "Color3" then h, s, v = NewColor:ToHSV() end;
						if NewAlpha ~= nil then a = MathClamp(tonumber(NewAlpha) or a, 0, 1) end;
					end;
					ApplyState();
				end;

				ApplyState();
				Library:RegisterFlag(flag, { Color = color, Transparency = 1 - a }, function(v) cp:Set(v) end);

				local open = false;
				local function reposition()
				local p = swatch.AbsolutePosition;
				local _, _, sc = Library:GuiPoint(gui, 0, 0);
				local sw = swatch.AbsoluteSize;
				local px, py = Library:GuiPoint(gui, p.X - PICKER_W * sc + sw.X, p.Y + sw.Y + 2);
				picker.Position = NewUdim2(0, px, 0, py);
				end;
				local PickerTween;
				local PICKER_ANIM = NewTweenInfo(0.15, Enum.EasingStyle.Quad, Enum.EasingDirection.Out);
				local function SetOpen(b)
					open = b;
					if PickerTween then PickerTween:Cancel() end;
					if b then
						reposition();
						picker.Size = FromOffset(PICKER_W, 0);
						picker.Visible = true;
						PickerTween = TweenService:Create(picker, PICKER_ANIM, { Size = FromOffset(PICKER_W, PICKER_H) });
						PickerTween:Play();
					else
						PickerTween = TweenService:Create(picker, PICKER_ANIM, { Size = FromOffset(PICKER_W, 0) });
						PickerTween:Play();
						PickerTween.Completed:Once(function()
							if not open then picker.Visible = false end;
						end);
					end;
				end;

				local DraggingSv, DraggingH, DraggingA = false, false, false;
				Library:Connection(swatch.MouseButton1Click, function() SetOpen(not open) end);
				Library:RegisterPopup(function() if open then SetOpen(false) end end);
				Library:Connection(swatch.MouseButton2Click, function()
					if (UserInputService:IsKeyDown(Enum.KeyCode.LeftControl) or UserInputService:IsKeyDown(Enum.KeyCode.RightControl)) and Library.CopiedColor then
						cp:Set(Library.CopiedColor);
					else
						Library.CopiedColor = { Color = color; Transparency = 1 - a };
					end;
				end);
				local function HookDown(inst, setter)
					Library:Connection(inst.InputBegan, function(input)
						if input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.Touch then
							setter(true);
						end;
					end);
				end;
				HookDown(SatLayer, function(b) DraggingSv = b end);
				HookDown(ValLayer, function(b) DraggingSv = b end);
				HookDown(hue, function(b) DraggingH = b end);
				HookDown(alpha, function(b) DraggingA = b end);

				Library:Connection(UserInputService.InputEnded, function(input)
					if input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.Touch then
						DraggingSv = false; DraggingH = false; DraggingA = false;
					end;
				end);
				Library:Connection(UserInputService.InputChanged, function(input)
					if input.UserInputType ~= Enum.UserInputType.MouseMovement and input.UserInputType ~= Enum.UserInputType.Touch then return end;
					if not (DraggingSv or DraggingH or DraggingA) then return end;
					local mx, my = Library:MousePoint(gui, input);
					if DraggingSv then
						local ap, sz = SatVal.AbsolutePosition, SatVal.AbsoluteSize;
						s = sz.X > 0 and MathClamp((mx - ap.X) / sz.X, 0, 1) or 0;
						v = sz.Y > 0 and 1 - MathClamp((my - ap.Y) / sz.Y, 0, 1) or 0;
					elseif DraggingH then
						local ap, sz = hue.AbsolutePosition, hue.AbsoluteSize;
						h = sz.Y > 0 and 1 - MathClamp((my - ap.Y) / sz.Y, 0, 1) or 0;
					elseif DraggingA then
						local ap, sz = alpha.AbsolutePosition, alpha.AbsoluteSize;
						a = sz.Y > 0 and 1 - MathClamp((my - ap.Y) / sz.Y, 0, 1) or 0;
					end;
					ApplyState();
				end);
				Library:Connection(UserInputService.InputBegan, function(input)
					if input.UserInputType ~= Enum.UserInputType.MouseButton1 then return end;
					if not open then return end;
					local mx, my = Library:MousePoint(gui, input);
					if not Library:PointInObject(picker, mx, my, 2) and not Library:PointInObject(swatch, mx, my, 2) then SetOpen(false) end;
				end);

				return cp;
			end;

			insert(self.Sections, SectionObj);
			if self.RefreshCanvases then
				task.defer(function()
					self:RefreshCanvases();
				end);
			end;

			if IsMulti then
				local subs = {};
				subs[1] = SectionObj;
				subs[PrimaryName] = SectionObj;
				for i = 2, #SectionNames do
					local sub = setmetatable({
						Outer = SectionOuter;
						Body  = SectionBody;
						Content = SubContents[i];
						Name = tostring(SectionNames[i]);
					}, { __index = SectionObj });
					subs[i] = sub;
					subs[sub.Name] = sub;
					insert(self.Sections, sub);
				end;
				return subs;
			end;

			return SectionObj;
		end;

		Library._BuildSection = Library._BuildSection or tab.Section;

			function tab:Subtab(SubName)
			if not self.SubtabStrip then
				self.Content.Visible = false;
				self.SubtabStrip = Library:CreateInstance("Frame", {
					Name = "SubtabStrip";
					Parent = InnerBody;
					Position = NewUdim2(0, 2, 0, 27);
					Size = NewUdim2(1, -4, 0, 16);
					BackgroundTransparency = 1;
					BorderSizePixel = 0;
					Visible = self.Active;
					ZIndex = 3;
				});
				Library:CreateInstance("UIListLayout", {
					Parent = self.SubtabStrip;
					FillDirection = Enum.FillDirection.Horizontal;
					SortOrder = Enum.SortOrder.LayoutOrder;
				});
				self.SubtabHolder = Library:CreateInstance("Frame", {
					Name = "SubtabHolder";
					Parent = InnerBody;
					Position = NewUdim2(0, 10, 0, 45);
					Size = NewUdim2(1, -20, 1, -55);
					BackgroundTransparency = 1;
					Visible = self.Active;
					ZIndex = 2;
				});
				self.Subtabs = {};
				self.SubtabStripFadeConn = nil;
				local PrevSetActive = self.SetActive;
				function self:SetActive(active)
					PrevSetActive(self, active);
					self.SubtabStrip.Visible = active;
					self.SubtabHolder.Visible = active;
					if self.SubtabStripFadeConn then self.SubtabStripFadeConn:Disconnect(); self.SubtabStripFadeConn = nil end;
					if active then
						local StripStart = tick();
						local StripDur = 0.22;
						self.SubtabStripFadeConn = RunService.RenderStepped:Connect(function()
							local p = MathClamp((tick() - StripStart) / StripDur, 0, 1);
							local e = 1 - (1 - p) * (1 - p);
							if p >= 1 then
								if self.SubtabStripFadeConn then self.SubtabStripFadeConn:Disconnect(); self.SubtabStripFadeConn = nil end;
							end;
						end);
						if self.ActiveSubtab then
							local sub = self.ActiveSubtab;
							sub.Active = false;
							sub:SetActive(true);
						end;
					else
					end;
				end;
			end;

			local order = #self.Subtabs + 1;
			local SubOuter = Library:CreateInstance("Frame", {
				Name = "SubTab_" .. order;
				Parent = self.SubtabStrip;
				Size = NewUdim2(0, 0, 1, 0);
				AutomaticSize = Enum.AutomaticSize.X;
				BackgroundTransparency = 1;
				LayoutOrder = order;
				ZIndex = 3;
			});
			local SubLabel = Library:CreateInstance("TextLabel", {
				Name = "Label"; Parent = SubOuter;
				AnchorPoint = NewVector2(0, 0);
				Position = NewUdim2(0, 0, 0, 6);
				Size = NewUdim2(0, 0, 0, 9);
				AutomaticSize = Enum.AutomaticSize.X;
				BackgroundTransparency = 1;
				FontFace = Library.Fonts.title;
				Text = tostring(SubName);
				TextColor3 = hex("8A8A92");
				TextSize = 9;
				TextXAlignment = Enum.TextXAlignment.Center;
				ZIndex = 5;
			});
			Library:CreateInstance("UIPadding", {
				Parent = SubLabel;
				PaddingLeft = NewUdim(0, 8);
				PaddingRight = NewUdim(0, 8);
			});
			local SubButton = Library:CreateInstance("TextButton", {
				Parent = SubOuter;
				Size = NewUdim2(1, 0, 1, 0);
				BackgroundTransparency = 1;
				AutoButtonColor = false; Text = ""; ZIndex = 6;
			});

			local SubContent = Library:CreateInstance("Frame", {
				Name = "SubContent_" .. order;
				Parent = self.SubtabHolder;
				Position = NewUdim2(0, 0, 0, 0);
				Size = NewUdim2(1, 0, 1, 0);
				BackgroundTransparency = 1;
				BorderSizePixel = 0;
				Visible = false;
				ZIndex = 2;
			});
			Library:CreateInstance("UIListLayout", {
				Parent = SubContent;
				FillDirection = Enum.FillDirection.Horizontal;
				SortOrder = Enum.SortOrder.LayoutOrder;
				Padding = NewUdim(0, 8);
			});
			local SubLeft = Library:CreateInstance("ScrollingFrame", {
				Name = "LeftCol"; Parent = SubContent;
				Size = NewUdim2(0.5, -4, 1, 0);
				BackgroundTransparency = 1;
				BorderSizePixel = 0;
				CanvasSize = NewUdim2(0, 0, 0, 0);
				AutomaticCanvasSize = Enum.AutomaticSize.Y;
				ScrollingDirection = Enum.ScrollingDirection.Y;
				ScrollBarThickness = 2;
				ScrollBarImageColor3 = Library.AccentColor or hex("98BCFF");
				ScrollBarImageTransparency = 0.15;
				ClipsDescendants = true;
				Active = true;
				LayoutOrder = 1;
				ZIndex = 2;
			});
			Library:CreateInstance("UIPadding", { Parent = SubLeft; PaddingTop = NewUdim(0, 8); PaddingRight = NewUdim(0, 4) });
			local SubLeftLayout = Library:CreateInstance("UIListLayout", {
				Parent = SubLeft;
				FillDirection = Enum.FillDirection.Vertical;
				SortOrder = Enum.SortOrder.LayoutOrder;
				Padding = NewUdim(0, 10);
			});
			local RefreshSubLeftCanvas = BindScrollCanvas(SubLeft, SubLeftLayout);
			local SubRight = Library:CreateInstance("ScrollingFrame", {
				Name = "RightCol"; Parent = SubContent;
				Size = NewUdim2(0.5, -4, 1, 0);
				BackgroundTransparency = 1;
				BorderSizePixel = 0;
				CanvasSize = NewUdim2(0, 0, 0, 0);
				AutomaticCanvasSize = Enum.AutomaticSize.Y;
				ScrollingDirection = Enum.ScrollingDirection.Y;
				ScrollBarThickness = 2;
				ScrollBarImageColor3 = Library.AccentColor or hex("98BCFF");
				ScrollBarImageTransparency = 0.15;
				ClipsDescendants = true;
				Active = true;
				LayoutOrder = 2;
				ZIndex = 2;
			});
			Library:CreateInstance("UIPadding", { Parent = SubRight; PaddingTop = NewUdim(0, 8); PaddingRight = NewUdim(0, 4) });
			local SubRightLayout = Library:CreateInstance("UIListLayout", {
				Parent = SubRight;
				FillDirection = Enum.FillDirection.Vertical;
				SortOrder = Enum.SortOrder.LayoutOrder;
				Padding = NewUdim(0, 10);
			});
			local RefreshSubRightCanvas = BindScrollCanvas(SubRight, SubRightLayout);

			local subtab = {
				Name = SubName; Label = SubLabel; Content = SubContent;
				LeftCol = SubLeft; RightCol = SubRight;
				Sections = {}; Active = false;
			};
			function subtab:RefreshCanvases()
				RefreshSubLeftCanvas();
				RefreshSubRightCanvas();
			end;
			local SubColorInfo = NewTweenInfo(0.15, Enum.EasingStyle.Linear);
			local SubFadeConn;
			local SubBasePos = NewUdim2(0, 0, 0, 0);
			local SubOffPos = NewUdim2(0, 0, 0, 8);
			function subtab:SetActive(active)
				if self.Active == active then return end;
				self.Active = active;
				if SubFadeConn then SubFadeConn:Disconnect(); SubFadeConn = nil end;
				local ContentRef = self.Content;
				Library:Tween(SubLabel, SubColorInfo, {
					TextColor3 = active and (Library.ShadeColor or hex("6E8CC8")) or hex("8A8A92");
				}):Play();
				if active then
					ContentRef.Position = SubOffPos;
					ContentRef.Visible = true;
					task.defer(function()
						Library:RefreshSettings();
						self:RefreshCanvases();
					end);
					task.delay(0.05, function()
						Library:RefreshSettings();
						self:RefreshCanvases();
					end);
					local StartT = tick();
					local Duration = 0.22;
					SubFadeConn = RunService.RenderStepped:Connect(function()
						local p = MathClamp((tick() - StartT) / Duration, 0, 1);
						local e = 1 - (1 - p) * (1 - p);
						ContentRef.Position = NewUdim2(0, 0, 0, MathFloor(8 * (1 - e) + 0.5));
						if p >= 1 then
							if SubFadeConn then SubFadeConn:Disconnect(); SubFadeConn = nil end;
						end;
					end);
				else
					ContentRef.Visible = false;
					ContentRef.Position = SubBasePos;
				end;
			end;
			subtab.Section = tab.Section;

			Library:Connection(SubButton.MouseButton1Down, function()
				if tab.ActiveSubtab == subtab then return end;
				if tab.ActiveSubtab then tab.ActiveSubtab:SetActive(false) end;
				subtab:SetActive(true);
				tab.ActiveSubtab = subtab;
			end);
			Library:Connection(SubButton.MouseEnter, function()
				if not subtab.Active then
					Library:Tween(SubLabel, SubColorInfo, { TextColor3 = FromRgb(255, 255, 255) }):Play();
				end;
			end);
			Library:Connection(SubButton.MouseLeave, function()
				if not subtab.Active then
					Library:Tween(SubLabel, SubColorInfo, { TextColor3 = hex("8A8A92") }):Play();
				end;
			end);

			insert(self.Subtabs, subtab);
			if not self.ActiveSubtab then
				subtab:SetActive(true);
				self.ActiveSubtab = subtab;
			end;
			return subtab;
		end;

		insert(self.Tabs, tab);
		if #self.Tabs == 1 then self:SetActiveTab(tab) end;
		return tab;
	end;

	local WindowToggleTween = NewTweenInfo(0.14, Enum.EasingStyle.Quad, Enum.EasingDirection.Out);
	function window:SetVisible(on)
		on = on == true;
		self.Visible = on;
		if on then
			gui.Enabled = true;
			WindowScale.Scale = 0.96;
			Library:Tween(WindowScale, WindowToggleTween, { Scale = 1 }):Play();
		else
			Library:CloseAllPopups();
			local Tween = Library:Tween(WindowScale, WindowToggleTween, { Scale = 0.96 });
			Tween:Play();
			Tween.Completed:Once(function()
				if not self.Visible then gui.Enabled = false end;
			end);
		end;
		if Library.FixDim then Library:FixDim() end;
		Library:SaveWidgetState(self);
		Library:SetNotifAnchorVisible(on);
	end;
	function window:Toggle() self:SetVisible(not self.Visible) end;
	function window:Destroy()
		if gui and gui.Parent then gui:Destroy() end;
		if Library.CurrentWindow == window then Library.CurrentWindow = nil end;
		if Library.FixDim then Library:FixDim() end;
	end;

	self.CurrentWindow = window;
	self:TrackWidget(window, "Window");
	self:FixDim();
	self:SetNotifAnchorVisible(window.Visible == true);
	self:Log("Window created");
	return window;
end;

--// Configs
Library.ConfigFlags = Library.ConfigFlags or {};

function Library:AutoFlag(hint)
	local base = tostring(hint or "flag"):gsub("[^%w_]", "_");
	if base == "" then base = "flag" end;
	if self.Flags[base] == nil then return base end;
	local i = 2;
	while self.Flags[base .. "_" .. i] ~= nil do i = i + 1 end;
	return base .. "_" .. i;
end;

function Library:RegisterFlag(flag, default, setter)
	self.ConfigFlags[flag] = setter;
	if self.PendingFlags and self.PendingFlags[flag] ~= nil then
		local pending = self.PendingFlags[flag];
		self.PendingFlags[flag] = nil;
		self.Flags[flag] = pending;
		if typeof(setter) == "function" then
			setter(pending);
		end;
	else
		self.Flags[flag] = default;
	end;
end;

function Library:GetConfig()
	local out = {};
	for k, val in self.Flags do
		if typeof(val) == "Color3" then
			out[k] = { type = "Color3"; hex = val:ToHex() };
		elseif typeof(val) == "EnumItem" then
			out[k] = { type = "EnumItem"; enum = tostring(val.EnumType); name = val.Name };
		elseif typeof(val) == "table" and typeof(val.Color) == "Color3" then
			out[k] = { type = "ColorAlpha"; hex = val.Color:ToHex(); transparency = tonumber(val.Transparency) or 0 };
		else
			out[k] = val;
		end;
	end;
	return JsonEncode(out);
end;

function Library:LoadConfig(text)
	local ok, data = pcall(JsonDecode, text);
	if not ok or typeof(data) ~= "table" then return end;
	self.PendingFlags = self.PendingFlags or {};
	local function DecodeValue(val)
		if typeof(val) == "table" and val.type == "Color3" and typeof(val.hex) == "string" then
			local ok2, c = pcall(Color3.fromHex, val.hex);
			if ok2 then val = c end;
		elseif typeof(val) == "table" and val.type == "ColorAlpha" and typeof(val.hex) == "string" then
			local ok2, c = pcall(Color3.fromHex, val.hex);
			if ok2 then val = { Color = c, Transparency = tonumber(val.transparency) or 0 } end;
		elseif typeof(val) == "table" and val.type == "EnumItem" then
			local et = Enum[val.enum];
			if et then
				local ok2, item = pcall(function() return et[val.name] end);
				if ok2 then val = item end;
			end;
		end;
		return val;
	end;
	local AppearanceOrder = {
		"appearance.theme";
		"appearance.AccentColor";
		"appearance.ShadeColor";
		"appearance.WindowBgColor";
	};
	local AppearanceSet = {};
	for _, flag in AppearanceOrder do AppearanceSet[flag] = true end;
	local function ApplyFlag(k, val)
		self.Flags[k] = val;
		local fn = self.ConfigFlags[k];
		if typeof(fn) == "function" then
			fn(val);
		else
			self.PendingFlags[k] = val;
		end;
	end;
	for k, val in data do
		if not AppearanceSet[k] then
			ApplyFlag(k, DecodeValue(val));
		end;
	end;
	-- A selected preset establishes its base palette. Explicit saved colors must
	-- be applied afterward so customized accent/shade/background values win.
	for _, flag in AppearanceOrder do
		if data[flag] ~= nil then
			ApplyFlag(flag, DecodeValue(data[flag]));
		end;
	end;
	task.defer(function()
		self:RefreshSettings();
		for _, Tab in self.CurrentWindow and self.CurrentWindow.Tabs or {} do
			if Tab.RefreshCanvases then Tab:RefreshCanvases() end;
			for _, Subtab in Tab.Subtabs or {} do
				if Subtab.RefreshCanvases then Subtab:RefreshCanvases() end;
			end;
		end;
	end);
	task.delay(0.05, function()
		self:RefreshSettings();
		for _, Tab in self.CurrentWindow and self.CurrentWindow.Tabs or {} do
			if Tab.RefreshCanvases then Tab:RefreshCanvases() end;
			for _, Subtab in Tab.Subtabs or {} do
				if Subtab.RefreshCanvases then Subtab:RefreshCanvases() end;
			end;
		end;
	end);
end;

function Library:ConfigPath(name)
	local safe = tostring(name):gsub("[<>:\"/\\|%?%*]", "_");
	return self.Directory .. "/Configs/" .. safe .. ".cfg";
end;

function Library:ListConfigs()
	local out = {};
	if typeof(listfiles) == "function" then
		local ok, files = pcall(listfiles, self.Directory .. "/Configs");
		if ok and typeof(files) == "table" then
			for _, p in files do
				local n = tostring(p):match("([^/\\]+)%.cfg$");
				if n then insert(out, n) end;
			end;
		end;
	end;
	table.sort(out);
	return out;
end;

function Library:Configs(opts)
	opts = typeof(opts) == "table" and opts or {};

	if typeof(self.CurrentConfigs) == "table" and typeof(self.CurrentConfigs.Gui) == "Instance" and self.CurrentConfigs.Gui.Parent then
		self.CurrentConfigs.Gui:Destroy();
	end;
	self.CurrentConfigs = nil;

	local w = tonumber(opts.width) or 240;
	local h = tonumber(opts.height) or 330;
	local TitleText = tostring(opts.title or "Configs");

	local VpSize = camera.ViewportSize;
	local UiScale = self:ComputeUIScale();
	local DefaultX = MathClamp(tonumber(opts.x) or 650, 0, MathMax(0, VpSize.X / UiScale - w));
	local DefaultY = MathClamp(tonumber(opts.y) or 70, 0, MathMax(0, VpSize.Y / UiScale - h));
	local pos = opts.position or NewUdim2(0, DefaultX, 0, DefaultY);

	local gui = self:CreateInstance("ScreenGui", {
		Name = "\0";
		Parent = (gethui and gethui()) or CoreGui;
		Enabled = true;
		DisplayOrder = self.WidgetDisplayOrder or 1002;
		IgnoreGuiInset = true;
		ResetOnSpawn = false;
		ZIndexBehavior = Enum.ZIndexBehavior.Global;
	});
	self:ApplyScale(gui);

	local outer = self:CreateInstance("Frame", {
		Name = "Outer";
		Parent = gui;
		Position = pos;
		Size = FromOffset(w, h);
		BackgroundColor3 = hex("07080A");
		BorderSizePixel = 0;
		Active = true;
	});
	self:CreateInstance("ImageLabel", {
		Name = "Glow";
		Parent = outer;
		AnchorPoint = NewVector2(0.5, 0.5);
		Position = NewUdim2(0.5, 0, 0.5, 0);
		Size = NewUdim2(1, 30, 1, 30);
		BackgroundTransparency = 1;
		Image = "rbxassetid://18245826428";
		ImageColor3 = hex("98BCFF");
		ImageTransparency = 0.86;
		ScaleType = Enum.ScaleType.Slice;
		SliceCenter = RectNew(21, 21, 79, 79);
		ZIndex = -1;
	});
	local inner = self:CreateInstance("Frame", {
		Name = "Inner";
		Parent = outer;
		Position = NewUdim2(0, 1, 0, 1);
		Size = NewUdim2(1, -2, 1, -2);
		BackgroundColor3 = hex("24262D");
		BorderSizePixel = 0;
	});
	local main = self:CreateInstance("Frame", {
		Name = "Main";
		Parent = inner;
		Position = NewUdim2(0, 1, 0, 1);
		Size = NewUdim2(1, -2, 1, -2);
		BackgroundColor3 = FromRgb(255, 255, 255);
		BorderSizePixel = 0;
	});
	self:CreateInstance("UIGradient", {
		Parent = main; Rotation = 90;
		Color = NewColorSequence(hex("131418"), hex("17181D"));
	});
	self:CreateInstance("Frame", {
		Name = "TopAccent";
		Parent = main;
		Position = NewUdim2(0, 0, 0, 0);
		Size = NewUdim2(1, 0, 0, 1);
		BackgroundColor3 = hex("98BCFF");
		BorderSizePixel = 0;
		ZIndex = 2;
	});
	self:CreateInstance("Frame", {
		Name = "TopAccentShade";
		Parent = main;
		Position = NewUdim2(0, 0, 0, 1);
		Size = NewUdim2(1, 0, 0, 1);
		BackgroundColor3 = hex("6E8CC8");
		BorderSizePixel = 0;
		ZIndex = 2;
	});
	local TitleLabel = self:CreateInstance("TextLabel", {
		Name = "Title";
		Parent = main;
		Position = NewUdim2(0, 10, 0, 5);
		Size = NewUdim2(1, -20, 0, 14);
		BackgroundTransparency = 1;
		FontFace = Library.Fonts.title;
		Text = TitleText;
		TextColor3 = FromRgb(255, 255, 255);
		TextSize = 9;
		TextXAlignment = Enum.TextXAlignment.Left;
		TextYAlignment = Enum.TextYAlignment.Top;
		ZIndex = 5;
	});
	local HeaderDrag = self:CreateInstance("Frame", {
		Name = "HeaderDrag";
		Parent = main;
		Position = NewUdim2(0, 0, 0, 0);
		Size = NewUdim2(1, 0, 0, 22);
		BackgroundTransparency = 1;
		Active = true;
		ZIndex = 4;
	});
	self:CreateInstance("UIGradient", {
		Parent = TitleLabel;
		Color = NewColorSequence(hex("98BCFF"), hex("6E8CC8"));
		Rotation = 90;
	});

	local section = self:CreateInstance("Frame", {
		Name = "Section";
		Parent = main;
		Position = NewUdim2(0, 6, 0, 22);
		Size = NewUdim2(1, -12, 1, -28);
		BackgroundColor3 = FromRgb(255, 255, 255);
		BorderSizePixel = 0;
		ZIndex = 2;
	});
	self:CreateInstance("UIGradient", {
		Parent = section; Rotation = 90;
		Color = NewColorSequence(hex("131418"), hex("17181D"));
	});

	local ListBg = self:CreateInstance("Frame", {
		Name = "ListBg";
		Parent = section;
		Position = NewUdim2(0, 8, 0, 8);
		Size = NewUdim2(1, -16, 1, -98);
		BackgroundColor3 = hex("07080A");
		BorderSizePixel = 0;
		ZIndex = 3;
	});
	local ListMid = self:CreateInstance("Frame", {
		Name = "Mid";
		Parent = ListBg;
		Position = NewUdim2(0, 1, 0, 1);
		Size = NewUdim2(1, -2, 1, -2);
		BackgroundColor3 = hex("24262D");
		BorderSizePixel = 0;
		ZIndex = 3;
	});
	local ListInner = self:CreateInstance("Frame", {
		Name = "Inner";
		Parent = ListMid;
		Position = NewUdim2(0, 1, 0, 1);
		Size = NewUdim2(1, -2, 1, -2);
		BackgroundColor3 = FromRgb(255, 255, 255);
		BorderSizePixel = 0;
		ZIndex = 3;
	});
	self:CreateInstance("UIGradient", {
		Parent = ListInner;
		Rotation = 90;
		Color = NewColorSequence(hex("131418"), hex("17181D"));
	});
	local list = self:CreateInstance("ScrollingFrame", {
		Name = "List";
		Parent = ListInner;
		Position = NewUdim2(0, 4, 0, 4);
		Size = NewUdim2(1, -8, 1, -8);
		BackgroundTransparency = 1;
		BorderSizePixel = 0;
		ScrollBarThickness = 2;
		ScrollBarImageColor3 = hex("98BCFF");
		CanvasSize = NewUdim2(0, 0, 0, 0);
		AutomaticCanvasSize = Enum.AutomaticSize.Y;
		ZIndex = 4;
	});
	self:CreateInstance("UIListLayout", {
		Parent = list;
		FillDirection = Enum.FillDirection.Vertical;
		SortOrder = Enum.SortOrder.LayoutOrder;
		Padding = NewUdim(0, 2);
	});
	local EmptyLbl = self:CreateInstance("TextLabel", {
		Name = "Empty";
		Parent = ListInner;
		AnchorPoint = NewVector2(0.5, 0);
		Position = NewUdim2(0.5, 0, 0, 6);
		Size = NewUdim2(1, -8, 0, 12);
		BackgroundTransparency = 1;
		FontFace = Library.Fonts.title;
		Text = "<no configs>";
		TextColor3 = hex("8A8A92");
		TextSize = 9;
		TextXAlignment = Enum.TextXAlignment.Center;
		TextYAlignment = Enum.TextYAlignment.Center;
		ZIndex = 5;
	});

	local AutoloadBg = self:CreateInstance("Frame", {
		Name = "AutoloadBg";
		Parent = section;
		AnchorPoint = NewVector2(0, 1);
		Position = NewUdim2(0, 8, 1, -72);
		Size = NewUdim2(1, -16, 0, 16);
		BackgroundColor3 = hex("07080A");
		BorderSizePixel = 0;
		ZIndex = 3;
	});
	local AutoloadMid = self:CreateInstance("Frame", {
		Name = "Mid";
		Parent = AutoloadBg;
		Position = NewUdim2(0, 1, 0, 1);
		Size = NewUdim2(1, -2, 1, -2);
		BackgroundColor3 = hex("24262D");
		BorderSizePixel = 0;
		ZIndex = 3;
	});
	local AutoloadInner = self:CreateInstance("Frame", {
		Name = "Inner";
		Parent = AutoloadMid;
		Position = NewUdim2(0, 1, 0, 1);
		Size = NewUdim2(1, -2, 1, -2);
		BackgroundColor3 = FromRgb(255, 255, 255);
		BorderSizePixel = 0;
		ZIndex = 3;
	});
	self:CreateInstance("UIGradient", {
		Parent = AutoloadInner;
		Rotation = 90;
		Color = NewColorSequence(hex("131418"), hex("17181D"));
	});
	local AutoloadLabel = self:CreateInstance("TextLabel", {
		Name = "Value";
		Parent = AutoloadInner;
		Position = NewUdim2(0, 6, 0, 0);
		Size = NewUdim2(1, -22, 1, 0);
		BackgroundTransparency = 1;
		FontFace = Library.Fonts.title;
		Text = "Autoload: None";
		TextColor3 = hex("B4B4B4");
		TextSize = 9;
		TextXAlignment = Enum.TextXAlignment.Left;
		TextYAlignment = Enum.TextYAlignment.Center;
		ZIndex = 4;
	});
	self:CreateInstance("TextLabel", {
		Name = "Arrow";
		Parent = AutoloadInner;
		AnchorPoint = NewVector2(1, 0.5);
		Position = NewUdim2(1, -4, 0.5, 0);
		Size = FromOffset(8, 9);
		BackgroundTransparency = 1;
		FontFace = Library.Fonts.title;
		Text = "v";
		TextColor3 = hex("B4B4B4");
		TextSize = 9;
		TextXAlignment = Enum.TextXAlignment.Center;
		TextYAlignment = Enum.TextYAlignment.Center;
		ZIndex = 4;
	});
	local AutoloadHit = self:CreateInstance("TextButton", {
		Name = "Hit";
		Parent = AutoloadBg;
		Size = NewUdim2(1, 0, 1, 0);
		BackgroundTransparency = 1;
		AutoButtonColor = false;
		Text = "";
		ZIndex = 5;
	});
	local AutoloadScale = self:CreateInstance("UIScale", {
		Parent = AutoloadBg;
		Scale = 1;
	});
	local AutoloadBtnTween = NewTweenInfo(0.12, Enum.EasingStyle.Quad, Enum.EasingDirection.Out);
	self:Connection(AutoloadHit.MouseEnter, function() self:Tween(AutoloadScale, AutoloadBtnTween, { Scale = 1.025 }):Play() end);
	self:Connection(AutoloadHit.MouseLeave, function() self:Tween(AutoloadScale, AutoloadBtnTween, { Scale = 1 }):Play() end);
	self:Connection(AutoloadHit.MouseButton1Down, function() self:Tween(AutoloadScale, NewTweenInfo(0.07, Enum.EasingStyle.Quad, Enum.EasingDirection.Out), { Scale = 0.975 }):Play() end);
	self:Connection(AutoloadHit.MouseButton1Up, function() self:Tween(AutoloadScale, AutoloadBtnTween, { Scale = 1.025 }):Play() end);

	local InputBg = self:CreateInstance("Frame", {
		Name = "InputBg";
		Parent = section;
		AnchorPoint = NewVector2(0, 1);
		Position = NewUdim2(0, 8, 1, -52);
		Size = NewUdim2(1, -16, 0, 16);
		BackgroundColor3 = hex("07080A");
		BorderSizePixel = 0;
		ZIndex = 3;
	});
	local InputMid = self:CreateInstance("Frame", {
		Name = "Mid";
		Parent = InputBg;
		Position = NewUdim2(0, 1, 0, 1);
		Size = NewUdim2(1, -2, 1, -2);
		BackgroundColor3 = hex("24262D");
		BorderSizePixel = 0;
		ZIndex = 3;
	});
	local InputInner = self:CreateInstance("Frame", {
		Name = "Inner";
		Parent = InputMid;
		Position = NewUdim2(0, 1, 0, 1);
		Size = NewUdim2(1, -2, 1, -2);
		BackgroundColor3 = FromRgb(255, 255, 255);
		BorderSizePixel = 0;
		ClipsDescendants = true;
		ZIndex = 3;
	});
	self:CreateInstance("UIGradient", {
		Parent = InputInner;
		Rotation = 90;
		Color = NewColorSequence(hex("131418"), hex("17181D"));
	});
	local InputBox = self:CreateInstance("TextBox", {
		Name = "Input";
		Parent = InputInner;
		Position = NewUdim2(0, 6, 0, 0);
		Size = NewUdim2(1, -12, 1, 0);
		BackgroundTransparency = 1;
		BorderSizePixel = 0;
		FontFace = Library.Fonts.title;
		Text = "";
		PlaceholderText = "Config name...";
		PlaceholderColor3 = hex("8A8A92");
		TextColor3 = FromRgb(255, 255, 255);
		TextSize = 9;
		TextXAlignment = Enum.TextXAlignment.Left;
		TextYAlignment = Enum.TextYAlignment.Center;
		ClearTextOnFocus = false;
		ZIndex = 4;
	});

	local LibRef = self;
	local function MakeBtn(text, position, size, anchor)
		local btn = LibRef:CreateInstance("TextButton", {
			Parent = section;
			AnchorPoint = anchor or NewVector2(0, 0);
			Position = position;
			Size = size;
			AutoButtonColor = false;
			Text = "";
			BackgroundColor3 = hex("07080A");
			BorderSizePixel = 0;
			ZIndex = 3;
		});
		local BtnInner = LibRef:CreateInstance("Frame", {
			Parent = btn;
			Position = NewUdim2(0, 1, 0, 1);
			Size = NewUdim2(1, -2, 1, -2);
			BackgroundColor3 = hex("24262D");
			BorderSizePixel = 0;
			ZIndex = 4;
		});
		local BtnBody = LibRef:CreateInstance("Frame", {
			Parent = BtnInner;
			Position = NewUdim2(0, 1, 0, 1);
			Size = NewUdim2(1, -2, 1, -2);
			BackgroundColor3 = FromRgb(255, 255, 255);
			BorderSizePixel = 0;
			ZIndex = 5;
		});
		LibRef:CreateInstance("UIGradient", {
			Parent = BtnBody;
			Rotation = 90;
			Color = NewColorSequence(hex("131418"), hex("17181D"));
		});
		local BtnLabel = LibRef:CreateInstance("TextLabel", {
			Parent = BtnBody;
			Size = NewUdim2(1, 0, 1, 0);
			BackgroundTransparency = 1;
			FontFace = Library.Fonts.title;
			Text = text;
			TextColor3 = hex("B4B4B4");
			TextSize = 9;
			TextXAlignment = Enum.TextXAlignment.Center;
			TextYAlignment = Enum.TextYAlignment.Center;
			ZIndex = 6;
		});
		local BtnHoverTween = NewTweenInfo(0.15, Enum.EasingStyle.Quad, Enum.EasingDirection.Out);
		LibRef:AnimateButton(btn);
		LibRef:Connection(btn.MouseEnter, function() LibRef:Tween(BtnLabel, BtnHoverTween, { TextColor3 = FromRgb(255, 255, 255) }):Play() end);
		LibRef:Connection(btn.MouseLeave, function() LibRef:Tween(BtnLabel, BtnHoverTween, { TextColor3 = hex("B4B4B4") }):Play() end);
		return btn, BtnLabel;
	end;

	local BotAnchor = NewVector2(0, 1);
	local LoadBtn, LoadLbl = MakeBtn("Load", NewUdim2(0, 8, 1, -32), NewUdim2(0.5, -10, 0, 16), BotAnchor);
	local SaveBtn, SaveLbl = MakeBtn("Save", NewUdim2(0.5, 2, 1, -32), NewUdim2(0.5, -10, 0, 16), BotAnchor);
	local CreateBtn, CreateLbl = MakeBtn("Create", NewUdim2(0, 8, 1, -14), NewUdim2(0.5, -10, 0, 16), BotAnchor);
	local RemoveBtn, RemoveLbl = MakeBtn("Remove", NewUdim2(0.5, 2, 1, -14), NewUdim2(0.5, -10, 0, 16), BotAnchor);

	local selected;
	local items = {};
	local function refresh()
		for _, it in items do it:Destroy() end;
		table.clear(items);
		local names = LibRef:ListConfigs();
		EmptyLbl.Visible = (#names == 0);
		for i, name in names do
			local row = LibRef:CreateInstance("TextButton", {
				Parent = list;
				Size = NewUdim2(1, 0, 0, 14);
				BackgroundTransparency = 1;
				BorderSizePixel = 0;
				AutoButtonColor = false;
				Text = "";
				LayoutOrder = i;
				ZIndex = 4;
			});
			local lbl = LibRef:CreateInstance("TextLabel", {
				Parent = row;
				Position = NewUdim2(0, 6, 0, 0);
				Size = NewUdim2(1, -12, 1, 0);
				BackgroundTransparency = 1;
				FontFace = Library.Fonts.title;
				Text = name;
				TextColor3 = (name == selected) and (Library.AccentColor or hex("98BCFF")) or hex("B4B4B4");
				TextSize = 9;
				TextXAlignment = Enum.TextXAlignment.Center;
				TextYAlignment = Enum.TextYAlignment.Center;
				ZIndex = 5;
			});
			LibRef:Connection(row.MouseEnter, function()
				if selected ~= name then lbl.TextColor3 = FromRgb(255, 255, 255) end;
			end);
			LibRef:Connection(row.MouseLeave, function()
				lbl.TextColor3 = (name == selected) and (Library.AccentColor or hex("98BCFF")) or hex("B4B4B4");
			end);
			LibRef:Connection(row.MouseButton1Click, function()
				selected = name;
				InputBox.Text = name;
				refresh();
			end);
			insert(items, row);
		end;
	end;
	refresh();

	local function trim(s)
		return (s:gsub("^%s+", ""):gsub("%s+$", ""));
	end;

	LibRef:Connection(CreateBtn.MouseButton1Click, LibRef:ConfirmClick(CreateLbl, function()
		local name = trim(InputBox.Text);
		if name == "" then return end;
		if typeof(writefile) ~= "function" then return end;
		local path = LibRef:ConfigPath(name);
		if typeof(isfile) == "function" and isfile(path) then
			LibRef:Notify({ Text = "Config already exists: " .. name });
			return;
		end;
		local json = LibRef:GetConfig();
		if typeof(json) ~= "string" then json = "{}" end;
		pcall(writefile, path, json);
		selected = name;
		refresh();
		LibRef:Notify({ Text = "Created " .. name });
	end));
	LibRef:Connection(SaveBtn.MouseButton1Click, LibRef:ConfirmClick(SaveLbl, function()
		local name = trim(InputBox.Text);
		if name == "" then name = selected end;
		if not name or name == "" then return end;
		if typeof(writefile) ~= "function" then return end;
		local path = LibRef:ConfigPath(name);
		local json = LibRef:GetConfig();
		if typeof(json) ~= "string" then json = "{}" end;
		pcall(writefile, path, json);
		selected = name;
		refresh();
		LibRef:Notify({ Text = "Saved " .. name });
	end));
	LibRef:Connection(LoadBtn.MouseButton1Click, LibRef:ConfirmClick(LoadLbl, function()
		local name = trim(InputBox.Text);
		if name == "" then name = selected end;
		if not name or name == "" then return end;
		if typeof(readfile) ~= "function" then return end;
		local path = LibRef:ConfigPath(name);
		if typeof(isfile) == "function" and not isfile(path) then return end;
		local ok, data = pcall(readfile, path);
		if ok and typeof(data) == "string" then
			LibRef:LoadConfig(data);
			LibRef:Notify({ Text = "Loaded " .. name });
		end;
	end));
	LibRef:Connection(RemoveBtn.MouseButton1Click, LibRef:ConfirmClick(RemoveLbl, function()
		local name = trim(InputBox.Text);
		if name == "" then name = selected end;
		if not name or name == "" then return end;
		if typeof(delfile) ~= "function" then return end;
		local path = LibRef:ConfigPath(name);
		if typeof(isfile) == "function" and not isfile(path) then return end;
		pcall(delfile, path);
		if selected == name then selected = nil; InputBox.Text = "" end;
		refresh();
		LibRef:Notify({ Text = "Removed " .. name });
	end));

	local AutoloadPath = self.Directory .. "/Configs/autoload.txt";
	local AutoloadName;
	if typeof(isfile) == "function" and isfile(AutoloadPath) then
		local OkA, TxtA = pcall(readfile, AutoloadPath);
		if OkA and typeof(TxtA) == "string" then
			AutoloadName = trim(TxtA);
			if AutoloadName == "" then AutoloadName = nil end;
		end;
	end;

	local function SetAutoload(name)
		AutoloadName = (name == "None" or name == nil or name == "") and nil or name;
		AutoloadLabel.Text = "Autoload: " .. (AutoloadName or "None");
		if AutoloadName then
			if typeof(writefile) == "function" then pcall(writefile, AutoloadPath, AutoloadName) end;
		elseif typeof(isfile) == "function" and isfile(AutoloadPath) and typeof(delfile) == "function" then
			pcall(delfile, AutoloadPath);
		end;
	end;
	AutoloadLabel.Text = "Autoload: " .. (AutoloadName or "None");

	local AutoloadPopup = self:CreateInstance("Frame", {
		Name = "AutoloadPopup";
		Parent = gui;
		BackgroundColor3 = hex("07080A");
		BorderSizePixel = 0;
		ClipsDescendants = true;
		Active = true;
		Visible = false;
		ZIndex = 60;
	});
	local AutoloadPopupMid = self:CreateInstance("Frame", {
		Parent = AutoloadPopup;
		Position = NewUdim2(0, 1, 0, 1);
		Size = NewUdim2(1, -2, 1, -2);
		BackgroundColor3 = hex("24262D");
		BorderSizePixel = 0;
		ZIndex = 61;
	});
	local AutoloadPopupInner = self:CreateInstance("Frame", {
		Parent = AutoloadPopupMid;
		Position = NewUdim2(0, 1, 0, 1);
		Size = NewUdim2(1, -2, 1, -2);
		BackgroundColor3 = FromRgb(255, 255, 255);
		BorderSizePixel = 0;
		Active = true;
		ZIndex = 62;
	});
	self:CreateInstance("UIGradient", {
		Parent = AutoloadPopupInner;
		Rotation = 90;
		Color = NewColorSequence(hex("131418"), hex("17181D"));
	});
	local AutoloadPopupList = self:CreateInstance("ScrollingFrame", {
		Parent = AutoloadPopupInner;
		Position = NewUdim2(0, 4, 0, 4);
		Size = NewUdim2(1, -8, 1, -8);
		BackgroundTransparency = 1;
		BorderSizePixel = 0;
		Active = true;
		ScrollBarThickness = 2;
		ScrollBarImageColor3 = hex("98BCFF");
		CanvasSize = NewUdim2(0, 0, 0, 0);
		AutomaticCanvasSize = Enum.AutomaticSize.Y;
		ZIndex = 63;
	});
	AutoloadPopupList.ZIndex = 64;
	self:CreateInstance("UIListLayout", {
		Parent = AutoloadPopupList;
		FillDirection = Enum.FillDirection.Vertical;
		SortOrder = Enum.SortOrder.LayoutOrder;
		Padding = NewUdim(0, 2);
	});

	local AutoloadOpen = false;
	local AUTOLOAD_FULL_H = 70;
	local AUTOLOAD_ANIM = NewTweenInfo(0.15, Enum.EasingStyle.Quad, Enum.EasingDirection.Out);
	local AutoloadTween;
	local function CloseAutoload()
		if not AutoloadOpen then return end;
		AutoloadOpen = false;
		if AutoloadTween then AutoloadTween:Cancel() end;
		local _, _, sc = LibRef:GuiPoint(gui, 0, 0);
		local w = AutoloadBg.AbsoluteSize.X / sc;
		AutoloadTween = TweenService:Create(AutoloadPopup, AUTOLOAD_ANIM, { Size = FromOffset(w, 0) });
		AutoloadTween:Play();
		AutoloadTween.Completed:Once(function()
			if not AutoloadOpen then AutoloadPopup.Visible = false end;
		end);
	end;
	local function OpenAutoload()
		AutoloadOpen = true;
		local p = AutoloadBg.AbsolutePosition;
		local s = AutoloadBg.AbsoluteSize;
		local px, py, sc = LibRef:GuiPoint(gui, p.X, p.Y + s.Y + 2);
		AutoloadPopup.Position = NewUdim2(0, px, 0, py);
		AutoloadPopup.Size = FromOffset(s.X / sc, 0);
		AutoloadPopup.Visible = true;
		if AutoloadTween then AutoloadTween:Cancel() end;
		AutoloadTween = TweenService:Create(AutoloadPopup, AUTOLOAD_ANIM, { Size = FromOffset(s.X / sc, AUTOLOAD_FULL_H) });
		AutoloadTween:Play();
	end;

	local function RebuildAutoloadPopup()
		for _, c in AutoloadPopupList:GetChildren() do
			if c:IsA("TextButton") then c:Destroy() end;
		end;
		local names = LibRef:ListConfigs();
		insert(names, 1, "None");
		for i, name in names do
			local row = LibRef:CreateInstance("TextButton", {
				Parent = AutoloadPopupList;
				Size = NewUdim2(1, 0, 0, 14);
				BackgroundTransparency = 1;
				BorderSizePixel = 0;
				AutoButtonColor = false;
				Text = "";
				LayoutOrder = i;
				ZIndex = 66;
			});
			local lbl = LibRef:CreateInstance("TextLabel", {
				Parent = row;
				Position = NewUdim2(0, 6, 0, 0);
				Size = NewUdim2(1, -12, 1, 0);
				BackgroundTransparency = 1;
				FontFace = Library.Fonts.title;
				Text = name;
				TextColor3 = (name == (AutoloadName or "None")) and (Library.AccentColor or hex("98BCFF")) or hex("B4B4B4");
				TextSize = 9;
				TextXAlignment = Enum.TextXAlignment.Left;
				TextYAlignment = Enum.TextYAlignment.Center;
				ZIndex = 67;
			});
			LibRef:Connection(row.MouseEnter, function()
				if name ~= (AutoloadName or "None") then lbl.TextColor3 = FromRgb(255, 255, 255) end;
			end);
			LibRef:Connection(row.MouseLeave, function()
				lbl.TextColor3 = (name == (AutoloadName or "None")) and (Library.AccentColor or hex("98BCFF")) or hex("B4B4B4");
			end);
			LibRef:Connection(row.MouseButton1Click, function()
				SetAutoload(name);
				RebuildAutoloadPopup();
				CloseAutoload();
			end);
		end;
	end;

	LibRef:Connection(AutoloadHit.MouseButton1Click, function()
		if AutoloadOpen then CloseAutoload() else RebuildAutoloadPopup(); OpenAutoload() end;
	end);
	LibRef:Connection(UserInputService.InputBegan, function(input)
		if not AutoloadOpen then return end;
		if input.UserInputType ~= Enum.UserInputType.MouseButton1 and input.UserInputType ~= Enum.UserInputType.Touch then return end;
		local mx, my = LibRef:MousePoint(gui, input);
		if not LibRef:PointInObject(AutoloadPopup, mx, my, 2) and not LibRef:PointInObject(AutoloadBg, mx, my, 2) then CloseAutoload() end;
	end);

	self:Draggable(outer, HeaderDrag);

	if AutoloadName then
		local p = self:ConfigPath(AutoloadName);
		if typeof(isfile) == "function" and isfile(p) and typeof(readfile) == "function" then
			task.delay(2, function()
				local OkL, data = pcall(readfile, p);
				if OkL and typeof(data) == "string" then
					self:LoadConfig(data);
				end;
			end)
		end;
	end;

	local panel = { Gui = gui, Outer = outer, Refresh = refresh };
	function panel:SetVisible(on) Library:SetWidgetVisible(self, on) end;
	function panel:Destroy()
		if self.Gui and self.Gui.Parent then self.Gui:Destroy() end;
		if Library.CurrentConfigs == panel then Library.CurrentConfigs = nil end;
	end;

	self.CurrentConfigs = panel;
	self:TrackWidget(panel, "Configs");
	return panel;
end;

function Library:Build(opts)
	opts = typeof(opts) == "table" and opts or {};

	if typeof(self.CurrentBuildPanel) == "table" and typeof(self.CurrentBuildPanel.Gui) == "Instance" and self.CurrentBuildPanel.Gui.Parent then
		self.CurrentBuildPanel.Gui:Destroy();
	end;
	self.CurrentBuildPanel = nil;

	local w = tonumber(opts.width) or 240;
	local h = tonumber(opts.height) or 420;
	local TitleText = tostring(opts.title or "Build");

	local VpSize = camera.ViewportSize;
	local UiScale = self:ComputeUIScale();
	local DefaultX = MathClamp(tonumber(opts.x) or 1650, 0, MathMax(0, VpSize.X / UiScale - w));
	local DefaultY = MathClamp(tonumber(opts.y) or 415, 0, MathMax(0, VpSize.Y / UiScale - h));
	local pos = opts.position or NewUdim2(0, DefaultX, 0, DefaultY);

	local gui = self:CreateInstance("ScreenGui", {
		Name = "\0";
		Parent = (gethui and gethui()) or CoreGui;
		Enabled = true;
		DisplayOrder = self.WidgetDisplayOrder or 1002;
		IgnoreGuiInset = true;
		ResetOnSpawn = false;
		ZIndexBehavior = Enum.ZIndexBehavior.Global;
	});
	self:ApplyScale(gui);

	local outer = self:CreateInstance("Frame", {
		Name = "Outer";
		Parent = gui;
		Position = pos;
		Size = FromOffset(w, h);
		BackgroundColor3 = hex("07080A");
		BorderSizePixel = 0;
		Active = true;
	});
	self:CreateInstance("ImageLabel", {
		Name = "Glow";
		Parent = outer;
		AnchorPoint = NewVector2(0.5, 0.5);
		Position = NewUdim2(0.5, 0, 0.5, 0);
		Size = NewUdim2(1, 30, 1, 30);
		BackgroundTransparency = 1;
		Image = "rbxassetid://18245826428";
		ImageColor3 = hex("98BCFF");
		ImageTransparency = 0.86;
		ScaleType = Enum.ScaleType.Slice;
		SliceCenter = RectNew(21, 21, 79, 79);
		ZIndex = -1;
	});
	local inner = self:CreateInstance("Frame", {
		Name = "Inner";
		Parent = outer;
		Position = NewUdim2(0, 1, 0, 1);
		Size = NewUdim2(1, -2, 1, -2);
		BackgroundColor3 = hex("24262D");
		BorderSizePixel = 0;
	});
	local main = self:CreateInstance("Frame", {
		Name = "Main";
		Parent = inner;
		Position = NewUdim2(0, 1, 0, 1);
		Size = NewUdim2(1, -2, 1, -2);
		BackgroundColor3 = FromRgb(255, 255, 255);
		BorderSizePixel = 0;
	});
	self:CreateInstance("UIGradient", {
		Parent = main; Rotation = 90;
		Color = NewColorSequence(hex("131418"), hex("17181D"));
	});
	self:CreateInstance("Frame", {
		Name = "TopAccent";
		Parent = main;
		Position = NewUdim2(0, 0, 0, 0);
		Size = NewUdim2(1, 0, 0, 1);
		BackgroundColor3 = hex("98BCFF");
		BorderSizePixel = 0;
		ZIndex = 2;
	});
	self:CreateInstance("Frame", {
		Name = "TopAccentShade";
		Parent = main;
		Position = NewUdim2(0, 0, 0, 1);
		Size = NewUdim2(1, 0, 0, 1);
		BackgroundColor3 = hex("6E8CC8");
		BorderSizePixel = 0;
		ZIndex = 2;
	});
	local TitleLabel = self:CreateInstance("TextLabel", {
		Name = "Title";
		Parent = main;
		Position = NewUdim2(0, 10, 0, 5);
		Size = NewUdim2(1, -20, 0, 14);
		BackgroundTransparency = 1;
		FontFace = Library.Fonts.title;
		Text = TitleText;
		TextColor3 = FromRgb(255, 255, 255);
		TextSize = 9;
		TextXAlignment = Enum.TextXAlignment.Left;
		TextYAlignment = Enum.TextYAlignment.Top;
		ZIndex = 5;
	});
	self:CreateInstance("UIGradient", {
		Parent = TitleLabel;
		Color = NewColorSequence(hex("98BCFF"), hex("6E8CC8"));
		Rotation = 90;
	});
	local HeaderDrag = self:CreateInstance("Frame", {
		Name = "HeaderDrag";
		Parent = main;
		Position = NewUdim2(0, 0, 0, 0);
		Size = NewUdim2(1, 0, 0, 22);
		BackgroundTransparency = 1;
		Active = true;
		ZIndex = 4;
	});

	local LibRef = self;
	local function trim(s)
		return (tostring(s):gsub("^%s+", ""):gsub("%s+$", ""));
	end;

	local ListBg = self:CreateInstance("Frame", {
		Name = "ListBg"; Parent = main;
		Position = NewUdim2(0, 6, 0, 24); Size = NewUdim2(1, -12, 0, 120);
		BackgroundColor3 = hex("07080A"); BorderSizePixel = 0; ZIndex = 3;
	});
	local ListMid = self:CreateInstance("Frame", {
		Name = "Mid"; Parent = ListBg; Position = NewUdim2(0, 1, 0, 1); Size = NewUdim2(1, -2, 1, -2);
		BackgroundColor3 = hex("24262D"); BorderSizePixel = 0; ZIndex = 3;
	});
	local ListInner = self:CreateInstance("Frame", {
		Name = "Inner"; Parent = ListMid; Position = NewUdim2(0, 1, 0, 1); Size = NewUdim2(1, -2, 1, -2);
		BackgroundColor3 = FromRgb(255, 255, 255); BorderSizePixel = 0; ZIndex = 3;
	});
	self:CreateInstance("UIGradient", { Parent = ListInner; Rotation = 90; Color = NewColorSequence(hex("131418"), hex("17181D")); });
	local list = self:CreateInstance("ScrollingFrame", {
		Name = "List"; Parent = ListInner; Position = NewUdim2(0, 4, 0, 4); Size = NewUdim2(1, -8, 1, -8);
		BackgroundTransparency = 1; BorderSizePixel = 0; ScrollBarThickness = 2; ScrollBarImageColor3 = hex("98BCFF");
		CanvasSize = NewUdim2(0, 0, 0, 0); AutomaticCanvasSize = Enum.AutomaticSize.Y; ZIndex = 4;
	});
	self:CreateInstance("UIListLayout", { Parent = list; FillDirection = Enum.FillDirection.Vertical; SortOrder = Enum.SortOrder.LayoutOrder; Padding = NewUdim(0, 2); });
	local EmptyLbl = self:CreateInstance("TextLabel", {
		Name = "Empty"; Parent = ListInner; AnchorPoint = NewVector2(0.5, 0);
		Position = NewUdim2(0.5, 0, 0, 6); Size = NewUdim2(1, -8, 0, 12);
		BackgroundTransparency = 1; FontFace = Library.Fonts.title; Text = "<no bases>";
		TextColor3 = hex("8A8A92"); TextSize = 9; TextXAlignment = Enum.TextXAlignment.Center; TextYAlignment = Enum.TextYAlignment.Center; ZIndex = 5;
	});
	EmptyLbl.Text = "<no saved builds>";

	local InputBg = self:CreateInstance("Frame", {
		Name = "InputBg"; Parent = main; Position = NewUdim2(0, 6, 0, 150); Size = NewUdim2(1, -12, 0, 16);
		BackgroundColor3 = hex("07080A"); BorderSizePixel = 0; ZIndex = 3;
	});
	local InputMid = self:CreateInstance("Frame", { Name = "Mid"; Parent = InputBg; Position = NewUdim2(0, 1, 0, 1); Size = NewUdim2(1, -2, 1, -2); BackgroundColor3 = hex("24262D"); BorderSizePixel = 0; ZIndex = 3; });
	local InputInner = self:CreateInstance("Frame", { Name = "Inner"; Parent = InputMid; Position = NewUdim2(0, 1, 0, 1); Size = NewUdim2(1, -2, 1, -2); BackgroundColor3 = FromRgb(255, 255, 255); BorderSizePixel = 0; ClipsDescendants = true; ZIndex = 3; });
	self:CreateInstance("UIGradient", { Parent = InputInner; Rotation = 90; Color = NewColorSequence(hex("131418"), hex("17181D")); });
	local InputBox = self:CreateInstance("TextBox", {
		Name = "Input"; Parent = InputInner; Position = NewUdim2(0, 6, 0, 0); Size = NewUdim2(1, -12, 1, 0);
		BackgroundTransparency = 1; FontFace = Library.Fonts.title; Text = ""; PlaceholderText = "Build name...";
		PlaceholderColor3 = hex("6A6A72"); TextColor3 = FromRgb(255, 255, 255); TextSize = 9;
		TextXAlignment = Enum.TextXAlignment.Left; TextYAlignment = Enum.TextYAlignment.Center; ClearTextOnFocus = false; ZIndex = 4;
	});

	local function MakeBtn(text, pos, size)
		local btn = LibRef:CreateInstance("TextButton", { Name = "Btn_" .. text; Parent = main; Position = pos; Size = size; BackgroundColor3 = hex("07080A"); BorderSizePixel = 0; AutoButtonColor = false; Text = ""; ZIndex = 3; });
		local BtnInner = LibRef:CreateInstance("Frame", { Parent = btn; Position = NewUdim2(0, 1, 0, 1); Size = NewUdim2(1, -2, 1, -2); BackgroundColor3 = hex("24262D"); BorderSizePixel = 0; ZIndex = 4; });
		local BtnBody = LibRef:CreateInstance("Frame", { Parent = BtnInner; Position = NewUdim2(0, 1, 0, 1); Size = NewUdim2(1, -2, 1, -2); BackgroundColor3 = FromRgb(255, 255, 255); BorderSizePixel = 0; ZIndex = 5; });
		LibRef:CreateInstance("UIGradient", { Parent = BtnBody; Rotation = 90; Color = NewColorSequence(hex("131418"), hex("17181D")); });
		local BtnLabel = LibRef:CreateInstance("TextLabel", { Parent = BtnBody; Size = NewUdim2(1, 0, 1, 0); BackgroundTransparency = 1; FontFace = Library.Fonts.title; Text = text; TextColor3 = hex("B4B4B4"); TextSize = 9; TextXAlignment = Enum.TextXAlignment.Center; TextYAlignment = Enum.TextYAlignment.Center; ZIndex = 6; });
		local HoverTween = NewTweenInfo(0.15, Enum.EasingStyle.Quad, Enum.EasingDirection.Out);
		LibRef:AnimateButton(btn);
		LibRef:Connection(btn.MouseEnter, function() LibRef:Tween(BtnLabel, HoverTween, { TextColor3 = FromRgb(255, 255, 255) }):Play() end);
		LibRef:Connection(btn.MouseLeave, function() LibRef:Tween(BtnLabel, HoverTween, { TextColor3 = hex("B4B4B4") }):Play() end);
		return btn;
	end;
	local SaveBtn = MakeBtn("Save Build", NewUdim2(0, 6, 0, 172), NewUdim2(0.5, -9, 0, 16));
	local LoadBtn = MakeBtn("Load Build", NewUdim2(0.5, 3, 0, 172), NewUdim2(0.5, -9, 0, 16));
	local RefreshBtn = MakeBtn("Refresh", NewUdim2(0, 6, 0, 192), NewUdim2(0.5, -9, 0, 16));
	local DeleteBtn = MakeBtn("Delete", NewUdim2(0.5, 3, 0, 192), NewUdim2(0.5, -9, 0, 16));

	local SecList = self:CreateInstance("ScrollingFrame", {
		Name = "Sections"; Parent = main; Position = NewUdim2(0, 6, 0, 214); Size = NewUdim2(1, -12, 1, -220);
		BackgroundTransparency = 1; BorderSizePixel = 0; ScrollBarThickness = 2; ScrollBarImageColor3 = hex("98BCFF");
		CanvasSize = NewUdim2(0, 0, 0, 0); AutomaticCanvasSize = Enum.AutomaticSize.Y; ZIndex = 2;
	});
	self:CreateInstance("UIListLayout", { Parent = SecList; FillDirection = Enum.FillDirection.Vertical; SortOrder = Enum.SortOrder.LayoutOrder; Padding = NewUdim(0, 6); });
	local Host = { LeftCol = SecList; RightCol = SecList; Sections = {}; RefreshCanvases = function() end };

	local folder = tostring(opts.folder or "LandryHaxx/Fallen/Builds");
	if typeof(isfolder) == "function" and not isfolder(folder) then pcall(function() makefolder(folder) end) end;
	local function BasePath(name) return folder .. "/" .. tostring(name) .. ".json" end;
	local function ListBases()
		local names = {};
		if typeof(listfiles) == "function" and typeof(isfolder) == "function" and isfolder(folder) then
			local ok, files = pcall(listfiles, folder);
			if ok and typeof(files) == "table" then
				for _, file in files do
					if typeof(file) == "string" and file:sub(-5) == ".json" then
						local name = file:match("([^/\\]+)%.json$");
						if name then insert(names, name) end;
					end;
				end;
			end;
		end;
		table.sort(names);
		return names;
	end;

	local selected;
	local rows = {};
	local function refresh()
		for _, it in rows do it:Destroy() end;
		table.clear(rows);
		local names = ListBases();
		EmptyLbl.Visible = (#names == 0);
		for i, name in names do
			local row = LibRef:CreateInstance("TextButton", { Parent = list; Size = NewUdim2(1, 0, 0, 14); BackgroundTransparency = 1; BorderSizePixel = 0; AutoButtonColor = false; Text = ""; LayoutOrder = i; ZIndex = 4; });
			local lbl = LibRef:CreateInstance("TextLabel", { Parent = row; Position = NewUdim2(0, 6, 0, 0); Size = NewUdim2(1, -12, 1, 0); BackgroundTransparency = 1; FontFace = Library.Fonts.title; Text = name; TextColor3 = (name == selected) and (Library.AccentColor or hex("98BCFF")) or hex("B4B4B4"); TextSize = 9; TextXAlignment = Enum.TextXAlignment.Center; TextYAlignment = Enum.TextYAlignment.Center; ZIndex = 5; });
			LibRef:Connection(row.MouseEnter, function() if selected ~= name then lbl.TextColor3 = FromRgb(255, 255, 255) end end);
			LibRef:Connection(row.MouseLeave, function() lbl.TextColor3 = (name == selected) and (Library.AccentColor or hex("98BCFF")) or hex("B4B4B4") end);
			LibRef:Connection(row.MouseButton1Click, function() selected = name; InputBox.Text = name; refresh() end);
			insert(rows, row);
		end;
	end;
	refresh();

	self:Connection(SaveBtn.MouseButton1Click, function()
		local name = trim(InputBox.Text);
		if name == "" then name = selected end;
		if not name or name == "" then LibRef:Notify({ Text = "Enter a build name first" }); return end;
		if typeof(opts.onSave) == "function" then
			local ok = opts.onSave(name, BasePath(name));
			if ok ~= false then selected = name end;
		end;
		refresh();
	end);
	self:Connection(LoadBtn.MouseButton1Click, function()
		local name = selected;
		if not name or name == "" then name = trim(InputBox.Text) end;
		if not name or name == "" then LibRef:Notify({ Text = "Select a build first" }); return end;
		if typeof(opts.onLoad) == "function" then opts.onLoad(name, BasePath(name)) end;
	end);
	self:Connection(RefreshBtn.MouseButton1Click, function() refresh() end);
	self:Connection(DeleteBtn.MouseButton1Click, function()
		local name = selected;
		if not name or name == "" then name = trim(InputBox.Text) end;
		if not name or name == "" then return end;
		local path = BasePath(name);
		if typeof(isfile) == "function" and isfile(path) and typeof(delfile) == "function" then
			pcall(delfile, path);
			if selected == name then selected = nil; InputBox.Text = "" end;
			LibRef:Notify({ Text = "Deleted " .. name });
			refresh();
		end;
	end);

	self:Draggable(outer, HeaderDrag);

	local panel = { Gui = gui, Outer = outer, Host = Host, Folder = folder };
	function panel:Section(name, side)
		if typeof(Library._BuildSection) ~= "function" then return nil end;
		return Library._BuildSection(self.Host, name, side);
	end;
	function panel:RefreshList() refresh() end;
	function panel:GetSelected() return selected end;
	function panel:SetVisible(on) Library:SetWidgetVisible(self, on) end;
	function panel:Destroy()
		if self.Gui and self.Gui.Parent then self.Gui:Destroy() end;
		if Library.CurrentBuildPanel == panel then Library.CurrentBuildPanel = nil end;
	end;

	self.CurrentBuildPanel = panel;
	self:TrackWidget(panel, "Build");
	return panel;
end;

function Library:GetWidget(widget)
	if typeof(widget) == "string" then
		return self.Widgets[widget] or self.Widgets[widget:gsub("^widgets%.", "")];
	end;
	if typeof(widget) == "table" then return widget end;
	if typeof(widget) == "Instance" then return { Frame = widget } end;
end;

function Library:GetWidgetBounds(widget)
	local panel = self:GetWidget(widget);
	local frame = panel and (panel.Frame or panel.Outer);
	if not frame then return end;
	local visible = panel.Visible;
	if visible == nil then visible = frame.Visible end;
	return {
		Position = frame.Position;
		AbsolutePosition = frame.AbsolutePosition;
		Size = frame.Size;
		AbsoluteSize = frame.AbsoluteSize;
		Visible = visible;
	};
end;

function Library:GetWidgetPosition(widget, absolute)
	local bounds = self:GetWidgetBounds(widget);
	if not bounds then return end;
	return absolute and bounds.AbsolutePosition or bounds.Position;
end;

function Library:SetWidgetPosition(widget, position)
	local panel = self:GetWidget(widget);
	local frame = panel and (panel.Frame or panel.Outer);
	if not frame then return false end;
	if typeof(position) == "Vector2" then
		position = NewUdim2(0, position.X, 0, position.Y);
	elseif typeof(position) == "table" then
		position = NewUdim2(
			tonumber(position.XScale) or 0,
			tonumber(position.X) or 0,
			tonumber(position.YScale) or 0,
			tonumber(position.Y) or 0
		);
	end;
	if typeof(position) ~= "UDim2" then return false end;
	frame.Position = position;
	self:SaveWidgetState(panel);
	return true;
end;

function Library:GetTheme()
	return {
		Name = self.ThemeName or "Custom";
		Accent = self.AccentColor;
		Shade = self.ShadeColor;
		Background = self.WindowBgColor;
	};
end;

function Library:SetTheme(theme)
	local values;
	if typeof(theme) == "string" then
		for _, preset in self.Themes or {} do
			if string.lower(preset.name) == string.lower(theme) then
				values = preset;
				break;
			end;
		end;
		if not values then return false end;
	else
		values = theme;
	end;
	if typeof(values) ~= "table" then return false end;

	local name = values.name or values.Name;
	local accent = values.accent or values.Accent or values.AccentColor;
	local shade = values.shade or values.Shade or values.ShadeColor;
	local background = values.bg or values.Background or values.WindowBgColor;
	local function Apply(flag, value, field)
		if typeof(value) ~= "Color3" then return end;
		self.Flags[flag] = value;
		local setter = self.ConfigFlags and self.ConfigFlags[flag];
		if typeof(setter) == "function" then setter(value) else self[field] = value end;
	end;

	if name and self.ConfigFlags and typeof(self.ConfigFlags["appearance.theme"]) == "function" then
		self.Flags["appearance.theme"] = name;
		self.ConfigFlags["appearance.theme"](name);
	else
		Apply("appearance.AccentColor", accent, "AccentColor");
		Apply("appearance.ShadeColor", shade, "ShadeColor");
		Apply("appearance.WindowBgColor", background, "WindowBgColor");
		self.ThemeName = tostring(name or "Custom");
	end;
	return true;
end;

function Library:Map(opts)
	opts = typeof(opts) == "table" and opts or {};

	if typeof(self.CurrentMapPanel) == "table" and typeof(self.CurrentMapPanel.Gui) == "Instance" and self.CurrentMapPanel.Gui.Parent then
		self.CurrentMapPanel.Gui:Destroy();
	end;
	self.CurrentMapPanel = nil;

	local h = tonumber(opts.height) or 300;
	local w = tonumber(opts.width) or h;
	local TitleText = tostring(opts.title or "Map");
	local VpSize = camera.ViewportSize;
	local UiScale = self:ComputeUIScale();
	local DefaultX = MathClamp(tonumber(opts.x) or (VpSize.X / UiScale - w - 20), 0, MathMax(0, VpSize.X / UiScale - w));
	local DefaultY = MathClamp(tonumber(opts.y) or 70, 0, MathMax(0, VpSize.Y / UiScale - h));
	local pos = opts.position or NewUdim2(0, DefaultX, 0, DefaultY);

	local gui = self:CreateInstance("ScreenGui", {
		Name = "\0";
		Parent = (gethui and gethui()) or CoreGui;
		Enabled = true;
		DisplayOrder = self.WidgetDisplayOrder or 1002;
		IgnoreGuiInset = true;
		ResetOnSpawn = false;
		ZIndexBehavior = Enum.ZIndexBehavior.Global;
	});
	self:ApplyScale(gui);

	local outer = self:CreateInstance("Frame", {
		Name = "Outer";
		Parent = gui;
		Position = pos;
		Size = FromOffset(w, h);
		BackgroundColor3 = hex("07080A");
		BorderSizePixel = 0;
		Active = true;
	});
	self:CreateInstance("ImageLabel", {
		Name = "Glow";
		Parent = outer;
		AnchorPoint = NewVector2(0.5, 0.5);
		Position = NewUdim2(0.5, 0, 0.5, 0);
		Size = NewUdim2(1, 30, 1, 30);
		BackgroundTransparency = 1;
		Image = "rbxassetid://18245826428";
		ImageColor3 = Library.AccentColor or hex("98BCFF");
		ImageTransparency = 0.86;
		ScaleType = Enum.ScaleType.Slice;
		SliceCenter = RectNew(21, 21, 79, 79);
		ZIndex = -1;
	});
	local inner = self:CreateInstance("Frame", {
		Name = "Inner";
		Parent = outer;
		Position = NewUdim2(0, 1, 0, 1);
		Size = NewUdim2(1, -2, 1, -2);
		BackgroundColor3 = hex("24262D");
		BorderSizePixel = 0;
	});
	local main = self:CreateInstance("Frame", {
		Name = "Main";
		Parent = inner;
		Position = NewUdim2(0, 1, 0, 1);
		Size = NewUdim2(1, -2, 1, -2);
		BackgroundColor3 = FromRgb(255, 255, 255);
		BorderSizePixel = 0;
	});
	self:CreateInstance("UIGradient", {
		Parent = main;
		Rotation = 90;
		Color = NewColorSequence(hex("131418"), hex("17181D"));
	});
	local TopAccent = self:CreateInstance("Frame", {
		Name = "TopAccent";
		Parent = main;
		Size = NewUdim2(1, 0, 0, 1);
		BackgroundColor3 = Library.AccentColor or hex("98BCFF");
		BorderSizePixel = 0;
		ZIndex = 2;
	});
	local TopAccentShade = self:CreateInstance("Frame", {
		Name = "TopAccentShade";
		Parent = main;
		Position = NewUdim2(0, 0, 0, 1);
		Size = NewUdim2(1, 0, 0, 1);
		BackgroundColor3 = Library.ShadeColor or hex("6E8CC8");
		BorderSizePixel = 0;
		ZIndex = 2;
	});
	local TitleLabel = self:CreateInstance("TextLabel", {
		Name = "Title";
		Parent = main;
		Position = NewUdim2(0, 10, 0, 5);
		Size = NewUdim2(1, -20, 0, 14);
		BackgroundTransparency = 1;
		FontFace = Library.Fonts.title;
		Text = TitleText;
		TextColor3 = FromRgb(255, 255, 255);
		TextSize = 9;
		TextXAlignment = Enum.TextXAlignment.Left;
		TextYAlignment = Enum.TextYAlignment.Top;
		ZIndex = 5;
	});
	self:CreateInstance("UIGradient", {
		Parent = TitleLabel;
		Color = NewColorSequence(TopAccent.BackgroundColor3, TopAccentShade.BackgroundColor3);
		Rotation = 90;
	});
	local HeaderDrag = self:CreateInstance("Frame", {
		Name = "HeaderDrag";
		Parent = main;
		Position = NewUdim2(0, 0, 0, 0);
		Size = NewUdim2(1, 0, 0, 22);
		BackgroundTransparency = 1;
		Active = true;
		ZIndex = 4;
	});
	local ViewportOutline = self:CreateInstance("Frame", {
		Name = "MapViewportOutline";
		Parent = main;
		AnchorPoint = NewVector2(0.5, 0);
		Position = NewUdim2(0.5, 0, 0, 24);
		Size = NewUdim2(1, -12, 1, -30);
		BackgroundColor3 = hex("07080A");
		BorderSizePixel = 0;
		ZIndex = 3;
	});
	local ViewportAspect = self:CreateInstance("UIAspectRatioConstraint", {
		Parent = ViewportOutline;
		AspectRatio = 1;
		DominantAxis = Enum.DominantAxis.Height;
	});
	local ViewportMid = self:CreateInstance("Frame", {
		Name = "Mid";
		Parent = ViewportOutline;
		Position = NewUdim2(0, 1, 0, 1);
		Size = NewUdim2(1, -2, 1, -2);
		BackgroundColor3 = hex("24262D");
		BorderSizePixel = 0;
		ZIndex = 4;
	});
	local Viewport = self:CreateInstance("Frame", {
		Name = "MapViewport";
		Parent = ViewportMid;
		Position = NewUdim2(0, 1, 0, 1);
		Size = NewUdim2(1, -2, 1, -2);
		BackgroundColor3 = hex("101114");
		BorderSizePixel = 0;
		ClipsDescendants = true;
		ZIndex = 5;
	});

	self:Draggable(outer, HeaderDrag);
	self:Resizable(outer, { MinX = 200; MinY = 200 });

	local panel = { Gui = gui, Outer = outer, Inner = inner, Main = main, Content = Viewport, Viewport = Viewport, ViewportOutline = ViewportOutline, ViewportAspect = ViewportAspect };
	function panel:SetVisible(on) Library:SetWidgetVisible(self, on) end;
	function panel:Destroy()
		if self.Gui and self.Gui.Parent then self.Gui:Destroy() end;
		if Library.CurrentMapPanel == panel then Library.CurrentMapPanel = nil end;
	end;

	self.CurrentMapPanel = panel;
	self:TrackWidget(panel, "MapV3");
	return panel;
end;

--// ESP Preview panel
function Library:EspPreview(opts)
	opts = typeof(opts) == "table" and opts or {};

	if typeof(self.CurrentEspPreview) == "table" and typeof(self.CurrentEspPreview.Gui) == "Instance" and self.CurrentEspPreview.Gui.Parent then
		self.CurrentEspPreview.Gui:Destroy();
	end;
	self.CurrentEspPreview = nil;

	local w = tonumber(opts.width) or 330;
	local h = tonumber(opts.height) or 335;
	local TitleText = tostring(opts.title or "ESP Preview");

	local VpSize = camera.ViewportSize;
	local UiScale = self:ComputeUIScale();
	local DefaultX = MathClamp(tonumber(opts.x) or 1150, 0, MathMax(0, VpSize.X / UiScale - w));
	local DefaultY = MathClamp(tonumber(opts.y) or 70, 0, MathMax(0, VpSize.Y / UiScale - h));
	local pos = opts.position or NewUdim2(0, DefaultX, 0, DefaultY);

	local gui = self:CreateInstance("ScreenGui", {
		Name = "\0";
		Parent = (gethui and gethui()) or CoreGui;
		Enabled = true;
		DisplayOrder = self.WidgetDisplayOrder or 1002;
		IgnoreGuiInset = true;
		ResetOnSpawn = false;
		ZIndexBehavior = Enum.ZIndexBehavior.Global;
	});
	self:ApplyScale(gui);

	local outer = self:CreateInstance("Frame", {
		Name = "Outer";
		Parent = gui;
		Position = pos;
		Size = FromOffset(w, h);
		BackgroundColor3 = hex("07080A");
		BorderSizePixel = 0;
		Active = true;
	});

	self:CreateInstance("ImageLabel", {
		Name = "Glow";
		Parent = outer;
		AnchorPoint = NewVector2(0.5, 0.5);
		Position = NewUdim2(0.5, 0, 0.5, 0);
		Size = NewUdim2(1, 30, 1, 30);
		BackgroundTransparency = 1;
		Image = "rbxassetid://18245826428";
		ImageColor3 = hex("98BCFF");
		ImageTransparency = 0.86;
		ScaleType = Enum.ScaleType.Slice;
		SliceCenter = RectNew(21, 21, 79, 79);
		ZIndex = -1;
	});

	local inner = self:CreateInstance("Frame", {
		Name = "Inner";
		Parent = outer;
		Position = NewUdim2(0, 1, 0, 1);
		Size = NewUdim2(1, -2, 1, -2);
		BackgroundColor3 = hex("24262D");
		BorderSizePixel = 0;
	});

	local main = self:CreateInstance("Frame", {
		Name = "Main";
		Parent = inner;
		Position = NewUdim2(0, 1, 0, 1);
		Size = NewUdim2(1, -2, 1, -2);
		BackgroundColor3 = FromRgb(255, 255, 255);
		BorderSizePixel = 0;
	});
	self:CreateInstance("UIGradient", {
		Parent = main; Rotation = 90;
		Color = NewColorSequence(hex("131418"), hex("17181D"));
	});

	local TopAccent = self:CreateInstance("Frame", {
		Name = "TopAccent";
		Parent = main;
		Position = NewUdim2(0, 0, 0, 0);
		Size = NewUdim2(1, 0, 0, 1);
		BackgroundColor3 = Library.Flags["appearance.AccentColor"] or Library.AccentColor or hex("98BCFF");
		BorderSizePixel = 0;
		ZIndex = 2;
	});
	local TopAccentShade = self:CreateInstance("Frame", {
		Name = "TopAccentShade";
		Parent = main;
		Position = NewUdim2(0, 0, 0, 1);
		Size = NewUdim2(1, 0, 0, 1);
		BackgroundColor3 = Library.Flags["appearance.ShadeColor"] or Library.ShadeColor or hex("6E8CC8");
		BorderSizePixel = 0;
		ZIndex = 2;
	});

	local header = self:CreateInstance("Frame", {
		Name = "Header";
		Parent = main;
		Position = NewUdim2(0, 0, 0, 0);
		Size = NewUdim2(1, 0, 0, 22);
		BackgroundTransparency = 1;
		BorderSizePixel = 0;
		Active = true;
		ZIndex = 4;
	});

	local TitleLabel = self:CreateInstance("TextLabel", {
		Name = "Title";
		Parent = header;
		Position = NewUdim2(0, 10, 0, 5);
		Size = NewUdim2(0, 100, 0, 14);
		BackgroundTransparency = 1;
		FontFace = Library.Fonts.title;
		Text = TitleText;
		TextColor3 = FromRgb(255, 255, 255);
		TextSize = 9;
		TextXAlignment = Enum.TextXAlignment.Left;
		TextYAlignment = Enum.TextYAlignment.Top;
		ZIndex = 5;
	});
	local TitleGradient = self:CreateInstance("UIGradient", {
		Parent = TitleLabel;
		Color = NewColorSequence(TopAccent.BackgroundColor3, TopAccentShade.BackgroundColor3);
		Rotation = 90;
	});

	local activeTab = tostring(opts.defaultTab or "Players");
	if activeTab ~= "AI" then activeTab = "Players" end;
	local TabButtons = {};
	local TabBar = self:CreateInstance("Frame", {
		Name = "Tabs";
		Parent = main;
		Position = NewUdim2(0, 0, 0, 22);
		Size = NewUdim2(1, 0, 0, 22);
		BackgroundColor3 = hex("101114");
		BorderSizePixel = 0;
		ZIndex = 6;
	});
	self:CreateInstance("Frame", {
		Name = "MergeLine";
		Parent = TabBar;
		Position = NewUdim2(0, 0, 0, 22);
		Size = NewUdim2(1, 0, 0, 1);
		BackgroundColor3 = hex("24262D");
		BorderSizePixel = 0;
		ZIndex = 7;
	});
	self:CreateInstance("Frame", {
		Name = "OutlineLine";
		Parent = TabBar;
		Position = NewUdim2(0, 0, 0, 23);
		Size = NewUdim2(1, 0, 0, 1);
		BackgroundColor3 = hex("07080A");
		BorderSizePixel = 0;
		ZIndex = 7;
	});
	local TabStrip = self:CreateInstance("Frame", {
		Name = "TabStrip";
		Parent = TabBar;
		Size = NewUdim2(1, 0, 1, 0);
		BackgroundTransparency = 1;
		BorderSizePixel = 0;
		ZIndex = 8;
	});
	self:CreateInstance("UIPadding", {
		Parent = TabStrip;
		PaddingBottom = NewUdim(0, 1);
	});
	self:CreateInstance("UIListLayout", {
		Parent = TabStrip;
		FillDirection = Enum.FillDirection.Horizontal;
		SortOrder = Enum.SortOrder.LayoutOrder;
		VerticalAlignment = Enum.VerticalAlignment.Top;
		Padding = NewUdim(0, 0);
	});

	local function MakeTab(name, order)
		local outerTab = self:CreateInstance("Frame", {
			Name = name .. "Tab";
			Parent = TabStrip;
			Size = NewUdim2(0, 0, 1, 0);
			AutomaticSize = Enum.AutomaticSize.X;
			BackgroundTransparency = 1;
			BorderSizePixel = 0;
			LayoutOrder = order;
			ZIndex = 8;
		});

		local label = self:CreateInstance("TextLabel", {
			Name = "Label";
			Parent = outerTab;
			Position = NewUdim2(0, 0, 0, 6);
			Size = NewUdim2(0, 0, 0, 9);
			AutomaticSize = Enum.AutomaticSize.X;
			BackgroundTransparency = 1;
			BorderSizePixel = 0;
			FontFace = Library.Fonts.title;
			Text = string.upper(name);
			TextColor3 = FromRgb(165, 170, 180);
			TextSize = 9;
			TextXAlignment = Enum.TextXAlignment.Center;
			TextYAlignment = Enum.TextYAlignment.Center;
			ZIndex = 9;
		});
		self:CreateInstance("UIPadding", {
			Parent = label;
			PaddingLeft = NewUdim(0, 8);
			PaddingRight = NewUdim(0, 8);
		});
		local button = self:CreateInstance("TextButton", {
			Name = "Hit";
			Parent = outerTab;
			Size = NewUdim2(1, 0, 1, 0);
			BackgroundTransparency = 1;
			BorderSizePixel = 0;
			AutoButtonColor = false;
			Text = "";
			ZIndex = 10;
		});

		TabButtons[name] = { Outer = outerTab; Label = label; Button = button };
		self:Connection(button.MouseButton1Click, function()
			activeTab = name;
		end);
	end;

	MakeTab("Players", 1);
	MakeTab("AI", 2);

	local BodyOutline = self:CreateInstance("Frame", {
		Name = "BodyOutline";
		Parent = main;
		Position = NewUdim2(0, 6, 0, 48);
		Size = NewUdim2(1, -12, 1, -54);
		BackgroundColor3 = hex("07080A");
		BorderSizePixel = 0;
		ZIndex = 2;
	});
	local BodyInner = self:CreateInstance("Frame", {
		Name = "Inner";
		Parent = BodyOutline;
		Position = NewUdim2(0, 1, 0, 1);
		Size = NewUdim2(1, -2, 1, -2);
		BackgroundColor3 = hex("24262D");
		BorderSizePixel = 0;
		ZIndex = 2;
	});
	local body = self:CreateInstance("Frame", {
		Name = "Body";
		Parent = BodyInner;
		Position = NewUdim2(0, 1, 0, 1);
		Size = NewUdim2(1, -2, 1, -2);
		BackgroundColor3 = FromRgb(255, 255, 255);
		BorderSizePixel = 0;
		ZIndex = 2;
	});
	self:CreateInstance("UIGradient", {
		Parent = body; Rotation = 90;
		Color = NewColorSequence(hex("131418"), hex("17181D"));
	});

	local ViewportBg = self:CreateInstance("Frame", {
		Name = "ViewportBg";
		Parent = body;
		Position = NewUdim2(0, 4, 0, 4);
		Size = NewUdim2(1, -8, 1, -8);
		BackgroundColor3 = FromRgb(255, 255, 255);
		BorderSizePixel = 0;
		ZIndex = 2;
	});
	self:CreateInstance("UIGradient", {
		Parent = ViewportBg;
		Rotation = 90;
		Color = NewColorSequence(hex("131418"), hex("17181D"));
	});

	local viewport = self:CreateInstance("ViewportFrame", {
		Name = "Viewport";
		Parent = body;
		Position = NewUdim2(0, 4, 0, 4);
		Size = NewUdim2(1, -8, 1, -8);
		BackgroundTransparency = 1;
		BorderSizePixel = 0;
		Ambient = FromRgb(180, 180, 190);
		LightColor = FromRgb(255, 255, 255);
		LightDirection = Vector3.new(-0.4, -1, -0.6);
		ZIndex = 3;
	});

	local overlay = self:CreateInstance("Frame", {
		Name = "Overlay";
		Parent = body;
		Position = NewUdim2(0, 4, 0, 4);
		Size = NewUdim2(1, -8, 1, -8);
		BackgroundTransparency = 1;
		BorderSizePixel = 0;
		ZIndex = 20;
	});

	local cam = self:CreateInstance("Camera", { Parent = viewport });
	viewport.CurrentCamera = cam;

	local DummyColor = typeof(opts.DummyColor) == "Color3" and opts.DummyColor or FromRgb(163, 162, 165);
	local function MakePart(name, size, position)
		local p = InstanceNew("Part");
		p.Name = name;
		p.Size = size;
		p.CFrame = CFrame.new(position);
		p.Color = DummyColor;
		p.Material = Enum.Material.Plastic;
		p.Anchored = true;
		p.CanCollide = false;
		p.TopSurface = Enum.SurfaceType.Smooth;
		p.BottomSurface = Enum.SurfaceType.Smooth;
		return p;
	end;

	local dummy = InstanceNew("Model");
	dummy.Name = "PreviewDummy";

	local hrp = MakePart("HumanoidRootPart", Vector3.new(2, 2, 1), Vector3.new(0, 0, 0));
	hrp.Transparency = 1;
	hrp.Parent = dummy;

	local torso = MakePart("Torso", Vector3.new(2, 2, 1), Vector3.new(0, 0, 0));
	torso.Parent = dummy;

	local head = MakePart("Head", Vector3.new(2, 1, 1), Vector3.new(0, 1.5, 0));
	local HeadMesh = InstanceNew("SpecialMesh");
	HeadMesh.MeshType = Enum.MeshType.Head;
	HeadMesh.Scale = Vector3.new(1.25, 1.25, 1.25);
	HeadMesh.Parent = head;
	head.Parent = dummy;

	MakePart("Left Arm", Vector3.new(1, 2, 1), Vector3.new(-1.5, 0, 0)).Parent = dummy;
	MakePart("Right Arm", Vector3.new(1, 2, 1), Vector3.new(1.5, 0, 0)).Parent = dummy;
	MakePart("Left Leg", Vector3.new(1, 2, 1), Vector3.new(-0.5, -2, 0)).Parent = dummy;
	MakePart("Right Leg", Vector3.new(1, 2, 1), Vector3.new(0.5, -2, 0)).Parent = dummy;

	local humanoid = InstanceNew("Humanoid");
	humanoid.Health = 82;
	humanoid.MaxHealth = 100;
	humanoid.Parent = dummy;

	dummy.PrimaryPart = hrp;
	dummy.Parent = viewport;

	local renderers = typeof(opts.Renderers) == "table" and opts.Renderers or typeof(opts.renderers) == "table" and opts.renderers or {};
	local previewData = {
		Players = {
			Name = "PLAYER";
			Player = { Name = "PLAYER" };
			Pointer = "ESPPreviewPlayers";
			Character = dummy;
			Humanoid = humanoid;
			RootPart = hrp;
			RootPosition = hrp.Position;
			Health = 82;
			MaxHealth = 100;
			Relation = "Enemy";
			BodyParts = {
				HumanoidRootPart = hrp;
				Torso = torso;
				Head = head;
				["Left Arm"] = dummy:FindFirstChild("Left Arm");
				["Right Arm"] = dummy:FindFirstChild("Right Arm");
				["Left Leg"] = dummy:FindFirstChild("Left Leg");
				["Right Leg"] = dummy:FindFirstChild("Right Leg");
			};
			Flags = { "ENEMY"; "VISIBLE" };
			Weapon = "M4A1";
		};
		AI = {
			Name = "SCAV";
			Player = { Name = "SCAV" };
			Pointer = "ESPPreviewAI";
			Character = dummy;
			Humanoid = humanoid;
			RootPart = hrp;
			RootPosition = hrp.Position;
			Health = 82;
			MaxHealth = 100;
			Relation = "Enemy";
			BodyParts = {
				HumanoidRootPart = hrp;
				Torso = torso;
				Head = head;
				["Left Arm"] = dummy:FindFirstChild("Left Arm");
				["Right Arm"] = dummy:FindFirstChild("Right Arm");
				["Left Leg"] = dummy:FindFirstChild("Left Leg");
				["Right Leg"] = dummy:FindFirstChild("Right Leg");
			};
			Flags = { "AI"; "HOSTILE" };
			Weapon = "AKM";
		};
	};

	local cf, size = dummy:GetBoundingBox();
	local focus = cf.Position + Vector3.new(0, size.Y * 0.08, 0);
	local dist = MathMax(size.X, size.Y, size.Z) * 2.2;
	cam.CFrame = CFrame.new(focus + Vector3.new(0, size.Y * 0.04, dist), focus);

	local yaw = math.pi;
	local pitch = 0;
	local dragging = false;
	local LastInput;

	local function ApplyPose()
		dummy:PivotTo(CFrame.new(cf.Position) * CFrame.fromEulerAnglesYXZ(0, yaw, 0) * CFrame.new(-cf.Position));
		local offset = CFrame.fromEulerAnglesYXZ(pitch, 0, 0) * CFrame.new(0, size.Y * 0.04, dist);
		cam.CFrame = CFrame.new((CFrame.new(focus) * offset).Position, focus);
	end;

	self:Connection(viewport.InputBegan, function(input)
		if input.UserInputType == Enum.UserInputType.MouseButton1
			or input.UserInputType == Enum.UserInputType.Touch then
			dragging = true;
			LastInput = input.Position;
		end;
	end);
	self:Connection(viewport.InputEnded, function(input)
		if input.UserInputType == Enum.UserInputType.MouseButton1
			or input.UserInputType == Enum.UserInputType.Touch then
			dragging = false;
			LastInput = nil;
		end;
	end);
	self:Connection(UserInputService.InputChanged, function(input)
		if not dragging or not LastInput then return end;
		if input.UserInputType ~= Enum.UserInputType.MouseMovement
			and input.UserInputType ~= Enum.UserInputType.Touch then return end;
		local dx = input.Position.X - LastInput.X;
		local dy = input.Position.Y - LastInput.Y;
		LastInput = input.Position;
		yaw = yaw - dx * 0.012;
		pitch = MathClamp(pitch + dy * 0.012, -math.rad(78), math.rad(78));
		ApplyPose();
	end);

	local function SyncTabs()
		local ActiveColor = Library.Flags["appearance.AccentColor"] or Library.AccentColor or TopAccent.BackgroundColor3 or hex("98BCFF");
		local ShadeColor = Library.Flags["appearance.ShadeColor"] or Library.ShadeColor or TopAccentShade.BackgroundColor3 or hex("6E8CC8");
		TopAccent.BackgroundColor3 = ActiveColor;
		TopAccentShade.BackgroundColor3 = ShadeColor;
		TitleGradient.Color = NewColorSequence(ActiveColor, ShadeColor);

		for TabName, Tab in TabButtons do
			local Active = TabName == activeTab;
			Tab.Label.TextColor3 = Active and ActiveColor or hex("8A8A92");
		end;
	end;

	local function HideRenderSet(renders)
		if not renders then return end;
		for _, render in renders do
			if typeof(render) == "Instance" then
				pcall(function()
					render.Visible = false;
				end);
			elseif typeof(render) == "table" then
				HideRenderSet(render);
			end;
		end;
	end;

	local function ApplyPreviewState()
		SyncTabs();

		local renderer = activeTab == "AI" and renderers.AI or renderers.Players;
		if renderer and renderer.Step and renderer.CreateRenders then
			for TabName, Data in previewData do
				if TabName ~= activeTab then HideRenderSet(Data.Renders); end;
			end;

			local Data = previewData[activeTab];
			Data.Name = activeTab == "AI" and "SCAV" or "PLAYER";
			Data.Player.Name = Data.Name;
			Data.RootPosition = hrp.Position;
			Data.RootCFrame = hrp.CFrame;
			Data.Health = humanoid.Health;
			Data.MaxHealth = humanoid.MaxHealth;

			local _, _, previewScale = self:GuiPoint(gui, 0, 0);
			local AbsSize = overlay.AbsoluteSize;
			local viewportSize = Vector2.new(AbsSize.X / previewScale, AbsSize.Y / previewScale);
			local centerScreen = cam.CFrame:PointToObjectSpace(focus);
			local centerDepth = -centerScreen.Z;
			local centerOffset = Vector2.new();
			if centerDepth > 0 then
				local height = MathMax(viewportSize.Y, 1);
				local width = MathMax(viewportSize.X, 1);
				local scale = 1 / math.tan(math.rad(70) * 0.5);
				centerOffset = Vector2.new(
					(centerScreen.X / centerDepth) * scale * height * 0.5 + width * 0.5,
					(-centerScreen.Y / centerDepth) * scale * height * 0.5 + height * 0.5
				) - Vector2.new(width * 0.5, height * 0.5);
			end;
			local fakeCamera = {
				ViewportSize = viewportSize;
				CFrame = cam.CFrame;
				FieldOfView = 70;
				WorldToViewportPoint = function(self, position)
					local relative = self.CFrame:PointToObjectSpace(position);
					local z = -relative.Z;
					if z <= 0 then
						return Vector3.new(0, 0, -1);
					end;

					local height = MathMax(viewportSize.Y, 1);
					local width = MathMax(viewportSize.X, 1);
					local scale = 1 / math.tan(math.rad(70) * 0.5);
					local x = (relative.X / z) * scale * height * 0.5 + width * 0.5 - centerOffset.X;
					local y = (-relative.Y / z) * scale * height * 0.5 + height * 0.5 - centerOffset.Y;
					return Vector3.new(x, y, z);
				end;
			};

			if not Data.Renders or Data.Renders[1].Parent ~= overlay then
				local oldOverlay = renderer.Overlay;
				renderer.Overlay = overlay;
				Data.Renders = renderer:CreateRenders(Data);
				renderer.Overlay = oldOverlay;

				if not Data.Renders.ConfigLeft then
					local box = Data.Renders[1];
					local function MakeContainer(name, pos, size, anchor)
						local f = Instance.new("Frame");
						f.Name = name;
						f.Parent = box;
						f.BackgroundTransparency = 1;
						f.BorderSizePixel = 0;
						f.ZIndex = 30;
						f.Visible = true;
						f.Position = pos;
						f.Size = size;
						if anchor then f.AnchorPoint = anchor end;
						Data.Renders["Config" .. name] = f;
						return f;
					end;
					local left = MakeContainer("Left", NewUdim2(0, -1, 0, 0), NewUdim2(0, 60, 1, 0), Vector2.new(1, 0));
					local right = MakeContainer("Right", NewUdim2(1, 1, 0, 0), NewUdim2(0, 60, 1, 0));
					local top = MakeContainer("Top", NewUdim2(0, 0, 0, -1), NewUdim2(1, 0, 0, 60), Vector2.new(0, 1));
					local bottom = MakeContainer("Bottom", NewUdim2(0, 0, 1, 1), NewUdim2(1, 0, 0, 60));
					for _, side in ipairs({left, right, top, bottom}) do
						local texts = Instance.new("Frame");
						texts.Name = side.Name .. "Texts";
						texts.Parent = side;
						texts.BackgroundTransparency = 1;
						texts.BorderSizePixel = 0;
						if side == left then
							texts.Size = UDim2.new(0, 0, 1, 0);
							texts.Position = UDim2.new(1, -1, 0, 0);
							texts.AnchorPoint = Vector2.new(1, 0);
							texts.AutomaticSize = Enum.AutomaticSize.X;
						elseif side == right then
							texts.Size = UDim2.new(0, 0, 1, 0);
							texts.Position = UDim2.new(0, 1, 0, 0);
							texts.AutomaticSize = Enum.AutomaticSize.X;
						elseif side == top then
							texts.Size = UDim2.new(1, 0, 0, 0);
							texts.Position = UDim2.new(0, 0, 1, -1);
							texts.AnchorPoint = Vector2.new(0, 1);
							texts.AutomaticSize = Enum.AutomaticSize.XY;
						elseif side == bottom then
							texts.Size = UDim2.new(1, 0, 0, 0);
							texts.Position = UDim2.new(0, 0, 0, 1);
							texts.AutomaticSize = Enum.AutomaticSize.XY;
						end;
						local list = Instance.new("UIListLayout");
						list.Parent = texts;
						list.FillDirection = Enum.FillDirection.Vertical;
						list.HorizontalAlignment = (side == left and Enum.HorizontalAlignment.Right) or (side == right and Enum.HorizontalAlignment.Left) or Enum.HorizontalAlignment.Center;
						list.VerticalAlignment = (side == top and Enum.VerticalAlignment.Bottom) or (side == bottom and Enum.VerticalAlignment.Top) or Enum.VerticalAlignment.Top;
						list.Padding = UDim.new(0, 1);
						list.SortOrder = Enum.SortOrder.LayoutOrder;
					end;
				end;
			end;

			Data.PreviewSettings = Data.PreviewSettings or {
				NamePosition = renderer.Settings and renderer.Settings.NamePosition or "Top";
				WeaponPosition = renderer.Settings and renderer.Settings.WeaponPosition or "Bottom";
				DistancePosition = renderer.Settings and renderer.Settings.DistancePosition or "Bottom";
				FlagsPosition = renderer.Settings and renderer.Settings.FlagsPosition or "Right";
				HealthBarPosition = renderer.Settings and renderer.Settings.HealthBarPosition or "Left";
			};

			local oldPlayers, oldPlayersIndex, oldCamera, oldActiveState = renderer.Players, renderer.PlayersIndex, renderer.Camera, renderer.ActiveState;
			local settings = {};
			for key, value in renderer.Settings or {} do
				settings[key] = value;
			end;
			for key, value in Data.PreviewSettings do
				settings[key] = value;
			end;
			settings.Activation = true;
			settings.Chams = false;
			settings.OutOfView = false;
			if settings.BoxStyle == "Solid" then
				settings.BoxStyle = "Corner";
				settings.CornerBox = true;
			end;
			do
				local BoxColor = settings.BoundingBoxColor;
				local NameColor = settings.NameColor;
				local DistanceColor = settings.DistanceColor;
				settings.BoundingBoxColor = {
					Color = BoxColor and BoxColor.Color or Color3.fromRGB(255, 255, 255);
					Transparency = 0;
				};
				settings.NameColor = {
					Color = NameColor and NameColor.Color or Color3.fromRGB(255, 255, 255);
					Transparency = 0;
				};
				settings.DistanceColor = {
					Color = DistanceColor and DistanceColor.Color or Color3.fromRGB(255, 255, 255);
					Transparency = 0;
				};
			end;

			renderer.Camera = fakeCamera;
			renderer:Step(settings, { Data }, 1);

			-- ESP Preview Drags
			if not Data.PreviewDrags then
				Data.PreviewDrags = true
				Data.Dragging = Data.Dragging or {}
				Data.Ghosts = Data.Ghosts or {}

				local function FindClosestFrame(position, containers)
					local minDist = math.huge
					local closest = nil
					for _, frame in ipairs(containers) do
						local pos = frame.AbsolutePosition
						local size = frame.AbsoluteSize
						local center = pos + size * 0.5
						local dist = (position - center).Magnitude
						if dist < minDist then
								minDist = dist
								closest = frame
							end
						end
						return closest
					end

				local function PreviewSet(Data, elementName, side)
					Data.PreviewSettings = Data.PreviewSettings or {}
					Data.PreviewSettings[elementName .. "Position"] = side
					local renderer = activeTab == "AI" and renderers.AI or renderers.Players
					if renderer and renderer.Settings then
						renderer.Settings[elementName .. "Position"] = side
					end
					local flagPrefix = activeTab == "AI" and "AIESP" or "PlayerESP"
					local flag = flagPrefix .. elementName .. "Position"
					if Library.Flags[flag] ~= side then
						Library.Flags[flag] = side
						local setter = Library.ConfigFlags[flag]
						if typeof(setter) == "function" then
							setter(side)
						end
					end
				end

				local function MakeDragHandle(parent)
					local btn = Instance.new("TextButton")
					btn.Name = "DragHandle"
					btn.Parent = parent
					btn.BackgroundTransparency = 1
					btn.BorderSizePixel = 0
					btn.Text = ""
					btn.ZIndex = 100
					btn.Active = true
					btn.Size = UDim2.new(0, 60, 0, 30)
					btn.Position = UDim2.new(0.5, -30, 0.5, -15)
					return btn
				end

				local function SetupDrag(elementName, getTarget, getHandleParents)
					local isDragging = false
					local dragStarted = false
					local dragStartPos = nil
					local ghost = nil
					local originalParents = {}

					local function getContainers()
						local d = previewData[activeTab]
						local containers = {}
						if d and d.Renders then
							for _, side in ipairs({"Left", "Right", "Top", "Bottom"}) do
								local c = d.Renders["Config" .. side]
								if c then
									table.insert(containers, c)
									c.BackgroundTransparency = 1
									end
								end
							end
							return containers
						end

						local function ensureHandles()
							local parents = getHandleParents()
							if not parents then return {} end
							if typeof(parents) == "Instance" then parents = {parents} end
							local handles = {}
							for _, parent in ipairs(parents) do
								if not parent then continue end
								local h = parent:FindFirstChild("DragHandle")
								if not h then
									h = MakeDragHandle(parent)
								end
								table.insert(handles, h)
							end
							return handles
						end

						local function startDrag(input)
							isDragging = true
							Data.Dragging[elementName] = true
							local target = getTarget()
							if target then
								originalParents = {}
								if typeof(target) == "Instance" then
									table.insert(originalParents, target.Parent)
									target.Parent = nil
								elseif typeof(target) == "table" then
									for _, obj in target do
										if obj then
											table.insert(originalParents, obj.Parent)
											obj.Parent = nil
										end
									end
								end

								ghost = Instance.new("Frame")
								ghost.Name = elementName .. "Ghost"
								ghost.Parent = gui
								ghost.BackgroundTransparency = 0.85
								ghost.BackgroundColor3 = Color3.fromRGB(255, 255, 255)
								ghost.BorderSizePixel = 1
								ghost.BorderColor3 = Color3.fromRGB(180, 180, 180)
								ghost.ZIndex = 200

								local minX, minY = math.huge, math.huge
								local maxX, maxY = -math.huge, -math.huge
								local function expandBounds(obj)
									if obj and obj.Visible then
										local pos = obj.AbsolutePosition
										local size = obj.AbsoluteSize
										minX = math.min(minX, pos.X)
										minY = math.min(minY, pos.Y)
										maxX = math.max(maxX, pos.X + size.X)
										maxY = math.max(maxY, pos.Y + size.Y)
									end
								end
								if typeof(target) == "Instance" then
									expandBounds(target)
								elseif typeof(target) == "table" then
									for _, obj in target do
										expandBounds(obj)
									end
								end
								if minX ~= math.huge then
									ghost.Position = UDim2.new(0, minX / UiScale, 0, minY / UiScale)
									ghost.Size = UDim2.new(0, (maxX - minX) / UiScale, 0, (maxY - minY) / UiScale)
								else
									ghost:Destroy()
									ghost = nil
									isDragging = false
									Data.Dragging[elementName] = false
									return
								end
								Data.Ghosts[elementName] = ghost
							end
						end

						local function moveDrag(input, containers)
							if not dragStarted or not ghost then return end
							local mousePos = Vector2.new(input.Position.X, input.Position.Y)
							ghost.Position = UDim2.new(0, mousePos.X / UiScale, 0, mousePos.Y / UiScale)
							if containers then
								local closest = FindClosestFrame(mousePos, containers)
								for _, c in ipairs(containers) do
									if c == closest then
										c.BackgroundTransparency = 0.85
										c.BackgroundColor3 = Color3.fromRGB(255, 255, 255)
									else
										c.BackgroundTransparency = 1
									end
								end
							end
						end

						local function endDrag(input, containers)
							if not dragStarted then
								isDragging = false
								dragStartPos = nil
								return
							end
							isDragging = false
							dragStarted = false
							dragStartPos = nil
							Data.Dragging[elementName] = false

							local target = getTarget()
							if target then
								if typeof(target) == "Instance" then
									target.Parent = originalParents[1] or Data.Renders[1]
								elseif typeof(target) == "table" then
									for i, obj in ipairs(target) do
										if obj then
											obj.Parent = originalParents[i] or Data.Renders[1]
										end
									end
								end
							end

							if ghost then
								ghost:Destroy()
								ghost = nil
								Data.Ghosts[elementName] = nil
							end

							if containers then
								for _, c in ipairs(containers) do
									c.BackgroundTransparency = 1
								end
							end

							local d = previewData[activeTab]
							if d and d.Renders then
								local dropContainers = {}
								for _, side in ipairs({"Left", "Right", "Top", "Bottom"}) do
									local c = d.Renders["Config" .. side]
									if c then table.insert(dropContainers, c) end
								end
								local mousePos = Vector2.new(input.Position.X, input.Position.Y)
								local closest = FindClosestFrame(mousePos, dropContainers)
								if closest then
									PreviewSet(d, elementName, closest.Name)
								end
							end
						end

						local function onInputBegan(input)
							if input.UserInputType == Enum.UserInputType.MouseButton1 then
								isDragging = true
								dragStartPos = Vector2.new(input.Position.X, input.Position.Y)
							end
						end
						local function onInputEnded(input)
							if input.UserInputType == Enum.UserInputType.MouseButton1 then
								endDrag(input, getContainers())
							end
						end

						Library:Connection(UserInputService.InputChanged, function(input)
							if not isDragging then return end
							if input.UserInputType == Enum.UserInputType.MouseMovement then
								local mousePos = Vector2.new(input.Position.X, input.Position.Y)
								local containers = getContainers()
								if not dragStarted then
									local delta = (mousePos - dragStartPos).Magnitude
									if delta > 4 then
										dragStarted = true
										startDrag(input)
									end
								end
								if dragStarted then
									moveDrag(input, containers)
								end
							end
						end)
						Library:Connection(UserInputService.InputEnded, function(input)
							if input.UserInputType == Enum.UserInputType.MouseButton1 then
								endDrag(input, getContainers())
							end
						end)

						for _, handle in ipairs(ensureHandles()) do
							Library:Connection(handle.InputBegan, onInputBegan)
							Library:Connection(handle.InputEnded, onInputEnded)
						end
					end

					local Renders = Data.Renders
					SetupDrag("Name", function() return Renders[8] end, function() return Renders[8] end)
					SetupDrag("Weapon", function() return Renders[10] end, function() return Renders[10] end)
					SetupDrag("Distance", function() return Renders[11] end, function() return Renders[11] end)
					SetupDrag("HealthBar", function() return {Renders[6], Renders[7]} end, function() return {Renders[6], Renders[7]} end)
					SetupDrag("Flags", function()
							local visibleFlags = {}
							if Renders.Flags then
								for _, label in Renders.Flags do
									if label.Visible then table.insert(visibleFlags, label) end
								end
							end
							return visibleFlags
						end, function()
							local parents = {}
							if Renders.Flags then
								for _, label in Renders.Flags do
									if label.Visible then table.insert(parents, label) end
								end
							end
							return parents
						end)
				end

				renderer.Players = oldPlayers;
			renderer.PlayersIndex = oldPlayersIndex;
			renderer.Camera = oldCamera;
			renderer.ActiveState = oldActiveState;
			return;
		end;
	end;

	ApplyPreviewState();
	local PreviewAccumulator = 0;
	self:Connection(RunService.RenderStepped, function(dt)
		if not main.Parent or not dummy.Parent then return end;
		if gui.Enabled == false or outer.Visible == false then return end;
		PreviewAccumulator += dt;
		if PreviewAccumulator < 1 / 30 then return end;
		dt = PreviewAccumulator;
		PreviewAccumulator = 0;
		if not dragging then
			yaw = yaw + dt * 0.6;
		end;
		ApplyPose();
		ApplyPreviewState();
	end);

	self:Draggable(outer, header);

	local panel = { Gui = gui, Outer = outer, Viewport = viewport, Camera = cam };
	function panel:SetVisible(on) Library:SetWidgetVisible(self, on) end;
	function panel:Destroy()
		if self.Gui and self.Gui.Parent then self.Gui:Destroy() end;
		if Library.CurrentEspPreview == panel then Library.CurrentEspPreview = nil end;
	end;

	self.CurrentEspPreview = panel;
	self:TrackWidget(panel, "EspPreview");
	return panel
end

--// Player list
Library.Themes = Library.Themes or {
	{ name = "Default";    accent = hex("98BCFF");                shade = hex("6E8CC8");                bg = hex("101114") };
	{ name = "Dracula";    accent = FromRgb(189, 147, 249);      shade = FromRgb(139, 107, 184);      bg = FromRgb(40, 42, 54) };
	{ name = "Cherry";     accent = FromRgb(204, 51, 71);        shade = FromRgb(150, 30, 50);        bg = FromRgb(28, 12, 16) };
	{ name = "Nord";       accent = FromRgb(143, 188, 187);      shade = FromRgb(101, 138, 138);      bg = FromRgb(46, 52, 64) };
	{ name = "Monokai";    accent = FromRgb(166, 226, 46);       shade = FromRgb(118, 161, 30);       bg = FromRgb(39, 40, 34) };
	{ name = "Tokyo";      accent = FromRgb(187, 154, 247);      shade = FromRgb(135, 111, 178);      bg = FromRgb(26, 27, 38) };
	{ name = "Catppuccin"; accent = FromRgb(203, 166, 247);      shade = FromRgb(147, 121, 178);      bg = FromRgb(30, 30, 46) };
	{ name = "Solarized";  accent = FromRgb(181, 137, 0);        shade = FromRgb(131, 99, 0);         bg = FromRgb(0, 43, 54) };
	{ name = "Gruvbox";    accent = FromRgb(250, 189, 47);       shade = FromRgb(178, 134, 35);       bg = FromRgb(40, 40, 40) };
	{ name = "Synthwave";  accent = FromRgb(0, 229, 255);        shade = FromRgb(0, 165, 184);        bg = FromRgb(34, 17, 51) };
};

Library.PlayerTags = Library.PlayerTags or {};
Library.PlayerTagColors = {
	None = FromRgb(220, 220, 220);
	Enemy = FromRgb(235, 75, 75);
	Friend = FromRgb(80, 145, 245);
	Caution = FromRgb(245, 200, 70);
};

function Library:PlayerList(opts)
	opts = typeof(opts) == "table" and opts or {};

	if typeof(self.CurrentPlayerList) == "table" and typeof(self.CurrentPlayerList.Gui) == "Instance" and self.CurrentPlayerList.Gui.Parent then
		self.CurrentPlayerList.Gui:Destroy();
	end;
	self.CurrentPlayerList = nil;

	local w = tonumber(opts.width) or 480;
	local h = tonumber(opts.height) or 400;
	local TitleText = tostring(opts.title or "Players");

	local VpSize = camera.ViewportSize;
	local UiScale = self:ComputeUIScale();
	local DefaultX = MathClamp(tonumber(opts.x) or 650, 0, MathMax(0, VpSize.X / UiScale - w));
	local DefaultY = MathClamp(tonumber(opts.y) or 415, 0, MathMax(0, VpSize.Y / UiScale - h));
	local pos = opts.position or NewUdim2(0, DefaultX, 0, DefaultY);

	local gui = self:CreateInstance("ScreenGui", {
		Name = "\0";
		Parent = (gethui and gethui()) or CoreGui;
		Enabled = true;
		DisplayOrder = self.WidgetDisplayOrder or 1002;
		IgnoreGuiInset = true;
		ResetOnSpawn = false;
		ZIndexBehavior = Enum.ZIndexBehavior.Global;
	});
	self:ApplyScale(gui);

	local outer = self:CreateInstance("Frame", {
		Name = "Outer"; Parent = gui;
		Position = pos; Size = FromOffset(w, h);
		BackgroundColor3 = hex("07080A"); BorderSizePixel = 0; Active = true;
	});
	self:CreateInstance("ImageLabel", {
		Name = "Glow"; Parent = outer;
		AnchorPoint = NewVector2(0.5, 0.5);
		Position = NewUdim2(0.5, 0, 0.5, 0);
		Size = NewUdim2(1, 30, 1, 30);
		BackgroundTransparency = 1;
		Image = "rbxassetid://18245826428";
		ImageColor3 = hex("98BCFF");
		ImageTransparency = 0.86;
		ScaleType = Enum.ScaleType.Slice;
		SliceCenter = RectNew(21, 21, 79, 79);
		ZIndex = -1;
	});
	local inner = self:CreateInstance("Frame", {
		Name = "Inner"; Parent = outer;
		Position = NewUdim2(0, 1, 0, 1); Size = NewUdim2(1, -2, 1, -2);
		BackgroundColor3 = hex("24262D"); BorderSizePixel = 0;
	});
	local main = self:CreateInstance("Frame", {
		Name = "Main"; Parent = inner;
		Position = NewUdim2(0, 1, 0, 1); Size = NewUdim2(1, -2, 1, -2);
		BackgroundColor3 = FromRgb(255, 255, 255); BorderSizePixel = 0;
	});
	self:CreateInstance("UIGradient", {
		Parent = main; Rotation = 90;
		Color = NewColorSequence(hex("131418"), hex("17181D"));
	});
	self:CreateInstance("Frame", {
		Name = "TopAccent"; Parent = main;
		Position = NewUdim2(0, 0, 0, 0); Size = NewUdim2(1, 0, 0, 1);
		BackgroundColor3 = hex("98BCFF"); BorderSizePixel = 0; ZIndex = 2;
	});
	self:CreateInstance("Frame", {
		Name = "TopAccentShade"; Parent = main;
		Position = NewUdim2(0, 0, 0, 1); Size = NewUdim2(1, 0, 0, 1);
		BackgroundColor3 = hex("6E8CC8"); BorderSizePixel = 0; ZIndex = 2;
	});

	local header = self:CreateInstance("Frame", {
		Name = "Header"; Parent = main;
		Position = NewUdim2(0, 0, 0, 0); Size = NewUdim2(1, 0, 0, 22);
		BackgroundTransparency = 1; Active = true; ZIndex = 4;
	});
	local TitleLabel = self:CreateInstance("TextLabel", {
		Name = "Title"; Parent = header;
		Position = NewUdim2(0, 10, 0, 5); Size = NewUdim2(1, -20, 0, 14);
		BackgroundTransparency = 1;
		FontFace = Library.Fonts.title;
		Text = TitleText;
		TextColor3 = FromRgb(255, 255, 255);
		TextSize = 9;
		TextXAlignment = Enum.TextXAlignment.Left;
		TextYAlignment = Enum.TextYAlignment.Top;
		ZIndex = 5;
	});
	self:CreateInstance("UIGradient", {
		Parent = TitleLabel;
		Color = NewColorSequence(hex("98BCFF"), hex("6E8CC8"));
		Rotation = 90;
	});

	local section = self:CreateInstance("Frame", {
		Name = "Section"; Parent = main;
		Position = NewUdim2(0, 6, 0, 22);
		Size = NewUdim2(1, -12, 1, -28);
		BackgroundColor3 = FromRgb(255, 255, 255); BorderSizePixel = 0; ZIndex = 2;
	});
	self:CreateInstance("UIGradient", {
		Parent = section; Rotation = 90;
		Color = NewColorSequence(hex("131418"), hex("17181D"));
	});

	local HeadshotSize = 92;
	local HeadshotOutline = self:CreateInstance("Frame", {
		Name = "HeadshotOutline"; Parent = section;
		AnchorPoint = NewVector2(1, 0);
		Position = NewUdim2(1, -8, 0, 8);
		Size = FromOffset(HeadshotSize, HeadshotSize);
		BackgroundColor3 = hex("07080A");
		BorderSizePixel = 0;
		ZIndex = 3;
	});
	local HeadshotMid = self:CreateInstance("Frame", {
		Name = "Mid"; Parent = HeadshotOutline;
		Position = NewUdim2(0, 1, 0, 1); Size = NewUdim2(1, -2, 1, -2);
		BackgroundColor3 = hex("24262D"); BorderSizePixel = 0; ZIndex = 4;
	});
	local headshot = self:CreateInstance("ImageLabel", {
		Name = "Headshot"; Parent = HeadshotMid;
		Position = NewUdim2(0, 1, 0, 1); Size = NewUdim2(1, -2, 1, -2);
		BackgroundColor3 = hex("131418");
		BorderSizePixel = 0;
		ScaleType = Enum.ScaleType.Crop; Image = "";
		ZIndex = 5;
	});

	local SelectedName = self:CreateInstance("TextLabel", {
		Name = "SelectedName"; Parent = section;
		AnchorPoint = NewVector2(1, 0);
		Position = NewUdim2(1, -8, 0, 8 + HeadshotSize + 4);
		Size = FromOffset(HeadshotSize, 12);
		BackgroundTransparency = 1;
		FontFace = Library.Fonts.title;
		Text = "";
		TextColor3 = FromRgb(255, 255, 255);
		TextSize = 9;
		TextXAlignment = Enum.TextXAlignment.Center;
		TextYAlignment = Enum.TextYAlignment.Center;
		TextTruncate = Enum.TextTruncate.AtEnd;
		ZIndex = 4;
	});

	local TagH = 16;
	local TagBg = self:CreateInstance("Frame", {
		Name = "TagBox"; Parent = section;
		AnchorPoint = NewVector2(1, 0);
		Position = NewUdim2(1, -8, 0, 8 + HeadshotSize + 4 + 12 + 4);
		Size = FromOffset(HeadshotSize, TagH);
		BackgroundColor3 = hex("07080A"); BorderSizePixel = 0; ZIndex = 3;
	});
	local TagMid = self:CreateInstance("Frame", {
		Parent = TagBg;
		Position = NewUdim2(0, 1, 0, 1); Size = NewUdim2(1, -2, 1, -2);
		BackgroundColor3 = hex("24262D"); BorderSizePixel = 0; ZIndex = 3;
	});
	local TagInner = self:CreateInstance("Frame", {
		Parent = TagMid;
		Position = NewUdim2(0, 1, 0, 1); Size = NewUdim2(1, -2, 1, -2);
		BackgroundColor3 = FromRgb(255, 255, 255); BorderSizePixel = 0; ZIndex = 3;
	});
	self:CreateInstance("UIGradient", {
		Parent = TagInner; Rotation = 90;
		Color = NewColorSequence(hex("131418"), hex("17181D"));
	});
	local TagLabel = self:CreateInstance("TextLabel", {
		Parent = TagInner;
		Position = NewUdim2(0, 6, 0, -1); Size = NewUdim2(1, -22, 1, 0);
		BackgroundTransparency = 1;
		FontFace = Library.Fonts.title;
		Text = "None"; TextColor3 = hex("B4B4B4");
		TextSize = 9;
		TextXAlignment = Enum.TextXAlignment.Left;
		TextYAlignment = Enum.TextYAlignment.Center;
		ZIndex = 4;
	});
	local TagArrow = self:CreateInstance("TextLabel", {
		Parent = TagInner;
		AnchorPoint = NewVector2(1, 0.5);
		Position = NewUdim2(1, -4, 0.5, 0); Size = FromOffset(8, 9);
		BackgroundTransparency = 1;
		FontFace = Library.Fonts.title;
		Text = "v"; TextColor3 = hex("B4B4B4");
		TextSize = 9;
		TextXAlignment = Enum.TextXAlignment.Center;
		TextYAlignment = Enum.TextYAlignment.Center;
		ZIndex = 4;
	});
	local TagHit = self:CreateInstance("TextButton", {
		Parent = TagBg;
		Size = NewUdim2(1, 0, 1, 0);
		BackgroundTransparency = 1; AutoButtonColor = false; Text = ""; ZIndex = 5;
	});
	local TagScale = self:CreateInstance("UIScale", {
		Parent = TagBg;
		Scale = 1;
	});
	local TagBtnTween = NewTweenInfo(0.12, Enum.EasingStyle.Quad, Enum.EasingDirection.Out);
	self:Connection(TagHit.MouseEnter, function() self:Tween(TagScale, TagBtnTween, { Scale = 1.025 }):Play() end);
	self:Connection(TagHit.MouseLeave, function() self:Tween(TagScale, TagBtnTween, { Scale = 1 }):Play() end);
	self:Connection(TagHit.MouseButton1Down, function() self:Tween(TagScale, NewTweenInfo(0.07, Enum.EasingStyle.Quad, Enum.EasingDirection.Out), { Scale = 0.975 }):Play() end);
	self:Connection(TagHit.MouseButton1Up, function() self:Tween(TagScale, TagBtnTween, { Scale = 1.025 }):Play() end);

	local SpecBtn = self:CreateInstance("TextButton", {
		Name = "SpectateBtn"; Parent = section;
		AnchorPoint = NewVector2(1, 0);
		Position = NewUdim2(1, -8, 0, 8 + HeadshotSize + 4 + 12 + 4 + TagH + 6);
		Size = FromOffset(HeadshotSize, 18);
		BackgroundColor3 = hex("07080A");
		BorderSizePixel = 0;
		AutoButtonColor = false;
		Text = "";
		ZIndex = 3;
	});
	local SpecMid = self:CreateInstance("Frame", {
		Parent = SpecBtn;
		Position = NewUdim2(0, 1, 0, 1); Size = NewUdim2(1, -2, 1, -2);
		BackgroundColor3 = hex("24262D"); BorderSizePixel = 0; ZIndex = 4;
	});
	local SpecBody = self:CreateInstance("Frame", {
		Parent = SpecMid;
		Position = NewUdim2(0, 1, 0, 1); Size = NewUdim2(1, -2, 1, -2);
		BackgroundColor3 = FromRgb(255, 255, 255); BorderSizePixel = 0; ZIndex = 5;
	});
	self:CreateInstance("UIGradient", {
		Parent = SpecBody; Rotation = 90;
		Color = NewColorSequence(hex("131418"), hex("17181D"));
	});
	local SpecLabel = self:CreateInstance("TextLabel", {
		Parent = SpecBody;
		Size = NewUdim2(1, 0, 1, 0);
		BackgroundTransparency = 1;
		FontFace = Library.Fonts.title;
		Text = "Spectate";
		TextColor3 = FromRgb(255, 255, 255);
		TextSize = 9;
		TextXAlignment = Enum.TextXAlignment.Center;
		TextYAlignment = Enum.TextYAlignment.Center;
		ZIndex = 6;
	});
	self:AnimateButton(SpecBtn);

	local SearchBg = self:CreateInstance("Frame", {
		Name = "SearchBg"; Parent = section;
		Position = NewUdim2(0, 8, 0, 8);
		Size = NewUdim2(1, -(HeadshotSize + 24), 0, 16);
		BackgroundColor3 = hex("07080A"); BorderSizePixel = 0; ZIndex = 3;
	});
	local SearchMid = self:CreateInstance("Frame", {
		Parent = SearchBg;
		Position = NewUdim2(0, 1, 0, 1); Size = NewUdim2(1, -2, 1, -2);
		BackgroundColor3 = hex("24262D"); BorderSizePixel = 0; ZIndex = 3;
	});
	local SearchInner = self:CreateInstance("Frame", {
		Parent = SearchMid;
		Position = NewUdim2(0, 1, 0, 1); Size = NewUdim2(1, -2, 1, -2);
		BackgroundColor3 = FromRgb(255, 255, 255); BorderSizePixel = 0; ClipsDescendants = true; ZIndex = 3;
	});
	self:CreateInstance("UIGradient", {
		Parent = SearchInner; Rotation = 90;
		Color = NewColorSequence(hex("131418"), hex("17181D"));
	});
	local SearchBox = self:CreateInstance("TextBox", {
		Parent = SearchInner;
		Position = NewUdim2(0, 6, 0, 0); Size = NewUdim2(1, -12, 1, 0);
		BackgroundTransparency = 1; BorderSizePixel = 0;
		FontFace = Library.Fonts.title;
		Text = ""; PlaceholderText = "Search...";
		PlaceholderColor3 = hex("8A8A92");
		TextColor3 = FromRgb(255, 255, 255);
		TextSize = 9;
		TextXAlignment = Enum.TextXAlignment.Left;
		TextYAlignment = Enum.TextYAlignment.Center;
		ClearTextOnFocus = false;
		ZIndex = 4;
	});

	local ListBg = self:CreateInstance("Frame", {
		Name = "ListBg"; Parent = section;
		Position = NewUdim2(0, 8, 0, 28);
		Size = NewUdim2(1, -(HeadshotSize + 24), 1, -36);
		BackgroundColor3 = hex("07080A"); BorderSizePixel = 0; ZIndex = 3;
	});
	local ListMid = self:CreateInstance("Frame", {
		Parent = ListBg;
		Position = NewUdim2(0, 1, 0, 1); Size = NewUdim2(1, -2, 1, -2);
		BackgroundColor3 = hex("24262D"); BorderSizePixel = 0; ZIndex = 3;
	});
	local ListInner = self:CreateInstance("Frame", {
		Parent = ListMid;
		Position = NewUdim2(0, 1, 0, 1); Size = NewUdim2(1, -2, 1, -2);
		BackgroundColor3 = FromRgb(255, 255, 255); BorderSizePixel = 0; ZIndex = 3;
	});
	self:CreateInstance("UIGradient", {
		Parent = ListInner; Rotation = 90;
		Color = NewColorSequence(hex("131418"), hex("17181D"));
	});
	local list = self:CreateInstance("ScrollingFrame", {
		Name = "List"; Parent = ListInner;
		Position = NewUdim2(0, 4, 0, 4); Size = NewUdim2(1, -8, 1, -8);
		BackgroundTransparency = 1; BorderSizePixel = 0;
		ScrollBarThickness = 2; ScrollBarImageColor3 = hex("98BCFF");
		CanvasSize = NewUdim2(0, 0, 0, 0);
		AutomaticCanvasSize = Enum.AutomaticSize.Y;
		ZIndex = 4;
	});
	self:CreateInstance("UIListLayout", {
		Parent = list;
		FillDirection = Enum.FillDirection.Vertical;
		SortOrder = Enum.SortOrder.LayoutOrder;
		Padding = NewUdim(0, 2);
	});

	local LibRef = self;
	local SelectedPlayer;
	local rows = {};

	local function ColorForTag(tag)
		local c = Library.PlayerTagColors[tag];
		return c or FromRgb(255, 255, 255);
	end;

	local function RefreshTagDisplay()
		if not SelectedPlayer or not SelectedPlayer.Parent then
			TagLabel.Text = "None"; TagLabel.TextColor3 = hex("8A8A92"); return;
		end;
		local tag = Library.PlayerTags[SelectedPlayer.Name] or "None";
		TagLabel.Text = tag;
		TagLabel.TextColor3 = (tag == "None") and hex("8A8A92") or ColorForTag(tag);
	end;

	local function RebuildHeadshot(plr)
		if not plr then headshot.Image = ""; return end;
		headshot.Image = "rbxthumb://type=AvatarHeadShot&id=" .. tostring(plr.UserId) .. "&w=150&h=150";
	end;

	local refresh;
	local RowColorTween = NewTweenInfo(0.15, Enum.EasingStyle.Quad, Enum.EasingDirection.Out);
	local function RowTargetColor(entry)
		local tag = Library.PlayerTags[entry.plr.Name] or "None";
		if tag ~= "None" then return ColorForTag(tag) end;
		if SelectedPlayer == entry.plr then return Library.AccentColor or hex("98BCFF") end;
		return FromRgb(220, 220, 220);
	end;
	local function UpdateRowColors()
		for _, entry in rows do
			if entry.label and entry.label.Parent then
				local lbl = entry.label;
				local EntryRef = entry;
				local tw = LibRef:Tween(lbl, RowColorTween, { TextColor3 = RowTargetColor(EntryRef) });
				tw:Play();
				tw.Completed:Once(function()
					if lbl and lbl.Parent then lbl.TextColor3 = RowTargetColor(EntryRef) end;
				end);
			end;
		end;
	end;
	local function SelectPlayer(plr)
		SelectedPlayer = plr;
		SelectedName.Text = plr and plr.Name or "";
		RebuildHeadshot(plr);
		RefreshTagDisplay();
		UpdateRowColors();
	end;

	function refresh()
		for _, entry in rows do
			if entry.row then entry.row:Destroy() end;
		end;
		table.clear(rows);
		local filter = string.lower(SearchBox.Text or "");
		local plist = PlayersService:GetPlayers();
		table.sort(plist, function(a, b) return a.Name:lower() < b.Name:lower() end);
		for i, plr in plist do
			if filter == "" or string.find(string.lower(plr.Name), filter, 1, true) then
				local suffix = (plr == LocalPlayer) and " (you)" or "";
				local row = LibRef:CreateInstance("TextButton", {
					Parent = list;
					Size = NewUdim2(1, 0, 0, 12);
					BackgroundTransparency = 1; BorderSizePixel = 0;
					AutoButtonColor = false; Text = "";
					LayoutOrder = i; ZIndex = 4;
				});
				local lbl = LibRef:CreateInstance("TextLabel", {
					Parent = row;
					Size = NewUdim2(1, 0, 1, 0);
					BackgroundTransparency = 1;
					FontFace = Library.Fonts.title;
					Text = plr.Name .. suffix;
					TextSize = 9;
					TextXAlignment = Enum.TextXAlignment.Center;
					TextYAlignment = Enum.TextYAlignment.Center;
					ZIndex = 5;
				});
				local entry = { row = row, label = lbl, plr = plr };
				lbl.TextColor3 = RowTargetColor(entry);
				LibRef:Connection(row.MouseButton1Click, function() SelectPlayer(plr) end);
				insert(rows, entry);
			end;
		end;
	end;

	local TagOptions = { "None", "Enemy", "Friend", "Caution" };
	local TagPopup;
	local TagRowsData = {};
	local TagOpen = false;

	local function RefreshTagOptionColors()
		local cur = (SelectedPlayer and Library.PlayerTags[SelectedPlayer.Name]) or "None";
		for _, entry in TagRowsData do
			if entry.hovered then
				entry.label.TextColor3 = FromRgb(255, 255, 255);
			else
				local IsSel = entry.value == cur;
				if IsSel then
					entry.label.TextColor3 = (entry.value == "None") and hex("6E8CC8") or ColorForTag(entry.value);
				else
					entry.label.TextColor3 = (entry.value == "None") and hex("B4B4B4") or ColorForTag(entry.value);
				end;
			end;
		end;
	end;

	local TAG_PADDING_TOP = 8;
	local TAG_PADDING_BOTTOM = 1;
	local function TagPopupFullHeight()
		return #TagOptions * 14 + TAG_PADDING_TOP + TAG_PADDING_BOTTOM;
	end;
	local function PositionTagPopup()
		if not TagPopup then return end;
		local tp = TagBg.AbsolutePosition;
		local ts = TagBg.AbsoluteSize;
		local px, py, sc = Library:GuiPoint(gui, tp.X, tp.Y + ts.Y + 2);
		TagPopup.Position = NewUdim2(0, px, 0, py);
		TagPopup.Size = FromOffset(ts.X / sc, TagPopupFullHeight());
	end;

	local TagAnimTween;
	local TAG_ANIM = NewTweenInfo(0.15, Enum.EasingStyle.Quad, Enum.EasingDirection.Out);
	local function CloseTag()
		if not TagOpen then return end;
		TagOpen = false; TagArrow.Text = "v";
		if not TagPopup then return end;
		if TagAnimTween then TagAnimTween:Cancel() end;
		local ts = TagBg.AbsoluteSize;
		local _, _, sc = Library:GuiPoint(gui, 0, 0);
		TagAnimTween = TweenService:Create(TagPopup, TAG_ANIM, { Size = FromOffset(ts.X / sc, 0) });
		TagAnimTween:Play();
		TagAnimTween.Completed:Connect(function()
			if not TagOpen then TagPopup.Visible = false end;
		end);
	end;

	local function BuildTagPopup()
		TagPopup = LibRef:CreateInstance("Frame", {
			Name = "TagPopup"; Parent = gui;
			BackgroundColor3 = hex("07080A"); BorderSizePixel = 0;
			ClipsDescendants = true;
			Active = true;
			Visible = false; ZIndex = 500;
		});
		local TpMid = LibRef:CreateInstance("Frame", {
			Parent = TagPopup;
			Position = NewUdim2(0, 1, 0, 1); Size = NewUdim2(1, -2, 1, -2);
			BackgroundColor3 = hex("24262D"); BorderSizePixel = 0; ZIndex = 501;
		});
		local TpInner = LibRef:CreateInstance("Frame", {
			Parent = TpMid;
			Position = NewUdim2(0, 1, 0, 1); Size = NewUdim2(1, -2, 1, -2);
			BackgroundColor3 = FromRgb(255, 255, 255); BorderSizePixel = 0; Active = true; ZIndex = 502;
		});
		LibRef:CreateInstance("UIGradient", {
			Parent = TpInner; Rotation = 90;
			Color = NewColorSequence(hex("131418"), hex("17181D"));
		});
		local pl = LibRef:CreateInstance("Frame", {
			Parent = TpInner;
			Size = NewUdim2(1, 0, 1, 0); BackgroundTransparency = 1; ZIndex = 503;
		});
		LibRef:CreateInstance("UIPadding", {
			Parent = pl;
			PaddingTop = NewUdim(0, TAG_PADDING_TOP); PaddingBottom = NewUdim(0, TAG_PADDING_BOTTOM);
		});
		LibRef:CreateInstance("UIListLayout", {
			Parent = pl;
			FillDirection = Enum.FillDirection.Vertical;
			SortOrder = Enum.SortOrder.LayoutOrder;
		});
		for i, opt in TagOptions do
			local r = LibRef:CreateInstance("TextButton", {
				Parent = pl;
				Size = NewUdim2(1, 0, 0, 14);
				BackgroundTransparency = 1; BorderSizePixel = 0;
				AutoButtonColor = false; Text = "";
				LayoutOrder = i; ZIndex = 504;
			});
			local base = (opt == "None") and hex("B4B4B4") or ColorForTag(opt);
			local lbl = LibRef:CreateInstance("TextLabel", {
				Parent = r;
				Position = NewUdim2(0, 8, 0, 0); Size = NewUdim2(1, -16, 1, 0);
				BackgroundTransparency = 1;
				FontFace = Library.Fonts.title;
				Text = opt; TextColor3 = base;
				TextSize = 9;
				TextXAlignment = Enum.TextXAlignment.Left;
				TextYAlignment = Enum.TextYAlignment.Center;
				ZIndex = 505;
			});
			local entry = { button = r, label = lbl, value = opt, hovered = false };
			insert(TagRowsData, entry);
			LibRef:Connection(r.MouseEnter, function() entry.hovered = true; RefreshTagOptionColors() end);
			LibRef:Connection(r.MouseLeave, function() entry.hovered = false; RefreshTagOptionColors() end);
			LibRef:Connection(r.MouseButton1Click, function()
				if SelectedPlayer then
					if opt == "None" then
						Library.PlayerTags[SelectedPlayer.Name] = nil;
					else
						Library.PlayerTags[SelectedPlayer.Name] = opt;
					end;
				end;
				CloseTag(); RefreshTagDisplay(); UpdateRowColors();
			end);
		end;
	end;

	local function OpenTag()
		if TagOpen then return end;
		if not SelectedPlayer then return end;
		if not TagPopup then BuildTagPopup() end;
		TagOpen = true; TagArrow.Text = "^";
		RefreshTagOptionColors();
		local tp = TagBg.AbsolutePosition;
		local ts = TagBg.AbsoluteSize;
		local px, py, sc = Library:GuiPoint(gui, tp.X, tp.Y + ts.Y + 2);
		TagPopup.Position = NewUdim2(0, px, 0, py);
		TagPopup.Size = FromOffset(ts.X / sc, 0);
		TagPopup.Visible = true;
		if TagAnimTween then TagAnimTween:Cancel() end;
		TagAnimTween = TweenService:Create(TagPopup, TAG_ANIM, { Size = FromOffset(ts.X / sc, TagPopupFullHeight()) });
		TagAnimTween:Play();
	end;

	LibRef:Connection(TagHit.MouseButton1Click, function()
		if TagOpen then CloseTag() else OpenTag() end;
	end);
	LibRef:Connection(UserInputService.InputBegan, function(input)
		if not TagOpen then return end;
		if input.UserInputType ~= Enum.UserInputType.MouseButton1 and input.UserInputType ~= Enum.UserInputType.Touch then return end;
		local mx, my = LibRef:MousePoint(gui, input);
		if not LibRef:PointInObject(TagPopup, mx, my, 2) and not LibRef:PointInObject(TagBg, mx, my, 2) then CloseTag() end;
	end);

	local spectating;
	local function StopSpectate()
		spectating = nil;
		local cam = WorkspaceService.CurrentCamera;
		local hum = LocalPlayer and LocalPlayer.Character and LocalPlayer.Character:FindFirstChildOfClass("Humanoid");
		if cam and hum then cam.CameraSubject = hum end;
		SpecLabel.Text = "Spectate";
	end;
	LibRef:Connection(SpecBtn.MouseButton1Click, function()
		if spectating then StopSpectate(); return end;
		if not SelectedPlayer or SelectedPlayer == LocalPlayer then return end;
		local cam = WorkspaceService.CurrentCamera;
		if not cam then return end;
		local tc = SelectedPlayer.Character;
		local hum = tc and tc:FindFirstChildOfClass("Humanoid");
		if hum then
			cam.CameraSubject = hum;
			spectating = SelectedPlayer;
			SpecLabel.Text = "Unspectate";
		end;
	end);

	self:Connection(SearchBox:GetPropertyChangedSignal("Text"), refresh);
	self:Connection(PlayersService.PlayerAdded, refresh);
	self:Connection(PlayersService.PlayerRemoving, function(p)
		if spectating == p then StopSpectate() end;
		if SelectedPlayer == p then SelectPlayer(nil) end;
		task.defer(refresh);
	end);

	refresh();
	if LocalPlayer then SelectPlayer(LocalPlayer) end;

	self:Draggable(outer, header);

	local panel = { Gui = gui, Outer = outer, Refresh = refresh };
	function panel:SetVisible(on) Library:SetWidgetVisible(self, on) end;
	function panel:Destroy()
		if self.Gui and self.Gui.Parent then self.Gui:Destroy() end;
		if Library.CurrentPlayerList == panel then Library.CurrentPlayerList = nil end;
	end;

	self.CurrentPlayerList = panel;
	self:TrackWidget(panel, "PlayerList");
	return panel;
end;

--// Keybind list
function Library:KeybindList(opts)
	opts = typeof(opts) == "table" and opts or {};

	if typeof(self.CurrentKeybindList) == "table" and typeof(self.CurrentKeybindList.Gui) == "Instance" and self.CurrentKeybindList.Gui.Parent then
		self.CurrentKeybindList.Gui:Destroy();
	end;
	self.CurrentKeybindList = nil;

	local w = tonumber(opts.width) or 200;
	local RowH = 14;
	local RowPad = 2;
	local function HeightFor(n)
		if n == 0 then return 0 end;
		return n * RowH + MathMax(0, n - 1) * RowPad + 38;
	end;

	local VpSize = camera.ViewportSize;
	local UiScale = self:ComputeUIScale();
	local DefaultX = MathClamp(tonumber(opts.x) or 1490, 0, MathMax(0, VpSize.X / UiScale - w));
	local DefaultY = MathClamp(tonumber(opts.y) or 70, 0, MathMax(0, VpSize.Y / UiScale - 250));
	local pos = opts.position or NewUdim2(0, DefaultX, 0, DefaultY);

	local gui = self:CreateInstance("ScreenGui", {
		Name = "\0";
		Parent = (gethui and gethui()) or CoreGui;
		Enabled = false;
		DisplayOrder = self.WidgetDisplayOrder or 1002;
		IgnoreGuiInset = true;
		ResetOnSpawn = false;
		ZIndexBehavior = Enum.ZIndexBehavior.Global;
	});
	self:ApplyScale(gui);

	local outer = self:CreateInstance("Frame", {
		Name = "Outer"; Parent = gui;
		Position = pos; Size = FromOffset(w, 0);
		BackgroundColor3 = hex("07080A"); BorderSizePixel = 0; Active = true;
		ClipsDescendants = true;
	});
	self:CreateInstance("ImageLabel", {
		Name = "Glow"; Parent = outer;
		AnchorPoint = NewVector2(0.5, 0.5);
		Position = NewUdim2(0.5, 0, 0.5, 0);
		Size = NewUdim2(1, 30, 1, 30);
		BackgroundTransparency = 1;
		Image = "rbxassetid://18245826428";
		ImageColor3 = hex("98BCFF");
		ImageTransparency = 0.86;
		ScaleType = Enum.ScaleType.Slice;
		SliceCenter = RectNew(21, 21, 79, 79);
		ZIndex = -1;
	});
	local inner = self:CreateInstance("Frame", {
		Name = "Inner"; Parent = outer;
		Position = NewUdim2(0, 1, 0, 1); Size = NewUdim2(1, -2, 1, -2);
		BackgroundColor3 = hex("24262D"); BorderSizePixel = 0;
	});
	local main = self:CreateInstance("Frame", {
		Name = "Main"; Parent = inner;
		Position = NewUdim2(0, 1, 0, 1); Size = NewUdim2(1, -2, 1, -2);
		BackgroundColor3 = FromRgb(255, 255, 255); BorderSizePixel = 0;
	});
	self:CreateInstance("UIGradient", {
		Parent = main; Rotation = 90;
		Color = NewColorSequence(hex("131418"), hex("17181D"));
	});
	self:CreateInstance("Frame", {
		Parent = main; Position = NewUdim2(0, 0, 0, 0); Size = NewUdim2(1, 0, 0, 1);
		BackgroundColor3 = hex("98BCFF"); BorderSizePixel = 0; ZIndex = 2;
	});
	self:CreateInstance("Frame", {
		Parent = main; Position = NewUdim2(0, 0, 0, 1); Size = NewUdim2(1, 0, 0, 1);
		BackgroundColor3 = hex("6E8CC8"); BorderSizePixel = 0; ZIndex = 2;
	});

	local header = self:CreateInstance("Frame", {
		Name = "Header"; Parent = main;
		Position = NewUdim2(0, 0, 0, 0); Size = NewUdim2(1, 0, 0, 22);
		BackgroundTransparency = 1; Active = true; ZIndex = 4;
	});
	local HeaderTitle = self:CreateInstance("TextLabel", {
		Parent = header;
		Position = NewUdim2(0, 10, 0, 5); Size = NewUdim2(1, -20, 0, 14);
		BackgroundTransparency = 1;
		FontFace = Library.Fonts.title;
		Text = tostring(opts.title or "Keybinds");
		TextColor3 = FromRgb(255, 255, 255);
		TextSize = 9;
		TextXAlignment = Enum.TextXAlignment.Left;
		TextYAlignment = Enum.TextYAlignment.Top;
		ZIndex = 5;
	});
	self:CreateInstance("UIGradient", {
		Parent = HeaderTitle;
		Color = NewColorSequence(hex("98BCFF"), hex("6E8CC8"));
		Rotation = 90;
	});

	local section = self:CreateInstance("Frame", {
		Parent = main;
		Position = NewUdim2(0, 6, 0, 22);
		Size = NewUdim2(1, -12, 1, -28);
		BackgroundTransparency = 1; BorderSizePixel = 0; ZIndex = 2;
	});
	local RowsHolder = self:CreateInstance("Frame", {
		Parent = section;
		Position = NewUdim2(0, 8, 0, 1); Size = NewUdim2(1, -16, 1, -12);
		BackgroundTransparency = 1; ZIndex = 3;
	});
	self:CreateInstance("UIListLayout", {
		Parent = RowsHolder;
		FillDirection = Enum.FillDirection.Vertical;
		SortOrder = Enum.SortOrder.LayoutOrder;
		Padding = NewUdim(0, RowPad);
	});

	local LibRef = self;
	local kb = {
		Gui = gui; Outer = outer;
		Entries = {}; OrderedIds = {};
		ManualVisible = true;
		LastVisibleCount = 0;
	};
	local ListTween = NewTweenInfo(0.16, Enum.EasingStyle.Quad, Enum.EasingDirection.Out);

	local function KeyText(k)
		if k == nil then return "-" end;
		local n = Library.KeyNames[k];
		if n then return n end;
		local raw = tostring(k);
		return (raw:gsub("Enum.KeyCode.", "")):gsub("Enum.UserInputType.", "");
	end;

	function kb:Refresh()
		for _, c in self.RowsHolder and self.RowsHolder:GetChildren() or RowsHolder:GetChildren() do
			if c:IsA("Frame") and c.Name ~= "layout" then c:Destroy() end;
		end;
		local VisibleCount = 0;
		local ActiveIds = {};
		for _, id in self.OrderedIds do
			local entry = self.Entries[id];
			if entry and entry.active and entry.key ~= nil and entry.show ~= false then
				insert(ActiveIds, id);
			end;
		end;
		if not self.ManualVisible or #ActiveIds == 0 then
			self.LastVisibleCount = 0;
			local Tween = LibRef:Tween(outer, ListTween, { Size = FromOffset(w, 0) });
			Tween:Play();
			Tween.Completed:Once(function()
				if self.LastVisibleCount == 0 then
					gui.Enabled = false;
					if LibRef.CurrentDock and LibRef.CurrentDock.RefreshBtns then LibRef.CurrentDock:RefreshBtns() end;
				end;
			end);
			return;
		end;
		gui.Enabled = true;
		if LibRef.CurrentDock and LibRef.CurrentDock.RefreshBtns then LibRef.CurrentDock:RefreshBtns() end;
		for _, id in ActiveIds do
			local entry = self.Entries[id];
			if entry and entry.active and entry.key ~= nil and entry.show ~= false then
				local row = LibRef:CreateInstance("Frame", {
					Parent = RowsHolder;
					Size = NewUdim2(1, 0, 0, RowH);
					BackgroundTransparency = 1; BorderSizePixel = 0;
					LayoutOrder = VisibleCount + 1; ZIndex = 4;
				});
				LibRef:CreateInstance("TextLabel", {
					Parent = row;
					Size = NewUdim2(0.6, 0, 1, 0);
					BackgroundTransparency = 1;
					FontFace = Library.Fonts.title;
					Text = tostring(entry.name or "");
					TextColor3 = FromRgb(255, 255, 255);
					TextSize = 9;
					TextXAlignment = Enum.TextXAlignment.Left;
					TextYAlignment = Enum.TextYAlignment.Center;
					ZIndex = 5;
				});
				local suffix = entry.mode and (" (" .. tostring(entry.mode) .. ")") or "";
				LibRef:CreateInstance("TextLabel", {
					Parent = row;
					AnchorPoint = NewVector2(1, 0);
					Position = NewUdim2(1, 0, 0, 0);
					Size = NewUdim2(0.4, 0, 1, 0);
					BackgroundTransparency = 1;
					FontFace = Library.Fonts.title;
					Text = KeyText(entry.key) .. suffix;
					TextColor3 = hex("6E8CC8");
					TextSize = 9;
					TextXAlignment = Enum.TextXAlignment.Right;
					TextYAlignment = Enum.TextYAlignment.Center;
					ZIndex = 5;
				});
				VisibleCount = VisibleCount + 1;
			end;
		end;
		self.LastVisibleCount = VisibleCount;
		LibRef:Tween(outer, ListTween, { Size = FromOffset(w, HeightFor(VisibleCount)) }):Play();
	end;

	function kb:Register(id, name, key, active, mode, show)
		if not self.Entries[id] then insert(self.OrderedIds, id) end;
		self.Entries[id] = { name = name or "keybind"; key = key; active = active == true; mode = mode; show = show ~= false };
		self:Refresh();
	end;

	function kb:Update(id, name, key, active, mode, show)
		local entry = self.Entries[id];
		if not entry then self:Register(id, name, key, active, mode, show); return end;
		if name ~= nil then entry.name = name end;
		if key == false then entry.key = nil
		elseif key ~= nil then entry.key = key end;
		if active ~= nil then entry.active = active == true end;
		if mode ~= nil then entry.mode = mode end;
		if show ~= nil then entry.show = show == true end;
		self:Refresh();
	end;

	function kb:Unregister(id)
		if not self.Entries[id] then return end;
		self.Entries[id] = nil;
		for i, eid in self.OrderedIds do
			if eid == id then table.remove(self.OrderedIds, i); break end;
		end;
		self:Refresh();
	end;

	function kb:SetVisible(on)
		self.ManualVisible = on == true;
		if self.ManualVisible then
			self:Refresh();
		else
			local Tween = LibRef:Tween(outer, ListTween, { Size = FromOffset(w, 0) });
			Tween:Play();
			Tween.Completed:Once(function()
				if not self.ManualVisible then
					gui.Enabled = false;
					if LibRef.CurrentDock and LibRef.CurrentDock.RefreshBtns then LibRef.CurrentDock:RefreshBtns() end;
				end;
			end);
		end;
		Library:SaveWidgetState(self);
	end;
	function kb:Destroy()
		if self.Gui and self.Gui.Parent then self.Gui:Destroy() end;
		if Library.CurrentKeybindList == self then Library.CurrentKeybindList = nil end;
	end;

	self.CurrentKeybindList = kb;
	self:TrackWidget(kb, "KeybindList");

	for _, entry in self.KeybindRegistry do
		kb:Register(entry.Id, entry.Name, entry.Key, entry.Active == true, entry.Mode, entry.ShowInList ~= false);
	end;

	kb:Refresh();
	self:Draggable(outer, header);
	return kb;
end;

--// Notifications
Library.Notifications = Library.Notifications or {};

function Library:NotifAnchorOffset()
	local f = self.NotifAnchorFrame;
	if f and f.Parent then
		local p = f.Position;
		return p.X.Offset, p.Y.Offset;
	end;
	return 20, 50;
end;

function Library:EnsureNotifAnchor()
	if self.NotifAnchorFrame and self.NotifAnchorFrame.Parent then return self.NotifAnchorFrame end;
	if not self.NotifAnchorGui or not self.NotifAnchorGui.Parent then
		self.NotifAnchorGui = self:CreateInstance("ScreenGui", {
			Name = "\0";
			Parent = (gethui and gethui()) or CoreGui;
			Enabled = true;
			DisplayOrder = 1099;
			IgnoreGuiInset = true;
			ResetOnSpawn = false;
			ZIndexBehavior = Enum.ZIndexBehavior.Global;
		});
	end;

	local Outline = self:CreateInstance("Frame", {
		Name = "NotifAnchor";
		Parent = self.NotifAnchorGui;
		AnchorPoint = NewVector2(0, 0);
		Position = NewUdim2(0, 20, 0, 50);
		AutomaticSize = Enum.AutomaticSize.XY;
		BackgroundColor3 = FromRgb(52, 52, 52);
		BorderSizePixel = 0;
		Active = true;
		Visible = false;
		ZIndex = 1100;
	});
	self:CreateInstance("UIPadding", {
		Parent = Outline;
		PaddingBottom = NewUdim(0, 1);
		PaddingRight = NewUdim(0, 1);
	});
	local Inline = self:CreateInstance("Frame", {
		Parent = Outline;
		Position = NewUdim2(0, 1, 0, 1);
		AutomaticSize = Enum.AutomaticSize.XY;
		Size = NewUdim2(0, 0, 0, 0);
		BackgroundColor3 = Library.WindowBgColor or hex("101114");
		BorderSizePixel = 0;
		ZIndex = 1101;
	});
	self:CreateInstance("UIPadding", {
		Parent = Inline;
		PaddingTop = NewUdim(0, 7);
		PaddingBottom = NewUdim(0, 6);
		PaddingLeft = NewUdim(0, 4);
		PaddingRight = NewUdim(0, 8);
	});
	self:CreateInstance("TextLabel", {
		Parent = Inline;
		AutomaticSize = Enum.AutomaticSize.XY;
		Size = NewUdim2(0, 0, 0, 0);
		Position = NewUdim2(0, 4, 0, -2);
		BackgroundTransparency = 1;
		FontFace = Library.Fonts.title;
		Text = "Notifications";
		TextColor3 = FromRgb(255, 255, 255);
		TextSize = 9;
		TextXAlignment = Enum.TextXAlignment.Left;
		ZIndex = 1102;
	});
	self:CreateInstance("Frame", {
		Name = "AccentSide";
		Parent = Outline;
		Position = NewUdim2(0, 1, 0, 1);
		Size = NewUdim2(0, 1, 1, -1);
		BackgroundColor3 = hex("98BCFF");
		BorderSizePixel = 0;
		ZIndex = 1103;
	});
	self:CreateInstance("Frame", {
		Name = "AccentLine";
		Parent = Outline;
		AnchorPoint = NewVector2(0, 1);
		Position = NewUdim2(0, 2, 1, -1);
		Size = NewUdim2(1, -1, 0, 1);
		BackgroundColor3 = hex("98BCFF");
		BorderSizePixel = 0;
		ZIndex = 1103;
	});

	self.NotifAnchorFrame = Outline;

	self:Draggable(Outline, Outline);
	self:TrackWidget({ Frame = Outline; Gui = self.NotifAnchorGui; Name = "NotifAnchor"; Key = "NotifAnchor"; Visible = true; }, "NotifAnchor");
	return Outline;
end;

function Library:SetNotifAnchorVisible(on)
	self:EnsureNotifAnchor();
	if not on and self.Flags and self.Flags["appearance.KeepDockOpen"] == true then
		on = true;
	end;
	if self.NotifAnchorFrame then
		self.NotifAnchorFrame.Visible = on == true;
	end;
end;

function Library:EnsureArrayList()
	if self.ArrayListGui and self.ArrayListGui.Parent then return self.ArrayListGui end;
	local gui = self:CreateInstance("ScreenGui", {
		Name = "\0";
		Parent = (gethui and gethui()) or CoreGui;
		Enabled = false;
		DisplayOrder = 1098;
		IgnoreGuiInset = true;
		ResetOnSpawn = false;
		ZIndexBehavior = Enum.ZIndexBehavior.Global;
	});
	self.ArrayListGui = gui;
	self.ArrayItems = {};

	local SavedSide = Library.Flags["appearance.ArraySide"];
	if SavedSide == "Left" or SavedSide == "Right" then self.ArraySide = SavedSide end;
	if self.ArraySide ~= "Left" then self.ArraySide = "Right" end;
	self.ArrayY = tonumber(Library.Flags["appearance.ArrayY"]) or self.ArrayY or 0;

	local White = FromRgb(255, 255, 255);
	local function ShineSeq()
		local TextBase = Library.AccentColor or hex("98BCFF");
		return NewColorSequence({
			NewColorSequenceKeypoint(0, TextBase);
			NewColorSequenceKeypoint(0.42, TextBase);
			NewColorSequenceKeypoint(0.5, White);
			NewColorSequenceKeypoint(0.58, TextBase);
			NewColorSequenceKeypoint(1, TextBase);
		});
	end;
	Library:OnAccentChange(function()
		if self.ArrayItems then
			for _, item in pairs(self.ArrayItems) do
				if item and item.Grad then item.Grad.Color = ShineSeq() end;
			end;
		end;
	end);

	local accentLine = self:CreateInstance("Frame", {
		Name = "AccentLine"; Parent = gui;
		AnchorPoint = NewVector2(1, 0);
		Position = NewUdim2(1, 0, 0, self.ArrayY);
		Size = NewUdim2(0, 2, 0, 0);
		BackgroundColor3 = Library.AccentColor or hex("98BCFF");
		BorderSizePixel = 0; ZIndex = 3;
	});
	self:CreateInstance("UIGradient", {
		Parent = accentLine; Rotation = 90;
		Color = NewColorSequence(Library.AccentColor or hex("98BCFF"), Library.ShadeColor or hex("6E8CC8"));
	});
	self.ArrayAccentLine = accentLine;

	local RowTween = NewTweenInfo(0.12, Enum.EasingStyle.Quad, Enum.EasingDirection.Out);

	local function SortedList()
		local list = {};
		for _, item in self.ArrayItems do list[#list + 1] = item end;
		table.sort(list, function(a, b) return a.Label.TextBounds.X > b.Label.TextBounds.X end);
		return list;
	end;

	local function Layout(animated)
		local right = self.ArraySide ~= "Left";
		local ap = right and NewVector2(1, 0) or NewVector2(0, 0);
		local list = SortedList();
		for i = 1, #list do
			local item = list[i];
			local lbl = item.Label;
			local y = self.ArrayY + (i - 1) * 14;
			lbl.AnchorPoint = ap;
			lbl.TextXAlignment = right and Enum.TextXAlignment.Right or Enum.TextXAlignment.Left;
			local pos = right and NewUdim2(1, -2, 0, y) or NewUdim2(0, 2, 0, y);
			if animated then
				if item.Y ~= y or item.Side ~= self.ArraySide then
					item.Y = y; item.Side = self.ArraySide;
					self:Tween(lbl, RowTween, { Position = pos }):Play();
				end;
			else
				item.Y = y; item.Side = self.ArraySide;
				lbl.Position = pos;
			end;
		end;
		local total = #list > 0 and (#list * 14) or 0;
		accentLine.AnchorPoint = ap;
		accentLine.Position = right and NewUdim2(1, 0, 0, self.ArrayY) or NewUdim2(0, 0, 0, self.ArrayY);
		accentLine.Size = NewUdim2(0, 2, 0, total);
	end;

	local Dragging, GrabDY;
	local DragHandler;
	DragHandler = function(input)
		if not Dragging then return end;
		local vp = camera.ViewportSize;
		local contentH = 0;
		for _ in self.ArrayItems do contentH = contentH + 14 end;
		self.ArrayY = MathClamp(input.Position.Y - GrabDY, 0, MathMax(0, vp.Y - contentH));
		if self.ArrayY < 12 then self.ArrayY = 0 end;
		self.ArraySide = (input.Position.X < vp.X / 2) and "Left" or "Right";
		Layout(false);
	end;
	local function StartDrag(input)
		if Dragging then return end;
		Dragging = true;
		GrabDY = input.Position.Y - self.ArrayY;
		self:RegisterDragger(DragHandler);
	end;
	local function EndDrag()
		if not Dragging then return end;
		Dragging = false;
		self:UnregisterDragger(DragHandler);
		Library.Flags["appearance.ArraySide"] = self.ArraySide;
		Library.Flags["appearance.ArrayY"] = self.ArrayY;
		Layout(true);
	end;
	self:Connection(UserInputService.InputEnded, function(input)
		if input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.Touch then
			EndDrag();
		end;
	end);

	local function MakeRow(Name)
		self.ArrayPhaseCtr = (self.ArrayPhaseCtr or 0) + 1;
		local PhaseOff = (self.ArrayPhaseCtr * 0.137) % 1;
		local right = self.ArraySide ~= "Left";

		local lbl = self:CreateInstance("TextLabel", {
			Name = Name; Parent = gui;
			AnchorPoint = right and NewVector2(1, 0) or NewVector2(0, 0);
			Position = right and NewUdim2(1, -2, 0, self.ArrayY) or NewUdim2(0, 2, 0, self.ArrayY);
			Size = NewUdim2(0, 0, 0, 14);
			AutomaticSize = Enum.AutomaticSize.X;
			BackgroundColor3 = FromRgb(0, 0, 0);
			BackgroundTransparency = 0.15;
			BorderSizePixel = 0;
			Active = true;
			FontFace = Library.Fonts.title;
			Text = Name;
			TextColor3 = White;
			TextSize = 9;
			TextXAlignment = right and Enum.TextXAlignment.Right or Enum.TextXAlignment.Left;
			TextYAlignment = Enum.TextYAlignment.Center;
			ZIndex = 2;
		});
		self:CreateInstance("UIPadding", { Parent = lbl; PaddingLeft = NewUdim(0, 6); PaddingRight = NewUdim(0, 6); });
		self:CreateInstance("UIStroke", { Parent = lbl; Thickness = 1; Color = FromRgb(0, 0, 0); Transparency = 0.15; });
		local grad = self:CreateInstance("UIGradient", { Parent = lbl; Color = ShineSeq(); Offset = NewVector2(-1.2, 0); });
		local shineTween = self:Tween(grad, NewTweenInfo(1.6, Enum.EasingStyle.Linear, Enum.EasingDirection.Out, -1, false, PhaseOff * 1.6), { Offset = NewVector2(1.2, 0) });
		shineTween:Play();

		local item = { Label = lbl, Grad = grad, ShineTween = shineTween, Y = -1, Side = nil };
		self:Connection(lbl.InputBegan, function(input)
			if input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.Touch then
				StartDrag(input);
			end;
		end);
		return item;
	end;

	Library:RegisterFlag("appearance.ArraySide", self.ArraySide, function(v)
		self.ArraySide = (v == "Left") and "Left" or "Right";
		if self.ArrayItems then Layout(false) end;
	end);
	Library:RegisterFlag("appearance.ArrayY", self.ArrayY, function(v)
		self.ArrayY = tonumber(v) or 0;
		if self.ArrayItems then Layout(false) end;
	end);

	local DiffAcc = 0;
	self:Connection(RunService.RenderStepped, function(dt)
		if not gui.Enabled then return end;
		DiffAcc = DiffAcc + dt;
		if DiffAcc < 0.1 then return end;
		DiffAcc = 0;

		local reg = Library.ToggleRegistry;
		local enabled = {};
		if reg then
			for i = 1, #reg do
				local t = reg[i];
				if Library.Flags[t.Flag] == true then
					enabled[tostring(t.Name)] = true;
				end;
			end;
		end;

		for name, item in self.ArrayItems do
			if not enabled[name] then
				if item.ShineTween then item.ShineTween:Cancel() end;
				if item.Label and item.Label.Parent then item.Label:Destroy() end;
				self.ArrayItems[name] = nil;
			end;
		end;
		for name in enabled do
			if not self.ArrayItems[name] then
				self.ArrayItems[name] = MakeRow(name);
			end;
		end;

		if not Dragging then Layout(true) end;
	end);

	if self.OnAccentChange then
		self:OnAccentChange(function()
			local Accent = Library.AccentColor or hex("98BCFF");
			if accentLine then accentLine.BackgroundColor3 = Accent end;
		end);
	end;
	return gui;
end;

function Library:SetArrayListVisible(on)
	self:EnsureArrayList();
	if self.ArrayListGui then self.ArrayListGui.Enabled = on == true end;
end;

function Library:Notify(opts)
	if typeof(opts) ~= "table" then opts = { Text = tostring(opts) } end;
	local text = tostring(opts.Text or opts.text or opts.Name or opts.name or "");
	local lifetime = tonumber(opts.Lifetime or opts.lifetime) or 3;

	self:EnsureNotifAnchor();
	local AnchorX, AnchorY = self:NotifAnchorOffset();

	if not self.NotifGui or not self.NotifGui.Parent then
		self.NotifGui = self:CreateInstance("ScreenGui", {
			Name = "\0";
			Parent = (gethui and gethui()) or CoreGui;
			Enabled = true;
			DisplayOrder = 1100;
			IgnoreGuiInset = true;
			ResetOnSpawn = false;
			ZIndexBehavior = Enum.ZIndexBehavior.Global;
		});
	end;

	local Outline = self:CreateInstance("Frame", {
		Name = "Notif"; Parent = self.NotifGui;
		AnchorPoint = NewVector2(1, 0);
		Position = NewUdim2(0, AnchorX, 0, AnchorY);
		AutomaticSize = Enum.AutomaticSize.XY;
		BackgroundColor3 = FromRgb(52, 52, 52);
		BorderSizePixel = 0;
		ZIndex = 1100;
	});
	self:CreateInstance("UIPadding", {
		Parent = Outline;
		PaddingBottom = NewUdim(0, 1);
		PaddingRight = NewUdim(0, 1);
	});
	local Inline = self:CreateInstance("Frame", {
		Parent = Outline;
		Position = NewUdim2(0, 1, 0, 1);
		AutomaticSize = Enum.AutomaticSize.XY;
		Size = NewUdim2(0, 0, 0, 0);
		BackgroundColor3 = Library.WindowBgColor or hex("101114");
		BorderSizePixel = 0;
		ZIndex = 1101;
	});
	self:CreateInstance("UIPadding", {
		Parent = Inline;
		PaddingTop = NewUdim(0, 7);
		PaddingBottom = NewUdim(0, 6);
		PaddingLeft = NewUdim(0, 4);
		PaddingRight = NewUdim(0, 8);
	});
	local TextLbl = self:CreateInstance("TextLabel", {
		Parent = Inline;
		AutomaticSize = Enum.AutomaticSize.XY;
		Size = NewUdim2(0, 0, 0, 0);
		Position = NewUdim2(0, 4, 0, -2);
		BackgroundTransparency = 1;
		FontFace = Library.Fonts.title;
		Text = text;
		TextColor3 = FromRgb(255, 255, 255);
		TextSize = 9;
		TextXAlignment = Enum.TextXAlignment.Left;
		ZIndex = 1102;
	});
	local AccentSide = self:CreateInstance("Frame", {
		Parent = Outline;
		Position = NewUdim2(0, 1, 0, 1);
		Size = NewUdim2(0, 1, 1, -1);
		BackgroundColor3 = hex("98BCFF");
		BorderSizePixel = 0;
		ZIndex = 1103;
	});
	local AccentLine = self:CreateInstance("Frame", {
		Parent = Outline;
		AnchorPoint = NewVector2(0, 1);
		Position = NewUdim2(0, 2, 1, -1);
		Size = NewUdim2(1, -1, 0, 1);
		BackgroundColor3 = hex("98BCFF");
		BorderSizePixel = 0;
		ZIndex = 1103;
	});

	local Notif = { Outline = Outline; Text = text; Alive = true };
	insert(self.Notifications, Notif);

	local function Reflow()
		local ox, oy = self:NotifAnchorOffset();
		local y = oy;
		for _, n in self.Notifications do
			if n.Alive and n.Outline and n.Outline.Parent then
				self:Tween(n.Outline, NewTweenInfo(0.18, Enum.EasingStyle.Quad, Enum.EasingDirection.Out), {
					Position = NewUdim2(0, ox, 0, y);
				}):Play();
				y = y + n.Outline.AbsoluteSize.Y + 6;
			end;
		end;
	end;

	task.defer(function()
		local ox, oy = self:NotifAnchorOffset();
		Outline.AnchorPoint = NewVector2(1, 0);
		Outline.Position = NewUdim2(0, ox - 40, 0, oy);
		task.wait();
		self:Tween(Outline, NewTweenInfo(0.22, Enum.EasingStyle.Quint, Enum.EasingDirection.Out), {
			AnchorPoint = NewVector2(0, 0);
		}):Play();
		Reflow();
	end);

	self:Tween(AccentLine, NewTweenInfo(lifetime, Enum.EasingStyle.Linear), {
		Size = NewUdim2(0, 0, 0, 1);
	}):Play();

	task.delay(lifetime, function()
		Notif.Alive = false;
		for i, n in self.Notifications do
			if n == Notif then table.remove(self.Notifications, i); break end;
		end;
		self:Tween(Outline, NewTweenInfo(0.2, Enum.EasingStyle.Quad, Enum.EasingDirection.In), {
			AnchorPoint = NewVector2(1, 0);
		}):Play();
		for _, ch in Outline:GetDescendants() do
			if ch:IsA("TextLabel") then
				self:Tween(ch, NewTweenInfo(0.2), { TextTransparency = 1 }):Play();
			elseif ch:IsA("Frame") then
				self:Tween(ch, NewTweenInfo(0.2), { BackgroundTransparency = 1 }):Play();
			end;
		end;
		self:Tween(Outline, NewTweenInfo(0.2), { BackgroundTransparency = 1 }):Play();
		Reflow();
		task.wait(0.25);
		if Outline and Outline.Parent then Outline:Destroy() end;
	end);

	return Notif;
end;

--// Watermark
function Library:Watermark(opts)
	opts = typeof(opts) == "table" and opts or {};
	local segments = opts.Segments or opts.segments;
	if typeof(segments) ~= "table" then
		segments = { tostring(opts.Text or opts.text or opts.Name or opts.name or "") };
	end;

	if typeof(self.CurrentWatermark) == "table" and typeof(self.CurrentWatermark.Gui) == "Instance" and self.CurrentWatermark.Gui.Parent then
		self.CurrentWatermark.Gui:Destroy();
	end;
	self.CurrentWatermark = nil;

	local gui = self:CreateInstance("ScreenGui", {
		Name = "\0";
		Parent = (gethui and gethui()) or CoreGui;
		Enabled = true;
		DisplayOrder = 1000;
		IgnoreGuiInset = true;
		ResetOnSpawn = false;
		ZIndexBehavior = Enum.ZIndexBehavior.Global;
	});

	local MinW = tonumber(opts.MinWidth) or 0;
	local frame = self:CreateInstance("Frame", {
		Name = "Watermark"; Parent = gui;
		AnchorPoint = NewVector2(0.5, 0);
		Position = opts.position or NewUdim2(0.5, 0, 0, 27);
		Size = FromOffset(MathMax(MinW, 60), 22);
		BackgroundColor3 = hex("07080A"); BorderSizePixel = 0; Active = true;
	});
	local WmScale = self:CreateInstance("UIScale", {
		Parent = frame;
		Scale = 1;
	});
	local mid = self:CreateInstance("Frame", {
		Name = "Mid"; Parent = frame;
		Position = NewUdim2(0, 1, 0, 1); Size = NewUdim2(1, -2, 1, -2);
		BackgroundColor3 = hex("24262D"); BorderSizePixel = 0;
	});
	local body = self:CreateInstance("Frame", {
		Name = "Body"; Parent = mid;
		Position = NewUdim2(0, 1, 0, 1); Size = NewUdim2(1, -2, 1, -2);
		BackgroundColor3 = FromRgb(255, 255, 255); BorderSizePixel = 0;
	});
	self:CreateInstance("UIGradient", {
		Parent = body; Rotation = 90;
		Color = NewColorSequence(hex("131418"), hex("17181D"));
	});
	self:CreateInstance("ImageLabel", {
		Name = "Glow"; Parent = frame;
		AnchorPoint = NewVector2(0.5, 0.5);
		Position = NewUdim2(0.5, 0, 0.5, 0);
		Size = NewUdim2(1, 30, 1, 30);
		BackgroundTransparency = 1;
		Image = "rbxassetid://18245826428";
		ImageColor3 = hex("98BCFF");
		ImageTransparency = 0.86;
		ScaleType = Enum.ScaleType.Slice;
		SliceCenter = RectNew(21, 21, 79, 79);
		ZIndex = -1;
	});
	self:CreateInstance("Frame", {
		Parent = body; Position = NewUdim2(0, 0, 0, 0); Size = NewUdim2(1, 0, 0, 1);
		BackgroundColor3 = hex("98BCFF"); BorderSizePixel = 0; ZIndex = 2;
	});
	self:CreateInstance("Frame", {
		Parent = body; Position = NewUdim2(0, 0, 0, 1); Size = NewUdim2(1, 0, 0, 1);
		BackgroundColor3 = hex("6E8CC8"); BorderSizePixel = 0; ZIndex = 2;
	});

	local strip = self:CreateInstance("Frame", {
		Parent = body;
		BackgroundTransparency = 1;
		AnchorPoint = NewVector2(0.5, 0);
		Position = NewUdim2(0.5, 0, 0, 0);
		Size = NewUdim2(0, 0, 1, 0);
		AutomaticSize = Enum.AutomaticSize.X;
		ZIndex = 3;
	});
	self:CreateInstance("UIPadding", {
		Parent = strip;
		PaddingLeft = NewUdim(0, 4);
		PaddingRight = NewUdim(0, 4);
	});
	self:CreateInstance("UIListLayout", {
		Parent = strip;
		FillDirection = Enum.FillDirection.Horizontal;
		VerticalAlignment = Enum.VerticalAlignment.Center;
		SortOrder = Enum.SortOrder.LayoutOrder;
		Padding = NewUdim(0, 10);
	});

	local LibRef = self;
	local labels = {};
	local function MakeLabel(text, IsAccent, order)
		local lbl = LibRef:CreateInstance("TextLabel", {
			Parent = strip;
			AutomaticSize = Enum.AutomaticSize.X;
			Size = NewUdim2(0, 0, 1, 0);
			BackgroundTransparency = 1;
			FontFace = Library.Fonts.title;
			Text = tostring(text);
			TextColor3 = IsAccent and hex("98BCFF") or FromRgb(255, 255, 255);
			TextSize = 9;
			TextXAlignment = Enum.TextXAlignment.Center;
			TextYAlignment = Enum.TextYAlignment.Center;
			LayoutOrder = order;
			ZIndex = 4;
		});
		return lbl;
	end;
	local function MakeDiv(order)
		local wrap = LibRef:CreateInstance("Frame", {
			Parent = strip;
			BackgroundTransparency = 1;
			BorderSizePixel = 0;
			Size = NewUdim2(0, 1, 1, 0);
			LayoutOrder = order;
			ZIndex = 4;
		});
		LibRef:CreateInstance("Frame", {
			Parent = wrap;
			AnchorPoint = NewVector2(0, 0.5);
			Position = NewUdim2(0, 0, 0.5, 1);
			Size = NewUdim2(0, 1, 0, 12);
			BackgroundColor3 = hex("24262D");
			BorderSizePixel = 0;
			ZIndex = 4;
		});
	end;

	for i, seg in segments do
		if i > 1 then MakeDiv(i * 2 - 1) end;
		labels[i] = MakeLabel(seg, i == 1, i * 2);
	end;

	self:Draggable(frame);

	local wm = { Gui = gui; Frame = frame; Scale = WmScale; Labels = labels; Segments = segments; Visible = true };
	function wm:SetSegment(i, text)
		if self.Labels[i] then
			self.Segments[i] = tostring(text or "");
			self.Labels[i].Text = self.Segments[i];
		end;
	end;
	function wm:SetSegments(NewSegments)
		if typeof(NewSegments) ~= "table" then return end;
		for i, v in NewSegments do
			if self.Labels[i] then
				self.Segments[i] = tostring(v or "");
				self.Labels[i].Text = self.Segments[i];
			end;
		end;
	end;
	function wm:SetText(text)
		self:SetSegment(1, text);
	end;
	local WmTweenInfo = NewTweenInfo(0.14, Enum.EasingStyle.Quad, Enum.EasingDirection.Out);
	function wm:SetVisible(on)
		on = on == true;
		self.Visible = on;
		if on then
			gui.Enabled = true;
			WmScale.Scale = 0.96;
			Library:Tween(WmScale, WmTweenInfo, { Scale = 1 }):Play();
		else
			local Tween = Library:Tween(WmScale, WmTweenInfo, { Scale = 0.96 });
			Tween:Play();
			Tween.Completed:Once(function()
				if not self.Visible then gui.Enabled = false end;
			end);
		end;
		Library:SaveWidgetState(self);
	end;
	function wm:Destroy()
		if self.Gui and self.Gui.Parent then self.Gui:Destroy() end;
		if Library.CurrentWatermark == wm then Library.CurrentWatermark = nil end;
	end;

	local function UpdateFrameSize()
		if not strip or not strip.Parent then return end;
		local sx = strip.AbsoluteSize.X;
		if sx and sx > 0 then
			frame.Size = FromOffset(MathMax(MinW, sx + 8), 22);
		end;
	end;
	self:Connection(strip:GetPropertyChangedSignal("AbsoluteSize"), UpdateFrameSize);
	task.defer(UpdateFrameSize);

	self.CurrentWatermark = wm;
	self:TrackWidget(wm, "Watermark");
	return wm;
end;

--// Appearance / settings panel
function Library:Appearance(opts)
	opts = typeof(opts) == "table" and opts or {};

	if typeof(self.CurrentAppearance) == "table" and typeof(self.CurrentAppearance.Gui) == "Instance" and self.CurrentAppearance.Gui.Parent then
		self.CurrentAppearance.Gui:Destroy();
	end;
	self.CurrentAppearance = nil;

	local w = tonumber(opts.width) or 240;
	local h = tonumber(opts.height) or 330;
	local TitleText = tostring(opts.title or "Appearance");

	local VpSize = camera.ViewportSize;
	local UiScale = self:ComputeUIScale();
	local DefaultX = MathClamp(tonumber(opts.x) or 900, 0, MathMax(0, VpSize.X / UiScale - w));
	local DefaultY = MathClamp(tonumber(opts.y) or 70, 0, MathMax(0, VpSize.Y / UiScale - h));
	local pos = opts.position or NewUdim2(0, DefaultX, 0, DefaultY);

	local gui = self:CreateInstance("ScreenGui", {
		Name = "\0";
		Parent = (gethui and gethui()) or CoreGui;
		Enabled = true;
		DisplayOrder = self.WidgetDisplayOrder or 1002;
		IgnoreGuiInset = true;
		ResetOnSpawn = false;
		ZIndexBehavior = Enum.ZIndexBehavior.Global;
	});
	self:ApplyScale(gui);

	local outer = self:CreateInstance("Frame", {
		Name = "Outer"; Parent = gui;
		Position = pos; Size = FromOffset(w, h);
		BackgroundColor3 = hex("07080A"); BorderSizePixel = 0; Active = true;
	});
	self:CreateInstance("ImageLabel", {
		Name = "Glow"; Parent = outer;
		AnchorPoint = NewVector2(0.5, 0.5);
		Position = NewUdim2(0.5, 0, 0.5, 0);
		Size = NewUdim2(1, 30, 1, 30);
		BackgroundTransparency = 1;
		Image = "rbxassetid://18245826428";
		ImageColor3 = hex("98BCFF");
		ImageTransparency = 0.86;
		ScaleType = Enum.ScaleType.Slice;
		SliceCenter = RectNew(21, 21, 79, 79);
		ZIndex = -1;
	});
	local inner = self:CreateInstance("Frame", {
		Parent = outer;
		Position = NewUdim2(0, 1, 0, 1); Size = NewUdim2(1, -2, 1, -2);
		BackgroundColor3 = hex("24262D"); BorderSizePixel = 0;
	});
	local main = self:CreateInstance("Frame", {
		Parent = inner;
		Position = NewUdim2(0, 1, 0, 1); Size = NewUdim2(1, -2, 1, -2);
		BackgroundColor3 = FromRgb(255, 255, 255); BorderSizePixel = 0;
	});
	self:CreateInstance("UIGradient", {
		Parent = main; Rotation = 90;
		Color = NewColorSequence(hex("131418"), hex("17181D"));
	});
	self:CreateInstance("Frame", {
		Parent = main; Position = NewUdim2(0, 0, 0, 0); Size = NewUdim2(1, 0, 0, 1);
		BackgroundColor3 = hex("98BCFF"); BorderSizePixel = 0; ZIndex = 2;
	});
	self:CreateInstance("Frame", {
		Parent = main; Position = NewUdim2(0, 0, 0, 1); Size = NewUdim2(1, 0, 0, 1);
		BackgroundColor3 = hex("6E8CC8"); BorderSizePixel = 0; ZIndex = 2;
	});

	local header = self:CreateInstance("Frame", {
		Name = "Header"; Parent = main;
		Position = NewUdim2(0, 0, 0, 0); Size = NewUdim2(1, 0, 0, 22);
		BackgroundTransparency = 1; Active = true; ZIndex = 4;
	});
	self:CreateInstance("TextLabel", {
		Parent = header;
		Position = NewUdim2(0, 10, 0, 5); Size = NewUdim2(1, -20, 0, 14);
		BackgroundTransparency = 1;
		FontFace = Library.Fonts.title;
		Text = TitleText;
		TextColor3 = hex("98BCFF");
		TextSize = 9;
		TextXAlignment = Enum.TextXAlignment.Left;
		TextYAlignment = Enum.TextYAlignment.Top;
		ZIndex = 5;
	});

	local section = self:CreateInstance("Frame", {
		Name = "Section"; Parent = main;
		Position = NewUdim2(0, 6, 0, 22);
		Size = NewUdim2(1, -12, 1, -28);
		BackgroundColor3 = FromRgb(255, 255, 255); BorderSizePixel = 0; ZIndex = 2;
	});
	self:CreateInstance("UIGradient", {
		Parent = section; Rotation = 90;
		Color = NewColorSequence(hex("131418"), hex("17181D"));
	});
	self:CreateInstance("Frame", {
		Name = "AccentBar"; Parent = section;
		Position = NewUdim2(0, 0, 0, 0); Size = NewUdim2(1, 0, 0, 1);
		BackgroundColor3 = hex("98BCFF"); BorderSizePixel = 0; ZIndex = 3;
	});
	self:CreateInstance("TextLabel", {
		Name = "SectionTitle"; Parent = section;
		Position = NewUdim2(0, 10, 0, 4);
		Size = NewUdim2(1, -20, 0, 12);
		BackgroundTransparency = 1;
		FontFace = Library.Fonts.title;
		Text = "Theme & overlay";
		TextColor3 = hex("8A8A92");
		TextSize = 9;
		TextXAlignment = Enum.TextXAlignment.Left;
		TextYAlignment = Enum.TextYAlignment.Center;
		ZIndex = 3;
	});

	local body = self:CreateInstance("ScrollingFrame", {
		Parent = section;
		Position = NewUdim2(0, 10, 0, 22);
		Size = NewUdim2(1, -20, 1, -28);
		BackgroundTransparency = 1; ZIndex = 3;
		BorderSizePixel = 0;
		ClipsDescendants = true;
		ScrollBarThickness = 3;
		ScrollBarImageColor3 = hex("3A3D45");
		ScrollingDirection = Enum.ScrollingDirection.Y;
		CanvasSize = NewUdim2(0, 0, 0, 0);
		AutomaticCanvasSize = Enum.AutomaticSize.Y;
	});
	self:CreateInstance("UIListLayout", {
		Parent = body;
		FillDirection = Enum.FillDirection.Vertical;
		SortOrder = Enum.SortOrder.LayoutOrder;
		Padding = NewUdim(0, 6);
	});
	self:CreateInstance("UIPadding", {
		Parent = body;
		PaddingRight = NewUdim(0, 6);
		PaddingBottom = NewUdim(0, 6);
	});

	local LibRef = self;
	local OrderCounter = 0;
	local function NextOrder() OrderCounter = OrderCounter + 1; return OrderCounter end;

	local function MakeRow(NameText, height)
		local row = LibRef:CreateInstance("Frame", {
			Parent = body;
			Size = NewUdim2(1, 0, 0, height or 18);
			BackgroundTransparency = 1; BorderSizePixel = 0;
			LayoutOrder = NextOrder(); ZIndex = 3;
		});
		LibRef:CreateInstance("TextLabel", {
			Parent = row;
			AnchorPoint = NewVector2(0, 0.5);
			Position = NewUdim2(0, 0, 0.5, 0);
			Size = NewUdim2(1, -64, 1, 0);
			BackgroundTransparency = 1;
			FontFace = Library.Fonts.title;
			Text = tostring(NameText);
			TextColor3 = hex("B4B4B4");
			TextSize = 9;
			TextXAlignment = Enum.TextXAlignment.Left;
			TextYAlignment = Enum.TextYAlignment.Center;
			ZIndex = 4;
		});
		return row;
	end;

	local function MakeToggle(parent, default, callback)
		local box = LibRef:CreateInstance("Frame", {
			Parent = parent;
			AnchorPoint = NewVector2(1, 0.5);
			Position = NewUdim2(1, 0, 0.5, 0);
			Size = FromOffset(14, 14);
			BackgroundColor3 = hex("07080A"); BorderSizePixel = 0; ZIndex = 4;
		});
		local BoxMid = LibRef:CreateInstance("Frame", {
			Parent = box;
			Position = NewUdim2(0, 1, 0, 1); Size = NewUdim2(1, -2, 1, -2);
			BackgroundColor3 = hex("24262D"); BorderSizePixel = 0; ZIndex = 5;
		});
		local BoxBody = LibRef:CreateInstance("Frame", {
			Parent = BoxMid;
			Position = NewUdim2(0, 1, 0, 1); Size = NewUdim2(1, -2, 1, -2);
			BackgroundColor3 = FromRgb(255, 255, 255); BorderSizePixel = 0; ZIndex = 6;
		});
		LibRef:CreateInstance("UIGradient", {
			Parent = BoxBody; Rotation = 90;
			Color = NewColorSequence(hex("131418"), hex("17181D"));
		});
		local fill = LibRef:CreateInstance("Frame", {
			Parent = BoxBody;
			Size = NewUdim2(1, 0, 1, 0);
			BackgroundColor3 = hex("98BCFF");
			BackgroundTransparency = default and 0 or 1;
			BorderSizePixel = 0; ZIndex = 7;
		});
		local hit = LibRef:CreateInstance("TextButton", {
			Parent = parent;
			Size = NewUdim2(1, 0, 1, 0);
			BackgroundTransparency = 1; AutoButtonColor = false; Text = ""; ZIndex = 8;
		});
		local state = default == true;
		local ToggleTween = NewTweenInfo(0.15, Enum.EasingStyle.Quad, Enum.EasingDirection.Out);
		local function set(v)
			state = v == true;
			LibRef:Tween(fill, ToggleTween, { BackgroundTransparency = state and 0 or 1 }):Play();
			if typeof(callback) == "function" then callback(state) end;
		end;
		LibRef:Connection(hit.MouseButton1Click, function() set(not state) end);
		return { fill = fill, get = function() return state end, set = set };
	end;

	local AccentColor = self.AccentColor or hex("98BCFF");
	self.AccentColor = AccentColor;

	local function EqColor(a, b)
		return MathAbs(a.R - b.R) < 0.004 and MathAbs(a.G - b.G) < 0.004 and MathAbs(a.B - b.B) < 0.004;
	end;
	local function ColorSwapMulti(mappings)
		local active = {};
		for _, m in mappings do
			if m[1] ~= m[2] then insert(active, m) end;
		end;
		if #active == 0 then return end;
		local function FindMap(c)
			for _, m in active do
				if EqColor(c, m[1]) then return m[2] end;
			end;
			return nil;
		end;
		local hui = (gethui and gethui()) or CoreGui;
		local function walk(inst)
			for _, ch in inst:GetChildren() do
				if ch.Name == "ThemeDot" or ch.Name == "ColorSwatch" or ch.Name == "PickerUI" then continue end;
				if ch:IsA("GuiObject") then
					local m = FindMap(ch.BackgroundColor3);
					if m then ch.BackgroundColor3 = m end;
				end;
				if ch:IsA("TextLabel") or ch:IsA("TextButton") or ch:IsA("TextBox") then
					local mt = FindMap(ch.TextColor3);
					if mt then ch.TextColor3 = mt end;
					local ms = FindMap(ch.TextStrokeColor3);
					if ms then ch.TextStrokeColor3 = ms end;
				elseif ch:IsA("ImageLabel") or ch:IsA("ImageButton") then
					local mi = FindMap(ch.ImageColor3);
					if mi then ch.ImageColor3 = mi end;
				end;
				if ch:IsA("ScrollingFrame") then
					local msb = FindMap(ch.ScrollBarImageColor3);
					if msb then ch.ScrollBarImageColor3 = msb end;
				end;
				if ch:IsA("UIStroke") then
					local mu = FindMap(ch.Color);
					if mu then ch.Color = mu end;
				elseif ch:IsA("UIGradient") then
					local kps = ch.Color.Keypoints;
					local changed = false;
					local NewKps = {};
					for i, k in kps do
						local mk = FindMap(k.Value);
						if mk then
							NewKps[i] = NewColorSequenceKeypoint(k.Time, mk);
							changed = true;
						else
							NewKps[i] = k;
						end;
					end;
					if changed then ch.Color = NewColorSequence(NewKps) end;
				end;
				walk(ch);
			end;
		end;
		walk(hui);
	end;
	local function ColorSwap(old, NewC)
		ColorSwapMulti({ { old, NewC } });
	end;
	local function ShiftV(c, factor)
		local h, s, v = Color3.toHSV(c);
		return FromHsv(h, s, MathClamp(v * factor, 0, 1));
	end;
	local function ShiftVS(c, vFactor, sCap)
		local h, s, v = Color3.toHSV(c);
		return FromHsv(h, MathMin(s, sCap), MathClamp(v * vFactor, 0, 1));
	end;
	local RowsByName = {};
	local function ApplyAccent(NewC)
		local old      = self.AccentColor;
		local OldGrad = self.AccentGradColor or hex("94B7F8");
		if old == NewC then return end;
		local NewGrad = ShiftV(NewC, 0.96);
		ColorSwapMulti({
			{ OldGrad, NewGrad };
			{ old, NewC };
		});
		self.AccentColor      = NewC;
		self.AccentGradColor = NewGrad;
		Library.Flags["appearance.AccentColor"] = NewC;
		if RowsByName.accent then
			RowsByName.accent.h, RowsByName.accent.s, RowsByName.accent.v = NewC:ToHSV();
			RowsByName.accent.fill.BackgroundColor3 = NewC;
		end;
	end;
	local function ApplyShade(NewC)
		local old      = self.ShadeColor or hex("6E8CC8");
		local OldGrad = self.ShadeGradColor or hex("6B84B3");
		if old == NewC then return end;
		local NewGrad = ShiftV(NewC, 0.90);
		ColorSwapMulti({
			{ OldGrad, NewGrad };
			{ old, NewC };
		});
		self.ShadeColor      = NewC;
		self.ShadeGradColor = NewGrad;
		Library.Flags["appearance.ShadeColor"] = NewC;
		if RowsByName.shade then
			RowsByName.shade.h, RowsByName.shade.s, RowsByName.shade.v = NewC:ToHSV();
			RowsByName.shade.fill.BackgroundColor3 = NewC;
		end;
	end;
	local function ApplyBg(NewMain)
		local h, s, v = Color3.toHSV(NewMain);
		if v > 0.25 then
			v = 0.25;
			NewMain = FromHsv(h, s, v);
		end;
		local OldMain     = self.WindowBgColor    or hex("101114");
		local OldGradTop = self.BgGradTopColor  or hex("131418");
		local OldGradBot = self.BgGradBotColor  or hex("17181D");
		if OldMain == NewMain then return end;
		local NewGradTop = ShiftV(NewMain, 1.19);
		local NewGradBot = ShiftV(NewMain, 1.45);
		ColorSwapMulti({
			{ OldGradTop, NewGradTop };
			{ OldGradBot, NewGradBot };
			{ OldMain,     NewMain };
		});
		self.BgGradTopColor  = NewGradTop;
		self.BgGradBotColor  = NewGradBot;
		self.WindowBgColor    = NewMain;
		Library.Flags["appearance.WindowBgColor"] = NewMain;
		if RowsByName.bg then
			RowsByName.bg.h, RowsByName.bg.s, RowsByName.bg.v = NewMain:ToHSV();
			RowsByName.bg.fill.BackgroundColor3 = NewMain;
		end;
	end;
	local function ApplyThemeBg(NewMain)
		local h, s, v = Color3.toHSV(NewMain);
		if v > 0.25 then
			v = 0.25;
			NewMain = FromHsv(h, s, v);
		end;
		local OldMain     = self.WindowBgColor    or hex("101114");
		local OldOuter    = self.WindowOuterColor or hex("07080A");
		local OldInner    = self.WindowInnerColor or hex("24262D");
		local OldControl  = self.BgControlColor   or hex("1C1D23");
		local OldGradTop = self.BgGradTopColor  or hex("131418");
		local OldGradBot = self.BgGradBotColor  or hex("17181D");
		local NewOuter    = ShiftVS(NewMain, 0.50, 0.35);
		local NewInner    = ShiftVS(NewMain, 2.25, 0.35);
		local NewControl  = ShiftVS(NewMain, 1.75, 0.35);
		local NewGradTop = ShiftV(NewMain, 1.19);
		local NewGradBot = ShiftV(NewMain, 1.45);
		ColorSwapMulti({
			{ OldOuter,    NewOuter };
			{ OldInner,    NewInner };
			{ OldControl,  NewControl };
			{ OldGradTop, NewGradTop };
			{ OldGradBot, NewGradBot };
			{ OldMain,     NewMain };
		});
		self.WindowOuterColor = NewOuter;
		self.WindowInnerColor = NewInner;
		self.BgControlColor   = NewControl;
		self.BgGradTopColor  = NewGradTop;
		self.BgGradBotColor  = NewGradBot;
		self.WindowBgColor    = NewMain;
		Library.Flags["appearance.WindowBgColor"] = NewMain;
		if RowsByName.bg then
			RowsByName.bg.h, RowsByName.bg.s, RowsByName.bg.v = NewMain:ToHSV();
			RowsByName.bg.fill.BackgroundColor3 = NewMain;
		end;
	end;
	self.ShadeColor        = self.ShadeColor        or hex("6E8CC8");
	self.AccentGradColor  = self.AccentGradColor  or hex("94B7F8");
	self.ShadeGradColor   = self.ShadeGradColor   or hex("6B84B3");
	self.WindowBgColor    = self.WindowBgColor    or hex("101114");
	self.WindowOuterColor = self.WindowOuterColor or hex("07080A");
	self.WindowInnerColor = self.WindowInnerColor or hex("24262D");
	self.BgGradTopColor  = self.BgGradTopColor  or hex("131418");
	self.BgGradBotColor  = self.BgGradBotColor  or hex("17181D");
	self.BgControlColor   = self.BgControlColor   or hex("1C1D23");

	Library:RegisterFlag("appearance.AccentColor", self.AccentColor, function(v)
		if typeof(v) == "Color3" then ApplyAccent(v) end;
	end);
	Library:RegisterFlag("appearance.ShadeColor", self.ShadeColor, function(v)
		if typeof(v) == "Color3" then ApplyShade(v) end;
	end);
	Library:RegisterFlag("appearance.WindowBgColor", self.WindowBgColor, function(v)
		if typeof(v) == "Color3" then ApplyThemeBg(v) end;
	end);
	Library:RegisterFlag("appearance.theme", self.ThemeName or "Default", function(name)
		for _, theme in self.Themes do
			if theme.name == name then
				self.ThemeName = name;
				ApplyAccent(theme.accent);
				if theme.shade then ApplyShade(theme.shade) end;
				if theme.bg then ApplyThemeBg(theme.bg) end;
				return;
			end;
		end;
	end);

	local PICKER_W, PICKER_H = 190, 160;
	local picker = self:CreateInstance("Frame", {
		Name = "Picker"; Parent = gui;
		Size = FromOffset(PICKER_W, PICKER_H);
		BackgroundColor3 = hex("07080A"); BorderSizePixel = 0;
		ClipsDescendants = true;
		Active = true;
		Visible = false; ZIndex = 60;
	});
	self:CreateInstance("Frame", {
		Parent = picker;
		Position = NewUdim2(0, 1, 0, 1); Size = NewUdim2(1, -2, 1, -2);
		BackgroundColor3 = hex("24262D"); BorderSizePixel = 0; ZIndex = 61;
	});
	local PickerBody = self:CreateInstance("Frame", {
		Parent = picker;
		Position = NewUdim2(0, 2, 0, 2); Size = NewUdim2(1, -4, 1, -4);
		BackgroundColor3 = hex("101114"); BorderSizePixel = 0; ZIndex = 62;
	});
	self:CreateInstance("UIPadding", {
		Parent = PickerBody;
		PaddingTop = NewUdim(0, 8); PaddingBottom = NewUdim(0, 8);
		PaddingLeft = NewUdim(0, 8); PaddingRight = NewUdim(0, 8);
	});
	local SatVal = self:CreateInstance("Frame", {
		Name = "PickerUI";
		Parent = PickerBody;
		Size = NewUdim2(1, -18, 1, 0);
		BackgroundColor3 = FromRgb(255, 0, 0); BorderSizePixel = 0; ZIndex = 63;
	});
	local SatLayer = self:CreateInstance("TextButton", {
		Parent = SatVal; Size = NewUdim2(1, 0, 1, 0);
		BackgroundColor3 = FromRgb(255, 255, 255); BorderSizePixel = 0;
		AutoButtonColor = false; Text = ""; ZIndex = 64;
	});
	self:CreateInstance("UIGradient", {
		Parent = SatLayer;
		Transparency = NewNumberSequence({
			NewNumberSequenceKeypoint(0, 0); NewNumberSequenceKeypoint(1, 1);
		});
		Color = NewColorSequence(FromRgb(255, 255, 255), FromRgb(255, 255, 255));
	});
	local ValLayer = self:CreateInstance("TextButton", {
		Parent = SatVal; Size = NewUdim2(1, 0, 1, 0);
		BackgroundColor3 = FromRgb(0, 0, 0); BorderSizePixel = 0;
		AutoButtonColor = false; Text = ""; ZIndex = 65;
	});
	self:CreateInstance("UIGradient", {
		Parent = ValLayer; Rotation = 90;
		Color = NewColorSequence(FromRgb(0, 0, 0), FromRgb(0, 0, 0));
		Transparency = NewNumberSequence({
			NewNumberSequenceKeypoint(0, 1); NewNumberSequenceKeypoint(1, 0);
		});
	});
	local SvMarker = self:CreateInstance("Frame", {
		Parent = SatVal; Size = FromOffset(2, 2);
		BorderSizePixel = 1; BorderColor3 = FromRgb(0, 0, 0);
		BackgroundColor3 = FromRgb(255, 255, 255); ZIndex = 66;
	});
	local hue = self:CreateInstance("TextButton", {
		Name = "PickerUI";
		Parent = PickerBody;
		AnchorPoint = NewVector2(1, 0);
		Position = NewUdim2(1, 0, 0, 0); Size = NewUdim2(0, 12, 1, 0);
		BackgroundColor3 = FromRgb(255, 255, 255); BorderSizePixel = 0;
		AutoButtonColor = false; Text = ""; ZIndex = 63;
	});
	self:CreateInstance("UIGradient", {
		Parent = hue; Rotation = 270;
		Color = NewColorSequence({
			NewColorSequenceKeypoint(0.00, FromRgb(255, 0, 0));
			NewColorSequenceKeypoint(0.17, FromRgb(255, 255, 0));
			NewColorSequenceKeypoint(0.33, FromRgb(0, 255, 0));
			NewColorSequenceKeypoint(0.50, FromRgb(0, 255, 255));
			NewColorSequenceKeypoint(0.67, FromRgb(0, 0, 255));
			NewColorSequenceKeypoint(0.83, FromRgb(255, 0, 255));
			NewColorSequenceKeypoint(1.00, FromRgb(255, 0, 0));
		});
	});
	local HueMarker = self:CreateInstance("Frame", {
		Parent = hue; Size = NewUdim2(1, 0, 0, 2);
		BorderSizePixel = 1; BorderColor3 = FromRgb(0, 0, 0);
		BackgroundColor3 = FromRgb(255, 255, 255); ZIndex = 64;
	});

	local CurrentTarget;
	RowsByName = {};
	local function RefreshPickerFor(t)
		local c = FromHsv(t.h, t.s, t.v);
		t.fill.BackgroundColor3 = c;
		t.apply(c);
		if t == CurrentTarget then
			SatVal.BackgroundColor3 = FromHsv(t.h, 1, 1);
			local SOff = (t.s < 1) and 0 or -3;
			local VOff = ((1 - t.v) < 1) and 0 or -3;
			SvMarker.Position = NewUdim2(t.s, SOff, 1 - t.v, VOff);
			local HOff = ((1 - t.h) < 1) and 0 or -2;
			HueMarker.Position = NewUdim2(0, 0, 1 - t.h, HOff);
		end;
	end;

	local PickerOpen = false;
	local PickerTween;
	local PICKER_ANIM = NewTweenInfo(0.15, Enum.EasingStyle.Quad, Enum.EasingDirection.Out);
	local function SetPickerOpen(b, target)
		PickerOpen = b;
		if PickerTween then PickerTween:Cancel() end;
		if b and target then
			CurrentTarget = target;
			RefreshPickerFor(target);
			local p = target.swatch.AbsolutePosition;
			local _, _, sc = Library:GuiPoint(gui, 0, 0);
			local px, py = Library:GuiPoint(gui, p.X - PICKER_W * sc + target.swatch.AbsoluteSize.X, p.Y + target.swatch.AbsoluteSize.Y + 2);
			picker.Position = NewUdim2(0, px, 0, py);
			picker.Size = FromOffset(PICKER_W, 0);
			picker.Visible = true;
			PickerTween = TweenService:Create(picker, PICKER_ANIM, { Size = FromOffset(PICKER_W, PICKER_H) });
			PickerTween:Play();
		else
			PickerTween = TweenService:Create(picker, PICKER_ANIM, { Size = FromOffset(PICKER_W, 0) });
			PickerTween:Play();
			PickerTween.Completed:Connect(function()
				if not PickerOpen then picker.Visible = false end;
			end);
		end;
	end;

	local function MakeColorRow(LabelText, initial, ApplyFn, key)
		local row = MakeRow(LabelText, 18);
		local SwatchOutline = self:CreateInstance("TextButton", {
			Name = "ColorSwatch";
			Parent = row;
			AnchorPoint = NewVector2(1, 0.5);
			Position = NewUdim2(1, 0, 0.5, 0);
			Size = FromOffset(26, 14);
			BackgroundColor3 = hex("07080A"); BorderSizePixel = 0;
			AutoButtonColor = false; Text = ""; ZIndex = 4;
		});
		self:CreateInstance("Frame", {
			Parent = SwatchOutline;
			Position = NewUdim2(0, 1, 0, 1); Size = NewUdim2(1, -2, 1, -2);
			BackgroundColor3 = hex("24262D"); BorderSizePixel = 0; ZIndex = 5;
		});
		local fill = self:CreateInstance("Frame", {
			Name = "ColorSwatchFill";
			Parent = SwatchOutline;
			Position = NewUdim2(0, 2, 0, 2); Size = NewUdim2(1, -4, 1, -4);
			BackgroundColor3 = initial; BorderSizePixel = 0; ZIndex = 6;
		});
		local h0, s0, v0 = initial:ToHSV();
		local target = { swatch = SwatchOutline, fill = fill, apply = ApplyFn, h = h0, s = s0, v = v0 };
		RowsByName[key] = target;
		self:Connection(SwatchOutline.MouseButton1Click, function()
			if PickerOpen and CurrentTarget == target then
				SetPickerOpen(false);
			else
				SetPickerOpen(true, target);
			end;
		end);
		self:Connection(SwatchOutline.MouseButton2Click, function()
			if (UserInputService:IsKeyDown(Enum.KeyCode.LeftControl) or UserInputService:IsKeyDown(Enum.KeyCode.RightControl)) and Library.CopiedColor and typeof(Library.CopiedColor.Color) == "Color3" then
				target.h, target.s, target.v = Library.CopiedColor.Color:ToHSV();
				RefreshPickerFor(target);
			else
				Library.CopiedColor = { Color = FromHsv(target.h, target.s, target.v); Transparency = 0 };
			end;
		end);
		return target;
	end;

	local AccentTarget = MakeColorRow("Accent color", self.AccentColor or hex("98BCFF"), ApplyAccent, "accent");
	local ShadeTarget  = MakeColorRow("Shade color",  self.ShadeColor,                   ApplyShade,  "shade");
	local BgTarget     = MakeColorRow("Window bg",    self.WindowBgColor,               ApplyBg,     "bg");

	local function MakeFontPicker(LabelText, FlagKey, default, apply)
		local row = MakeRow(LabelText, 18);
		local Bg = self:CreateInstance("Frame", { Parent = row; AnchorPoint = NewVector2(1, 0.5); Position = NewUdim2(1, 0, 0.5, 0); Size = FromOffset(82, 16); BackgroundColor3 = hex("07080A"); BorderSizePixel = 0; ZIndex = 4; });
		local Mid = self:CreateInstance("Frame", { Parent = Bg; Position = NewUdim2(0, 1, 0, 1); Size = NewUdim2(1, -2, 1, -2); BackgroundColor3 = hex("24262D"); BorderSizePixel = 0; ZIndex = 5; });
		local Body = self:CreateInstance("Frame", { Parent = Mid; Position = NewUdim2(0, 1, 0, 1); Size = NewUdim2(1, -2, 1, -2); BackgroundColor3 = FromRgb(255, 255, 255); BorderSizePixel = 0; ZIndex = 6; });
		self:CreateInstance("UIGradient", { Parent = Body; Rotation = 90; Color = NewColorSequence(hex("131418"), hex("17181D")); });
		local Lbl = self:CreateInstance("TextLabel", { Parent = Body; Position = NewUdim2(0, 6, 0, -1); Size = NewUdim2(1, -18, 1, 0); BackgroundTransparency = 1; FontFace = Library.Fonts.title; Text = default; TextColor3 = FromRgb(255, 255, 255); TextSize = 9; TextXAlignment = Enum.TextXAlignment.Left; TextYAlignment = Enum.TextYAlignment.Center; ZIndex = 7; });
		local Arrow = self:CreateInstance("TextLabel", { Parent = Body; AnchorPoint = NewVector2(1, 0.5); Position = NewUdim2(1, -4, 0.5, 0); Size = FromOffset(8, 9); BackgroundTransparency = 1; FontFace = Library.Fonts.title; Text = "v"; TextColor3 = hex("B4B4B4"); TextSize = 9; TextXAlignment = Enum.TextXAlignment.Center; TextYAlignment = Enum.TextYAlignment.Center; ZIndex = 7; });
		local Hit = self:CreateInstance("TextButton", { Parent = Bg; Size = NewUdim2(1, 0, 1, 0); BackgroundTransparency = 1; AutoButtonColor = false; Text = ""; ZIndex = 8; });

		local Popup = self:CreateInstance("Frame", { Name = "FontPopup"; Parent = gui; BackgroundColor3 = hex("07080A"); BorderSizePixel = 0; Active = true; Visible = false; ClipsDescendants = true; ZIndex = 60; });
		local PMid = self:CreateInstance("Frame", { Parent = Popup; Position = NewUdim2(0, 1, 0, 1); Size = NewUdim2(1, -2, 1, -2); BackgroundColor3 = hex("24262D"); BorderSizePixel = 0; ZIndex = 61; });
		local PInner = self:CreateInstance("Frame", { Parent = PMid; Position = NewUdim2(0, 1, 0, 1); Size = NewUdim2(1, -2, 1, -2); BackgroundColor3 = FromRgb(255, 255, 255); BorderSizePixel = 0; ZIndex = 62; });
		self:CreateInstance("UIGradient", { Parent = PInner; Rotation = 90; Color = NewColorSequence(hex("131418"), hex("17181D")); });
		local PList = self:CreateInstance("Frame", { Parent = PInner; Size = NewUdim2(1, 0, 1, 0); BackgroundTransparency = 1; ZIndex = 63; });
		self:CreateInstance("UIPadding", { Parent = PList; PaddingTop = NewUdim(0, 4); PaddingBottom = NewUdim(0, 6); });
		self:CreateInstance("UIListLayout", { Parent = PList; FillDirection = Enum.FillDirection.Vertical; SortOrder = Enum.SortOrder.LayoutOrder; Padding = NewUdim(0, 1); });

		local names = Library.UIFontNames or {};
		local Open = false;
		local AnimTween;
		local function Close()
			Open = false; Arrow.Text = "v";
			if AnimTween then AnimTween:Cancel() end;
			AnimTween = TweenService:Create(Popup, NewTweenInfo(0.15, Enum.EasingStyle.Quad, Enum.EasingDirection.Out), { Size = FromOffset(Popup.AbsoluteSize.X, 0) });
			AnimTween:Play();
			AnimTween.Completed:Once(function() if not Open then Popup.Visible = false end end);
		end;
		local function OpenList()
			Open = true; Arrow.Text = "^";
			local tp = Bg.AbsolutePosition; local ts = Bg.AbsoluteSize;
			local TargetH = #names * 14 + 10;
			local px, py, sc = Library:GuiPoint(gui, tp.X, tp.Y + ts.Y + 2);
			Popup.Position = NewUdim2(0, px, 0, py);
			Popup.Size = FromOffset(ts.X / sc, 0);
			Popup.Visible = true;
			if AnimTween then AnimTween:Cancel() end;
			AnimTween = TweenService:Create(Popup, NewTweenInfo(0.15, Enum.EasingStyle.Quad, Enum.EasingDirection.Out), { Size = FromOffset(ts.X / sc, TargetH) });
			AnimTween:Play();
		end;
		local function pick(name)
			Lbl.Text = name;
			Library.Flags[FlagKey] = name;
			if apply then apply(name) end;
		end;
		for i, name in ipairs(names) do
			local r = self:CreateInstance("TextButton", { Parent = PList; Size = NewUdim2(1, 0, 0, 13); BackgroundTransparency = 1; AutoButtonColor = false; Text = ""; LayoutOrder = i; ZIndex = 64; });
			local l = self:CreateInstance("TextLabel", { Parent = r; Position = NewUdim2(0, 6, 0, 0); Size = NewUdim2(1, -10, 1, 0); BackgroundTransparency = 1; FontFace = Library.Fonts.title; Text = name; TextColor3 = hex("B4B4B4"); TextSize = 9; TextXAlignment = Enum.TextXAlignment.Left; TextYAlignment = Enum.TextYAlignment.Center; ZIndex = 65; });
			self:Connection(r.MouseEnter, function() l.TextColor3 = FromRgb(255, 255, 255) end);
			self:Connection(r.MouseLeave, function() l.TextColor3 = hex("B4B4B4") end);
			self:Connection(r.MouseButton1Click, function() pick(name); Close() end);
		end;
		self:Connection(Hit.MouseButton1Click, function() if Open then Close() else OpenList() end end);
		self:Connection(UserInputService.InputBegan, function(input)
			if not Open then return end;
			if input.UserInputType ~= Enum.UserInputType.MouseButton1 then return end;
			local mx, my = Library:MousePoint(gui, input);
			if not Library:PointInObject(Popup, mx, my, 2) and not Library:PointInObject(Bg, mx, my, 2) then Close() end;
		end);
		Library:RegisterFlag(FlagKey, default, function(v) if type(v) == "string" then pick(v) end end);
		pick(default);
		return Lbl;
	end;

	local function MakeFontSlider(LabelText, FlagKey, minV, maxV, default, apply)
		local row = MakeRow(LabelText, 26);
		local Track = self:CreateInstance("Frame", { Parent = row; AnchorPoint = NewVector2(1, 0.5); Position = NewUdim2(1, 0, 0.5, 0); Size = FromOffset(82, 12); BackgroundColor3 = hex("07080A"); BorderSizePixel = 0; ZIndex = 4; });
		local Mid = self:CreateInstance("Frame", { Parent = Track; Position = NewUdim2(0, 1, 0, 1); Size = NewUdim2(1, -2, 1, -2); BackgroundColor3 = hex("1C1D23"); BorderSizePixel = 0; ZIndex = 5; });
		local Fill = self:CreateInstance("Frame", { Parent = Mid; BackgroundColor3 = hex("98BCFF"); BorderSizePixel = 0; ZIndex = 6; });
		local Hit = self:CreateInstance("TextButton", { Parent = Track; Size = NewUdim2(1, 0, 1, 0); BackgroundTransparency = 1; AutoButtonColor = false; Text = ""; ZIndex = 7; });
		local dragging = false;
		local function setval(v)
			v = MathClamp(MathFloor((tonumber(v) or default) + 0.5), minV, maxV);
			Fill.Size = NewUdim2((v - minV) / MathMax(1, (maxV - minV)), 0, 1, 0);
			Library.Flags[FlagKey] = v;
			if apply then apply(v) end;
		end;
		local function update(px)
			local abs = Track.AbsolutePosition.X;
			local wide = MathMax(1, Track.AbsoluteSize.X);
			setval(minV + (maxV - minV) * MathClamp((px - abs) / wide, 0, 1));
		end;
		self:Connection(Hit.InputBegan, function(i) if i.UserInputType == Enum.UserInputType.MouseButton1 then dragging = true; update(i.Position.X) end end);
		self:Connection(UserInputService.InputChanged, function(i) if dragging and i.UserInputType == Enum.UserInputType.MouseMovement then update(i.Position.X) end end);
		self:Connection(UserInputService.InputEnded, function(i) if i.UserInputType == Enum.UserInputType.MouseButton1 then dragging = false end end);
		Library:RegisterFlag(FlagKey, default, function(v) setval(v) end);
		setval(default);
		return row;
	end;

	local FontSizes = { SmallestPixel7 = 9, ProggyTiny = 9, Minecraftia = 10 };
	MakeFontPicker("UI Font", "appearance.UIFont", "SmallestPixel7", function(name)
		local f = Library.UIFonts and Library.UIFonts[name];
		if f then Library:ApplyMenuFont(f) end;
		Library:SetMenuFontSize((FontSizes[name] or 9) / 9);
	end);
	MakeFontPicker("ESP Font", "appearance.ESPFont", "SmallestPixel7", function(name)
		local f = Library.UIFonts and Library.UIFonts[name];
		if f then Library.ESPFont = f end;
		local s = FontSizes[name] or 9;
		Library.ESPFontSize = s;
		Library.Flags.ESPFontSize = s;
	end);

	local DraggingSv, DraggingH = false, false;
	self:Connection(SatLayer.InputBegan, function(input)
		if input.UserInputType == Enum.UserInputType.MouseButton1 then DraggingSv = true end;
	end);
	self:Connection(ValLayer.InputBegan, function(input)
		if input.UserInputType == Enum.UserInputType.MouseButton1 then DraggingSv = true end;
	end);
	self:Connection(hue.InputBegan, function(input)
		if input.UserInputType == Enum.UserInputType.MouseButton1 then DraggingH = true end;
	end);
	self:Connection(UserInputService.InputEnded, function(input)
		if input.UserInputType == Enum.UserInputType.MouseButton1 then
			DraggingSv = false; DraggingH = false;
		end;
	end);
	self:Connection(UserInputService.InputChanged, function(input)
		if input.UserInputType ~= Enum.UserInputType.MouseMovement then return end;
		if not CurrentTarget or not (DraggingSv or DraggingH) then return end;
		local mx, my = Library:MousePoint(gui, input);
		if DraggingSv then
			local ap, sz = SatVal.AbsolutePosition, SatVal.AbsoluteSize;
			CurrentTarget.s = sz.X > 0 and MathClamp((mx - ap.X) / sz.X, 0, 1) or 0;
			CurrentTarget.v = sz.Y > 0 and 1 - MathClamp((my - ap.Y) / sz.Y, 0, 1) or 0;
		elseif DraggingH then
			local ap, sz = hue.AbsolutePosition, hue.AbsoluteSize;
			CurrentTarget.h = sz.Y > 0 and 1 - MathClamp((my - ap.Y) / sz.Y, 0, 1) or 0;
		end;
		RefreshPickerFor(CurrentTarget);
	end);
	self:Connection(UserInputService.InputBegan, function(input)
		if input.UserInputType ~= Enum.UserInputType.MouseButton1 then return end;
		if not PickerOpen then return end;
		local mx, my = Library:MousePoint(gui, input);
		local InsideAnySwatch = Library:PointInObject(AccentTarget.swatch, mx, my, 2) or Library:PointInObject(ShadeTarget.swatch, mx, my, 2) or Library:PointInObject(BgTarget.swatch, mx, my, 2);
		if not Library:PointInObject(picker, mx, my, 2) and not InsideAnySwatch then SetPickerOpen(false) end;
	end);

	local function SetColor(key, c)
		local t = RowsByName[key];
		if not t then return end;
		t.h, t.s, t.v = c:ToHSV();
		RefreshPickerFor(t);
	end;

	local ThemeRow = MakeRow("Theme", 18);
	local ThemeBg = self:CreateInstance("Frame", {
		Parent = ThemeRow;
		AnchorPoint = NewVector2(1, 0.5);
		Position = NewUdim2(1, 0, 0.5, 0);
		Size = FromOffset(82, 16);
		BackgroundColor3 = hex("07080A"); BorderSizePixel = 0; ZIndex = 4;
	});
	local ThemeMid = self:CreateInstance("Frame", {
		Parent = ThemeBg;
		Position = NewUdim2(0, 1, 0, 1); Size = NewUdim2(1, -2, 1, -2);
		BackgroundColor3 = hex("24262D"); BorderSizePixel = 0; ZIndex = 5;
	});
	local ThemeBody = self:CreateInstance("Frame", {
		Parent = ThemeMid;
		Position = NewUdim2(0, 1, 0, 1); Size = NewUdim2(1, -2, 1, -2);
		BackgroundColor3 = FromRgb(255, 255, 255); BorderSizePixel = 0; ZIndex = 6;
	});
	self:CreateInstance("UIGradient", {
		Parent = ThemeBody; Rotation = 90;
		Color = NewColorSequence(hex("131418"), hex("17181D"));
	});
	local ThemeLbl = self:CreateInstance("TextLabel", {
		Parent = ThemeBody;
		Position = NewUdim2(0, 6, 0, -1); Size = NewUdim2(1, -18, 1, 0);
		BackgroundTransparency = 1;
		FontFace = Library.Fonts.title;
		Text = self.ThemeName or "Default";
		TextColor3 = FromRgb(255, 255, 255);
		TextSize = 9;
		TextXAlignment = Enum.TextXAlignment.Left;
		TextYAlignment = Enum.TextYAlignment.Center;
		ZIndex = 7;
	});
	local ThemeArrow = self:CreateInstance("TextLabel", {
		Parent = ThemeBody;
		AnchorPoint = NewVector2(1, 0.5);
		Position = NewUdim2(1, -4, 0.5, 0); Size = FromOffset(8, 9);
		BackgroundTransparency = 1;
		FontFace = Library.Fonts.title;
		Text = "v"; TextColor3 = hex("B4B4B4");
		TextSize = 9;
		TextXAlignment = Enum.TextXAlignment.Center;
		TextYAlignment = Enum.TextYAlignment.Center;
		ZIndex = 7;
	});
	local ThemeHit = self:CreateInstance("TextButton", {
		Parent = ThemeBg;
		Size = NewUdim2(1, 0, 1, 0);
		BackgroundTransparency = 1; AutoButtonColor = false; Text = ""; ZIndex = 8;
	});

	local ThemePopup = self:CreateInstance("Frame", {
		Name = "ThemePopup"; Parent = gui;
		BackgroundColor3 = hex("07080A"); BorderSizePixel = 0;
		Active = true;
		Visible = false; ClipsDescendants = true; ZIndex = 60;
	});
	local TpMid = self:CreateInstance("Frame", {
		Parent = ThemePopup;
		Position = NewUdim2(0, 1, 0, 1); Size = NewUdim2(1, -2, 1, -2);
		BackgroundColor3 = hex("24262D"); BorderSizePixel = 0; ZIndex = 61;
	});
	local TpInner = self:CreateInstance("Frame", {
		Parent = TpMid;
		Position = NewUdim2(0, 1, 0, 1); Size = NewUdim2(1, -2, 1, -2);
		BackgroundColor3 = FromRgb(255, 255, 255); BorderSizePixel = 0; ZIndex = 62;
	});
	self:CreateInstance("UIGradient", {
		Parent = TpInner; Rotation = 90;
		Color = NewColorSequence(hex("131418"), hex("17181D"));
	});
	local TpList = self:CreateInstance("Frame", {
		Parent = TpInner;
		Size = NewUdim2(1, 0, 1, 0);
		BackgroundTransparency = 1; ZIndex = 63;
	});
	self:CreateInstance("UIPadding", {
		Parent = TpList;
		PaddingTop = NewUdim(0, 4); PaddingBottom = NewUdim(0, 6);
	});
	self:CreateInstance("UIListLayout", {
		Parent = TpList;
		FillDirection = Enum.FillDirection.Vertical;
		SortOrder = Enum.SortOrder.LayoutOrder;
		Padding = NewUdim(0, 1);
	});

	local ThemeOpen = false;
	local ThemeAnimTween;
	local THEME_ANIM_TIME = 0.15;
	local function CloseTheme()
		ThemeOpen = false; ThemeArrow.Text = "v";
		if ThemeAnimTween then ThemeAnimTween:Cancel() end;
		local FullW = ThemePopup.AbsoluteSize.X;
		ThemeAnimTween = TweenService:Create(ThemePopup, NewTweenInfo(THEME_ANIM_TIME, Enum.EasingStyle.Quad, Enum.EasingDirection.Out), { Size = FromOffset(FullW, 0) });
		ThemeAnimTween:Play();
		ThemeAnimTween.Completed:Once(function()
			if not ThemeOpen then ThemePopup.Visible = false end;
		end);
	end;
	local function OpenTheme()
		ThemeOpen = true; ThemeArrow.Text = "^";
		local tp = ThemeBg.AbsolutePosition;
		local ts = ThemeBg.AbsoluteSize;
		local TargetH = #Library.Themes * 14 + 10;
		local px, py, sc = Library:GuiPoint(gui, tp.X, tp.Y + ts.Y + 2);
		ThemePopup.Position = NewUdim2(0, px, 0, py);
		ThemePopup.Size = FromOffset(ts.X / sc, 0);
		ThemePopup.Visible = true;
		if ThemeAnimTween then ThemeAnimTween:Cancel() end;
		ThemeAnimTween = TweenService:Create(ThemePopup, NewTweenInfo(THEME_ANIM_TIME, Enum.EasingStyle.Quad, Enum.EasingDirection.Out), { Size = FromOffset(ts.X / sc, TargetH) });
		ThemeAnimTween:Play();
	end;

	self.ThemeDots = self.ThemeDots or {};
	for i, theme in Library.Themes do
		local row = self:CreateInstance("TextButton", {
			Parent = TpList;
			Size = NewUdim2(1, 0, 0, 13);
			BackgroundTransparency = 1; AutoButtonColor = false; Text = "";
			LayoutOrder = i; ZIndex = 64;
		});
		local lbl = self:CreateInstance("TextLabel", {
			Parent = row;
			Position = NewUdim2(0, 6, 0, 0); Size = NewUdim2(1, -22, 1, 0);
			BackgroundTransparency = 1;
			FontFace = Library.Fonts.title;
			Text = theme.name;
			TextColor3 = hex("B4B4B4");
			TextSize = 9;
			TextXAlignment = Enum.TextXAlignment.Left;
			TextYAlignment = Enum.TextYAlignment.Center;
			ZIndex = 65;
		});
		local dot = self:CreateInstance("Frame", {
			Name = "ThemeDot";
			Parent = row;
			AnchorPoint = NewVector2(1, 0.5);
			Position = NewUdim2(1, -6, 0.5, 0);
			Size = FromOffset(8, 8);
			BorderSizePixel = 0;
			ZIndex = 65;
		});
		dot.BackgroundColor3 = theme.accent;
		insert(self.ThemeDots, { frame = dot, color = theme.accent });
		LibRef:Connection(row.MouseEnter, function() lbl.TextColor3 = FromRgb(255, 255, 255) end);
		LibRef:Connection(row.MouseLeave, function() lbl.TextColor3 = hex("B4B4B4") end);
		LibRef:Connection(row.MouseButton1Click, function()
			self.ThemeName = theme.name;
			Library.Flags["appearance.theme"] = theme.name;
			ThemeLbl.Text = theme.name;
			SetColor("accent", theme.accent);
			if theme.shade then SetColor("shade", theme.shade) end;
			if theme.bg then
				ApplyThemeBg(theme.bg);
				SetColor("bg", theme.bg);
			end;
			CloseTheme();
		end);
	end;

	self:Connection(ThemeHit.MouseButton1Click, function()
		if ThemeOpen then CloseTheme() else OpenTheme() end;
	end);
	self:Connection(UserInputService.InputBegan, function(input)
		if not ThemeOpen then return end;
		if input.UserInputType ~= Enum.UserInputType.MouseButton1 then return end;
		local mx, my = Library:MousePoint(gui, input);
		if not Library:PointInObject(ThemePopup, mx, my, 2) and not Library:PointInObject(ThemeBg, mx, my, 2) then CloseTheme() end;
	end);

	local DimRow = MakeRow("Menu dim", 18);
	local DimT;
	DimT = MakeToggle(DimRow, self.MenuDim == true, function(v)
		self.MenuDim = v;
		Library.Flags["appearance.MenuDim"] = v;
		if self.FixDim then self:FixDim() end;
	end);
	Library:RegisterFlag("appearance.MenuDim", self.MenuDim == true, function(v) DimT.set(v) end);

	local DimOpacityRow = MakeRow("Dim opacity", 26);
	local DimTrack = self:CreateInstance("Frame", {
		Parent = DimOpacityRow;
		AnchorPoint = NewVector2(1, 0.5);
		Position = NewUdim2(1, 0, 0.5, 0);
		Size = FromOffset(82, 12);
		BackgroundColor3 = hex("07080A"); BorderSizePixel = 0; ZIndex = 4;
	});
	local DimTrackMid = self:CreateInstance("Frame", {
		Parent = DimTrack;
		Position = NewUdim2(0, 1, 0, 1); Size = NewUdim2(1, -2, 1, -2);
		BackgroundColor3 = hex("1C1D23"); BorderSizePixel = 0; ZIndex = 5;
	});
	local DimFill = self:CreateInstance("Frame", {
		Parent = DimTrackMid;
		Size = NewUdim2(0.55, 0, 1, 0);
		BackgroundColor3 = hex("98BCFF");
		BorderSizePixel = 0; ZIndex = 6;
	});
	local DimHit = self:CreateInstance("TextButton", {
		Parent = DimTrack;
		Size = NewUdim2(1, 0, 1, 0);
		BackgroundTransparency = 1; AutoButtonColor = false; Text = ""; ZIndex = 7;
	});
	local DimValue = self.MenuDimOpacity or 0.55;
	self.MenuDimOpacity = DimValue;
	local DimDragging = false;
	local DimTargetT = DimValue;
	local DimVisualT = DimValue;
	DimFill.Size = NewUdim2(DimVisualT, 0, 1, 0);
	local function DimUpdate(px)
		local abs = DimTrack.AbsolutePosition.X;
		local wide = MathMax(1, DimTrack.AbsoluteSize.X);
		local pct = MathClamp((px - abs) / wide, 0, 1);
		DimValue = pct;
		DimTargetT = pct;
		self.MenuDimOpacity = pct;
		Library.Flags["appearance.MenuDimOpacity"] = pct;
		if self.FixDim then self:FixDim() end;
	end;
	Library:RegisterFlag("appearance.MenuDimOpacity", DimValue, function(v)
		v = MathClamp(tonumber(v) or 0, 0, 1);
		DimValue = v;
		DimTargetT = v;
		self.MenuDimOpacity = v;
		if self.FixDim then self:FixDim() end;
	end);
	self:RegisterSliderTicker({
		Alive = function() return DimFill.Parent ~= nil end;
		Tick = function(dt)
			if MathAbs(DimTargetT - DimVisualT) < 0.0005 then
				if DimVisualT ~= DimTargetT then
					DimVisualT = DimTargetT;
					DimFill.Size = NewUdim2(DimVisualT, 0, 1, 0);
				end;
				return;
			end;
			local alpha = 1 - math.exp(-dt * 12);
			DimVisualT = DimVisualT + (DimTargetT - DimVisualT) * alpha;
			DimFill.Size = NewUdim2(DimVisualT, 0, 1, 0);
		end;
	});
	self:Connection(DimHit.InputBegan, function(input)
		if input.UserInputType == Enum.UserInputType.MouseButton1 then
			DimDragging = true; DimUpdate(input.Position.X);
		end;
	end);
	self:Connection(UserInputService.InputChanged, function(input)
		if DimDragging and input.UserInputType == Enum.UserInputType.MouseMovement then
			DimUpdate(input.Position.X);
		end;
	end);
	self:Connection(UserInputService.InputEnded, function(input)
		if input.UserInputType == Enum.UserInputType.MouseButton1 then DimDragging = false end;
	end);

	local AnonRow = MakeRow("Anonymous", 18);
	local AnonT;
	AnonT = MakeToggle(AnonRow, self.Anonymous == true, function(v)
		self.Anonymous = v;
		Library.Flags["appearance.anonymous"] = v;
		if typeof(self.CurrentWatermark) == "table" and self.CurrentWatermark.Labels then
			-- Mask local player name in watermark
			for i, seg in self.CurrentWatermark.Segments do
				if seg == LocalPlayer.Name then
					self.CurrentWatermark.Labels[i].Text = v and "hidden" or seg;
				end;
			end;
		end;
	end);
	Library:RegisterFlag("appearance.anonymous", self.Anonymous == true, function(v) AnonT.set(v) end);

	local KeepDockRow = MakeRow("Keep dock open", 18);
	local KeepDockT;
	KeepDockT = MakeToggle(KeepDockRow, Library.Flags["appearance.KeepDockOpen"] == true, function(v)
		Library.Flags["appearance.KeepDockOpen"] = v;
	end);
	Library:RegisterFlag("appearance.KeepDockOpen", Library.Flags["appearance.KeepDockOpen"] == true, function(v) KeepDockT.set(v == true) end);

	local function BindText(k)
		if k == nil then return "-" end;
		local n = Library.KeyNames[k];
		if n then return n end;
		return (tostring(k):gsub("Enum.KeyCode.", "")):gsub("Enum.UserInputType.", "");
	end;
	local function MakeBindRow(LabelText, StateKey, DefaultKey, OnMatch)
		local FlagName = "appearance." .. StateKey;
		local row = MakeRow(LabelText, 18);
		local btn = self:CreateInstance("TextButton", {
			Parent = row;
			AnchorPoint = NewVector2(1, 0.5);
			Position = NewUdim2(1, 0, 0.5, 0);
			Size = FromOffset(56, 16);
			BackgroundColor3 = hex("07080A"); BorderSizePixel = 0;
			AutoButtonColor = false; Text = ""; ZIndex = 4;
		});
		self:CreateInstance("Frame", {
			Parent = btn;
			Position = NewUdim2(0, 1, 0, 1); Size = NewUdim2(1, -2, 1, -2);
			BackgroundColor3 = hex("24262D"); BorderSizePixel = 0; ZIndex = 5;
		});
		local BodyF = self:CreateInstance("Frame", {
			Parent = btn;
			Position = NewUdim2(0, 2, 0, 2); Size = NewUdim2(1, -4, 1, -4);
			BackgroundColor3 = FromRgb(255, 255, 255); BorderSizePixel = 0; ZIndex = 6;
		});
		self:CreateInstance("UIGradient", {
			Parent = BodyF; Rotation = 90;
			Color = NewColorSequence(hex("131418"), hex("17181D"));
		});
		local lbl = self:CreateInstance("TextLabel", {
			Parent = BodyF;
			Size = NewUdim2(1, 0, 1, 0);
			BackgroundTransparency = 1;
			FontFace = Library.Fonts.title;
			TextColor3 = FromRgb(255, 255, 255);
			TextSize = 9;
			TextXAlignment = Enum.TextXAlignment.Center;
			TextYAlignment = Enum.TextYAlignment.Center;
			ZIndex = 7;
		});
		self:CreateInstance("UIPadding", {
			Parent = lbl;
			PaddingBottom = NewUdim(0, 2);
		});
		self:AnimateButton(btn);

		local CurrentBind = self[StateKey] or self.Flags[FlagName] or DefaultKey;
		self[StateKey] = CurrentBind;
		self.Flags[FlagName] = CurrentBind;
		local listening = false;
		lbl.Text = BindText(CurrentBind);
		self:Connection(btn.MouseButton1Click, function()
			if listening then return end;
			listening = true; lbl.Text = "...";
		end);
		self:Connection(UserInputService.InputBegan, function(input, gpe)
			if listening then
				if input.KeyCode == Enum.KeyCode.Escape then
					CurrentBind = nil; self[StateKey] = nil;
					Library.Flags[FlagName] = nil;
					lbl.Text = BindText(CurrentBind);
					listening = false;
					return;
				end;
				if input.UserInputType == Enum.UserInputType.Keyboard then
					CurrentBind = input.KeyCode;
				elseif input.UserInputType == Enum.UserInputType.MouseButton1
					or input.UserInputType == Enum.UserInputType.MouseButton2
					or input.UserInputType == Enum.UserInputType.MouseButton3 then
					CurrentBind = input.UserInputType;
				else
					return;
				end;
				self[StateKey] = CurrentBind;
				Library.Flags[FlagName] = CurrentBind;
				lbl.Text = BindText(CurrentBind);
				listening = false;
				return;
			end;
			if UserInputService:GetFocusedTextBox() ~= nil or CurrentBind == nil then return end;
			local match = (input.UserInputType == Enum.UserInputType.Keyboard and input.KeyCode == CurrentBind)
				or (input.UserInputType == CurrentBind);
			if not match then return end;
			OnMatch();
		end);
		Library:RegisterFlag(FlagName, CurrentBind, function(v)
			CurrentBind = v;
			self[StateKey] = v;
			lbl.Text = BindText(v);
		end);
	end;

	MakeBindRow("Menu bind", "MenuBind", Enum.KeyCode.Insert, function()
		local win = self.CurrentWindow;
		local TargetState = not (win and win.Gui and win.Gui.Enabled);
		if win and win.Gui then
			if typeof(win.SetVisible) == "function" then win:SetVisible(TargetState) else win.Gui.Enabled = TargetState end;
		end;
		for _, key in { "CurrentEspPreview", "CurrentConfigs", "CurrentPlayerList", "CurrentAppearance", "CurrentDock", "CurrentLuaEditor", "CurrentQuestPanel" } do
			local p = self[key];
			if typeof(p) == "table" and p.Gui then
				if TargetState then
					local saved = self.Flags[p.WidgetFlag];
					if saved and saved.Visible == true then
						if typeof(p.SetVisible) == "function" then p:SetVisible(true) else p.Gui.Enabled = true end;
					end;
				else
					if not (key == "CurrentDock" and self.Flags["appearance.KeepDockOpen"] == true) then
						self:SetWidgetVisible(p, false, true);
					end;
				end;
			end;
		end;
		if self.FixDim then self:FixDim() end;
		if self.CurrentDock and self.CurrentDock.RefreshBtns then self.CurrentDock:RefreshBtns() end;
	end);

	local WatermarkRow = MakeRow("Watermark", 18);
	if self.WatermarkVisible == nil then self.WatermarkVisible = true end;
	local WmT;
	WmT = MakeToggle(WatermarkRow, self.WatermarkVisible == true, function(v)
		self.WatermarkVisible = v;
		Library.Flags["appearance.WatermarkVisible"] = v;
		local p = self.CurrentWatermark;
		if typeof(p) == "table" and p.Gui then p:SetVisible(v) end;
	end);
	Library:RegisterFlag("appearance.WatermarkVisible", self.WatermarkVisible == true, function(v) WmT.set(v) end);

	local KblistRow = MakeRow("Keybind list", 18);
	if self.KeybindListVisible == nil then self.KeybindListVisible = true end;
	local KblT;
	KblT = MakeToggle(KblistRow, self.KeybindListVisible == true, function(v)
		self.KeybindListVisible = v;
		Library.Flags["appearance.KeybindListVisible"] = v;
		local p = self.CurrentKeybindList;
		if typeof(p) == "table" and p.Gui then p:SetVisible(v) end;
	end);
	Library:RegisterFlag("appearance.KeybindListVisible", self.KeybindListVisible == true, function(v) KblT.set(v) end);

	local ArrayRow = MakeRow("Array list", 18);
	if self.ArrayListVisible == nil then self.ArrayListVisible = false end;
	local ArrT;
	ArrT = MakeToggle(ArrayRow, self.ArrayListVisible == true, function(v)
		self.ArrayListVisible = v;
		Library.Flags["appearance.ArrayListVisible"] = v;
		Library:SetArrayListVisible(v);
	end);
	Library:RegisterFlag("appearance.ArrayListVisible", self.ArrayListVisible == true, function(v) ArrT.set(v) end);

	self:Draggable(outer, header);

	local panel = { Gui = gui, Outer = outer };
	function panel:SetVisible(on) Library:SetWidgetVisible(self, on) end;
	function panel:Destroy()
		if self.Gui and self.Gui.Parent then self.Gui:Destroy() end;
		if Library.CurrentAppearance == panel then Library.CurrentAppearance = nil end;
	end;

	self.CurrentAppearance = panel;
	self:TrackWidget(panel, "Appearance");
	return panel;
end;

--// Dock (screen-wide top bar)
function Library:Dock(opts)
	opts = typeof(opts) == "table" and opts or {};
	local text = tostring(opts.text or opts.Text or "LandryHaxx");

	if self.CurrentDock and typeof(self.CurrentDock.Gui) == "Instance" and self.CurrentDock.Gui.Parent then
		self.CurrentDock.Gui:Destroy();
	end;

	local gui = self:CreateInstance("ScreenGui", {
		Name = "\0";
		Parent = (gethui and gethui()) or CoreGui;
		Enabled = true;
		DisplayOrder = 999;
		IgnoreGuiInset = true;
		ResetOnSpawn = false;
		ZIndexBehavior = Enum.ZIndexBehavior.Global;
	});

	self:CreateInstance("Frame", {
		Name = "Dim";
		Parent = gui;
		Position = NewUdim2(0, 0, 0, 0);
		Size = NewUdim2(1, 0, 1, 0);
		BackgroundColor3 = FromRgb(0, 0, 0);
		BackgroundTransparency = 0.85;
		BorderSizePixel = 0;
		ZIndex = 0;
	});

	local outer = self:CreateInstance("Frame", {
		Name = "Dock";
		Parent = gui;
		Position = NewUdim2(0, 0, 0, 0);
		Size = NewUdim2(1, 0, 0, 22);
		BackgroundColor3 = FromRgb(255, 255, 255);
		BorderSizePixel = 0;
		ZIndex = 1;
	});
	self:CreateInstance("UIGradient", {
		Parent = outer; Rotation = 90;
		Color = NewColorSequence(hex("131418"), hex("17181D"));
	});

	self:CreateInstance("Frame", {
		Name = "AccentLine";
		Parent = outer;
		Position = NewUdim2(0, 0, 1, -4);
		Size = NewUdim2(1, 0, 0, 1);
		BackgroundColor3 = hex("98BCFF");
		BorderSizePixel = 0;
		ZIndex = 2;
	});
	self:CreateInstance("Frame", {
		Name = "AccentShade";
		Parent = outer;
		Position = NewUdim2(0, 0, 1, -3);
		Size = NewUdim2(1, 0, 0, 1);
		BackgroundColor3 = hex("6E8CC8");
		BorderSizePixel = 0;
		ZIndex = 2;
	});
	self:CreateInstance("Frame", {
		Name = "OutlineGray";
		Parent = outer;
		Position = NewUdim2(0, 0, 1, -2);
		Size = NewUdim2(1, 0, 0, 1);
		BackgroundColor3 = hex("24262D");
		BorderSizePixel = 0;
		ZIndex = 2;
	});
	self:CreateInstance("Frame", {
		Name = "OutlineBlack";
		Parent = outer;
		Position = NewUdim2(0, 0, 1, -1);
		Size = NewUdim2(1, 0, 0, 1);
		BackgroundColor3 = hex("07080A");
		BorderSizePixel = 0;
		ZIndex = 2;
	});

	local LeftStrip = self:CreateInstance("Frame", {
		Name = "LeftStrip"; Parent = outer;
		Position = NewUdim2(0, 8, 0, 0);
		Size = NewUdim2(1, -16, 1, -5);
		BackgroundTransparency = 1;
		ZIndex = 3;
	});
	self:CreateInstance("UIListLayout", {
		Parent = LeftStrip;
		FillDirection = Enum.FillDirection.Horizontal;
		VerticalAlignment = Enum.VerticalAlignment.Center;
		SortOrder = Enum.SortOrder.LayoutOrder;
		Padding = NewUdim(0, 12);
	});

	local label = self:CreateInstance("TextLabel", {
		Name = "Label";
		Parent = LeftStrip;
		Size = NewUdim2(0, 0, 1, 0);
		AutomaticSize = Enum.AutomaticSize.X;
		BackgroundTransparency = 1;
		FontFace = Library.Fonts.title;
		Text = text;
		TextColor3 = FromRgb(255, 255, 255);
		TextSize = 9;
		TextXAlignment = Enum.TextXAlignment.Left;
		TextYAlignment = Enum.TextYAlignment.Center;
		LayoutOrder = 1;
		ZIndex = 3;
	});

	local BtnStrip = self:CreateInstance("Frame", {
		Name = "BtnStrip"; Parent = LeftStrip;
		Size = NewUdim2(0, 0, 0, 14);
		AutomaticSize = Enum.AutomaticSize.X;
		BackgroundTransparency = 1;
		LayoutOrder = 2;
		ZIndex = 3;
	});
	self:CreateInstance("UIListLayout", {
		Parent = BtnStrip;
		FillDirection = Enum.FillDirection.Horizontal;
		VerticalAlignment = Enum.VerticalAlignment.Center;
		SortOrder = Enum.SortOrder.LayoutOrder;
		Padding = NewUdim(0, 4);
	});

	local LibRef = self;
	local BtnCount = 0;
	local function MakeDockBtn(LabelText, StateKey, Optional)
		BtnCount = BtnCount + 1;
		local btn = LibRef:CreateInstance("TextButton", {
			Name = "DockBtn_" .. LabelText;
			Parent = BtnStrip;
			Size = NewUdim2(0, 0, 1, 0);
			AutomaticSize = Enum.AutomaticSize.X;
			BackgroundTransparency = 1;
			AutoButtonColor = false;
			FontFace = Library.Fonts.title;
			Text = LabelText;
			TextColor3 = Library.AccentColor or hex("98BCFF");
			TextSize = 9;
			TextXAlignment = Enum.TextXAlignment.Center;
			TextYAlignment = Enum.TextYAlignment.Center;
			LayoutOrder = BtnCount; ZIndex = 4;
		});
		local scale = LibRef:CreateInstance("UIScale", {
			Parent = btn;
			Scale = 1;
		});
		local BtnTween = NewTweenInfo(0.12, Enum.EasingStyle.Quad, Enum.EasingDirection.Out);
		local function refresh()
			local p = LibRef[StateKey];
			if Optional then
				local has = typeof(p) == "table" and p.Gui ~= nil;
				if btn.Visible ~= has then btn.Visible = has end;
				if not has then return end;
			end;
			local enabled;
			if typeof(p) == "table" and p.Gui then
				if p.Visible ~= nil then
					enabled = p.Visible == true;
				else
					enabled = p.Gui.Enabled == true;
				end;
			else
				enabled = true;
			end;
			local TargetColor = enabled and (Library.AccentColor or hex("98BCFF")) or hex("5F636C");
			LibRef:Tween(btn, BtnTween, { TextColor3 = TargetColor }):Play();
		end;
		refresh();
		LibRef:Connection(btn.MouseEnter, function()
			LibRef:Tween(scale, BtnTween, { Scale = 1.05 }):Play();
		end);
		LibRef:Connection(btn.MouseLeave, function()
			LibRef:Tween(scale, BtnTween, { Scale = 1 }):Play();
		end);
		LibRef:Connection(btn.MouseButton1Down, function()
			LibRef:Tween(scale, NewTweenInfo(0.07, Enum.EasingStyle.Quad, Enum.EasingDirection.Out), { Scale = 0.94 }):Play();
		end);
		LibRef:Connection(btn.MouseButton1Up, function()
			LibRef:Tween(scale, BtnTween, { Scale = 1.05 }):Play();
		end);
		LibRef:Connection(btn.MouseButton1Click, function()
			local p = LibRef[StateKey];
			if typeof(p) == "table" and p.Gui then
				local CurrentlyVisible;
				if p.Visible ~= nil then
					CurrentlyVisible = p.Visible == true;
				else
					CurrentlyVisible = p.Gui.Enabled == true;
				end;
				if typeof(p.SetVisible) == "function" then
					p:SetVisible(not CurrentlyVisible);
				else
					p.Gui.Enabled = not CurrentlyVisible;
					LibRef:SaveWidgetState(p);
				end;
				refresh();
				if StateKey == "CurrentWindow" and LibRef.FixDim then
					LibRef:FixDim();
				end;
			end;
		end);
		return { button = btn, Refresh = refresh };
	end;

	local DockBtns = {
		MakeDockBtn("Window",     "CurrentWindow");
		MakeDockBtn("Watermark",  "CurrentWatermark");
		MakeDockBtn("Keybinds",   "CurrentKeybindList");
		MakeDockBtn("ESP",        "CurrentEspPreview");
		MakeDockBtn("Players",    "CurrentPlayerList");
		MakeDockBtn("Configs",    "CurrentConfigs");
		MakeDockBtn("Appearance", "CurrentAppearance");
		MakeDockBtn("Lua",        "CurrentLuaEditor");
		MakeDockBtn("Activity",   "CurrentActivity", true);
		MakeDockBtn("Map",        "CurrentMapPanel", true);
		MakeDockBtn("Quests",     "CurrentQuestPanel", true);
		MakeDockBtn("Build",      "CurrentBuildPanel", true);
		MakeDockBtn("Debugger",   "CurrentDebuggerPanel", true);
	};

	task.defer(function()
		for _, b in DockBtns do b.Refresh() end;
	end);

	local dock = { Gui = gui, Outer = outer, Label = label, Btns = DockBtns };

	function dock:SetText(NewText)
		self.Label.Text = tostring(NewText);
	end;

	function dock:RefreshBtns()
		for _, b in self.Btns do b.Refresh() end;
	end;

	function dock:SetVisible(on)
		Library:SetWidgetVisible(self, on);
	end;

	function dock:Destroy()
		if self.Gui and self.Gui.Parent then self.Gui:Destroy() end;
		if Library.CurrentDock == dock then Library.CurrentDock = nil end;
	end;

	self.CurrentDock = dock;
	self:TrackWidget(dock, "Dock");
	return dock;
end;

function Library:LuaEditor(opts)
	opts = typeof(opts) == "table" and opts or {};

	if typeof(self.CurrentLuaEditor) == "table" and typeof(self.CurrentLuaEditor.Gui) == "Instance" and self.CurrentLuaEditor.Gui.Parent then
		self.CurrentLuaEditor.Gui:Destroy();
	end;
	self.CurrentLuaEditor = nil;

	local w = tonumber(opts.width) or 500;
	local h = tonumber(opts.height) or 400;
	local TitleText = tostring(opts.title or "Lua");
	local folder = tostring(opts.folder or "LandryHaxx/Luas");

	if isfolder and not isfolder(folder) then
		pcall(function() makefolder(folder) end);
	end;

	local VpSize = camera.ViewportSize;
	local UiScale = self:ComputeUIScale();
	local DefaultX = MathClamp(tonumber(opts.x) or 1140, 0, MathMax(0, VpSize.X / UiScale - w));
	local DefaultY = MathClamp(tonumber(opts.y) or 415, 0, MathMax(0, VpSize.Y / UiScale - h));

	local gui = self:CreateInstance("ScreenGui", {
		Name = "\0";
		Parent = (gethui and gethui()) or CoreGui;
		Enabled = true;
		DisplayOrder = self.WidgetDisplayOrder or 1002;
		IgnoreGuiInset = true;
		ResetOnSpawn = false;
		ZIndexBehavior = Enum.ZIndexBehavior.Global;
	});
	self:ApplyScale(gui);

	local outer = self:CreateInstance("Frame", {
		Name = "Outer";
		Parent = gui;
		Position = NewUdim2(0, DefaultX, 0, DefaultY);
		Size = FromOffset(w, h);
		BackgroundColor3 = hex("07080A");
		BorderSizePixel = 0;
		Active = true;
	});
	self:CreateInstance("ImageLabel", {
		Name = "Glow";
		Parent = outer;
		AnchorPoint = NewVector2(0.5, 0.5);
		Position = NewUdim2(0.5, 0, 0.5, 0);
		Size = NewUdim2(1, 30, 1, 30);
		BackgroundTransparency = 1;
		Image = "rbxassetid://18245826428";
		ImageColor3 = hex("98BCFF");
		ImageTransparency = 0.86;
		ScaleType = Enum.ScaleType.Slice;
		SliceCenter = RectNew(21, 21, 79, 79);
		ZIndex = -1;
	});
	local inner = self:CreateInstance("Frame", {
		Name = "Inner";
		Parent = outer;
		Position = NewUdim2(0, 1, 0, 1);
		Size = NewUdim2(1, -2, 1, -2);
		BackgroundColor3 = hex("24262D");
		BorderSizePixel = 0;
	});
	local main = self:CreateInstance("Frame", {
		Name = "Main";
		Parent = inner;
		Position = NewUdim2(0, 1, 0, 1);
		Size = NewUdim2(1, -2, 1, -2);
		BackgroundColor3 = FromRgb(255, 255, 255);
		BorderSizePixel = 0;
	});
	self:CreateInstance("UIGradient", {
		Parent = main; Rotation = 90;
		Color = NewColorSequence(hex("131418"), hex("17181D"));
	});
	self:CreateInstance("Frame", {
		Name = "TopAccent"; Parent = main;
		Size = NewUdim2(1, 0, 0, 1);
		BackgroundColor3 = hex("98BCFF");
		BorderSizePixel = 0; ZIndex = 2;
	});
	self:CreateInstance("Frame", {
		Name = "TopAccentShade"; Parent = main;
		Position = NewUdim2(0, 0, 0, 1);
		Size = NewUdim2(1, 0, 0, 1);
		BackgroundColor3 = hex("6E8CC8");
		BorderSizePixel = 0; ZIndex = 2;
	});
	local HeaderDrag = self:CreateInstance("Frame", {
		Name = "HeaderDrag"; Parent = main;
		Position = NewUdim2(0, 0, 0, 0);
		Size = NewUdim2(1, 0, 0, 20);
		BackgroundTransparency = 1; Active = true;
		ZIndex = 2;
	});

	local TabStrip = self:CreateInstance("Frame", {
		Name = "TabStrip"; Parent = main;
		Position = NewUdim2(0, 10, 0, 5);
		Size = NewUdim2(1, -50, 0, 14);
		BackgroundTransparency = 1;
		ZIndex = 4;
	});
	self:CreateInstance("UIListLayout", {
		Parent = TabStrip;
		FillDirection = Enum.FillDirection.Horizontal;
		SortOrder = Enum.SortOrder.LayoutOrder;
		Padding = NewUdim(0, 10);
		VerticalAlignment = Enum.VerticalAlignment.Center;
	});

	local LuaTabs = {};
	local ActiveLuaTab;
	local TabColorTween = NewTweenInfo(0.15, Enum.EasingStyle.Quad, Enum.EasingDirection.Out);
	local function SetActiveLuaTab(tab)
		if ActiveLuaTab == tab then return end;
		if ActiveLuaTab then
			if ActiveLuaTab.Content then ActiveLuaTab.Content.Visible = false; end;
			if typeof(ActiveLuaTab.Label) == "Instance" and ActiveLuaTab.Label.Parent then
				Library:Tween(ActiveLuaTab.Label, TabColorTween, { TextColor3 = hex("8A8A92") }):Play();
			end;
		end;
		ActiveLuaTab = tab;
		if not tab then return end;
		if tab.Content then tab.Content.Visible = true; end;
		if typeof(tab.Label) == "Instance" and tab.Label.Parent then
			Library:Tween(tab.Label, TabColorTween, { TextColor3 = Library.AccentColor or hex("98BCFF") }):Play();
		end;
	end;

	local TitleLabel = self:CreateInstance("TextLabel", {
		Name = "Title"; Parent = TabStrip;
		AutomaticSize = Enum.AutomaticSize.X;
		Size = NewUdim2(0, 0, 0, 14);
		BackgroundTransparency = 1;
		FontFace = Library.Fonts.title;
		Text = TitleText;
		TextColor3 = Library.AccentColor or hex("98BCFF");
		TextSize = 9;
		TextXAlignment = Enum.TextXAlignment.Left;
		TextYAlignment = Enum.TextYAlignment.Center;
		LayoutOrder = 1; ZIndex = 5;
	});
	local TitleHit = self:CreateInstance("TextButton", {
		Parent = TitleLabel;
		Size = NewUdim2(1, 0, 1, 0);
		BackgroundTransparency = 1; AutoButtonColor = false; Text = "";
		ZIndex = 6;
	});

	local EditorContent = self:CreateInstance("Frame", {
		Name = "EditorContent"; Parent = main;
		Size = NewUdim2(1, 0, 1, 0);
		BackgroundTransparency = 1;
		ZIndex = 2;
	});

	local StatusLabel = self:CreateInstance("TextLabel", {
		Name = "Status"; Parent = EditorContent;
		AnchorPoint = NewVector2(1, 0);
		Position = NewUdim2(1, -8, 0, 5);
		Size = NewUdim2(0, 0, 0, 14);
		AutomaticSize = Enum.AutomaticSize.X;
		BackgroundTransparency = 1;
		FontFace = Library.Fonts.title;
		Text = "Idle";
		TextColor3 = hex("8A8A92");
		TextSize = 9;
		TextXAlignment = Enum.TextXAlignment.Right;
		ZIndex = 3;
	});

	local function SetStatus(text, color)
		StatusLabel.Text = text;
		StatusLabel.TextColor3 = color or hex("8A8A92");
	end;

	--// Menu bar (Editor / File)
	local MenuBar = self:CreateInstance("Frame", {
		Name = "MenuBar"; Parent = EditorContent;
		Position = NewUdim2(0, 6, 0, 22);
		Size = NewUdim2(1, -12, 0, 16);
		BackgroundTransparency = 1;
		ZIndex = 6;
	});
	self:CreateInstance("UIListLayout", {
		Parent = MenuBar;
		FillDirection = Enum.FillDirection.Horizontal;
		SortOrder = Enum.SortOrder.LayoutOrder;
		Padding = NewUdim(0, 6);
		VerticalAlignment = Enum.VerticalAlignment.Center;
	});
	local EditorMenu = self:ContextMenu(gui);
	local DoNew, DoSave, DoLoad, DoExec, DoFileBrowser;
	local NextUntitledNameFn;
	local function MakeMenuButton(label, items, LayoutOrder)
		local btn = self:CreateInstance("TextButton", {
			Name = "Menu_" .. label; Parent = MenuBar;
			Size = NewUdim2(0, 0, 1, 0);
			AutomaticSize = Enum.AutomaticSize.X;
			BackgroundTransparency = 1; AutoButtonColor = false;
			FontFace = Library.Fonts.title;
			Text = label;
			TextColor3 = hex("B4B4B4");
			TextSize = 9;
			TextXAlignment = Enum.TextXAlignment.Center;
			TextYAlignment = Enum.TextYAlignment.Center;
			LayoutOrder = LayoutOrder; ZIndex = 7;
		});
		local BtnTween = NewTweenInfo(0.12, Enum.EasingStyle.Quad, Enum.EasingDirection.Out);
		self:Connection(btn.MouseEnter, function() self:Tween(btn, BtnTween, { TextColor3 = FromRgb(255, 255, 255) }):Play() end);
		self:Connection(btn.MouseLeave, function() self:Tween(btn, BtnTween, { TextColor3 = hex("B4B4B4") }):Play() end);
		self:Connection(btn.MouseButton1Click, function()
			local ap = btn.AbsolutePosition;
			EditorMenu.Open(ap.X, ap.Y + btn.AbsoluteSize.Y, items);
		end);
		return btn;
	end;

	local CurrentFile = nil;
	local CurrentPath = nil;
	local CodeBox;

	local function BuildButton(label, parent, LayoutOrder, width)
		local BtnOuter = self:CreateInstance("Frame", {
			Name = "Btn_" .. label; Parent = parent;
			Size = FromOffset(width or 56, 18);
			LayoutOrder = LayoutOrder;
			BackgroundColor3 = hex("07080A");
			BorderSizePixel = 0; ZIndex = 3;
		});
		local BtnMid = self:CreateInstance("Frame", {
			Parent = BtnOuter;
			Position = NewUdim2(0, 1, 0, 1); Size = NewUdim2(1, -2, 1, -2);
			BackgroundColor3 = hex("24262D");
			BorderSizePixel = 0; ZIndex = 3;
		});
		local BtnBody = self:CreateInstance("Frame", {
			Parent = BtnMid;
			Position = NewUdim2(0, 1, 0, 1); Size = NewUdim2(1, -2, 1, -2);
			BackgroundColor3 = FromRgb(255, 255, 255);
			BorderSizePixel = 0; ZIndex = 4;
		});
		self:CreateInstance("UIGradient", {
			Parent = BtnBody; Rotation = 90;
			Color = NewColorSequence(hex("131418"), hex("17181D"));
		});
		local BtnLabel = self:CreateInstance("TextLabel", {
			Parent = BtnBody;
			Size = NewUdim2(1, 0, 1, 0);
			BackgroundTransparency = 1;
			FontFace = Library.Fonts.title;
			Text = label;
			TextColor3 = hex("B4B4B4");
			TextSize = 9;
			TextXAlignment = Enum.TextXAlignment.Center;
			ZIndex = 5;
		});
		local BtnHit = self:CreateInstance("TextButton", {
			Parent = BtnOuter;
			Size = NewUdim2(1, 0, 1, 0);
			BackgroundTransparency = 1; AutoButtonColor = false; Text = "";
			ZIndex = 6;
		});
		local BtnScale = self:CreateInstance("UIScale", { Parent = BtnOuter; Scale = 1 });
		local BtnHoverTween = NewTweenInfo(0.15, Enum.EasingStyle.Quad, Enum.EasingDirection.Out);
		local PressIn = NewTweenInfo(0.08, Enum.EasingStyle.Quad, Enum.EasingDirection.Out);
		local PressOut = NewTweenInfo(0.16, Enum.EasingStyle.Back, Enum.EasingDirection.Out);
		self:Connection(BtnHit.MouseEnter, function() self:Tween(BtnLabel, BtnHoverTween, { TextColor3 = FromRgb(255, 255, 255) }):Play() end);
		self:Connection(BtnHit.MouseLeave, function()
			self:Tween(BtnLabel, BtnHoverTween, { TextColor3 = hex("B4B4B4") }):Play();
			self:Tween(BtnScale, PressOut, { Scale = 1 }):Play();
		end);
		self:Connection(BtnHit.MouseButton1Down, function() self:Tween(BtnScale, PressIn, { Scale = 0.94 }):Play() end);
		self:Connection(BtnHit.MouseButton1Up, function() self:Tween(BtnScale, PressOut, { Scale = 1 }):Play() end);
		return BtnOuter, BtnLabel, BtnHit;
	end;

	--// File helpers
	local function LoadFileContent(name)
		if not name then return end;
		CurrentFile = name;
		CurrentPath = folder .. "/" .. name;
		if isfile and isfile(CurrentPath) and readfile then
			local ok, content = pcall(readfile, CurrentPath);
			if ok then CodeBox.Text = content; SetStatus("Loaded " .. name, Library.AccentColor or hex("98BCFF")); return end;
		end;
		CodeBox.Text = "";
		SetStatus("New " .. name, hex("8A8A92"));
	end;

	local function OpenFileByPath(path)
		if typeof(path) ~= "string" or #path == 0 then return end;
		local ok, content = pcall(readfile, path);
		if ok and typeof(content) == "string" then
			CurrentPath = path;
			CurrentFile = tostring(path):match("[^/\\]+$") or "file";
			CodeBox.Text = content;
			SetStatus("Loaded " .. CurrentFile, Library.AccentColor or hex("98BCFF"));
			SetActiveLuaTab(EditorTab);
			return true;
		end;
		SetStatus("missing: " .. tostring(path), hex("EB4B4B"));
		Library:Notify({ Text = "Missing: " .. tostring(path) });
		return false;
	end;

	local function RenamePath(old, new)
		if typeof(renamefile) == "function" then return pcall(renamefile, old, new); end;
		if typeof(moverfile) == "function" then return pcall(moverfile, old, new); end;
		if isfolder and isfolder(old) then
			if typeof(makefolder) ~= "function" or typeof(listfiles) ~= "function" then return false end;
			local ok = pcall(makefolder, new);
			if not ok then return false end;
			for _, p in listfiles(old) do
				local dest = new .. tostring(p):sub(#tostring(old) + 1);
				local o2 = RenamePath(p, dest);
				if not o2 then return false end;
			end;
			return pcall(delfolder, old);
		end;
		if not isfile or not isfile(old) then return false end;
		if typeof(writefile) ~= "function" or typeof(readfile) ~= "function" then return false end;
		local ok, content = pcall(readfile, old);
		if not ok then return false end;
		local w = pcall(writefile, new, content);
		if not w then return false end;
		return pcall(delfile, old);
	end;

	--// Bottom toolbar
	local BottomBar = self:CreateInstance("Frame", {
		Name = "BottomBar"; Parent = EditorContent;
		AnchorPoint = NewVector2(0, 1);
		Position = NewUdim2(0, 6, 1, -6);
		Size = NewUdim2(1, -12, 0, 18);
		BackgroundTransparency = 1;
		ZIndex = 3;
	});
	self:CreateInstance("UIListLayout", {
		Parent = BottomBar;
		FillDirection = Enum.FillDirection.Horizontal;
		SortOrder = Enum.SortOrder.LayoutOrder;
		Padding = NewUdim(0, 4);
	});

	local _, _, LoadHit = BuildButton("Load", BottomBar, 1);
	local _, _, SaveHit = BuildButton("Save", BottomBar, 2);
	local _, _, NewHit  = BuildButton("New",  BottomBar, 3);
	local _, _, ExecHit = BuildButton("Exec", BottomBar, 4);

	--// Code box -----
	local CodeOuter = self:CreateInstance("Frame", {
		Name = "CodeOuter"; Parent = EditorContent;
		Position = NewUdim2(0, 6, 0, 42);
		Size = NewUdim2(1, -12, 1, -70);
		BackgroundColor3 = hex("07080A");
		BorderSizePixel = 0; ZIndex = 3;
	});
	local CodeMid = self:CreateInstance("Frame", {
		Parent = CodeOuter;
		Position = NewUdim2(0, 1, 0, 1); Size = NewUdim2(1, -2, 1, -2);
		BackgroundColor3 = hex("24262D");
		BorderSizePixel = 0; ZIndex = 3;
	});
	local CodeBody = self:CreateInstance("Frame", {
		Parent = CodeMid;
		Position = NewUdim2(0, 1, 0, 1); Size = NewUdim2(1, -2, 1, -2);
		BackgroundColor3 = FromRgb(255, 255, 255);
		BorderSizePixel = 0; ZIndex = 4;
		ClipsDescendants = true;
	});
	self:CreateInstance("UIGradient", {
		Parent = CodeBody; Rotation = 90;
		Color = NewColorSequence(hex("131418"), hex("17181D"));
	});
	local CodeScroll = self:CreateInstance("ScrollingFrame", {
		Parent = CodeBody;
		Position = NewUdim2(0, 0, 0, 0);
		Size = NewUdim2(1, 0, 1, 0);
		BackgroundTransparency = 1;
		BorderSizePixel = 0;
		ScrollBarThickness = 2;
		ScrollBarImageColor3 = hex("98BCFF");
		CanvasSize = NewUdim2(0, 0, 0, 0);
		AutomaticCanvasSize = Enum.AutomaticSize.Y;
		ZIndex = 5;
	});

	local function LoadCodeFont()
		local dir  = "LandryHaxx/Fonts";
		local name = "CONSOLA";
		local url  = "https://github.com/cascade-v/44/raw/refs/heads/main/CONSOLA.TTF";
		local ttf  = dir .. "/" .. name .. ".ttf";
		local json = dir .. "/" .. name .. ".json";
		local ok, font = pcall(function()
			if isfolder and not isfolder(dir) then makefolder(dir) end;
			if not isfile(ttf) then writefile(ttf, game:HttpGet(url)) end;
			local asset = getcustomasset(ttf);
			if not isfile(json) then
				local family = string.format(
					'{"name":"%s","faces":[{"name":"Regular","weight":400,"style":"normal","assetId":"%s"}]}',
					name, asset
				);
				writefile(json, family);
			end;
			return Font.new(getcustomasset(json), Enum.FontWeight.Regular);
		end);
		if ok and font then return font end;
		return Library.Fonts.title;
	end;
	local CodeFont = LoadCodeFont();
	local CODE_TEXT_SIZE = 12;

	local SYN = {
		keyword = "C586C0";
		string = "CE9178";
		comment = "6A9955";
		number = "B5CEA8";
		func = "DCDCAA";
		global = "4FC1FF";
	};
	local SYN_KEYWORDS = {
		["and"] = true; ["break"] = true; ["do"] = true; ["else"] = true; ["elseif"] = true;
		["end"] = true; ["false"] = true; ["for"] = true; ["function"] = true; ["goto"] = true;
		["if"] = true; ["in"] = true; ["local"] = true; ["nil"] = true; ["not"] = true;
		["or"] = true; ["repeat"] = true; ["return"] = true; ["then"] = true; ["true"] = true;
		["until"] = true; ["while"] = true;
	};
	local SYN_GLOBALS = {
		["print"] = true; ["warn"] = true; ["error"] = true; ["pcall"] = true; ["xpcall"] = true;
		["require"] = true; ["type"] = true; ["typeof"] = true; ["tonumber"] = true; ["tostring"] = true;
		["ipairs"] = true; ["pairs"] = true; ["next"] = true; ["select"] = true; ["unpack"] = true;
		["table"] = true; ["string"] = true; ["math"] = true; ["os"] = true; ["io"] = true;
		["coroutine"] = true; ["game"] = true; ["workspace"] = true; ["script"] = true;
		["Instance"] = true; ["Vector2"] = true; ["Vector3"] = true; ["CFrame"] = true; ["Color3"] = true;
		["UDim"] = true; ["UDim2"] = true; ["Enum"] = true; ["TweenService"] = true;
		["UserInputService"] = true; ["task"] = true; ["wait"] = true; ["spawn"] = true; ["delay"] = true;
		["loadstring"] = true; ["load"] = true; ["debug"] = true;
		["readfile"] = true; ["writefile"] = true; ["listfiles"] = true; ["isfile"] = true;
		["isfolder"] = true; ["makefolder"] = true; ["delfolder"] = true; ["delfile"] = true;
		["appendfile"] = true; ["loadfile"] = true; ["dofile"] = true; ["getcustomasset"] = true;
		["gethui"] = true; ["getgenv"] = true; ["getrenv"] = true; ["hookfunction"] = true;
		["newcclosure"] = true; ["getnamecallmethod"] = true; ["getrawmetatable"] = true;
	};
	local SYN_COLORS = {
		comment = "6A9955";
		string = "CE9178";
		number = "B5CEA8";
		keyword = "C586C0";
		global = "4FC1FF";
		func = "DCDCAA";
	};
	local function EscapeRich(s)
		return (s:gsub("&", "&amp;"):gsub("<", "&lt;"):gsub(">", "&gt;"));
	end;
	local function HighlightLua(code)
		if typeof(code) ~= "string" or #code == 0 then return "" end;
		if #code > 300000 then return EscapeRich(code) end;
		local out = {};
		local i, len = 1, #code;
		while i <= len do
			local c = code:sub(i, i);
			if c == "-" and code:sub(i + 1, i + 1) == "-" then
				local start = i;
				local eq = 0;
				while code:sub(i + 2 + eq, i + 2 + eq) == "=" do eq += 1; end;
				if code:sub(i + 2, i + 2) == "[" and code:sub(i + 2 + eq, i + 2 + eq) == "[" then
					local close = "]" .. string.rep("=", eq) .. "]";
					local j = code:find(close, i + 3 + eq, true);
					i = (j and j + #close - 1) or len;
				else
					local j = code:find("\n", i + 2, true);
					i = (j and j) or (len + 1);
				end;
				insert(out, { code:sub(start, i - 1), "comment" });
				continue;
			end;
			if c == '"' or c == "'" then
				local q = c;
				local j = i + 1;
				while j <= len do
					local cc = code:sub(j, j);
					if cc == "\\" then
						j += 2;
					elseif cc == q then
						break;
					else
						j += 1;
					end;
				end;
				insert(out, { code:sub(i, j > len and len or j), "string" });
				i = (j > len and len + 1) or (j + 1);
				continue;
			end;
			if c == "[" then
				local eq = 0;
				while code:sub(i + 1 + eq, i + 1 + eq) == "=" do eq += 1; end;
				if code:sub(i + 1 + eq, i + 1 + eq) == "[" then
					local close = "]" .. string.rep("=", eq) .. "]";
					local j = code:find(close, i + 2 + eq, true);
					local e = (j and j + #close - 1) or len;
					insert(out, { code:sub(i, e), "string" });
					i = e + 1;
					continue;
				end;
			end;
			if c:match("%d") or (c == "." and code:sub(i + 1, i + 1):match("%d")) then
				local m = code:match("^0[xX][0-9a-fA-F]+", i)
					or code:match("^%d+%.?%d*[eE][+-]?%d+", i)
					or code:match("^%d+%.?%d*", i)
					or code:match("^%.%d+[eE][+-]?%d+", i)
					or code:match("^%.%d+", i);
				if m then
					insert(out, { m, "number" });
					i += #m;
					continue;
				end;
			end;
			if c:match("[A-Za-z_]") then
				local m = code:match("^[A-Za-z_][A-Za-z0-9_]*", i);
				if SYN_KEYWORDS[m] then
					insert(out, { m, "keyword" });
				elseif SYN_GLOBALS[m] then
					insert(out, { m, "global" });
				else
					local after = code:sub(i + #m, i + #m);
					local prev = i > 1 and code:sub(i - 1, i - 1) or "";
					if after == "(" or ((prev == "." or prev == ":") and after == "(") then
						insert(out, { m, "func" });
					else
						insert(out, { m });
					end;
				end;
				i += #m;
				continue;
			end;
			insert(out, { c });
			i += 1;
		end;
		local sb = {};
		local runBuf = {};
		local runCol;
		local function FlushRun()
			if #runBuf > 0 then
				local txt = concat(runBuf, "");
				if runCol then
					insert(sb, '<font color="#' .. runCol .. '">' .. txt .. '</font>');
				else
					insert(sb, txt);
				end;
				runBuf = {};
			end;
		end;
		for _, t in ipairs(out) do
			local txt = EscapeRich(t[1]);
			local col = t[2] and SYN_COLORS[t[2]];
			if col ~= runCol then
				FlushRun();
				runCol = col;
			end;
			insert(runBuf, txt);
		end;
		FlushRun();
		return concat(sb, "");
	end;

	CodeBox = self:CreateInstance("TextBox", {
		Name = "Input"; Parent = CodeScroll;
		NoFontScale = true;
		Position = NewUdim2(0, 6, 0, 4);
		Size = NewUdim2(1, -12, 0, 0);
		AutomaticSize = Enum.AutomaticSize.Y;
		BackgroundTransparency = 1;
		BorderSizePixel = 0;
		ClearTextOnFocus = false;
		MultiLine = true;
		TextWrapped = false;
		FontFace = CodeFont;
		Text = "";
		PlaceholderText = "-- your lua here";
		PlaceholderColor3 = hex("646464");
		TextColor3 = FromRgb(255, 255, 255);
		TextSize = CODE_TEXT_SIZE;
		TextXAlignment = Enum.TextXAlignment.Left;
		TextYAlignment = Enum.TextYAlignment.Top;
		ZIndex = 6;
	});
	local CodeOverlay = self:CreateInstance("TextLabel", {
		Name = "Highlight"; Parent = CodeScroll;
		NoFontScale = true;
		Position = NewUdim2(0, 6, 0, 4);
		Size = NewUdim2(1, -12, 0, 0);
		AutomaticSize = Enum.AutomaticSize.Y;
		BackgroundTransparency = 1;
		BorderSizePixel = 0;
		Text = "";
		RichText = true;
		FontFace = CodeFont;
		TextColor3 = hex("D4D4D4");
		TextSize = CODE_TEXT_SIZE;
		TextWrapped = false;
		TextXAlignment = Enum.TextXAlignment.Left;
		TextYAlignment = Enum.TextYAlignment.Top;
		ZIndex = 7;
	});
	local LastCode = "";
	local function RefreshCodeHighlight()
		local txt = CodeBox.Text;
		if txt ~= LastCode then
			LastCode = txt;
			CodeOverlay.Text = HighlightLua(txt);
			pcall(function()
				local mw = 100000;
				local measured = TextService:GetTextSize(txt, CODE_TEXT_SIZE, CodeFont, NewVector2(mw, mw));
				local w = MathMax(1, MathCeil(measured.X) + 12);
				CodeBox.Size = NewUdim2(0, w, 0, CodeBox.Size.Y.Offset);
				CodeOverlay.Size = NewUdim2(0, w, 0, CodeOverlay.Size.Y.Offset);
				CodeScroll.CanvasSize = NewUdim2(0, w, 0, CodeScroll.CanvasSize.Y.Offset);
			end);
		end;
	end;
	RefreshCodeHighlight();
	task.spawn(function()
		while CodeOverlay and CodeOverlay.Parent do
			task.wait();
			pcall(RefreshCodeHighlight);
		end;
	end);

	--// Action handlers -
	self:Connection(LoadHit.MouseButton1Click, function()
		if CurrentFile then
			LoadFileContent(CurrentFile);
			Library:Notify({ Text = "Loaded " .. CurrentFile });
		else
			SetStatus("no file selected", hex("EB4B4B"));
			Library:Notify({ Text = "No file selected" });
		end;
	end);

	local function NextUntitledName()
		if not isfile or not isfile(folder .. "/untitled.lua") then return "untitled.lua" end;
		local i = 2;
		while isfile(folder .. "/untitled_" .. i .. ".lua") do i += 1 end;
		return "untitled_" .. i .. ".lua";
	end;

	self:Connection(SaveHit.MouseButton1Click, function()
		if not writefile then
			SetStatus("writefile unavailable", hex("EB4B4B"));
			Library:Notify({ Text = "writefile unavailable" });
			return;
		end;
		local name = CurrentFile or NextUntitledName();
		local path = CurrentPath or (folder .. "/" .. name);
		CurrentFile = name;
		CurrentPath = path;
		local ok, err = pcall(writefile, path, CodeBox.Text);
		if ok then
			SetStatus("Saved " .. name, hex("98BCFF"));
			Library:Notify({ Text = "Saved " .. name });
		else
			SetStatus("save failed", hex("EB4B4B"));
			Library:Notify({ Text = "Save failed" });
			Library:Log("lua save fail: " .. tostring(err));
		end;
	end);

	self:Connection(NewHit.MouseButton1Click, function()
		CurrentFile = nil;
		CurrentPath = nil;
		CodeBox.Text = "";
		SetStatus("New file", hex("8A8A92"));
		Library:Notify({ Text = "New file" });
	end);

	local function RunCode()
		local source = CodeBox.Text;
		local chunk, err = loadstring(source);
		if not chunk then
			SetStatus("compile error", hex("EB4B4B"));
			Library:Notify({ Text = "Compile error" });
			Library:ConsolePush("Compile error: " .. tostring(err), "error");
			Library:Log("lua compile: " .. tostring(err));
			return;
		end;

		Library.LuaApi = Library.LuaApi or {};
		if not Library.Raycast then
			local WS = game:GetService("Workspace");
			local R = {};
			function R.Params(ignore, filterType, ignoreWater)
				local p = RaycastParams.new();
				p.FilterDescendantsInstances = (typeof(ignore) == "table") and ignore or {};
				p.FilterType = filterType or Enum.RaycastFilterType.Exclude;
				p.IgnoreWater = ignoreWater == true;
				return p;
			end;
			function R.Cast(origin, direction, params)
				if typeof(params) ~= "RaycastParams" then params = R.Params(params); end;
				return WS:Raycast(origin, direction, params);
			end;
			function R.To(origin, target, params)
				if typeof(params) ~= "RaycastParams" then params = R.Params(params); end;
				return WS:Raycast(origin, target - origin, params);
			end;
			function R.Visible(origin, target, ignore)
				local res = R.To(origin, target, R.Params(ignore));
				return res == nil, res;
			end;
			Library.Raycast = R;
		end;

		pcall(function()
			if not setfenv then return end;
			local baseEnv = (getgenv and getgenv()) or getfenv(0);
			local api = Library.LuaApi;
			local LandryHaxx = (api and api.LandryHaxx) or baseEnv.LandryHaxx or (shared and shared.LandryHaxx);
			if not LandryHaxx and api and api.LuaTab then LandryHaxx = { LuaTab = api.LuaTab }; end;
			if LandryHaxx then
				local Panel = LandryHaxx.LuaTab or Library.CurrentLuaEditor;
				if Panel and Panel.AddTab then
					LandryHaxx.AddTab = function(a, b)
						local name = b; if name == nil then name = a; end;
						return Panel:AddTab(name);
					end;
				end;
				LandryHaxx.Flags = LandryHaxx.Flags or Library.Flags;
				if getgenv then getgenv().LandryHaxx = getgenv().LandryHaxx or LandryHaxx; end;
				if shared then shared.LandryHaxx = shared.LandryHaxx or LandryHaxx; end;
				_G.LandryHaxx = _G.LandryHaxx or LandryHaxx;
			end;
			local env = setmetatable({
				UI = Library.CurrentLuaEditor;
				Editor = Library.CurrentLuaEditor;
				Library = Library;
				LandryHaxx = LandryHaxx;
				Flags = Library.Flags;
				Targeting = api.Targeting or baseEnv.Targeting or (shared and shared.Targeting);
				Raycast = api.Raycast or Library.Raycast;
				print = function(...)
					local parts = {};
					for i = 1, select("#", ...) do parts[i] = tostring((select(i, ...))) end;
					Library:ConsolePush(concat(parts, "\t"), "output");
				end;
				warn = function(...)
					local parts = {};
					for i = 1, select("#", ...) do parts[i] = tostring((select(i, ...))) end;
					Library:ConsolePush(concat(parts, "\t"), "warn");
				end;
				error = function(msg, lvl)
					Library:ConsolePush(tostring(msg), "error");
					return error(msg, lvl);
				end;
			}, { __index = baseEnv; __newindex = baseEnv });
			setfenv(chunk, env);
		end);

		local ok, RunErr = pcall(chunk);
		if ok then
			SetStatus("Ran ok", hex("98BCFF"));
			Library:Notify({ Text = "Executed " .. (CurrentFile or "untitled") });
			Library:ConsolePush("Ran " .. (CurrentFile or "untitled") .. " ok", "success");
		else
			SetStatus("runtime error", hex("EB4B4B"));
			Library:Notify({ Text = "Runtime error" });
			Library:ConsolePush("Runtime error: " .. tostring(RunErr), "error");
			Library:Log("lua run: " .. tostring(RunErr));
		end;
	end;
	self:Connection(ExecHit.MouseButton1Click, RunCode);

	self:Draggable(outer, HeaderDrag);

	local EditorTab = { Name = TitleText, Label = TitleLabel, Content = EditorContent };
	insert(LuaTabs, EditorTab);
	ActiveLuaTab = EditorTab;
	self:Connection(TitleHit.MouseButton1Click, function() SetActiveLuaTab(EditorTab) end);

	--// Menu actions
	NextUntitledNameFn = NextUntitledName;
	local function DoNewAction()
		CurrentFile = nil;
		CurrentPath = nil;
		CodeBox.Text = "";
		SetStatus("New file", hex("8A8A92"));
		Library:Notify({ Text = "New file" });
	end;
	local function DoSaveAction()
		if not writefile then
			SetStatus("writefile unavailable", hex("EB4B4B"));
			Library:Notify({ Text = "writefile unavailable" });
			return;
		end;
		local name = CurrentFile or NextUntitledName();
		local path = CurrentPath or (folder .. "/" .. name);
		CurrentFile = name;
		CurrentPath = path;
		local ok, err = pcall(writefile, path, CodeBox.Text);
		if ok then
			SetStatus("Saved " .. name, hex("98BCFF"));
			Library:Notify({ Text = "Saved " .. name });
		else
			SetStatus("save failed", hex("EB4B4B"));
			Library:Notify({ Text = "Save failed" });
			Library:Log("lua save fail: " .. tostring(err));
		end;
	end;
	local function DoLoadAction()
		if CurrentFile then
			LoadFileContent(CurrentFile);
			Library:Notify({ Text = "Loaded " .. CurrentFile });
		else
			SetStatus("no file selected", hex("EB4B4B"));
			Library:Notify({ Text = "No file selected" });
		end;
	end;
	--// File tab: hierarchical browser with dependency info
	local function ListFilesRecursive(path)
		local out = {};
		if not listfiles then return out end;
		local ok, entries = pcall(listfiles, path);
		if not ok or typeof(entries) ~= "table" then return out end;
		for _, p in entries do
			local name = tostring(p):match("[^/\\]+$");
			if name then
				local isDir = (isfolder and isfolder(p) == true) or false;
				local node = { name = name, path = p, isDir = isDir, children = {} };
				if isDir then node.children = ListFilesRecursive(p); end;
				insert(out, node);
			end;
		end;
		table.sort(out, function(a, b)
			if a.isDir ~= b.isDir then return a.isDir; end;
			return a.name:lower() < b.name:lower();
		end);
		return out;
	end;
	local function GetFileDeps(content)
		local deps = {};
		if typeof(content) ~= "string" then return deps end;
		for m in content:gmatch("require%s*%(%s*['\"]([^'\"]+)['\"]") do
			insert(deps, { kind = "require", target = m });
		end;
		for m in content:gmatch("loadfile%s*%(%s*['\"]([^'\"]+)['\"]") do
			insert(deps, { kind = "loadfile", target = m });
		end;
		for m in content:gmatch("dofile%s*%(%s*['\"]([^'\"]+)['\"]") do
			insert(deps, { kind = "dofile", target = m });
		end;
		return deps;
	end;
	local function FileIsLua(path)
		return tostring(path):sub(-4):lower() == ".lua";
	end;
	local FileTreeState = setmetatable({}, { __mode = "k" });

	-- File tab page (a real tab, not a floating window)
	local FilePage = self:CreateInstance("Frame", {
		Name = "FilePage"; Parent = main;
		Position = NewUdim2(0, 0, 0, 0);
		Size = NewUdim2(1, 0, 1, 0);
		BackgroundTransparency = 1;
		BorderSizePixel = 0;
		Visible = false;
		ZIndex = 2;
	});
	local RefreshFileBrowser;
	local FbScroll = self:CreateInstance("ScrollingFrame", {
		Name = "FbScroll"; Parent = FilePage;
		Position = NewUdim2(0, 6, 0, 6);
		Size = NewUdim2(1, -12, 1, -12);
		BackgroundTransparency = 1;
		BorderSizePixel = 0;
		ScrollBarThickness = 2; ScrollBarImageColor3 = hex("98BCFF");
		CanvasSize = NewUdim2(0, 0, 0, 0);
		AutomaticCanvasSize = Enum.AutomaticSize.Y;
		ZIndex = 3;
	});
	self:CreateInstance("UIPadding", {
		Parent = FbScroll;
		PaddingTop = NewUdim(0, 14); PaddingBottom = NewUdim(0, 2);
		PaddingLeft = NewUdim(0, 2); PaddingRight = NewUdim(0, 2);
	});
	self:CreateInstance("UIListLayout", {
		Parent = FbScroll;
		SortOrder = Enum.SortOrder.LayoutOrder;
		Padding = NewUdim(0, 1);
	});
	local FileMenu = self:ContextMenu(gui);
	local FileModalGui;
	local function CloseFileModal()
		if FileModalGui and FileModalGui.Parent then FileModalGui:Destroy() end;
		FileModalGui = nil;
	end;
	local function FileModal(opts)
		opts = typeof(opts) == "table" and opts or {};
		CloseFileModal();
		local g = self:CreateInstance("ScreenGui", {
			Name = "\0";
			Parent = (gethui and gethui()) or CoreGui;
			Enabled = true;
			DisplayOrder = 1600;
			IgnoreGuiInset = true;
			ResetOnSpawn = false;
			ZIndexBehavior = Enum.ZIndexBehavior.Global;
		});
		self:ApplyScale(g);
		FileModalGui = g;
		self:CreateInstance("TextButton", {
			Name = "Dim"; Parent = g;
			Size = NewUdim2(1, 0, 1, 0);
			BackgroundColor3 = hex("000000");
			BackgroundTransparency = 0.6;
			AutoButtonColor = false; Text = "";
			ZIndex = 150;
		}).MouseButton1Click:Connect(function() CloseFileModal() end);
		local win = self:CreateInstance("Frame", {
			Name = "FileModal"; Parent = g;
			AnchorPoint = NewVector2(0.5, 0.5);
			Position = NewUdim2(0.5, 0, 0.5, 0);
			Size = FromOffset(300, 160);
			BackgroundColor3 = hex("07080A");
			BorderSizePixel = 0;
			ZIndex = 151;
			ClipsDescendants = true;
		});
		local inner = self:CreateInstance("Frame", {
			Parent = win;
			Position = NewUdim2(0, 1, 0, 1); Size = NewUdim2(1, -2, 1, -2);
			BackgroundColor3 = hex("24262D"); BorderSizePixel = 0; ZIndex = 152;
		});
		local body = self:CreateInstance("Frame", {
			Parent = inner;
			Position = NewUdim2(0, 1, 0, 1); Size = NewUdim2(1, -2, 1, -2);
			BackgroundColor3 = FromRgb(255, 255, 255);
			BorderSizePixel = 0; ZIndex = 153;
		});
		self:CreateInstance("UIGradient", {
			Parent = body; Rotation = 90;
			Color = NewColorSequence(hex("131418"), hex("17181D"));
		});
		local AccentBar = self:CreateInstance("Frame", {
			Parent = body; Size = NewUdim2(1, 0, 0, 1);
			BackgroundColor3 = self.AccentColor or hex("98BCFF");
			BorderSizePixel = 0; ZIndex = 154;
		});
		self:CreateInstance("Frame", {
			Parent = body;
			Position = NewUdim2(0, 0, 0, 1); Size = NewUdim2(1, 0, 0, 1);
			BackgroundColor3 = self.ShadeColor or hex("6E8CC8");
			BorderSizePixel = 0; ZIndex = 154;
		});
		local title = self:CreateInstance("TextLabel", {
			Parent = body;
			Position = NewUdim2(0, 6, 0, 3); Size = NewUdim2(1, -30, 0, 14);
			BackgroundTransparency = 1;
			FontFace = Library.Fonts.title;
			Text = tostring(opts.Title or "Input");
			TextColor3 = FromRgb(255, 255, 255); TextSize = 9;
			TextXAlignment = Enum.TextXAlignment.Left;
			TextYAlignment = Enum.TextYAlignment.Top;
			ZIndex = 155;
		});
		self:CreateInstance("UIGradient", {
			Parent = title; Rotation = 90;
			Color = NewColorSequence(AccentBar.BackgroundColor3, self.ShadeColor or hex("6E8CC8"));
		});
		self:CreateInstance("TextButton", {
			Name = "Close"; Parent = body;
			Position = NewUdim2(1, -18, 0, 1); Size = FromOffset(16, 18);
			BackgroundTransparency = 1; AutoButtonColor = false;
			FontFace = Library.Fonts.title; Text = "x";
			TextColor3 = hex("B4B4B4"); TextSize = 9; ZIndex = 155;
		}).MouseButton1Click:Connect(function() CloseFileModal() end);

		local y = 28;
		if opts.Message then
			self:CreateInstance("TextLabel", {
				Parent = body;
				Position = NewUdim2(0, 10, 0, y); Size = NewUdim2(1, -20, 0, 24);
				BackgroundTransparency = 1;
				FontFace = Library.Fonts.title;
				Text = tostring(opts.Message);
				TextColor3 = hex("B4B4B4"); TextSize = 8;
				TextXAlignment = Enum.TextXAlignment.Left;
				TextYAlignment = Enum.TextYAlignment.Top;
				TextWrapped = true;
				ZIndex = 155;
			});
			y += 28;
		end;
		local input;
		if opts.Input ~= nil then
			local BoxOuter = self:CreateInstance("Frame", {
				Parent = body;
				Position = NewUdim2(0, 10, 0, y); Size = NewUdim2(1, -20, 0, 20);
				BackgroundColor3 = hex("07080A");
				BorderSizePixel = 0; ZIndex = 155;
			});
			local BoxMid = self:CreateInstance("Frame", {
				Parent = BoxOuter;
				Position = NewUdim2(0, 1, 0, 1); Size = NewUdim2(1, -2, 1, -2);
				BackgroundColor3 = hex("24262D");
				BorderSizePixel = 0; ZIndex = 156;
			});
			local BoxBody = self:CreateInstance("Frame", {
				Parent = BoxMid;
				Position = NewUdim2(0, 1, 0, 1); Size = NewUdim2(1, -2, 1, -2);
				BackgroundColor3 = FromRgb(255, 255, 255);
				BorderSizePixel = 0; ZIndex = 157;
				ClipsDescendants = true;
			});
			self:CreateInstance("UIGradient", {
				Parent = BoxBody; Rotation = 90;
				Color = NewColorSequence(hex("131418"), hex("17181D"));
			});
			input = self:CreateInstance("TextBox", {
				Parent = BoxBody;
				Size = NewUdim2(1, 0, 1, 0);
				BackgroundTransparency = 1; BorderSizePixel = 0;
				ClearTextOnFocus = false;
				FontFace = Library.Fonts.title;
				Text = tostring(opts.Input);
				TextColor3 = FromRgb(255, 255, 255);
				TextSize = 9;
				TextXAlignment = Enum.TextXAlignment.Left;
				TextYAlignment = Enum.TextYAlignment.Center;
				ZIndex = 158;
			});
			self:CreateInstance("UIPadding", { Parent = input; PaddingLeft = NewUdim(0, 4); PaddingRight = NewUdim(0, 4); });
			y += 28;
		end;
		local function MakeModalBtn(label, x, accent, onClick)
			local outer = self:CreateInstance("Frame", {
				Parent = body;
				Position = NewUdim2(0, x, 0, y); Size = FromOffset(58, 20);
				BackgroundColor3 = hex("07080A");
				BorderSizePixel = 0; ZIndex = 155;
			});
			local mid = self:CreateInstance("Frame", {
				Parent = outer;
				Position = NewUdim2(0, 1, 0, 1); Size = NewUdim2(1, -2, 1, -2);
				BackgroundColor3 = hex("24262D");
				BorderSizePixel = 0; ZIndex = 156;
			});
			local b = self:CreateInstance("Frame", {
				Parent = mid;
				Position = NewUdim2(0, 1, 0, 1); Size = NewUdim2(1, -2, 1, -2);
				BackgroundColor3 = FromRgb(255, 255, 255);
				BorderSizePixel = 0; ZIndex = 157;
			});
			self:CreateInstance("UIGradient", {
				Parent = b; Rotation = 90;
				Color = accent and NewColorSequence(hex("94B7F8"), hex("6B84B3")) or NewColorSequence(hex("131418"), hex("17181D"));
			});
			self:CreateInstance("TextLabel", {
				Parent = b;
				Size = NewUdim2(1, 0, 1, 0);
				BackgroundTransparency = 1;
				FontFace = Library.Fonts.title;
				Text = label;
				TextColor3 = accent and FromRgb(255, 255, 255) or hex("B4B4B4");
				TextSize = 9;
				ZIndex = 158;
			});
			self:CreateInstance("TextButton", {
				Parent = outer;
				Size = NewUdim2(1, 0, 1, 0);
				BackgroundTransparency = 1; AutoButtonColor = false; Text = "";
				ZIndex = 159;
			}).MouseButton1Click:Connect(onClick);
			return outer;
		end;
		MakeModalBtn(tostring(opts.CancelText or "cancel"), 300 - 10 - 58 - 8 - 58, false, function() CloseFileModal() end);
		MakeModalBtn(tostring(opts.ConfirmText or "ok"), 300 - 10 - 58, true, function()
			local value = input and input.Text or nil;
			CloseFileModal();
			if typeof(opts.OnConfirm) == "function" then pcall(opts.OnConfirm, value) end;
		end);
		if input then
			self:Connection(input.FocusLost, function(enter)
				if enter then
					local value = input.Text;
					CloseFileModal();
					if typeof(opts.OnConfirm) == "function" then pcall(opts.OnConfirm, value) end;
				end;
			end);
		end;
		win.Size = FromOffset(300, y + 26);
		task.defer(function()
			if input and input.Parent then pcall(function() input:CaptureFocus() end) end;
		end);
	end;

	local function NewFileIn(dir)
		FileModal({
			Title = "New File";
			Message = "in  " .. tostring(dir);
			Input = "";
			OnConfirm = function(name)
				name = tostring(name):gsub("^%s+", ""):gsub("%s+$", "");
				if name == "" then return end;
				if typeof(writefile) ~= "function" then SetStatus("writefile unavailable", hex("EB4B4B")); return end;
				local path = dir .. "/" .. name;
				if isfile and isfile(path) then Library:Notify({ Text = "already exists" }); return end;
				local ok = pcall(writefile, path, "");
				if ok then
					SetStatus("created " .. path, hex("98BCFF"));
					if RefreshFileBrowser then RefreshFileBrowser(); end;
				else
					SetStatus("create failed", hex("EB4B4B"));
					Library:Log("file create fail: " .. tostring(path));
				end;
			end;
		});
	end;
	local function NewFolderIn(dir)
		FileModal({
			Title = "New Folder";
			Message = "in  " .. tostring(dir);
			Input = "";
			OnConfirm = function(name)
				name = tostring(name):gsub("^%s+", ""):gsub("%s+$", "");
				if name == "" then return end;
				if typeof(makefolder) ~= "function" then SetStatus("makefolder unavailable", hex("EB4B4B")); return end;
				local path = dir .. "/" .. name;
				if isfolder and isfolder(path) then Library:Notify({ Text = "already exists" }); return end;
				local ok = pcall(makefolder, path);
				if ok then
					SetStatus("created " .. path, hex("98BCFF"));
					if RefreshFileBrowser then RefreshFileBrowser(); end;
				else
					SetStatus("create failed", hex("EB4B4B"));
				end;
			end;
		});
	end;
	local function RenamePathUI(node)
		FileModal({
			Title = "Rename";
			Message = tostring(node.path);
			Input = node.name;
			OnConfirm = function(newName)
				newName = tostring(newName):gsub("^%s+", ""):gsub("%s+$", "");
				if newName == "" or newName == node.name then return end;
				local parent = tostring(node.path):match("^(.*)[/\\][^/\\]+$") or folder;
				local newPath = parent .. "/" .. newName;
				if isfile and isfile(newPath) or (isfolder and isfolder(newPath)) then
					Library:Notify({ Text = "already exists" }); return;
				end;
				local ok, err = RenamePath(node.path, newPath);
				if ok then
					SetStatus("renamed -> " .. newName, hex("98BCFF"));
					if RefreshFileBrowser then RefreshFileBrowser(); end;
				else
					SetStatus("rename failed", hex("EB4B4B"));
					Library:Notify({ Text = "Rename failed" });
					Library:Log("lua rename fail: " .. tostring(err));
				end;
			end;
		});
	end;
	local function DeletePathUI(node)
		FileModal({
			Title = "Delete";
			Message = "Delete '" .. node.name .. "'? This cannot be undone.";
			ConfirmText = "delete";
			OnConfirm = function()
				local ok;
				if node.isDir then
					ok = (typeof(delfolder) == "function") and pcall(delfolder, node.path) or false;
				else
					ok = (typeof(delfile) == "function") and pcall(delfile, node.path) or false;
				end;
				if ok then
					SetStatus("deleted " .. node.name, hex("98BCFF"));
					if RefreshFileBrowser then RefreshFileBrowser(); end;
				else
					SetStatus("delete failed", hex("EB4B4B"));
					Library:Notify({ Text = "Delete failed" });
				end;
			end;
		});
	end;
	local function FindDepPath(dir, target, depth)
		if depth > 8 then return nil end;
		local ok, entries = pcall(listfiles, dir);
		if not ok or typeof(entries) ~= "table" then return nil end;
		local clean = tostring(target):gsub("\\", "/"):gsub("^/+", ""):gsub("/+$", "");
		local rel = (tostring(dir):gsub("\\", "/"):gsub("/+$", "")) .. "/" .. clean;
		if isfile and isfile(rel) then return rel end;
		if isfile and isfile(rel .. ".lua") then return rel .. ".lua" end;
		for _, p in entries do
			local name = tostring(p):match("[^/\\]+$") or "";
			if name == clean or name:gsub("%.lua$", "") == clean then
				return p;
			end;
		end;
		for _, p in entries do
			if isfolder and isfolder(p) then
				local r = FindDepPath(p, clean, depth + 1);
				if r then return r end;
			end;
		end;
		return nil;
	end;
	local function OpenDepTarget(node, dep)
		local path = FindDepPath(folder, dep.target, 0);
		if path then
			OpenFileByPath(path);
		else
			SetStatus("missing dep: " .. dep.target, hex("EB4B4B"));
			Library:Notify({ Text = "Missing: " .. dep.target });
		end;
	end;

	local function MakeFileRow(parent, node, depth)
		local indent = 4 + depth * 12;
		local row = self:CreateInstance("Frame", {
			Name = "FileRow"; Parent = parent;
			Size = NewUdim2(1, 0, 0, 18);
			BackgroundTransparency = 1;
			BorderSizePixel = 0;
			LayoutOrder = #parent:GetChildren() + 1;
			ZIndex = 4;
		});
		local lbl = self:CreateInstance("TextLabel", {
			Name = "Name"; Parent = row;
			Position = NewUdim2(0, indent, 0, 0);
			Size = NewUdim2(1, -(indent + 2), 1, 0);
			BackgroundTransparency = 1;
			FontFace = Library.Fonts.title;
			Text = node.name;
			TextColor3 = node.isDir and hex("DADADA") or (CurrentFile == node.name and (Library.AccentColor or hex("98BCFF")) or hex("DADADA"));
			TextSize = 9;
			TextXAlignment = Enum.TextXAlignment.Left;
			TextYAlignment = Enum.TextYAlignment.Center;
			TextTruncate = Enum.TextTruncate.AtEnd;
			ZIndex = 5;
		});
		local hit = self:CreateInstance("TextButton", {
			Parent = row;
			Size = NewUdim2(1, 0, 1, 0);
			BackgroundTransparency = 1; AutoButtonColor = false; Text = "";
			ZIndex = 6;
		});
		local parentDir = node.isDir and node.path or (tostring(node.path):match("^(.*)[/\\][^/\\]+$") or folder);
		self:Connection(hit.MouseButton2Click, function()
			local mx, my = UserInputService:GetMouseLocation().X, UserInputService:GetMouseLocation().Y;
			FileMenu.Open(mx, my, {
				{ Text = "New File",   Icon = "✚", OnClick = function() NewFileIn(parentDir) end };
				{ Text = "New Folder", Icon = "▸", OnClick = function() NewFolderIn(parentDir) end };
				"Divider";
				{ Text = "Rename", Icon = "✎", OnClick = function() RenamePathUI(node) end };
				{ Text = "Delete", Icon = "✕", OnClick = function() DeletePathUI(node) end };
				"Divider";
				{ Text = "Open", Icon = "▣", Disabled = node.isDir or not FileIsLua(node.path), OnClick = function() OpenFileByPath(node.path) end };
			});
		end);
		if not node.isDir and FileIsLua(node.path) then
			local content = "";
			if isfile and isfile(node.path) and readfile then
				local ok, c = pcall(readfile, node.path);
				if ok then content = c; end;
			end;
			local deps = GetFileDeps(content);
			if #deps > 0 then
				row.Size = NewUdim2(1, 0, 0, 30);
				local dx = indent;
				for _, d in ipairs(deps) do
					local w = 6 + #d.target * 4;
					local dep = self:CreateInstance("TextButton", {
						Name = "Dep"; Parent = row;
						Position = NewUdim2(0, dx, 0, 17);
						Size = FromOffset(w, 12);
						BackgroundTransparency = 1;
						AutoButtonColor = false;
						FontFace = Library.Fonts.title;
						Text = d.target;
						TextColor3 = hex("8AB4F8");
						TextSize = 7;
						TextXAlignment = Enum.TextXAlignment.Left;
						TextYAlignment = Enum.TextYAlignment.Top;
						TextTruncate = Enum.TextTruncate.AtEnd;
						ZIndex = 6;
					});
					self:Connection(dep.MouseEnter, function()
						self:Tween(dep, NewTweenInfo(0.1, Enum.EasingStyle.Quad, Enum.EasingDirection.Out), { TextColor3 = FromRgb(255, 255, 255) }):Play();
					end);
					self:Connection(dep.MouseLeave, function()
						self:Tween(dep, NewTweenInfo(0.1, Enum.EasingStyle.Quad, Enum.EasingDirection.Out), { TextColor3 = hex("8AB4F8") }):Play();
					end);
					self:Connection(dep.MouseButton1Click, function() OpenDepTarget(node, d) end);
					dx += w + 6;
				end;
			end;
		end;
		return row, hit;
	end;
	local function BuildTree(parent, nodes, depth)
		for _, node in ipairs(nodes) do
			local row, hit = MakeFileRow(parent, node, depth);
			if node.isDir then
				local cont = self:CreateInstance("Frame", {
					Name = "DirChildren"; Parent = parent;
					Size = NewUdim2(1, 0, 0, 0);
					BackgroundTransparency = 1;
					BorderSizePixel = 0;
					ClipsDescendants = true;
					Visible = false;
					LayoutOrder = #parent:GetChildren() + 1;
					ZIndex = 4;
				});
				local rail = self:CreateInstance("Frame", {
					Name = "Rail"; Parent = cont;
					Position = NewUdim2(0, 5, 0, 0);
					Size = NewUdim2(0, 1, 0, 0);
					BackgroundColor3 = hex("3A3D45");
					BorderSizePixel = 0;
					ZIndex = 4;
				});
				self:CreateInstance("Frame", {
					Name = "RailEnd"; Parent = rail;
					AnchorPoint = NewVector2(0.5, 1);
					Position = NewUdim2(0.5, 0, 1, 0);
					Size = FromOffset(3, 3);
					BackgroundColor3 = hex("3A3D45");
					BorderSizePixel = 0;
					ZIndex = 4;
				});
				local content = self:CreateInstance("Frame", {
					Name = "Content"; Parent = cont;
					Position = NewUdim2(0, 18, 0, 0);
					Size = NewUdim2(1, -18, 0, 0);
					AutomaticSize = Enum.AutomaticSize.Y;
					BackgroundTransparency = 1;
					BorderSizePixel = 0;
					ZIndex = 4;
				});
				self:CreateInstance("UIListLayout", { Parent = content; SortOrder = Enum.SortOrder.LayoutOrder; Padding = NewUdim(0, 1); });
				local st = FileTreeState[node.path];
				if not st then st = { Expanded = false; Built = false }; FileTreeState[node.path] = st; end;
				local DirTween = NewTweenInfo(0.16, Enum.EasingStyle.Quad, Enum.EasingDirection.Out);
				local function AnimateDir(open)
					st.Expanded = open;
					if open then
						if not st.Built then
							st.Built = true;
							if #node.children > 0 then BuildTree(content, node.children, depth + 1); end;
						end;
						cont.Visible = true;
						local h = 0;
						for _, ch in content:GetChildren() do
							if ch:IsA("Frame") then h += ch.Size.Y.Offset end;
						end;
						self:Tween(cont, DirTween, { Size = NewUdim2(1, 0, 0, h) }):Play();
						self:Tween(rail, DirTween, { Size = NewUdim2(0, 1, 0, h) }):Play();
					else
						local t = self:Tween(cont, DirTween, { Size = NewUdim2(1, 0, 0, 0) });
						t:Play();
						t.Completed:Once(function()
							if not st.Expanded and cont and cont.Parent then
								cont.Visible = false;
								cont.Size = NewUdim2(1, 0, 0, 0);
								rail.Size = NewUdim2(0, 1, 0, 0);
							end;
						end);
					end;
				end;
				self:Connection(hit.MouseButton1Click, function() AnimateDir(not st.Expanded) end);
			else
				self:Connection(hit.MouseButton1Click, function()
					if node.isDir then return end;
					OpenFileByPath(node.path);
				end);
				self:Connection(hit.MouseEnter, function()
					self:Tween(row, NewTweenInfo(0.12, Enum.EasingStyle.Quad, Enum.EasingDirection.Out), { BackgroundColor3 = self.AccentColor or hex("2E5E9E"); BackgroundTransparency = 0.8 }):Play();
				end);
				self:Connection(hit.MouseLeave, function()
					self:Tween(row, NewTweenInfo(0.12, Enum.EasingStyle.Quad, Enum.EasingDirection.Out), { BackgroundTransparency = 1 }):Play();
				end);
			end;
		end;
	end;
	local function RefreshFileBrowserImpl()
		for _, ch in FbScroll:GetChildren() do
			if ch:IsA("TextButton") or ch:IsA("TextLabel") or ch:IsA("Frame") then ch:Destroy() end;
		end;
		for _, st in pairs(FileTreeState) do
			if typeof(st) == "table" then
				st.Built = false;
				st.Expanded = false;
			end;
		end;
		local nodes = ListFilesRecursive(folder);
		BuildTree(FbScroll, nodes, 0);
		if #nodes == 0 then
			self:CreateInstance("TextLabel", {
				Parent = FbScroll;
				Size = NewUdim2(1, 0, 0, 18);
				BackgroundTransparency = 1;
				FontFace = Library.Fonts.title;
				Text = "(no files yet)";
				TextColor3 = hex("646464");
				TextSize = 9;
				TextXAlignment = Enum.TextXAlignment.Left;
				LayoutOrder = 1;
				ZIndex = 5;
			});
		end;
	end;
	RefreshFileBrowser = RefreshFileBrowserImpl;

	-- register the File tab in the editor's tab strip
	local FileTabLabel = self:CreateInstance("TextLabel", {
		Name = "FileTab"; Parent = TabStrip;
		AutomaticSize = Enum.AutomaticSize.X;
		Size = NewUdim2(0, 0, 0, 14);
		BackgroundTransparency = 1;
		FontFace = Library.Fonts.title;
		Text = "File";
		TextColor3 = hex("8A8A92");
		TextSize = 9;
		TextXAlignment = Enum.TextXAlignment.Left;
		TextYAlignment = Enum.TextYAlignment.Center;
		LayoutOrder = 2; ZIndex = 5;
	});
	local FileTabHit = self:CreateInstance("TextButton", {
		Parent = FileTabLabel;
		Size = NewUdim2(1, 0, 1, 0);
		BackgroundTransparency = 1; AutoButtonColor = false; Text = "";
		ZIndex = 6;
	});
	local FileTab = { Name = "File", Label = FileTabLabel, Content = FilePage };
	insert(LuaTabs, FileTab);
	self:Connection(FileTabHit.MouseButton1Click, function()
		SetActiveLuaTab(FileTab);
		RefreshFileBrowser();
	end);
	self:Connection(FileTabHit.MouseEnter, function()
		if ActiveLuaTab ~= FileTab then self:Tween(FileTabLabel, TabColorTween, { TextColor3 = FromRgb(255, 255, 255) }):Play(); end;
	end);
	self:Connection(FileTabHit.MouseLeave, function()
		if ActiveLuaTab ~= FileTab then self:Tween(FileTabLabel, TabColorTween, { TextColor3 = hex("8A8A92") }):Play(); end;
	end);
	local function DoFileBrowserAction()
		SetActiveLuaTab(FileTab);
		RefreshFileBrowser();
		SetStatus("browse: " .. folder, hex("98BCFF"));
	end;
	DoNew = DoNewAction;
	DoSave = DoSaveAction;
	DoLoad = DoLoadAction;
	DoExec = RunCode;
	DoFileBrowser = DoFileBrowserAction;

	MakeMenuButton("Editor", {
		{ Text = "New File",     Icon = "✚", OnClick = function() DoNew() end };
		{ Text = "Save",         Icon = "▣", OnClick = function() DoSave() end };
		{ Text = "Load",         Icon = "▤", OnClick = function() DoLoad() end };
		"Divider";
		{ Text = "Run  (Ctrl+Enter)", Icon = "▶", OnClick = function() DoExec() end };
	}, 1);
	MakeMenuButton("File", {
		{ Text = "Open File Browser", Icon = "▸", OnClick = function() DoFileBrowser() end };
		{ Text = "New Lua",      Icon = "✚", OnClick = function()
			local name = NextUntitledNameFn();
			if writefile and name then
				pcall(writefile, folder .. "/" .. name, "");
				LoadFileContent(name);
				SetStatus("New " .. name, hex("98BCFF"));
			end;
		end };
	}, 2);

	local panel = { Gui = gui, Outer = outer, CodeBox = CodeBox, Tabs = LuaTabs };
	function panel:SetVisible(on) Library:SetWidgetVisible(self, on) end;
	function panel:Destroy()
		if self.Gui and self.Gui.Parent then self.Gui:Destroy() end;
		if Library.CurrentLuaEditor == panel then Library.CurrentLuaEditor = nil end;
	end;
	function panel:AddTab(name)
		name = tostring(name or "Tab");
		local order = #LuaTabs + 1;

		local lbl = Library:CreateInstance("TextLabel", {
			Parent = TabStrip;
			AutomaticSize = Enum.AutomaticSize.X;
			Size = NewUdim2(0, 0, 0, 14);
			BackgroundTransparency = 1;
			FontFace = Library.Fonts.title;
			Text = name;
			TextColor3 = hex("8A8A92");
			TextSize = 9;
			TextXAlignment = Enum.TextXAlignment.Left;
			TextYAlignment = Enum.TextYAlignment.Center;
			LayoutOrder = order; ZIndex = 5;
		});
		local hit = Library:CreateInstance("TextButton", {
			Parent = lbl;
			Size = NewUdim2(1, 0, 1, 0);
			BackgroundTransparency = 1; AutoButtonColor = false; Text = "";
			ZIndex = 6;
		});

		local content = Library:CreateInstance("ScrollingFrame", {
			Name = "TabContent_" .. name; Parent = main;
			Position = NewUdim2(0, 6, 0, 24);
			Size = NewUdim2(1, -12, 1, -30);
			BackgroundTransparency = 1;
			BorderSizePixel = 0;
			Visible = false;
			Active = true;
			ClipsDescendants = true;
			ScrollBarThickness = 3;
			ScrollBarImageColor3 = hex("98BCFF");
			ScrollingDirection = Enum.ScrollingDirection.Y;
			CanvasSize = NewUdim2(0, 0, 0, 0);
			AutomaticCanvasSize = Enum.AutomaticSize.Y;
			ZIndex = 2;
		});
		Library:CreateInstance("UIPadding", {
			Parent = content;
			PaddingTop = NewUdim(0, 2); PaddingBottom = NewUdim(0, 2);
			PaddingLeft = NewUdim(0, 2); PaddingRight = NewUdim(0, 2);
		});
		Library:CreateInstance("UIListLayout", {
			Parent = content;
			FillDirection = Enum.FillDirection.Vertical;
			SortOrder = Enum.SortOrder.LayoutOrder;
			Padding = NewUdim(0, 6);
		});

		local tab = { Name = name, Label = lbl, Content = content, WidgetCount = 0, Sections = 0 };
		insert(LuaTabs, tab);
		Library:Connection(hit.MouseButton1Click, function() SetActiveLuaTab(tab) end);
		Library:Connection(hit.MouseEnter, function()
			if ActiveLuaTab ~= tab then
				Library:Tween(lbl, TabColorTween, { TextColor3 = FromRgb(255, 255, 255) }):Play();
			end;
		end);
		Library:Connection(hit.MouseLeave, function()
			if ActiveLuaTab ~= tab then
				Library:Tween(lbl, TabColorTween, { TextColor3 = hex("8A8A92") }):Play();
			end;
		end);

		local function BuildLuaToggle(host, Data, default, callback, FlagOpt)
			if typeof(Data) ~= "table" then
				Data = { Name = Data, Default = default, Callback = callback, Flag = FlagOpt };
			end;
			local ToggleName = Data.Name or Data.name or "Toggle";
			local Default    = Data.Default; if Default == nil then Default = Data.default end;
			local cb         = Data.Callback or Data.callback;
			local FlagOptVal = Data.Flag or Data.flag;
			local flag = Library:AutoFlag(FlagOptVal or ToggleName);
			host.WidgetCount = (host.WidgetCount or 0) + 1;

			local row = Library:CreateInstance("Frame", {
				Name = "Toggle_" .. ToggleName;
				Parent = host.Content;
				Size = NewUdim2(1, 0, 0, 12);
				BackgroundTransparency = 1;
				LayoutOrder = host.WidgetCount;
				ZIndex = 2;
			});
			local BoxOutline = Library:CreateInstance("Frame", {
				Name = "Box"; Parent = row;
				AnchorPoint = NewVector2(0, 0.5);
				Position = NewUdim2(0, 0, 0.5, 0);
				Size = NewUdim2(0, 12, 0, 12);
				BackgroundColor3 = hex("24262D");
				BorderSizePixel = 0; ZIndex = 2;
			});
			local BoxBody = Library:CreateInstance("Frame", {
				Name = "Body"; Parent = BoxOutline;
				Position = NewUdim2(0, 1, 0, 1); Size = NewUdim2(1, -2, 1, -2);
				BackgroundColor3 = hex("1C1D23");
				BorderSizePixel = 0; ZIndex = 3;
			});
			local BoxFill = Library:CreateInstance("Frame", {
				Name = "Fill"; Parent = BoxBody;
				Size = NewUdim2(1, 0, 1, 0);
				BackgroundColor3 = FromRgb(255, 255, 255);
				BackgroundTransparency = 1;
				BorderSizePixel = 0; ZIndex = 4;
			});
			Library:CreateInstance("UIGradient", {
				Parent = BoxFill; Rotation = 90;
				Color = NewColorSequence(hex("94B7F8"), hex("6B84B3"));
			});
			local label = Library:CreateInstance("TextLabel", {
				Name = "Label"; Parent = row;
				AnchorPoint = NewVector2(0, 0.5);
				Position = NewUdim2(0, 18, 0.5, -1);
				Size = NewUdim2(1, -18, 1, 0);
				BackgroundTransparency = 1;
				FontFace = Library.Fonts.title;
				Text = tostring(ToggleName);
				TextColor3 = FromRgb(255, 255, 255);
				TextSize = 9;
				TextXAlignment = Enum.TextXAlignment.Left;
				TextYAlignment = Enum.TextYAlignment.Center;
				TextTruncate = Enum.TextTruncate.AtEnd;
				ZIndex = 3;
			});
			local hitBtn = Library:CreateInstance("TextButton", {
				Name = "Hit"; Parent = row;
				Size = NewUdim2(1, 0, 1, 0);
				BackgroundTransparency = 1; AutoButtonColor = false; Text = "";
				ZIndex = 5;
			});

			local state = Default == true;
			BoxFill.BackgroundTransparency = state and 0 or 1;
			label.TextColor3 = state and (Library.AccentColor or hex("98BCFF")) or hex("646464");

			local Toggle = { Row = row, Fill = BoxFill, Label = label, Name = ToggleName, Flag = flag, State = state };
			local ToggleTween = NewTweenInfo(0.15, Enum.EasingStyle.Quad, Enum.EasingDirection.Out);
			function Toggle:Set(v)
				v = v == true;
				if self.State == v then return end;
				self.State = v;
				Library.Flags[self.Flag] = v;
				Library:Tween(self.Fill, ToggleTween, { BackgroundTransparency = v and 0 or 1 }):Play();
				local LabelRef = self.Label;
				local LabelTween = Library:Tween(LabelRef, ToggleTween, { TextColor3 = v and (Library.AccentColor or hex("98BCFF")) or hex("646464") });
				LabelTween:Play();
				LabelTween.Completed:Once(function()
					if LabelRef and LabelRef.Parent then
						LabelRef.TextColor3 = self.State and (Library.AccentColor or hex("98BCFF")) or hex("646464");
					end;
				end);
				if typeof(cb) == "function" then cb(v) end;
			end;
			function Toggle:Get() return self.State end;
			Library:RegisterFlag(flag, state, function(v) Toggle:Set(v) end);
			Library:Connection(hitBtn.MouseButton1Click, function() Toggle:Set(not Toggle.State) end);
			return Toggle;
		end;

		function tab:Toggle(Data, default, callback, FlagOpt)
			return BuildLuaToggle(self, Data, default, callback, FlagOpt);
		end;

		function tab:Section(SectionName, side)
			if Library._BuildSection then
				if not self._SecHost then
					self._SecHost = {
						LeftCol = self.Content; RightCol = self.Content;
						Sections = {}; RefreshCanvases = function() end;
					};
				end;
				return Library._BuildSection(self._SecHost, SectionName, side);
			end;
			SectionName = tostring(SectionName or "Section");
			self.Sections = self.Sections + 1;

			local SecOuter = Library:CreateInstance("Frame", {
				Name = "Section_" .. SectionName;
				Parent = self.Content;
				Size = NewUdim2(1, 0, 0, 60);
				AutomaticSize = Enum.AutomaticSize.Y;
				BackgroundColor3 = hex("24262D");
				BorderSizePixel = 0;
				LayoutOrder = self.Sections;
				ZIndex = 2;
			});
			local SecBody = Library:CreateInstance("Frame", {
				Name = "Body"; Parent = SecOuter;
				Position = NewUdim2(0, 1, 0, 1); Size = NewUdim2(1, -2, 1, -2);
				BackgroundColor3 = FromRgb(255, 255, 255);
				BorderSizePixel = 0; ZIndex = 2;
			});
			Library:CreateInstance("UIGradient", {
				Parent = SecBody; Rotation = 90;
				Color = NewColorSequence(hex("131418"), hex("17181D"));
			});
			Library:CreateInstance("Frame", {
				Name = "TopAccent"; Parent = SecBody;
				Position = NewUdim2(0, 0, 0, 0); Size = NewUdim2(1, 0, 0, 1);
				BackgroundColor3 = hex("98BCFF");
				BorderSizePixel = 0; ZIndex = 3;
			});
			Library:CreateInstance("Frame", {
				Name = "TopAccentShade"; Parent = SecBody;
				Position = NewUdim2(0, 0, 0, 1); Size = NewUdim2(1, 0, 0, 1);
				BackgroundColor3 = hex("6E8CC8");
				BorderSizePixel = 0; ZIndex = 3;
			});
			local title = Library:CreateInstance("TextLabel", {
				Name = "Title"; Parent = SecBody;
				Position = NewUdim2(0, 10, 0, 7);
				Size = NewUdim2(0, 0, 0, 12);
				AutomaticSize = Enum.AutomaticSize.X;
				BackgroundTransparency = 1;
				FontFace = Library.Fonts.title;
				Text = SectionName;
				TextColor3 = FromRgb(255, 255, 255);
				TextSize = 9;
				TextXAlignment = Enum.TextXAlignment.Left;
				TextYAlignment = Enum.TextYAlignment.Center;
				ZIndex = 4;
			});
			local SecContent = Library:CreateInstance("Frame", {
				Name = "Content"; Parent = SecBody;
				Position = NewUdim2(0, 0, 0, 22);
				Size = NewUdim2(1, 0, 1, -22);
				BackgroundTransparency = 1;
				ZIndex = 2;
			});
			Library:CreateInstance("UIPadding", {
				Parent = SecContent;
				PaddingTop = NewUdim(0, 4); PaddingBottom = NewUdim(0, 8);
				PaddingLeft = NewUdim(0, 10); PaddingRight = NewUdim(0, 10);
			});
			Library:CreateInstance("UIListLayout", {
				Parent = SecContent;
				FillDirection = Enum.FillDirection.Vertical;
				SortOrder = Enum.SortOrder.LayoutOrder;
				Padding = NewUdim(0, 6);
			});

			local section = { Outer = SecOuter, Body = SecBody, Content = SecContent, Name = SectionName, WidgetCount = 0 };
			function section:Toggle(Data, default, callback, FlagOpt)
				return BuildLuaToggle(self, Data, default, callback, FlagOpt);
			end;
			return section;
		end;

		local function DefaultSection(host)
			if not host._DefaultSection then host._DefaultSection = host:Section(host.Name or "Script"); end;
			return host._DefaultSection;
		end;
		for _, MethodName in next, { "Slider", "RangeSlider", "Dropdown", "Keybind", "Colorpicker", "Textbox", "Button", "MultiButton", "ImageLabel" } do
			tab[MethodName] = function(self, ...)
				local sec = DefaultSection(self);
				local fn = sec and sec[MethodName];
				if typeof(fn) == "function" then return fn(sec, ...); end;
			end;
		end;

		return tab;
	end;

	function panel:Section(name, side)
		if not self._DefaultTab then self._DefaultTab = self:AddTab("Lua"); end;
		return self._DefaultTab:Section(name, side);
	end;
	for _, M in next, { "Toggle", "Slider", "RangeSlider", "Dropdown", "Keybind", "Colorpicker", "Textbox", "Button", "MultiButton", "ImageLabel" } do
		panel[M] = function(self, ...)
			if not self._DefaultTab then self._DefaultTab = self:AddTab("Lua"); end;
			local fn = self._DefaultTab[M];
			if typeof(fn) == "function" then return fn(self._DefaultTab, ...); end;
		end;
	end;

	self.CurrentLuaEditor = panel;
	self:TrackWidget(panel, "LuaEditor");
	return panel;
end;

function Library:OpenInIDE(text)
	text = text and tostring(text);
	local ed = self.CurrentLuaEditor;
	if not (ed and typeof(ed.Gui) == "Instance" and ed.Gui.Parent) then
		ed = self:LuaEditor();
	end;
	if ed and typeof(ed.Gui) == "Instance" then
		self:SetWidgetVisible(ed, true);
		if ed.CodeBox and text then
			local cur = ed.CodeBox.Text;
			if cur ~= "" and cur:sub(-1) ~= "\n" then cur = cur .. "\n"; end;
			ed.CodeBox.Text = cur .. text .. "\n";
		end;
	end;
	return ed;
end;

--// Activity window (Dex / Player / Remotes / Lua / Events)
function Library:Activity(opts)
	opts = typeof(opts) == "table" and opts or {};

	if typeof(self.CurrentActivity) == "table" and typeof(self.CurrentActivity.Gui) == "Instance" and self.CurrentActivity.Gui.Parent then
		self.CurrentActivity.Gui:Destroy();
	end;
	self.CurrentActivity = nil;

	local w = tonumber(opts.width) or 520;
	local h = tonumber(opts.height) or 420;

	local VpSize = camera.ViewportSize;
	local UiScale = self:ComputeUIScale();
	local DefaultX = MathClamp(tonumber(opts.x) or 30, 0, MathMax(0, VpSize.X / UiScale - w));
	local DefaultY = MathClamp(tonumber(opts.y) or 340, 0, MathMax(0, VpSize.Y / UiScale - h));

	local gui = self:CreateInstance("ScreenGui", {
		Name = "\0";
		Parent = (gethui and gethui()) or CoreGui;
		Enabled = true;
		DisplayOrder = self.WidgetDisplayOrder or 1002;
		IgnoreGuiInset = true;
		ResetOnSpawn = false;
		ZIndexBehavior = Enum.ZIndexBehavior.Global;
	});
	self:ApplyScale(gui);

	local outer = self:CreateInstance("Frame", {
		Name = "Outer";
		Parent = gui;
		Position = NewUdim2(0, DefaultX, 0, DefaultY);
		Size = FromOffset(w, h);
		BackgroundColor3 = hex("07080A");
		BorderSizePixel = 0;
		Active = true;
	});
	self:CreateInstance("ImageLabel", {
		Name = "Glow";
		Parent = outer;
		AnchorPoint = NewVector2(0.5, 0.5);
		Position = NewUdim2(0.5, 0, 0.5, 0);
		Size = NewUdim2(1, 30, 1, 30);
		BackgroundTransparency = 1;
		Image = "rbxassetid://18245826428";
		ImageColor3 = hex("98BCFF");
		ImageTransparency = 0.86;
		ScaleType = Enum.ScaleType.Slice;
		SliceCenter = RectNew(21, 21, 79, 79);
		ZIndex = -1;
	});
	local inner = self:CreateInstance("Frame", {
		Name = "Inner";
		Parent = outer;
		Position = NewUdim2(0, 1, 0, 1);
		Size = NewUdim2(1, -2, 1, -2);
		BackgroundColor3 = hex("24262D");
		BorderSizePixel = 0;
	});
	local main = self:CreateInstance("Frame", {
		Name = "Main";
		Parent = inner;
		Position = NewUdim2(0, 1, 0, 1);
		Size = NewUdim2(1, -2, 1, -2);
		BackgroundColor3 = FromRgb(255, 255, 255);
		BorderSizePixel = 0;
	});
	self:CreateInstance("UIGradient", {
		Parent = main; Rotation = 90;
		Color = NewColorSequence(hex("131418"), hex("17181D"));
	});
	self:CreateInstance("Frame", {
		Name = "TopAccent"; Parent = main;
		Size = NewUdim2(1, 0, 0, 1);
		BackgroundColor3 = hex("98BCFF");
		BorderSizePixel = 0; ZIndex = 2;
	});
	self:CreateInstance("Frame", {
		Name = "TopAccentShade"; Parent = main;
		Position = NewUdim2(0, 0, 0, 1);
		Size = NewUdim2(1, 0, 0, 1);
		BackgroundColor3 = hex("6E8CC8");
		BorderSizePixel = 0; ZIndex = 2;
	});
	local HeaderDrag = self:CreateInstance("Frame", {
		Name = "HeaderDrag"; Parent = main;
		Position = NewUdim2(0, 0, 0, 0);
		Size = NewUdim2(1, 0, 0, 20);
		BackgroundTransparency = 1; Active = true;
		ZIndex = 2;
	});
	local TitleLabel = self:CreateInstance("TextLabel", {
		Name = "Title"; Parent = main;
		Position = NewUdim2(0, 10, 0, 3);
		Size = NewUdim2(1, -60, 0, 14);
		BackgroundTransparency = 1;
		FontFace = Library.Fonts.title;
		Text = "Activity";
		TextColor3 = FromRgb(255, 255, 255);
		TextSize = 9;
		TextXAlignment = Enum.TextXAlignment.Left;
		ZIndex = 4;
	});
	self:CreateInstance("UIGradient", {
		Parent = TitleLabel;
		Color = NewColorSequence(hex("98BCFF"), hex("6E8CC8"));
		Rotation = 90;
	});
	local CloseHit = self:CreateInstance("TextButton", {
		Name = "CloseHit"; Parent = main;
		Position = NewUdim2(1, -20, 0, 2);
		Size = FromOffset(16, 16);
		BackgroundTransparency = 1;
		FontFace = Library.Fonts.title;
		Text = "x";
		TextColor3 = hex("B4B4B4");
		TextSize = 9;
		ZIndex = 4;
	});

	local TabBar = self:CreateInstance("Frame", {
		Name = "TabBar"; Parent = main;
		Position = NewUdim2(0, 0, 0, 22);
		Size = NewUdim2(1, 0, 0, 22);
		BackgroundTransparency = 1;
		ZIndex = 4;
	});
	local TabStrip = self:CreateInstance("Frame", {
		Name = "TabStrip"; Parent = TabBar;
		Position = NewUdim2(0, 10, 0, 0);
		Size = NewUdim2(1, -20, 1, 0);
		BackgroundTransparency = 1;
		ZIndex = 5;
	});
	self:CreateInstance("UIListLayout", {
		Parent = TabStrip;
		FillDirection = Enum.FillDirection.Horizontal;
		SortOrder = Enum.SortOrder.LayoutOrder;
		Padding = NewUdim(0, 6);
		VerticalAlignment = Enum.VerticalAlignment.Center;
	});

	local ContentArea = self:CreateInstance("Frame", {
		Name = "ContentArea"; Parent = main;
		Position = NewUdim2(0, 4, 0, 46);
		Size = NewUdim2(1, -8, 1, -50);
		BackgroundTransparency = 1;
		ClipsDescendants = true;
		ZIndex = 3;
	});

	self:Draggable(outer, HeaderDrag);

	local panel;
	local ActivityTabs = {};
	local ActiveTab = nil;
	local TabTween = NewTweenInfo(0.15, Enum.EasingStyle.Quad, Enum.EasingDirection.Out);
	local function SetActiveTab(tab)
		if ActiveTab == tab then return end;
		if ActiveTab then
			ActiveTab.Page.Visible = false;
			if typeof(ActiveTab.Label) == "Instance" and ActiveTab.Label.Parent then
				self:Tween(ActiveTab.Label, TabTween, { TextColor3 = hex("8A8A92") }):Play();
			end;
		end;
		ActiveTab = tab;
		if tab then
			tab.Page.Visible = true;
			if typeof(tab.Label) == "Instance" and tab.Label.Parent then
				self:Tween(tab.Label, TabTween, { TextColor3 = FromRgb(255, 255, 255) }):Play();
			end;
		end;
	end;
	local function MakeTab(name)
		local lbl = self:CreateInstance("TextButton", {
			Name = "Tab_" .. name; Parent = TabStrip;
			Size = NewUdim2(0, 0, 0, 16);
			AutomaticSize = Enum.AutomaticSize.X;
			BackgroundTransparency = 1;
			AutoButtonColor = false;
			FontFace = Library.Fonts.title;
			Text = name;
			TextColor3 = hex("8A8A92");
			TextSize = 9;
			LayoutOrder = #ActivityTabs + 1;
			ZIndex = 5;
		});
		local page = self:CreateInstance("Frame", {
			Name = "Page_" .. name; Parent = ContentArea;
			Position = NewUdim2(0, 2, 0, 2);
			Size = NewUdim2(1, -4, 1, -4);
			BackgroundTransparency = 1;
			BorderSizePixel = 0;
			Visible = false;
			ZIndex = 4;
		});
		local tab = { Name = name, Label = lbl, Page = page };
		insert(ActivityTabs, tab);
		self:Connection(lbl.MouseButton1Click, function() SetActiveTab(tab) end);
		self:Connection(lbl.MouseEnter, function()
			if ActiveTab ~= tab then self:Tween(lbl, TabTween, { TextColor3 = FromRgb(255, 255, 255) }):Play(); end;
		end);
		self:Connection(lbl.MouseLeave, function()
			if ActiveTab ~= tab then self:Tween(lbl, TabTween, { TextColor3 = hex("8A8A92") }):Play(); end;
		end);
		return tab;
	end;
	self:Connection(CloseHit.MouseButton1Click, function()
		if panel and typeof(panel.SetVisible) == "function" then panel:SetVisible(false); end;
	end);

	local function EscTxt(s)
		return (s:gsub("&", "&amp;"):gsub("<", "&lt;"):gsub(">", "&gt;"));
	end;
	local function ColSpan(color, text)
		return '<font color="' .. color .. '">' .. EscTxt(text) .. '</font>';
	end;
	local function ConsoleColor(kind)
		if kind == "error" then return "#FF7B72";
		elseif kind == "warn" then return "#FFA657";
		elseif kind == "success" then return "#7EE787";
		elseif kind == "info" then return "#E0E0E0";
		else return "#B4B4B4"; end;
	end;
	local function InstExpr(inst)
		local segs = {};
		for seg in (inst:GetFullName()):gmatch("[^.]+") do
			segs[#segs + 1] = seg:gsub('"', '\\"');
		end;
		local expr = "game";
		if #segs > 1 then
			for i = 2, #segs do
				expr = expr .. ':WaitForChild("' .. segs[i] .. '")';
			end;
		end;
		return expr;
	end;

	--// standard control builders (match the window's style)
	local CtrlTween = NewTweenInfo(0.15, Enum.EasingStyle.Quad, Enum.EasingDirection.Out);
	local PressIn = NewTweenInfo(0.08, Enum.EasingStyle.Quad, Enum.EasingDirection.Out);
	local PressOut = NewTweenInfo(0.16, Enum.EasingStyle.Back, Enum.EasingDirection.Out);
	local function MakeActToggle(parent, name, x, y)
		local outline = self:CreateInstance("Frame", {
			Name = "Tog_" .. name; Parent = parent;
			Position = NewUdim2(0, x, 0, y + 5);
			Size = NewUdim2(0, 12, 0, 12);
			BackgroundColor3 = hex("24262D");
			BorderSizePixel = 0; ZIndex = 6;
		});
		local body = self:CreateInstance("Frame", {
			Parent = outline;
			Position = NewUdim2(0, 1, 0, 1); Size = NewUdim2(1, -2, 1, -2);
			BackgroundColor3 = hex("1C1D23"); BorderSizePixel = 0; ZIndex = 7;
		});
		local fill = self:CreateInstance("Frame", {
			Parent = body;
			Size = NewUdim2(1, 0, 1, 0);
			BackgroundColor3 = FromRgb(255, 255, 255);
			BackgroundTransparency = 1;
			BorderSizePixel = 0; ZIndex = 8;
		});
		self:CreateInstance("UIGradient", {
			Parent = fill; Rotation = 90;
			Color = NewColorSequence(hex("94B7F8"), hex("6B84B3"));
		});
		local label = self:CreateInstance("TextLabel", {
			Name = "Label"; Parent = parent;
			Position = NewUdim2(0, x + 16, 0, y);
			Size = NewUdim2(0, 120, 0, 22);
			BackgroundTransparency = 1;
			FontFace = Library.Fonts.title;
			Text = name;
			TextColor3 = hex("646464");
			TextSize = 9;
			TextXAlignment = Enum.TextXAlignment.Left;
			TextYAlignment = Enum.TextYAlignment.Center;
			ZIndex = 6;
		});
		local hit = self:CreateInstance("TextButton", {
			Name = "Hit"; Parent = parent;
			Position = NewUdim2(0, x, 0, y);
			Size = NewUdim2(0, 136, 0, 22);
			BackgroundTransparency = 1; AutoButtonColor = false; Text = ""; ZIndex = 9;
		});
		local Toggle = {
			Outline = outline; Body = body; Fill = fill; Label = label; Hit = hit; State = false;
		};
		function Toggle:Set(v)
			v = v == true;
			if self.State == v then return end;
			self.State = v;
			Library:Tween(self.Fill, CtrlTween, { BackgroundTransparency = v and 0 or 1 }):Play();
			Library:Tween(self.Label, CtrlTween, { TextColor3 = v and (Library.AccentColor or hex("98BCFF")) or hex("646464") }):Play();
		end;
		function Toggle:Get() return self.State == true end;
		return Toggle;
	end;
	local function MakeActButton(parent, name, x, y, w, anchor)
		local anch = anchor or NewVector2(0, 0);
		local outer = self:CreateInstance("Frame", {
			Name = "Btn_" .. name; Parent = parent;
			AnchorPoint = anch;
			Position = NewUdim2(0, x, 0, y);
			Size = FromOffset(w or 52, 22);
			BackgroundColor3 = hex("07080A");
			BorderSizePixel = 0; ZIndex = 6;
		});
		local inner = self:CreateInstance("Frame", {
			Parent = outer;
			Position = NewUdim2(0, 1, 0, 1); Size = NewUdim2(1, -2, 1, -2);
			BackgroundColor3 = hex("24262D"); BorderSizePixel = 0; ZIndex = 7;
		});
		local body = self:CreateInstance("Frame", {
			Parent = inner;
			Position = NewUdim2(0, 1, 0, 1); Size = NewUdim2(1, -2, 1, -2);
			BackgroundColor3 = FromRgb(255, 255, 255); BorderSizePixel = 0; ZIndex = 8;
		});
		self:CreateInstance("UIGradient", {
			Parent = body; Rotation = 90;
			Color = NewColorSequence(hex("131418"), hex("17181D"));
		});
		local label = self:CreateInstance("TextLabel", {
			Parent = body;
			Size = NewUdim2(1, 0, 1, 0);
			BackgroundTransparency = 1;
			FontFace = Library.Fonts.title;
			Text = name;
			TextColor3 = hex("B4B4B4");
			TextSize = 9;
			ZIndex = 9;
		});
		local scale = self:CreateInstance("UIScale", { Parent = outer; Scale = 1; });
		local hit = self:CreateInstance("TextButton", {
			Parent = outer;
			Size = NewUdim2(1, 0, 1, 0);
			BackgroundTransparency = 1; AutoButtonColor = false; Text = ""; ZIndex = 10;
		});
		self:Connection(hit.MouseButton1Down, function() Library:Tween(scale, PressIn, { Scale = 0.94 }):Play(); end);
		self:Connection(hit.MouseButton1Up, function() Library:Tween(scale, PressOut, { Scale = 1 }):Play(); end);
		self:Connection(hit.MouseLeave, function() Library:Tween(scale, PressOut, { Scale = 1 }):Play(); end);
		return { outer = outer, body = body, label = label, scale = scale, hit = hit, name = name };
	end;

	--// Dex tab
	local DexPage = MakeTab("Dex").Page;
	local DexMenu = self:ContextMenu(gui);
	local DexBar = self:CreateInstance("Frame", {
		Name = "DexBar"; Parent = DexPage;
		Position = NewUdim2(0, 0, 0, 0);
		Size = NewUdim2(1, 0, 0, 28);
		BackgroundTransparency = 1;
		BorderSizePixel = 0;
		ZIndex = 6;
	});
	local DexSearchOuter = self:CreateInstance("Frame", {
		Name = "SearchOuter"; Parent = DexBar;
		Position = NewUdim2(0, 4, 0, 4);
		Size = NewUdim2(1, -56, 0, 20);
		BackgroundColor3 = hex("07080A");
		BorderSizePixel = 0;
		ZIndex = 6;
	});
	local DexSearchMid = self:CreateInstance("Frame", {
		Parent = DexSearchOuter;
		Position = NewUdim2(0, 1, 0, 1); Size = NewUdim2(1, -2, 1, -2);
		BackgroundColor3 = hex("24262D");
		BorderSizePixel = 0; ZIndex = 7;
	});
	local DexSearchBody = self:CreateInstance("Frame", {
		Parent = DexSearchMid;
		Position = NewUdim2(0, 1, 0, 1); Size = NewUdim2(1, -2, 1, -2);
		BackgroundColor3 = FromRgb(255, 255, 255);
		BorderSizePixel = 0; ZIndex = 8;
		ClipsDescendants = true;
	});
	self:CreateInstance("UIGradient", {
		Parent = DexSearchBody; Rotation = 90;
		Color = NewColorSequence(hex("131418"), hex("17181D"));
	});
	local DexSearch = self:CreateInstance("TextBox", {
		Name = "Search"; Parent = DexSearchBody;
		Size = NewUdim2(1, 0, 1, 0);
		BackgroundTransparency = 1;
		BorderSizePixel = 0;
		ClearTextOnFocus = false;
		FontFace = Library.Fonts.title;
		PlaceholderText = "search...";
		PlaceholderColor3 = hex("646464");
		Text = "";
		TextColor3 = FromRgb(255, 255, 255);
		TextSize = 9;
		TextXAlignment = Enum.TextXAlignment.Left;
		TextYAlignment = Enum.TextYAlignment.Center;
		ClipsDescendants = true;
		ZIndex = 9;
	});
	self:CreateInstance("UIPadding", { Parent = DexSearch; PaddingLeft = NewUdim(0, 4); PaddingRight = NewUdim(0, 4); });
	local DexScroll = self:CreateInstance("ScrollingFrame", {
		Name = "DexScroll"; Parent = DexPage;
		Position = NewUdim2(0, 0, 0, 28);
		Size = NewUdim2(1, 0, 1, -28);
		BackgroundTransparency = 1;
		BorderSizePixel = 0;
		ScrollBarThickness = 2;
		ScrollBarImageColor3 = hex("98BCFF");
		CanvasSize = NewUdim2(0, 0, 0, 0);
		AutomaticCanvasSize = Enum.AutomaticSize.Y;
		ZIndex = 5;
	});
	self:CreateInstance("UIPadding", { Parent = DexScroll; PaddingTop = NewUdim(0, 2); PaddingBottom = NewUdim(0, 2); });
	self:CreateInstance("UIListLayout", { Parent = DexScroll; SortOrder = Enum.SortOrder.LayoutOrder; });

	local DexState = setmetatable({}, { __mode = "k" });
	local SelectedDexRow = nil;
	local rootExpanded = false;
	local rootState = nil;
	local DexSearching = false;
	local ClassIcons = {
		Folder = "rbxassetid://6031073792";
		Model = "rbxassetid://6031085245";
		Part = "rbxassetid://6031073569";
		WedgePart = "rbxassetid://6031073569";
		MeshPart = "rbxassetid://6031073569";
		BasePart = "rbxassetid://6031073569";
		Script = "rbxassetid://6031090417";
		LocalScript = "rbxassetid://6031090417";
		ModuleScript = "rbxassetid://6031090812";
		RemoteEvent = "rbxassetid://6031073809";
		RemoteFunction = "rbxassetid://6031073809";
		BindableEvent = "rbxassetid://6031073809";
		BindableFunction = "rbxassetid://6031073809";
		Player = "rbxassetid://6031073222";
		Camera = "rbxassetid://6031085245";
	};
	local function DexIcon(inst)
		return ClassIcons[inst.ClassName] or "rbxassetid://6031085245";
	end;
	local function DexGlyph(inst)
		local c = inst.ClassName;
		if c == "Folder" then return "▣";
		elseif c == "Model" or c == "Camera" then return "◆";
		elseif c == "Part" or c == "WedgePart" or c == "MeshPart" or c == "BasePart" then return "●";
		elseif c == "Script" or c == "LocalScript" then return "▷";
		elseif c == "ModuleScript" then return "◈";
		elseif c:sub(1, 6) == "Remote" or c:sub(1, 7) == "Bindable" then return "◉";
		elseif c == "Player" then return "◉";
		else return "·"; end;
	end;
	local function DexColor(inst)
		local c = inst.ClassName;
		if c:sub(1, 6) == "Remote" or c:sub(1, 7) == "Bindable" then return hex("FFA657");
		elseif c == "Player" then return hex("98BCFF");
		elseif c == "Workspace" or c == "Lighting" or c == "ReplicatedStorage" then return hex("79C0FF");
		elseif c == "Script" or c == "LocalScript" or c == "ModuleScript" then return hex("7EE787");
		elseif c == "Part" or c == "MeshPart" or c == "BasePart" then return hex("A5D6FF");
		else return hex("B4B4B4"); end;
	end;
	local DexTween = NewTweenInfo(0.12, Enum.EasingStyle.Quad, Enum.EasingDirection.Out);

	local function SelectDexRow(row)
		SelectedDexRow = row;
	end;

	local DexSettingsWin = nil;
	local function OpenDexSettings(inst)
		if not inst then return end;
		if DexSettingsWin and DexSettingsWin.Parent then DexSettingsWin:Destroy(); end;
		local win = self:CreateInstance("Frame", {
			Name = "DexSettings"; Parent = gui;
			AnchorPoint = NewVector2(0.5, 0.5);
			Position = NewUdim2(0.5, 0, 0.5, 0);
			Size = FromOffset(320, 260);
			BackgroundColor3 = hex("07080A");
			BorderSizePixel = 0;
			ZIndex = 60;
			ClipsDescendants = true;
		});
		local winScale = self:CreateInstance("UIScale", { Parent = win; Scale = 0.9; });
		task.spawn(function() self:Tween(winScale, NewTweenInfo(0.16, Enum.EasingStyle.Back, Enum.EasingDirection.Out), { Scale = 1 }):Play(); end);
		local inner = self:CreateInstance("Frame", {
			Parent = win;
			Position = NewUdim2(0, 1, 0, 1); Size = NewUdim2(1, -2, 1, -2);
			BackgroundColor3 = hex("24262D"); BorderSizePixel = 0; ZIndex = 61;
		});
		local body = self:CreateInstance("Frame", {
			Parent = inner;
			Position = NewUdim2(0, 1, 0, 1); Size = NewUdim2(1, -2, 1, -2);
			BackgroundColor3 = FromRgb(255, 255, 255);
			BorderSizePixel = 0; ZIndex = 61;
		});
		self:CreateInstance("UIGradient", {
			Parent = body; Rotation = 90;
			Color = NewColorSequence(hex("131418"), hex("17181D"));
		});
		local AccentBar = self:CreateInstance("Frame", {
			Parent = body; Size = NewUdim2(1, 0, 0, 1);
			BackgroundColor3 = self.AccentColor or hex("98BCFF");
			BorderSizePixel = 0; ZIndex = 63;
		});
		self:CreateInstance("Frame", {
			Parent = body;
			Position = NewUdim2(0, 0, 0, 1); Size = NewUdim2(1, 0, 0, 1);
			BackgroundColor3 = self.ShadeColor or hex("6E8CC8");
			BorderSizePixel = 0; ZIndex = 63;
		});
		local header = self:CreateInstance("Frame", {
			Parent = body;
			Size = NewUdim2(1, 0, 0, 20);
			BackgroundTransparency = 1; BorderSizePixel = 0; ZIndex = 62;
		});
		local title = self:CreateInstance("TextLabel", {
			Parent = header;
			Position = NewUdim2(0, 6, 0, 3); Size = NewUdim2(1, -30, 1, -6);
			BackgroundTransparency = 1;
			FontFace = Library.Fonts.title;
			Text = "Settings  -  " .. inst.Name .. "  [" .. inst.ClassName .. "]";
			TextColor3 = FromRgb(255, 255, 255); TextSize = 9;
			TextXAlignment = Enum.TextXAlignment.Left;
			TextYAlignment = Enum.TextYAlignment.Top;
			ZIndex = 63;
		});
		self:CreateInstance("UIGradient", {
			Parent = title; Rotation = 90;
			Color = NewColorSequence(AccentBar.BackgroundColor3, self.ShadeColor or hex("6E8CC8"));
		});
		local close = self:CreateInstance("TextButton", {
			Parent = header;
			Position = NewUdim2(1, -18, 0, 1); Size = FromOffset(16, 18);
			BackgroundTransparency = 1; AutoButtonColor = false;
			FontFace = Library.Fonts.title; Text = "x";
			TextColor3 = hex("B4B4B4"); TextSize = 9; ZIndex = 63;
		});
		self:Connection(close.MouseButton1Click, function() win:Destroy(); DexSettingsWin = nil; end);
		self:Draggable(win, header);
		local scroll = self:CreateInstance("ScrollingFrame", {
			Parent = body;
			Position = NewUdim2(0, 0, 0, 22); Size = NewUdim2(1, 0, 1, -22);
			BackgroundTransparency = 1; BorderSizePixel = 0;
			ScrollBarThickness = 2; ScrollBarImageColor3 = hex("98BCFF");
			CanvasSize = NewUdim2(0, 0, 0, 0); AutomaticCanvasSize = Enum.AutomaticSize.Y;
			ZIndex = 62;
		});
		self:CreateInstance("UIPadding", { Parent = scroll; PaddingTop = NewUdim(0, 2); PaddingBottom = NewUdim(0, 2); PaddingLeft = NewUdim(0, 4); PaddingRight = NewUdim(0, 4); });
		self:CreateInstance("UIListLayout", { Parent = scroll; SortOrder = Enum.SortOrder.LayoutOrder; Padding = NewUdim(0, 1); });
		local ok, props = pcall(function() return inst:GetProperties() end);
		local Plist = (ok and typeof(props) == "table" and #props > 0) and props or nil;
		if not Plist then
			Plist = {};
			for _, n in { "Name", "ClassName" } do
				local s, v = pcall(function() return inst[n] end);
				if s then insert(Plist, { Name = n, Value = v, Type = "String" }); end;
			end;
			if inst:IsA("BasePart") then
				for _, n in { "Position", "Size", "Orientation", "Anchored", "CanCollide", "Transparency", "Material", "Color" } do
					local s, v = pcall(function() return inst[n] end);
					if s and v ~= nil then insert(Plist, { Name = n, Value = v, Type = "Variant" }); end;
				end;
			end;
		end;
		local rows = 0;
		for _, p in Plist do
			local pname = tostring(p.Name or "?");
			local val = tostring(p.Value);
			if #val > 180 then val = val:sub(1, 180) .. "..."; end;
			local tstr = tostring(p.Type or "");
			self:CreateInstance("TextLabel", {
				Parent = scroll;
				Size = NewUdim2(1, 0, 0, 16);
				BackgroundTransparency = 1;
				FontFace = Library.Fonts.title;
				Text = pname .. " = " .. val;
				TextColor3 = (tstr:lower():find("color") and hex("79C0FF")) or (tstr:lower():find("bool") and hex("7EE787")) or hex("B4B4B4");
				TextSize = 8;
				TextXAlignment = Enum.TextXAlignment.Left;
				TextTruncate = Enum.TextTruncate.AtEnd;
				LayoutOrder = rows; ZIndex = 63;
			});
			rows += 1;
		end;
		if rows == 0 then
			self:CreateInstance("TextLabel", {
				Parent = scroll;
				Size = NewUdim2(1, 0, 0, 16);
				BackgroundTransparency = 1;
				FontFace = Library.Fonts.title;
				Text = "(no properties)";
				TextColor3 = hex("646464"); TextSize = 8;
				TextXAlignment = Enum.TextXAlignment.Left; ZIndex = 63;
			});
		end;
		DexSettingsWin = win;
	end;
	local function TryScriptSource(s)
		if typeof(s) ~= "Instance" or not s:IsA("LuaSourceContainer") then return nil end;
		local ok, src = pcall(function() return s.Source end);
		if ok and typeof(src) == "string" and src ~= "" then return src end;
		local ok2, bc = pcall(function()
			if getscriptbytecode then return getscriptbytecode(s) end;
		end);
		if ok2 and bc then
			local ok3, ds = pcall(function() return decompile(bc) end);
			if ok3 and typeof(ds) == "string" and ds ~= "" then return ds end;
		end;
		local ok4, d = pcall(function() return decompile(s) end);
		if ok4 and typeof(d) == "string" and d ~= "" then return d end;
		return nil;
	end;
	local function DexRightClick(inst)
		local mx, my = UserInputService:GetMouseLocation().X, UserInputService:GetMouseLocation().Y;
		local full = pcall(function() return inst:GetFullName() end);
		full = full and tostring(full) or inst.Name;
		local items = {
			{ Text = "Copy Name", OnClick = function() self:SetClipboard(inst.Name) end };
			{ Text = "Copy Path", OnClick = function() self:SetClipboard(full) end };
			"Divider";
			{ Text = "Settings", OnClick = function() OpenDexSettings(inst) end };
		};
		if inst:IsA("LuaSourceContainer") then
			insert(items, "Divider");
			insert(items, { Text = "View Source", OnClick = function()
				local src = TryScriptSource(inst);
				if src then
					self:OpenInIDE('--[[' .. full .. ']]\n' .. src);
				else
					Library:Notify({ Text = "Could not read source for " .. inst.Name });
				end;
			end });
		end;
		insert(items, "Divider");
		insert(items, { Text = "Open in IDE", OnClick = function() self:OpenInIDE('--[[' .. full .. ']]\nlocal obj = ' .. InstExpr(inst)) end });
		DexMenu.Open(mx, my, items);
	end;
	local DexRowByInst = setmetatable({}, { __mode = "k" });
	local FindDexRow;
	local RevealInTree;
	local function MakeDexRow(parent, inst, depth)
		local row = self:CreateInstance("Frame", {
			Name = "Row"; Parent = parent;
			Size = NewUdim2(1, 0, 0, 18);
			BackgroundTransparency = 1;
			BorderSizePixel = 0;
			ZIndex = 5;
		});
		DexRowByInst[inst] = row;
		self:CreateInstance("TextLabel", {
			Name = "Label"; Parent = row;
			Position = NewUdim2(0, 4, 0, 0);
			Size = NewUdim2(1, -8, 1, 0);
			BackgroundTransparency = 1;
			FontFace = Library.Fonts.title;
			Text = inst.Name;
			TextColor3 = hex("DADADA");
			TextSize = 9;
			TextXAlignment = Enum.TextXAlignment.Left;
			TextYAlignment = Enum.TextYAlignment.Center;
			TextTruncate = Enum.TextTruncate.AtEnd;
			ZIndex = 6;
		});
		local hit = self:CreateInstance("TextButton", {
			Name = "Hit"; Parent = row;
			Size = NewUdim2(1, 0, 1, 0);
			BackgroundTransparency = 1; AutoButtonColor = false; Text = ""; ZIndex = 7;
		});
		self:Connection(hit.MouseEnter, function()
			if SelectedDexRow ~= row then
				self:Tween(row, DexTween, { BackgroundColor3 = FromRgb(255, 255, 255); BackgroundTransparency = 0.9 }):Play();
			end;
		end);
		self:Connection(hit.MouseLeave, function()
			if SelectedDexRow ~= row then
				self:Tween(row, DexTween, { BackgroundTransparency = 1 }):Play();
			end;
		end);
		return row, hit;
	end;
	local ImportantServices = {
		Workspace = true; ReplicatedStorage = true;
	};
	local function GetTargetH(ch)
		local v = ch:GetAttribute("TargetH");
		return typeof(v) == "number" and v or ch.Size.Y.Offset;
	end;
	local function SetTargetH(inst, v)
		inst:SetAttribute("TargetH", v);
	end;
	local function BubbleHeight(cont)
		if not cont or not cont.Parent then return end;
		local content = cont:FindFirstChild("Content");
		if content then
			local h = 0;
			for _, ch in content:GetChildren() do
				if ch:IsA("Frame") then
					h += GetTargetH(ch);
				end;
			end;
			SetTargetH(cont, h);
			local tt = NewTweenInfo(0.14, Enum.EasingStyle.Quad, Enum.EasingDirection.Out);
			self:Tween(cont, tt, { Size = NewUdim2(1, 0, 0, h) }):Play();
			local rail = cont:FindFirstChild("Rail");
			if rail then self:Tween(rail, tt, { Size = NewUdim2(0, 1, 0, h) }):Play(); end;
		end;
		local p = cont.Parent;
		if p and p.Name == "Content" and p.Parent then
			BubbleHeight(p.Parent);
		end;
	end;
	local function MakeDexChildren(parent, inst, depth)
		local children = inst:GetChildren();
		local DirTween = NewTweenInfo(0.16, Enum.EasingStyle.Quad, Enum.EasingDirection.Out);
		for i, child in ipairs(children) do
			if inst == game then
				if not ImportantServices[child.Name] then continue end;
			else
				if child:IsA("BasePart") or child:IsA("Model") then continue end;
			end;
			local row, hit = MakeDexRow(parent, child, depth);
			row.LayoutOrder = i;
			local st = DexState[child];
			if not st then st = { Expanded = false, Built = false }; DexState[child] = st; end;
			local hasKids = #child:GetChildren() > 0;
			local cont = self:CreateInstance("Frame", {
				Name = "Children"; Parent = parent;
				Size = NewUdim2(1, 0, 0, 0);
				BackgroundTransparency = 1;
				BorderSizePixel = 0;
				ClipsDescendants = true;
				LayoutOrder = i + 0.5;
				Visible = false;
				ZIndex = 5;
			});
			local rail = self:CreateInstance("Frame", {
				Name = "Rail"; Parent = cont;
				Position = NewUdim2(0, 5, 0, 0);
				Size = NewUdim2(0, 1, 0, 0);
				BackgroundColor3 = hex("3A3D45");
				BorderSizePixel = 0;
				ZIndex = 6;
			});
			self:CreateInstance("Frame", {
				Name = "RailEnd"; Parent = rail;
				AnchorPoint = NewVector2(0.5, 1);
				Position = NewUdim2(0.5, 0, 1, 0);
				Size = FromOffset(3, 3);
				BackgroundColor3 = hex("3A3D45");
				BorderSizePixel = 0;
				ZIndex = 6;
			});
			local content = self:CreateInstance("Frame", {
				Name = "Content"; Parent = cont;
				Position = NewUdim2(0, 18, 0, 0);
				Size = NewUdim2(1, -18, 0, 0);
				AutomaticSize = Enum.AutomaticSize.Y;
				BackgroundTransparency = 1;
				BorderSizePixel = 0;
				ZIndex = 6;
			});
			self:CreateInstance("UIListLayout", { Parent = content; SortOrder = Enum.SortOrder.LayoutOrder; Padding = NewUdim(0, 1); });
			st.Container = cont;
			st.Content = content;
			local requires = {};
			if child:IsA("LuaSourceContainer") then
				local okr, rq = pcall(function() return child.Requires end);
				if okr and typeof(rq) == "table" then requires = rq end;
			end;
			if #requires > 0 then
				local depsBtn = self:CreateInstance("TextButton", {
					Name = "DepsBtn"; Parent = row;
					Position = NewUdim2(1, -16, 0, 0);
					Size = NewUdim2(0, 14, 1, 0);
					BackgroundTransparency = 1; AutoButtonColor = false; Text = "";
					ZIndex = 8;
				});
				local DepsPanel = self:CreateInstance("Frame", {
					Name = "Deps"; Parent = parent;
					Size = NewUdim2(1, 0, 0, 0);
					LayoutOrder = i + 0.25;
					BackgroundTransparency = 1;
					BorderSizePixel = 0;
					ClipsDescendants = true;
					Visible = false;
					ZIndex = 5;
				});
				local DepRail = self:CreateInstance("Frame", {
					Name = "Rail"; Parent = DepsPanel;
					Position = NewUdim2(0, 5, 0, 0);
					Size = NewUdim2(0, 1, 0, 0);
					BackgroundColor3 = hex("3A3D45");
					BorderSizePixel = 0;
					ZIndex = 6;
				});
				self:CreateInstance("Frame", {
					Name = "RailEnd"; Parent = DepRail;
					AnchorPoint = NewVector2(0.5, 1);
					Position = NewUdim2(0.5, 0, 1, 0);
					Size = FromOffset(3, 3);
					BackgroundColor3 = hex("3A3D45");
					BorderSizePixel = 0;
					ZIndex = 6;
				});
				local depContent = self:CreateInstance("Frame", {
					Name = "Content"; Parent = DepsPanel;
					Position = NewUdim2(0, 18, 0, 0);
					Size = NewUdim2(1, -18, 0, 0);
					AutomaticSize = Enum.AutomaticSize.Y;
					BackgroundTransparency = 1;
					BorderSizePixel = 0;
					ZIndex = 6;
				});
				self:CreateInstance("UIListLayout", { Parent = depContent; SortOrder = Enum.SortOrder.LayoutOrder; Padding = NewUdim(0, 1); });
				for ri, rinst in ipairs(requires) do
					local depRow = self:CreateInstance("Frame", {
						Name = "Dep"; Parent = depContent;
						Size = NewUdim2(1, 0, 0, 16);
						BackgroundTransparency = 1;
						BorderSizePixel = 0;
						LayoutOrder = ri;
						ZIndex = 6;
					});
					DexRowByInst[rinst] = depRow;
					self:CreateInstance("TextLabel", {
						Name = "Label"; Parent = depRow;
						Position = NewUdim2(0, 4, 0, 0);
						Size = NewUdim2(1, -8, 1, 0);
						BackgroundTransparency = 1;
						FontFace = Library.Fonts.title;
						Text = rinst.Name;
						TextColor3 = hex("B4B4B4");
						TextSize = 8;
						TextXAlignment = Enum.TextXAlignment.Left;
						TextYAlignment = Enum.TextYAlignment.Center;
						TextTruncate = Enum.TextTruncate.AtEnd;
						ZIndex = 7;
					});
					local depHit = self:CreateInstance("TextButton", {
						Parent = depRow;
						Size = NewUdim2(1, 0, 1, 0);
						BackgroundTransparency = 1; AutoButtonColor = false; Text = "";
						ZIndex = 8;
					});
					self:Connection(depHit.MouseEnter, function()
						if SelectedDexRow ~= depRow then
							self:Tween(depRow, DexTween, { BackgroundColor3 = FromRgb(255, 255, 255); BackgroundTransparency = 0.9 }):Play();
						end;
					end);
					self:Connection(depHit.MouseLeave, function()
						if SelectedDexRow ~= depRow then
							self:Tween(depRow, DexTween, { BackgroundTransparency = 1 }):Play();
						end;
					end);
					self:Connection(depHit.MouseButton1Click, function()
						RevealInTree(rinst);
					end);
				end;
				local DepOpen = false;
				self:Connection(depsBtn.MouseButton1Click, function()
					DepOpen = not DepOpen;
					local H = DepOpen and (#requires * 17 + 2) or 0;
					DepsPanel.Visible = true;
					SetTargetH(DepsPanel, H);
					self:Tween(DepsPanel, NewTweenInfo(0.14, Enum.EasingStyle.Quad, Enum.EasingDirection.Out), { Size = NewUdim2(1, 0, 0, H) }):Play();
					self:Tween(DepRail, NewTweenInfo(0.14, Enum.EasingStyle.Quad, Enum.EasingDirection.Out), { Size = NewUdim2(0, 1, 0, H) }):Play();
					BubbleHeight(parent.Parent);
					task.delay(0.14, function()
						if not DepOpen and DepsPanel and DepsPanel.Parent then DepsPanel.Visible = false end;
					end);
				end);
			end;
			self:Connection(hit.MouseButton1Click, function()
				SelectDexRow(row);
				if not hasKids then return end;
				local open = not st.Expanded;
				st.Expanded = open;
				if open then
					if not st.Built then
						st.Built = true;
						MakeDexChildren(content, child, depth + 1);
					end;
					cont.Visible = true;
					local h = 0;
					for _, ch in content:GetChildren() do
						if ch:IsA("Frame") then h += GetTargetH(ch) end;
					end;
					SetTargetH(cont, h);
					self:Tween(cont, DirTween, { Size = NewUdim2(1, 0, 0, h) }):Play();
					self:Tween(rail, DirTween, { Size = NewUdim2(0, 1, 0, h) }):Play();
					BubbleHeight(parent.Parent);
				else
					SetTargetH(cont, 0);
					BubbleHeight(parent.Parent);
					local t = self:Tween(cont, DirTween, { Size = NewUdim2(1, 0, 0, 0) });
					t:Play();
					t.Completed:Once(function()
						if not st.Expanded and cont and cont.Parent then
							cont.Visible = false;
							cont.Size = NewUdim2(1, 0, 0, 0);
							rail.Size = NewUdim2(0, 1, 0, 0);
						end;
					end);
				end;
			end);
			self:Connection(hit.MouseButton2Click, function() DexRightClick(child) end);
		end;
	end;
	local function BuildDexTree()
		for _, ch in DexScroll:GetChildren() do
			if ch:IsA("TextButton") or ch:IsA("Frame") or ch:IsA("ImageLabel") or ch:IsA("TextLabel") then ch:Destroy() end;
		end;
		for k in pairs(DexState) do DexState[k] = nil end;
		SelectedDexRow = nil;
		local rootRow, rootHit = MakeDexRow(DexScroll, game, 0);
		rootRow.LayoutOrder = 1;
		local rootCont = self:CreateInstance("Frame", {
			Name = "Children"; Parent = DexScroll;
			Size = NewUdim2(1, 0, 0, 0);
			BackgroundTransparency = 1;
			BorderSizePixel = 0;
			ClipsDescendants = true;
			LayoutOrder = 1.5;
			Visible = false;
			ZIndex = 5;
		});
		local rootRail = self:CreateInstance("Frame", {
			Name = "Rail"; Parent = rootCont;
			Position = NewUdim2(0, 5, 0, 0);
			Size = NewUdim2(0, 1, 0, 0);
			BackgroundColor3 = hex("3A3D45");
			BorderSizePixel = 0;
			ZIndex = 6;
		});
		self:CreateInstance("Frame", {
			Name = "RailEnd"; Parent = rootRail;
			AnchorPoint = NewVector2(0.5, 1);
			Position = NewUdim2(0.5, 0, 1, 0);
			Size = FromOffset(3, 3);
			BackgroundColor3 = hex("3A3D45");
			BorderSizePixel = 0;
			ZIndex = 6;
		});
		local rootContent = self:CreateInstance("Frame", {
			Name = "Content"; Parent = rootCont;
			Position = NewUdim2(0, 18, 0, 0);
			Size = NewUdim2(1, -18, 0, 0);
			AutomaticSize = Enum.AutomaticSize.Y;
			BackgroundTransparency = 1;
			BorderSizePixel = 0;
			ZIndex = 6;
		});
		self:CreateInstance("UIListLayout", { Parent = rootContent; SortOrder = Enum.SortOrder.LayoutOrder; Padding = NewUdim(0, 1); });
		rootState = { Expanded = false, Built = true, Container = rootCont, Content = rootContent };
		MakeDexChildren(rootContent, game, 1);
		local RootDirTween = NewTweenInfo(0.16, Enum.EasingStyle.Quad, Enum.EasingDirection.Out);
		self:Connection(rootHit.MouseButton1Click, function()
			SelectDexRow(rootRow);
			rootExpanded = not rootExpanded;
			if rootExpanded then
				rootCont.Visible = true;
				local h = 0;
				for _, ch in rootContent:GetChildren() do
					if ch:IsA("Frame") then h += GetTargetH(ch) end;
				end;
				SetTargetH(rootCont, h);
				self:Tween(rootCont, RootDirTween, { Size = NewUdim2(1, 0, 0, h) }):Play();
				self:Tween(rootRail, RootDirTween, { Size = NewUdim2(0, 1, 0, h) }):Play();
			else
				SetTargetH(rootCont, 0);
				local t = self:Tween(rootCont, RootDirTween, { Size = NewUdim2(1, 0, 0, 0) });
				t:Play();
				t.Completed:Once(function()
					if not rootExpanded and rootCont and rootCont.Parent then
						rootCont.Visible = false;
						rootCont.Size = NewUdim2(1, 0, 0, 0);
						rootRail.Size = NewUdim2(0, 1, 0, 0);
					end;
				end);
			end;
		end);
		self:Connection(rootHit.MouseButton2Click, function() DexRightClick(game) end);
		task.defer(function()
			if rootCont and rootCont.Parent then
				rootExpanded = true;
				rootCont.Visible = true;
				local h = 0;
				for _, ch in rootContent:GetChildren() do
					if ch:IsA("Frame") then h += GetTargetH(ch) end;
				end;
				SetTargetH(rootCont, h);
				rootCont.Size = NewUdim2(1, 0, 0, h);
				rootRail.Size = NewUdim2(0, 1, 0, h);
			end;
		end);
	end;
	FindDexRow = function(inst)
		if not inst then return nil end;
		return DexRowByInst[inst];
	end;
	RevealInTree = function(inst)
		if not inst then return end;
		if DexSearching then
			DexSearching = false;
			DexSearch.Text = "";
		end;
		if inst == game then return end;
		local chain = {};
		local cur = inst;
		while cur and cur.Parent and cur ~= game do
			insert(chain, 1, cur);
			cur = cur.Parent;
		end;
		if cur ~= game then return end;
		local curNode = game;
		local st = rootState;
		local depth = 1;
		for _, node in ipairs(chain) do
			if not st or not st.Content then break end;
			st.Expanded = true;
			st.Container.Visible = true;
			if not st.Built then
				st.Built = true;
				MakeDexChildren(st.Content, curNode, depth);
			end;
			local h = 0;
			for _, ch in st.Content:GetChildren() do
				if ch:IsA("Frame") then h += ch.Size.Y.Offset end;
			end;
			st.Container.Size = NewUdim2(1, 0, 0, h);
			local rail = st.Container:FindFirstChild("Rail");
			if rail then rail.Size = NewUdim2(0, 1, 0, h) end;
			task.spawn(function()
				local c = st.Content;
				if c and c.Parent then
					for _, ch in c:GetChildren() do
						if ch:IsA("GuiObject") then
							pcall(function() self:Tween(ch, NewTweenInfo(0.14, Enum.EasingStyle.Quad, Enum.EasingDirection.Out), { BackgroundTransparency = 0; TextTransparency = 0 }):Play(); end);
						end;
					end;
				end;
			end);
			depth += 1;
			curNode = node;
			st = DexState[node];
		end;
		local targetRow = FindDexRow(inst);
		if targetRow then
			SelectDexRow(targetRow);
			pcall(function()
				local sp = DexScroll.AbsolutePosition;
				local rp = targetRow.AbsolutePosition;
				local cy = DexScroll.CanvasPosition.Y + (rp.Y - sp.Y) - 4;
				DexScroll.CanvasPosition = NewVector2(DexScroll.CanvasPosition.X, MathMax(0, cy));
			end);
		end;
	end;
	local function MakeDexSearchRow(parent, inst, index)
		local row = self:CreateInstance("Frame", {
			Name = "SearchRow"; Parent = parent;
			Size = NewUdim2(1, 0, 0, 18);
			BackgroundTransparency = 1;
			BorderSizePixel = 0;
			LayoutOrder = index;
			ZIndex = 5;
		});
		DexRowByInst[inst] = row;
		self:CreateInstance("TextLabel", {
			Name = "Label"; Parent = row;
			Position = NewUdim2(0, 4, 0, 0);
			Size = NewUdim2(1, -174, 1, 0);
			BackgroundTransparency = 1;
			FontFace = Library.Fonts.title;
			Text = inst.Name;
			TextColor3 = hex("DADADA");
			TextSize = 9;
			TextXAlignment = Enum.TextXAlignment.Left;
			TextYAlignment = Enum.TextYAlignment.Center;
			TextTruncate = Enum.TextTruncate.AtEnd;
			ZIndex = 6;
		});
		local full = pcall(function() return inst:GetFullName() end);
		full = full and tostring(full) or inst.Name;
		self:CreateInstance("TextLabel", {
			Name = "Path"; Parent = row;
			AnchorPoint = NewVector2(1, 0);
			Position = NewUdim2(1, -8, 0, 0);
			Size = NewUdim2(0, 150, 1, 0);
			BackgroundTransparency = 1;
			FontFace = Library.Fonts.title;
			Text = full;
			TextColor3 = hex("5F636C");
			TextSize = 7;
			TextXAlignment = Enum.TextXAlignment.Right;
			TextYAlignment = Enum.TextYAlignment.Center;
			TextTruncate = Enum.TextTruncate.AtEnd;
			ZIndex = 6;
		});
		local hit = self:CreateInstance("TextButton", {
			Name = "Hit"; Parent = row;
			Size = NewUdim2(1, 0, 1, 0);
			BackgroundTransparency = 1; AutoButtonColor = false; Text = "";
			ZIndex = 8;
		});
		self:Connection(hit.MouseEnter, function()
			if SelectedDexRow ~= row then
				self:Tween(row, DexTween, { BackgroundColor3 = FromRgb(255, 255, 255); BackgroundTransparency = 0.9 }):Play();
			end;
		end);
		self:Connection(hit.MouseLeave, function()
			if SelectedDexRow ~= row then
				self:Tween(row, DexTween, { BackgroundTransparency = 1 }):Play();
			end;
		end);
		self:Connection(hit.MouseButton1Click, function() RevealInTree(inst) end);
		self:Connection(hit.MouseButton2Click, function() DexRightClick(inst) end);
		return row;
	end;
	local function ClearDex()
		for _, ch in DexScroll:GetChildren() do
			if ch:IsA("TextButton") or ch:IsA("Frame") or ch:IsA("ImageLabel") or ch:IsA("TextLabel") then ch:Destroy() end;
		end;
		SelectedDexRow = nil;
	end;
	local function BuildDexSearch(q)
		ClearDex();
		local results = {};
		local function Walk(inst, depth)
			if #results >= 400 then return end;
			for _, ch in inst:GetChildren() do
				if #results >= 400 then return end;
				if ch.Name:lower():find(q, 1, true) then
					results[#results + 1] = ch;
				end;
				if depth < 24 then Walk(ch, depth + 1) end;
			end;
		end;
		for _, svc in next, { game:FindFirstChild("Workspace"); game:FindFirstChild("ReplicatedStorage") } do
			if svc then Walk(svc, 0) end;
		end;
		for i, inst in ipairs(results) do
			MakeDexSearchRow(DexScroll, inst, i);
		end;
		if #results == 0 then
			self:CreateInstance("TextLabel", {
				Parent = DexScroll;
				Size = NewUdim2(1, 0, 0, 18);
				BackgroundTransparency = 1;
				FontFace = Library.Fonts.title;
				Text = "no results";
				TextColor3 = hex("646464");
				TextSize = 9;
				TextXAlignment = Enum.TextXAlignment.Left;
				LayoutOrder = 1;
				ZIndex = 6;
			});
		end;
	end;
	local function RefreshDex()
		local q = DexSearch.Text:lower():gsub("^%s+", ""):gsub("%s+$", "");
		if q == "" then
			DexSearching = false;
			BuildDexTree();
		else
			DexSearching = true;
			BuildDexSearch(q);
		end;
	end;
	local DexRefresh = MakeActButton(DexBar, "Refresh", -4, 3, 42, NewVector2(1, 0));
	self:Connection(DexRefresh.hit.MouseButton1Click, function() RefreshDex(); end);
	self:Connection(DexSearch:GetPropertyChangedSignal("Text"), RefreshDex);
	BuildDexTree();

	--// Player tab (join / leave / chat log)
	local PlayerPage = MakeTab("Player").Page;
	local Players = game:GetService("Players");
	local PlayerLines = {};
	local PlayerScroll = self:CreateInstance("ScrollingFrame", {
		Name = "PlayerScroll"; Parent = PlayerPage;
		Position = NewUdim2(0, 0, 0, 0);
		Size = NewUdim2(1, 0, 1, 0);
		BackgroundTransparency = 1;
		BorderSizePixel = 0;
		ScrollBarThickness = 2;
		ScrollBarImageColor3 = hex("98BCFF");
		CanvasSize = NewUdim2(0, 0, 0, 0);
		AutomaticCanvasSize = Enum.AutomaticSize.Y;
		ZIndex = 5;
	});
	self:CreateInstance("UIPadding", { Parent = PlayerScroll; PaddingTop = NewUdim(0, 2); PaddingBottom = NewUdim(0, 2); PaddingLeft = NewUdim(0, 4); PaddingRight = NewUdim(0, 4); });
	local PlayerLabel = self:CreateInstance("TextLabel", {
		Name = "PlayerLabel"; Parent = PlayerScroll;
		Position = NewUdim2(0, 0, 0, 0);
		Size = NewUdim2(1, 0, 0, 0);
		AutomaticSize = Enum.AutomaticSize.Y;
		BackgroundTransparency = 1;
		BorderSizePixel = 0;
		FontFace = Library.Fonts.title;
		Text = "";
		TextColor3 = hex("B4B4B4");
		TextSize = 9;
		TextXAlignment = Enum.TextXAlignment.Left;
		TextYAlignment = Enum.TextYAlignment.Top;
		TextWrapped = true;
		RichText = true;
		ZIndex = 6;
	});
	local function PlayerLog(color, text)
		insert(PlayerLines, '<font color="' .. color .. '">' .. EscTxt(text) .. '</font>');
		if #PlayerLines > 300 then table.remove(PlayerLines, 1) end;
		PlayerLabel.Text = concat(PlayerLines, "\n");
		task.spawn(function() PlayerScroll.CanvasPosition = NewVector2(0, 999999) end);
	end;
	local function HookChat(player)
		pcall(function()
			player.Chatted:Connect(function(msg)
				PlayerLog("#B4B4B4", ("[%s] %s: %s"):format(os.date("%H:%M:%S"), player.Name, tostring(msg)));
			end);
		end);
	end;
	self:Connection(Players.PlayerAdded, function(p)
		task.defer(function()
			if typeof(p) == "Instance" then
				PlayerLog("#7EE787", ("[%s] %s joined"):format(os.date("%H:%M:%S"), p.Name));
				HookChat(p);
			end;
		end);
	end);
	self:Connection(Players.PlayerRemoving, function(p)
		task.defer(function()
			if typeof(p) == "Instance" then
				PlayerLog("#FF7B72", ("[%s] %s left"):format(os.date("%H:%M:%S"), p.Name));
			end;
		end);
	end);
	task.spawn(function()
		task.wait(0.1);
		for _, p in Players:GetPlayers() do HookChat(p) end;
	end);

	--// Lua console tab
	local LuaPage = MakeTab("Lua").Page;
	local LuaConsoleScroll = self:CreateInstance("ScrollingFrame", {
		Name = "LuaConsoleScroll"; Parent = LuaPage;
		Position = NewUdim2(0, 0, 0, 28);
		Size = NewUdim2(1, 0, 1, -28);
		BackgroundTransparency = 1;
		BorderSizePixel = 0;
		ScrollBarThickness = 2;
		ScrollBarImageColor3 = hex("98BCFF");
		CanvasSize = NewUdim2(0, 0, 0, 0);
		AutomaticCanvasSize = Enum.AutomaticSize.Y;
		ZIndex = 5;
	});
	local LuaConsoleLabel = self:CreateInstance("TextLabel", {
		Name = "LuaConsoleLabel"; Parent = LuaConsoleScroll;
		Position = NewUdim2(0, 4, 0, 2);
		Size = NewUdim2(1, -8, 0, 0);
		AutomaticSize = Enum.AutomaticSize.Y;
		BackgroundTransparency = 1;
		BorderSizePixel = 0;
		FontFace = Library.Fonts.title;
		Text = "";
		TextColor3 = hex("B4B4B4");
		TextSize = 9;
		TextXAlignment = Enum.TextXAlignment.Left;
		TextYAlignment = Enum.TextYAlignment.Top;
		TextWrapped = true;
		RichText = true;
		ZIndex = 6;
	});
	local LuaClearBtn = MakeActButton(LuaPage, "clear", -4, 2, 42, NewVector2(1, 0));
	local LuaSink = {
		Lines = {};
		Push = function(self, text, kind)
			insert(self.Lines, ColSpan(ConsoleColor(kind), text));
			if #self.Lines > 500 then table.remove(self.Lines, 1) end;
			LuaConsoleLabel.Text = concat(self.Lines, "\n");
			task.spawn(function() LuaConsoleScroll.CanvasPosition = NewVector2(0, 999999) end);
		end;
	};
	self:AddConsoleSink(LuaSink);
	self:Connection(LuaClearBtn.hit.MouseButton1Click, function()
		LuaSink.Lines = {};
		LuaConsoleLabel.Text = "";
	end);

	--// Events tab (empty)
	local EventsPage = MakeTab("Events").Page;

	SetActiveTab(ActivityTabs[1]);

	local panel = { Gui = gui, Outer = outer, Tabs = ActivityTabs, Visible = true };
	function panel:SetVisible(on)
		Library:SetWidgetVisible(self, on);
	end;
	function panel:Destroy()
		Library:RemoveConsoleSink(LuaSink);
		if self.Gui and self.Gui.Parent then self.Gui:Destroy() end;
		if Library.CurrentActivity == panel then Library.CurrentActivity = nil end;
	end;
	self.CurrentActivity = panel;
	self:TrackWidget(panel, "Activity");
	return panel;
end;

--// Unload
function Library:Unload()
	self:Log("Unload requested");
	for _, conn in self.Connections do
		if conn ~= nil then
			conn:Disconnect();
		end;
	end;
	self.Connections = {};

	local win = self.CurrentWindow;
	if typeof(win) == "table" and typeof(win.Gui) == "Instance" and win.Gui.Parent then
		win.Gui:Destroy();
	end;
	self.CurrentWindow = nil;

	local dock = self.CurrentDock;
	if typeof(dock) == "table" and typeof(dock.Gui) == "Instance" and dock.Gui.Parent then
		dock.Gui:Destroy();
	end;
	self.CurrentDock = nil;

	local preview = self.CurrentEspPreview;
	if typeof(preview) == "table" and typeof(preview.Gui) == "Instance" and preview.Gui.Parent then
		preview.Gui:Destroy();
	end;
	self.CurrentEspPreview = nil;

	local cfgs = self.CurrentConfigs;
	if typeof(cfgs) == "table" and typeof(cfgs.Gui) == "Instance" and cfgs.Gui.Parent then
		cfgs.Gui:Destroy();
	end;
	self.CurrentConfigs = nil;

	local pl = self.CurrentPlayerList;
	if typeof(pl) == "table" and typeof(pl.Gui) == "Instance" and pl.Gui.Parent then
		pl.Gui:Destroy();
	end;
	self.CurrentPlayerList = nil;

	local kbl = self.CurrentKeybindList;
	if typeof(kbl) == "table" and typeof(kbl.Gui) == "Instance" and kbl.Gui.Parent then
		kbl.Gui:Destroy();
	end;
	self.CurrentKeybindList = nil;

	local wm = self.CurrentWatermark;
	if typeof(wm) == "table" and typeof(wm.Gui) == "Instance" and wm.Gui.Parent then
		wm.Gui:Destroy();
	end;
	self.CurrentWatermark = nil;

	local app = self.CurrentAppearance;
	if typeof(app) == "table" and typeof(app.Gui) == "Instance" and app.Gui.Parent then
		app.Gui:Destroy();
	end;
	self.CurrentAppearance = nil;

	local LuaEd = self.CurrentLuaEditor;
	if typeof(LuaEd) == "table" and typeof(LuaEd.Gui) == "Instance" and LuaEd.Gui.Parent then
		LuaEd.Gui:Destroy();
	end;
	self.CurrentLuaEditor = nil;

	local Act = self.CurrentActivity;
	if typeof(Act) == "table" and typeof(Act.Gui) == "Instance" and Act.Gui.Parent then
		Act:Destroy();
	end;
	self.CurrentActivity = nil;

	local MapPanel = self.CurrentMapPanel;
	if typeof(MapPanel) == "table" and typeof(MapPanel.Gui) == "Instance" and MapPanel.Gui.Parent then
		MapPanel.Gui:Destroy();
	end;
	self.CurrentMapPanel = nil;

	if self.MenuDimTween then
		self.MenuDimTween:Cancel();
		self.MenuDimTween = nil;
	end;
	if typeof(self.MenuDimGui) == "Instance" and self.MenuDimGui.Parent then
		self.MenuDimGui:Destroy();
	end;
	self.MenuDimGui = nil;

	self.Flags = {};
	self.Toggles = {};
	self.Options = {};
	self:Log("Unload complete");
end;

Library:Log("Library ready");

return Library;
