-- 
-- Please see the license.txt file included with this distribution for 
-- attribution and copyright information.
--

local updateHealthHelperOriginal;
local updateHealthBarScaleOriginal;
local TOKEN_HEALTHBAR_WIDTH_Original;
local TOKEN_HEALTHBAR_HOFFSET_Original;

function onInit()
	-- Save hooks to TokenManager values and function so we can re-use them as needed.
	-- This will make it less likely this extension breaks if the CoreRPG changes.
	TOKEN_HEALTHBAR_WIDTH_Original = TokenManager.TOKEN_HEALTHBAR_WIDTH;
	TOKEN_HEALTHBAR_HOFFSET_Original = TokenManager.TOKEN_HEALTHBAR_HOFFSET;
	
	updateHealthHelperOriginal = TokenManager.updateHealthHelper;
	TokenManager.updateHealthHelper = updateHealthHelper;
	
	updateHealthBarScaleOriginal = TokenManager.updateHealthBarScale;
	TokenManager.updateHealthBarScale = updateHealthBarScale;
	
	TokenManager.registerWidgetSet("healthbarframe", {"healthbarframe"});
	TokenManager.registerWidgetSet("health", {"healthbar", "healthdot", "healthbarframe"});
	
	registerOptions();
end

function registerOptions()
	-- Custom HealthBar (CHB)
	OptionsManager.registerOption2("CHBO", false, "option_custom_healthbar", "option_label_CHBO", "option_entry_cycler", 
			{ labels = "option_val_1|option_val_2|option_val_5|option_val_10|option_val_15", values = "1|2|5|10|15", baselabel = "option_val_off", baseval = "off", default = "5" });
	OptionsManager.registerOption2("CHBW", false, "option_custom_healthbar", "option_label_CHBW", "option_entry_cycler", 
			{ labels = "option_val_10|option_val_15|option_val_20|option_val_25|option_val_30", values = "10|15|20|25|30", baselabel = "option_val_off", baseval = "off", default = "20" });
	OptionsManager.registerOption2("CHBG", false, "option_custom_healthbar", "option_label_CHBG", "option_entry_cycler", 
			{ labels = "option_val_on", values = "on", baselabel = "option_val_off", baseval = "off", default = "on" });
	OptionsManager.registerOption2("CHBC", false, "option_custom_healthbar", "option_label_CHBC", "option_entry_cycler", 
			{ labels = "option_val_dark", values = "dark", baselabel = "option_val_light", baseval = "light", default = "light" });
	DB.addHandler("options.CHBO", "onUpdate", TokenManager.onOptionChanged);
	DB.addHandler("options.CHBW", "onUpdate", TokenManager.onOptionChanged);
	DB.addHandler("options.CHBG", "onUpdate", TokenManager.onOptionChanged);
	DB.addHandler("options.CHBC", "onUpdate", TokenManager.onOptionChanged);

end
		
function updateHealthHelper(tokenCT, nodeCT)
	local sOptTH;
	
	-- Call the CoreRPG version first for the base health bar
	updateHealthHelperOriginal(tokenCT, nodeCT);

	local aWidgets = TokenManager.getWidgetList(tokenCT, "healthbarframe");
	
	sOptTH = OptionsManager.getOption("CHBG");
	if sOptTH == "off" then
		for _,vWidget in pairs(aWidgets) do
			vWidget.destroy();
		end
		
		return;
	end
	
	if Session.IsHost then
		sOptTH = OptionsManager.getOption("TGMH");
	elseif DB.getValue(nodeCT, "friendfoe", "") == "friend" then
		sOptTH = OptionsManager.getOption("TPCH");
	else
		sOptTH = OptionsManager.getOption("TNPCH");
	end

	if sOptTH == "off" then
		for _,vWidget in pairs(aWidgets) do
			vWidget.destroy();
		end
	else
		local nPercentWounded,sStatus,sColor = TokenManager2.getHealthInfo(nodeCT);
		
		if sOptTH == "bar" or sOptTH == "barhover" then
			local w, h = tokenCT.getSize();
		
			local bAddBar = false;
			if h > 0 then
				bAddBar = true; 
			end
			
			if bAddBar then
				local widgetHealthBarFrame = aWidgets["healthbarframe"];
				if not widgetHealthBarFrame then
					widgetHealthBarFrame = tokenCT.addBitmapWidget("healthbar");
					widgetHealthBarFrame.setName("healthbarframe");
				end

				if widgetHealthBarFrame then
					widgetHealthBarFrame.sendToBack();

					local sOptCHBC = OptionsManager.getOption("CHBC");
					if sOptCHBC == "dark" then
						widgetHealthBarFrame.setColor("C0202020"); --  dark mode
					else
						widgetHealthBarFrame.setColor("C0E0E0E0"); -- light mode
					end
					widgetHealthBarFrame.setTooltipText(sStatus);
					widgetHealthBarFrame.setVisible(sOptTH == "bar");
				end
			end
			
		elseif sOptTH == "dot" or sOptTH == "dothover" then
			if aWidgets["healthbarframe"] then
				aWidgets["healthbarframe"].destroy();
			end
		end
	end
end

function updateHealthBarScale(tokenCT, nodeCT, nPercentWounded)
	
	-- Cal the CoreRPG version first to get the real healthbar dimensions set
	updateHealthBarScaleOriginal(tokenCT, nodeCT, nPercentWounded);
	
	-- Get the offset option
	local sOptCHBO = OptionsManager.getOption("CHBO");
	if sOptCHBO == "off" then
		sOptCHBO = TOKEN_HEALTHBAR_HOFFSET_Original;
	end
	TokenManager.TOKEN_HEALTHBAR_HOFFSET = sOptCHBO;
	
	-- Get the width option
	local sOptCHBW = OptionsManager.getOption("CHBW");
	if sOptCHBW == "off" then
		sOptCHBW = TOKEN_HEALTHBAR_WIDTH_Original;
	end
	TokenManager.TOKEN_HEALTHBAR_WIDTH = sOptCHBW;
	
	-- Calculate the background "empty" portion of the health bar to show where 100% would be
	widgetHealthBar = tokenCT.findWidget("healthbarframe");
	if widgetHealthBar then
		local nDU = GameSystem.getDistanceUnitsPerGrid();
		local nSpace = math.ceil(DB.getValue(nodeCT, "space", nDU) / nDU);
		local sOptTASG = OptionsManager.getOption("TASG");

		local barw = TokenManager.TOKEN_HEALTHBAR_WIDTH;
		local barh = TokenManager.TOKEN_HEALTHBAR_HEIGHT;
		if sOptTASG == "80" then
			barw = barw * 0.8;
			barh = barh * 0.8;
		end

		widgetHealthBar.setClipRegion(0, 0, 100, 100);
		widgetHealthBar.setSize(barw * nSpace, barh * nSpace);
		widgetHealthBar.setPosition("right", TokenManager.TOKEN_HEALTHBAR_HOFFSET, 0);
	end
end
