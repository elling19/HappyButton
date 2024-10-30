local addonName, _ = ... ---@type string, table
local addon = LibStub('AceAddon-3.0'):GetAddon(addonName)

---@class Client: AceModule
local Client = addon:NewModule("Client")

function Client:IsRetail()
    local version = select(4, GetBuildInfo())
    return version > 110000
end
