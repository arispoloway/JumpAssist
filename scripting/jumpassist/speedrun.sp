float
	  g_fStartLoc[3]
	, g_fStartAng[3]
	, g_fLoc[3]
	, g_fAng[3]
	, g_fBottomLoc[3]
	, g_fTopLoc[3]
	, g_fZoneBottom[32][3]
	, g_fZoneTop[32][3]
	, g_fZoneTimes[32][32]
	, g_fRecordTime[9]
	, g_fProcessingZoneTimes[32][32];
int
	  g_iNextCheckPoint[32]
	, g_iProcessingClass[32]
	, g_iLastFrameInStartZone[32]
	, g_iBeamSprite
	, g_iHaloSprite
	, g_iNumZones = 0;
bool
	  g_bSkippedCheckPointMessage[32];
char
	  g_sMap[64];
ConVar
	  cvarSpeedrunEnabled;

enum {
	LISTING_RANKED,
	LISTING_GENERAL,
	LISTING_PLAYER
}

void processSpeedrun(int client) {
	char query[1024];
	char steamid[32];
	char endtime[4];

	GetClientAuthId(client, AuthId_Steam2, steamid, sizeof(steamid));
	Format(endtime, sizeof(endtime), "c%d", g_iNumZones-1);
	Format(query, sizeof(query), "SELECT %s FROM times WHERE SteamID='%s' AND class='%d' AND MapName='%s'", endtime, steamid, g_iProcessingClass[client], g_sMap);
	g_hDatabase.Query(SQL_OnSpeedrunCheckLoad, query, client);
}

public void SQL_OnSpeedrunCheckLoad(Database db, DBResultSet results, const char[] error, any data) {
	int client = data, datetime;
	float t;
	char query[1024];
	char steamid[32];

	GetClientAuthId(client, AuthId_Steam2, steamid, sizeof(steamid));
	datetime = GetTime();

	if (db == null) {
		LogError("OnSpeedrunCheckLoad() - Query failed! %s", error);
	}
	else if (results.RowCount) {
		results.FetchRow();
		float endTime = results.FetchFloat(0);

		if (endTime > g_fProcessingZoneTimes[client][g_iNumZones-1]-g_fProcessingZoneTimes[client][0]) {
			Format(query, sizeof(query), "UPDATE times SET time='%d',", datetime);
			for (int i = 0; i < 32; i++) {
				if (i == 0) {
					Format(query, sizeof(query), "%s c%d='%f',", query, i, 0.0);
				}
				else {
					t = g_fProcessingZoneTimes[client][i]-g_fProcessingZoneTimes[client][0];
					if (t < 0.0) {
						t = 0.0;
					}
					Format(query, sizeof(query), "%s c%d='%f'", query, i, t);
					if (i != 31) {
						Format(query, sizeof(query), "%s,", query);
					}
				}
			}
			Format(query, sizeof(query), "%s WHERE SteamID='%s' AND MapName='%s' AND class='%d';", query, steamid, g_sMap, g_iProcessingClass[client]);
			g_hDatabase.Query(SQL_OnSpeedrunSubmit, query, client);
		}
		else {
			char clientName[64];
			char message[256];
			float time = g_fProcessingZoneTimes[client][g_iNumZones-1] - g_fProcessingZoneTimes[client][0];

			GetClientName(client, clientName, sizeof(clientName));
			Format(message, sizeof(message), "\x01[\x03JA\x01] \x03%s\x01: \x05%s\x01 map run: \x04%s\x01", clientName, GetClassname(g_iProcessingClass[client]), TimeFormat(time));
			PrintToChatAll(message);
		}
	}
	else {
		Format(query, sizeof(query), "INSERT INTO times VALUES(null, '%s', '%d', '%s', '%d',", steamid, g_iProcessingClass[client], g_sMap, datetime);
		for (int i = 0; i < 32; i++) {
			if (i == 0) {
				Format(query, sizeof(query), "%s '%f',", query, 0.0);
			}
			else {
				t = g_fProcessingZoneTimes[client][i]-g_fProcessingZoneTimes[client][0];
				if (t < 0.0) {
					t = 0.0;
				}
				Format(query, sizeof(query), "%s '%f'", query, t);
				if (i != 31) {
					Format(query, sizeof(query), "%s,", query);
				}
			}
		}
		Format(query, sizeof(query), "%s);", query);
		g_hDatabase.Query(SQL_OnSpeedrunSubmit, query, client);
	}
}

public void SQL_OnSpeedrunSubmit(Handle owner, Handle hndl, const char[] error, any data) {
	int client = data;
	if (hndl == null) {
		LogError("OnSpeedrunSubmit() - Query failed! %s", error);
	}
	else {
		char clientName[64];
		char message[256];
		float time = g_fProcessingZoneTimes[client][g_iNumZones-1] - g_fProcessingZoneTimes[client][0];

		GetClientName(client, clientName, sizeof(clientName));
		if (time < g_fRecordTime[g_iProcessingClass[client]]) {
			float previousRecord = g_fRecordTime[g_iProcessingClass[client]];

			g_fRecordTime[g_iProcessingClass[client]] = time;
			if (previousRecord == 99999999.99) {
				Format(message, sizeof(message), "\x01[\x03JA\x01] \x03%s\x01 set the map record as \x05%s\x01 with time \x04%s\x01!", clientName, GetClassname(g_iProcessingClass[client]), TimeFormat(time));
			}
			else {
				Format(message, sizeof(message), "\x01[\x03JA\x01] \x03%s\x01 broke the map record as \x05%s\x01 by \x04%s\x01 with time \x04%s\x01!", clientName, GetClassname(g_iProcessingClass[client]), TimeFormat(previousRecord-time), TimeFormat(time));
			}
		}
		else {
			Format(message, sizeof(message), "\x01[\x03JA\x01] \x03%s\x01: \x05%s\x01 map run: \x04%s\x01", clientName, GetClassname(g_iProcessingClass[client]), TimeFormat(time));
		}
		PrintToChatAll(message);
	}
}

