--[[

	OTE GlassPremium Master Control
	Do not modify, copy or distribute without permission of author
	Helkarakse 20131213
	
]]

-- Libraries
os.loadAPI("functions")

-- Variables
local modemFrequency = 1
local modem

-- References
local peripheral = peripheral

-- Arrays
local menuOptions = {
	{name = "[1] Perform configuration backup"},
	{name = "[2] Perform rolling reboots"}
}

local function displayMenu()
	for i = 1, #menuOptions do
		print(menuOptions[i].name);
	end
end

local function init()
	local hasModem, modemDir = functions.locatePeripheral("modem")
	if (hasModem) then
		modem = peripheral.wrap(modemDir)
		modem.open(modemFrequency)
	end
	
	displayMenu()
end

init()