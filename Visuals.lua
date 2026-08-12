local Visuals = {
    Instances = {},
    ScreenGui = nil,
    Debug = false,
    EffectHolder = game:GetObjects("rbxassetid://17192721766")[1],
};

Visuals.__index = Visuals;
Visuals.Dependencies = { "Util" };

local Global = getgenv();
Global.Libraries = Global.Libraries or {};
local Libraries = Global.Libraries;

local Utility = Libraries.Util;
assert(Utility, "Visuals dependency missing: Util must be loaded before Visuals");

local Animations = Utility.Animations;
local Directory = Utility.Directory;

local Workspace = cloneref(game:GetService("Workspace"));
local RunService = cloneref(game:GetService("RunService"));
local UserInputService = cloneref(game:GetService("UserInputService"));

local Camera = Workspace.CurrentCamera;

if not isfile(Directory.Images .. "/GlowCircle.png") then
    writefile(Directory.Images .. "/GlowCircle.png", game:HttpGet('https://raw.githubusercontent.com/ewghost/lol/refs/heads/main/GlowCircle.png'))
end

Visuals.ScreenGui = Utility:Instance("ScreenGui", {
    Parent = gethui(),
    IgnoreGuiInset = true,
    DisplayOrder = 2,
});

function Visuals:Beam(Parent, Style, Color, Color2, Transparency, Transparency2, Lifetime, Origin, Destination, Options)
    Options = typeof(Options) == "table" and Options or {}
    local TravelSpeed = tonumber(Options.TravelSpeed)
    local TextureSpeed = tonumber(Options.TextureSpeed) or 10
    local TextureVariant = tostring(Options.TextureVariant or "Light")
    local UseTravel = TravelSpeed ~= nil and TravelSpeed > 0
    local FadeDuration = 0.5
    local StartColor = typeof(Color) == "Color3" and Color or Color3.fromRGB(255, 255, 255)
    local EndColor = typeof(Color2) == "Color3" and Color2 or StartColor

    Transparency = tonumber(Transparency) or 0
    Transparency2 = tonumber(Transparency2) or Transparency
    Lifetime = tonumber(Lifetime) or 1

    local Model = Instance.new("Model", Parent);

    local OriginPart = Utility:Instance("Part", {
        Size = Vector3.new(0.05, 0.05, 0.05),
        Position = Origin,
        CFrame = CFrame.new(Origin),
        Transparency = 1,
        Anchored = true,
        CanCollide = false,
        CanQuery = false,
        Parent = Model,
    });

    local DestinationPart = Utility:Instance("Part", {
        Size = Vector3.new(0.05, 0.05, 0.05),
        Position = UseTravel and Origin or Destination,
        CFrame = CFrame.new(UseTravel and Origin or Destination),
        Transparency = 1,
        Anchored = true,
        CanCollide = false,
        CanQuery = false,
        Parent = Model,
    });

    local OriginAttachment = Utility:Instance("Attachment", {
        Parent = OriginPart,
    });

    local DestinationAttachment = Utility:Instance("Attachment", {
        Parent = DestinationPart,
    });

    local Beam;
    local ExtraBeams = {}
    local BeamColor = Color ~= "Rainbow" and ColorSequence.new({
        ColorSequenceKeypoint.new(0, StartColor),
        ColorSequenceKeypoint.new(1, EndColor),
    }) or ColorSequence.new({
        ColorSequenceKeypoint.new(0, Color3.fromRGB(255, 255, 255)),
        ColorSequenceKeypoint.new(1, Color3.fromRGB(255, 255, 255)),
    });
    local BeamTransparency = NumberSequence.new {
        NumberSequenceKeypoint.new(0, Transparency),
        NumberSequenceKeypoint.new(1, Transparency2),
    } or NumberSequence.new {
        NumberSequenceKeypoint.new(0, 0),
        NumberSequenceKeypoint.new(1, 0),
    }
    if Style == "Flat" then
        Beam = Utility:Instance("Beam", {
            Brightness = 1,
            Color = BeamColor,
            LightEmission = 0.25,
            LightInfluence = 1,
            Texture = "rbxassetid://12781848822",
            TextureLength = 20,
            TextureMode = "Static",
            Width0 = 0.8,
            Width1 = 0.8,
            Segments = 10,
            Attachment0 = OriginAttachment,
            Attachment1 = DestinationAttachment,
            FaceCamera = true,
            TextureSpeed = TextureSpeed,
            Transparency = BeamTransparency,
        });
    end;

    if Style == "Lightning" then
        Beam = Utility:Instance("Beam", {
            Brightness = 5,
            Color = BeamColor,
            LightEmission = 1,
            LightInfluence = 0,
            Texture = "rbxassetid://7151778302",
            TextureLength = 3,
            TextureMode = "Static",
            Width0 = 0.5,
            Width1 = 0.5,
            Attachment0 = OriginAttachment,
            Attachment1 = DestinationAttachment,
            FaceCamera = true,
            TextureSpeed = TextureSpeed,
            ZOffset = 0,
            Transparency = BeamTransparency,
        });
    end;

    if Style == "Liquid" then
        Beam = Utility:Instance("Beam", {
            Texture = "rbxassetid://12788927812",
            TextureLength = 10,
            TextureMode = "Wrap",
            TextureSpeed = 1,
            Width0 = 0.3,
            Width1 = 0.3,
            LightEmission = 1,
            LightInfluence = 0,
            Brightness = 1,
            Attachment0 = OriginAttachment,
            Attachment1 = DestinationAttachment,
            FaceCamera = true,
            Transparency = BeamTransparency,
            Color = Color ~= "Rainbow" and ColorSequence.new({
                ColorSequenceKeypoint.new(0, StartColor),
                ColorSequenceKeypoint.new(0.5, Color3.new(1,1,1)),
                ColorSequenceKeypoint.new(1, EndColor),
            }) or BeamColor,
        });
    end;

    if Style == "Helix" then
        Beam = Utility:Instance("Beam", {
            Texture = "rbxassetid://7071778278",
            Brightness = 1.5,
            Transparency = BeamTransparency,
            LightEmission = 1,
            LightInfluence = 0,
            Segments = 1,
            TextureLength = 12,
            TextureMode = "Wrap",
            TextureSpeed = 1,
            Width0 = 0.6,
            Width1 = 0.6,
            FaceCamera = true,
            Attachment0 = OriginAttachment,
            Attachment1 = DestinationAttachment,
            Color = BeamColor,
        });
    end;

    if not Beam then
        Beam = Utility:Instance("Beam", {
            Brightness = 5,
            Color = BeamColor,
            LightEmission = 1,
            LightInfluence = 0,
            Texture = "",
            TextureLength = 1,
            TextureMode = "Stretch",
            Width0 = 0.1,
            Width1 = 0.1,
            Attachment0 = OriginAttachment,
            Attachment1 = DestinationAttachment,
            FaceCamera = true,
            TextureSpeed = TextureSpeed,
            Transparency = BeamTransparency,
        });
    end;

    Beam.Parent = Model;
    local RainbowConnection
    if UseTravel then
        local Distance = (Destination - Origin).Magnitude
        local TravelTime = Distance / TravelSpeed
        if TravelTime > 0 then
            local TravelTween = Animations:Tween(DestinationPart, TweenInfo.new(TravelTime, Enum.EasingStyle.Linear), {
                Position = Destination,
                CFrame = CFrame.new(Destination),
            })
            if TravelTween then
                TravelTween:Play()
            end
        end
    end

    local TextureTween = Animations:Tween(Beam, TweenInfo.new(5, Enum.EasingStyle.Exponential, Enum.EasingDirection.Out, 0, false, 0), {
        TextureSpeed = math.max(0.5, TextureSpeed * 0.2)
    });
    if TextureTween then
        TextureTween:Play()
    end

    local SpeedTween = Animations:Tween(Beam,
        TweenInfo.new(0.6, Enum.EasingStyle.Quad, Enum.EasingDirection.InOut, 2, true), {
            TextureSpeed = 2
        })
    if SpeedTween then
        SpeedTween:Play()
    end

    --[[Animations:Basic({
        Component = Beam,
        Property = "TextureSpeed",
        Value = 1,
        Speed = 0.5
    });]]

    Delay(Lifetime + 1, function()
        local FadeTween = Animations:Tween(Beam, TweenInfo.new(0.5, Enum.EasingStyle.Quint), {
            Width0 = 0,
            Width1 = 0,
            TextureSpeed = 1,
            Brightness = 0
        });

        for _, ExtraBeam in next, ExtraBeams do
            local ExtraFadeTween = Animations:Tween(ExtraBeam, TweenInfo.new(0.5, Enum.EasingStyle.Quint), {
                Width0 = 0,
                Width1 = 0,
                TextureSpeed = 1,
                Brightness = 0
            })
            if ExtraFadeTween then
                ExtraFadeTween:Play()
            end
        end

        if FadeTween then
            FadeTween:Play();
            FadeTween.Completed:Wait();
            Model:Destroy();
            if RainbowConnection then
                RainbowConnection:Disconnect();
                RainbowConnection = nil;
            end;
        else
            Model:Destroy();
            if RainbowConnection then
                RainbowConnection:Disconnect();
                RainbowConnection = nil;
            end;
        end;
    end);

    if Color == "Rainbow" then
        local Resolution = 12
        local Speed = 0.2
        local Span = 0.35
        local RainbowAccumulator = 0

        RainbowConnection = RunService.RenderStepped:Connect(function(DeltaTime)
            if not Beam or not Beam.Parent then return end
            RainbowAccumulator += DeltaTime
            if RainbowAccumulator < 1 / 30 then return end
            RainbowAccumulator = 0

            local Time = tick() * Speed
            local Keypoints = table.create(Resolution + 1)

            for Index = 0, Resolution do
                local Alpha = Index / Resolution
                local Hue = (Time + Alpha * Span) % 1

                Keypoints[Index + 1] =
                    ColorSequenceKeypoint.new(
                        Alpha,
                        Color3.fromHSV(Hue, 0.78, 1)
                    )
            end

            Beam.Color = ColorSequence.new(Keypoints)
        end)
    end

    return {
        Model = Model,
        Beam = Beam,
    };