public Action cmdShowPR(int client, int args) {
	if (!cvarSpeedrunEnabled.BoolValue) {
		return Plugin_Continue;
	}
	if (g_hDatabase == null) {
		PrintToChat(client, "This feature is not supported without a database configuration");
		return Plugin_Handled;
	}
	if (!client) {
		ReplyToCommand(client, "\x01[\x03JA\x01] Cannot use this command from rcon");
		return Plugin_Handled;
	}
	if (!IsSpeedrunMap()) {
		ReplyToCommand(client, "\x01[\x03JA\x01] This map does not currently have speedrunning configured");
		return Plugin_Handled;
	}
	char query[1024];
	char steamid[32];
	char endtime[4];
	int class;

	GetClientAuthId(client, AuthId_Steam2, steamid, sizeof(steamid));
	class = (IsClientObserver(client)) ? 3 : view_as<int>(TF2_GetPlayerClass(client));

	Format(endtime, sizeof(endtime), "c%d", g_iNumZones-1);
	Format(query, sizeof(query), "SELECT MapName, SteamID, %s, class FROM times WHERE SteamID='%s' AND class='%d' AND MapName='%s'", endtime, steamid, class, g_sMap);
	g_hDatabase.Query(SQL_OnSpeedrunListingSubmit, query, client);

	return Plugin_Continue;
}

public void SQL_OnSpeedrunListingSubmit(Database db, DBResultSet results, const char[] error, any data) {
	int client = data;
	if (db == null) {
		LogError("OnSpeedrunListingSubmit() - Query failed! %s", error);
	}
	else if (results.RowCount) {
		char mapName[32];
		char steamid[32];
		char class[128];
		char timeString[128];
		char query[1024];
		char playerName[64];
		char toPrint[128];
		float time;
		DBResultSet hQuery;

		results.FetchRow();
		results.FetchString(0, mapName, sizeof(mapName));
		results.FetchString(1, steamid, sizeof(steamid));
		time = results.FetchFloat(2);
		timeString = TimeFormat(time);
		class = GetClassname(results.FetchInt(3));
		Format(query, sizeof(query), "SELECT name FROM steamids WHERE SteamID='%s'", steamid);
		SQL_LockDatabase(g_hDatabase);
		if ((hQuery = SQL_Query(g_hDatabase, query)) == null) {
			char err[256];
			SQL_GetError(hQuery, err, sizeof(err));
			Format(toPrint, sizeof(toPrint), "\x01[\x03JA\x01] An error occurred: %s", err);
		}
		else {
			hQuery.FetchRow();
			hQuery.FetchString(0, playerName, sizeof(playerName));
			Format(toPrint, sizeof(toPrint), "\x01[\x03JA\x01] \x03%s\x01: \x05%s\x01 - \x03%s\x01: \x04%s\x01", playerName, mapName, class, timeString);
		}
		SQL_UnlockDatabase(g_hDatabase);
		PrintToChat(client, toPrint);
		delete hQuery;
	}
	else {
		PrintToChat(client, "\x01[\x03JA\x01] No record exists");
	}
}

public Action cmdShowPlayerInfo(int client, int args) {
	if (!cvarSpeedrunEnabled.BoolValue) {
		return Plugin_Continue;
	}
	if (g_hDatabase == null) {
		PrintToChat(client, "This feature is not supported without a database configuration");
		return Plugin_Handled;
	}
	if (!IsSpeedrunMap()) {
		ReplyToCommand(client, "\x01[\x03JA\x01] This map does not currently have speedrunning configured");
		return Plugin_Handled;
	}
	if (!client) {
		ReplyToCommand(client, "\x01[\x03JA\x01] Cannot use this command from rcon");
		return Plugin_Handled;
	}
	char query[1024];
	char steamid[32];
	ArrayList data = new ArrayList(64);

	GetClientAuthId(client, AuthId_Steam2, steamid, sizeof(steamid));
	if (args == 0 || 1) {
		Format(query, sizeof(query), "SELECT * FROM times WHERE SteamID='%s' LIMIT 50", steamid);
		data.Push(client);
		data.Push(LISTING_PLAYER);
		data.PushString(g_sMap);
		data.Push(0);
	}
	// else {
		// TAKE THE || 1 OUT OF THE IF STATEMENT WHEN YOU IMPLIMENT THIS
	// }
	g_hDatabase.Query(SQL_OnSpeedrunMultiListingSubmit, query, data);

	return Plugin_Continue;
}

public Action cmdShowTop(int client, int args) {
	if (!cvarSpeedrunEnabled.BoolValue) {
		return Plugin_Continue;
	}
	if (g_hDatabase == null) {
		PrintToChat(client, "This feature is not supported without a database configuration");
		return Plugin_Handled;
	}
	if (!IsSpeedrunMap()) {
		ReplyToCommand(client, "\x01[\x03JA\x01] This map does not currently have speedrunning configured");
		return Plugin_Handled;
	}
	if (!client) {
		ReplyToCommand(client, "\x01[\x03JA\x01] Cannot use this command from rcon");
		return Plugin_Handled;
	}
	char query[1024];
	char endtime[4];
	int class;
	ArrayList data = new ArrayList(64);
	class = (IsClientObserver(client)) ? 3 : view_as<int>(TF2_GetPlayerClass(client));

	if (args == 0) {
		Format(endtime, sizeof(endtime), "c%d", g_iNumZones-1);
		Format(query, sizeof(query), "SELECT * FROM times WHERE class='%d' AND MapName='%s' ORDER BY %s ASC LIMIT 50", class, g_sMap, endtime);
		data.Push(client);
		data.Push(LISTING_RANKED);
		data.PushString(g_sMap);
		data.Push(class);
	}
	else {
		char arg1[128];
		char endTime[4];
		char mapName[128];
		char err[128];
		DBResultSet results;

		GetCmdArg(1, arg1, sizeof(arg1));
		mapName = GetFullMapName(arg1);
		Format(query, sizeof(query), "SELECT * FROM times WHERE MapName='%s' LIMIT 1", mapName);
		SQL_LockDatabase(g_hDatabase);
		if ((results = SQL_Query(g_hDatabase, query)) == null) {
			SQL_GetError(results, err, sizeof(err));
			char toPrint[128];
			Format(toPrint, sizeof(toPrint), "\x01[\x03JA\x01] An error occurred: %s", err);
			PrintToChat(client, toPrint);
			return Plugin_Handled;
		}
		else {
			if (results.RowCount) {
				results.FetchRow();
				int finish = GetFinishCheckpoint(results);
				Format(endTime, sizeof(endTime), "c%d", finish);
			}
			else {
				PrintToChat(client, "\x01[\x03JA\x01] No records exists");
				return Plugin_Handled;
			}
		}
		SQL_UnlockDatabase(g_hDatabase);
		Format(query, sizeof(query), "SELECT * FROM times WHERE class='%d' AND MapName='%s' ORDER BY %s ASC LIMIT 50", class, mapName, endTime);
		data.Push(client);
		data.Push(LISTING_RANKED);
		data.PushString(mapName);
		data.Push(class);
	}
	g_hDatabase.Query(SQL_OnSpeedrunMultiListingSubmit, query, data);

	return Plugin_Continue;
}

