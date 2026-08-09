--[[
    1/21/2026
    Utility.luau
    Purpose:
        Utility functions to be used across all NH games
    Author: @.yxyv
    Dependencies:
        None
]]

local Utility = {};
local Elements = {
    Instantiated = {},
};
local UserInputService = game:GetService("UserInputService");
local InstanceNew = Instance.new;
--#region Utility
function Utility:GetMouseLocation()
    return UserInputService:GetMouseLocation();
end;

function Utility:Instance(Class, Data)
    local NewInstance = InstanceNew(Class);

    for Property, Value in Data do
        NewInstance[Property] = Value;
    end;

    local Instantiated = Elements.Instantiated
    Instantiated[#Instantiated + 1] = NewInstance
    return NewInstance
end;

function Utility:DisconnectConnections(Set)
    if type(Set) ~= "table" then
        return
    end

    for Index = 1, #Set do
        local Connection = Set[Index]
        if Connection and typeof(Connection.Disconnect) == "function" then
            Connection:Disconnect()
        end
        Set[Index] = nil
    end
end

function Utility:FormatHoursMinutes(Seconds)
    local TotalSeconds = tonumber(Seconds) or 0
    local Hours = math.floor(TotalSeconds / 3600)
    local Minutes = math.floor((TotalSeconds % 3600) / 60)
    return Hours, Minutes, (`{Hours}h/{Minutes}m`)
end

function Utility:LerpColor(a, b, t)
    return Color3.new(
        a.R + (b.R - a.R) * t,
        a.G + (b.G - a.G) * t,
        a.B + (b.B - a.B) * t
    )
end

function Utility:ColorToRichRGB(Color)
    return string.format(
        "rgb(%d,%d,%d)",
        math.floor(Color.R * 255),
        math.floor(Color.G * 255),
        math.floor(Color.B * 255)
    )
end

function Utility:SetIndicatorRow(Row, Text)
    local Label = Row and Row.Instance
    if Label and Label.Text ~= Text then
        Label.Text = Text
    end
end

function Utility:GetFlatLookVector(SourceCFrame)
    local LookVector = SourceCFrame.LookVector
    local FlatLook = Vector3.new(LookVector.X, 0, LookVector.Z)
    if FlatLook.Magnitude < 0.001 then
        return Vector3.new(0, 0, -1)
    end

    return FlatLook.Unit
end

--#endregion Utility
_G.Utility = Utility;
return Utility;
