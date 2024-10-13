---@class HtItem
---@field type integer | nil
---@field id integer | nil
---@field icon integer | string | nil
---@field name string | nil
local htItem = {}


---@class ProfileConfig
---@field tmpConfigString string
---@field GenerateNewProfileName function
---@field ShowLoadConfirmation function
local profileConfig = {}


---@class ProfileConfig.ConfigTable
---@field name string
---@field profile table

---@class Config
---@field tmpCoverConfig boolean 
---@field tmpImportSourceString string?
---@field tmpNewItemType integer?
---@field tmpNewItemVal HtItem
---@field ShowExportDialog function
---@field IsTitleDuplicated function
---@field CreateDuplicateTitle function
local Config = {}


---@class ConfigOptions
---@field CategoryOptions function
---@field IconSourceOptions function
---@field ConfigOptions function
---@field Options function
local ConfigOptions = {}