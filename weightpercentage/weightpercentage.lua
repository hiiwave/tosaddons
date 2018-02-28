local addonName = "WEIGHTPERCENTAGE";
local addonNameLower = string.lower(addonName);
local author = "hiiwave";
local version = "0.1.3"

_G["ADDONS"] = _G["ADDONS"] or {};
_G["ADDONS"][author] = _G["ADDONS"][author] or {};
_G["ADDONS"][author][addonName] = _G["ADDONS"][author][addonName] or {};
local g = _G["ADDONS"][author][addonName];


local itemHelper = {}
local weightScale = {}

function WEIGHTPERCENTAGE_ON_INIT()
  g.addon = addon;
  g.frame = frame;
  CHAT_SYSTEM("addon:WeightScale loaded")
  weightScale:load()
end


-----------------------
-- weightScale Module --
-----------------------

--! load command
function weightScale:load()
  local acutil = require('acutil')
  acutil.slashCommand('/weight', WEIGHTSCALE_RUN);
end

--! function hooked to command
function WEIGHTSCALE_RUN(command)
  local threshold = 0
  if #command == 0 then
    -- weightScale:print(DEVELOPERCONSOLE_PRINT_TEXT)
    weightScale:print(CHAT_SYSTEM)
  else
    cmd = table.remove(command, 1)
    if tonumber(cmd) then
      weightScale:print(CHAT_SYSTEM, tonumber(cmd))
    elseif string.find(cmd, "potion") then
      weightScale:print(CHAT_SYSTEM, 0, true)  --isPotionSeparated = true
    else
      weightScale:print(CHAT_SYSTEM)
    end
  end
end

--! Print the results by printfunc
--! @param printfunc can be CHAT_SYSTEM, DEVELOPERCONSOLE_PRINT_TEXT, .etc
--! @param percentage_threshold only print weights larger than threshold
--! @param isPotionSeparated whether separate potion from Consume
function weightScale:print(printfunc, percentage_threshold, isPotionSeparated)
  local weights_map = self:calculateWeightMap(isPotionSeparated)
  local maxweight = GetMyPCObject().MaxWeight
  local total = self:totalWeight(weights_map)
  percentage_threshold = percentage_threshold or 0  --0 is treated true in lua
  printfunc("== Weights ==")
  for category, w in spairs(weights_map,
                     function(t,a,b) return t[b] < t[a] end) do
    local percentage = w / maxweight * 100
    if percentage <= percentage_threshold then break end
    local repr = string.format("%s: %d (%.1f%%)", category, w, percentage)
    printfunc(repr)
  end
  -- printfunc("(ignore those < percentage_threshold%)")
  local total_percentage = total / maxweight * 100
  printfunc(string.format("Total: %d (%.1f%%)", total, total_percentage))
  -- printfunc("==========")
end

--! Create a map [category: weight] and return
--! @param isPotionSeparated bool
--!        true if you want to separate category Consume
--!        to Consume(Portion) and Consume(Else)
function weightScale:calculateWeightMap(isPotionSeparated)
  local inventoryItems = itemHelper:getitems()
  local weights_map = {}
  for type = 1 , #SLOTSET_NAMELIST do
    local category = SLOTSET_NAMELIST[type]
    category = string.sub(category, 6)
    local items = inventoryItems[type]
    if isPotionSeparated and category == 'Consume' then
      weights_map['Consume(Portion)'], weights_map['Consume(Else)'] = self:sumweight_consume(items)
    else
      weights_map[category] = self:sumweight(items)
    end
  end
  local pc = GetMyPCObject();
  weights_map['Equiping'] = pc.NowWeight - self:totalWeight(weights_map)
  return weights_map
end

--! Testing Purporse only
function weightScale:test()
  local inventoryItems = itemHelper:getitems()
  local type = 7
  local items = inventoryItems[type]
  -- pprinting.dump(tablelength(items))
  for p, v in pairs(items) do
    -- pprinting.dump(v)
  end
end

--! return the totalWeight on knapsack except for wore equipments
function weightScale:totalWeight(weights_map)
  local sum = 0
  for k, v in pairs(weights_map) do
    sum = sum + v
  end
  return sum
end

--! return the sum of weights given items,
--! used when calculating sum of weights for each category
function weightScale:sumweight(items)
  local weight = 0
  for k, v in pairs(items) do
    weight = weight + v.count * v.weight
  end
  return weight
end

