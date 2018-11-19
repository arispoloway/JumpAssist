#pragma newdecls required

ConVar
	  cvarPluginEnabled;
ConVar
	  g_hHostname;
Handle
	  g_hProfileLoaded;
bool
	  g_bCPTouched[MAXPLAYERS+1][32]
	, g_bHPRegen[MAXPLAYERS+1]
	, g_bAmmoRegen[MAXPLAYERS+1]
	, g_bHardcore[MAXPLAYERS+1]
	, g_bLoadedPlayerSettings[MAXPLAYERS+1]
	, g_bBeatTheMap[MAXPLAYERS+1]
	, g_bUsedReset[MAXPLAYERS+1]
	, g_bSpeedRun[MAXPLAYERS+1]
	, g_bUnkillable[MAXPLAYERS+1]
	, g_bLateLoad;
int
	  g_iCPs
	, g_iForceTeam = 1
	, g_iCPsTouched[MAXPLAYERS+1]
	, g_iMapClass = -1
	, g_iLockCPs = 1;
float
	  g_fOrigin[MAXPLAYERS+1][3]
	, g_fAngles[MAXPLAYERS+1][3]
	, g_fLastSavePos[MAXPLAYERS+1][3]
	, g_fLastSaveAngles[MAXPLAYERS+1][3];
char
	  g_sJtele[64]
	, g_sCaps[MAXPLAYERS+1];

void JA_SendQuery(char[] query, int client) {
	g_hDatabase.Query(SQL_OnSetMy, query, client);
}

void JA_CreateForward() {
	g_hProfileLoaded = CreateGlobalForward("OnProfileLoaded", ET_Ignore, Param_Cell, Param_Cell, Param_Cell, Param_Cell);
}

void ConnectToDatabase() {
	Database.Connect(SQL_OnConnect, "jumpassist");
}

