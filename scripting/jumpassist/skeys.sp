//#include "jumpassist/database.sp"

new Handle:HudDisplayForward;
new Handle:HudDisplayASD;
new Handle:HudDisplayDuck;
new Handle:HudDisplayJump;

new bool:g_bGetClientKeys[MAXPLAYERS+1];

new g_iButtons[MAXPLAYERS+1];
new g_iSkeysRed[MAXPLAYERS+1];
new g_iSkeysGreen[MAXPLAYERS+1];
new g_iSkeysBlue[MAXPLAYERS+1];

new String:wasBack[MAXPLAYERS+1];
new String:wasMoveRight[MAXPLAYERS+1];
new String:wasMoveLeft[MAXPLAYERS+1];

public OnProfileLoaded(client, red, green, blue)
{
	g_iSkeysRed[client] = red;
	g_iSkeysGreen[client] = green;
	g_iSkeysBlue[client] = blue;

}

public OnGameFrame()
{
	new iClientToShow, iObserverMode;
	for (new i=1;i<MaxClients;i++)
	{

		if (g_bGetClientKeys[i])
		{
			ClearSyncHud(i, HudDisplayForward);
			ClearSyncHud(i, HudDisplayASD);
			ClearSyncHud(i, HudDisplayDuck);
			ClearSyncHud(i, HudDisplayJump);
			
			if (g_iButtons[i] & IN_SCORE) { return; }
			iObserverMode = GetEntPropEnt(i, Prop_Send, "m_iObserverMode");
			if (IsClientObserver(i)) { iClientToShow = GetEntPropEnt(i, Prop_Send, "m_hObserverTarget"); } else { iClientToShow = i; }
			if (!IsValidClient(i) || !IsValidClient(iClientToShow) || iObserverMode == 6) { return; }

			if (g_iButtons[iClientToShow] & IN_FORWARD)
			{
				SetHudTextParams(0.80, 0.40, 0.3, g_iSkeysRed[i], g_iSkeysGreen[i], g_iSkeysBlue[i], 255, 0, 0.0, 0.0, 0.0);
				ShowSyncHudText(i, HudDisplayForward, "W");
			} else {
				SetHudTextParams(0.80, 0.40, 0.3, g_iSkeysRed[i], g_iSkeysGreen[i], g_iSkeysBlue[i], 255, 0, 0.0, 0.0, 0.0);
				ShowSyncHudText(i, HudDisplayForward, "-");
			}
			

			if (g_iButtons[iClientToShow] & IN_BACK || g_iButtons[iClientToShow] & IN_MOVELEFT || g_iButtons[iClientToShow] & IN_MOVERIGHT)
			{
				decl String:g_sButtons[64];
				
				if (g_iButtons[iClientToShow] & IN_BACK)
				{
					Format(wasBack[iClientToShow], sizeof(wasBack), "S");
				} else {
					Format(wasBack[iClientToShow], sizeof(wasBack), "-");
				}
				if (g_iButtons[iClientToShow] & IN_MOVELEFT)
				{
					Format(wasMoveLeft[iClientToShow], sizeof(wasMoveLeft), "A");
				} else {
					Format(wasMoveLeft[iClientToShow], sizeof(wasMoveLeft), "-");
				}
				if (g_iButtons[iClientToShow] & IN_MOVERIGHT)
				{
					Format(wasMoveRight[iClientToShow], sizeof(wasMoveRight), "D");
				} else {
					Format(wasMoveRight[iClientToShow], sizeof(wasMoveRight), "-");
				}
				Format(g_sButtons, sizeof(g_sButtons), "%s %s %s", wasMoveLeft[iClientToShow], wasBack[iClientToShow], wasMoveRight[iClientToShow]);
				SetHudTextParams(0.78, 0.45, 0.3, g_iSkeysRed[i], g_iSkeysGreen[i], g_iSkeysBlue[i], 255, 0, 0.0, 0.0, 0.0);
				ShowSyncHudText(i, HudDisplayASD, g_sButtons);
			} else {
				decl String:g_sButtons[64]; Format(g_sButtons, sizeof(g_sButtons), "- - -");
				SetHudTextParams(0.78, 0.45, 0.3, g_iSkeysRed[i], g_iSkeysGreen[i], g_iSkeysBlue[i], 255, 0, 0.0, 0.0, 0.0);
				ShowSyncHudText(i, HudDisplayASD, g_sButtons);
			}
			if (g_iButtons[iClientToShow] & IN_DUCK)
			{
				SetHudTextParams(0.84, 0.45, 0.3, g_iSkeysRed[i], g_iSkeysGreen[i], g_iSkeysBlue[i], 255, 0, 0.0, 0.0, 0.0);
				ShowSyncHudText(i, HudDisplayDuck, "Duck");
			}
			if (g_iButtons[iClientToShow] & IN_JUMP)
			{
				SetHudTextParams(0.84, 0.40, 0.3, g_iSkeysRed[i], g_iSkeysGreen[i], g_iSkeysBlue[i], 255, 0, 0.0, 0.0, 0.0);
				ShowSyncHudText(i, HudDisplayJump, "Jump");
				
			}
		}
	}
	
	
}




public Action:cmdGetClientKeys(client, args)
{
/*
	if (!IsClientObserver(client))
	{
		ReplyToCommand(client, "\x01[\x03JA\x01] %t", "Showkeys_SpecOnly");
		return Plugin_Handled;
	}
*/
	if (g_bGetClientKeys[client])
	{
		g_bGetClientKeys[client] = false;
		PrintToChat(client, "\x01[\x03JA\x01] %t", "Showkeys_Off");
	} else {
		g_bGetClientKeys[client] = true;
		PrintToChat(client, "\x01[\x03JA\x01] %t", "Showkeys_On");
	}
	return Plugin_Handled;
}
public Action:cmdChangeSkeysColor(client, args)
{
	decl String:red[4], String:blue[4], String:green[4], String:query[512], String:steamid[32];
	if (args < 1)
	{
		PrintToChat(client, "\x01[\x03JA\x01] %t", "SkeysColor_Help");
		return Plugin_Handled;
	}

	GetCmdArg(1, red, sizeof(red)), GetCmdArg(2, green, sizeof(green)), GetCmdArg(3, blue, sizeof(blue));
	GetClientAuthString(client, steamid, sizeof(steamid));
	if (!IsStringNumeric(red) || !IsStringNumeric(blue) || !IsStringNumeric(green))
	{
		PrintToChat(client, "\x01[\x03JA\x01] %t", "Numeric_Invalid");
		return Plugin_Handled;
	}

	g_iSkeysRed[client] = StringToInt(red); g_iSkeysBlue[client] = StringToInt(blue); g_iSkeysGreen[client] = StringToInt(green);

	Format(query, sizeof(query), "UPDATE `player_profiles` SET SKEYS_RED_COLOR=%i, SKEYS_GREEN_COLOR=%i, SKEYS_BLUE_COLOR=%i WHERE steamid = '%s'", g_iSkeysRed[client], g_iSkeysGreen[client], g_iSkeysBlue[client], steamid);
	JA_SendQuery(query, client);

	return Plugin_Handled;
}