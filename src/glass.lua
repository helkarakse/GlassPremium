--[[

	Terminal Glasses Lite Version 0.1 Dev
	Do not modify, copy or distribute without permission of author
	Helkarakse & Shotexpert, 20131203

]]

-- Libraries
os.loadAPI("functions")
os.loadAPI("tickParser")
os.loadAPI("rssParser")

-- Variables
local jsonFile = "profile.txt"
local rssLink = "http://www.otegamers.com/index.php?app=core&module=global&section=rss&type=forums&id=24"

-- Glass elements
local bridge, mainBox, edgeBox
local header, headerText, clockText, tpsText, lastUpdatedText

-- Display limit
local limit = 5

-- For the refresh loop
local lastUpdated, currentFileSize

-- Color array
local colors = {
	headerStart = 0x18caf0,
	headerEnd = 0x9fedfd,
	white = 0xffffff, 
	red = 0xFF0000
}

-- Text size array
local size = {
	small = 0.6, normal = 1, large = 1.25
}

-- Data arrays
local entitiesArray, chunksArray, typesArray, callsArray

-- Positioning variables
local headerHeight = (size.small * 10)
local tpsHeight = (size.normal * 10)
local lineMultiplier = headerHeight

-- Small TPS Size:
local smallX = 10
local smallY = 65
local smallWidth = 100
local smallHeight = 40

-- Full TPS size:
local largeX = 10
local largeY = 65
local largeWidth = 250
local largeHeight = (28 * lineMultiplier) + 10

-- RSS size:
local rssX = 10
local rssY = 65
local rssWidth = 150
local rssHeight = (10 * lineMultiplier) + 10

-- Event handling related
local currentDisplay = 1 -- main display

-- Functions
local function drawMain(inputX, inputY, inputWidth, inputHeight)
	mainBox = bridge.addBox(inputX, inputY, inputWidth, inputHeight, colors.headerEnd, 0.3)
	header = bridge.addGradientBox(inputX - 5, inputY, inputWidth, headerHeight, colors.headerEnd, 0, colors.headerStart, 1, 2)
	edgeBox = bridge.addGradientBox(inputX, inputY + inputHeight - 2, inputWidth, 2, colors.headerStart, 1, colors.headerEnd, 0, 2)
	header.setZIndex(2)
end

local function drawHeader(inputX, inputY)
	headerText = bridge.addText(inputX, inputY + 1, "OTE Glass (c) Helk & Shot 2013", colors.white)
	headerText.setZIndex(3)
	headerText.setScale(size.small)
end

local function drawTps(inputX, inputY)
	local tps = tickParser.getTps()
	local switch = {
		[1] = function()
			local tpsLabelText = bridge.addText(inputX + smallWidth - 55, inputY + smallHeight - tpsHeight, "TPS:", colors.white)
			tpsLabelText.setScale(size.normal)
			tpsLabelText.setZIndex(4)
			
			tpsText = bridge.addText(inputX + smallWidth - 30, inputY + smallHeight - tpsHeight, tps, tickParser.getTpsHexColor(tps))
			tpsText.setScale(size.normal)
			tpsText.setZIndex(4)
			
			clockText = bridge.addText(inputX + 10, inputY + headerHeight + 10, "", colors.white)
			clockText.setScale(size.large)
			clockText.setZIndex(4)
		end,
		[2] = function()
			local tpsLabelText = bridge.addText(inputX + largeWidth - 55, inputY + largeHeight - tpsHeight, "TPS:", colors.white)
			tpsLabelText.setScale(size.normal)
			tpsLabelText.setZIndex(4)
			
			tpsText = bridge.addText(inputX + largeWidth - 30, inputY + largeHeight - tpsHeight, tps, tickParser.getTpsHexColor(tps))
			tpsText.setScale(size.normal)
			tpsText.setZIndex(4)
			
			clockText = bridge.addText(inputX + largeWidth - 30, inputY + 1, "", colors.white)
			clockText.setScale(size.small)
			clockText.setZIndex(4)
			
			local lastUpdatedLabelText = bridge.addText(inputX + largeWidth - 100, inputY + 1, "Last Updated:", colors.white)
			lastUpdatedLabelText.setScale(size.small)
			lastUpdatedLabelText.setZIndex(4)
			
			lastUpdatedText = bridge.addText(inputX + largeWidth - 55, inputY + 1, "", colors.white)
			lastUpdatedText.setScale(size.small)
			lastUpdatedText.setZIndex(4)
		end,
	}
	
	switch[currentDisplay]()
