-- BusinessInventoryStorageController.lua
-- Malik Allen LLC, Roblox Studio Pro GPT

local Player = game.Players.LocalPlayer

-- References to UI elements within BusinessInventoryStorage
local StorageSlots = Player:WaitForChild("PlayerGui"):WaitForChild("Menues"):WaitForChild("BusinessStorage"):WaitForChild("BusinessInventoryStorage"):WaitForChild("InventorySlots")
local InfoPanel = script.Parent:WaitForChild("InfoPanel")
local TakeButton = InfoPanel:WaitForChild("TakeButton")
local NextArrow = script.Parent:WaitForChild("NextArrow")
local PreviousArrow = script.Parent:WaitForChild("PreviousArrow")
local PageIndicator = script.Parent:WaitForChild("PageIndicator")
local SpaceCount = script.Parent:WaitForChild("SpaceCount")
local InfoDescription = InfoPanel:WaitForChild("Description")
local InfoItemName = InfoPanel:WaitForChild("ItemName")

-- Modules and Events
local MasterFolder = game.ReplicatedStorage.InventorySystem
local ItemDB = require(MasterFolder.Modules.ItemData)
local Events = MasterFolder.Events
local UpdateStorageUIEvent = Events.ServerClient.UpdateStorageUI
local RemoveFromStorageEvent = Events.ClientServer.RemoveFromStorage
local LoadPlayerDataEvent = game.ReplicatedStorage.PlayerDataSystem.Events.ServerClient.LoadData

-- Static
local SlotCount = 9

-- Tracking Variables
local CurrentStorageItems = {}
local CurrentPages = {}
local CurrentSelectedPage = 1
local CurrentSelectedItem = nil

InfoPanel.Visible = false  -- Set InfoPanel initially to be hidden

local function GetPages(items)
	local pages = {}
	local currentPage = 1
	for i, item in ipairs(items) do
		if not pages[currentPage] then
			pages[currentPage] = {}
		end
		if #pages[currentPage] < SlotCount then
			table.insert(pages[currentPage], item)
		end
		if #pages[currentPage] >= SlotCount then
			currentPage += 1
		end
	end
	return pages
end

local function UpdateStorageDisplay()
	local page = CurrentPages[CurrentSelectedPage] or {}
	for i, slot in ipairs(StorageSlots:GetChildren()) do
		slot:SetAttribute("CurrentItem", nil)
		slot.Image = ""
		slot.ImageColor3 = Color3.new(1, 1, 1)
		local itemName = page[i]
		if itemName then
			local itemInfo = ItemDB.Items[itemName]
			if itemInfo then
				slot:SetAttribute("CurrentItem", itemName)
				slot.Image = itemInfo.Image
			end
		end
	end
	PageIndicator.Text = string.format("Page %d of %d", CurrentSelectedPage, #CurrentPages)
end

local function UpdateStorageItems(items)
	CurrentStorageItems = items
	CurrentPages = GetPages(items)
	CurrentSelectedPage = 1
	UpdateStorageDisplay()
end

local function UpdateSpaceCount()
	local businessStorageCapacity = 20 -- Adjust based on actual capacity
	SpaceCount.Text = string.format("%d / %d", #CurrentStorageItems, businessStorageCapacity)
end

local function UpdateInfoPanel(selectedSlot)
	if CurrentSelectedItem then
		CurrentSelectedItem.ImageColor3 = Color3.new(1, 1, 1)
	end
	CurrentSelectedItem = selectedSlot
	if CurrentSelectedItem then
		CurrentSelectedItem.ImageColor3 = Color3.new(1, 0, 0.0156863)
		local itemName = CurrentSelectedItem:GetAttribute("CurrentItem")
		if itemName then
			local itemInfo = ItemDB.Items[itemName]
			InfoPanel.Visible = true
			InfoItemName.Text = itemName
			InfoDescription.Text = itemInfo.Description or "No Description Available"
			TakeButton.Visible = true
		else
			InfoPanel.Visible = false
		end
	else
		InfoPanel.Visible = false
	end
end

NextArrow.MouseButton1Click:Connect(function()
	if CurrentPages[CurrentSelectedPage + 1] then
		CurrentSelectedPage += 1
		UpdateStorageDisplay()
		UpdateInfoPanel(nil) -- Clear selection when page changes
	end
end)

PreviousArrow.MouseButton1Click:Connect(function()
	if CurrentSelectedPage > 1 then
		CurrentSelectedPage -= 1
		UpdateStorageDisplay()
		UpdateInfoPanel(nil) -- Clear selection when page changes
	end
end)

LoadPlayerDataEvent.OnClientEvent:Connect(function(data)
	UpdateStorageItems(data.BusinessInventory or {})
	UpdateSpaceCount()
end)

UpdateStorageUIEvent.OnClientEvent:Connect(function(data)
	UpdateStorageItems(data.Storage or {})
	UpdateSpaceCount()
end)

for _, slot in ipairs(StorageSlots:GetChildren()) do
	slot.MouseButton1Click:Connect(function()
		UpdateInfoPanel(slot)
	end)
end

TakeButton.MouseButton1Click:Connect(function()
	if CurrentSelectedItem and CurrentSelectedItem:GetAttribute("CurrentItem") then
		local selectedItemName = CurrentSelectedItem:GetAttribute("CurrentItem")
		RemoveFromStorageEvent:FireServer(selectedItemName, 1)
		for i, item in ipairs(CurrentStorageItems) do
			if item == selectedItemName then
				table.remove(CurrentStorageItems, i)
				break
			end
		end
		UpdateStorageItems(CurrentStorageItems)
		UpdateInfoPanel(nil) -- Clear selection after taking item
	end
end)
