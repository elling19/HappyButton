# HappyButton

<img src="./Media/Logo64.png" alt="HappyButton" width="64" height="64">


[中文README](README_CN.md)


Welcome to the **HappyButton** plugin! This is a **World of Warcraft** plugin that primarily provides custom item bar functionality, making it easier to manage items, equip items, skills, mounts, toys, and pets.

## Features
- **Custom Item Bars**: You can create item bars and item bar groups in the settings interface, and create items, item groups, and scripts for them.
- **Custom Settings**: You can add settings to your defined item bars, including frame attachment, position, load conditions, and display conditions.
- **Configuration Strings**: You can share the item bars you create with other players in the form of strings.

## Installation
1. Download the plugin files.
2. Extract them to the AddOns directory: `Interface/AddOns`.
3. Reload the game.

## Usage
### Open the Settings Interface
Use the command `/hb` to open the settings interface, or click on the game menu -> AddOns -> `HappyButton` to open the settings interface.
### Settings
Once the settings interface is open, you will see three settings menus in the left sidebar:
- **Basic Settings**: Includes `Edit Mode` and import/export for `Plugin Configuration Strings`.
- **Element Settings**: Includes settings for `BarGroup`, `Bar`, `ItemGroup`, `Item`, and `Script`.
- **Profiles**: Used for switching configurations.

## Special Note
Due to Blizzard API limitations, the plugin cannot automatically update/create/delete/move item buttons during combat. Therefore, when combat begins, the plugin will automatically hide the `BarGroup` and disable automatic updates for all items.

## Logo
- **Source**: The logo was created using AI.
- **BLP File Creation**: The BLP file was created using the tool [BLP Lab v0.5.0](https://www.hiveworkshop.com/threads/blp-lab-v0-5-0.137599/).

## Feedback
If you have any suggestions, please provide feedback on GitHub or submit an issue.