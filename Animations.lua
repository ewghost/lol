--[[
    1/21/2026
    Animations.luau
    Purpose:
        Animations to be used across all NH modules & games
    Author: @.yxyv
    Dependencies:
        None
]]

local Animations = {};
local TweenService = game:GetService('TweenService');
local TweenInfoNew = TweenInfo.new;
local QuadEasingStyle = Enum.EasingStyle.Quad;

--#region Animations
function Animations:Tween(...)
    local Tween = TweenService:Create(...)
    Tween:Play();
    return Tween;
end;

function Animations:Basic(Data)
    local Properties = {}
    Properties[Data.Property] = Data.Value

    return Animations:Tween(
        Data.Component,
        TweenInfoNew(Data.Speed or 0.15, QuadEasingStyle),
        Properties
    )
end;
--#endregion Animations
_G.Animations = Animations;
return Animations