end;

function Visuals:CreateFOVCircle()
    local FOVCircle = {};
    FOVCircle.__index = FOVCircle;

    FOVCircle.Radius = 200;
    FOVCircle.Thickness = 2;
    FOVCircle.GlowSize = 18;
    FOVCircle.GlowLayers = 8;
    FOVCircle.GlowTransparency = 0.75;
    FOVCircle.Transparency = 0;
    FOVCircle.RotateSpeed = 1.2;
    FOVCircle.Saturation = 0.45;
    FOVCircle.Color1 = Color3.fromRGB(255, 20, 147);
    FOVCircle.Color2 = Color3.fromRGB(255, 255, 255);
    FOVCircle.Rotation = 0;
    FOVCircle.GlowEnabled = false;
    FOVCircle.SpinEnabled = false;
    FOVCircle.FillEnabled = false;
    FOVCircle.FillTransparency = 0.85;
    FOVCircle.SmoothPosition = Vector2.new(0, 0);
    FOVCircle.HasExternalPosition = false;
    FOVCircle.ExternalPosition = nil;

    FOVCircle.Holder = Utility:Instance("Frame", {
        AnchorPoint = Vector2.new(0.5, 0.5),
        BackgroundTransparency = 1,
        Size = UDim2.fromOffset(FOVCircle.Radius * 2, FOVCircle.Radius * 2),
        Position = UDim2.fromScale(0.5, 0.5),
        Parent = self.ScreenGui,
        Visible = false,
    });

    FOVCircle.GlowHolder = Utility:Instance("Frame", {
        AnchorPoint = Vector2.new(0.5, 0.5),
        Position = UDim2.fromScale(0.5, 0.5),
        Size = UDim2.fromScale(1, 1),
        BackgroundTransparency = 1,
        ZIndex = 1,
        Parent = FOVCircle.Holder,
    });

    Utility:Instance("UICorner", {
        CornerRadius = UDim.new(1, 0),
        Parent = FOVCircle.GlowHolder,
    });

    FOVCircle.Circle = Utility:Instance("Frame", {
        AnchorPoint = Vector2.new(0.5, 0.5),
        Position = UDim2.fromScale(0.5, 0.5),
        Size = UDim2.fromScale(1, 1),
        BackgroundTransparency = 1,
        ZIndex = 5,
        Parent = FOVCircle.Holder,
    });

    Utility:Instance("UICorner", {
        CornerRadius = UDim.new(1, 0),
        Parent = FOVCircle.Circle,
    });

    FOVCircle.Fill = Utility:Instance("Frame", {
        AnchorPoint = Vector2.new(0.5, 0.5),
        Position = UDim2.fromScale(0.5, 0.5),
        Size = UDim2.fromScale(1, 1),
        BackgroundColor3 = Color3.fromRGB(255, 255, 255),
        BackgroundTransparency = 0.85,
        ZIndex = 2,
        Parent = FOVCircle.Holder,
        Visible = false,
    });

    Utility:Instance("UICorner", {
        CornerRadius = UDim.new(1, 0),
        Parent = FOVCircle.Fill,
    });

    FOVCircle.FillGradient = Utility:Instance("UIGradient", {
        Parent = FOVCircle.Fill,
    });

    FOVCircle.OuterGlow = {};
    for Index = 1, FOVCircle.GlowLayers do
        local Stroke = Utility:Instance("UIStroke", {
            ApplyStrokeMode = Enum.ApplyStrokeMode.Border,
            LineJoinMode = Enum.LineJoinMode.Round,
            Thickness = 1,
            Transparency = 1,
            Color = Color3.new(1, 1, 1),
            Enabled = false,
            Parent = FOVCircle.GlowHolder,
        });
        local Gradient = Utility:Instance("UIGradient", {
            Parent = Stroke,
        });
        FOVCircle.OuterGlow[Index] = { Stroke = Stroke, Gradient = Gradient };
    end;

    FOVCircle.InnerGlow = {};
    for Index = 1, FOVCircle.GlowLayers do
        local Frame = Utility:Instance("Frame", {
            AnchorPoint = Vector2.new(0.5, 0.5),
            Position = UDim2.fromScale(0.5, 0.5),
            Size = UDim2.fromScale(1, 1),
            BackgroundTransparency = 1,
            Parent = FOVCircle.GlowHolder,
        });
        Utility:Instance("UICorner", {
            CornerRadius = UDim.new(1, 0),
            Parent = Frame,
        });
        local Stroke = Utility:Instance("UIStroke", {
            ApplyStrokeMode = Enum.ApplyStrokeMode.Border,
            LineJoinMode = Enum.LineJoinMode.Round,
            Thickness = 1,
            Transparency = 1,
            Color = Color3.new(1, 1, 1),
            Enabled = false,
            Parent = Frame,
        });
        local Gradient = Utility:Instance("UIGradient", {
            Parent = Stroke,
        });
        FOVCircle.InnerGlow[Index] = { Frame = Frame, Stroke = Stroke, Gradient = Gradient };
    end;

    FOVCircle.RingStroke = Utility:Instance("UIStroke", {
        ApplyStrokeMode = Enum.ApplyStrokeMode.Border,
        LineJoinMode = Enum.LineJoinMode.Round,
        Thickness = FOVCircle.Thickness,
        Color = Color3.new(1, 1, 1),
        Parent = FOVCircle.Circle,
    });
    FOVCircle.RingGradient = Utility:Instance("UIGradient", {
        Parent = FOVCircle.RingStroke,
    });

    FOVCircle.InnerOutline = Utility:Instance("UIStroke", {
        ApplyStrokeMode = Enum.ApplyStrokeMode.Border,
        LineJoinMode = Enum.LineJoinMode.Round,
        Thickness = FOVCircle.Thickness,
        Color = Color3.new(1, 1, 1),
        Parent = FOVCircle.Circle,
    });
    FOVCircle.InnerGradient = Utility:Instance("UIGradient", {
        Parent = FOVCircle.InnerOutline,
    });

    FOVCircle.InsetFrame = Utility:Instance("Frame", {
        AnchorPoint = Vector2.new(0.5, 0.5),
        Position = UDim2.fromScale(0.5, 0.5),
        Size = UDim2.fromScale(1, 1),
        BackgroundTransparency = 1,
        Parent = FOVCircle.Circle,
    });
    Utility:Instance("UICorner", {
        CornerRadius = UDim.new(1, 0),
        Parent = FOVCircle.InsetFrame,
    });
    FOVCircle.InsetStroke = Utility:Instance("UIStroke", {
        ApplyStrokeMode = Enum.ApplyStrokeMode.Border,
        LineJoinMode = Enum.LineJoinMode.Round,
        Thickness = FOVCircle.Thickness,
        Color = Color3.new(1, 1, 1),
        Parent = FOVCircle.InsetFrame,
    });
    FOVCircle.InsetGradient = Utility:Instance("UIGradient", {
        Parent = FOVCircle.InsetStroke,
    });

    function FOVCircle:BuildSequence()
        return ColorSequence.new({
            ColorSequenceKeypoint.new(0, self.Color1),
            ColorSequenceKeypoint.new(1, self.Color2),
        });
    end;

    function FOVCircle:ApplyGradients(Sequence, Rotation)
        self.RingGradient.Color = Sequence;
        self.RingGradient.Rotation = Rotation;
        self.InnerGradient.Color = Sequence;
        self.InnerGradient.Rotation = Rotation;
        self.InsetGradient.Color = Sequence;
        self.InsetGradient.Rotation = Rotation;
        self.FillGradient.Color = Sequence;
        self.FillGradient.Rotation = Rotation;
        for Index = 1, #self.OuterGlow do
            local Layer = self.OuterGlow[Index];
            Layer.Gradient.Color = Sequence;
            Layer.Gradient.Rotation = Rotation;
        end;
        for Index = 1, #self.InnerGlow do
            local Layer = self.InnerGlow[Index];
            Layer.Gradient.Color = Sequence;
            Layer.Gradient.Rotation = Rotation;
        end;
    end;

    function FOVCircle:SetPosition(Position)
        self.HasExternalPosition = true;
        if typeof(Position) == "Vector2" then
            self.ExternalPosition = Position;
            self.Holder.Position = UDim2.fromOffset(Position.X, Position.Y);
        elseif typeof(Position) == "UDim2" then
            self.ExternalPosition = nil;
            self.Holder.Position = Position;
        end;
    end;

    function FOVCircle:SetRadius(Radius)
        Radius = tonumber(Radius) or self.Radius;
        self.Radius = Radius;
        local Diameter = Radius * 2;
        self.Holder.Size = UDim2.fromOffset(Diameter, Diameter);
    end;

    function FOVCircle:SetColor(Color1, Color2)
        if typeof(Color1) == "table" and typeof(Color1.Color) == "Color3" then
            Color1 = Color1.Color;
        end;
        if typeof(Color2) == "table" and typeof(Color2.Color) == "Color3" then
            Color2 = Color2.Color;
        end;
        Color1 = Color1 or self.Color1;
        Color2 = Color2 or Color1;
        self.Color1 = Color1;
        self.Color2 = Color2;
    end;

    function FOVCircle:SetFill(State, Transparency)
        self.FillEnabled = State == true;
        self.FillTransparency = tonumber(Transparency) or self.FillTransparency;
        self.Fill.Visible = self.FillEnabled;
        self.Fill.BackgroundTransparency = self.FillTransparency;
        self.FillGradient.Transparency = NumberSequence.new(self.FillTransparency);
    end;

    function FOVCircle:SetTransparency(Transparency)
        self.Transparency = math.clamp(tonumber(Transparency) or self.Transparency or 0, 0, 1);
    end;

    function FOVCircle:SetGlow(State)
        self.GlowEnabled = State == true;
    end;

    function FOVCircle:SetSpin(State)
        self.SpinEnabled = State == true;
        if not self.SpinEnabled then
            self.Rotation = 0;
        end;
    end;

    function FOVCircle:SetRainbow(State)
    end;

    function FOVCircle:SetVisible(State)
        self.Holder.Visible = State == true;
    end;

    function FOVCircle:Update(Settings, DeltaTime)
        Settings = typeof(Settings) == "table" and Settings or {};
        DeltaTime = tonumber(DeltaTime) or (1 / 60);

        local function GetColor(Value, Fallback)
            if typeof(Value) == "Color3" then
                return Value;
            elseif typeof(Value) == "table" and typeof(Value.Color) == "Color3" then
                return Value.Color;
            end;
            return Fallback;
        end;

        local Radius = Settings.Radius or Settings.FOVCircleRadius;
        local Visible = Settings.Visible;
        local Glow = Settings.Glow;
        local Fill = Settings.Fill;
        local Rotate = Settings.Rotate;
        local Transparency = Settings.Transparency;

        if Visible == nil then Visible = Settings.FOVCircle end;
        if Glow == nil then Glow = Settings.FOVCircleGlow end;
        if Fill == nil then Fill = Settings.FOVCircleFill end;
        if Rotate == nil then Rotate = Settings.FOVCircleRotate end;

        if Radius ~= nil then
            self:SetRadius(Radius);
        end;

        self:SetColor(
            GetColor(Settings.Color1 or Settings.FOVCircleGradient1, self.Color1),
            GetColor(Settings.Color2 or Settings.FOVCircleGradient2, self.Color2)
        );
        self:SetGlow(Glow == true);
        self:SetFill(Fill == true, Settings.FillTransparency);
        self:SetTransparency(Transparency);
        self:SetSpin(Rotate == true);

        if Visible ~= nil then
            self:SetVisible(Visible == true);
        end;

        if not self.Holder.Visible then
            return;
        end;

        if not self.HasExternalPosition then
            local Mouse = UserInputService:GetMouseLocation();
            self.SmoothPosition = self.SmoothPosition:Lerp(Vector2.new(Mouse.X, Mouse.Y), math.clamp(DeltaTime * 12, 0, 1));
            self.Holder.Position = UDim2.fromOffset(self.SmoothPosition.X, self.SmoothPosition.Y);
        elseif self.ExternalPosition then
            self.SmoothPosition = self.ExternalPosition;
        end;
        self.HasExternalPosition = false;

        if self.SpinEnabled then
            self.Rotation = (self.Rotation + self.RotateSpeed * DeltaTime * 60) % 360;
        else
            self.Rotation = 0;
        end;

        local Sequence = self:BuildSequence();
        self:ApplyGradients(Sequence, self.Rotation);

        local GlowOn = self.GlowEnabled;
        local Layers = self.GlowLayers;
        local Spread = self.GlowSize;
        local BaseT = math.clamp(self.GlowTransparency + (1 - self.GlowTransparency) * self.Transparency, 0, 1);

        for Index = 1, Layers do
            local Frac = Index / Layers;
            local T = BaseT + (1 - BaseT) * Frac;
            local Outer = self.OuterGlow[Index];
            if Outer then
                Outer.Stroke.Enabled = GlowOn;
                Outer.Stroke.Thickness = GlowOn and (self.Thickness + Spread * Frac) or 0;
                Outer.Stroke.Transparency = GlowOn and T or 1;
            end;
            local Inner = self.InnerGlow[Index];
            if Inner then
                local Inset = Spread * Frac;
                Inner.Frame.Size = UDim2.fromScale(1, 1) - UDim2.fromOffset(Inset * 2, Inset * 2);
                Inner.Stroke.Enabled = GlowOn;
                Inner.Stroke.Thickness = GlowOn and (Spread * Frac) or 0;
                Inner.Stroke.Transparency = GlowOn and T or 1;
            end;
        end;

        self.InsetStroke.Thickness = self.Thickness * 0.6;
        self.RingStroke.Thickness = self.Thickness;
        self.InnerOutline.Thickness = self.Thickness;
        local RingTransparency = NumberSequence.new(self.Transparency);
        self.RingStroke.Transparency = 0;
        self.InnerOutline.Transparency = 0;
        self.InsetStroke.Transparency = 0;
        self.RingGradient.Transparency = RingTransparency;
        self.InnerGradient.Transparency = RingTransparency;
        self.InsetGradient.Transparency = RingTransparency;
    end;

    FOVCircle:SetRadius(FOVCircle.Radius);
    FOVCircle:SetColor(FOVCircle.Color1, FOVCircle.Color2);

    return FOVCircle
