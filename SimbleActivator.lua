

-- [ AutoUpdate ]

do
    
    local Version = 0.16
    
    local Files =
    {
        Lua =
        {
            Path = SCRIPT_PATH,
            Name = "SimbleActivator.lua",
            Url = "https://raw.githubusercontent.com/Pussykate/GoS/master/SimbleActivator.lua"
        },
        Version = {
            Path = SCRIPT_PATH,
            Name = "SimbleActivator.version",
            Url = "https://raw.githubusercontent.com/Pussykate/GoS/master/SimbleActivator.version"
        },
    }
    
    local function AutoUpdate()
        
        local function DownloadFile(url, path, fileName)
            DownloadFileAsync(url, path .. fileName, function() end)
            while not FileExist(path .. fileName) do end
        end
        
        local function ReadFile(path, fileName)
            local file = io.open(path .. fileName, "r")
            local result = file:read()
            file:close()
            return result
        end
        
        DownloadFile(Files.Version.Url, Files.Version.Path, Files.Version.Name)
        
        local NewVersion = tonumber(ReadFile(Files.Version.Path, Files.Version.Name))
        if NewVersion > Version then
            DownloadFile(Files.Lua.Url, Files.Lua.Path, Files.Lua.Name)
            print("New PussyActivator Version Press 2x F6")
        else
            print(Files.Version.Name .. ": No Updates Found")
        end
        
    end
    
    AutoUpdate()
    
end

class "Activator"

local menu = 1
local _OnWaypoint = {}
local _OnVision = {}
local Allies = {}; local Enemies = {}; local Turrets = {}; local Units = {}; local AllyHeroes = {}
local intToMode = {[0] = "", [1] = "Combo", [2] = "Harass", [3] = "LastHit", [4] = "Clear"}
local castSpell = {state = 0, tick = GetTickCount(), casting = GetTickCount() - 1000, mouse = mousePos}
local spellcast = {state = 1, mouse = mousePos}
local ItemHotKey = {[ITEM_1] = HK_ITEM_1, [ITEM_2] = HK_ITEM_2,[ITEM_3] = HK_ITEM_3, [ITEM_4] = HK_ITEM_4, [ITEM_5] = HK_ITEM_5, [ITEM_6] = HK_ITEM_6,}
local Orb

local myPotTicks = 0;
local myHealTicks = 0;
local myShieldTicks = 0;
local myAntiCCTicks = 0;

local hotkeyTable = {};
hotkeyTable[ITEM_1] = HK_ITEM_1;
hotkeyTable[ITEM_2] = HK_ITEM_2;
hotkeyTable[ITEM_3] = HK_ITEM_3;
hotkeyTable[ITEM_4] = HK_ITEM_4;
hotkeyTable[ITEM_5] = HK_ITEM_5;
hotkeyTable[ITEM_6] = HK_ITEM_6;
local InventoryTable = {};
local currentlyDrinkingPotion = false;
local HealthPotionSlot = 0;
local CookiePotionSlot = 0;
local RefillablePotSlot = 0;
local CorruptPotionSlot = 0;
local HuntersPotionSlot = 0;

function GetTarget(range) 
	local target = nil 
	if Orb == 1 then
		target = EOW:GetTarget(range)
	elseif Orb == 2 then 
		target = _G.SDK.TargetSelector:GetTarget(range)
	elseif Orb == 3 then
		target = GOS:GetTarget(range)
	elseif Orb == 4 then
		target = _G.gsoSDK.TS:GetTarget(range)		
	end
	return target 
end


function GetMode()
	if Orb == 1 then
		return intToMode[EOW.CurrentMode]
	elseif Orb == 2 then
		if _G.SDK.Orbwalker.Modes[_G.SDK.ORBWALKER_MODE_COMBO] then
			return "Combo"
		elseif _G.SDK.Orbwalker.Modes[_G.SDK.ORBWALKER_MODE_HARASS] then
			return "Harass"	
		elseif _G.SDK.Orbwalker.Modes[_G.SDK.ORBWALKER_MODE_LANECLEAR] or _G.SDK.Orbwalker.Modes[_G.SDK.ORBWALKER_MODE_JUNGLECLEAR] then
			return "Clear"
		elseif _G.SDK.Orbwalker.Modes[_G.SDK.ORBWALKER_MODE_LASTHIT] then
			return "LastHit"
		elseif _G.SDK.Orbwalker.Modes[_G.SDK.ORBWALKER_MODE_FLEE] then
			return "Flee"
		end
	elseif Orb == 4 then
		if _G.SDK.Orbwalker.Modes[_G.SDK.ORBWALKER_MODE_COMBO] then
			return "Combo"
		elseif _G.SDK.Orbwalker.Modes[_G.SDK.ORBWALKER_MODE_HARASS] then
			return "Harass"	
		elseif _G.SDK.Orbwalker.Modes[_G.SDK.ORBWALKER_MODE_LANECLEAR] or _G.SDK.Orbwalker.Modes[_G.SDK.ORBWALKER_MODE_JUNGLECLEAR] then
			return "Clear"
		elseif _G.SDK.Orbwalker.Modes[_G.SDK.ORBWALKER_MODE_LASTHIT] then
			return "LastHit"
		elseif _G.SDK.Orbwalker.Modes[_G.SDK.ORBWALKER_MODE_FLEE] then
			return "Flee"
		end			
	else
		return GOS.GetMode()
	end
end	

function GetAllyHeroes() 
	AllyHeroes = {}
	for i = 1, Game.HeroCount() do
		local Hero = Game.Hero(i)
		if Hero.isAlly and not Hero.isMe then
			table.insert(AllyHeroes, Hero)
		end
	end
	return AllyHeroes
end

function GetEnemyHeroes()
    local _EnemyHeroes = {}
    for i = 1, Game.HeroCount() do
        local unit = Game.Hero(i)
        if unit.isEnemy then
            table.insert(_EnemyHeroes, unit)
        end
    end
    return _EnemyHeroes
end

function GetDistanceSqr(p1, p2)
    if not p1 then return math.huge end
    p2 = p2 or myHero
    local dx = p1.x - p2.x
    local dz = (p1.z or p1.y) - (p2.z or p2.y)
    return dx * dx + dz * dz
end

