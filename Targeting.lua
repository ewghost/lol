--[[
    1/21/2026
    Targeting.luau
    Purpose:
        Targeting features to be used across all NiggaHack games
    Author: @.yxyv
    Dependencies:
        Entities.lua
]]

local Entities = _G.Entities;
local Targeting = {};

local Workspace = cloneref(game.GetService(game, "Workspace"));
local Players = cloneref(game.GetService(game, "Players"));
local Mouse = Players.LocalPlayer:GetMouse();

local Camera = Workspace.CurrentCamera;
local Vector2New = Vector2.new;
local Huge = math.huge;
local Clock = os.clock;
local LocalPlayer = Players.LocalPlayer;
local DeadState = Enum.HumanoidStateType.Dead;
local IgnoreCacheTTL = 0.25;
local ResolveCacheTTL = 0.1;
local AliveCacheTTL = 0.05;
local QueryCacheTTL = 0.05;
local QueryMouseThreshold = 6;
local QueryOriginThreshold = 1.5;

Targeting.MouseOffset = Vector2.new();
Targeting.Camera = Camera;
Targeting.__index = Targeting;
Targeting.Debug = false;
Targeting.EnforceTeams = false;
Targeting.EnforceHealth = false;
Targeting.ClientTeam = "";
Targeting.MinHealth = 0;
Targeting.QueryCache = {
    LastAt = 0,
    LastOrigin = nil,
    LastMouse = nil,
    LastUseCenter = nil,
    LastMaxDistance = nil,
    LastRadius = nil,
    LastCheckClosest = nil,
    LastResult = nil,
};
Targeting.Fallen = {
    ManipulatedPositon = nil,
    ScannedPosition = nil,
    ScanPos = nil,
    ManipPos = nil,
    Targets = {},
};

function Targeting:GetResolvedCharacter(Entity)
    if not Entity then
        return nil
    end;

    local Now = Clock();
    local CachedAt = Entity._nhResolvedCharacterAt;
    local Character = Entity.Character;
    if Character and CachedAt and (Now - CachedAt) <= ResolveCacheTTL then
        return Character
    end;

    if Entity.GetCharacter then
        local Success, Result = pcall(Entity.GetCharacter, Entity);
        if Success and Result then
            Character = Result;
            Entity.Character = Result;
        end;
    end;

    Entity._nhResolvedCharacterAt = Now;

    return Character;
end;

function Targeting:GetResolvedParts(Entity)
    if not Entity then
        return nil, nil
    end;

    local Now = Clock();
    local Character = self:GetResolvedCharacter(Entity);
    if not Character then
        return nil, nil
    end;

    local Parts = Entity.BodyParts;
    local Head = Parts and Parts.Head;

    if Head and Head.Parent == Character then
        local CachedAt = Entity._nhResolvedPartsAt;
        if CachedAt and (Now - CachedAt) <= ResolveCacheTTL then
            return Parts, Character
        end;
    end;

    if not (Head and Head.Parent == Character) and Entity.RefreshParts then
        local Success, Result = pcall(Entity.RefreshParts, Entity, Character);
        if Success and type(Result) == "table" then
            Parts = Result;
        else
            Parts = Entity.BodyParts;
        end;
        Head = Parts and Parts.Head;
    end;

    if not (Head and Head.Parent == Character) then
        return nil, Character
    end;

    Entity._nhResolvedPartsAt = Now;
    return Parts, Character;
end;

function Targeting:TeamCheck(EntityTeam, ClientTeam)
    if EntityTeam == ClientTeam then
        return true
    end;

    return false
end;