public void SQL_OnSpeedrunMultiListingSubmit(Database db, DBResultSet results, const char[] error, any data) {
	if (db == null) {
		LogError("OnSpeedrunMultiListingSubmit() - Query failed! %s", error);
		return;
	}
	//Data should be an array of [client, Listing type from enum, map, class]
	ArrayList array = view_as<ArrayList>(data);
	int client = array.Get(0);
	int multiType = array.Get(1);
	int class = array.Get(3);
	char map[64];

	array.GetString(2, map, sizeof(map));

	if (results.RowCount) {
		Menu menu = BuildMultiListingMenu(results, multiType, class, map);
		menu.Display(client, MENU_TIME_FOREVER);
	}
	else {
		PrintToChat(client, "\x01[\x03JA\x01] No records exists");
	}
	delete array;
}

float GetFinishTime(DBResultSet results) {
	for (int i = 7; i < 38; i++) {
		if (results.FetchFloat(i) == 0.0) {
			return (results.FetchFloat(i-1));
		}
	}
	return 0.0;
}

int GetFinishCheckpoint(DBResultSet results) {
	for (int i = 7; i < 38; i++) {
		if (results.FetchFloat(i) == 0.0) {
			return (i-6);
		}
	}
	return 0;
}

Menu BuildMultiListingMenu(DBResultSet resultSet, int type, int class, char[] map) {
	char mapName[32];
	char steamid[32];
	char timeString[128];
	char query[1024];
	char playerName[64];
	char toPrint[128];
	char err[256];
	char classString[128];
	char idString[16];
	char title[256];
	float time;
	DBResultSet results;
	int id;
	int listingClass;
	Menu menu = new Menu(Menu_MultiListing);

	//NOT VERY EFFICIENT WITH THE WHOLE STEAMID THING
	for (int i = 0; i < resultSet.RowCount; i++) {
		resultSet.FetchRow();
		resultSet.FetchString(3, mapName, sizeof(mapName));
		resultSet.FetchString(1, steamid, sizeof(steamid));

		time = GetFinishTime(resultSet);
		timeString = TimeFormat(time);
		id = resultSet.FetchInt(0);
		listingClass = resultSet.FetchInt(2);
		classString = GetClassname(listingClass);

		Format(idString, sizeof(idString), "%d", id);
		Format(query, sizeof(query), "SELECT name FROM steamids WHERE SteamID='%s'", steamid);

		SQL_LockDatabase(g_hDatabase);
		if ((results = SQL_Query(g_hDatabase, query)) == null) {
			SQL_GetError(results, err, sizeof(err));
			Format(toPrint, sizeof(toPrint), "\x01[\x03JA\x01] An error occurred: %s", err);
		}
		else {
			results.FetchRow();
			results.FetchString(0, playerName, sizeof(playerName));
			if (type == LISTING_RANKED) {
				Format(toPrint, sizeof(toPrint), "(%d) %s: %s", i+1, timeString, playerName);
			}
			else if (type == LISTING_GENERAL) {
				Format(toPrint, sizeof(toPrint), "%s: %s", timeString, mapName, playerName);
			}
			else if (type == LISTING_PLAYER) {
				Format(toPrint, sizeof(toPrint), "%s - [%s - %s]", timeString, mapName,  classString);
			}
		}
		SQL_UnlockDatabase(g_hDatabase);
		menu.AddItem(idString, toPrint);
	}
	delete results;

	switch (type) {
		case LISTING_RANKED: {
			classString = GetClassname(class);
			Format(title, sizeof(title), "%s - %s", map, classString);
		}
		case LISTING_PLAYER: {
			Format(title, sizeof(title), "%s", playerName);
		}
	}
	menu.SetTitle(title);

	return menu;
}

int Menu_MultiListing(Menu menu, MenuAction action, int param1, int param2) {
	if (action == MenuAction_Select) {
		char info[32];
		menu.GetItem(param2, info, sizeof(info));
		PrintToChat(param1, "You selected run ID #%s", info);
	}
}

public Action cmdShowWR(int client, int args) {
	if (!cvarSpeedrunEnabled.BoolValue) {
		return Plugin_Continue;
	}
	if (g_hDatabase == null) {
		PrintToChat(client, "This feature is not supported without a database configuration");
		return Plugin_Handled;
	}
	if (!IsSpeedrunMap()) {
		ReplyToCommand(client, "\x01[\x03JA\x01] This map does not currently have speedrunning configured");
		return Plugin_Handled;
	}
	if (!client) {
		ReplyToCommand(client, "\x01[\x03JA\x01] Cannot use this command from rcon");
		return Plugin_Handled;
	}
	char query[1024];
	char steamid[32];
	char endtime[4];
	int class;

	GetClientAuthId(client, AuthId_Steam2, steamid, sizeof(steamid));
	class = (IsClientObserver(client)) ? 3 : view_as<int>(TF2_GetPlayerClass(client));

	Format(endtime, sizeof(endtime), "c%d", g_iNumZones-1);
	Format(query, sizeof(query), "SELECT MapName, SteamID, %s, class FROM times WHERE class='%d' AND MapName='%s' ORDER BY %s ASC LIMIT 1", endtime, class, g_sMap, endtime);
	g_hDatabase.Query(SQL_OnSpeedrunListingSubmit, query, client);

	return Plugin_Continue;
}