function CastSpellMM(spell,pos,range,delay)
	local range = range or math.huge
	local delay = delay or 250
	local ticker = GetTickCount()
	if castSpell.state == 0 and GetDistanceSqr(myHero.pos,pos) < range and ticker - castSpell.casting > delay + Game.Latency then
		castSpell.state = 1
		castSpell.mouse = mousePos
		castSpell.tick = ticker
	end
	if castSpell.state == 1 then
		if ticker - castSpell.tick < Game.Latency then
			local castPosMM = pos:ToMM()
			Control.SetCursorPos(castPosMM.x,castPosMM.y)
			Control.KeyDown(spell)
			Control.KeyUp(spell)
			castSpell.casting = ticker + delay
			DelayAction(function()
				if castSpell.state == 1 then
					Control.SetCursorPos(castSpell.mouse)
					castSpell.state = 0
				end
			end,Game.Latency()/1000)
		end
		if ticker - castSpell.casting > Game.Latency then
			Control.SetCursorPos(castSpell.mouse)
			castSpell.state = 0
		end
	end
end

local function IsRecalling()
	for i = 1, 63 do
	local buff = myHero:GetBuff(i) 
		if buff.count > 0 and buff.name == "recall" and Game.Timer() < buff.expireTime then
			return true
		end
	end 
	return false
end

local function BaseCheck()
	for i = 1, Game.ObjectCount() do
		local base = Game.Object(i)
		if base.type == Obj_AI_SpawnPoint then
			if base.isAlly and myHero.pos:DistanceTo(base.pos) >= 800 then
				return true
			end
		end
	end	
	return false	
end	

local function MyHeroReady()
    return myHero.dead == false and Game.IsChatOpen() == false and BaseCheck() and (ExtLibEvade == nil or ExtLibEvade.Evading == false) and IsRecalling() == false
end

function Activator:__init()
    self:LoadMenu()
	self:OnLoad()
	Callback.Add("Tick", function() self:Tick() end)
	Callback.Add("Draw", function() self:OnDraw() end)
end



function Activator:LoadMenu()
    
    self.Menu = MenuElement({type = MENU, id = "Activator", leftIcon = "https://raw.githubusercontent.com/Pussykate/GoS/master/PageImage/ActivatorScriptLogo.png"})
    
	
	--Shield/Heal MyHero
    self.Menu:MenuElement({id = "ZS", name = "MyHero Shield+Heal Items", type = MENU})
    self.Menu.ZS:MenuElement({id = "self", name = "MyHero Shield+Heal Items", type = MENU})	

    self.Menu.ZS.self:MenuElement({id = "UseZ", name = "Zhonya's", value = true, leftIcon = "https://de.share-your-photo.com/img/76fbcec284.jpg"})
	self.Menu.ZS.self:MenuElement({id = "myHPZ", name = "[HP Setting]", value = 30, min = 0, max = 100, step = 1, identifier = "%"})

    self.Menu.ZS.self:MenuElement({id = "UseS", name = "Stopwatch", value = true, leftIcon = "https://vignette.wikia.nocookie.net/leagueoflegends/images/e/e6/Stopwatch_item.png"})
 	self.Menu.ZS.self:MenuElement({id = "myHPS", name = "[HP Setting]", value = 30, min = 0, max = 100, step = 1, identifier = "%"})   

	self.Menu.ZS.self:MenuElement({id = "Sera", name = "Seraphs Embrace", value = true, leftIcon = "http://ddragon.leagueoflegends.com/cdn/5.9.1/img/item/3040.png"})	
	self.Menu.ZS.self:MenuElement({id = "SeraHP", name = "[HP Setting]", value = 30, min = 0, max = 100, step = 1, identifier = "%"})

    self.Menu.ZS.self:MenuElement({id = "Edge", name = "Edge of Night", value = true, leftIcon = "https://vignette.wikia.nocookie.net/leagueoflegends/images/6/69/Edge_of_Night_item.png"})	
	self.Menu.ZS.self:MenuElement({id = "EdgeHP", name = "[HP Setting]", value = 30, min = 0, max = 100, step = 1, identifier = "%"})

    self.Menu.ZS.self:MenuElement({id = "Iron", name = "Locket of the Iron Solari", value = true, leftIcon = "http://ddragon.leagueoflegends.com/cdn/5.9.1/img/item/3190.png"})	
	self.Menu.ZS.self:MenuElement({id = "IronHP", name = "[HP Setting]", value = 30, min = 0, max = 100, step = 1, identifier = "%"})
	
    self.Menu.ZS.self:MenuElement({id = "Red", name = "Redemption", value = true, leftIcon = "https://vignette.wikia.nocookie.net/leagueoflegends/images/9/94/Redemption_item.png"})
	self.Menu.ZS.self:MenuElement({id = "RedHP", name = "[HP Setting]", value = 30, min = 0, max = 100, step = 1, identifier = "%"})	

	self.Menu.ZS.self:MenuElement({id = "Mira", name = "Mercurial Scimittar[AntiCC]", value = true, leftIcon = "http://ddragon.leagueoflegends.com/cdn/5.9.1/img/item/3139.png"})    
    self.Menu.ZS.self:MenuElement({id = "Quick", name = "Quicksilver Sash[AntiCC]", value = true, leftIcon = "http://ddragon.leagueoflegends.com/cdn/5.9.1/img/item/3140.png"})    
    self.Menu.ZS.self:MenuElement({id = "Mika", name = "Mikael's Crucible[AntiCC]", value = true, leftIcon = "http://ddragon.leagueoflegends.com/cdn/5.9.1/img/item/3222.png"})    
    self.Menu.ZS.self:MenuElement({id = "QSS", name = "AntiZed Ult", type = MENU})
    self.Menu.ZS.self.QSS:MenuElement({id = "UseSZ", name = "AutoUse Stopwatch or Zhonya on ZedUlt", value = true})	
------------------------------------------------------------------------------------------------------------------------------------------------------	
	--Shield/Heal Ally    
	
	self.Menu.ZS:MenuElement({id = "ally", name = "Ally Shield+Heal Items", type = MENU})
 
    self.Menu.ZS.ally:MenuElement({id = "Red", name = "Redemption", value = true, leftIcon = "https://vignette.wikia.nocookie.net/leagueoflegends/images/9/94/Redemption_item.png"})
	self.Menu.ZS.ally:MenuElement({id = "allyHP", name = "[AllyHP]", value = 30, min = 0, max = 100, step = 1, identifier = "%"}) 
 
	self.Menu.ZS.ally:MenuElement({id = "Iron", name = "Locket of the Iron Solari", value = true, leftIcon = "http://ddragon.leagueoflegends.com/cdn/5.9.1/img/item/3190.png"})	
	self.Menu.ZS.ally:MenuElement({id = "IronHP", name = "[AllyHP]", value = 30, min = 0, max = 100, step = 1, identifier = "%"})	
    
    self.Menu.ZS.ally:MenuElement({id = "Mika", name = "Mikael's Crucible[AntiCC]", value = true, leftIcon = "http://ddragon.leagueoflegends.com/cdn/5.9.1/img/item/3222.png"})    