function Targeting:ShouldIgnoreEntity(Entity, Pointer)
    if not Entity then
        return true
    end;

    local Now = Clock();
    local CachedAt = Entity._nhIgnoreAt;
    if CachedAt and (Now - CachedAt) <= IgnoreCacheTTL then
        return Entity._nhIgnoreValue == true
    end;

    local Playerlist = _G.Modules and _G.Modules.Playerlist
    local EntityPointer = Entity.Pointer or Pointer
    if typeof(EntityPointer) == "Instance" and EntityPointer:IsA("Player") and Playerlist and Playerlist.Players then
        local Entry = Playerlist.Players[EntityPointer.Name]
        if type(Entry) == "table" and Entry.Status == "Friendly" then
            Entity._nhIgnoreAt = Now;
            Entity._nhIgnoreValue = true;
            return true
        end
    end

    if Entity.IsPreview then
        Entity._nhIgnoreAt = Now;
        Entity._nhIgnoreValue = true;
        return true
    end;

    if Pointer == LocalPlayer or Entity.Pointer == LocalPlayer then
        Entity._nhIgnoreAt = Now;
        Entity._nhIgnoreValue = true;
        return true
    end;

    local Character = Entity.Character;
    if Character and LocalPlayer.Character and Character == LocalPlayer.Character then
        Entity._nhIgnoreAt = Now;
        Entity._nhIgnoreValue = true;
        return true
    end;

    if Entity.CharacterOwner and Entity.CharacterOwner == LocalPlayer then
        Entity._nhIgnoreAt = Now;
        Entity._nhIgnoreValue = true;
        return true
    end;

    if typeof(Character) == "Instance" then
        if Character:GetAttribute("PDIgnorePreview") == true or Character:GetAttribute("PDIgnoreChams") == true then
            Entity._nhIgnoreAt = Now;
            Entity._nhIgnoreValue = true;
            return true
        end

        if Character:FindFirstAncestorOfClass("ViewportFrame") then
            Entity._nhIgnoreAt = Now;
            Entity._nhIgnoreValue = true;
            return true
        end
    end

    if typeof(EntityPointer) == "Instance" then
        if EntityPointer:GetAttribute("PDIgnorePreview") == true or EntityPointer:GetAttribute("PDIgnoreChams") == true then
            Entity._nhIgnoreAt = Now;
            Entity._nhIgnoreValue = true;
            return true
        end

        if EntityPointer:FindFirstAncestorOfClass("ViewportFrame") then
            Entity._nhIgnoreAt = Now;
            Entity._nhIgnoreValue = true;
            return true
        end
    end

    Entity._nhIgnoreAt = Now;
    Entity._nhIgnoreValue = false;
    return false
end;

function Targeting:AliveCheck(Entity, Min)
    local Now = Clock();
    local MinHealth = Min or 0;
    local CachedAt = Entity and Entity._nhAliveAt;
    if Entity and CachedAt and (Now - CachedAt) <= AliveCacheTTL and Entity._nhAliveMin == MinHealth then
        return Entity._nhAliveValue == true
    end;

    local Parts, Character = self:GetResolvedParts(Entity);
    local Head = Parts and Parts.Head;
    if not (Head and Character and Head.Parent == Character) then
        if Entity then
            Entity._nhAliveAt = Now;
            Entity._nhAliveMin = MinHealth;
            Entity._nhAliveValue = false;
        end;
        return false
    end;

    local Humanoid = Entity.Humanoid;
    if not (Humanoid and Humanoid.Parent == Character) then
        Humanoid = Character:FindFirstChildOfClass("Humanoid");
        Entity.Humanoid = Humanoid;
    end;
    local CurrentHealth, MaxHealth;
    if Entity and Entity.GetHealth then
        CurrentHealth, MaxHealth = Entity:GetHealth(Humanoid)
    elseif Humanoid then
        CurrentHealth, MaxHealth = Humanoid.Health, Humanoid.MaxHealth
    end;

    if CurrentHealth ~= nil then
        if CurrentHealth <= 0 then
            Entity._nhAliveAt = Now;
            Entity._nhAliveMin = MinHealth;
            Entity._nhAliveValue = false;
            return false
        end;
        if MinHealth > 0 and CurrentHealth < MinHealth then
            Entity._nhAliveAt = Now;
            Entity._nhAliveMin = MinHealth;
            Entity._nhAliveValue = false;
            return false
        end;
        if MaxHealth ~= nil and MaxHealth <= 0 then
            Entity._nhAliveAt = Now;
            Entity._nhAliveMin = MinHealth;
            Entity._nhAliveValue = false;
            return false
        end;
        -- GetHealth confirmed alive — no Humanoid required
        Entity._nhAliveAt = Now;
        Entity._nhAliveMin = MinHealth;
        Entity._nhAliveValue = true;
        return true
    end;

    if Humanoid then
        if Humanoid.Health <= 0 then
            Entity._nhAliveAt = Now;
            Entity._nhAliveMin = MinHealth;
            Entity._nhAliveValue = false;
            return false
        end;
        if Humanoid:GetState() == DeadState then
            Entity._nhAliveAt = Now;
            Entity._nhAliveMin = MinHealth;
            Entity._nhAliveValue = false;
            return false
        end;
        Entity._nhAliveAt = Now;
        Entity._nhAliveMin = MinHealth;
        Entity._nhAliveValue = true;
        return true
    end;

    Entity._nhAliveAt = Now;
    Entity._nhAliveMin = MinHealth;
    Entity._nhAliveValue = false;
    return false
