function TakeUnfoundBooks(srcContainer)
    local items = srcContainer:getItems()
    local alreadyTakenItems = {}
    local RB = EHIFTB.getPlayerMemory().rememberedBooks

    local activeContainer = getPlayerInventory(0).inventoryPane.inventory
    if activeContainer:getType() == "KeyRing" then
        getPlayer():Say("Les livres ne rentrent pas dans un trousseau de clefs...")
        return
    end
    for i = 0, items:size() - 1 do
        local item = items:get(i)
        local idType = EHIFTB.isValidEHIFTBItem(item, "grab")
        if idType then
            local identifier = EHIFTB.getItemIdentifier(item)
            if
                not RB[identifier] and not alreadyTakenItems[identifier] and
                    not EHIFTB.isValidItemInInventory(idType, identifier, item)
             then
                local transferItem = ISInventoryTransferAction:new(getPlayer(), item, srcContainer, activeContainer)
                ISTimedActionQueue.add(transferItem)
                alreadyTakenItems[identifier] = true
            end
        end
    end
end

local function addTakeUnfoundBooks(player, context, items)
    local item
    if items[1].items then
        item = items[1].items[1]
    else -- if right-clicked in hotbar
        item = items[1]
    end
    local isItemInInventory = EggonsMU.functions.isACarriedContainer(itemContainer)
    if EHIFTB.isValidEHIFTBItem(item, "grab") and not isItemInInventory then
        local itemContainer = item:getContainer()
        context:addOption("Prendre tous les livres et magazines non encore lu", itemContainer, TakeUnfoundBooks)
    end
end

Events.OnFillInventoryObjectContextMenu.Add(addTakeUnfoundBooks)