-----------------------------------------------------------------------------------------------------------------------------------------------------------
	--Target Items

    self.Menu:MenuElement({id = "Dmg", name = "TargetItems[ComboMode]", type = MENU})
	
 	self.Menu.Dmg:MenuElement({id = "Spell", name = "Spellbinder", value = true, leftIcon = "https://vignette.wikia.nocookie.net/leagueoflegends/images/0/0f/Spellbinder_item.png"})    
	self.Menu.Dmg:MenuElement({id = "Tia", name = "Tiamat", value = true, leftIcon = "http://ddragon.leagueoflegends.com/cdn/5.9.1/img/item/3077.png"})    
    self.Menu.Dmg:MenuElement({id = "Rave", name = "Ravenous Hydra", value = true, leftIcon = "https://vignette.wikia.nocookie.net/leagueoflegends/images/e/e8/Ravenous_Hydra_item.png"})    
    self.Menu.Dmg:MenuElement({id = "Tita", name = "Titanic Hydra", value = true, leftIcon = "https://vignette.wikia.nocookie.net/leagueoflegends/images/2/22/Titanic_Hydra_item.png"})    
	self.Menu.Dmg:MenuElement({id = "Blade", name = "Blade of the Ruined King", value = true, leftIcon = "http://ddragon.leagueoflegends.com/cdn/5.9.1/img/item/3153.png"})
 	self.Menu.Dmg:MenuElement({id = "Bilg", name = "Bilgewater Cutlass", value = true, leftIcon = "http://ddragon.leagueoflegends.com/cdn/5.9.1/img/item/3144.png"})
 	self.Menu.Dmg:MenuElement({id = "Glp", name = "Hextech GLP-800", value = true, leftIcon = "https://vignette4.wikia.nocookie.net/leagueoflegends/images/c/c9/Hextech_GLP-800_item.png"})
 	self.Menu.Dmg:MenuElement({id = "Gun", name = "Hextech Gunblade", value = true, leftIcon = "https://vignette4.wikia.nocookie.net/leagueoflegends/images/6/64/Hextech_Gunblade_item.png"})
 	self.Menu.Dmg:MenuElement({id = "Proto", name = "Hextech Protobelt-01", value = true, leftIcon = "https://vignette2.wikia.nocookie.net/leagueoflegends/images/8/8d/Hextech_Protobelt-01_item.png"})
 	self.Menu.Dmg:MenuElement({id = "Omen", name = "Randuin's Omen", value = true, leftIcon = "https://vignette.wikia.nocookie.net/leagueoflegends/images/0/08/Randuin%27s_Omen_item.png"})	
 	self.Menu.Dmg:MenuElement({id = "Ocount", name = "Auto Randuin's Omen[Targets]", value = 3, min = 1, max = 5, step = 1})	
	self.Menu.Dmg:MenuElement({id = "Glory", name = "Righteous Glory", value = true, leftIcon = "http://ddragon.leagueoflegends.com/cdn/5.9.1/img/item/3800.png"})
 	self.Menu.Dmg:MenuElement({id = "Gcount", name = "Auto Righteous Glory[Targets]", value = 3, min = 1, max = 5, step = 1})	
 	self.Menu.Dmg:MenuElement({id = "Twin", name = "Twin Shadows", value = true, leftIcon = "https://vignette.wikia.nocookie.net/leagueoflegends/images/4/4b/Twin_Shadows_item.png"})
	self.Menu.Dmg:MenuElement({id = "minRange", name = "Twin Shadows[MinCastDistance]", value = 500, min = 100, max = 2000, step = 50})	
	self.Menu.Dmg:MenuElement({id = "maxRange", name = "Twin Shadows[MaxCastDistance]", value = 2500, min = 500, max = 4000, step = 50})


