AddCSLuaFile()

if SERVER and not file.Exists('weapons/lightning_caller.lua', 'lsv') then
	Error('Please install Lightning Caller addon from https://steamcommunity.com/sharedfiles/filedetails/?id=3041749826')
end

-- Resource Caching

if SERVER then
	resource.AddFile('materials/vgui/ttt/icon_ttt_smite.png')
	resource.AddFile('materials/vgui/ttt/hud_ttt_smite.png')
	resource.AddFile('materials/vgui/entities/weapon_ttt_smite.vmt')
	resource.AddFile('materials/hud/killicons/weapon_ttt_smite.vmt')

	resource.AddFile('sound/ttt_smite/ttt_smite_explode.wav')
	resource.AddFile('sound/ttt_smite/ttt_smite_thunder.wav')
	resource.AddFile('sound/ttt_smite/ttt_smite_speech.wav')

	resource.AddFile('models/weapons/c_wizardry_caller.mdl')
end

sound.Add({
	name = 'ttt_smite_speech',
	sound = Sound('ttt_smite/ttt_smite_speech.wav')
})

sound.Add({
	name = 'ttt_smite_explode',
	sound = Sound('ttt_smite/ttt_smite_explode.wav')
})

sound.Add({
	name = 'ttt_smite_thunder',
	sound = Sound('ttt_smite/ttt_smite_thunder.wav')
})

-- ConVars

CreateConVar('ttt_smite_time', 1.68, {FCVAR_SERVER_CAN_EXECUTE, FCVAR_ARCHIVE}, 'Delay in seconds from starting to smite to the actual smite.')
CreateConVar('ttt_smite_damage', 150, {FCVAR_SERVER_CAN_EXECUTE, FCVAR_ARCHIVE}, 'Damage of the smite.')
CreateConVar('ttt_smite_range', 4096, {FCVAR_SERVER_CAN_EXECUTE, FCVAR_ARCHIVE}, 'Range of the smite in units.')
CreateConVar('ttt_smite_radius', 128, {FCVAR_SERVER_CAN_EXECUTE, FCVAR_ARCHIVE}, 'Radius of the smite in units.')
CreateConVar('ttt_smite_sparks_victim', 1, {FCVAR_SERVER_CAN_EXECUTE, FCVAR_ARCHIVE}, 'Should the victim emit sparks when they are a potential smite target?')
CreateConVar('ttt_smite_sparks_self', 1, {FCVAR_SERVER_CAN_EXECUTE, FCVAR_ARCHIVE}, 'Should the owner emit sparks when they holding the Lightning Caller?')
CreateConVar('ttt_smite_cooldown', 10, {FCVAR_SERVER_CAN_EXECUTE, FCVAR_ARCHIVE}, 'Cooldown of the smite in seconds.')
CreateConVar('ttt_smite_ammo', 2, {FCVAR_SERVER_CAN_EXECUTE, FCVAR_ARCHIVE}, 'Amount of smites the Lightning Caller can hold.')
CreateConVar('ttt_smite_status', 0, {FCVAR_SERVER_CAN_EXECUTE, FCVAR_ARCHIVE}, 'Should the smite status be shown to the potential victim?')
CreateConVar('ttt_smite_speech', 1, {FCVAR_SERVER_CAN_EXECUTE, FCVAR_ARCHIVE}, 'Should the smite speech be played?')

-- Sandbox Compatibility

hook.Add('AddToolMenuCategories', 'SmiteAddToolMenuCategories', function()
	spawnmenu.AddToolCategory('Utilities', 'Lightning Caller', 'Lightning Caller')
end)

local SMITE_DEFAULTS = {
	ttt_smite_time = 1.68,
	ttt_smite_damage = 150,
	ttt_smite_range = 4096,
	ttt_smite_radius = 128,
	ttt_smite_sparks_victim = 1,
	ttt_smite_sparks_self = 1,
	ttt_smite_cooldown = 10,
	ttt_smite_ammo = 2,
	ttt_smite_status = 0,
	ttt_smite_speech = 1
}

