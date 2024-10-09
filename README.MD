# HappyToolkit

<img src="./Media/logo.jpg" alt="HappyToolkit" width="160" height="300">

This is a World of Warcraft addon that collect your toys and items, use them anytime without searching it.

### Usage
- You can use the command `/click ToggleHappyToolkitGUIButton` to toggle the window state.
- You can also set a keybinding in the keybinding settings to toggle the window state.

### How to Register New Icons?
To add new icons to HappyToolkit, you can use the following code snippet. This function checks if an item is learned and usable before registering it:

```lua
local function callbackFunc()
    local isLearned = true  -- Check if the item is learned
    local isUsable = true   -- Check if the item is usable
    if isLearned and isUsable then
        return function ()
            return {
                closeGUIAfterClick = true,  -- Close the GUI after clicking the icon
                icon = nil,                  -- Path to the icon
                text = nil,                  -- Display text
                macro = {                    -- Item or ability IDs
                    itemID = nil,
                    toyID = nil,
                    spellID = nil,
                    petID = nil,              -- SpeciesID, not the petGUID
                    mountID = nil,
                },
                leftClickCallback = nil      -- Callback function after left click
            }
        end
    else
        return nil  -- the callback will not be register if return nil. 
    end
end

local frame = CreateFrame("Frame")
frame:RegisterEvent("ADDON_LOADED")
frame:SetScript("OnEvent", function(self, event, addonName)
    if addonName == "your addon name" then
        if G_HAPPY_TOOLKIT and G_HAPPY_TOOLKIT.Register then
            G_HAPPY_TOOLKIT.Register("{category}", callbackFunc) -- category options: teleprot,class,profession,mail,bank,merchant,other
        end
    end
end)
```

### TODO:
1. Add more useful toys and items.
2. Support for players to manually add toys and items.
3. Hide the button if the button can not used.

### Known Bugs:
1. `leftClickCallback` not working.

### Logo Attribution
- **Logo Source**: The logo is sourced from [wowhead](https://www.wowhead.com/item=151351/glowing-gift).

If you have any suggestions or discover any bugs, please raise them in the issues.