------------------------------------------------------------------------------------------------------------------------------------------------------------
    --Potions
    self.Menu:MenuElement({id = "Healing", name = "Potions", type = MENU})
    
	self.Menu.Healing:MenuElement({id = "Enabled", name = "Potions Enabled", value = true})
    self.Menu.Healing:MenuElement({id = "UsePots", name = "Health Potions", value = true, leftIcon = "http://puu.sh/rUYAW/7fe329aa43.png"})
    self.Menu.Healing:MenuElement({id = "UseCookies", name = "Biscuit", value = true, leftIcon = "http://puu.sh/rUZL0/201b970f16.png"})
    self.Menu.Healing:MenuElement({id = "UseRefill", name = "Refillable Potion", value = true, leftIcon = "http://puu.sh/rUZPt/da7fadf9d1.png"})
    self.Menu.Healing:MenuElement({id = "UseCorrupt", name = "Corrupting Potion", value = true, leftIcon = "http://puu.sh/rUZUu/130c59cdc7.png"})
    self.Menu.Healing:MenuElement({id = "UseHunters", name = "Hunter's Potion", value = true, leftIcon = "http://puu.sh/rUZZM/46b5036453.png"})
    self.Menu.Healing:MenuElement({id = "UsePotsPercent", name = "Use if health is below:", value = 50, min = 5, max = 95, identifier = "%"})
    
    --Summoners
    self.Menu:MenuElement({id = "summ", name = "Summoner Spells", type = MENU})
    self.Menu.summ:MenuElement({id = "heal", name = "SummonerHeal", type = MENU, leftIcon = "http://puu.sh/rXioi/2ac872033c.png"})
    self.Menu.summ.heal:MenuElement({id = "self", name = "Heal Self", value = true})
    self.Menu.summ.heal:MenuElement({id = "ally", name = "Heal Ally", value = true})
    self.Menu.summ.heal:MenuElement({id = "selfhp", name = "Self HP:", value = 30, min = 5, max = 95, identifier = "%"})
    self.Menu.summ.heal:MenuElement({id = "allyhp", name = "Ally HP:", value = 30, min = 5, max = 95, identifier = "%"})
    
    self.Menu.summ:MenuElement({id = "barr", name = "SummonerBarrier", type = MENU, leftIcon = "http://puu.sh/rXjQ1/af78cc6c34.png"})
    self.Menu.summ.barr:MenuElement({id = "self", name = "Use Barrier", value = true})
    self.Menu.summ.barr:MenuElement({id = "selfhp", name = "Self HP:", value = 30, min = 5, max = 95, identifier = "%"})
    
    self.Menu.summ:MenuElement({id = "ex", name = "SummonerExhaust", type = MENU, leftIcon = "http://ddragon.leagueoflegends.com/cdn/5.9.1/img/spell/SummonerExhaust.png"})
    self.Menu.summ.ex:MenuElement({id = "target", name = "Use Exhaust", value = true})
    self.Menu.summ.ex:MenuElement({id = "hp", name = "Target HP:", value = 30, min = 5, max = 95, identifier = "%"})
    
    self.Menu.summ:MenuElement({id = "clean", name = "SummonerCleanse", type = MENU, leftIcon = "http://puu.sh/rYrzP/5853206291.png"})
    self.Menu.summ.clean:MenuElement({id = "self", name = "Use Cleanse", value = true})
    
    self.Menu.summ:MenuElement({id = "ign", name = "SummonerIgnite", type = MENU, leftIcon = "http://ddragon.leagueoflegends.com/cdn/5.9.1/img/spell/SummonerDot.png"})
 	self.Menu.summ.ign:MenuElement({id = "ST", name = "TargetHP or KillSteal", drop = {"TargetHP", "KillSteal"}, value = 1})   
    self.Menu.summ.ign:MenuElement({id = "hp", name = "TargetHP:", value = 30, min = 5, max = 95, identifier = "%"})
	
    self.Menu.summ:MenuElement({id = "SmiteMenu", name = "SummonerSmite", type = MENU, leftIcon = "http://puu.sh/rPsnZ/a05d0f19a8.png"})
	self.Menu.summ.SmiteMenu:MenuElement({id = "Enabled", name = "Enabled[OfficialSmiteManager]", value = true})
	
	self.Menu.summ.SmiteMenu:MenuElement({type = MENU, id = "SmiteMarker", name = "Smite Marker Minions"})
	self.Menu.summ.SmiteMenu.SmiteMarker:MenuElement({id = "Enabled", name = "Enabled", value = true})
	self.Menu.summ.SmiteMenu.SmiteMarker:MenuElement({id = "MarkBaron", name = "Mark Baron", value = true, leftIcon = "http://puu.sh/rPuVv/933a78e350.png"})
	self.Menu.summ.SmiteMenu.SmiteMarker:MenuElement({id = "MarkHerald", name = "Mark Herald", value = true, leftIcon = "http://puu.sh/rQs4A/47c27fa9ea.png"})
	self.Menu.summ.SmiteMenu.SmiteMarker:MenuElement({id = "MarkDragon", name = "Mark Dragon", value = true, leftIcon = "http://puu.sh/rPvdF/a00d754b30.png"})
	self.Menu.summ.SmiteMenu.SmiteMarker:MenuElement({id = "MarkBlue", name = "Mark Blue Buff", value = true, leftIcon = "http://puu.sh/rPvNd/f5c6cfb97c.png"})
	self.Menu.summ.SmiteMenu.SmiteMarker:MenuElement({id = "MarkRed", name = "Mark Red Buff", value = true, leftIcon = "http://puu.sh/rPvQs/fbfc120d17.png"})
	self.Menu.summ.SmiteMenu.SmiteMarker:MenuElement({id = "MarkGromp", name = "Mark Gromp", value = true, leftIcon = "http://puu.sh/rPvSY/2cf9ff7a8e.png"})
	self.Menu.summ.SmiteMenu.SmiteMarker:MenuElement({id = "MarkWolves", name = "Mark Wolves", value = true, leftIcon = "http://puu.sh/rPvWu/d9ae64a105.png"})
	self.Menu.summ.SmiteMenu.SmiteMarker:MenuElement({id = "MarkRazorbeaks", name = "Mark Razorbeaks", value = true, leftIcon = "http://puu.sh/rPvZ5/acf0e03cc7.png"})
	self.Menu.summ.SmiteMenu.SmiteMarker:MenuElement({id = "MarkKrugs", name = "Mark Krugs", value = true, leftIcon = "http://puu.sh/rPw6a/3096646ec4.png"})
	self.Menu.summ.SmiteMenu.SmiteMarker:MenuElement({id = "MarkCrab", name = "Mark Crab", value = true, leftIcon = "http://puu.sh/rPwaw/10f0766f4d.png"})
	
	self.Menu.summ.SmiteMenu:MenuElement({type = MENU, id = "AutoSmiter", name = "Auto Smite Minions"})
	self.Menu.summ.SmiteMenu.AutoSmiter:MenuElement({id = "Enabled", name = "Toggle Enable Key", key = string.byte("M"), toggle = true})
	self.Menu.summ.SmiteMenu.AutoSmiter:MenuElement({id = "DrawSTS", name = "Draw Smite Toggle State", value = true})
	
	self.Menu.summ.SmiteMenu.AutoSmiter:MenuElement({id = "SmiteBaron", name = "Smite Baron", value = true, leftIcon = "http://puu.sh/rPuVv/933a78e350.png"})
	self.Menu.summ.SmiteMenu.AutoSmiter:MenuElement({id = "SmiteHerald", name = "Smite Herald", value = true, leftIcon = "http://puu.sh/rQs4A/47c27fa9ea.png"})
	self.Menu.summ.SmiteMenu.AutoSmiter:MenuElement({id = "SmiteDragon", name = "Smite Dragon", value = true, leftIcon = "http://puu.sh/rPvdF/a00d754b30.png"})
	self.Menu.summ.SmiteMenu.AutoSmiter:MenuElement({id = "SmiteBlue", name = "Smite Blue Buff", value = true, leftIcon = "http://puu.sh/rPvNd/f5c6cfb97c.png"})
	self.Menu.summ.SmiteMenu.AutoSmiter:MenuElement({id = "SmiteRed", name = "Smite Red Buff", value = true, leftIcon = "http://puu.sh/rPvQs/fbfc120d17.png"})
	self.Menu.summ.SmiteMenu.AutoSmiter:MenuElement({id = "SmiteGromp", name = "Smite Gromp", value = false, leftIcon = "http://puu.sh/rPvSY/2cf9ff7a8e.png"})
	self.Menu.summ.SmiteMenu.AutoSmiter:MenuElement({id = "SmiteWolves", name = "Smite Wolves", value = false, leftIcon = "http://puu.sh/rPvWu/d9ae64a105.png"})
	self.Menu.summ.SmiteMenu.AutoSmiter:MenuElement({id = "SmiteRazorbeaks", name = "Smite Razorbeaks", value = false, leftIcon = "http://puu.sh/rPvZ5/acf0e03cc7.png"})
	self.Menu.summ.SmiteMenu.AutoSmiter:MenuElement({id = "SmiteKrugs", name = "Smite Krugs", value = false, leftIcon = "http://puu.sh/rPw6a/3096646ec4.png"})
	self.Menu.summ.SmiteMenu.AutoSmiter:MenuElement({id = "SmiteCrab", name = "Smite Crab", value = false, leftIcon = "http://puu.sh/rPwaw/10f0766f4d.png"})
	
	self.Menu.summ.SmiteMenu:MenuElement({type = MENU, id = "AutoSmiterH", name = "Auto Smite Heroes"})	
	self.Menu.summ.SmiteMenu.AutoSmiterH:MenuElement({id = "Enabled", name = "Smite Logic", value = 2, drop = {"AutoSmite Always", "AutoSmite KillSteal"}})