hook.Add('PopulateToolMenu', 'SmitePopulateToolMenu', function()
	spawnmenu.AddToolMenuOption('Utilities', 'Lightning Caller', 'lightning_caller', 'Settings', '', '', function(panel)
		panel:Help('Lightning Caller Settings')

		panel:ToolPresets('ttt_smite_presets', SMITE_DEFAULTS)

		panel:Help('General Settings')

		panel:NumSlider('Smite Delay', 'ttt_smite_time', 0.1, 10, 2)
		panel:ControlHelp('Delay in seconds from starting to smite to the actual smite.')

		panel:NumSlider('Smite Damage', 'ttt_smite_damage', 0, 1000, 0)
		panel:ControlHelp('Damage of the smite.')

		panel:NumSlider('Smite Cooldown', 'ttt_smite_cooldown', 1, 60, 1)
		panel:ControlHelp('Cooldown of the smite in seconds.')

		panel:NumSlider('Smite Range', 'ttt_smite_range', 0, 4096, 0)
		panel:ControlHelp('Range of the smite in units.')

		panel:NumSlider('Smite Radius', 'ttt_smite_radius', 0, 512, 0)
		panel:ControlHelp('Radius of the smite in units.')

		panel:Help('Effect Settings')

		panel:CheckBox('Sparks on Victim', 'ttt_smite_sparks_victim')
		panel:ControlHelp('Should the victim emit sparks when they are a potential smite target?')

		panel:CheckBox('Sparks on Self', 'ttt_smite_sparks_self')
		panel:ControlHelp('Should the owner emit sparks when they holding the Lightning Caller?')

		panel:CheckBox('Smite Speech', 'ttt_smite_speech')
		panel:ControlHelp('Should the smite speech be played?')

		panel:Help('TTT2 Settings')

		panel:CheckBox('Smite Status', 'ttt_smite_status')
	end)
end)

-- TTT Compatibility

if CLIENT then
	hook.Add('InitPostEntity', 'SmiteInitPostEntity', function()
		if TTT2 ~= nil or LANG == nil then return end

		LANG.AddToLanguage('English', 'smite_name', 'Smite')
		LANG.AddToLanguage('English', 'smite_desc', 'Smite your enemies with the power of lightning,\nand insult them too!')
	end)
end

-- TTT ULX Compatibility

hook.Add('TTTUlxInitCustomCVar', 'SmiteTTTUlxInitCustomCvar', function(name)
	ULib.replicatedWritableCvar('ttt_smite_time', 'rep_ttt_smite_time', GetConVar('ttt_smite_time'):GetFloat(), true, false, name)
	ULib.replicatedWritableCvar('ttt_smite_damage', 'rep_ttt_smite_damage', GetConVar('ttt_smite_damage'):GetInt(), true, false, name)
	ULib.replicatedWritableCvar('ttt_smite_range', 'rep_ttt_smite_range', GetConVar('ttt_smite_range'):GetInt(), true, false, name)
	ULib.replicatedWritableCvar('ttt_smite_sparks_victim', 'rep_ttt_smite_sparks_victim', GetConVar('ttt_smite_sparks_victim'):GetBool(), true, false, name)
	ULib.replicatedWritableCvar('ttt_smite_sparks_self', 'rep_ttt_smite_sparks_self', GetConVar('ttt_smite_sparks_self'):GetBool(), true, false, name)
	ULib.replicatedWritableCvar('ttt_smite_cooldown', 'rep_ttt_smite_cooldown', GetConVar('ttt_smite_cooldown'):GetFloat(), true, false, name)
	ULib.replicatedWritableCvar('ttt_smite_ammo', 'rep_ttt_smite_ammo', GetConVar('ttt_smite_ammo'):GetInt(), true, false, name)
	ULib.replicatedWritableCvar('ttt_smite_radius', 'rep_ttt_smite_radius', GetConVar('ttt_smite_radius'):GetInt(), true, false, name)
	ULib.replicatedWritableCvar('ttt_smite_status', 'rep_ttt_smite_status', GetConVar('ttt_smite_status'):GetBool(), true, false, name)
	ULib.replicatedWritableCvar('ttt_smite_speech', 'rep_ttt_smite_speech', GetConVar('ttt_smite_speech'):GetBool(), true, false, name)
end)