end;

function Targeting:GetClosestEntity(Origin: Vector3, MaxDistance: number, Radius: number, CheckClosest: boolean, UseCenter: boolean)
    local Now = Clock();
    local Target = nil;
    local ClosestPart = nil;
    local ScreenPoint;
    local WorldPosition;
    local TargetData;
    local Distance = Huge;
    local CameraRef = self.Camera;
    local AimPosition = UseCenter
        and Vector2New(CameraRef.ViewportSize.X * 0.5, CameraRef.ViewportSize.Y * 0.5)
        or (Vector2New(Mouse.X, Mouse.Y) + self.MouseOffset);
    local MaxDistanceSquared = MaxDistance * MaxDistance;
    local RadiusSquared = Radius * Radius;
    local QueryCache = self.QueryCache;
    local LastResult = QueryCache.LastResult;
    local LastOrigin = QueryCache.LastOrigin;
    local LastMouse = QueryCache.LastMouse;

    if LastResult
        and (Now - (QueryCache.LastAt or 0)) <= QueryCacheTTL
        and QueryCache.LastUseCenter == UseCenter
        and QueryCache.LastMaxDistance == MaxDistance
        and QueryCache.LastRadius == Radius
        and QueryCache.LastCheckClosest == CheckClosest
        and LastOrigin
        and (Origin - LastOrigin).Magnitude <= QueryOriginThreshold
        and (
            UseCenter
            or (
                LastMouse
                and (AimPosition - LastMouse).Magnitude <= QueryMouseThreshold
            )
        )
    then
        local CachedPart = LastResult.ClosestPart;
        local CachedEntity = LastResult.TargetData;
        if CachedEntity and CachedPart and CachedPart.Parent then
            return LastResult
        end;
    end;

    for Pointer, Entity in Entities.Main.Cache do
        if self:ShouldIgnoreEntity(Entity, Pointer) then
            continue
        end;

        local Parts = nil;
        if Targeting.EnforceHealth then
            if not self:AliveCheck(Entity, self.MinHealth) then
                continue
            end;
            Parts = Entity.BodyParts;
        else
            Parts = select(1, self:GetResolvedParts(Entity));
            if not Parts then
                continue
            end;
        end;

        if Targeting.EnforceTeams and self:TeamCheck(Entity, self.ClientTeam) then
            continue
        end;

        if Parts and Parts.Head and Parts.Head:IsA("BasePart") then
            local HeadPosition = Parts.Head.Position;
            local DeltaX = HeadPosition.X - Origin.X;
            local DeltaY = HeadPosition.Y - Origin.Y;
            local DeltaZ = HeadPosition.Z - Origin.Z;
            local MagnitudeSquared = (DeltaX * DeltaX) + (DeltaY * DeltaY) + (DeltaZ * DeltaZ);

            if MagnitudeSquared > MaxDistanceSquared then
                continue;
            end;

            local ScreenPosition, IsOnScreen = CameraRef:WorldToViewportPoint(HeadPosition);
            if not IsOnScreen then
                continue;
            end;

            local ScreenDeltaX = ScreenPosition.X - AimPosition.X;
            local ScreenDeltaY = ScreenPosition.Y - AimPosition.Y;
            local MouseDistance = (ScreenDeltaX * ScreenDeltaX) + (ScreenDeltaY * ScreenDeltaY);

            if MouseDistance < Distance and MouseDistance < RadiusSquared then
                Distance = MouseDistance;
                Target = Pointer;
                TargetData = Entity;
                ScreenPoint = ScreenPosition;
                WorldPosition = HeadPosition;
                ClosestPart = Parts.Head;

                local PartDistance = Huge

                if CheckClosest then
                    local CachedClosestPart = Entity._nhClosestPart;
                    local CachedClosestScreen = Entity._nhClosestScreen;
                    local CachedClosestAt = Entity._nhClosestAt;
                    local CachedClosestMouse = Entity._nhClosestMouse;
                    if CachedClosestPart
                        and CachedClosestScreen
                        and CachedClosestPart.Parent == Parts.Head.Parent
                        and CachedClosestAt
                        and (Now - CachedClosestAt) <= QueryCacheTTL
                        and CachedClosestMouse
                        and (AimPosition - CachedClosestMouse).Magnitude <= QueryMouseThreshold
                    then
                        ClosestPart = CachedClosestPart;
                        WorldPosition = CachedClosestPart.Position;
                        ScreenPoint = CachedClosestScreen;
                    else
                        for _, Part in Parts do
                            if not Part:IsA("BasePart") then continue end;
                            local ScreenPosition2, IsOnScreen2 = CameraRef:WorldToViewportPoint(Part.Position);

                            if not IsOnScreen2 then continue end;

                            local ScreenDeltaX2 = ScreenPosition2.X - AimPosition.X;
                            local ScreenDeltaY2 = ScreenPosition2.Y - AimPosition.Y;
                            local MouseDistance2 = (ScreenDeltaX2 * ScreenDeltaX2) + (ScreenDeltaY2 * ScreenDeltaY2);

                            if MouseDistance2 < PartDistance then
                                PartDistance = MouseDistance2;
                                ClosestPart = Part;
                                WorldPosition = ClosestPart.Position;
                                ScreenPoint = ScreenPosition2;
                            end;
                        end;
                        Entity._nhClosestPart = ClosestPart;
                        Entity._nhClosestScreen = ScreenPoint;
                        Entity._nhClosestAt = Now;
                        Entity._nhClosestMouse = AimPosition;
                    end;
                end;
            end;
        end;
    end;

    local Result = {
        Target = Target,
        ClosestPart = ClosestPart,
        ScreenPoint = ScreenPoint,
        TargetData = TargetData,
        WorldPosition = WorldPosition,
    };
    QueryCache.LastAt = Now;
    QueryCache.LastOrigin = Origin;
    QueryCache.LastMouse = AimPosition;
    QueryCache.LastUseCenter = UseCenter;
    QueryCache.LastMaxDistance = MaxDistance;
    QueryCache.LastRadius = Radius;
    QueryCache.LastCheckClosest = CheckClosest;
    QueryCache.LastResult = Result;

    return Result;