end
	


function Activator:Tick()
  
	self:Auto()
	self:MyHero()
    self:Ally()
    self:Summoner()
	self:Ignite()
	self:Pots()
	self:Smite()
	local Mode = GetMode()
	if Mode == "Combo" then
	self:Target()
	end

end

local MarkTable = {
	SRU_Baron = "MarkBaron",
	SRU_RiftHerald = "MarkHerald",
	SRU_Dragon_Water = "MarkDragon",
	SRU_Dragon_Fire = "MarkDragon",
	SRU_Dragon_Earth = "MarkDragon",
	SRU_Dragon_Air = "MarkDragon",
	SRU_Dragon_Elder = "MarkDragon",
	SRU_Blue = "MarkBlue",
	SRU_Red = "MarkRed",
	SRU_Gromp = "MarkGromp",
	SRU_Murkwolf = "MarkWolves",
	SRU_Razorbeak = "MarkRazorbeaks",
	SRU_Krug = "MarkKrugs",
	Sru_Crab = "MarkCrab",
}

local SmiteTable = {
	SRU_Baron = "SmiteBaron",
	SRU_RiftHerald = "SmiteHerald",
	SRU_Dragon_Water = "SmiteDragon",
	SRU_Dragon_Fire = "SmiteDragon",
	SRU_Dragon_Earth = "SmiteDragon",
	SRU_Dragon_Air = "SmiteDragon",
	SRU_Dragon_Elder = "SmiteDragon",
	SRU_Blue = "SmiteBlue",
	SRU_Red = "SmiteRed",
	SRU_Gromp = "SmiteGromp",
	SRU_Murkwolf = "SmiteWolves",
	SRU_Razorbeak = "SmiteRazorbeaks",
	SRU_Krug = "SmiteKrugs",
	Sru_Crab = "SmiteCrab",
}

local SmiteNames = {'SummonerSmite','S5_SummonerSmiteDuel','S5_SummonerSmitePlayerGanker','S5_SummonerSmiteQuick','ItemSmiteAoE'};
local SmiteDamage = {390 , 410 , 430 , 450 , 480 , 510 , 540 , 570 , 600 , 640 , 680 , 720 , 760 , 800 , 850 , 900 , 950 , 1000};
local mySmiteSlot = 0;

function Ready(spell)
    return Game.CanUseSpell(spell) == 0
end

function Activator:GetSmite(smiteSlot)
	local returnVal = 0;
	local spellName = myHero:GetSpellData(smiteSlot).name;
	for i = 1, 5 do
		if spellName == SmiteNames[i] then
			returnVal = smiteSlot
		end
	end
	return returnVal;
end



function Activator:OnLoad()
	mySmiteSlot = self:GetSmite(SUMMONER_1);
	if mySmiteSlot == 0 then
		mySmiteSlot = self:GetSmite(SUMMONER_2);
	end
end

function Activator:DrawSmiteableMinion(type,minion)
	if not type or not self.Menu.summ.SmiteMenu.SmiteMarker[type] then
		return
	end
	if self.Menu.summ.SmiteMenu.SmiteMarker[type]:Value() then
		if minion.pos2D.onScreen then
			Draw.Circle(minion.pos,minion.boundingRadius,6,Draw.Color(0xFF00FF00));
		end
	end
end

function Activator:AutoSmiteMinion(type,minion)
	if not type or not self.Menu.summ.SmiteMenu.AutoSmiter[type] then
		return
	end
	if self.Menu.summ.SmiteMenu.AutoSmiter[type]:Value() then
		if minion.pos2D.onScreen then
			if mySmiteSlot == SUMMONER_1 then
				Control.CastSpell(HK_SUMMONER_1,minion)
			else
				Control.CastSpell(HK_SUMMONER_2,minion)
			end
		end
	end
end

function Activator:Smite()
if mySmiteSlot == 0 then return end	
	if self.Menu.summ.SmiteMenu.SmiteMarker.Enabled:Value() or self.Menu.summ.SmiteMenu.AutoSmiter.Enabled:Value() then 
		local SData = myHero:GetSpellData(mySmiteSlot);
		for i = 1, Game.MinionCount() do
			minion = Game.Minion(i);
			if minion and minion.valid and (minion.team == 300) and minion.visible then
				if minion.health <= SmiteDamage[myHero.levelData.lvl] then
					local minionName = minion.charName;
					if self.Menu.summ.SmiteMenu.SmiteMarker.Enabled:Value() then
						self:DrawSmiteableMinion(MarkTable[minionName], minion);
					end
					if self.Menu.summ.SmiteMenu.AutoSmiter.Enabled:Value() then
						if mySmiteSlot > 0 then
							if SData.level > 0 then
								if (SData.ammo > 0) then
									if minion.distance <= (500+myHero.boundingRadius+minion.boundingRadius) then
										self:AutoSmiteMinion(SmiteTable[minionName], minion);
									end
								end
							end
						end
					end
				end
			end
		end
	end 		
for i, target in pairs(GetEnemyHeroes()) do
	if target == nil then return end	
	
		
	local smiteDmg = 20+8*myHero.levelData.lvl;
	local SData = myHero:GetSpellData(mySmiteSlot);
	
	if IsValid(target,800) and SData.name == "S5_SummonerSmiteDuel" or SData.name == "S5_SummonerSmitePlayerGanker" then	
		
		if self.Menu.summ.SmiteMenu.AutoSmiterH.Enabled:Value() == 2 then
			if SData.level > 0 then
				if (SData.ammo > 0) then

					if (target.distance <= (500+myHero.boundingRadius+target.boundingRadius)) and target.health <= smiteDmg then
						if mySmiteSlot == SUMMONER_1 and Ready(SUMMONER_1) then
							Control.CastSpell(HK_SUMMONER_1,target)
						end	
						if mySmiteSlot == SUMMONER_2 and Ready(SUMMONER_2) then
							Control.CastSpell(HK_SUMMONER_2,target)
						end
					end
				end
			end
		end
	
		
		

		if self.Menu.summ.SmiteMenu.AutoSmiterH.Enabled:Value() == 1 then
			if SData.level > 0 then
				if (SData.ammo > 0) then

					if (target.distance <= (500+myHero.boundingRadius+target.boundingRadius)) then
						if mySmiteSlot == SUMMONER_1 and Ready(SUMMONER_1) then
							Control.CastSpell(HK_SUMMONER_1,target)
						end	
						if mySmiteSlot == SUMMONER_2 and Ready(SUMMONER_2) then
							Control.CastSpell(HK_SUMMONER_2,target)
						end
					end
				end
			end
		end
	end