end

local function drawEntities(inputX, inputY)
	local data = tickParser.getSingleEntities()
	entitiesArray = {}
	
	table.insert(entitiesArray, bridge.addText(inputX, inputY, "Entity Name:", colors.white).setScale(size.small))
	table.insert(entitiesArray, bridge.addText(inputX + 100, inputY, "Position:", colors.white).setScale(size.small))
	table.insert(entitiesArray, bridge.addText(inputX + 150, inputY, "%", colors.white).setScale(size.small))
	table.insert(entitiesArray, bridge.addText(inputX + 200, inputY, "Dimension:", colors.white).setScale(size.small))
	
	for i = 1, limit do
		table.insert(entitiesArray, bridge.addText(inputX, inputY + (lineMultiplier * i), data[i].name, colors.white).setScale(size.small))
		table.insert(entitiesArray, bridge.addText(inputX + 100, inputY + (lineMultiplier * i), data[i].position, colors.white).setScale(size.small))
		table.insert(entitiesArray, bridge.addText(inputX + 150, inputY + (lineMultiplier * i), data[i].percent, tickParser.getPercentHexColor(data[i].percent)).setScale(size.small))
		table.insert(entitiesArray, bridge.addText(inputX + 200, inputY + (lineMultiplier * i), tickParser.getDimensionName(tickParser.getServerId(os.getComputerID()), data[i].dimId), colors.white).setScale(size.small))
	end
	
	for i = 1, #entitiesArray do
		entitiesArray[i].setZIndex(5)
	end
end

local function drawChunks(inputX, inputY)
	local data = tickParser.getChunks()
	chunksArray = {}
	
	table.insert(chunksArray, bridge.addText(inputX, inputY, "Chunk Position (X, Z):", colors.white).setScale(size.small))
	table.insert(chunksArray, bridge.addText(inputX + 100, inputY, "Time/Tick:", colors.white).setScale(size.small))
	table.insert(chunksArray, bridge.addText(inputX + 150, inputY, "%", colors.white).setScale(size.small))
	
	for i = 1, limit do
		table.insert(chunksArray, bridge.addText(inputX, inputY + (lineMultiplier * i), data[i].positionX .. ", " .. data[i].positionZ, colors.white).setScale(size.small))
		table.insert(chunksArray, bridge.addText(inputX + 100, inputY + (lineMultiplier * i), data[i].time, colors.white).setScale(size.small))
		table.insert(chunksArray, bridge.addText(inputX + 150, inputY + (lineMultiplier * i), data[i].percent, tickParser.getPercentHexColor(data[i].percent)).setScale(size.small))
	end
	
	for i = 1, #chunksArray do
		chunksArray[i].setZIndex(5)
	end
end

local function drawTypes(inputX, inputY)
	local data = tickParser.getEntityByTypes()
	typesArray = {}
	
	table.insert(typesArray, bridge.addText(inputX, inputY, "Entity Type:", colors.white).setScale(size.small))
	table.insert(typesArray, bridge.addText(inputX + 100, inputY, "Time/Tick:", colors.white).setScale(size.small))
	table.insert(typesArray, bridge.addText(inputX + 150, inputY, "%", colors.white).setScale(size.small))
	
	for i = 1, limit do
		table.insert(typesArray, bridge.addText(inputX, inputY + (lineMultiplier * i), data[i].type, colors.white).setScale(size.small))
		table.insert(typesArray, bridge.addText(inputX + 100, inputY + (lineMultiplier * i), data[i].time, colors.white).setScale(size.small))
		table.insert(typesArray, bridge.addText(inputX + 150, inputY + (lineMultiplier * i), data[i].percent, tickParser.getPercentHexColor(data[i].percent)).setScale(size.small))
	end
	
	for i = 1, #typesArray do
		typesArray[i].setZIndex(5)
	end