if CLIENT then
	hook.Add('TTTUlxModifyAddonSettings', 'SmiteTTTUlxModifyAddonSettings', function(name)
		local tttrspnl = xlib.makelistlayout{w = 415, h = 318, parent = xgui.null}

		-- Basic Settings 
		local tttrsclp1 = vgui.Create('DCollapsibleCategory', tttrspnl)
		tttrsclp1:SetSize(390, 50)
		tttrsclp1:SetExpanded(1)
		tttrsclp1:SetLabel('Basic Settings')

		local tttrslst1 = vgui.Create('DPanelList', tttrsclp1)
		tttrslst1:SetPos(5, 25)
		tttrslst1:SetSize(390, 150)
		tttrslst1:SetSpacing(5)

		local tttrsdh11 = xlib.makeslider{label = 'ttt_smite_time (Def. 1.68)', repconvar = 'rep_ttt_smite_time', min = 0.1, max = 10, decimal = 2, parent = tttrslst1}
		tttrslst1:AddItem(tttrsdh11)

		local tttrsdh12 = xlib.makeslider{label = 'ttt_smite_range (Def. 1024)', repconvar = 'rep_ttt_smite_range', min = 0, max = 4096, decimal = 0, parent = tttrslst1}
		tttrslst1:AddItem(tttrsdh12)

		local tttrsdh13 = xlib.makeslider{label = 'ttt_smite_radius (Def. 128)', repconvar = 'rep_ttt_smite_radius', min = 0, max = 512, decimal = 0, parent = tttrslst1}
		tttrslst1:AddItem(tttrsdh13)

		local tttrsdh14 = xlib.makeslider{label = 'ttt_smite_damage (Def. 0)', repconvar = 'rep_ttt_smite_damage', min = 0, max = 1000, decimal = 0, parent = tttrslst1}
		tttrslst1:AddItem(tttrsdh14)

		local tttrsdh17 = xlib.makeslider{label = 'ttt_smite_cooldown (Def. 10)', repconvar = 'rep_ttt_smite_cooldown', min = 1, max = 60, decimal = 1, parent = tttrslst1}
		tttrslst1:AddItem(tttrsdh17)

		local tttrsdh18 = xlib.makeslider{label = 'ttt_smite_ammo (Def. 2)', repconvar = 'rep_ttt_smite_ammo', min = 1, max = 10, decimal = 0, parent = tttrslst1}
		tttrslst1:AddItem(tttrsdh18)

		-- Effect Settings
		local tttrsclp2 = vgui.Create('DCollapsibleCategory', tttrspnl)
		tttrsclp2:SetSize(390, 50)
		tttrsclp2:SetExpanded(1)
		tttrsclp2:SetLabel('Effect Settings')

		local tttrslst2 = vgui.Create('DPanelList', tttrsclp2)
		tttrslst2:SetPos(5, 25)
		tttrslst2:SetSize(390, 50)
		tttrslst2:SetSpacing(5)

		local tttrsdh21 = xlib.makecheckbox{label = 'ttt_smite_sparks_victim (Def. 1)', repconvar = 'rep_ttt_smite_sparks_victim', parent = tttrslst2}
		tttrslst2:AddItem(tttrsdh21)

		local tttrsdh22 = xlib.makecheckbox{label = 'ttt_smite_sparks_self (Def. 1)', repconvar = 'rep_ttt_smite_sparks_self', parent = tttrslst2}
		tttrslst2:AddItem(tttrsdh22)

		if TTT2 then
			local tttrsdh23 = xlib.makecheckbox{label = 'ttt_smite_status (Def. 0)', repconvar = 'rep_ttt_smite_status', parent = tttrslst2}
			tttrslst2:AddItem(tttrsdh23)
		end

		local tttrsdh24 = xlib.makecheckbox{label = 'ttt_smite_speech (Def. 1)', repconvar = 'rep_ttt_smite_speech', parent = tttrslst2}
		tttrslst2:AddItem(tttrsdh24)

		xgui.hookEvent('onProcessModules', nil, tttrspnl.processModules)
		xgui.addSubModule('Smite', tttrspnl, nil, name)
	end)
end

-- TTT2 Compatibility

if CLIENT then
	hook.Add('Initialize', 'SmiteInitialize', function()
		if TTT2 and STATUS ~= nil then
			STATUS:RegisterStatus('ttt_smite_warning', {
				hud = Material('vgui/ttt/hud_ttt_smite.png'),
				type = 'default'
			})
		end
	end)
end