end	
end	



function Activator:OnDraw()
if myHero.alive == false then return end
	if self.Menu.summ.SmiteMenu.Enabled:Value() and (mySmiteSlot > 0) then
		if self.Menu.summ.SmiteMenu.AutoSmiter.DrawSTS:Value() then
			local myKey = self.Menu.summ.SmiteMenu.AutoSmiter.Enabled:Key();
			if self.Menu.summ.SmiteMenu.AutoSmiter.Enabled:Value() then
				if myKey > 0 then Draw.Text("Smite On ".."["..string.char(self.Menu.summ.SmiteMenu.AutoSmiter.Enabled:Key()).."]",18,myHero.pos2D.x-70,myHero.pos2D.y+70,Draw.Color(255, 30, 230, 30)) end;
				else
				if myKey > 0 then Draw.Text("Smite Off ".."["..string.char(self.Menu.summ.SmiteMenu.AutoSmiter.Enabled:Key()).."]",18,myHero.pos2D.x-70,myHero.pos2D.y+70,Draw.Color(255, 230, 30, 30)) end;
				end
			end
	
	end
end

local CleanBuffs =
{
    [5] = true,
    [7] = true,
    [8] = true,
    [21] = true,
    [22] = true,
    [25] = true,
    [10] = true,
    [31] = true,
    [24] = true,
}
function Cleans(unit)
    for i = 0, unit.buffCount do
        local buff = unit:GetBuff(i)
        if buff then
            local bCount = buff.count;
            local bType = buff.type;
            if (bCount and bType and bCount > 0 and CleanBuffs[bType]) then
                return true
            end
        end
    end
    return false
end

function IsValid(unit)
    if (unit and unit.valid and unit.isTargetable and unit.alive and unit.visible and unit.networkID and unit.pathing and unit.health > 0) then
        return true;
    end
    return false;
end

function GetInventorySlotItem(itemID)
    assert(type(itemID) == "number", "GetInventorySlotItem: wrong argument types (<number> expected)")
    for _, j in pairs({ITEM_1, ITEM_2, ITEM_3, ITEM_4, ITEM_5, ITEM_6}) do
        if myHero:GetItemData(j).itemID == itemID and myHero:GetSpellData(j).currentCd == 0 then return j end
    end
    return nil
end

function HasBuff(unit, buffName)
    for i = 0, unit.buffCount do
        local buff = unit:GetBuff(i)
        if buff ~= nil and buff.count > 0 then
            if buff.name == buffName then
                local CurrentTime = Game.Timer()
                if buff.startTime <= CurrentTime + 0.1 and buff.expireTime >= CurrentTime then
                    return true
                end
            end
        end
    end
    return false
end

function Activator:EnemiesAround(pos, range)
    local pos = pos.pos
    local N = 0
    for i = 1, Game.HeroCount() do
        local hero = Game.Hero(i)
        if (IsValid(hero) and hero.team ~= TEAM_ALLY and GetDistanceSqr(pos, hero.pos) < range * range) then
            N = N + 1
        end
    end
    return N
end

function myGetSlot(itemID)
local retval = 0;
for i = ITEM_1, ITEM_6 do
	if InventoryTable[i] ~= nil then
		if InventoryTable[i].itemID == itemID then
			if (itemID > 2030) and (itemID < 2034) then --potion solution
				if InventoryTable[i].ammo > 0 then
					retval = i;
					break;
					end
				else
				retval = i;
				break;
				end
			end
		end
	end
return retval
end

function Activator:Auto()
if myHero.dead then return end
for i, target in pairs(GetEnemyHeroes()) do	
local Omen, Glory = GetInventorySlotItem(3143), GetInventorySlotItem(3800)   	
	if IsValid(target) then		
		if Omen and self.Menu.Dmg.Omen:Value() and self:EnemiesAround(myHero, 500) >= self.Menu.Dmg.Ocount:Value() and myHero.pos:DistanceTo(target.pos) <= 450 then
            Control.CastSpell(ItemHotKey[Omen])
        end	

		if Glory and self.Menu.Dmg.Glory:Value() and myHero.pos:DistanceTo(target.pos) <= 250 and self:EnemiesAround(myHero, 450) >= self.Menu.Dmg.Gcount:Value() then
            Control.CastSpell(ItemHotKey[Glory])
        end
	end
end
end	


-- MyHero Items ---------------

function Activator:MyHero()
if myHero.dead then return end
local Zo, St, Se, Ed, Mi, Qu, Mik, Iro, Re = GetInventorySlotItem(3157), GetInventorySlotItem(2420), GetInventorySlotItem(3040), GetInventorySlotItem(3814), GetInventorySlotItem(3139), GetInventorySlotItem(3140), GetInventorySlotItem(3222), GetInventorySlotItem(3190), GetInventorySlotItem(3107)   
	if self:EnemiesAround(myHero.pos, 1000) then
        
		if Zo and self.Menu.ZS.self.UseZ:Value() and myHero.health/myHero.maxHealth < self.Menu.ZS.self.myHPZ:Value()/100 then
            Control.CastSpell(ItemHotKey[Zo])
        end
    
		if St and self.Menu.ZS.self.UseS:Value() and myHero.health/myHero.maxHealth < self.Menu.ZS.self.myHPS:Value()/100 then
            Control.CastSpell(ItemHotKey[St])
        end
		
		if Se and self.Menu.ZS.self.Sera:Value() and myHero.health/myHero.maxHealth < self.Menu.ZS.self.SeraHP:Value()/100 then
            Control.CastSpell(ItemHotKey[Se])
        end	

		if Ed and self.Menu.ZS.self.Edge:Value() and myHero.health/myHero.maxHealth < self.Menu.ZS.self.EdgeHP:Value()/100 then
            Control.CastSpell(ItemHotKey[Ed])
        end

		if Iro and self.Menu.ZS.self.Iron:Value() and myHero.health/myHero.maxHealth < self.Menu.ZS.self.IronHP:Value()/100 then
            Control.CastSpell(ItemHotKey[Iro])
        end	

		if Re and self.Menu.ZS.self.Red:Value() and myHero.health/myHero.maxHealth < self.Menu.ZS.self.RedHP:Value()/100 then
            Control.CastSpell(ItemHotKey[Re], myHero.pos)
        end			
    end
	
	local Immobile = Cleans(myHero)

	if Immobile then
		
		if Mi and self.Menu.ZS.self.Mira:Value() then
            Control.CastSpell(ItemHotKey[Mi])
        end
		
		if Qu and self.Menu.ZS.self.Quick:Value() then
            Control.CastSpell(ItemHotKey[Qu])
        end

		if Mik and self.Menu.ZS.self.Mika:Value() then
            Control.CastSpell(ItemHotKey[Mik], myHero)
        end		
	end