end;

function Visuals:CreateCrosshair()
    local Crosshair = {};
    Crosshair.__index = Crosshair;

    Crosshair.Length = 20;
    Crosshair.Thickness = 2;
    Crosshair.Gap = 10;
    Crosshair.OutlineColor = Color3.fromRGB(0, 0, 0);
    Crosshair.OutlineThickness = 1;
    Crosshair.ArmNames = { "Top", "Right", "Bottom", "Left" };
    Crosshair.Strokes = {};

    Crosshair.Holder = Utility:Instance("Frame", {
        Name = "CrosshairRoot",
        AnchorPoint = Vector2.new(0.5, 0.5),
        Position = UDim2.fromOffset(Camera.ViewportSize.X * 0.5, Camera.ViewportSize.Y * 0.5),
        Size = UDim2.fromOffset(1, 1),
        BackgroundTransparency = 1,
        Visible = false,
        Parent = self.ScreenGui
    });

    local function CreateArm(Name)
        local Arm = Utility:Instance("Frame", {
            Name = Name,
            AnchorPoint = Vector2.new(0.5, 0.5),
            Position = UDim2.fromScale(0.5, 0.5),
            Size = UDim2.fromOffset(1, 1),
            BackgroundColor3 = Color3.fromRGB(255, 255, 255),
            BorderSizePixel = 0,
            Parent = Crosshair.Holder
        });

        Crosshair.Strokes[Name] = Utility:Instance("UIStroke", {
            Color = Crosshair.OutlineColor,
            Thickness = Crosshair.OutlineThickness,
            ApplyStrokeMode = Enum.ApplyStrokeMode.Border,
            Parent = Arm
        });

        return Arm;
    end;

    Crosshair.Top = CreateArm("Top");
    Crosshair.Right = CreateArm("Right");
    Crosshair.Bottom = CreateArm("Bottom");
    Crosshair.Left = CreateArm("Left");

    function Crosshair:SetLength(Pixels)
        self.Length = math.max(1, Pixels);
        self:UpdateSize();
    end;

    function Crosshair:SetThickness(Pixels)
        self.Thickness = math.max(1, Pixels);
        self.OutlineThickness = math.max(1, math.floor(self.Thickness * 0.5));

        for _, Name in ipairs(self.ArmNames) do
            self.Strokes[Name].Thickness = self.OutlineThickness;
        end;

        self:UpdateSize();
    end;

    function Crosshair:UpdateSize()
        local armLength = self.Length;
        local armThickness = self.Thickness;
        local offset = self.Gap + (armLength * 0.5);

        self.Top.Size = UDim2.fromOffset(armThickness, armLength);
        self.Bottom.Size = UDim2.fromOffset(armThickness, armLength);
        self.Left.Size = UDim2.fromOffset(armLength, armThickness);
        self.Right.Size = UDim2.fromOffset(armLength, armThickness);

        self.Top.Position = UDim2.new(0.5, 0, 0.5, -offset);
        self.Bottom.Position = UDim2.new(0.5, 0, 0.5, offset);
        self.Left.Position = UDim2.new(0.5, -offset, 0.5, 0);
        self.Right.Position = UDim2.new(0.5, offset, 0.5, 0);
    end;

    function Crosshair:SetRotation(Rotation)
        self.Holder.Rotation = Rotation;
    end;

    function Crosshair:SmoothRotation(Rotation)
        Animations:Basic({
            Component = self.Holder,
            Property = "Rotation",
            Value = Rotation
        });
    end;

    function Crosshair:SetVisible(State)
        self.Holder.Visible = State;
    end;

    function Crosshair:SetTransparency(Alpha)
        for _, Name in ipairs(self.ArmNames) do
            Animations:Basic({
                Component = self[Name],
                Property = "BackgroundTransparency",
                Value = Alpha
            });

            Animations:Basic({
                Component = self.Strokes[Name],
                Property = "Transparency",
                Value = Alpha
            });
        end;
    end;

    function Crosshair:SetColor(Color)
        for _, Name in ipairs(self.ArmNames) do
            Animations:Basic({
                Component = self[Name],
                Property = "BackgroundColor3",
                Value = Color
            });
        end;
    end;

    function Crosshair:SetPosition(Position)
        Animations:Basic({
            Component = self.Holder,
            Property = "Position",
            Value = Position,
            Speed = 0.05
        });
    end;

    Crosshair:UpdateSize();
    return Crosshair;
