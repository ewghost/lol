local UidBackend = {}
UidBackend.__index = UidBackend
UidBackend.Dependencies = {}

local Global = getgenv()
Global.Libraries = Global.Libraries or {}

local HttpService = cloneref(game:GetService("HttpService"))
local Request = request or http_request or (syn and syn.request) or (http and http.request)

local LpUrl = "https://api.luaprot.net/api/v2/storage"

local function Encode(Query)
    local Parts = {}

    for Key, Value in Query do
        if Value ~= nil then
            Parts[#Parts + 1] = HttpService:UrlEncode(tostring(Key)) .. "=" .. HttpService:UrlEncode(tostring(Value))
        end
    end

    return table.concat(Parts, "&")
end

local function Decode(Body)
    if type(Body) ~= "string" or Body == "" then
        return nil
    end

    local Success, Result = pcall(function()
        return HttpService:JSONDecode(Body)
    end)

    return Success and Result or nil
end

function UidBackend.new(Config)
    assert(Request, "No HTTP request function available.")
    assert(type(Config) == "table", "UidBackend.new expects a config table.")
    assert(Config.ApiKey, "UidBackend.new missing ApiKey.")
    assert(Config.HubId, "UidBackend.new missing HubId.")

    return setmetatable({
        ApiKey = Config.ApiKey,
        HubId = tostring(Config.HubId),
        LpUrl = Config.LpUrl or LpUrl,
        CounterKey = Config.CounterKey or "__uid_counter",
        CounterValueId = Config.CounterValueId or "next_uid",
        UserValuePrefix = Config.UserValuePrefix or "uid_",
    }, UidBackend)
end

function UidBackend:Request(Method, Query, Body)
    Query = Query or {}
    Query.hubId = Query.hubId or self.HubId

    local Url = self.LpUrl
    local QueryString = Encode(Query)
    if QueryString ~= "" then
        Url ..= "?" .. QueryString
    end

    local Response = Request({
        Url = Url,
        Method = Method,
        Headers = {
            ["Content-Type"] = "application/json",
            ["Authorization"] = self.ApiKey,
        },
        Body = Body and HttpService:JSONEncode(Body) or nil,
    })

    local Data = Decode(Response and Response.Body)
    return Data or {
        success = false,
        statusCode = Response and (Response.StatusCode or Response.Status) or 0,
        message = Response and Response.Body or "Request failed.",
    }
end

function UidBackend:List(Query)
    return self:Request("GET", Query)
end

function UidBackend:Get(Query)
    Query = Query or {}
    Query.exact = Query.exact or 1
    return self:Request("GET", Query)
end

function UidBackend:Create(Data)
    Data = table.clone(Data or {})
    Data.hubId = Data.hubId or self.HubId
    return self:Request("POST", nil, Data)
end

function UidBackend:Update(Data)
    Data = table.clone(Data or {})
    Data.hubId = Data.hubId or self.HubId
    return self:Request("PATCH", nil, Data)
end

function UidBackend:Delete(Query)
    return self:Request("DELETE", Query)
end

function UidBackend:GetValue(Key, Hwid, ValueId)
    local Result = self:Get({
        key = Key,
        hwid = Hwid,
        valueId = ValueId,
        exact = 1,
    })

    return Result and Result.success and Result.entry and Result.entry.data, Result
end

function UidBackend:SetValue(Key, Hwid, ValueId, Data)
    local Existing = self:Get({
        key = Key,
        hwid = Hwid,
        valueId = ValueId,
        exact = 1,
    })

    if Existing and Existing.success and Existing.entry then
        return self:Update({
            originalKey = Key,
            originalHwid = Hwid,
            originalValueId = ValueId,
            key = Key,
            hwid = Hwid,
            valueId = ValueId,
            data = Data,
        })
    end

    return self:Create({
        key = Key,
        hwid = Hwid,
        valueId = ValueId,
        data = Data,
    })
end

function UidBackend:GetNextUID()
    local Current = tonumber(self:GetValue(self.CounterKey, nil, self.CounterValueId)) or 0
    local UID = Current + 1
    self:SetValue(self.CounterKey, nil, self.CounterValueId, UID)
    return UID
end

function UidBackend:GetUID(UserKey, Hwid)
    assert(UserKey ~= nil, "GetUID missing UserKey.")

    local Key = tostring(UserKey)
    local ValueId = self.UserValuePrefix .. Key
    local Existing = self:GetValue(Key, Hwid, ValueId)
    local ExistingUID = tonumber(Existing)

    if ExistingUID ~= nil then
        return ExistingUID
    end

    local UID = self:GetNextUID()
    self:SetValue(Key, Hwid, ValueId, UID)
    return UID
end

Global.Libraries.UidBackend = UidBackend
return UidBackend