void RunDBCheck() {
	char error[255], query[2048], ident[64];
	SQL_ReadDriver(g_hDatabase, ident, sizeof ident);
	bool isMysql = StrEqual(ident, "mysql", false);

	g_hDatabase.Format(
		  query
		, sizeof(query)
		, "CREATE TABLE IF NOT EXISTS `player_saves` "
		... "("
			... "`RecID` INTEGER NOT NULL PRIMARY KEY %s, "
			... "`steamID` VARCHAR(32) NOT NULL, "
			... "`playerClass` INT(1) NOT NULL, "
			... "`playerTeam` INT(1) NOT NULL, "
			... "`playerMap` VARCHAR(32) NOT NULL, "
			... "`save1` INT(25) NOT NULL, "
			... "`save2` INT(25) NOT NULL, "
			... "`save3` INT(25) NOT NULL, "
			... "`save4` INT(25) NOT NULL, "
			... "`save5` INT(25) NOT NULL, "
			... "`save6` INT(25) NOT NULL, "
			... "`Capped` VARCHAR(32)"
		... ")"
		, isMysql?"AUTO_INCREMENT":"AUTOINCREMENT"
	);

	if (!SQL_FastQuery(g_hDatabase, query)) {
		SQL_GetError(g_hDatabase, error, sizeof(error));
		LogError("Failed to query (player_saves) (error: %s)", error);
		SQL_UnlockDatabase(g_hDatabase);
	}

	g_hDatabase.Format(
		  query
		, sizeof(query)
		, "CREATE TABLE IF NOT EXISTS `player_profiles` "
		... "("
			... "`ID` integer PRIMARY KEY %s NOT NULL, "
			... "`SteamID` text NOT NULL, "
			... "`Health` integer NOT NULL DEFAULT 0, "
			... "`Ammo` integer NOT NULL DEFAULT 0, "
			... "`Hardcore` integer NOT NULL DEFAULT 0, "
			... "`PlayerFOV` integer NOT NULL DEFAULT 90, "
			... "`SKEYS_RED_COLOR` INTEGER NOT NULL DEFAULT 255, "
			... "`SKEYS_GREEN_COLOR` INTEGER NOT NULL DEFAULT 255, "
			... "`SKEYS_BLUE_COLOR` INTEGER NOT NULL DEFAULT 255"
		... ")"
		, isMysql?"AUTO_INCREMENT":"AUTOINCREMENT"
	);

	if (!SQL_FastQuery(g_hDatabase, query)) {
		SQL_GetError(g_hDatabase, error, sizeof(error));
		LogError("Failed to query (player_profiles) (error: %s)", error);
		SQL_UnlockDatabase(g_hDatabase);
	}

	g_hDatabase.Format(
		  query
		, sizeof(query)
		, "CREATE TABLE IF NOT EXISTS `map_settings` "
		... "("
			... "`ID` integer PRIMARY KEY %s NOT NULL, "
			... "`Map` text NOT NULL, "
			... "`Team` int NOT NULL, "
			... "`LockCPs` int NOT NULL, "
			... "`Class` int NOT NULL"
		... ")"
		, isMysql?"AUTO_INCREMENT":"AUTOINCREMENT"
	);

	if (!SQL_FastQuery(g_hDatabase, query)) {
		SQL_GetError(g_hDatabase, error, sizeof(error));
		LogError("Failed to query (map_settings) (error: %s)", error);
		SQL_UnlockDatabase(g_hDatabase);
	}

	g_hDatabase.Format(
		  query
		, sizeof(query)
		, "CREATE TABLE IF NOT EXISTS `Teleports` "
		... "("
			... "`ID` INTEGER PRIMARY KEY %s NOT NULL, "
			... "`MapName` TEXT(32) NOT NULL, "
			... "`TeleName` TEXT(64) NOT NULL, "
			... "`L1` FLOAT NOT NULL, "
			... "`L2` FLOAT NOT NULL, "
			... "`L3` FLOAT NOT NULL, "
			... "`A1` FLOAT NOT NULL, "
			... "`A2` FLOAT NOT NULL, "
			... "`A3` FLOAT NOT NULL"
		... ")"
		, isMysql?"AUTO_INCREMENT":"AUTOINCREMENT"
	);

	if (!SQL_FastQuery(g_hDatabase, query)) {
		SQL_GetError(g_hDatabase, error, sizeof(error));
		LogError("Failed to query (teleports) (error: %s)", error);
		SQL_UnlockDatabase(g_hDatabase);
	}

	g_hDatabase.Format(
		  query
		, sizeof(query)
		, "CREATE TABLE IF NOT EXISTS `startlocs` "
		... "("
			... "`ID` INTEGER PRIMARY KEY %s NOT NULL, "
			... "`MapName` TEXT(32) NOT NULL, "
			...	"`x` FLOAT(25) NOT NULL, "
			... "`y` FLOAT(25) NOT NULL, "
			... "`z` FLOAT(25) NOT NULL, "
			... "`xang` FLOAT(25) NOT NULL, "
			... "`yang` FLOAT(25) NOT NULL, "
			... "`zang` FLOAT(25) NOT NULL"
		... ")"
		, isMysql?"AUTO_INCREMENT":"AUTOINCREMENT"
	);

	if (!SQL_FastQuery(g_hDatabase, query)) {
		SQL_GetError(g_hDatabase, error, sizeof(error));
		LogError("Failed to query (startlocs) (error: %s)", error);
		SQL_UnlockDatabase(g_hDatabase);
	}

	g_hDatabase.Format(
		  query
		, sizeof(query)
		, "CREATE TABLE IF NOT EXISTS `zones` "
		... "("
			... "`ID` INTEGER PRIMARY KEY %s NOT NULL, "
			... "`Number` INT(25) NOT NULL, "
			... "`MapName` TEXT(32) NOT NULL, "
			... "`x1` FLOAT(25) NOT NULL, "
			... "`y1` FLOAT(25) NOT NULL, "
			... "`z1` FLOAT(25) NOT NULL, "
			... "`x2` FLOAT(25) NOT NULL, "
			... "`y2` FLOAT(25) NOT NULL, "
			... "`z2` FLOAT(25) NOT NULL"
		... ")"
		, isMysql?"AUTO_INCREMENT":"AUTOINCREMENT"
	);

	if (!SQL_FastQuery(g_hDatabase, query)) {
		SQL_GetError(g_hDatabase, error, sizeof(error));
		LogError("Failed to query (zones) (error: %s)", error);
		SQL_UnlockDatabase(g_hDatabase);
	}

	SQL_UnlockDatabase(g_hDatabase);
	g_hDatabase.Format(
		query
		, sizeof(query)
		, "CREATE TABLE IF NOT EXISTS `times` "
		... "("
			... "`ID` INTEGER PRIMARY KEY %s NOT NULL, "
			... "`SteamID` text NOT NULL, "
			... "`class` INT(23) NOT NULL, "
			... "`MapName` TEXT(32) NOT NULL, "
			... "`time` BIGINT NOT NULL, "
			... "`c0` FLOAT(25) DEFAULT '0.0', "
			... "`c1` FLOAT(25) DEFAULT '0.0', "
			... "`c2` FLOAT(25) DEFAULT '0.0', "
			... "`c3` FLOAT(25) DEFAULT '0.0', "
			... "`c4` FLOAT(25) DEFAULT '0.0', "
			... "`c5` FLOAT(25) DEFAULT '0.0', "
			... "`c6` FLOAT(25) DEFAULT '0.0', "
			... "`c7` FLOAT(25) DEFAULT '0.0', "
			... "`c8` FLOAT(25) DEFAULT '0.0', "
			... "`c9` FLOAT(25) DEFAULT '0.0', "
			... "`c10` FLOAT(25) DEFAULT '0.0', "
			... "`c11` FLOAT(25) DEFAULT '0.0', "
			... "`c12` FLOAT(25) DEFAULT '0.0', "
			... "`c13` FLOAT(25) DEFAULT '0.0', "
			... "`c14` FLOAT(25) DEFAULT '0.0', "
			... "`c15` FLOAT(25) DEFAULT '0.0', "
			... "`c16` FLOAT(25) DEFAULT '0.0', "
			... "`c17` FLOAT(25) DEFAULT '0.0', "
			... "`c18` FLOAT(25) DEFAULT '0.0', "
			... "`c19` FLOAT(25) DEFAULT '0.0', "
			... "`c20` FLOAT(25) DEFAULT '0.0', "
			... "`c21` FLOAT(25) DEFAULT '0.0', "
			... "`c22` FLOAT(25) DEFAULT '0.0', "
			... "`c23` FLOAT(25) DEFAULT '0.0', "
			... "`c24` FLOAT(25) DEFAULT '0.0', "
			... "`c25` FLOAT(25) DEFAULT '0.0', "
			... "`c26` FLOAT(25) DEFAULT '0.0', "
			... "`c27` FLOAT(25) DEFAULT '0.0', "
			... "`c28` FLOAT(25) DEFAULT '0.0', "
			... "`c29` FLOAT(25) DEFAULT '0.0', "
			... "`c30` FLOAT(25) DEFAULT '0.0', "
			... "`c31` FLOAT(25) DEFAULT '0.0'"
		... ")"
		, isMysql?"AUTO_INCREMENT":"AUTOINCREMENT"
	);

	if (!SQL_FastQuery(g_hDatabase, query)) {
		SQL_GetError(g_hDatabase, error, sizeof(error));
		LogError("Failed to query (times) (error: %s)", error);
		SQL_UnlockDatabase(g_hDatabase);
	}

	SQL_UnlockDatabase(g_hDatabase);
	g_hDatabase.Format(
		  query
		, sizeof(query)
		, "CREATE TABLE IF NOT EXISTS `steamids` "
		... "("
			... "`ID` INTEGER PRIMARY KEY %s NOT NULL, "
			... "`SteamID` text NOT NULL, "
			... "`name` TEXT(64) NOT NULL"
		... ")"
		, isMysql?"AUTO_INCREMENT":"AUTOINCREMENT"
	);

	if (!SQL_FastQuery(g_hDatabase, query)) {
		SQL_GetError(g_hDatabase, error, sizeof(error));
		LogError("Failed to query (steamids) (error: %s)", error);
		SQL_UnlockDatabase(g_hDatabase);
	}
	SQL_UnlockDatabase(g_hDatabase);

	LoadMapSpeedrunInfo();
}

