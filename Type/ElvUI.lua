---@meta _
---@class ElvUI
---@field Media {Textures: {[string]: string}}
---@field TexCoords number[]
local ElvUI = {}

---@param module  string
---@return any
function ElvUI:GetModule(module) end

---@class ElvUISkins
---@field HandleButton fun(self: ElvUISkins, button: Button): nil
local ElvUISkins = {}