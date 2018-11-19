#define defaultXLoc 0.54
#define defaultYLoc 0.40

Handle
	  HudDisplayForward
	, HudDisplayASD
	, HudDisplayDuck
	, HudDisplayJump
	, HudDisplayM1
	, HudDisplayM2;
bool
	  g_bGetClientKeys[MAXPLAYERS+1];
int
	  g_iButtons[MAXPLAYERS+1]
	, g_iSkeysRed[MAXPLAYERS+1]
	, g_iSkeysGreen[MAXPLAYERS+1]
	, g_iSkeysBlue[MAXPLAYERS+1];
float
	  g_iSkeysXLoc[MAXPLAYERS+1]
	, g_iSkeysYLoc[MAXPLAYERS+1];

public void OnProfileLoaded(int client, int red, int green, int blue) {
	g_iSkeysRed[client] = red;
	g_iSkeysGreen[client] = green;
	g_iSkeysBlue[client] = blue;
}

void SetAllSkeysDefaults() {
	for (int i = 0; i <= MaxClients; i++) {
		SetSkeysDefaults(i);
	}
}

void SetSkeysDefaults(int client) {
	g_iSkeysXLoc[client] = defaultXLoc;
	g_iSkeysYLoc[client] = defaultYLoc;
}

void SkeysOnGameFrame() {
	int iClientToShow, iObserverMode;
	for (int i = 1; i < MaxClients; i++) {
		if (g_bGetClientKeys[i] && IsClientInGame(i)) {
			ClearSyncHud(i, HudDisplayForward);
			ClearSyncHud(i, HudDisplayASD);
			ClearSyncHud(i, HudDisplayDuck);
			ClearSyncHud(i, HudDisplayJump);
			ClearSyncHud(i, HudDisplayM1);
			ClearSyncHud(i, HudDisplayM2);

			if (g_iButtons[i] & IN_SCORE) {
				continue;
			}
			iObserverMode = GetEntPropEnt(i, Prop_Send, "m_iObserverMode");
			iClientToShow = IsClientObserver(i) ? GetEntPropEnt(i, Prop_Send, "m_hObserverTarget") : i;

			if (!IsValidClient(i) || !IsValidClient(iClientToShow) || iObserverMode == 7) {
				continue;
			}

			int r = g_iSkeysRed[i];
			int g = g_iSkeysGreen[i];
			int b = g_iSkeysBlue[i];

			bool forwards = (g_iButtons[iClientToShow] & IN_FORWARD) > 0;
			bool back = (g_iButtons[iClientToShow] & IN_BACK) > 0;
			bool left = (g_iButtons[iClientToShow] & IN_MOVELEFT) > 0;
			bool right = (g_iButtons[iClientToShow] & IN_MOVERIGHT) > 0;
			bool duck = (g_iButtons[iClientToShow] & IN_DUCK) > 0;
			bool jump = (g_iButtons[iClientToShow] & IN_JUMP) > 0;
			bool m1 = (g_iButtons[iClientToShow] & IN_ATTACK) > 0;
			bool m2 = (g_iButtons[iClientToShow] & IN_ATTACK2) > 0;

			SetHudTextParams(g_iSkeysXLoc[i]+0.06, g_iSkeysYLoc[i], 0.3, r, g, b, 255, 0, 0.0, 0.0, 0.0);
			ShowSyncHudText(i, HudDisplayForward, forwards?"W":"-");

			SetHudTextParams(g_iSkeysXLoc[i] + 0.04, g_iSkeysYLoc[i]+0.05, 0.3, r, g, b, 255, 0, 0.0, 0.0, 0.0);
			ShowSyncHudText(i, HudDisplayASD, "%s %s %s", left?"A":"-", back?"S":"-", right?"D":"-");

			SetHudTextParams(g_iSkeysXLoc[i]+0.1, g_iSkeysYLoc[i]+0.05, 0.3, r, g, b, 255, 0, 0.0, 0.0, 0.0);
			ShowSyncHudText(i, HudDisplayDuck, duck?"Duck":"");

			SetHudTextParams(g_iSkeysXLoc[i] + 0.1, g_iSkeysYLoc[i], 0.3, r, g, b, 255, 0, 0.0, 0.0, 0.0);
			ShowSyncHudText(i, HudDisplayJump, jump?"Jump":"");

			SetHudTextParams(g_iSkeysXLoc[i], g_iSkeysYLoc[i], 0.3, r, g, b, 255, 0, 0.0, 0.0, 0.0);
			ShowSyncHudText(i, HudDisplayM1, m1?"M1":"");

			SetHudTextParams(g_iSkeysXLoc[i], g_iSkeysYLoc[i]+0.05, 0.3, r, g, b, 255, 0, 0.0, 0.0, 0.0);
			ShowSyncHudText(i, HudDisplayM2, m2?"M2":"");
			//.54 x def and .4 y def
		}
	}
}