public void SQL_OnConnect(Database db, const char[] error, any data) {
	if (db == null) {
		PrintToServer("[JumpAssist] Invalid database configuration, assuming none");
		PrintToServer(error);
	}
	else {
		g_hDatabase = db;

		if (g_bLateLoad) {
			// Reload map configurations
			LoadMapCFG();
			TF2_SetGameType();
			int iCP = -1;
			g_iCPs = 0;
			while ((iCP = FindEntityByClassname(iCP, "trigger_capture_area")) != -1) {
				g_iCPs++;
			}
			Hook_Func_regenerate();

			// Reload player saves for those who are a valid client.
			for (int i = 1; i < MaxClients; i++) {
				if (IsValidClient(i)) {
					UpdateSteamID(i);
					ReloadPlayerData(i);
				}
			}
		}
		RunDBCheck();
	}
}

public void SQL_OnPlayerRanSQL(Database db, DBResultSet results, const char[] error, any data) {
	int client = data;

	if (db == null) {
		LogError("Query failed! %s", error);
		ReplyToCommand(client, "\x01[\x03JA\x01] Query Failed. %s", error);
		return;
	}
	PrintToChat(client, "\x01[\x03JA\x01] Query was successful.");
}

public void SQL_OnMapSettingsUpdated(Database db, DBResultSet results, const char[] error, any data) {
	int client = data;

	if (db == null) {
		LogError("Query failed! %s", error);
		PrintToChat(client, "\x01[\x03JA\x01] %t (%s)", "Mapset_Not_Saved", cLightGreen, cDefault, error);
		return;
	}
	PrintToChat(client, "\x01[\x03JA\x01] %t", "Mapset_Saved", cLightGreen, cDefault);
}

public void SQL_OnMapSettingsLoad(Database db, DBResultSet result, const char[] error, any data) {
	if (db == null) {
		LogError("Query failed! %s", error);
		return;
	}
	if (result.RowCount) {
		result.FetchRow();
		g_iForceTeam = result.FetchInt(0);
		g_iLockCPs = result.FetchInt(1);
		g_iMapClass = result.FetchInt(2);
	}
	else {
		CreateMapCFG();
	}
}

public void SQL_OnSetMy(Database db, DBResultSet results, const char[] error, any data) {
	int client = data;
	if (db == null) {
		LogError("Query failed! %s", error);
		PrintToChat(client, "\x01[\x03JA\x01] %t", "SetMy_Failed");
		return;
	}
	PrintToChat(client, "\x01[\x03JA\x01] %t", "SetMy_Success");
}

public void SQL_OnLoadPlayerProfile(Database db, DBResultSet results, const char[] error, any data) {
	char sMapName[32]; GetCurrentMap(sMapName, sizeof(sMapName));
	int client = data;

	if (db == null) {
		LogError("Something bad happened");
		return;
	}
	if (results.RowCount) {
		//Bookmark
		results.FetchRow();
		int HP = results.FetchInt(2);
		int Ammo = results.FetchInt(3);
		int HC = results.FetchInt(4);
		int PlayerFOV = results.FetchInt(5);
		int red = results.FetchInt(6);
		int green = results.FetchInt(7);
		int blue = results.FetchInt(8);
		//LogError("HP = %i, Ammo = %i, HC = %i, PlayerFOV = %i, red = %i, green = %i, blue = %i", HP, Ammo, HC, PlayerFOV, red, green, blue);

		// Skeys hud color.
		//g_iSkeysRed[client] = red; g_iSkeysGreen[client] = green; g_iSkeysBlue[client] = blue;

		Call_StartForward(g_hProfileLoaded);
		Call_PushCell(client);
		Call_PushCell(red);
		Call_PushCell(green);
		Call_PushCell(blue);
		Call_Finish();

		// FOV
		if (FindPluginByFile("fov.smx") != null) {
			char fovcmd[32];
			Format(fovcmd, sizeof(fovcmd), "sm_fov %i", PlayerFOV);
			if (IsClientConnected(client)) {
				FakeClientCommand(client, fovcmd);
			}
		}
		g_bHPRegen[client] = (HP == 1);
		g_bAmmoRegen[client] = (Ammo == 1);
		if (HC == 1) {
			g_bHardcore[client] = true;
			g_bHPRegen[client] = false;
			g_bAmmoRegen[client] = false;
		}
		g_bLoadedPlayerSettings[client] = true;
		return;
	}
	else {
		// No profile
		if (IsValidClient(client)) {
			char SteamID[32];
			GetClientAuthId(client, AuthId_Steam2, SteamID, sizeof(SteamID));
			if (g_hDatabase != null) {
				CreatePlayerProfile(client, SteamID);
			}
		}
	}
}

public void SQL_OnCreatePlayerProfile(Database db, DBResultSet results, const char[] error, any data) {
	int client = data;
	if (db == null) {
		LogError("OnCreatePlayerProfile() - Query failed! %s", error);
		return;
	}
	g_bHPRegen[client] = false;
	g_bHardcore[client] = false;
	g_bLoadedPlayerSettings[client] = true;
}

public void SQL_OnMenuSendToLocation(Database db, DBResultSet results, const char[] error, any data) {
	int client = data;

	if (db == null) {
		LogError("OnMenuSendToLocation() - Query failed! %s", error);
	}
	else if (results.RowCount) {
		results.FetchRow();
		float fLoc[3];
		float fPosVec[3];
		float fPosAng[3];
		char sJumpName[MAX_NAME_LENGTH];
		char sClientName[MAX_NAME_LENGTH];
		GetClientName(client, sClientName, sizeof(sClientName));

		for (int i = 0; i < 3; i++) {
			fLoc[i] = results.FetchFloat(i+1);
			fPosAng[i] = results.FetchFloat(i+4);
		}

		results.FetchString(0, sJumpName, sizeof(sJumpName));

		TeleportEntity(client, fLoc, fPosAng, fPosVec);
		PrintToChatAll("\x01[\x03JA\x01] %t", "Teleported_PlayerJump", sClientName, cLightGreen, cDefault, sJumpName, cLightGreen, cDefault);
	}
	else {
		PrintToChat(client, "\x01[\x03JA\x01] %t", "Teleports_NoneFound");
	}
}

