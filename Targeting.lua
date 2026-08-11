local Global = getgenv();
Global.Libraries = Global.Libraries or {};
local Libraries = Global.Libraries;

local Targeting = {};
Targeting.Dependencies = { "ESP" };

local Workspace = cloneref(game.GetService(game, "Workspace"));
local Players   = cloneref(game.GetService(game, "Players"));
local Client    = Players.LocalPlayer;
local Mouse     = Client:GetMouse();
local Camera    = Workspace.CurrentCamera;

Targeting.MouseOffset = Vector2.new();
Targeting.Camera = Camera;
Targeting.Entities = Libraries.ESP or Libraries.Entities;
Targeting.__index = Targeting;
Targeting.Debug = false;
Targeting.EnforceTeams = false;
Targeting.EnforceHealth = false;
Targeting.ClientTeam = "";
Targeting.MinHealth = 0;

do --// Targeting
    -- functions
        function Targeting:GetEntities()
            local CurrentLibraries = Global.Libraries
            if not CurrentLibraries then
                return self.Entities
            end;

            self.Entities = CurrentLibraries.ESP or CurrentLibraries.Entities or self.Entities;
            return self.Entities
        end;

        function Targeting:GetCamera()
            self.Camera = Workspace.CurrentCamera or self.Camera;
            return self.Camera
        end;

        function Targeting:TeamCheck(Entity, ClientTeam)
            if Entity.Team == ClientTeam then
                return true
            end;

            return false
        end;

        function Targeting:AliveCheck(Entity, Min)
            if Entity.Humanoid and Entity.Humanoid.Health >= Min then
                return true
            end;

            return false
        end;

        function Targeting:GetClosestEntityToMouse(Origin, MaxDistance, Radius, CheckClosest)
            local Entities = self:GetEntities();
            local Cache = Entities and ((Entities.Main and Entities.Main.Cache) or Entities.Cache or Entities.Players)
            if not Cache then
                return {
                    Target = nil,
                    ClosestPart = nil,
                    ScreenPoint = nil,
                    TargetData = nil,
                    WorldPosition = nil,
                }
            end;

            local Camera = self:GetCamera();
            local Target = nil;
            local ClosestPart = nil;
            local ScreenPoint;
            local WorldPosition;
            local TargetData;
            local Distance = math.huge;

            for Pointer, Entity in Cache do
                local Parts = Entity.BodyParts;

                if self.EnforceHealth and not self:AliveCheck(Entity, self.MinHealth) then
                    continue
                end;

                if self.EnforceTeams and self:TeamCheck(Entity, self.ClientTeam) then
                    continue
                end;

                if Parts and Parts.Head and Parts.Head:IsA("BasePart") then
                    local HeadPosition = Parts.Head.Position
                    local Magnitude = (HeadPosition - Origin).Magnitude

                    if Magnitude > MaxDistance then
                        continue
                    end;

                    local ScreenPosition, IsOnScreen = Camera:WorldToViewportPoint(HeadPosition);
                    if not IsOnScreen then
                        continue
                    end;

                    local MousePosition = Vector2.new(Mouse.X, Mouse.Y) + self.MouseOffset
                    local MouseDistance = (
                        Vector2.new(ScreenPosition.X, ScreenPosition.Y)
                        - MousePosition
                    ).Magnitude

                    if MouseDistance < Distance and MouseDistance < Radius then
                        Distance = MouseDistance;
                        Target = Pointer;
                        TargetData = Entity;
                        ScreenPoint = ScreenPosition;
                        WorldPosition = HeadPosition;
                        ClosestPart = Parts.Head;

                        local PartDistance = math.huge

                        if CheckClosest then
                            for _, Part in Parts do
                                if not Part:IsA("BasePart") then
                                    continue
                                end;

                                local PartScreenPosition, PartIsOnScreen = Camera:WorldToViewportPoint(Part.Position);
                                if not PartIsOnScreen then
                                    continue
                                end;

                                local PartMouseDistance = (
                                    Vector2.new(PartScreenPosition.X, PartScreenPosition.Y)
                                    - MousePosition
                                ).Magnitude

                                if PartMouseDistance < PartDistance then
                                    PartDistance = PartMouseDistance;
                                    ClosestPart = Part;
                                    WorldPosition = ClosestPart.Position;
                                    ScreenPoint = PartScreenPosition;
                                end;
                            end;
                        end;
                    end;
                end;
            end;

            return {
                Target = Target,
                ClosestPart = ClosestPart,
                ScreenPoint = ScreenPoint,
                TargetData = TargetData,
                WorldPosition = WorldPosition,
            }
        end;

        function Targeting:GetClosestEntityToCenter(Origin, MaxDistance, Radius, CheckClosest)
            local Entities = self:GetEntities();
            local Cache = Entities and ((Entities.Main and Entities.Main.Cache) or Entities.Cache or Entities.Players)
            if not Cache then
                return {
                    TargetData = nil,
                    Target = nil,
                    ClosestPart = nil,
                    ScreenPoint = nil,
                    WorldPosition = nil,
                }
            end;

            local Camera = self:GetCamera();
            local Target = nil;
            local ClosestPart = nil;
            local ScreenPoint;
            local WorldPosition;
            local TargetData = nil;
            local Distance = math.huge;
            local Center = Vector2.new(Camera.ViewportSize.X / 2, Camera.ViewportSize.Y / 2);

            for Pointer, Entity in Cache do
                local Parts = Entity.BodyParts;

                if self.EnforceHealth and not self:AliveCheck(Entity, self.MinHealth) then
                    continue
                end;

                if self.EnforceTeams and self:TeamCheck(Entity, self.ClientTeam) then
                    continue
                end;

                if Parts and Parts.Head and Parts.Head:IsA("BasePart") then
                    local HeadPosition = Parts.Head.Position
                    local Magnitude = (HeadPosition - Origin).Magnitude

                    if Magnitude > MaxDistance then
                        continue
                    end;

                    local ScreenPosition, IsOnScreen = Camera:WorldToViewportPoint(HeadPosition);
                    if not IsOnScreen then
                        continue
                    end;

                    local ScreenDelta = (Vector2.new(ScreenPosition.X, ScreenPosition.Y) - Center).Magnitude

                    if ScreenDelta < Distance and ScreenDelta < Radius then
                        Distance = ScreenDelta;
                        Target = Pointer;
                        TargetData = Entity;
                        ScreenPoint = ScreenPosition;
                        WorldPosition = HeadPosition;
                        ClosestPart = Parts.Head;

                        local PartDistance = math.huge;

                        if CheckClosest then
                            for _, Part in Parts do
                                if not Part:IsA("BasePart") then
                                    continue
                                end;

                                local PartScreenPosition, PartIsOnScreen = Camera:WorldToViewportPoint(Part.Position);
                                if not PartIsOnScreen then
                                    continue
                                end;

                                local PartDelta = (Vector2.new(PartScreenPosition.X, PartScreenPosition.Y) - Center).Magnitude;

                                if PartDelta < PartDistance then
                                    PartDistance = PartDelta;
                                    ClosestPart = Part;
                                    WorldPosition = Part.Position;
                                    ScreenPoint = PartScreenPosition;
                                end;
                            end;
                        end;
                    end;
                end;
            end;

            return {
                TargetData = TargetData,
                Target = Target,
                ClosestPart = ClosestPart,
                ScreenPoint = ScreenPoint,
                WorldPosition = WorldPosition,
            }
        end;
    --