public Action cmdSpeedrunRestart(int client, int args) {
	if (!cvarSpeedrunEnabled.BoolValue) {
		return Plugin_Continue;
	}
	if (g_hDatabase == null) {
		PrintToChat(client, "This feature is not supported without a database configuration");
		return Plugin_Handled;
	}
	if (!client) {
		ReplyToCommand(client, "\x01[\x03JA\x01] Cannot speedrun from rcon");
		return Plugin_Handled;
	}
	if (IsClientObserver(client)) {
		ReplyToCommand(client, "\x01[\x03JA\x01] Cannot speedrun as spectator");
		return Plugin_Handled;
	}
	if (!IsSpeedrunMap()) {
		ReplyToCommand(client, "\x01[\x03JA\x01] This map does not currently have speedrunning configured");
		return Plugin_Handled;
	}
	RestartSpeedrun(client);

	return Plugin_Continue;
}

public Action cmdDisableSpeedrun(int client, int args) {
	if (!cvarSpeedrunEnabled.BoolValue) {
		return Plugin_Continue;
	}
	if (g_hDatabase == null) {
		PrintToChat(client, "This feature is not supported without a database configuration");
		return Plugin_Handled;
	}
	if (!client) {
		ReplyToCommand(client, "\x01[\x03JA\x01] Cannot speedrun from rcon");
		return Plugin_Handled;
	}
	if (IsClientObserver(client)) {
		ReplyToCommand(client, "\x01[\x03JA\x01] Cannot speedrun as spectator");
		return Plugin_Handled;
	}
	if (g_iSpeedrunStatus[client]) {
		ReplyToCommand(client, "\x01[\x03JA\x01] Speedrunning disabled");
		g_iSpeedrunStatus[client] = 0;
	}
	return Plugin_Continue;
}

public Action cmdToggleSpeedrun(int client, int args) {
	if (!cvarSpeedrunEnabled.BoolValue) {
		return Plugin_Continue;
	}
	if (g_hDatabase == null) {
		PrintToChat(client, "This feature is not supported without a database configuration");
		return Plugin_Handled;
	}
	if (!client) {
		ReplyToCommand(client, "\x01[\x03JA\x01] Cannot speedrun from rcon");
		return Plugin_Handled;
	}
	if (IsClientObserver(client)) {
		ReplyToCommand(client, "\x01[\x03JA\x01] Cannot speedrun as spectator");
		return Plugin_Handled;
	}
	if (!IsSpeedrunMap()) {
		ReplyToCommand(client, "\x01[\x03JA\x01] This map does not currently have speedrunning configured");
		return Plugin_Handled;
	}
	if (g_iSpeedrunStatus[client]) {
		ReplyToCommand(client, "\x01[\x03JA\x01] Speedrunning disabled");
		g_iSpeedrunStatus[client] = 0;
	}
	else {
		ReplyToCommand(client, "\x01[\x03JA\x01] Speedrunning enabled");
		g_iSpeedrunStatus[client] = 1;
		RestartSpeedrun(client);
		g_bHPRegen[client] = false;
		g_bAmmoRegen[client] = false;
		g_bUnkillable[client] = false;
		SetEntProp(client, Prop_Data, "m_takedamage", 2, 1);
	}
	return Plugin_Continue;
}

public void RestartSpeedrun(int client) {
	float v[3];

	g_iSpeedrunStatus[client] = 2;
	for (int i = 0; i < 32; i++) {
		g_fZoneTimes[client][i] = 0.0;
	}
	g_iLastFrameInStartZone[client] = false;

	for (int i = 0; i < 3; i++) {
		ReSupply(client, g_iClientWeapons[client][i]);
	}

	int iMaxHealth = GetEntProp(GetPlayerResourceEntity(), Prop_Send, "m_iMaxHealth", _, client);
	SetEntityHealth(client, iMaxHealth);
	TeleportEntity(client, g_fStartLoc, g_fStartAng, v);
}

public Action cmdSpeedrunForceReload(int client, int args) {
	if (!cvarSpeedrunEnabled.BoolValue) {
		return Plugin_Continue;
	}
	if (g_hDatabase == null) {
		PrintToChat(client, "This feature is not supported without a database configuration");
		return Plugin_Handled;
	}
	ClearMapSpeedrunInfo();
	LoadMapSpeedrunInfo();

	return Plugin_Continue;
}

public Action cmdRemoveTime(int client, int args) {
	if (!cvarSpeedrunEnabled.BoolValue) {
		return Plugin_Continue;
	}
	if (g_hDatabase == null) {
		PrintToChat(client, "This feature is not supported without a database configuration");
		return Plugin_Handled;
	}
	if (!client) {
		ReplyToCommand(client, "\x01[\x03JA\x01] Cannot remove times from rcon");
		return Plugin_Handled;
	}
	if (IsClientObserver(client)) {
		ReplyToCommand(client, "\x01[\x03JA\x01] Cannot clear time as spectator");
		return Plugin_Handled;
	}
	char query[1024];
	char steamid[32];
	DBResultSet results;

	GetClientAuthId(client, AuthId_Steam2, steamid, sizeof(steamid));
	int class = view_as<int>(TF2_GetPlayerClass(client));
	Format(query, sizeof(query), "DELETE FROM times WHERE MapName='%s' AND SteamID='%s' AND class='%d'", g_sMap, steamid, class);
	SQL_LockDatabase(g_hDatabase);
	if ((results = SQL_Query(g_hDatabase, query)) == null) {
		char err[256];
		SQL_GetError(results, err, sizeof(err));
		PrintToChat(client, "\x01[\x03JA\x01] An error occurred: %s", err);
	}
	SQL_UnlockDatabase(g_hDatabase);
	char classString[128];
	classString = GetClassname(class);
	PrintToChat(client, "\x01[\x03JA\x01] %s time cleared", classString);

	return Plugin_Continue;
}