public Action cmdGetClientKeys(int client, int args) {
	g_bGetClientKeys[client] = !g_bGetClientKeys[client];
	PrintToChat(client, "\x01[\x03JA\x01] %t", g_bGetClientKeys[client] ? "Showkeys_On" : "Showkeys_Off");
	return Plugin_Handled;
}

public Action cmdChangeSkeysColor(int client, int args) {
	char red[4];
	char blue[4];
	char green[4];
	char query[512];
	char steamid[32];
		
	if (args < 1) {
		PrintToChat(client, "\x01[\x03JA\x01] %t", "SkeysColor_Help");
		return Plugin_Handled;
	}
	GetCmdArg(1, red, sizeof(red));
	GetCmdArg(2, green, sizeof(green));
	GetCmdArg(3, blue, sizeof(blue));
	GetClientAuthId(client, AuthId_Steam2, steamid, sizeof(steamid));
	if (!IsStringNumeric(red) || !IsStringNumeric(blue) || !IsStringNumeric(green)) {
		PrintToChat(client, "\x01[\x03JA\x01] %t", "Numeric_Invalid");
		return Plugin_Handled;
	}
	g_iSkeysRed[client] = StringToInt(red);
	g_iSkeysBlue[client] = StringToInt(blue);
	g_iSkeysGreen[client] = StringToInt(green);

	//if (!databaseConfigured)
	//{
	//	PrintToChat(client, "No database configured - cannot save key colors");
	//	return Plugin_Handled;
	//}
	//This will throw a server error but its no big deal
	g_hDatabase.Format(
		  query
		, sizeof(query)
		, "UPDATE `player_profiles` "
		... "SET "
			... "SKEYS_RED_COLOR=%i, "
			... "SKEYS_GREEN_COLOR=%i, "
			... "SKEYS_BLUE_COLOR=%i "
		... "WHERE steamid = '%s'"
		, g_iSkeysRed[client]
		, g_iSkeysGreen[client]
		, g_iSkeysBlue[client]
		, steamid
	);
	JA_SendQuery(query, client);

	return Plugin_Handled;
}

public Action cmdChangeSkeysLoc(int client, int args) {
	if (args != 2) {
		PrintToChat(client, "\x01[\x03JA\x01] This command requires 2 arguments");
		return Plugin_Handled;
	}
	char arg1[16];
	char arg2[16];
	float xLoc;
	float yLoc;

	GetCmdArg(1, arg1, sizeof(arg1));
	GetCmdArg(2, arg2, sizeof(arg2));
	xLoc = StringToFloat(arg1);
	yLoc = StringToFloat(arg2);
	if (xLoc >= 1.0 || yLoc >= 1.0 || xLoc <= 0.0 || yLoc <= 0.0) {
		PrintToChat(client, "\x01[\x03JA\x01] Both arguments must be between 0 and 1");
		return Plugin_Handled;
	}
	g_iSkeysXLoc[client] = xLoc;
	g_iSkeysYLoc[client] = yLoc;

	return Plugin_Continue;
}