public void SQL_OnJumpList(Database db, DBResultSet results, const char[] error, any Data) {
	int client = Data, count = 1;

	if (db == null) {
		LogError("OnJumpList() - Query failed! %s", error);
	}
	else if (results.RowCount) {
		int g_iJumps = results.RowCount;
		char menuItem[MAX_NAME_LENGTH];
		char g_sMenuItemName[MAX_NAME_LENGTH];
		char g_sTempStorage[MAX_NAME_LENGTH];

		// Create the menu
		Menu g_hMenu = new Menu(JumpListHandler);
		g_hMenu.SetTitle("%t", "Found_Jumps", g_iJumps);

		for (int i = 1; i <= g_iJumps; i++) {
			results.FetchRow();
			results.FetchString(0, g_sTempStorage, sizeof(g_sTempStorage));
			Format(menuItem, sizeof(menuItem), "%s", g_sTempStorage);
			Format(g_sMenuItemName, sizeof(g_sMenuItemName), "%s", g_sTempStorage);
			g_hMenu.AddItem(menuItem, g_sMenuItemName);
			//LogMessage("Processing %s %i of %i", g_sJump[count], count, g_iJumps);
			count++;
		}
		g_hMenu.Display(client, MENU_TIME_FOREVER);
	}
	else {
		PrintToChat(client, "\x01[\x03JA\x01] %t", "Teleports_NoneFound");
	}
}

public void SQL_OnSendToLocation(Database db, DBResultSet results, const char[] error, any data) {
	int client = data;

	if (db == null) {
		LogError("OnSendToLocaton() - Query failed! %s", error);
	}
	else if (results.RowCount) {
		float fLoc[3];
		float fPosVec[3];
		float fPosAng[3];
		char sJumpName[MAX_NAME_LENGTH];
		char sClientName[MAX_NAME_LENGTH];

		for (int i = 0; i < 3; i++) {
			fLoc[i] = results.FetchFloat(i+1);
			fPosAng[i] = results.FetchFloat(i+4);
		}

		results.FetchString(0, sJumpName, sizeof(sJumpName));

		TeleportEntity(client, fLoc, fPosAng, fPosVec);
		GetClientName(client, sClientName, sizeof(sClientName));
		PrintToChatAll("\x01[\x03JA\x01] %t", "Teleport_Send", sClientName, cLightGreen, cDefault, sJumpName, cLightGreen, cDefault);
	}
	else {
		PrintToChat(client, "\x01[\x03JA\x01] %t", "Teleports_NoMatch");
	}
}

public void SQL_OnDefaultCallback(Database db, DBResultSet results, const char[] error, any data) {
	if (db == null) {
		LogError("OnDefaultCallback() - Query failed! %s", error);
	}
}

public void SQL_OnReloadPlayerData(Database db, DBResultSet results, const char[] error, any data) {
	int client = data;

	if (db == null) {
		LogError("OnreloadPlayerData() - Query failed! %s", error);
	}
	else if (results.RowCount) {
		results.FetchRow();
		for (int i = i; i < 3; i++) {
			g_fOrigin[client][i] = results.FetchFloat(i);
			g_fAngles[client][i] = results.FetchFloat(i+3);
		}

		results.FetchString(6, g_sCaps[client], sizeof(g_sCaps));

		// if (g_bUsedReset[client]) {
			// if (g_sCaps[client] != -1) {
				// int len = strlen(g_sCaps[client]);
				// for (int i = 0; i <= len; i++) {
					//g_bCPTouched[client][i] = true;
					//g_iCPsTouched[client]++;
				// }
			// }
		// }
		g_bUsedReset[client] = false;
	}
}

public void SQL_OnLoadPlayerData(Database db, DBResultSet results, const char[] error, any data) {
	int client = data;
	if (db == null) {
		LogError("OnLoadPlayerData() - Query failed! %s", error);
	}
	else if (results.RowCount) {
		results.FetchRow();
		for (int i = 0; i < 3; i++) {
			g_fOrigin[client][i] = results.FetchFloat(i);
			g_fAngles[client][i] = results.FetchFloat(i+3);
		}

		results.FetchString(6, g_sCaps[client], sizeof(g_sCaps));

		// if (g_sCaps[client] != -1) {
			// int len = strlen(g_sCaps[client]);
			// for (int i = 0; i <= len; i++) {
				// g_bCPTouched[client][i] = true; TURNING OFF HTESE LINES FOR NOW
				// g_iCPsTouched[client]++;
			// }
		// }
		if (!g_bHardcore[client] && !IsClientRacing(client) && g_iSpeedrunStatus[client] == 0) {
			Teleport(client);
			g_iLastTeleport[client] = RoundFloat(GetEngineTime());
		}
	}
}

public void SQL_OnDeletePlayerData(Database db, DBResultSet results, const char[] error, any data) {
	int client = data;
	int team = GetClientTeam(client);
	int class = view_as<int>(TF2_GetPlayerClass(client));

	if (db == null) {
		LogError("OnDeletePlayerData() - Query failed! %s", error);
	}
	else if (results.RowCount) {
		char query[256];
		char steamid[64];
		char mapName[32];

		GetClientAuthId(client, AuthId_Steam2, steamid, sizeof(steamid));
		GetCurrentMap(mapName, sizeof(mapName));

		g_hDatabase.Format(
			  query
			, sizeof(query)
			, "DELETE FROM player_saves "
			... "WHERE steamID = '%s' "
			... "AND playerTeam = '%i' "
			... "AND playerClass = '%i' "
			... "AND playerMap = '%s'"
			, steamid
			, team
			, class
			, mapName
		);
		g_hDatabase.Query(SQL_OnDefaultCallback, query, client, DBPrio_High);

		g_bBeatTheMap[client] = false;

		//TF2_RespawnPlayer(client);
		//PrintToChat(client, "\x01[\x03JA\x01] %t", "Player_Restarted");
		return;
	}
	else {
		g_bBeatTheMap[client] = false;
		EraseLocs(client);
		//TF2_RespawnPlayer(client);
		//PrintToChat(client, "\x01[\x03JA\x01] %t", "Player_Restarted");
	}
}

