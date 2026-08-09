--[[
    1/21/2026
    Visuals.lua
    Purpose:
        Visual features to be used across all Niggahack games
    Author: @.yxyv
    Dependencies:
        Animations
        Directory
]]

local Visuals = {
    Instances = {},
    ScreenGui = nil,
    Debug = false,
    EffectHolder = game:GetObjects("rbxassetid://17192721766")[1],
};

Visuals.__index = Visuals;

local Animations = _G.Animations;
local Directory = _G.Directory;
local Utility = _G.Utility;

local Workspace = cloneref(game:GetService("Workspace"));
local RunService = cloneref(game:GetService("RunService"));

local Camera = Workspace.CurrentCamera;

if not isfile(Directory.Images .. "/GlowCircle.png") then
    writefile(Directory.Images .. "/GlowCircle.png", game:HttpGet('https://pasted-detected.online/glowCircle.png'))
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

    if Style == "Line" then
        local MainLine = Drawing.new("Line")
        local OutlineLine = Drawing.new("Line")
        local StartTime = tick()
        local Destroyed = false
        local RenderConnection
        local From = Camera:WorldToViewportPoint(Origin)
        local To = Camera:WorldToViewportPoint(Destination)
        local SpawnVisible = (From.Z > 0) or (To.Z > 0)
        local From2D = Vector2.new(From.X, From.Y)
        local To2D = Vector2.new(To.X, To.Y)

        MainLine.Visible = true
        MainLine.ZIndex = 3
        MainLine.Thickness = 1
        MainLine.Color = Color
        MainLine.Transparency = 1 - (Transparency or 0)

        OutlineLine.Visible = true
        OutlineLine.ZIndex = 2
        OutlineLine.Thickness = 2
        OutlineLine.Color = Color3.new(0, 0, 0)
        OutlineLine.Transparency = MainLine.Transparency

        RenderConnection = RunService.RenderStepped:Connect(function()
            if Destroyed then
                return
            end

            local Now = tick()
            local Elapsed = Now - StartTime
            local FadeAlpha = 1

            if Elapsed >= Lifetime then
                FadeAlpha = math.clamp(1 - ((Elapsed - Lifetime) / FadeDuration), 0, 1)
            end

            if FadeAlpha <= 0 then
                Destroyed = true
                if RenderConnection then
                    RenderConnection:Disconnect()
                    RenderConnection = nil
                end
                MainLine:Remove()
                OutlineLine:Remove()
                return
            end

            local Alpha = (1 - (Transparency or 0)) * FadeAlpha

            MainLine.Visible = SpawnVisible
            OutlineLine.Visible = SpawnVisible
            if not SpawnVisible then
                return
            end

            MainLine.From = From2D
            MainLine.To = To2D
            MainLine.Transparency = Alpha

            OutlineLine.From = MainLine.From
            OutlineLine.To = MainLine.To
            OutlineLine.Transparency = Alpha
        end)

        return {
            Beam = nil,
            Model = nil,
            Line = MainLine,
            Outline = OutlineLine,
        }
    end

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
        ColorSequenceKeypoint.new(0, Color),
        ColorSequenceKeypoint.new(1, Color2),
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
    if Style == "Flat" or Style == "Textured" then
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

        if TextureVariant == "Dark" then
            Beam.Brightness = 1
            Beam.LightEmission = 0.25
            Beam.LightInfluence = 1
            Beam.Texture = "rbxassetid://12781848822"
            Beam.TextureLength = 20
            Beam.TextureMode = Enum.TextureMode.Static
            Beam.Width0 = 0.5
            Beam.Width1 = 0.5

            local Beam2 = Beam:Clone()
            Beam2.Name = "DarkBeam2"
            Beam2.Attachment0 = OriginAttachment
            Beam2.Attachment1 = DestinationAttachment
            Beam2.Parent = Model
            table.insert(ExtraBeams, Beam2)

            local Beam3 = Beam:Clone()
            Beam3.Name = "DarkBeam3"
            Beam3.Attachment0 = OriginAttachment
            Beam3.Attachment1 = DestinationAttachment
            Beam3.Parent = Model
            table.insert(ExtraBeams, Beam3)
        else
            Beam.Brightness = 5
            Beam.LightEmission = 1
            Beam.LightInfluence = 0
            Beam.Texture = "rbxassetid://12781800668"
            Beam.TextureLength = 4
            Beam.TextureMode = Enum.TextureMode.Wrap
            Beam.TextureSpeed = 10
            Beam.Width0 = 0.5
            Beam.Width1 = 0.5
        end
    end;

    if Style == "Classic" then
        Beam = Utility:Instance("Beam", {
            Brightness = 5,
            Color = BeamColor,
            LightEmission = 1,
            LightInfluence = 0,
            Texture = "http://www.roblox.com/asset/?id=446111271",
            TextureLength = 12,
            TextureMode = "Static",
            Width0 = 0.5,
            Width1 = 0.5,
            Attachment0 = OriginAttachment,
            Attachment1 = DestinationAttachment,
            FaceCamera = true,
            TextureSpeed = TextureSpeed,
            ZOffset = -1,
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

    if Style == "Laser" then
        Beam = Utility:Instance("Beam", {
            Brightness = 5,
            Color = BeamColor,
            LightEmission = 1,
            LightInfluence = 0,
            Texture = "rbxassetid://18654087326",
            TextureLength = 1,
            TextureMode = "Static",
            Width0 = 0.2,
            Width1 = 0.2,
            Attachment0 = OriginAttachment,
            FaceCamera = true,
            Attachment1 = DestinationAttachment,
            TextureSpeed = TextureSpeed,
            Transparency = BeamTransparency,
        });
    end;

    if Style == "Energy" then
        Beam = Utility:Instance("Beam", {
            Brightness = 5,
            Color = BeamColor,
            LightEmission = 1,
            LightInfluence = 0,
            Texture = "rbxassetid://13832105797",
            TextureLength = 1,
            TextureMode = "Static",
            Width0 = 0.25,
            Width1 = 0.25,
            Attachment0 = OriginAttachment,
            Attachment1 = DestinationAttachment,
            FaceCamera = true,
            TextureSpeed = TextureSpeed,
            Transparency = BeamTransparency,
        });
    end;

    if Style == "Strand" then
        Beam = Utility:Instance("Beam", {
            Brightness = 5,
            Color = BeamColor,
            LightEmission = 1,
            LightInfluence = 0,
            Texture = "rbxassetid://119094363918228",
            TextureLength = 5,
            TextureMode = "Static",
            Width0 = 0.2,
            Width1 = 0.2,
            Attachment0 = OriginAttachment,
            Attachment1 = DestinationAttachment,
            FaceCamera = true,
            TextureSpeed = TextureSpeed,
            Transparency = BeamTransparency,
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
            Animations:Tween(DestinationPart, TweenInfo.new(TravelTime, Enum.EasingStyle.Linear), {
                Position = Destination,
                CFrame = CFrame.new(Destination),
            })
        end
    end

    Animations:Tween(Beam, TweenInfo.new(5, Enum.EasingStyle.Exponential, Enum.EasingDirection.Out, 0, false, 0), {
        TextureSpeed = math.max(0.5, TextureSpeed * 0.2)
    });

    if Style == "Flat" or Style == "Textured" then
        if TextureVariant == "Light" then
            local SpeedTween = Animations:Tween(Beam,
                TweenInfo.new(0.6, Enum.EasingStyle.Quad, Enum.EasingDirection.InOut, 2, true), {
                    TextureSpeed = 2
                })
            if SpeedTween then
                SpeedTween:Play()
            end
        else
            for _, ExtraBeam in next, ExtraBeams do
                Animations:Tween(ExtraBeam,
                    TweenInfo.new(5, Enum.EasingStyle.Exponential, Enum.EasingDirection.Out, 0, false, 0), {
                        TextureSpeed = math.max(0.5, TextureSpeed * 0.2)
                    })
            end
        end
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
            Animations:Tween(ExtraBeam, TweenInfo.new(0.5, Enum.EasingStyle.Quint), {
                Width0 = 0,
                Width1 = 0,
                TextureSpeed = 1,
                Brightness = 0
            })
        end

        if FadeTween then
            FadeTween.Completed:Wait();
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

        RainbowConnection = RunService.RenderStepped:Connect(function()
            if not Beam or not Beam.Parent then return end

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
    FOVCircle.Saturation = 0.45;

    FOVCircle.Holder = Utility:Instance("Frame", {
        BackgroundTransparency = 1,
        Parent = self.ScreenGui,
        Size = UDim2.new(0, 460, 0, 460),
        Position = UDim2.new(0.5, 0, 0.5, 0),
        AnchorPoint = Vector2.new(0.5, 0.5),
        Visible = true,
    });

    --// Circles
    FOVCircle.Outline = Utility:Instance("Frame", {
        AnchorPoint = Vector2.new(0.5, 0.5),
        BackgroundTransparency = 1,
        Position = UDim2.new(0.5, 0, 0.5, 0),
        Size = UDim2.new(1, 0, 1, 0),
        ZIndex = 1,
        Parent = FOVCircle.Holder,
        Visible = true,
    });

    FOVCircle.Inline = Utility:Instance("Frame", {
        BackgroundTransparency = 1,
        ZIndex = 2,
        Size = UDim2.new(1, 2, 1, 2),
        Position = UDim2.new(0, -1, 0, -1),
        Parent = FOVCircle.Outline,
        Visible = true,
    })

    FOVCircle.Glow = Utility:Instance("ImageLabel", {
        AnchorPoint = Vector2.new(0.5, 0.5),
        BackgroundTransparency = 1,
        Position = UDim2.new(0.5, 0, 0.5, 0),
        Size = UDim2.new(1.13, 0, 1.13, 0),
        Image = getcustomasset(Directory.Images .. "/GlowCircle.png"),
        Parent = FOVCircle.Outline,
        ZIndex = 0,
        Visible = true,
    });

    --// Strokes
    FOVCircle.OutlineStroke = Utility:Instance("UIStroke", {
        Parent = FOVCircle.Outline,
        Thickness = 4, --// or 3, 1
        Color = Color3.fromRGB(0, 0, 0),
        Enabled = false
    });

    FOVCircle.InlineStroke = Utility:Instance("UIStroke", {
        Parent = FOVCircle.Inline,
        Thickness = 2, --// or 3, 1
        Color = Color3.fromRGB(255, 255, 255)
    });

    --// Gradients

    FOVCircle.InlineGradient = Utility:Instance("UIGradient", {
        Parent = FOVCircle.InlineStroke
    });

    FOVCircle.GlowGradient = Utility:Instance("UIGradient", {
        Parent = FOVCircle.Glow,
        Transparency = NumberSequence.new {
            NumberSequenceKeypoint.new(0, 0.8),
            NumberSequenceKeypoint.new(1, 0.8),
        }
    });

    --// Corners
    Utility:Instance("UICorner", {
        Parent = FOVCircle.Outline,
        CornerRadius = UDim.new(1, 0)
    });

    Utility:Instance("UICorner", {
        Parent = FOVCircle.Inline,
        CornerRadius = UDim.new(1, 0)
    });

    --// Functions
    function FOVCircle:SetPosition(Position)
        self.Holder.Position = Position
    end;

    function FOVCircle:SetRadius(Radius)
        self.Holder.Size = UDim2.new(0, Radius, 0, Radius)
        local GlowOffset = Radius * 0.13
        self.Glow.Size = UDim2.new(0, Radius + GlowOffset, 0, Radius + GlowOffset)
    end

    function FOVCircle:SetColor(Color1, Color2)
        --// colors will be done in pairs because of the rainbow and stuffsss yeah idk we'll see
        local Sequence = ColorSequence.new({
            ColorSequenceKeypoint.new(0, Color1),
            ColorSequenceKeypoint.new(1, Color2),
        });

        self.InlineGradient.Color = Sequence;
        self.GlowGradient.Color = Sequence;
    end;

    function FOVCircle:SetSpin(State)
        if self.Connection then
            self.Connection:Disconnect();
            self.Connection = nil;
        end;

        if not State then
            self.InlineGradient.Rotation = 0;
            self.GlowGradient.Rotation = 0;
            return
        end;
        local RotationOffset = 0

        self.Connection = RunService.RenderStepped:Connect(function(DeltaTime)
            RotationOffset = (RotationOffset + 1.2 * DeltaTime * 60) % 360;
            self.InlineGradient.Rotation = RotationOffset;
            self.GlowGradient.Rotation = RotationOffset;
        end);
    end;

    function FOVCircle:SetRainbow(State)
        if self.RainbowConnection then
            self.RainbowConnection:Disconnect();
            self.RainbowConnection = nil;
        end;

        if not State then
            return
        end;

        self.RainbowConnection = RunService.RenderStepped:Connect(function()
            local Time = tick() * 0.25 * 1.2;
            local Span = 0.33;
            local Sequence = {};

            for Index = 0, 1, 0.1 do
                local Hue = (Time + Index * Span) % 1;

                local Saturation = self.Saturation;
                local Value = 1;

                Sequence[#Sequence + 1] = ColorSequenceKeypoint.new(Index, Color3.fromHSV(Hue, Saturation, Value));
            end;

            local ColorSeq = ColorSequence.new(Sequence);
            self.InlineGradient.Color = ColorSeq;
            self.GlowGradient.Color = ColorSeq;
        end);
    end;

    function FOVCircle:SetVisible(State)
        self.Holder.Visible = State;
    end;

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

function Visuals:CreateHitEffect(Parent, Style, Color, Origin, Lifetime, Scale)
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

        Emitter:Emit(1);
        Emitter.Transparency = NumberSequence.new({
            NumberSequenceKeypoint.new(0, 0),
            NumberSequenceKeypoint.new(1, 0.7),
        });
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

        Emitter:Emit(1);
        Emitter.Transparency = NumberSequence.new({
            NumberSequenceKeypoint.new(0, 0),
            NumberSequenceKeypoint.new(1, 0.7),
        });
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

        Emitter:Emit(1);
        Emitter.Transparency = NumberSequence.new({
            NumberSequenceKeypoint.new(0, 0),
            NumberSequenceKeypoint.new(1, 0.7),
        });
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

        Emitter:Emit(1);
        Emitter.Transparency = NumberSequence.new({
            NumberSequenceKeypoint.new(0, 0),
            NumberSequenceKeypoint.new(1, 0.7),
        });
        task.delay(EffectLifetime, function()
            OriginPart:Destroy();
            Emitter:Destroy();
        end)
    end;
end;

_G.Visuals = Visuals;
return Visuals;