end;

function Visuals:CreateHitEffect(Parent, Style, Color, Origin, Lifetime, Scale, Transparency)
    local Model = Instance.new("Model", Parent);
    local OriginPart = Instance.new("Part");
    OriginPart.Parent = Model;
    OriginPart.Size = Vector3.new(0.1, 0.1, 0.1);
    OriginPart.Transparency = 1;
    OriginPart.Anchored = true;
    OriginPart.CanCollide = false;
    OriginPart.CanQuery = false;
    OriginPart.CFrame = CFrame.new(Origin);
    local Emitter;
    local EffectLifetime = tonumber(Lifetime) or 2;
    local EffectScale = math.max(tonumber(Scale) or 1, 0.1);
    local EffectTransparency = math.clamp(tonumber(Transparency) or 0, 0, 1);
    local function ScaleSequence(Sequence)
        local Keypoints = {};
        for _, Keypoint in ipairs(Sequence.Keypoints) do
            Keypoints[#Keypoints + 1] = NumberSequenceKeypoint.new(
                Keypoint.Time,
                Keypoint.Value * EffectScale,
                Keypoint.Envelope * EffectScale
            );
        end;
        return NumberSequence.new(Keypoints)
    end;
    local function FadeSequence(StartValue, EndValue)
        StartValue = EffectTransparency + (1 - EffectTransparency) * StartValue;
        EndValue = EffectTransparency + (1 - EffectTransparency) * EndValue;
        return NumberSequence.new({
            NumberSequenceKeypoint.new(0, StartValue),
            NumberSequenceKeypoint.new(1, EndValue),
        })
    end;

    if Style == "Dot" then
        Style = "Dots"
    end;

    if Style == "Sparks" then
        local Attachment = Instance.new("Attachment", OriginPart);
        Attachment.Name = "Attachment";

        local Shards = Instance.new("ParticleEmitter", Attachment);
        Shards.Name = "Shards";
        Shards.Brightness = 4;
        Shards.Color = ColorSequence.new(Color);
        Shards.Drag = 7.5;
        Shards.Lifetime = NumberRange.new(0.5, 1);
        Shards.Orientation = Enum.ParticleOrientation.VelocityParallel;
        Shards.Rate = 0;
        Shards.Rotation = NumberRange.new(90, 90);
        Shards.Size = ScaleSequence(NumberSequence.new({
            NumberSequenceKeypoint.new(0, 0),
            NumberSequenceKeypoint.new(0.24537815153598785, 0.675000011920929),
            NumberSequenceKeypoint.new(1, 0),
        }));
        Shards.Speed = NumberRange.new(10, 15);
        Shards.SpreadAngle = Vector2.new(-360, 360);
        Shards.Squash = NumberSequence.new(0.10999999940395355);
        Shards.Texture = "rbxassetid://8030734851";
        Shards.Transparency = FadeSequence(0, 0.7);

        local Slash = Instance.new("ParticleEmitter", Attachment);
        Slash.Name = "Slash";
        Slash.Brightness = 4;
        Slash.Color = ColorSequence.new(Color);
        Slash.FlipbookLayout = Enum.ParticleFlipbookLayout.Grid4x4;
        Slash.FlipbookMode = Enum.ParticleFlipbookMode.OneShot;
        Slash.Lifetime = NumberRange.new(0.8, 1.5);
        Slash.LightEmission = 1;
        Slash.Orientation = Enum.ParticleOrientation.VelocityPerpendicular;
        Slash.Rate = 0;
        Slash.RotSpeed = NumberRange.new(-360, 360);
        Slash.Rotation = NumberRange.new(-180, 180);
        Slash.Size = ScaleSequence(NumberSequence.new({
            NumberSequenceKeypoint.new(0, 1.6918035745620728),
            NumberSequenceKeypoint.new(0.45546218752861023, 2.3400001525878906),
            NumberSequenceKeypoint.new(0.7042016983032227, 1.350000023841858),
            NumberSequenceKeypoint.new(1, 1.2600001096725464),
        }));
        Slash.Speed = NumberRange.new(2.880000114440918, 4.320000171661377);
        Slash.SpreadAngle = Vector2.new(6, 6);
        Slash.Texture = "rbxassetid://17853203150";
        Slash.TimeScale = 0.7;
        Slash.Transparency = FadeSequence(0, 0.7);

        local Sparkles = Instance.new("ParticleEmitter", Attachment);
        Sparkles.Name = "Sparkles";
        Sparkles.Acceleration = Vector3.new(0, 18, 0);
        Sparkles.Brightness = 5;
        Sparkles.Color = ColorSequence.new(Color);
        Sparkles.Drag = 6;
        Sparkles.EmissionDirection = Enum.NormalId.Back;
        Sparkles.FlipbookFramerate = NumberRange.new(0, 0);
        Sparkles.FlipbookMode = Enum.ParticleFlipbookMode.Random;
        Sparkles.Lifetime = NumberRange.new(0.2, 0.5);
        Sparkles.LightEmission = 1;
        Sparkles.Rate = 0;
        Sparkles.RotSpeed = NumberRange.new(-100, 100);
        Sparkles.Rotation = NumberRange.new(0, 360);
        Sparkles.ShapeInOut = Enum.ParticleEmitterShapeInOut.Inward;
        Sparkles.ShapeStyle = Enum.ParticleEmitterShapeStyle.Surface;
        Sparkles.Size = ScaleSequence(NumberSequence.new({
            NumberSequenceKeypoint.new(0, 0),
            NumberSequenceKeypoint.new(0.48067227005958557, 0.5114758014678955),
            NumberSequenceKeypoint.new(1, 0),
        }));
        Sparkles.Speed = NumberRange.new(10.8, 18);
        Sparkles.SpreadAngle = Vector2.new(360, 360);
        Sparkles.Texture = "rbxassetid://10598374841";
        Sparkles.TimeScale = 0.8;
        Sparkles.ZOffset = -1;
        Sparkles.Transparency = FadeSequence(0, 0.7);

        Shards:Emit(12);
        Slash:Emit(3);
        Sparkles:Emit(20);

        task.delay(EffectLifetime, function()
            Model:Destroy();
        end)
    end;

    if Style == "Dots" then
        Emitter = Instance.new("ParticleEmitter");
        Emitter.Parent = OriginPart;
        Emitter.Texture = "rbxassetid://124005197513236";
        Emitter.Lifetime = NumberRange.new(0.875, 2.125);
        Emitter.Brightness = 20;
        Emitter.ZOffset = 0.8;
        Emitter.Rate = 18;
        Emitter.Rotation = NumberRange.new(-360, 360);
        Emitter.RotSpeed = NumberRange.new(-80, 80);
        Emitter.SpreadAngle = Vector2.new(-90, 90);
        Emitter.Speed = NumberRange.new(7.2, 16);

        Emitter.EmissionDirection = Enum.NormalId.Top;
        Emitter.Shape = Enum.ParticleEmitterShape.Box;
        Emitter.ShapeInOut = Enum.ParticleEmitterShapeInOut.Outward;
        Emitter.ShapeStyle = Enum.ParticleEmitterShapeStyle.Volume;

        Emitter.Drag = 4.4;
        Emitter.LockedToPart = false;
        Emitter.Color = ColorSequence.new(Color);

        Emitter.Acceleration = Vector3.new(0, 0, 0);
        Emitter.Size = NumberSequence.new(EffectScale);

        Emitter.Transparency = FadeSequence(0, 0.7);
        Emitter:Emit(1);
        task.delay(EffectLifetime, function()
            OriginPart:Destroy();
            Emitter:Destroy();
        end)
    end;

    if Style == "Catalyst" then
        Emitter = Instance.new("ParticleEmitter");
        Emitter.Parent = OriginPart;
        Emitter.Texture = "rbxassetid://12602224662";
        Emitter.Lifetime = NumberRange.new(1, 1);
        Emitter.Rate = 3;
        Emitter.Rotation = NumberRange.new(-1000, 1000);
        Emitter.RotSpeed = NumberRange.new(-10, 10);
        Emitter.SpreadAngle = Vector2.new(-1000, 1000);
        Emitter.Speed = NumberRange.new(0, 0);

        Emitter.EmissionDirection = Enum.NormalId.Top;
        Emitter.Shape = Enum.ParticleEmitterShape.Box;
        Emitter.ShapeInOut = Enum.ParticleEmitterShapeInOut.Outward;
        Emitter.ShapeStyle = Enum.ParticleEmitterShapeStyle.Volume;

        Emitter.FlipbookLayout = Enum.ParticleFlipbookLayout.Grid8x8;
        Emitter.FlipbookBlendFrames = true;
        Emitter.FlipbookMode = Enum.ParticleFlipbookMode.OneShot;
        Emitter.Drag = 1;
        Emitter.LockedToPart = false;
        Emitter.Color = ColorSequence.new(Color);

        Emitter.Acceleration = Vector3.new(0, 0, 0);
        Emitter.Size = NumberSequence.new(EffectScale);

        Emitter.Transparency = FadeSequence(0, 0.7);
        Emitter:Emit(1);
        task.delay(EffectLifetime, function()
            OriginPart:Destroy();
            Emitter:Destroy();
        end)
    end;

    if Style == "Mist" then
        Emitter = Instance.new("ParticleEmitter");
        Emitter.Parent = OriginPart;
        Emitter.Texture = "rbxassetid://12830011666";
        Emitter.Lifetime = NumberRange.new(0.5, 0.5);
        Emitter.RotSpeed = NumberRange.new(10, 100);
        Emitter.Speed = NumberRange.new(0, 0);
        Emitter.Brightness = 20;
        Emitter.SpreadAngle = Vector2.new(-180, 180);
        Emitter.Size = ScaleSequence(NumberSequence.new({
            NumberSequenceKeypoint.new(0, 0.18),
            NumberSequenceKeypoint.new(0.192, 0.0625),
            NumberSequenceKeypoint.new(0.408, 2.75),
            NumberSequenceKeypoint.new(1, 6),
        }));
        Emitter.Color = ColorSequence.new(Color);
        Emitter.LightEmission = 540;
        Emitter.VelocitySpread = 0;
        Emitter.Enabled = true;
        Emitter.EmissionDirection = Enum.NormalId.Top;
        Emitter.FlipbookLayout = Enum.ParticleFlipbookLayout.Grid1x1;
        Emitter.FlipbookMode = Enum.ParticleFlipbookMode.OneShot;
        Emitter.Shape = Enum.ParticleEmitterShape.Box;
        Emitter.ShapeInOut = Enum.ParticleEmitterShapeInOut.Outward;
        Emitter.ShapeStyle = Enum.ParticleEmitterShapeStyle.Volume;
        Emitter.ZOffset = 2.5;
        Emitter.Rate = 0.5;

        Emitter.Transparency = FadeSequence(0, 0.7);
        Emitter:Emit(1);
        task.delay(EffectLifetime, function()
            OriginPart:Destroy();
            Emitter:Destroy();
        end)
    end;

    if Style == "Chiral" then
        Emitter = Instance.new("ParticleEmitter");
        Emitter.Parent = OriginPart;
        Emitter.Texture = "rbxassetid://15011464541";
        Emitter.Lifetime = NumberRange.new(3, 3);
        Emitter.Rate = 3;
        Emitter.Rotation = NumberRange.new(-1000, 1000);
        Emitter.RotSpeed = NumberRange.new(-10, 10);
        Emitter.SpreadAngle = Vector2.new(-1000, 1000);
        Emitter.Speed = NumberRange.new(0, 0);

        Emitter.EmissionDirection = Enum.NormalId.Top;
        Emitter.Shape = Enum.ParticleEmitterShape.Box;
        Emitter.ShapeInOut = Enum.ParticleEmitterShapeInOut.Outward;
        Emitter.ShapeStyle = Enum.ParticleEmitterShapeStyle.Volume;

        Emitter.FlipbookLayout = Enum.ParticleFlipbookLayout.Grid8x8;
        Emitter.FlipbookBlendFrames = true;
        Emitter.FlipbookMode = Enum.ParticleFlipbookMode.OneShot;
        Emitter.Drag = 1;
        Emitter.LockedToPart = false;
        Emitter.Color = ColorSequence.new(Color);

        Emitter.Acceleration = Vector3.new(0, 0, 0);
        Emitter.Size = NumberSequence.new(EffectScale);

        Emitter.Transparency = FadeSequence(0, 0.7);
        Emitter:Emit(1);
        task.delay(EffectLifetime, function()
            OriginPart:Destroy();
            Emitter:Destroy();
        end)
    end;
end;

Libraries.Visuals = Visuals;
return Visuals