public void SQL_OnGetPlayerData(Database db, DBResultSet results, const char[] error, any data) {
	if (db == null) {
		LogError("OnGetPlayerData() - Query failed! %s", error);
		return;
	}
	int client = data;
	if (results.RowCount) {
		UpdatePlayerData(client);
	}
	else {
		SavePlayerData(client);
	}
}

public void SQL_OnTeleportAdded(Database db, DBResultSet results, const char[] error, any data) {
	if (db == null) {
		LogError("OnTeleportAdded() - Query failed! %s", error);
		return;
	}
	int client = data;
	if (results.RowCount) {
		PrintToChat(client, "\x01[\x03JA\x01] %t", "AddTele_Failed");
	}
	else {
		PrintToChat(client, "\x01[\x03JA\x01] %t", "AddTele_Success");
	}
}

void GetPlayerData(int client) {
	char query[256];
	char steamid[64];
	char mapName[32];

	GetClientAuthId(client, AuthId_Steam2, steamid, sizeof(steamid));
	GetCurrentMap(mapName, sizeof(mapName));

	int team = GetClientTeam(client);
	int class = view_as<int>(TF2_GetPlayerClass(client));

	g_hDatabase.Format(
		  query
		, sizeof(query)
		, "SELECT * FROM `player_saves` "
		... "WHERE steamID = '%s' "
		... "AND playerTeam = '%i' "
		... "AND playerClass = '%i' "
		... "AND playerMap = '%s'"
		, steamid
		, team
		, class
		, mapName
	);

	g_hDatabase.Query(SQL_OnGetPlayerData, query, client);
}

void SavePlayerData(int client) {
	if (IsFakeClient(client)) {
		return;
	}
	char query[1024];
	char steamid[64];
	char mapName[64];

	GetClientAuthId(client, AuthId_Steam2, steamid, sizeof(steamid));
	GetCurrentMap(mapName, sizeof(mapName));

	int team = GetClientTeam(client);
	int class = view_as<int>(TF2_GetPlayerClass(client));
	float SavePos1[MAXPLAYERS+1][3];
	float SavePos2[MAXPLAYERS+1][3];

	GetClientAbsOrigin(client, SavePos1[client]);
	GetClientAbsAngles(client, SavePos2[client]);
	g_hDatabase.Format(
		  query
		, sizeof(query)
		, "INSERT INTO `player_saves` "
		... "VALUES"
		... "("
			... "null, "
			... "'%s', " // steamid
			... "'%i', " // class
			... "'%i', " // team
			... "'%s', " // mapName
			... "'%f', " // SavePos1 0
			... "'%f', " // SavePos1 1
			... "'%f', " // SavePos1 2
			... "'%f', " // SavePos2 0
			... "'%f', " // SavePos2 1
			... "'%f', " // SavePos2 2
			... "'%s'"
		... ")"
		, steamid
		, class
		, team
		, mapName
		, SavePos1[client][0]
		, SavePos1[client][1]
		, SavePos1[client][2]
		, SavePos2[client][0]
		, SavePos2[client][1]
		, SavePos2[client][2]
		, g_sCaps[client]
	);

	SavePos1[client] = NULL_VECTOR;
	SavePos2[client] = NULL_VECTOR;

	g_hDatabase.Query(SQL_OnDefaultCallback, query, client);
}

void UpdatePlayerData(int client) {
	char query[1024];
	char steamid[64];
	char mapName[64];

	GetClientAuthId(client, AuthId_Steam2, steamid, sizeof(steamid));
	GetCurrentMap(mapName, sizeof(mapName));

	int team = GetClientTeam(client);
	int class = view_as<int>(TF2_GetPlayerClass(client));

	float SavePos1[MAXPLAYERS+1][3];
	float SavePos2[MAXPLAYERS+1][3];

	GetClientAbsOrigin(client, SavePos1[client]);
	GetClientAbsAngles(client, SavePos2[client]);

	g_hDatabase.Format(
		query
		, sizeof(query)
		, "UPDATE `player_saves` "
		... "SET "
			... "save1 = '%f', " // SavePos1 0
			... "save2 = '%f', " // SavePos1 1
			... "save3 = '%f', " // SavePos1 2
			... "save4 = '%f', " // SavePos2 0
			... "save5 = '%f', " // SavePos2 1
			... "save6 = '%f', " // SavePos2 2
			... "Capped = '%s' " // g_sCaps
		... "WHERE steamID = '%s' " // steamid
		... "AND playerTeam = '%i' " // team
		... "AND playerClass = '%i' " // class
		... "AND playerMap = '%s'" // mapName
		, SavePos1[client][0]
		, SavePos1[client][1]
		, SavePos1[client][2]
		, SavePos2[client][0]
		, SavePos2[client][1]
		, SavePos2[client][2]
		, g_sCaps[client]
		, steamid
		, team
		, class
		, mapName
	);

	SavePos1[client] = NULL_VECTOR;
	SavePos2[client] = NULL_VECTOR;

	g_hDatabase.Query(SQL_OnDefaultCallback, query, client);
}

void DeletePlayerData(int client) {
	char query[1024];
	char steamid[64];
	char mapName[32];

	GetClientAuthId(client, AuthId_Steam2, steamid, sizeof(steamid));
	GetCurrentMap(mapName, sizeof(mapName));

	int team = GetClientTeam(client);
	int class = view_as<int>(TF2_GetPlayerClass(client));

	g_hDatabase.Format(
		query
		, sizeof(query)
		, "DELETE FROM player_saves "
		... "WHERE steamID = '%s' "
		... "AND playerTeam = '%i' "
		... "AND playerClass = '%i' "
		... "AND playerMap = '%s'"
		, steamid
		, team
		, class
		, mapName
	);

	g_hDatabase.Query(SQL_OnDeletePlayerData, query, client);
}