public Action cmdClearTimes(int client, int args) {
	if (!cvarSpeedrunEnabled.BoolValue) {
		return Plugin_Continue;
	}
	if (g_hDatabase == null) {
		PrintToChat(client, "This feature is not supported without a database configuration");
		return Plugin_Handled;
	}
	if (!client) {
		ReplyToCommand(client, "\x01[\x03JA\x01] Cannot clear times from rcon");
		return Plugin_Handled;
	}
	char query[1024];
	DBResultSet results;

	Format(query, sizeof(query), "DELETE FROM times WHERE MapName='%s'", g_sMap);
	SQL_LockDatabase(g_hDatabase);
	if ((results = SQL_Query(g_hDatabase, query)) == null) {
		char err[256];
		SQL_GetError(results, err, sizeof(err));
		PrintToChat(client, "\x01[\x03JA\x01] An error occurred: %s", err);
	}
	SQL_UnlockDatabase(g_hDatabase);
	for (int i = 0; i < 9; i++) {
		g_fRecordTime[i] = 99999999.99;
	}
	for (int i = 0; i < 32; i++) {
		if (g_fZoneTimes[i][g_iNumZones-1] != 0.0) {
			for (int j = 32; j < 32; j++) {
				g_fZoneTimes[i][j] = 0.0;
			}
		}
	}
	PrintToChat(client, "\x01[\x03JA\x01] All times cleared");

	return Plugin_Continue;
}

public Action cmdClearZones(int client, int args) {
	if (!cvarSpeedrunEnabled.BoolValue) {
		return Plugin_Continue;
	}
	if (g_hDatabase == null) {
		PrintToChat(client, "This feature is not supported without a database configuration");
		return Plugin_Handled;
	}
	if (!client) {
		ReplyToCommand(client, "\x01[\x03JA\x01] Cannot clear zones from rcon");
		return Plugin_Handled;
	}
	char query[1024];
	DBResultSet results;

	Format(query, sizeof(query), "DELETE FROM times WHERE MapName='%s'", g_sMap);
	SQL_LockDatabase(g_hDatabase);
	if ((results = SQL_Query(g_hDatabase, query)) == null) {
		char err[256];
		SQL_GetError(results, err, sizeof(err));
		PrintToChat(client, "\x01[\x03JA\x01] An error occurred: %s", err);
	}
	SQL_UnlockDatabase(g_hDatabase);
	for (int i = 0; i < 9; i++) {
		g_fRecordTime[i] = 99999999.99;
	}
	if (g_iNumZones) {
		for (int i = 0; i < 32; i++) {
			if (g_fZoneTimes[i][g_iNumZones-1] != 0.0) {
				for (int j = 32; j < 32; j++) {
					g_fZoneTimes[i][j] = 0.0;
				}
			}
		}
	}
	Format(query, sizeof(query), "DELETE FROM zones WHERE MapName='%s'", g_sMap);
	SQL_LockDatabase(g_hDatabase);
	if ((results = SQL_Query(g_hDatabase, query)) == null) {
		char err[256];
		SQL_GetError(results, err, sizeof(err));
		PrintToChat(client, "\x01[\x03JA\x01] An error occurred: %s", err);
	}
	SQL_UnlockDatabase(g_hDatabase);
	for (int i = 0; i < 32; i++) {
		g_fZoneBottom[i] = NULL_VECTOR;
		g_fZoneTop[i] = NULL_VECTOR;
	}
	g_iNumZones = 0;
	PrintToChat(client, "\x01[\x03JA\x01] All zones cleared");

	return Plugin_Continue;
}

public Action cmdShowZones(int client, int args) {
	if (!cvarSpeedrunEnabled.BoolValue) {
		return Plugin_Continue;
	}
	if (g_hDatabase == null) {
		PrintToChat(client, "This feature is not supported without a database configuration");
		return Plugin_Handled;
	}
	if (!client) {
		ReplyToCommand(client, "\x01[\x03JA\x01] Cannot show zones from rcon");
		return Plugin_Handled;
	}
	if (IsClientObserver(client)) {
		ReplyToCommand(client, "\x01[\x03JA\x01] Cannot show zones as spectator");
		return Plugin_Handled;
	}
	for (int i = 0; i < g_iNumZones; i++) {
		ShowZone(client, i);
	}
	ReplyToCommand(client, "\x01[\x03JA\x01] Showing all zones");

	return Plugin_Continue;
}

public Action cmdShowZone(int client, int args) {
	if (!cvarSpeedrunEnabled.BoolValue) {
		return Plugin_Continue;
	}
	if (g_hDatabase == null) {
		PrintToChat(client, "This feature is not supported without a database configuration");
		return Plugin_Handled;
	}
	if (!client) {
		ReplyToCommand(client, "\x01[\x03JA\x01] Cannot show zones from rcon");
		return Plugin_Handled;
	}
	if (IsClientObserver(client)) {
		ReplyToCommand(client, "\x01[\x03JA\x01] Cannot show zones as spectator");
		return Plugin_Handled;
	}
	bool foundZone;
	for (int i = 0; i < g_iNumZones; i++) {
		if (IsInZone(client, i)) {
			ShowZone(client, i);
			if (i == 0) {
				ReplyToCommand(client, "\x01[\x03JA\x01] Showing \x05Start\x01 zone");
			}
			else if (i == g_iNumZones-1) {
				ReplyToCommand(client, "\x01[\x03JA\x01] Showing \x05Finish\x01 zone");
			}
			else {
				ReplyToCommand(client, "\x01[\x03JA\x01] Showing checkpoint \x05%d\x01", i);
			}
			foundZone = true;
			break;
		}
	}
	if (!foundZone) {
		ReplyToCommand(client, "\x01[\x03JA\x01] You are not in a zone");
	}

	return Plugin_Continue;
}