end

local function drawCalls(inputX, inputY)
	local data = tickParser.getAverageCalls()
	callsArray = {}
	
	table.insert(callsArray, bridge.addText(inputX, inputY, "Entity Name:", colors.white).setScale(size.small))
	table.insert(callsArray, bridge.addText(inputX + 100, inputY, "Time/Tick:", colors.white).setScale(size.small))
	table.insert(callsArray, bridge.addText(inputX + 150, inputY, "Average Calls", colors.white).setScale(size.small))
	
	for i = 1, limit do
		table.insert(callsArray, bridge.addText(inputX, inputY + (lineMultiplier * i), data[i].name, colors.white).setScale(size.small))
		table.insert(callsArray, bridge.addText(inputX + 100, inputY + (lineMultiplier * i), data[i].time, colors.white).setScale(size.small))
		table.insert(callsArray, bridge.addText(inputX + 150, inputY + (lineMultiplier * i), data[i].calls, colors.white).setScale(size.small))
	end
	
	for i = 1, #callsArray do
		callsArray[i].setZIndex(5)
	end
end

local function drawSanta(inputX, inputY)
	local boxArray = {}
	--white parts
	table.insert(boxArray, bridge.addBox(inputX, inputY-9, 2, 2, colors.white, 1))
	table.insert(boxArray, bridge.addBox(inputX-9, inputY-1, 9, 2, colors.white, 1))
	
	--red parts
	table.insert(boxArray, bridge.addBox(inputX-2, inputY-8, 2, 1, colors.red, 1))
	table.insert(boxArray, bridge.addBox(inputX-3, inputY-7, 4, 1, colors.red, 1))
	table.insert(boxArray, bridge.addBox(inputX-4, inputY-6, 5, 1, colors.red, 1))
	table.insert(boxArray, bridge.addBox(inputX-5, inputY-5, 5, 1, colors.red, 1))
	table.insert(boxArray, bridge.addBox(inputX-6, inputY-4, 5, 1, colors.red, 1))
	table.insert(boxArray, bridge.addBox(inputX-7, inputY-3, 6, 1, colors.red, 1))
	table.insert(boxArray, bridge.addBox(inputX-8, inputY-2, 8, 1, colors.red, 1))
	
	--set zindexes
	for key, value in pairs(boxArray) do
		value.setZIndex(6)
	end
end

local function drawData()
	drawEntities(largeX + 5, largeY + headerHeight + 5)
	drawChunks(largeX + 5, largeY + headerHeight + 5 + ((limit + 2) * lineMultiplier))
	drawTypes(largeX + 5, largeY + headerHeight + 5 + ((limit + 2) * 2 * lineMultiplier))
	drawCalls(largeX + 5, largeY + headerHeight + 5 + ((limit + 2) * 3 * lineMultiplier))
end

local function drawRss(inputX, inputY)
	local data = rssParser.getItems()
	local rssArray = {}
	
--	for key, value in pairs(items) do
--		local title, link, desc, pubDate, guid = parser.parseItem(value)
--		
--		-- data display
--		monitor.setCursorPos(xPos, yPos)
--		monitor.write(functions.truncate(title, titleLimit))
--		monitor.setCursorPos(xPos + titleLimit, yPos)
--		monitor.write(parser.convertDate(pubDate))
--		
--		yPos = yPos + 1
--	end
	
	table.insert(rssArray, bridge.addText(inputX, inputY, "Title", colors.white).setScale(size.small))
	table.insert(rssArray, bridge.addText(inputX + 100, inputY, "Date", colors.white).setScale(size.small))
	
	local j = 1
	for key, value in pairs(data) do
		local title, link, desc, pubDate, guid = rssParser.parseItem(value)
		table.insert(rssArray, bridge.addText(inputX, inputY + (lineMultiplier * j), functions.truncate(title, 50), colors.white).setScale(size.small))
		table.insert(rssArray, bridge.addText(inputX + 100, inputY + (lineMultiplier * j), date, colors.white).setScale(size.small))
		j = j + 1
	end
	
	for i = 1, #rssArray do
		rssArray[i].setZIndex(5)
	end