end

function Activator:QSS()
    if myHero.dead then return end
    local hasBuff = HasBuff(myHero, "zedrdeathmark")
    local S, Z = GetInventorySlotItem(2420), GetInventorySlotItem(3157)
    if self.Menu.ZS.self.QSS.UseSZ:Value() and hasBuff then
        if S then
			Control.CastSpell(ItemHotKey[S])
		end	
		if Z then
			Control.CastSpell(ItemHotKey[Z])
		end	
    end
end

-- Ally Items ---------------

function Activator:Ally()
if myHero.dead then return end
local Mik, Iro, Re = GetInventorySlotItem(3222), GetInventorySlotItem(3190), GetInventorySlotItem(3107)   
	
	for i, ally in pairs(GetAllyHeroes()) do
	local Immobile = Cleans(ally)
		if Iro and self.Menu.ZS.ally.Iron:Value() and ally.health/ally.maxHealth < self.Menu.ZS.ally.IronHP:Value()/100 and myHero.pos:DistanceTo(ally.pos) <= 600 and not ally.dead then
            Control.CastSpell(ItemHotKey[Iro])
        end	

		if Re and self.Menu.ZS.ally.Red:Value() and ally.health/ally.maxHealth < self.Menu.ZS.ally.allyHP:Value()/100 then
            
			if ally.pos:To2D().onScreen then						
				Control.CastSpell(ItemHotKey[Re], ally.pos) 
				
			elseif not ally.pos:To2D().onScreen then			
				CastSpellMM(ItemHotKey[Re], ally.pos, 5500, 300)
			end
        end			

		if myHero.pos:DistanceTo(ally.pos) <= 600 and not ally.dead and Immobile then
			if Mik and self.Menu.ZS.ally.Mika:Value() then
				Control.CastSpell(ItemHotKey[Mik], ally)
			end	
        end		
	end
end

-- Target Items -----------------------------

function Activator:Target()
if myHero.dead then return end
for i, target in pairs(GetEnemyHeroes()) do	
local Tia, Rave, Tita, Blade, Bilg, Glp, Gun, Proto, Omen, Glory, Twin, Spell = GetInventorySlotItem(3077), GetInventorySlotItem(3074), GetInventorySlotItem(3748), GetInventorySlotItem(3153), GetInventorySlotItem(3144), GetInventorySlotItem(3030), GetInventorySlotItem(3146), GetInventorySlotItem(3152), GetInventorySlotItem(3143), GetInventorySlotItem(3800), GetInventorySlotItem(3905), GetInventorySlotItem(3907)   
	if IsValid(target) then
        
		if Tia and self.Menu.Dmg.Tia:Value() and myHero.pos:DistanceTo(target.pos) <= 400 then
            Control.CastSpell(ItemHotKey[Tia])
        end
		
		if Rave and self.Menu.Dmg.Rave:Value() and myHero.pos:DistanceTo(target.pos) <= 400 then
            Control.CastSpell(ItemHotKey[Rave])
        end
		
		if Tita and self.Menu.Dmg.Tita:Value() and myHero.pos:DistanceTo(target.pos) <= 400 then
            Control.CastSpell(ItemHotKey[Tita])
        end
		
		if Blade and self.Menu.Dmg.Blade:Value() and myHero.pos:DistanceTo(target.pos) <= 550 then
            Control.CastSpell(ItemHotKey[Blade])
        end
		
		if Bilg and self.Menu.Dmg.Bilg:Value() and myHero.pos:DistanceTo(target.pos) <= 550 then
            Control.CastSpell(ItemHotKey[Bilg])
        end	

		if Glp and self.Menu.Dmg.Glp:Value() and myHero.pos:DistanceTo(target.pos) <= 800 then
            Control.CastSpell(ItemHotKey[Glp], target.pos)
        end	

		if Gun and self.Menu.Dmg.Gun:Value() and myHero.pos:DistanceTo(target.pos) <= 700 then
            Control.CastSpell(ItemHotKey[Gun], target.pos)
        end

		if Proto and self.Menu.Dmg.Proto:Value() and myHero.pos:DistanceTo(target.pos) <= 800 then
            Control.CastSpell(ItemHotKey[Proto], target.pos)
        end	

		if Omen and self.Menu.Dmg.Omen:Value() and myHero.pos:DistanceTo(target.pos) <= 500 then
            Control.CastSpell(ItemHotKey[Omen])
        end	

		if Glory and self.Menu.Dmg.Glory:Value() and myHero.pos:DistanceTo(target.pos) <= 450 then
            Control.CastSpell(ItemHotKey[Glory])
        end	

		if Twin and self.Menu.Dmg.Twin:Value() and myHero.pos:DistanceTo(target.pos) <= self.Menu.Dmg.maxRange:Value() and myHero.pos:DistanceTo(target.pos) >= self.Menu.Dmg.minRange:Value() then
            Control.CastSpell(ItemHotKey[Twin])
        end	

		if Spell and self.Menu.Dmg.Spell:Value() and myHero.pos:DistanceTo(target.pos) <= 600 then
            Control.CastSpell(ItemHotKey[Spell])
        end		
    end
end
end





-- Potions ---------------------

function Activator:Pots()
if myHero.alive == false then return end 

hotkeyTable[ITEM_1] = HK_ITEM_1;
hotkeyTable[ITEM_2] = HK_ITEM_2;
hotkeyTable[ITEM_3] = HK_ITEM_3;
hotkeyTable[ITEM_4] = HK_ITEM_4;
hotkeyTable[ITEM_5] = HK_ITEM_5;
hotkeyTable[ITEM_6] = HK_ITEM_6;