end;

do --// Debug
    if Targeting.Debug then
        local UserInputService = cloneref(game.GetService(game, "UserInputService"));

        UserInputService.InputBegan:Connect(function(Input)
            if Input.KeyCode == Enum.KeyCode.E then
                local CurrentCamera = Targeting:GetCamera();
                local MouseData = Targeting:GetClosestEntityToMouse(
                    CurrentCamera.CFrame.Position,
                    2000,
                    1000,
                    true
                );

                local CenterData = Targeting:GetClosestEntityToCenter(
                    CurrentCamera.CFrame.Position,
                    2000,
                    1000,
                    true
                );

                if MouseData and MouseData.TargetData then
                    print("Got Mouse Closest Target!");
                    print("Pointer:", MouseData.Target);
                    print("TargetData:", MouseData.TargetData);
                    print("Name:", MouseData.TargetData.Name);
                    print("Closest part:", MouseData.ClosestPart);
                    print("World position:", MouseData.WorldPosition);
                    print("Screen position:", MouseData.ScreenPoint);
                end;

                if CenterData and CenterData.TargetData then
                    warn("Got Center Closest Target!");
                    warn("Pointer:", CenterData.Target);
                    warn("TargetData:", CenterData.TargetData);
                    warn("Name:", CenterData.TargetData.Name);
                    warn("Closest part:", CenterData.ClosestPart);
                    warn("World position:", CenterData.WorldPosition);
                    warn("Screen position:", CenterData.ScreenPoint);
                end;
            end;
        end);
    end;
end;

Libraries.Targeting = Targeting;
return Targeting