void ReloadPlayerData(int client) {
	if (IsFakeClient(client)) {
		return;
	}
	char query[1024];
	char steamid[64];
	char mapName[32];

	GetClientAuthId(client, AuthId_Steam2, steamid, sizeof(steamid));
	GetCurrentMap(mapName, sizeof(mapName));

	int team = GetClientTeam(client);
	int class = view_as<int>(TF2_GetPlayerClass(client));

	g_hDatabase.Format(
		  query
		, sizeof(query)
		, "SELECT save1, save2, save3, save4, save5, save6, capped "
		... "FROM player_saves "
		... "WHERE steamID = '%s' "
		... "AND playerTeam = '%i' "
		... "AND playerClass = '%i' "
		... "AND playerMap = '%s'"
		, steamid
		, team
		, class
		, mapName
	);
	//PrintToServer(steamid);
	g_hDatabase.Query(SQL_OnReloadPlayerData, query, client, DBPrio_High);
}

void LoadPlayerData(int client) {
	if (IsFakeClient(client)) {
		return;
	}
	char query[1024];
	char steamid[32];
	char mapName[32];

	GetClientAuthId(client, AuthId_Steam2, steamid, sizeof(steamid));
	GetCurrentMap(mapName, sizeof(mapName));

	int team = GetClientTeam(client);
	int class = view_as<int>(TF2_GetPlayerClass(client));

	g_hDatabase.Format(
		query
		, sizeof(query)
		, "SELECT save1, save2, save3, save4, save5, save6, capped "
		... "FROM player_saves "
		... "WHERE steamID = '%s' "
		... "AND playerTeam = '%i' "
		... "AND playerClass = '%i' "
		... "AND playerMap = '%s'"
		, steamid
		, team
		, class
		, mapName
	);
	//PrintToServer(sSteamID);
	g_hDatabase.Query(SQL_OnLoadPlayerData, query, client, DBPrio_High);
}

void LoadPlayerProfile(int client, char[] steamid) {
	if (!IsValidClient(client)) {
		return;
	}
	char query[1024];

	g_hDatabase.Format(query, sizeof(query), "SELECT * FROM `player_profiles` WHERE SteamID = '%s'", steamid);

	if (g_hDatabase != null) {
		g_hDatabase.Query(SQL_OnLoadPlayerProfile, query, client);
	}
	else {
		g_bHPRegen[client] = false;
		g_bAmmoRegen[client] = false;
		g_bHardcore[client] = false;
		g_bLoadedPlayerSettings[client] = true;
	}
}

void JumpList(int client) {
	char query[1024];
	char currentMap[32];
	GetCurrentMap(currentMap, sizeof(currentMap));

	g_hDatabase.Format(
		  query
		, sizeof(query)
		, "SELECT TeleName, L1, L2, L3 "
		... "FROM `Teleports` "
		... "WHERE MapName = '%s' "
		... "ORDER BY TeleName*1"
		, currentMap
	);
	g_hDatabase.Query(SQL_OnJumpList, query, client);
}

void MenuSendToLocation(int client, char[] ClientName, char[] Jump) {
	char query[1024];
	char currentMap[32];
	GetCurrentMap(currentMap, sizeof(currentMap));

	int target = FindTarget2(client, ClientName, true, false);

	g_hDatabase.Format(
		query
		, sizeof(query)
		, "SELECT TeleName, L1, L2, L3, A1, A2, A3 "
		... "FROM `Teleports` "
		... "WHERE MapName = '%s' "
		... "AND TeleName = '%s'"
		, currentMap
		, Jump
	);
	g_hDatabase.Query(SQL_OnMenuSendToLocation, query, target);
}

void CreateMapCFG() {
	char mapName[64];
	char query[1024];
	GetCurrentMap(mapName, sizeof(mapName));

	g_hDatabase.Format(query, sizeof(query), "INSERT INTO `map_settings` values(null, '%s', '1', '1', '-1')", mapName);
	g_hDatabase.Query(SQL_OnDefaultCallback, query);
	g_iForceTeam = 1;
	g_iMapClass = -1;
	g_iLockCPs = 1;
}

void LoadMapCFG() {
	char mapName[64];
	char query[1024];
	GetCurrentMap(mapName, sizeof(mapName));
	g_hDatabase.Format(query, sizeof(query), "SELECT Team, LockCPs, Class FROM `map_settings` WHERE Map = '%s'", mapName);
	g_hDatabase.Query(SQL_OnMapSettingsLoad, query);
}

void CreatePlayerProfile(int client, char[] steamid) {
	char query[1024];
	g_hDatabase.Format(
		query
		, sizeof(query)
		, "INSERT INTO `player_profiles` "
		... "VALUES"
		... "("
			... "null, "
			... "'%s', "
			... "'0', "
			... "'0', "
			... "'0', "
			... "'90', "
			... "'255', "
			... "'255', "
			... "'255'"
		... ")"
		, steamid
	);
	g_hDatabase.Query(SQL_OnCreatePlayerProfile, query, client);
}

public Action cmdAddTele(int client, int args) {
	if (g_hDatabase == null) {
		PrintToChat(client, "This feature is not supported without a database configuration");
		return Plugin_Handled;
	}
	if (args < 1) {
		PrintToChat(client, "\x01[\x03JA\x01] %t", "AddTele_Help");
		return Plugin_Handled;
	}
	char jumpName[32];
	char query[1024];
	char mapName[32];
	float location[3];
	float angles[3];

	GetClientAbsOrigin(client, location);
	GetClientAbsAngles(client, angles);
	GetCmdArg(1, jumpName, sizeof(jumpName));
	GetCurrentMap(mapName, sizeof(mapName));

	g_hDatabase.Format(
		  query
		, sizeof(query)
		, "INSERT Into `Teleports` "
		... "VALUES"
		... "("
			... "null, "
			... "'%s', " // mapName
			... "'%s', " // jumpName
			... "'%f', " // location[0]
			... "'%f', " // location[1]
			... "'%f', " // location[2]
			... "'%f', " // angles[0]
			... "'%f', " // angles[1]
			... "'%f'" // angles[2]
		... ")"
		, mapName
		, jumpName
		, location[0]
		, location[1]
		, location[2]
		, angles[0]
		, angles[1]
		, angles[2]
	);
	g_hDatabase.Query(SQL_OnTeleportAdded, query, client);
	return Plugin_Handled;
}