void SpeedrunOnGameFrame() {
	for (int i = 0; i < 32; i++) {
		if (g_iSpeedrunStatus[i] == 1) {
			for (int j = 0; j < g_iNumZones; j++) {
				if (IsInZone(i, j) && g_fZoneTimes[i][j] == 0.0 && j != 0 && j == g_iNextCheckPoint[i]) {
					g_fZoneTimes[i][j] = GetEngineTime();
					if (j != g_iNumZones-1) {
						char timeString[128];
						timeString = TimeFormat(g_fZoneTimes[i][j] - g_fZoneTimes[i][0]);
						PrintToChat(i, "\x01[\x03JA\x01] \x01\x04Checkpoint %d\x01: %s", j, timeString);
						g_iNextCheckPoint[i]++;
					}
					else {
						char timeString[128];
						timeString = TimeFormat(g_fZoneTimes[i][j] - g_fZoneTimes[i][0]);
						PrintToChat(i, "\x01[\x03JA\x01] Finished in %s", timeString);
						g_iSpeedrunStatus[i] = 2;
						g_iProcessingClass[i] = view_as<int>(TF2_GetPlayerClass(i));
						g_fProcessingZoneTimes[i] = g_fZoneTimes[i];
						processSpeedrun(i);
					}
					g_bSkippedCheckPointMessage[i] = false;
				}
				else if (!g_bSkippedCheckPointMessage[i] && j > g_iNextCheckPoint[i] && IsInZone(i, j)) {
					PrintToChat(i, "\x01[\x03JA\x01] You skipped \x01\x04Checkpoint %d\x01!", g_iNextCheckPoint[i]);
					g_bSkippedCheckPointMessage[i] = true;
				}
				if (!IsInZone(i, 0) && g_iLastFrameInStartZone[i]) {
					for (int h = 0; h < 32; h++) {
						g_fZoneTimes[i][h] = 0.0;
					}
					PrintToChat(i, "\x01[\x03JA\x01] Speedrun started");
					g_iNextCheckPoint[i] = 1;
					g_bSkippedCheckPointMessage[i] = false;
					g_fZoneTimes[i][j] = GetEngineTime();
				}
				if (IsInZone(i, 0)) {
					g_iLastFrameInStartZone[i] = true;
				}
				else {
					g_iLastFrameInStartZone[i] = false;
				}
			}
		}
		else if (g_iSpeedrunStatus[i]==2) {
			if (IsInZone(i, 0)) {
				g_iSpeedrunStatus[i] = 1;
				PrintToChat(i, "\x01[\x03JA\x01] Entered start zone");
			}
		}
	}
}

public Action ClearMapSpeedrunInfo() {
	for (int i = 0; i < 32; i++) {
		g_fZoneBottom[i] = NULL_VECTOR;
		g_fZoneTop[i] = NULL_VECTOR;
		for (int j = 0; j < 32; j++) {
			g_fZoneTimes[i][j] = 0.0;
			g_fProcessingZoneTimes[i][j] = 0.0;
		}
		g_iProcessingClass[i] = 0;
		g_iLastFrameInStartZone[i] = false;
		g_iSpeedrunStatus[i] = 0;
	}
	for (int j = 0; j < 9; j++) {
		g_fRecordTime[j] = 99999999.99;
	}
	g_iNumZones = 0;
	g_fStartLoc = NULL_VECTOR;
	g_fStartAng = NULL_VECTOR;
}

public Action LoadMapSpeedrunInfo() {
	char query[1024] = "";

	ClearMapSpeedrunInfo();
	GetCurrentMap(g_sMap, sizeof(g_sMap));
	Format(query, sizeof(query), "SELECT x, y, z, xang, yang, zang FROM startlocs WHERE MapName='%s'", g_sMap);
	g_hDatabase.Query(SQL_OnMapStartLocationLoad, query, 0);
	Format(query, sizeof(query), "SELECT x1, y1, z1, x2, y2, z2 FROM zones WHERE MapName='%s' ORDER BY 'number' ASC", g_sMap);
	g_hDatabase.Query(SQL_OnMapZonesLoad, query, 0);
}

public void SQL_OnMapZonesLoad(Database db, DBResultSet results, const char[] error, any data) {
	if (db == null) {
		LogError("OnMapZonesLoad() - Query failed! %s", error);
	}
	else if (results.RowCount) {
		int numRows = results.RowCount;
		g_iNumZones = 0;
		for (g_iNumZones = 0; g_iNumZones < numRows; g_iNumZones++) {
			results.FetchRow();
			for (int i = 0; i < 3; i++) {
				g_fZoneBottom[g_iNumZones][i] = results.FetchFloat(i);
				g_fZoneTop[g_iNumZones][i] = results.FetchFloat(i+3);
			}
		}
		char query[1024] = "";
		for (int i = 0; i < 9; i++) {
			Format(query, sizeof(query), "SELECT c%d FROM times WHERE MapName='%s' AND class='%d' ORDER BY c%d ASC LIMIT 1", g_iNumZones-1, g_sMap, i, g_iNumZones-1);
			g_hDatabase.Query(SQL_OnRecordLoad, query, i);
		}
	}
	// else { }
}

public void SQL_OnRecordLoad(Database db, DBResultSet results, const char[] error, any data) {
	int class = data;

	if (db == null) {
		LogError("OnRecordLoad() - Query failed! %s", error);
	}
	else if (results.RowCount) {
		results.FetchRow();
		float t = results.FetchFloat(0);
		if (t != 0.0) {
			g_fRecordTime[class] = t;
		}
	}
	// else { }
}

public void SQL_OnMapStartLocationLoad(Database db, DBResultSet results, const char[] error, any data) {
	if (db == null) {
		LogError("OnMapStartLocationLoad() - Query failed! %s", error);
	}
	else if (results.RowCount) {
		results.FetchRow();
		for (int i = 0; i < 3; i++) {
			g_fStartLoc[i] = results.FetchFloat(i);
			g_fStartAng[i] = results.FetchFloat(i+3);
		}
	}
	// else { }
}