if (myPotTicks + 1000 < GetTickCount()) and self.Menu.Healing.Enabled:Value() then
	local myPotTicks = GetTickCount();
	currentlyDrinkingPotion = false;
	for j = ITEM_1, ITEM_6 do
		InventoryTable[j] = myHero:GetItemData(j);
	end
	local HealthPotionSlot = GetInventorySlotItem(2003);
	local CookiePotionSlot = GetInventorySlotItem(2010);
	local RefillablePotSlot = GetInventorySlotItem(2031);
	local HuntersPotionSlot = GetInventorySlotItem(2032);
	local CorruptPotionSlot = GetInventorySlotItem(2033);

	for i = 0, 63 do
		local buffData = myHero:GetBuff(i);
		if buffData.count > 0 then
			if (buffData.type == 13) or (buffData.type == 26) then 
				if (buffData.name == "ItemDarkCrystalFlask") or (buffData.name == "ItemCrystalFlaskJungle") or (buffData.name == "ItemCrystalFlask") or (buffData.name == "ItemMiniRegenPotion") or (buffData.name == "RegenerationPotion") then
					currentlyDrinkingPotion = true;
					break;
				end
			end
		end
	end	
	if (currentlyDrinkingPotion == false) and myHero.health/myHero.maxHealth <= self.Menu.Healing.UsePotsPercent:Value()/100 and MyHeroReady() then
		if HealthPotionSlot and self.Menu.Healing.UsePots:Value() then
			Control.CastSpell(ItemHotKey[HealthPotionSlot])
		end
		if CookiePotionSlot and self.Menu.Healing.UseCookies:Value() then
			Control.CastSpell(ItemHotKey[CookiePotionSlot])
		end
		if RefillablePotSlot and self.Menu.Healing.UseRefill:Value() then
			Control.CastSpell(ItemHotKey[RefillablePotSlot])
		end
		if CorruptPotionSlot and self.Menu.Healing.UseCorrupt:Value() then
			Control.CastSpell(ItemHotKey[CorruptPotionSlot])
		end
		if HuntersPotionSlot and self.Menu.Healing.UseHunters:Value() then
			Control.CastSpell(ItemHotKey[HuntersPotionSlot])
		end
	end
end
end

--Summoners-------------------------

function Activator:Summoner()
if myHero.dead then return end
for i, target in pairs(GetEnemyHeroes()) do
    local MyHp = myHero.health/myHero.maxHealth

    
    if IsValid(target) then
        if self.Menu.summ.heal.self:Value() and MyHp <= self.Menu.summ.heal.selfhp:Value()/100 then
            if myHero:GetSpellData(SUMMONER_1).name == "SummonerHeal" and Ready(SUMMONER_1) then
                Control.CastSpell(HK_SUMMONER_1, myHero)
            elseif myHero:GetSpellData(SUMMONER_2).name == "SummonerHeal" and Ready(SUMMONER_2) then
                Control.CastSpell(HK_SUMMONER_2, myHero)
            end
        end
        for i, ally in pairs(GetAllyHeroes()) do
            local AllyHp = ally.health/ally.maxHealth
            if self.Menu.summ.heal.ally:Value() and AllyHp <= self.Menu.summ.heal.allyhp:Value()/100 then
                if IsValid(ally) and myHero.pos:DistanceTo(ally.pos) <= 850 and not ally.dead then
                    if myHero:GetSpellData(SUMMONER_1).name == "SummonerHeal" and Ready(SUMMONER_1) then
                        Control.CastSpell(HK_SUMMONER_1, ally)
                    elseif myHero:GetSpellData(SUMMONER_2).name == "SummonerHeal" and Ready(SUMMONER_2) then
                        Control.CastSpell(HK_SUMMONER_2, ally)
                    end
                end
            end
        end
        if self.Menu.summ.barr.self:Value() and MyHp <= self.Menu.summ.barr.selfhp:Value()/100 then
            if myHero:GetSpellData(SUMMONER_1).name == "SummonerBarrier" and Ready(SUMMONER_1) then
                Control.CastSpell(HK_SUMMONER_1, myHero)
            elseif myHero:GetSpellData(SUMMONER_2).name == "SummonerBarrier" and Ready(SUMMONER_2) then
                Control.CastSpell(HK_SUMMONER_2, myHero)
            end
        end
        local Immobile = Cleans(myHero)
        if self.Menu.summ.clean.self:Value() and Immobile then
            if myHero:GetSpellData(SUMMONER_1).name == "SummonerBoost" and Ready(SUMMONER_1) then
                Control.CastSpell(HK_SUMMONER_1, myHero)
            elseif myHero:GetSpellData(SUMMONER_2).name == "SummonerBoost" and Ready(SUMMONER_2) then
                Control.CastSpell(HK_SUMMONER_2, myHero)
            end
        end
        local TargetHp = target.health/target.maxHealth
        if self.Menu.summ.ex.target:Value() then
            if myHero.pos:DistanceTo(target.pos) <= 650 and TargetHp <= self.Menu.summ.ex.hp:Value()/100 then
                if myHero:GetSpellData(SUMMONER_1).name == "SummonerExhaust" and Ready(SUMMONER_1) then
                    Control.CastSpell(HK_SUMMONER_1, target)
                elseif myHero:GetSpellData(SUMMONER_2).name == "SummonerExhaust" and Ready(SUMMONER_2) then
                    Control.CastSpell(HK_SUMMONER_2, target)
                end
            end
        end
	end
end
end	
		
function Activator:Ignite()		
if myHero.dead then return end
for i, target in pairs(GetEnemyHeroes()) do	
	if IsValid(target) then	
		local TargetHp = target.health/target.maxHealth
        if self.Menu.summ.ign.ST:Value() == 1 then
			if TargetHp <= self.Menu.summ.ign.hp:Value()/100 and myHero.pos:DistanceTo(target.pos) <= 600 then
                if myHero:GetSpellData(SUMMONER_1).name == "SummonerDot" and Ready(SUMMONER_1) then
                    Control.CastSpell(HK_SUMMONER_1, target)
                elseif myHero:GetSpellData(SUMMONER_2).name == "SummonerDot" and Ready(SUMMONER_2) then
                    Control.CastSpell(HK_SUMMONER_2, target)
                end
            end
        elseif self.Menu.summ.ign.ST:Value() == 2 then       
			local IGdamage = 50 + 20 * myHero.levelData.lvl
			if myHero.pos:DistanceTo(target.pos) <= 600 and target.health  <= IGdamage then
                if myHero:GetSpellData(SUMMONER_1).name == "SummonerDot" and Ready(SUMMONER_1) then
                    Control.CastSpell(HK_SUMMONER_1, target)
                elseif myHero:GetSpellData(SUMMONER_2).name == "SummonerDot" and Ready(SUMMONER_2) then
                    Control.CastSpell(HK_SUMMONER_2, target)
                end
            end
        end		
	end
end	
end
	
function OnLoad()
	Activator()
end	