end

local function drawScreen()
	bridge.clear()
	local switch = {
		[1] = function()
			-- draw main, header and tps
			drawMain(smallX, smallY, smallWidth, smallHeight)
			drawHeader(smallX, smallY)
			drawTps(smallX, smallY)
			end,
		[2] = function()
			-- draw main, header, tps and data
			drawMain(largeX, largeY, largeWidth, largeHeight)
			drawHeader(largeX, largeY)
			drawTps(largeX, largeY)
			drawData()
			end,
		[3] = function()
			drawMain(rssX, rssY, rssWidth, rssHeight)
			drawHeader(rssX, rssY)
			drawRss(rssX + 5, rssY + headerHeight + 5)
			end,
		[4] = function()
			end
	}
	
	switch[currentDisplay]()
end

-- Data Retrieval
local function getRssData()
	local xmlString
	local data = http.get(rssLink)
	if (data) then
    	functions.debug("XML file successfully retrieved.")
		xmlString = data.readAll()
		rssParser.parseData(xmlString)
		return true
	else
		functions.debug("Could not retrieve xml file.")
		return false
	end
end

local function getTickData()
	local file = fs.open(jsonFile, "r")
	local text = file.readAll()
	file.close()
	
	-- reset the updated time and the new file size
	currentFileSize = fs.getSize(jsonFile)
	functions.debug("Setting the current file size to: ", currentFileSize)
	lastUpdated = 0
	
	-- re-parse the data
	tickParser.parseData(text)
end

-- Loops
local tickRefreshLoop = function()
	lastUpdated = 0
	while true do
		if (fs.getSize(jsonFile) ~= currentFileSize) then
			-- Get the new data
			functions.debug("File size of profile.txt has changed. Assuming new data.")
			getTickData()
			
			-- redraw the new data
			functions.debug("Current display is: ", currentDisplay)
			drawScreen()
		else
			if (currentDisplay == 2) then
				lastUpdatedText.setText(lastUpdated .. "s")
			end
		end
		
		lastUpdated = lastUpdated + 1
		sleep(1)
	end
end

local rssRefreshLoop = function()
	while true do
		getRssData()
		sleep(60)
	end
end

local clockRefreshLoop = function()
	while true do
		-- no currentDisplay checks because clock will be on all of them
		local nTime = os.time()
		clockText.setText(textutils.formatTime(nTime, false))
		sleep(1)
	end
end

-- Event handler for chat commands
local eventHandler = function()
	while true do
		local event, message = os.pullEvent("chat_command")
		
		local args = functions.explode(" ", message)
		if (args[1] == "change") then
			functions.debug("Changing screen to: ", args[2])
			currentDisplay = tonumber(args[2])
			drawScreen()
		else
			-- switch statement (for efficiency vs if/else)
			local switch = {
				[1] = function()
					-- tick and clock
					functions.debug("Message was retrieved by the event [1]: ", message)
					end,
				[2] = function()
					-- full tick
					functions.debug("Message was retrieved by the event [2]: ", message)
					end,
				[3] = function()
					-- rss
					functions.debug("Message was retrieved by the event [3]: ", message)
					end,
				[4] = function()
					-- help
					functions.debug("Message was retrieved by the event [4]: ", message)
					end
			}
			
			switch[currentDisplay]()
		end
	end
end

local function init()
	local hasBridge, bridgeDir = functions.locatePeripheral("glassesbridge")
	if (hasBridge ~= true) then
		functions.debug("Terminal glasses bridge peripheral required.")
	else
		functions.debug("Found terminal bridge peripheral at: ", bridgeDir)
		bridge = peripheral.wrap(bridgeDir)
		bridge.clear()
	end
	
	getTickData()
	getRssData()
	
	drawScreen()
--	drawMain(largeX, largeY, largeWidth, largeHeight)
--	drawHeader(largeX, largeY)
--	drawTps(largeX, largeY)
--	--	drawSanta(largeX + 10, largeY - 1)
--	drawData()
	
	parallel.waitForAll(tickRefreshLoop, clockRefreshLoop, rssRefreshLoop, eventHandler)
end

init()