public Action cmdAddZone(int client, int args) {
	if (!cvarSpeedrunEnabled.BoolValue) {
		return Plugin_Continue;
	}
	if (g_hDatabase == null) {
		PrintToChat(client, "This feature is not supported without a database configuration");
		return Plugin_Handled;
	}
	if (!client) {
		ReplyToCommand(client, "\x01[\x03JA\x01] Cannot setup corners from rcon");
		return Plugin_Handled;
	}
	if (IsClientObserver(client)) {
		ReplyToCommand(client, "\x01[\x03JA\x01] Cannot setup corners as spectator");
		return Plugin_Handled;
	}
	if (g_iNumZones == 32) {
		ReplyToCommand(client, "\x01[\x03JA\x01] Maximum zone count reached");
		return Plugin_Handled;
	}
	float start[3];
	float angle[3];
	float loc[3];

	GetClientEyePosition(client, start);
	GetClientEyeAngles(client, angle);
	TR_TraceRayFilter(start, angle, MASK_SOLID, RayType_Infinite, TraceEntityFilterPlayer, client);
	if (TR_DidHit(null)) {
		TR_GetEndPosition(loc, null);
	}
	if (loc[0] == 0.0) {
		ReplyToCommand(client, "\x01[\x04JT\x01] Invalid location");
		return Plugin_Handled;
	}
	if (g_fBottomLoc[0] == 0.0 && g_fTopLoc[0] == 0.0) {
		g_fBottomLoc = loc;
	}
	else {
		if (loc[2] < g_fBottomLoc[2]) {
			g_fTopLoc = g_fBottomLoc;
			g_fBottomLoc = loc;
		}
		else {
			g_fTopLoc = loc;
		}
		char query[1024];

		Format(query, sizeof(query), "INSERT INTO zones VALUES (null, '%d', '%s', '%f', '%f', '%f', '%f', '%f', '%f')", g_iNumZones, g_sMap, g_fBottomLoc[0], g_fBottomLoc[1], g_fBottomLoc[2], g_fTopLoc[0], g_fTopLoc[1], g_fTopLoc[2]);
		g_fZoneBottom[g_iNumZones] = g_fBottomLoc;
		g_fZoneTop[g_iNumZones] = g_fTopLoc;
		g_fBottomLoc = NULL_VECTOR;
		g_fTopLoc = NULL_VECTOR;
		g_hDatabase.Query(SQL_OnZoneAdded, query, client);
	}
	ReplyToCommand(client, "\x01[\x03JA\x01] Corner successfully selected");

	return Plugin_Continue;
}

public void SQL_OnZoneAdded(Handle owner, Handle hndl, const char[] error, any data) {
	int client = data;
	if (hndl == null) {
		LogError("OnCheckPointAdded() - Query failed! %s", error);
	}
	else if (!error[0]) {
		PrintToChat(client, "\x01[\x03JA\x01] Zone creation was successful");
		ShowZone(client, g_iNumZones);
		g_iNumZones++;
	}
	else {
		PrintToChat(client, "\x01[\x03JA\x01] Zone creation failed");
		g_fZoneBottom[g_iNumZones] = NULL_VECTOR;
		g_fZoneTop[g_iNumZones] = NULL_VECTOR;
	}
}

public Action cmdSetStart(int client, int args) {
	if (!cvarSpeedrunEnabled.BoolValue) {
		return Plugin_Continue;
	}
	if (g_hDatabase == null) {
		PrintToChat(client, "This feature is not supported without a database configuration");
		return Plugin_Handled;
	}
	if (!client) {
		ReplyToCommand(client, "\x01[\x03JA\x01] Cannot select start from rcon");
		return Plugin_Handled;
	}
	if (IsClientObserver(client)) {
		ReplyToCommand(client, "\x01[\x03JA\x01] Cannot select start as spectator");
		return Plugin_Handled;
	}
	float a[3];
	float l[3];
	char query[1024];

	GetEntPropVector(client, Prop_Data, "m_vecOrigin", l);
	GetClientEyeAngles(client, a);
	g_fStartLoc = l;
	g_fStartAng = a;
	g_fLoc = l;
	g_fAng = a;
	Format(query, sizeof(query), "SELECT * FROM startlocs WHERE MapName='%s'", g_sMap);
	g_hDatabase.Query(SQL_OnStartLocationCheck, query, client);

	return Plugin_Continue;
}

public void SQL_OnStartLocationCheck(Database db, DBResultSet results, const char[] error, any data) {
	int client = data;
	char query[1024];

	if (db == null) {
		LogError("OnStartLocationCheck() - Query failed! %s", error);
	}
	else if (results.RowCount) {
		Format(query, sizeof(query), "UPDATE startlocs SET x='%f', ='%f', ='%f', ang='%f', ang='%f', ang='%f' WHERE MapName='%s'", g_fLoc[0], g_fLoc[1], g_fLoc[2], g_fAng[0], g_fAng[1], g_fAng[2], g_sMap);
		g_hDatabase.Query(SQL_OnStartLocationSet, query, client);
	}
	else {
		Format(query, sizeof(query), "INSERT INTO startlocs VALUES(null,'%s', '%f','%f','%f','%f','%f','%f');", g_sMap, g_fLoc[0], g_fLoc[1], g_fLoc[2], g_fAng[0], g_fAng[1], g_fAng[2]);
		g_hDatabase.Query(SQL_OnStartLocationSet, query, client);
	}
}

public void SQL_OnStartLocationSet(Database db, DBResultSet results, const char[] error, any data) {
	int client = data;

	if (db == null) {
		LogError("OnStartLocationSet() - Query failed! %s", error);
	}
	else if (!error[0]) {
		PrintToChat(client, "\x01[\x03JA\x01] Start location successfully set");
	}
	else {
		PrintToServer(error);
		PrintToChat(client, "\x01[\x03JA\x01] Start location failed to set");
		g_fLoc = NULL_VECTOR;
		g_fAng = NULL_VECTOR;
	}
}
/*public Action cmdTest(int client, int args) {
	char testString[64];
	Format(testString, sizeof(testString), "rush");
	PrintToServer(testString[3]);
}*/

char GetFullMapName(char[] inputMapName) {
	char baseJump[5] = "jump_";
	char m[128];
	char toReturn[6];

	//Substring magic
	strcopy(toReturn, 6, inputMapName[0]);
	if (StrEqual(toReturn, baseJump, false)) {
		Format(m, sizeof(m), "%s", inputMapName);
	}
	else {
		Format(m, sizeof(m), "jump_%s", inputMapName);
	}

	return m;
}

void UpdateSteamID(int client) {
	char query[1024];
	char steamid[32];

	GetClientAuthId(client, AuthId_Steam2, steamid, sizeof(steamid));
	Format(query, sizeof(query), "SELECT * FROM steamids WHERE SteamID='%s'", steamid);
	g_hDatabase.Query(SQL_OnSteamIDCheck, query, client);
}