public Action SendToLocation(int client, int args) {
	if (g_hDatabase == null) {
		PrintToChat(client, "This feature is not supported without a database configuration");
		return Plugin_Handled;
	}
	if (cvarPluginEnabled.BoolValue) {
		if (args < 2) {
			Menu menu = new Menu(jteleHandler);
			menu.SetTitle("%t", "Pick_Client");
			for (int i = 0; i < MaxClients; i++) {
				if (i > 0) {
					if (IsClientInGame(i) && !IsClientObserver(i) && !IsFakeClient(i)) {
						char clientname[MAX_NAME_LENGTH];
						GetClientName(i, clientname, sizeof(clientname));
						menu.AddItem(clientname, clientname);
					}
				}
			}
			menu.Display(client, MENU_TIME_FOREVER);
			return Plugin_Handled;
		}
		char query[1024];
		char currentMap[32];
		char arg1[MAX_NAME_LENGTH];
		char arg2[MAX_NAME_LENGTH];

		GetCurrentMap(currentMap, sizeof(currentMap));
		GetCmdArg(1, arg1, sizeof(arg1));
		GetCmdArg(2, arg2, sizeof(arg2));

		int target = FindTarget2(client, arg1, true, false);

		if (target == -1) {
			return Plugin_Handled;
		}
		Format(query, sizeof(query), "SELECT TeleName, L1, L2, L3, A1, A2, A3 FROM `Teleports` WHERE MapName = '%s' AND TeleName = '%s'", currentMap, arg2[0]);

		g_hDatabase.Query(SQL_OnSendToLocation, query, target);
	}
	return Plugin_Handled;
}

public Action cmdSetMy(int client, int args) {
	if (g_hDatabase == null) {
		PrintToChat(client, "This feature is not supported without a database configuration");
		return Plugin_Handled;
	}
	if (!cvarPluginEnabled.BoolValue) {
		return Plugin_Handled;
	}
	if (args < 1) {
		PrintToChat(client, "\x01[\x03JA\x01] %t", "SetMy_Help");
		return Plugin_Handled;
	}
	char arg1[MAX_NAME_LENGTH];
	char arg2[MAX_NAME_LENGTH];
	char steamid[32];
	GetClientAuthId(client, AuthId_Steam2, steamid, sizeof(steamid));
	GetCmdArg(1, arg1, sizeof(arg1)), GetCmdArg(2, arg2, sizeof(arg2));

	if (StrEqual(arg1, "hardcore", false)) {
		if (IsClientInGame(client) && !IsFakeClient(client)) {
			char query[1024];

			if (IsUsingJumper(client)) {
				PrintToChat(client, "\x01[\x03JA\x01] %t", "Jumper_Command_Disabled");
				return Plugin_Handled;
			}
			if (StrEqual(arg2, "off", false)) {
				Format(query, sizeof(query), "UPDATE `player_profiles` SET Health=0, Ammo=0, Hardcore=0 WHERE SteamID = '%s'", steamid);
				g_hDatabase.Query(SQL_OnSetMy, query, client);
				g_bHardcore[client] = false;
				g_bHPRegen[client] = false;
				g_bAmmoRegen[client] = false;
			}
			else if (StrEqual(arg2, "on", false)) {
				Format(query, sizeof(query), "UPDATE `player_profiles` SET Health=0, Ammo=0, Hardcore=1 WHERE SteamID = '%s'", steamid);
				g_hDatabase.Query(SQL_OnSetMy, query, client);
				g_bHardcore[client] = true;
				g_bHPRegen[client] = false;
				g_bAmmoRegen[client] = false;
			}
			else {
				PrintToChat(client, "\x01[\x03JA\x01] %t", "SetMy_Hardcore_Help");
				return Plugin_Handled;
			}
		}
	}
	else if (StrEqual(arg1, "regen", false)) {
		if (IsClientInGame(client) && !IsFakeClient(client)) {
			char query[1024];

			if (StrEqual(arg2, "off", false)) {
				Format(query, sizeof(query), "UPDATE `player_profiles` SET Health=0, Ammo=0, Hardcore=0 WHERE SteamID = '%s'", steamid);
				g_hDatabase.Query(SQL_OnSetMy, query, client);
				g_bHardcore[client] = false;
				g_bHPRegen[client] = false;
				g_bAmmoRegen[client] = false;
			}
			else if (StrEqual(arg2, "on", false)) {
				Format(query, sizeof(query), "UPDATE `player_profiles` SET Health=1, Ammo=1, Hardcore=0 WHERE SteamID = '%s'", steamid);
				g_hDatabase.Query(SQL_OnSetMy, query, client);
				g_bHardcore[client] = false;
				g_bHPRegen[client] = true;
				g_bAmmoRegen[client] = true;
			}
			else {
				PrintToChat(client, "\x01[\x03JA\x01] %t", "SetMy_Regen_Help");
				return Plugin_Handled;
			}
		}
	}
	else if (StrEqual(arg1, "ammo", false)) {
		if (IsClientInGame(client) && !IsFakeClient(client)) {
			char query[1024];

			if (StrEqual(arg2, "off", false)) {
				Format(query, sizeof(query), "UPDATE `player_profiles` SET Ammo=0, Hardcore=0 WHERE SteamID = '%s'", steamid);
				g_hDatabase.Query(SQL_OnSetMy, query, client);
				g_bHardcore[client] = false;
				g_bAmmoRegen[client] = false;
			}
			else if (StrEqual(arg2, "on", false)) {
				Format(query, sizeof(query), "UPDATE `player_profiles` SET Ammo=1, Hardcore=0 WHERE SteamID = '%s'", steamid);
				g_hDatabase.Query(SQL_OnSetMy, query, client);
				g_bHardcore[client] = false;
				g_bAmmoRegen[client] = true;
			}
			else {
				PrintToChat(client, "\x01[\x03JA\x01] %t", "SetMy_Regen_Help");
				return Plugin_Handled;
			}
		}
	}
	else if (StrEqual(arg1, "health", false)) {
		if (IsClientInGame(client) && !IsFakeClient(client)) {
			char query[1024];

			if (StrEqual(arg2, "off", false)) {
				Format(query, sizeof(query), "UPDATE `player_profiles` SET Health=0, Hardcore=0 WHERE SteamID = '%s'", steamid);
				g_hDatabase.Query(SQL_OnSetMy, query, client);
				g_bHardcore[client] = false;
				g_bHPRegen[client] = false;
			}
			else if (StrEqual(arg2, "on", false)) {
				Format(query, sizeof(query), "UPDATE `player_profiles` SET Health=1, Hardcore=0 WHERE SteamID = '%s'", steamid);
				g_hDatabase.Query(SQL_OnSetMy, query, client);
				g_bHardcore[client] = false;
				g_bHPRegen[client] = true;
			}
			else {
				PrintToChat(client, "\x01[\x03JA\x01] %t", "SetMy_Regen_Help");
				return Plugin_Handled;
			}
		}
	}
	else if (StrEqual(arg1, "fov", false)) {
		if (FindPluginByFile("fov.smx") == null) {
			PrintToChat(client, "\x01[\x03JA\x01] %t", "SetMy_FOV_NotInstalled");
			return Plugin_Handled;
		}
		char query[1024], fovcmd[12];
		if (StrEqual(arg2, "", false)) {
			PrintToChat(client, "\x01[\x03JA\x01] %t", "SetMy_FOV_Help");
			return Plugin_Handled;
		}
		if (!IsCharNumeric(arg2[0])) {
			PrintToChat(client, "\x01[\x03JA\x01] %t", "Numeric_Invalid");
			return Plugin_Handled;
		}
		Format(query, sizeof(query), "UPDATE `player_profiles` SET PlayerFOV=%i WHERE SteamID = '%s'", StringToInt(arg2), steamid);
		g_hDatabase.Query(SQL_OnSetMy, query, client);

		Format(fovcmd, sizeof(fovcmd), "sm_fov %i", StringToInt(arg2));
		FakeClientCommand(client, fovcmd);
	}
	else {
		PrintToChat(client, "\x01[\x03JA\x01] %t", "SetMy_Help");
		return Plugin_Handled;
	}
	/*
	if (StrEqual(arg1, "color", false)) {
		if (StrEqual(arg2), "", false)) {
			return Plugin_Handled;
		}
	}
	*/
	return Plugin_Handled;
}