end;

function Targeting:GetClosestEntityToMouse(Origin: Vector3, MaxDistance: number, Radius: number, CheckClosest: boolean)
    return self:GetClosestEntity(Origin, MaxDistance, Radius, CheckClosest, false);
end;

function Targeting:GetClosestEntityToCenter(Origin: Vector3, MaxDistance: number, Radius: number, CheckClosest: boolean)
    return self:GetClosestEntity(Origin, MaxDistance, Radius, CheckClosest, true);
end;

if Targeting.Debug then
    local UserInputService = cloneref(game.GetService(game, "UserInputService"));

    UserInputService.InputBegan:Connect(function(Input)
        if Input.KeyCode == Enum.KeyCode.E then
            local MouseData = Targeting:GetClosestEntityToMouse(
                Camera.CFrame.p,
                2000,
                1000,
                true
            );

            local CenterData = Targeting:GetClosestEntityToCenter(
                Camera.CFrame.p,
                2000,
                1000,
                true
            );

            if MouseData and MouseData.TargetData then
                print("Got Mouse Closest Target!")
                print("Pointer:", MouseData.Target);
                print("TargetData:", MouseData.TargetData);
                print("Name:", MouseData.TargetData.Name);
                print("Closest part:", MouseData.ClosestPart)
                print("World position:", MouseData.WorldPosition);
                print("Screen position:", MouseData.ScreenPoint);
            end;

            if CenterData and CenterData.TargetData then
                warn("Got Center Closest Target!")
                warn("Pointer:", CenterData.Target);
                warn("TargetData:", CenterData.TargetData);
                warn("Name:", CenterData.TargetData.Name);
                warn("Closest part:", CenterData.ClosestPart)
                warn("World position:", CenterData.WorldPosition);
                warn("Screen position:", CenterData.ScreenPoint);
            end;
        end;
    end);
end;
_G.Targeting = Targeting;
return Targeting;
