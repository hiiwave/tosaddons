local addonName = "GUILDCONTRIBPARSER";
_G["ADDONS"] = _G["ADDONS"] or {}
_G["ADDONS"][addonName] = _G["ADDONS"][addonName] or {}
local author = "hiiwave";
local version = "0.1.0"

local g = _G["ADDONS"][addonName];
local acutil = require('acutil')
g.settingPath = '../addons/guildcontribparser/'
g.contriblistPath = g.settingPath..'contrib.json'
-- g.contriblist = acutil.loadJSON(g.contriblistPath, nil) or {}


local GuildContribParser = {}

function GUILDCONTRIBPARSER_ON_INIT()
    g.addon = addon;
    GuildContribParser:load()
end

function GUILDCONTRIBPARSER_RUN(command)
    GuildContribParser:parseAll()
end


-----------------------
-- GuildContribParser Module --
-----------------------

function GuildContribParser:load()
    CHAT_SYSTEM("addon:GuildContribParser loaded")
    acutil.slashCommand('/guildcontrib', GUILDCONTRIBPARSER_RUN);
end

function GuildContribParser:parseAll()
    CHAT_SYSTEM("Start parsing guild contribution..")
    local guildgrowth = ui.GetFrame('guildgrowth')
   	if guildgrowth == nil or guildgrowth:IsVisible() == 0 then
        CHAT_SYSTEM("Guild Growth NOT visible")
        return
    end

    local contrib_list = guildgrowth:GetChild('ctrlset_growth')
                                    :GetChild('gbox_contribution')
                                    :GetChild('gbox_list')

    g.contriblist = {}
    CHAT_SYSTEM("Records num: "..contrib_list:GetChildCount() - 1)
    for i = 1, contrib_list:GetChildCount() - 1 do
        local ctrl_set = contrib_list:GetChildByIndex(i)
        self:parseOne(i, ctrl_set, g.contriblist)
    end

    acutil.saveJSON(g.contriblistPath, g.contriblist)
    CHAT_SYSTEM("Result saved to "..g.contriblistPath)
end

function GuildContribParser:parseOne(i, ctrl_set, contriblist)
    local t_name = ctrl_set:GetChild('t_name')
    local gauge = ctrl_set:GetChild('gauge')
    local record = {}
    if t_name ~= nil then
        record['name'] = string.match(t_name:GetText(), "{.*}(.*)")
        record['contrib'] = string.match(gauge:GetText(), "%d+")
        contriblist[i] = record
    end
    
end

-- dofile('../data/addon_d/guildcontribparser/guildcontribparser.lua')
-- GuildContribParser:load()