public void SQL_OnSteamIDCheck(Database db, DBResultSet results, const char[] error, any data) {
	int client = data;
	char query[1024];

	if (db == null) {
		LogError("OnSpeedrunSubmit() - Query failed! %s", error);
	}
	else if (results.RowCount) {
		char name[64], steamid[32], nameEscaped[128];

		GetClientName(client, name, sizeof(name));
		GetClientAuthId(client, AuthId_Steam2, steamid, sizeof(steamid));
		g_hDatabase.Escape(name, nameEscaped, sizeof(nameEscaped));
		Format(query, sizeof(query), "UPDATE steamids SET name='%s' WHERE SteamID='%s'", nameEscaped, steamid);
		g_hDatabase.Query(SQL_OnSteamIDUpdate, query, client);
	}
	else {
		char name[64];
		char steamid[32];
		char nameEscaped[128];

		GetClientName(client, name, sizeof(name));
		GetClientAuthId(client, AuthId_Steam2, steamid, sizeof(steamid));
		g_hDatabase.Escape(name, nameEscaped, sizeof(nameEscaped));
		Format(query, sizeof(query), "INSERT INTO steamids VALUES(null,'%s', '%s');", steamid, nameEscaped);
		g_hDatabase.Query(SQL_OnSteamIDUpdate, query, client);
	}
}

public void SQL_OnSteamIDUpdate(Database db, DBResultSet results, const char[] error, any data) {
	if (db == null) {
		LogError("OnSteamIDUpdate() - Query failed! %s", error);
	}
}

bool IsSpeedrunMap() {
	return (g_fZoneBottom[0][0] != 0.0 && g_fZoneBottom[1][0] != 0.0 && g_fStartLoc[0] != 0.0);
}

bool IsInZone(int client, int zone) {
	return IsInRegion(client, g_fZoneBottom[zone], g_fZoneTop[zone]);
}

bool IsInRegion(int client, float bottom[3], float upper[3]) {
	float f[3];
	float e[3];
	float end1[3];
	float end2[3];

	GetEntPropVector(client, Prop_Data, "m_vecOrigin", f);
	GetClientEyePosition(client, e);
	if (upper[0] < bottom[0]) {
		end1[0] = upper[0];
		end2[0] = bottom[0];
	}
	else {
		end1[0] = bottom[0];
		end2[0] = upper[0];
	}
	if (upper[1] < bottom[1]) {
		end1[1] = upper[1];
		end2[1] = bottom[1];
	}
	else {
		end1[1] = bottom[1];
		end2[1] = upper[1];
	}
	if (upper[2] < bottom[2]) {
		end1[2] = upper[2];
		end2[2] = bottom[2];
	}
	else {
		end1[2] = bottom[2];
		end2[2] = upper[2];
	}
	if (f[0] > end1[0] && end2[0] > f[0] && f[1] > end1[1] && end2[1] > f[1] && f[2] > end1[2] && end2[2] > f[2]) {
		return true;
	}
	if (e[0] > end1[0] && end2[0] > e[0] && e[1] > end1[1] && end2[1] > e[1] && e[2] > end1[2] && end2[2] > e[2]) {
		return true;
	}
	return false;
}

bool TraceEntityFilterPlayer(int entity, int contentsMask, any data) {
	return entity > MaxClients;
}

void ShowZone(int client, int zone) {
	Effect_DrawBeamBoxToClient(client, g_fZoneBottom[zone], g_fZoneTop[zone], g_iBeamSprite, g_iHaloSprite, 0, 30);
}

void Effect_DrawBeamBoxToClient(
	int client,
	const float bottomCorner[3],
	const float upperCorner[3],
	int modelIndex,
	int haloIndex,
	int startFrame = 0,
	int frameRate = 30,
	float life = 5.0,
	float width = 5.0,
	float endWidth = 5.0,
	int fadeLength = 2,
	float amplitude = 1.0,
	const int color[4] = { 255, 0, 0, 255 },
	int speed = 0
) {
	int clients[1];
	clients[0] = client;
	Effect_DrawBeamBox(clients, 1, bottomCorner, upperCorner, modelIndex, haloIndex, startFrame, frameRate, life, width, endWidth, fadeLength, amplitude, color, speed);
}

void Effect_DrawBeamBox(
	int[] clients,
	int numClients,
	const float bottomCorner[3],
	const float upperCorner[3],
	int modelIndex,
	int haloIndex,
	int startFrame = 0,
	int frameRate = 30,
	float life = 5.0,
	float width = 5.0,
	float endWidth = 5.0,
	int fadeLength = 2,
	float amplitude = 1.0,
	const int color[4] = { 255, 0, 0, 255 },
	int speed = 0
) {
	// Create the additional corners of the box
	float corners[8][3];

	for (int i = 0; i < 4; i++) {
		Array_Copy(bottomCorner, corners[i], 3);
		Array_Copy(upperCorner, corners[i+4], 3);
	}
	corners[1][0] = upperCorner[0];
	corners[2][0] = upperCorner[0];
	corners[2][1] = upperCorner[1];
	corners[3][1] = upperCorner[1];
	corners[4][0] = bottomCorner[0];
	corners[4][1] = bottomCorner[1];
	corners[5][1] = bottomCorner[1];
	corners[7][0] = bottomCorner[0];
	// Draw all the edges
	// Horizontal Lines
	// Bottom
	for (int i = 0; i < 4; i++) {
		int j = (i == 3 ? 0 : i+1);
		TE_SetupBeamPoints(corners[i], corners[j], modelIndex, haloIndex, startFrame, frameRate, life, width, endWidth, fadeLength, amplitude, color, speed);
		TE_Send(clients, numClients);
	}
	// Top
	for (int i = 4; i < 8; i++) {
		int j = (i == 7 ? 4 : i+1);
		TE_SetupBeamPoints(corners[i], corners[j], modelIndex, haloIndex, startFrame, frameRate, life, width, endWidth, fadeLength, amplitude, color, speed);
		TE_Send(clients, numClients);
	}
	// All Vertical Lines
	for (int i = 0; i < 4; i++) {
		TE_SetupBeamPoints(corners[i], corners[i+4], modelIndex, haloIndex, startFrame, frameRate, life, width, endWidth, fadeLength, amplitude, color, speed);
		TE_Send(clients, numClients);
	}
}

void Array_Copy(const any[] array, any[] newArray, int size) {
	for (int i = 0; i < size; i++) {
		newArray[i] = array[i];
	}
}