-- BusinessInventoryStorageController.lua
-- Malik Allen LLC, Roblox Studio Pro GPT

local Player = game.Players.LocalPlayer
local MasterFolder = game.ReplicatedStorage.InventorySystem

-- UI Elements
local StorageSlots = script.Parent.InventorySlots
local InfoPanel = script.Parent.InfoPanel
local NextArrow = script.Parent.NextArrow
local PreviousArrow = script.Parent.PreviousArrow
local PageIndicator = script.Parent.PageIndicator
local SpaceCount = script.Parent.SpaceCount
local TakeButton = InfoPanel.TakeButton
local InfoDescription = InfoPanel.Description
local InfoItemName = InfoPanel.ItemName

-- Events
local Events = MasterFolder.Events
local RemoveFromStorageEvent = Events.ClientServer.RemoveFromStorage -- Event to remove items from storage

-- Modules
local ItemDB = require(MasterFolder.Modules.ItemData)

-- Static
local SlotCount = 9

-- Tracking
local CurrentStorageItems = {}
local CurrentPages = {}
local CurrentSelectedPage = 1
local CurrentSelectedItem = nil

-- Organize items into pages for display
function GetPages(Items)
    local Pages = {}
    local CurrentPage = 1
    for i, Item in ipairs(Items) do
        if not Pages[CurrentPage] then Pages[CurrentPage] = {} end
        if #Pages[CurrentPage] < SlotCount then
            table.insert(Pages[CurrentPage], Item)
        end
        if #Pages[CurrentPage] >= SlotCount then
            CurrentPage += 1
        end
    end
    return Pages
end

-- Update the space count in storage
function UpdateSpaceCount()
    local StorageSpace = #CurrentStorageItems
    SpaceCount.Text = string.format("%d / %d", StorageSpace, 50) -- Assuming max storage space is 50
end

-- Select and display items from a specific page
function SelectPage(PageNumber)
    local Page = CurrentPages[PageNumber] or {}

    -- Clear item selection when updating the page display
    UpdateInfoPanel(nil)

    for i, Item in ipairs(StorageSlots:GetChildren()) do
        Item:SetAttribute("CurrentItem", nil)
        Item.Image = ""
        Item.ImageColor3 = Color3.new(1, 1, 1)

        local PageItem = Page[i]
        if not PageItem then continue end

        local ItemInfo = ItemDB.Items[PageItem]
        if not ItemInfo then continue end

        Item:SetAttribute("CurrentItem", PageItem)
        Item.Image = ItemInfo["Image"]
    end

    CurrentSelectedPage = PageNumber
    PageIndicator.Text = string.format("Page %d Of %d", PageNumber, #CurrentPages)
end

-- Switch between pages
function MoveToPage(ByValue)
    local TargetNumber = CurrentSelectedPage + ByValue
    if CurrentPages[TargetNumber] then
        SelectPage(TargetNumber)
        UpdateInfoPanel(CurrentSelectedItem)
    end
end

-- Update the storage items when there's a change
function UpdateStorageItems(Items)
    CurrentStorageItems = Items
    CurrentPages = GetPages(Items)
    SelectPage(1)
    UpdateSpaceCount()
end

-- Update the info panel for the selected item
function UpdateInfoPanel(Item)
    if CurrentSelectedItem then
        CurrentSelectedItem.ImageColor3 = Color3.new(1, 1, 1)
    end

    CurrentSelectedItem = Item

    if CurrentSelectedItem then
        CurrentSelectedItem.ImageColor3 = Color3.new(1, 0, 0.0156863)
    end

    local ItemName = (CurrentSelectedItem and CurrentSelectedItem:GetAttribute("CurrentItem")) or nil

    if not ItemName then
        InfoPanel.Visible = false -- Hide InfoPanel if no item is selected
        return
    end

    -- Display item information if an item is selected
    InfoPanel.Visible = true
    local ItemInfo = ItemDB.Items[ItemName]
    InfoItemName.Text = ItemName
    InfoDescription.Text = ItemInfo["Description"] or "No Description Available"

    -- Customize description based on item type
    if ItemInfo["Type"] == "Wearable" then
        InfoDescription.Text = string.format("<i>%s</i>\n<b><br />Health: %d<br />Speed: %d</b>", ItemInfo["Description"], ItemInfo["Health"] or 0, ItemInfo["Speed"] or 0)
    elseif ItemInfo["Type"] == "Tool" then
        InfoDescription.Text = string.format("<i>%s</i>\n<b><br />Damage: %d</b>", ItemInfo["Description"], ItemInfo["Damage"] or 0)
    elseif ItemInfo["Type"] == "Food" then
        InfoDescription.Text = string.format("<i>%s</i>\n<b><br />+%d Health</b>", ItemInfo["Description"], ItemInfo["HealthAmount"] or 0)
    elseif ItemInfo["Type"] == "Drink" then
        InfoDescription.Text = string.format("<i>%s</i>\n<b><br />+%d Speed<br />Duration: %d seconds</b>", ItemInfo["Description"], ItemInfo["SpeedBoost"] or 0, ItemInfo["EffectDuration"] or 0)
    end
end

-- Select an item from the storage inventory
for _, Item in ipairs(StorageSlots:GetChildren()) do
    Item.MouseButton1Click:Connect(function()
        UpdateInfoPanel(Item)
    end)
end

-- Handle the Take action to move an item to the player's inventory
TakeButton.MouseButton1Click:Connect(function()
    if not CurrentSelectedItem or not CurrentSelectedItem:GetAttribute("CurrentItem") then return end
    local itemName = CurrentSelectedItem:GetAttribute("CurrentItem")
    RemoveFromStorageEvent:FireServer(itemName, 1) -- Move item to player inventory
end)

-- Navigation buttons for next/previous pages
NextArrow.MouseButton1Click:Connect(function() MoveToPage(1) end)
PreviousArrow.MouseButton1Click:Connect(function() MoveToPage(-1) end)

-- Event listener to update storage items
Events.ServerClient.UpdateStorageUI.OnClientEvent:Connect(function(data)
    UpdateStorageItems(data.Inventory or {})
end)