--! return the sum of weights given items,
--! but differentiate portion
function weightScale:sumweight_consume(items)
  local weight_portion = 0
  local weight_else = 0
  for k, v in pairs(items) do
    if itemHelper:isPotion(v.name) then
      weight_portion = weight_portion + v.count * v.weight
    else
      weight_else = weight_else + v.count * v.weight
    end
  end
  return weight_portion, weight_else
end


-----------------------
-- itemHelper Module --
-----------------------

--! Get an item table from game UI
function itemHelper:getitems()
  local inventoryItems = {}
  local group = GET_CHILD(ui.GetFrame('inventory'), 'inventoryGbox', 'ui::CGroupBox')
  local tree_box = GET_CHILD(group, 'treeGbox_ITEM','ui::CGroupBox')
  local tree = GET_CHILD(tree_box, 'inventree_ITEM','ui::CTreeControl')
  local tree_box2 = GET_CHILD(group, 'treeGbox_EQUIP','ui::CGroupBox')
  local tree2 = GET_CHILD(tree_box2, 'inventree_EQUIP','ui::CTreeControl')

  for i = 1 , #SLOTSET_NAMELIST do
    repeat
      inventoryItems[i] = {}
      local slotSet = GET_CHILD(tree, SLOTSET_NAMELIST[i],'ui::CSlotSet')
      local slotSet2 = GET_CHILD(tree2, SLOTSET_NAMELIST[i],'ui::CSlotSet')
      slotSet = slotSet or slotSet2
      for j = 0 , slotSet:GetChildCount() - 1 do
        local slot = slotSet:GetChildByIndex(j);
        local invItem = GET_SLOT_ITEM(slot);
        if invItem then
          table.insert(inventoryItems[i], self:buildAnItem(invItem))
        end
      end
    until true
  end
  return inventoryItems
end

--! Parse item from SLOT_ITEM
--! (credit to axjv: https://github.com/axjv/Input-Switcher)
function itemHelper:buildAnItem(invItem)
  itemobj = {}
  if invItem ~= nil then
    local invIndex = invItem.invIndex
    local itemCls = GetIES(invItem:GetObject());
    if itemCls ~= nil then
      itemobj.name = dictionary.ReplaceDicIDInCompStr(itemCls.Name)
      itemobj.slot = slot
      itemobj.slotset = slotSet
      itemobj.count = GET_REMAIN_INVITEM_COUNT(invItem)
      itemobj.weight = itemCls.Weight
      itemobj.itemtype = itemCls.ItemType
      itemobj.type = itemCls.StringArg..dictionary.ReplaceDicIDInCompStr(itemCls.Name)
      itemobj.grade = itemHelper:getItemGrade(itemCls)
      itemobj.icon = itemCls.Icon..dictionary.ReplaceDicIDInCompStr(itemCls.Name)
      itemobj.lock = invItem.isLockState
    end
  end
  return itemobj
end

--! Get itemGrade (Credit to Mie)
function itemHelper:getItemGrade(itemCls)
  if (itemCls.ItemType == "Recipe") then
    local recipeGrade = string.match(itemCls.Icon, "misc(%d)");
    if recipeGrade ~= nil then
      return (tonumber(recipeGrade) - 1)..itemCls.Name;
    end
  else
    return itemCls.ItemGrade..itemCls.Name
  end
end

--! check if an item is a potion
function itemHelper:isPotion(itemname)
  local keywords = {"藥水", "ポーション", "Potion", "포션"}
  for k, word in pairs(keywords) do
    if string.find(itemname, word) then
      return true
    end
  end
  return false
end


----------------------
-- Helper Functions --
----------------------

-- iterate over table in some order
-- credit to Michal Kottman:  https://stackoverflow.com/questions/15706270/sort-a-table-in-lua
function spairs(t, order)
  -- collect the keys
  local keys = {}
  for k in pairs(t) do keys[#keys+1] = k end

  -- if order function given, sort by it by passing the table and keys a, b,
  -- otherwise just sort the keys
  if order then
    table.sort(keys, function(a,b) return order(t, a, b) end)
  else
    table.sort(keys)
  end

  -- return the iterator function
  local i = 0
  return function()
    i = i + 1
    if keys[i] then
      return keys[i], t[keys[i]]
    end
  end
end

-- For debugging
-- dofile('../data/addon_d/weightpercentage/weightpercentage.lua')
-- CHAT_SYSTEM("addon:WeightScale loaded")
-- weightScale:load()