public Action cmdMapSet(int client, int args) {
	if (g_hDatabase == null) {
		PrintToChat(client, "This feature is not supported without a database configuration");
		return Plugin_Handled;
	}
	if (!cvarPluginEnabled.BoolValue) {
		return Plugin_Handled;
	}
	if (args < 2) {
		PrintToChat(client, "\x01[\x03JA\x01] %t", "Mapset_Help");
		return Plugin_Handled;
	}
	char arg1[MAX_NAME_LENGTH];
	char arg2[MAX_NAME_LENGTH];
	char query[512];
	char mapName[64];
	GetCurrentMap(mapName, sizeof(mapName));
	int g_iTeam, g_iClass, g_iLock;

	GetCmdArg(1, arg1, sizeof(arg1)),	GetCmdArg(2, arg2, sizeof(arg2));

	if (StrEqual(arg1, "team", false)) {
		if (StrEqual(arg2, "red", false) || StrEqual(arg2, "blue", false) || StrEqual(arg2, "none", false)) {
			// Wonder if there is a prettier way of doing this.
			if (StrEqual(arg2, "red", false)) {
				g_iTeam = 2;
				g_iForceTeam = 2;
				CheckTeams();
			}
			else if (StrEqual(arg2, "blue", false)) {
				g_iTeam = 3;
				g_iForceTeam = 3;
				CheckTeams();
			}
			else if (StrEqual(arg2, "none", false)) {
				g_iTeam = 1;
				g_iForceTeam = 1;
			}
			Format(query, sizeof(query), "UPDATE `map_settings` SET Team = '%i' WHERE Map = '%s'", g_iTeam, mapName);
			g_hDatabase.Query(SQL_OnMapSettingsUpdated, query, client);
		}
		else {
			PrintToChat(client, "\x01[\x03JA\x01] %t", "Mapset_Team_Help");
			return Plugin_Handled;
		}
	}
	if (StrEqual(arg1, "class", false)) {
		g_iClass = view_as<int>(TF2_GetClass(arg2));
		if (g_iClass <= 0) {
			PrintToChat(client, "\x01[\x03JA\x01] %t", "Mapset_Class_Invalid", arg2, cLightGreen, cDefault);
			return Plugin_Handled;
		}
		g_iMapClass = g_iClass;
		Format(query, sizeof(query), "UPDATE `map_settings` SET Class = '%i' WHERE Map = '%s'", g_iClass, mapName);
		g_hDatabase.Query(SQL_OnMapSettingsUpdated, query, client);
	}
	if (StrEqual(arg1, "lockcps", false)) {
		if (StrEqual(arg2, "on", false)) {
			g_iLock = 1;
		}
		else if (StrEqual(arg2, "off", false)) {
			g_iLock = 0;
		}
		else {
			PrintToChat(client, "\x01[\x03JA\x01] %t", "Mapset_LockCP_Help");
			return Plugin_Handled;
		}
		Format(query, sizeof(query), "UPDATE `map_settings` SET LockCPs = '%i' WHERE Map = '%s'", g_iLock, mapName);
		g_hDatabase.Query(SQL_OnMapSettingsUpdated, query, client);
	}
	return Plugin_Handled;
}