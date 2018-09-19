--[[
	Single Buff Monitor, by default for hunter pet's frenzy buff
	Copyright (c) 2018, stephen Liang
	All rights reserved.
]]

----------------------------------------------------
-- Initializing Addon 
----------------------------------------------------

BuffMonitorAddon = {}
BuffMonitorAddon.spell_id = 272790

-- BuffMonitorAddon.spell_name = spell_name
-- BuffMonitorAddon.spell_icon = spell_icon

-- pet by default but can be set to player, focus, target or more : https://wow.gamepedia.com/UnitId
BuffMonitorAddon.targetToMonitor = "pet"  
BuffMonitorAddon.frameWidth = 50
BuffMonitorAddon.frameHeight = 50
BuffMonitorAddon.defaultFrameWidth = 50
BuffMonitorAddon.defaultFrameHeight = 50
BuffMonitorAddon.stackCountFontSize = 25
BuffMonitorAddon.stackCountDefaultFontSize = 25
BuffMonitorAddon.stackCountFont = "Fonts\\FRIZQT__.TTF"
BuffMonitorAddon.frame = nil

----------------------------------------------------
-- Handling Command Line 
----------------------------------------------------

local function MyAddonCommands(msg, editbox)

    local args = {};
	for _, arg in ipairs({ string.split(' ', msg) }) do
		if (#arg > 0) then
			table.insert(args, arg);
		end
    end
    if args[1] == nil then
        print("|cff00cc66 [Single Buff Monitor] command examples: |r")
        print("|cff00cc66 show : |r /sbmonitor show")
        print("|cff00cc66 hide : |r /sbmonitor hide")
        print("|cff00cc66 resize : |r /sbmonitor resize 50 50")
    elseif args[1] == "show" then
        BuffMonitorAddon.showAddon()
    elseif args[1] == "hide" then
        BuffMonitorAddon.hideAddon()
    elseif args[1] == "resize" then
        BuffMonitorAddon.resizeAddon(tonumber(args[2]), tonumber(args[3]))
    else
        print("|cff00cc66 [Single Buff Monitor] command examples: |r")
        print("|cff00cc66 show : |r /sbmonitor show")
        print("|cff00cc66 hide : |r /sbmonitor hide")
        print("|cff00cc66 resize : |r /sbmonitor resize 50 50")
    end
end
SLASH_BUFFMONITOR1 = '/sbmonitor'
SlashCmdList["BUFFMONITOR"] = MyAddonCommands 

----------------------------------------------------
-- Detailed Commandline method implementation
----------------------------------------------------

function BuffMonitorAddon.resizeAddon(width, height)
    if (width ~= nil and width > 0) and (height ~= nil and height > 0)  then
        BuffMonitorAddon.frameWidth = width
        BuffMonitorAddon.frameHeight = height
    else
        BuffMonitorAddon.frameWidth = BuffMonitorAddon.defaultFrameWidth
        BuffMonitorAddon.frameHeight = BuffMonitorAddon.defaultFrameHeight
    end
    BuffMonitorAddon.frame:SetWidth(BuffMonitorAddon.frameWidth)
    BuffMonitorAddon.frame:SetHeight(BuffMonitorAddon.frameHeight)
    local newFontSize = (height/BuffMonitorAddon.defaultFrameHeight)*BuffMonitorAddon.stackCountDefaultFontSize
    BuffMonitorAddon.stackCountFontSize = newFontSize
end
function BuffMonitorAddon.showAddon()
    if BuffMonitorAddon.frame ~= nil then
        BuffMonitorAddon.frame:Show()
    end
end
function BuffMonitorAddon.hideAddon()
    if BuffMonitorAddon.frame ~= nil then
        BuffMonitorAddon.frame:Hide()
    end
end

local function initializeFrame()
    BuffMonitorAddon.frame = CreateFrame("Frame", "BuffmonitorFrame", UIParent)
    local frame = BuffMonitorAddon.frame
    local spell_name, _, spell_icon = GetSpellInfo(BuffMonitorAddon.spell_id)
    frame:SetWidth(BuffMonitorAddon.frameWidth)
    frame:SetHeight(BuffMonitorAddon.frameHeight)
    frame:SetPoint("CENTER", 0, 0)  -- @@@@@@@@@@@@@@  read new position from config.
    frame:RegisterEvent("PLAYER_ENTERING_WORLD")
    frame:RegisterEvent("PLAYER_REGEN_DISABLED")
    frame:RegisterEvent("PLAYER_REGEN_ENABLED")
    frame:SetScript("OnEvent",function(self,event,...)
        if event=="PLAYER_ENTERING_WORLD" then
            -- print("entering the world") works after reload
            self:SetAlpha(0.5)
            self.count:SetText("")
            self.cooldown:Hide()
        elseif event=="PLAYER_REGEN_DISABLED" then
            --print("entering in combat")
            self:SetAlpha(1)
            
        elseif event=="PLAYER_REGEN_ENABLED" then
            -- print("leaving combat")
            self:SetAlpha(0.5)
            self.count:SetText("")
            -- self.cooldown:Hide() no need to hide, as cooldown may still exist.
        end
    end)

    -- The minimum number of seconds between each update
    local ONUPDATE_INTERVAL = 0.1
    -- The number of seconds since the last update
    local TimeSinceLastUpdate = 0
    local current_stack_count = 0
    local cooldownStartTime = 0;
    local ex_expirationTime = 0;

    frame:SetScript("OnUpdate", function(self, elapsed)
        TimeSinceLastUpdate = TimeSinceLastUpdate + elapsed
        if TimeSinceLastUpdate >= ONUPDATE_INTERVAL then
            TimeSinceLastUpdate = 0
            for i=1, 40 do
                local bf_name, bf_icon, bf_count, bf_debuffType, bf_duration, bf_expirationTime, bf_caster, bf_canStealOrPurge, bf_nameplateShowPersonal, bf_spellId = UnitAura(BuffMonitorAddon.targetToMonitor,i)
                
                if (bf_name == spell_name) then
                    current_stack_count = bf_count
                    self.count:SetText(bf_count)
                    self.count:SetFont(BuffMonitorAddon.stackCountFont, BuffMonitorAddon.stackCountFontSize, "OUTLINE")
                    if (bf_duration) then
                        if(bf_duration>0) then
                            if bf_count ~= current_stack_count then
                                self.cooldown:Show()
                                cooldownStartTime = GetTime() -- start a new cooldown as new stack added
                                ex_expirationTime = bf_expirationTime
                                self.cooldown:SetCooldown(cooldownStartTime, bf_expirationTime-cooldownStartTime, 1)
                            elseif (bf_count == current_stack_count) and (bf_expirationTime-ex_expirationTime > 0) then
                                    self.cooldown:Show()
                                    cooldownStartTime = GetTime() -- start a new cooldown as new stack added
                                    ex_expirationTime = bf_expirationTime
                                    self.cooldown:SetCooldown(cooldownStartTime, bf_expirationTime-cooldownStartTime, 1)
                            end

                        else
                            self.cooldown:Hide()
                            isCoolDownRunning = false
                        end
                    end
                    break
                else
                    self.count:SetText("")
                end
            end
        end
    end)
    -- When the frame is shown, reset the update timer
    frame:SetScript("OnShow", function(self)
        TimeSinceLastUpdate = 0
    end)

    frame.icon = frame:CreateTexture("$parentIcon", "BACKGROUND")
    frame.icon:SetAllPoints(frame)
    frame.icon:SetTexture(spell_icon)
    frame.icon:SetTexCoord(0.07, 0.93, 0.07, 0.93)


    frame.count = frame:CreateFontString(nil, "OVERLAY")
    frame.count:SetFont(BuffMonitorAddon.stackCountFont, BuffMonitorAddon.stackCountDefaultFontSize, "OUTLINE")
    frame.count:SetTextColor(0, 1, 0)
    frame.count:SetPoint("BOTTOMRIGHT", -1, 1)
    frame.count:SetJustifyH("CENTER")

    frame.cooldown = CreateFrame("Cooldown", nil, frame, "CooldownFrameTemplate")
    frame.cooldown:SetReverse(true)
    frame.cooldown:SetAllPoints(frame.icon)
    frame:Show()
    frame:SetMovable(true)
    frame:EnableMouse(true)
    frame:RegisterForDrag("LeftButton", "RightButton")
    frame:SetScript("OnMouseDown", function(self,arg1)
        self:StartMoving()
    end)
    frame:SetScript("OnMouseUp", function(self,arg1)
        self:StopMovingOrSizing()
    end)
end

initializeFrame()
print("Welcome to use |cff00cc66 [Single Buff Monitor] |r")
print("|cff00cc66 show : |r /sbmonitor show")
print("|cff00cc66 hide : |r /sbmonitor hide")
print("|cff00cc66 resize : |r /sbmonitor resize 50 50")