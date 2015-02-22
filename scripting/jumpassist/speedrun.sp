
new Float:startLoc[3], Float:startAng[3], Float:sLoc[3], Float:sAng[3], Float:bottomLoc[3], Float:topLoc[3];

new Float:zoneBottom[32][3];
new Float:zoneTop[32][3];
new Float:zoneTimes[32][32];
new Float:recordTime[9];
new nextCheckpoint[32];
new bool:skippedCheckpointMessage[32];
new processingClass[32];
new Float:processingZoneTimes[32][32];


new lastFrameInStartZone[32];
//SPEEDRUN STATUS NOW IN jumpassist.sp
	//0 = not running
	//1 = running
	//2 = finished

new g_BeamSprite;
new g_HaloSprite;

new String:cMap[64];
new numZones = 0;

new Handle:hSpeedrunEnabled;


public processSpeedrun(client){
	new String:query[1024] = "", String:steamid[32], String:endtime[4];
	GetClientAuthId(client, AuthId_Steam2, steamid, sizeof(steamid));

	Format(endtime, sizeof(endtime), "c%d", numZones-1);

	Format(query, sizeof(query), "SELECT %s FROM times WHERE SteamID='%s' AND class='%d' AND MapName='%s'", endtime, steamid, processingClass[client], cMap);
	SQL_TQuery(g_hDatabase, SQL_OnSpeedrunCheckLoad, query, client);
}

public SQL_OnSpeedrunCheckLoad(Handle:owner, Handle:hndl, const String:error[], any:data){

	new client = data;
	new Float:t;
	new String:query[1024], String:steamid[32], datetime;
	GetClientAuthId(client, AuthId_Steam2, steamid, sizeof(steamid));

	datetime = GetTime();
	if (hndl == INVALID_HANDLE)
	{
		LogError("OnSpeedrunCheckLoad() - Query failed! %s", error);
	}
	else if (SQL_GetRowCount(hndl))
	{
		SQL_FetchRow(hndl);
		new Float:endTime = SQL_FetchFloat(hndl, 0);

		if(endTime > processingZoneTimes[client][numZones-1]-processingZoneTimes[client][0]){
			Format(query, sizeof(query), "UPDATE times SET time='%d',", datetime);

			for(new i = 0; i < 32; i++){
				if(i == 0){
					Format(query, sizeof(query), "%s c%d='%f',", query, i, 0.0);
				}else{
					t = processingZoneTimes[client][i]-processingZoneTimes[client][0];
					if(t < 0.0){
						t = 0.0;
					}
					Format(query, sizeof(query), "%s c%d='%f'", query, i, t);
					if(i != 31){
						Format(query, sizeof(query), "%s,",query);
					}
				}
			}
			Format(query, sizeof(query), "%s WHERE SteamID='%s' AND MapName='%s' AND class='%d';", query, steamid, cMap, processingClass[client]);

			SQL_TQuery(g_hDatabase, SQL_OnSpeedrunSubmit, query, client);
		}else{
			new String:clientName[64], String:message[256];
			GetClientName(client, clientName, sizeof(clientName));
			new Float:time = processingZoneTimes[client][numZones-1] - processingZoneTimes[client][0];
			Format(message, sizeof(message), "\x01[\x03JA\x01] \x03%s\x01: \x05%s\x01 map run: \x06%s\x01", clientName, GetClassname(processingClass[client]), TimeFormat(time));
			PrintToChatAll(message);
		}


	}
	else
	{
		Format(query, sizeof(query), "INSERT INTO times VALUES(null, '%s', '%d', '%s', '%d',", steamid, processingClass[client], cMap, datetime);

		for(new i = 0; i < 32; i++){
			if(i == 0){
				Format(query, sizeof(query), "%s '%f',", query, 0.0);
			}else{
				t = processingZoneTimes[client][i]-processingZoneTimes[client][0];
				if(t < 0.0){
					t = 0.0;
				}
				Format(query, sizeof(query), "%s '%f'", query, t);
				if(i != 31){
					Format(query, sizeof(query), "%s,",query);
				}
			}
		}

		Format(query, sizeof(query), "%s);", query);

		SQL_TQuery(g_hDatabase, SQL_OnSpeedrunSubmit, query, client);
	}
}


public SQL_OnSpeedrunSubmit(Handle:owner, Handle:hndl, const String:error[], any:data){
	new client = data;
	if (hndl == INVALID_HANDLE)
	{
		LogError("OnSpeedrunSubmit() - Query failed! %s", error);
	}
	else
	{
		new String:clientName[64], String:message[256];
		GetClientName(client, clientName, sizeof(clientName));
		new Float:time = processingZoneTimes[client][numZones-1] - processingZoneTimes[client][0];
		if(time < recordTime[processingClass[client]]){
			new Float:previousRecord = recordTime[processingClass[client]];
			recordTime[processingClass[client]] = time;
			
			if(previousRecord == 99999999.99){
				Format(message, sizeof(message), "\x01[\x03JA\x01] \x03%s\x01 set the map record as \x05%s\x01 with time \x06%s\x01!", clientName, GetClassname(processingClass[client]), TimeFormat(time));
			}else{
				Format(message, sizeof(message), "\x01[\x03JA\x01] \x03%s\x01 broke the map record as \x05%s\x01 by \x06%s\x01 with time \x06%s\x01!", clientName, GetClassname(processingClass[client]), TimeFormat(previousRecord-time), TimeFormat(time));
			}
			
		}else{
			Format(message, sizeof(message), "\x01[\x03JA\x01] \x03%s\x01: \x05%s\x01 map run: \x06%s\x01", clientName, GetClassname(processingClass[client]), TimeFormat(time));
		}
		PrintToChatAll(message);
	}
}

public SpeedrunOnGameFrame(){
	for(new i = 0; i < 32; i++){
		if(speedrunStatus[i]==1){
			for(new j = 0; j < numZones; j++){
				if(IsInZone(i, j) && zoneTimes[i][j] == 0.0 && j != 0 && j==nextCheckpoint[i]) {
					zoneTimes[i][j] = GetEngineTime();
					if(j != numZones-1){
						new String:timeString[128];
						timeString = TimeFormat(zoneTimes[i][j] - zoneTimes[i][0]);
						PrintToChat(i, "\x01[\x03JA\x01] \x01\x04Checkpoint %d\x01: %s", j, timeString);
						nextCheckpoint[i]++;
					}else{
						new String:timeString[128];
						timeString = TimeFormat(zoneTimes[i][j] - zoneTimes[i][0]);
						PrintToChat(i, "\x01[\x03JA\x01] Finished in %s", timeString);
						speedrunStatus[i] = 2;

						processingClass[i] = int:TF2_GetPlayerClass(i);
						processingZoneTimes[i] = zoneTimes[i];

						for(new h = 0; h < 32; h++){
							zoneTimes[i][h] = 0.0;
						}
						processSpeedrun(i);
					}
					skippedCheckpointMessage[i] = false;
				}else if(!skippedCheckpointMessage[i] && j > nextCheckpoint[i] && IsInZone(i, j)){
					PrintToChat(i, "\x01[\x03JA\x01] You skipped \x01\x04Checkpoint %d\x01!", nextCheckpoint[i]);
					skippedCheckpointMessage[i] = true;
				}
				if(!IsInZone(i, 0) && lastFrameInStartZone[i]){
					PrintToChat(i, "\x01[\x03JA\x01] Speedrun started");
					nextCheckpoint[i] = 1;
					skippedCheckpointMessage[i] = false;
					zoneTimes[i][j] = GetEngineTime();
				}			
				if(IsInZone(i, 0)){
					lastFrameInStartZone[i] = true;
				}else{
					lastFrameInStartZone[i] = false;
				}

			
			}
		}else if(speedrunStatus[i]==2){
			if(IsInZone(i, 0)){
				speedrunStatus[i] = 1;
				PrintToChat(i, "\x01[\x03JA\x01] Entered start zone");
			}

		}
	}
}

public UpdateSteamID(client){
	new String:query[1024] = "", String:steamid[32];
	GetClientAuthId(client, AuthId_Steam2, steamid, sizeof(steamid));

	Format(query, sizeof(query), "SELECT * FROM steamids WHERE SteamID='%s'", steamid);
	SQL_TQuery(g_hDatabase, SQL_OnSteamIDCheck, query, client);
}

public SQL_OnSteamIDCheck(Handle:owner, Handle:hndl, const String:error[], any:data){
	new client = data;
	new String:query[1024];

	if (hndl == INVALID_HANDLE)
	{
		LogError("OnSpeedrunSubmit() - Query failed! %s", error);
	}
	else if (SQL_GetRowCount(hndl))
	{
		new String:name[64], String:steamid[32];
		GetClientName(client, name, sizeof(name));
		GetClientAuthId(client, AuthId_Steam2, steamid, sizeof(steamid));

		Format(query, sizeof(query), "UPDATE steamids SET name='%s' WHERE SteamID='%s'", name, steamid);
		SQL_TQuery(g_hDatabase, SQL_OnSteamIDUpdate, query, client);

	}
	else
	{
		new String:name[64], String:steamid[32];
		GetClientName(client, name, sizeof(name));
		GetClientAuthId(client, AuthId_Steam2, steamid, sizeof(steamid));

		Format(query, sizeof(query), "INSERT INTO steamids VALUES(null,'%s', '%s');", steamid, name);
		SQL_TQuery(g_hDatabase, SQL_OnSteamIDUpdate, query, client);
	}
}

public SQL_OnSteamIDUpdate(Handle:owner, Handle:hndl, const String:error[], any:data){
	if (hndl == INVALID_HANDLE)
	{
		LogError("OnSteamIDUpdate() - Query failed! %s", error);
	}
}

public Action:cmdShowPR(client,args){
	if(!GetConVarBool(hSpeedrunEnabled)){
		return Plugin_Continue;
	}
	if(!databaseConfigured)
	{
		PrintToChat(client, "This feature is not supported without a database configuration");
		return Plugin_Handled;
	}

	if( !client ){
		ReplyToCommand(client, "\x01[\x03JA\x01] Cannot use this command from rcon");
		return Plugin_Handled;
	}
	if(!IsSpeedrunMap()){
		ReplyToCommand(client, "\x01[\x03JA\x01] This map does not currently have speedrunning configured");
		return Plugin_Handled;
	}	
	new String:query[1024] = "", String:steamid[32], String:endtime[4], class;
	GetClientAuthId(client, AuthId_Steam2, steamid, sizeof(steamid));	
	if(IsClientObserver(client)){
		class = 3;
	}else{
		class = int:TF2_GetPlayerClass(client);
	}



	Format(endtime, sizeof(endtime), "c%d", numZones-1);

	Format(query, sizeof(query), "SELECT MapName, SteamID, %s, class FROM times WHERE SteamID='%s' AND class='%d' AND MapName='%s'", endtime, steamid, class, cMap);
	SQL_TQuery(g_hDatabase, SQL_OnSpeedrunListingSubmit, query, client);
	return Plugin_Continue;
}
public SQL_OnSpeedrunListingSubmit(Handle:owner, Handle:hndl, const String:error[], any:data){
	new client = data;
	if (hndl == INVALID_HANDLE)
	{
		LogError("OnSpeedrunListingSubmit() - Query failed! %s", error);
	}
	else if(SQL_GetRowCount(hndl))
	{

		SQL_FetchRow(hndl);
		new String:mapName[32], String:steamid[32], String:class[128], Float:time, String:timeString[128], String:query[1024];
		new String:playerName[64], String:toPrint[128];
		SQL_FetchString(hndl, 0, mapName, sizeof(mapName));
		SQL_FetchString(hndl, 1, steamid, sizeof(steamid));
		time = SQL_FetchFloat(hndl, 2);
		timeString = TimeFormat(time);
		class = GetClassname(SQL_FetchInt(hndl, 3));
		new Handle:hQuery;
		Format(query, sizeof(query), "SELECT name FROM steamids WHERE SteamID='%s'", steamid);

		SQL_LockDatabase(g_hDatabase);
		if((hQuery = SQL_Query(g_hDatabase, query)) == INVALID_HANDLE){
			new String:err[256];
			SQL_GetError(hQuery, err, sizeof(err));
			Format(toPrint, sizeof(toPrint), "\x01[\x03JA\x01] An error occurred: %s", err);
		}else{
			SQL_FetchRow(hQuery);
			SQL_FetchString(hQuery, 0, playerName, sizeof(playerName));
			Format(toPrint, sizeof(toPrint), "\x01[\x03JA\x01] \x03%s\x01: \x05%s\x01 - \x03%s\x01: \x06%s\x01", playerName, mapName, class, timeString);
		}
		SQL_UnlockDatabase(g_hDatabase);

		PrintToChat(client, toPrint);

		CloseHandle(hQuery);
	}else{
		PrintToChat(client, "\x01[\x03JA\x01] No record exists");
	}
}


public Action:cmdShowWR(client,args){
	if(!GetConVarBool(hSpeedrunEnabled)){
		return Plugin_Continue;
	}

	if(!databaseConfigured)
	{
		PrintToChat(client, "This feature is not supported without a database configuration");
		return Plugin_Handled;
	}
	if(!IsSpeedrunMap()){
		ReplyToCommand(client, "\x01[\x03JA\x01] This map does not currently have speedrunning configured");
		return Plugin_Handled;
	}
	if( !client ){
		ReplyToCommand(client, "\x01[\x03JA\x01] Cannot use this command from rcon");
		return Plugin_Handled;
	}
	new String:query[1024] = "", String:steamid[32], String:endtime[4], class;
	GetClientAuthId(client, AuthId_Steam2, steamid, sizeof(steamid));

	if(IsClientObserver(client)){
		class = 3;
	}else{
		class = int:TF2_GetPlayerClass(client);
	}


	Format(endtime, sizeof(endtime), "c%d", numZones-1);

	Format(query, sizeof(query), "SELECT MapName, SteamID, %s, class FROM times WHERE class='%d' AND MapName='%s' ORDER BY %s ASC LIMIT 1", endtime, class, cMap, endtime);
	SQL_TQuery(g_hDatabase, SQL_OnSpeedrunListingSubmit, query, client);
	return Plugin_Continue;
}

// public Action:cmdShowTop(client,args){

// }

public Action:cmdSpeedrunRestart(client,args){
	if(!GetConVarBool(hSpeedrunEnabled)){
		return Plugin_Continue;
	}
	if(!databaseConfigured)
	{
		PrintToChat(client, "This feature is not supported without a database configuration");
		return Plugin_Handled;
	}

	if( !client ){
		ReplyToCommand(client, "\x01[\x03JA\x01] Cannot speedrun from rcon");
		return Plugin_Handled;
	}
	if(IsClientObserver(client)){
		ReplyToCommand(client, "\x01[\x03JA\x01] Cannot speedrun as spectator");
		return Plugin_Handled;
	}
	if(!IsSpeedrunMap()){
		ReplyToCommand(client, "\x01[\x03JA\x01] This map does not currently have speedrunning configured");
		return Plugin_Handled;
	}

	RestartSpeedrun(client);
	return Plugin_Continue;
}

public Action:cmdToggleSpeedrun(client,args){
	if(!GetConVarBool(hSpeedrunEnabled)){
		return Plugin_Continue;
	}

	if(!databaseConfigured)
	{
		PrintToChat(client, "This feature is not supported without a database configuration");
		return Plugin_Handled;
	}

	if( !client ){
		ReplyToCommand(client, "\x01[\x03JA\x01] Cannot speedrun from rcon");
		return Plugin_Handled;
	}
	if(IsClientObserver(client)){
		ReplyToCommand(client, "\x01[\x03JA\x01] Cannot speedrun as spectator");
		return Plugin_Handled;
	}
	if(!IsSpeedrunMap()){
		ReplyToCommand(client, "\x01[\x03JA\x01] This map does not currently have speedrunning configured");
		return Plugin_Handled;
	}


	if(speedrunStatus[client]){
		ReplyToCommand(client, "\x01[\x03JA\x01] Speedrunning disabled");
		speedrunStatus[client] = 0;

	}else{
		ReplyToCommand(client, "\x01[\x03JA\x01] Speedrunning enabled");
		speedrunStatus[client] = 1;
		RestartSpeedrun(client);
		g_bHPRegen[client] = false;
		g_bAmmoRegen[client] = false;
		g_bUnkillable[client] = false;
		SetEntProp(client, Prop_Data, "m_takedamage", 2, 1);
	}
	return Plugin_Continue;
}

public RestartSpeedrun(client){
	new Float:v[3];
	speedrunStatus[client] = 2;
	for(new i = 0; i < 32; i++){
		zoneTimes[client][i] = 0.0;
	}
	lastFrameInStartZone[client] = false;
	TeleportEntity(client,startLoc,startAng,v);
}


public Action:cmdClearZones(client,args){
	if(!GetConVarBool(hSpeedrunEnabled)){
		return Plugin_Continue;
	}

	if(!databaseConfigured)
	{
		PrintToChat(client, "This feature is not supported without a database configuration");
		return Plugin_Handled;
	}

	if( !client ){
		ReplyToCommand(client, "\x01[\x03JA\x01] Cannot clear zones from rcon");
		return Plugin_Handled;
	}

	new String:query[1024];
	new Handle:hQuery;
	Format(query, sizeof(query), "DELETE FROM zones WHERE MapName='%s'", cMap);

	SQL_LockDatabase(g_hDatabase);
	if((hQuery = SQL_Query(g_hDatabase, query)) == INVALID_HANDLE){
		new String:err[256];
		SQL_GetError(hQuery, err, sizeof(err));
		PrintToChat(client, "\x01[\x03JA\x01] An error occurred: %s", err);
	}
	SQL_UnlockDatabase(g_hDatabase);

	for(new i = 0; i < 32; i++){
		zoneBottom[i][0] = 0.0;
		zoneBottom[i][1] = 0.0;
		zoneBottom[i][2] = 0.0;
		zoneTop[i][0] = 0.0;
		zoneTop[i][1] = 0.0;
		zoneTop[i][2] = 0.0;
	}
	
	PrintToChat(client, "\x01[\x03JA\x01] All zones cleared");
	return Plugin_Continue;
}

public Action:cmdShowZones(client,args){
	if(!GetConVarBool(hSpeedrunEnabled)){
		return Plugin_Continue;
	}

	if(!databaseConfigured)
	{
		PrintToChat(client, "This feature is not supported without a database configuration");
		return Plugin_Handled;
	}

	if( !client ){
		ReplyToCommand(client, "\x01[\x03JA\x01] Cannot show zones from rcon");
		return Plugin_Handled;
	}
	if(IsClientObserver(client)){
		ReplyToCommand(client, "\x01[\x03JA\x01] Cannot show zones as spectator");
		return Plugin_Handled;
	}

	for(new i = 0; i < numZones; i++){
		ShowZone(client, i);
	}

	ReplyToCommand(client, "\x01[\x03JA\x01] Showing all zones");
	return Plugin_Continue;

}



public Action:ClearMapSpeedrunInfo(){
	for(new i = 0; i < 32; i++){
		zoneBottom[i][0] = 0.0;
		zoneBottom[i][1] = 0.0;
		zoneBottom[i][2] = 0.0;
		zoneTop[i][0] = 0.0;
		zoneTop[i][1] = 0.0;
		zoneTop[i][2] = 0.0;

		for(new j = 0; j < 32; j++){
			zoneTimes[i][j] = 0.0;
			processingZoneTimes[i][j] = 0.0;
		}
		processingClass[i] = 0;

		lastFrameInStartZone[i] = false;
		speedrunStatus[i] = 0;
	}

	for(new j = 0; j < 9; j++){
		recordTime[j] = 99999999.99;
	}
	numZones = 0;
	startLoc[0] = 0.0;
	startLoc[1] = 0.0;
	startLoc[2] = 0.0;
	startAng[0] = 0.0;
	startAng[1] = 0.0;
	startAng[2] = 0.0;
}

public Action:LoadMapSpeedrunInfo(){
	ClearMapSpeedrunInfo();

	new String:query[1024] = "";
	GetCurrentMap(cMap, sizeof(cMap));

	Format(query, sizeof(query), "SELECT x, y, z, xang, yang, zang FROM startlocs WHERE MapName='%s'", cMap);
	SQL_TQuery(g_hDatabase, SQL_OnMapStartLocationLoad, query, 0);

	Format(query, sizeof(query), "SELECT x1, y1, z1, x2, y2, z2 FROM zones WHERE MapName='%s' ORDER BY 'number' ASC", cMap);
	SQL_TQuery(g_hDatabase, SQL_OnMapZonesLoad, query, 0);	


}

public SQL_OnMapZonesLoad(Handle:owner, Handle:hndl, const String:error[], any:data){

	if (hndl == INVALID_HANDLE)
	{
		LogError("OnMapZonesLoad() - Query failed! %s", error);
	}
	else if (SQL_GetRowCount(hndl))
	{
		new numRows = SQL_GetRowCount(hndl);
		numZones = 0;
		for(numZones=0; numZones < numRows; numZones++){

			SQL_FetchRow(hndl);
			zoneBottom[numZones][0] = SQL_FetchFloat(hndl, 0);
			zoneBottom[numZones][1] = SQL_FetchFloat(hndl, 1);
			zoneBottom[numZones][2] = SQL_FetchFloat(hndl, 2);
			zoneTop[numZones][0] = SQL_FetchFloat(hndl, 3);
			zoneTop[numZones][1] = SQL_FetchFloat(hndl, 4);
			zoneTop[numZones][2] = SQL_FetchFloat(hndl, 5);
		}
		new String:query[1024] = "";
		for(new i = 0; i < 9; i++){
			Format(query, sizeof(query), "SELECT c%d FROM times WHERE MapName='%s' AND class='%d' ORDER BY c%d ASC LIMIT 1", numZones-1, cMap, i, numZones-1);
			SQL_TQuery(g_hDatabase, SQL_OnRecordLoad, query, i);
		}
		
	}
	else
	{

	}
}
public SQL_OnRecordLoad(Handle:owner, Handle:hndl, const String:error[], any:data){
	new class = data;

	if (hndl == INVALID_HANDLE)
	{
		LogError("OnRecordLoad() - Query failed! %s", error);
	}
	else if (SQL_GetRowCount(hndl))
	{
		SQL_FetchRow(hndl);
		new Float:t = SQL_FetchFloat(hndl, 0);
		if(t != 0.0){
			recordTime[class] = t;
		}
	}
	else
	{

	}

}


public SQL_OnMapStartLocationLoad(Handle:owner, Handle:hndl, const String:error[], any:data){


	if (hndl == INVALID_HANDLE)
	{
		LogError("OnMapStartLocationLoad() - Query failed! %s", error);
	}
	else if (SQL_GetRowCount(hndl))
	{
		SQL_FetchRow(hndl);
		startLoc[0] = SQL_FetchFloat(hndl, 0);
		startLoc[1] = SQL_FetchFloat(hndl, 1);
		startLoc[2] = SQL_FetchFloat(hndl, 2);
		startAng[0] = SQL_FetchFloat(hndl, 3);
		startAng[1] = SQL_FetchFloat(hndl, 4);
		startAng[2] = SQL_FetchFloat(hndl, 5);
	}
	else
	{


	}
}


public Action:cmdAddZone(client,args){
	if(!GetConVarBool(hSpeedrunEnabled)){
		return Plugin_Continue;
	}

	if(!databaseConfigured)
	{
		PrintToChat(client, "This feature is not supported without a database configuration");
		return Plugin_Handled;
	}

	if( !client ){
		ReplyToCommand(client, "\x01[\x03JA\x01] Cannot setup corners from rcon");
		return Plugin_Handled;
	}
	if(IsClientObserver(client)){
		ReplyToCommand(client, "\x01[\x03JA\x01] Cannot setup corners as spectator");
		return Plugin_Handled;
	}
	if(numZones == 32){
		ReplyToCommand(client, "\x01[\x03JA\x01] Maximum zone count reached");
		return Plugin_Handled;
	}

	decl Float:start[3], Float:angle[3], Float:loc[3];

	GetClientEyePosition(client, start);
	GetClientEyeAngles(client, angle);
	TR_TraceRayFilter(start, angle, MASK_SOLID, RayType_Infinite, TraceEntityFilterPlayer, client);
	if (TR_DidHit(INVALID_HANDLE)){
		TR_GetEndPosition(loc, INVALID_HANDLE);
	}

	if(loc[0] == 0.0){
		ReplyToCommand(client, "\x01[\x04JT\x01] Invalid location");
		return Plugin_Handled;
	}

	if(bottomLoc[0] == 0.0 && topLoc[0] == 0.0){
		bottomLoc[0] = loc[0];
		bottomLoc[1] = loc[1];
		bottomLoc[2] = loc[2];
	}else{

		if(loc[2] < bottomLoc[2]){
			topLoc[0] = bottomLoc[0];
			topLoc[1] = bottomLoc[1];
			topLoc[2] = bottomLoc[2];
			bottomLoc[0] = loc[0];
			bottomLoc[1] = loc[1];
			bottomLoc[2] = loc[2];
		}else{
			topLoc[0] = loc[0];
			topLoc[1] = loc[1];
			topLoc[2] = loc[2];
		}


		new String:query[1024];

		Format(query, sizeof(query), "INSERT INTO zones VALUES (null, '%d', '%s', '%f', '%f', '%f', '%f', '%f', '%f')", numZones, cMap, bottomLoc[0], bottomLoc[1], bottomLoc[2], topLoc[0], topLoc[1], topLoc[2]);

		zoneBottom[numZones] = bottomLoc;
		zoneTop[numZones] = topLoc;

		bottomLoc[0] = 0.0;
		bottomLoc[1] = 0.0;
		bottomLoc[2] = 0.0;

		topLoc[0] = 0.0;
		topLoc[1] = 0.0;
		topLoc[2] = 0.0;

		SQL_TQuery(g_hDatabase, SQL_OnZoneAdded, query, client);

	}

	ReplyToCommand(client, "\x01[\x03JA\x01] Corner successfully selected");
	return Plugin_Continue;

}



public SQL_OnZoneAdded(Handle:owner, Handle:hndl, const String:error[], any:data){

	new client = data;

	if (hndl == INVALID_HANDLE)
	{
		LogError("OnCheckPointAdded() - Query failed! %s", error);
	}
	else if (!error[0])
	{
		PrintToChat(client, "\x01[\x03JA\x01] Zone creation was successful");
		ShowZone(client, numZones);
		numZones++;
	}
	else
	{
		PrintToChat(client, "\x01[\x03JA\x01] Zone creation failed");
		zoneBottom[numZones][0] = 0.0;
		zoneBottom[numZones][1] = 0.0;
		zoneBottom[numZones][2] = 0.0;
		zoneTop[numZones][0] = 0.0;
		zoneTop[numZones][1] = 0.0;
		zoneTop[numZones][2] = 0.0;

	}
}

public Action:cmdSetStart(client, args){
	if(!GetConVarBool(hSpeedrunEnabled)){
		return Plugin_Continue;
	}

	if(!databaseConfigured){
		PrintToChat(client, "This feature is not supported without a database configuration");
		return Plugin_Handled;
	}

	if( !client ){
		ReplyToCommand(client, "\x01[\x03JA\x01] Cannot select start from rcon");
		return Plugin_Handled;
	}
	if(IsClientObserver(client)){
		ReplyToCommand(client, "\x01[\x03JA\x01] Cannot select start as spectator");
		return Plugin_Handled;
	}

	decl Float:a[3];
	decl Float:l[3];

	GetEntPropVector(client, Prop_Data, "m_vecOrigin", l);
	GetClientEyeAngles(client, a);



	sLoc = l;
	sAng = a;

	new String:query[1024];

	Format(query, sizeof(query), "SELECT * FROM startlocs WHERE MapName='%s'", cMap);

	SQL_TQuery(g_hDatabase, SQL_OnStartLocationCheck, query, client);
	return Plugin_Continue;
}

public SQL_OnStartLocationCheck(Handle:owner, Handle:hndl, const String:error[], any:data){

	new client = data;
	new String:query[1024];

	if (hndl == INVALID_HANDLE)
	{
		LogError("OnStartLocationCheck() - Query failed! %s", error);
	}
	else if (SQL_GetRowCount(hndl))
	{
		Format(query, sizeof(query), "UPDATE startlocs SET x='%f',y='%f',z='%f',xang='%f',yang='%f',zang='%f' WHERE MapName='%s'", sLoc[0], sLoc[1], sLoc[2], sAng[0], sAng[1], sAng[2], cMap);
		SQL_TQuery(g_hDatabase, SQL_OnStartLocationSet, query, client);

	}
	else
	{
		Format(query, sizeof(query), "INSERT INTO startlocs VALUES(null,'%s', '%f','%f','%f','%f','%f','%f');",cMap, sLoc[0], sLoc[1], sLoc[2], sAng[0], sAng[1], sAng[2]);
		SQL_TQuery(g_hDatabase, SQL_OnStartLocationSet, query, client);
	}
}

public SQL_OnStartLocationSet(Handle:owner, Handle:hndl, const String:error[], any:data){

	new client = data;

	if (hndl == INVALID_HANDLE)
	{
		LogError("OnStartLocationSet() - Query failed! %s", error);
	}
	else if (!error[0])
	{

		PrintToChat(client, "\x01[\x03JA\x01] Start location successfully set");
	}
	else
	{
		PrintToServer(error);
		PrintToChat(client, "\x01[\x03JA\x01] Start location failed to set");
		sLoc[0] = 0.0;
		sLoc[1] = 0.0;
		sLoc[2] = 0.0;

		sAng[0] = 0.0;
		sAng[1] = 0.0;
		sAng[2] = 0.0;

	}
}




bool:IsSpeedrunMap(){
	if(zoneBottom[0][0] != 0.0 && zoneBottom[1][0] != 0.0 && startLoc[0] != 0.0){
		return true;
	}
	return false;
}

bool:IsInZone(client, zone){
	return IsInRegion(client, zoneBottom[zone], zoneTop[zone]);
}

bool:IsInRegion(client, Float:bottom[3], Float:upper[3]){
	decl Float:f[3], Float:e[3], Float:end1[3], Float:end2[3];

	GetEntPropVector(client, Prop_Data, "m_vecOrigin", f);
	GetClientEyePosition(client, e);
	if(upper[0] < bottom[0]){
		end1[0] = upper[0];
		end2[0] = bottom[0];
	}else{
		end1[0] = bottom[0];
		end2[0] = upper[0];
	}
	if(upper[1] < bottom[1]){
		end1[1] = upper[1];
		end2[1] = bottom[1];
	}else{
		end1[1] = bottom[1];
		end2[1] = upper[1];
	}
	if(upper[2] < bottom[2]){
		end1[2] = upper[2];
		end2[2] = bottom[2];
	}else{
		end1[2] = bottom[2];
		end2[2] = upper[2];
	}


	if(f[0] > end1[0] && end2[0] > f[0] && f[1] > end1[1] && end2[1] > f[1] && f[2] > end1[2] && end2[2] > f[2]){
		return true;
	}
	if(e[0] > end1[0] && end2[0] > e[0] && e[1] > end1[1] && end2[1] > e[1] && e[2] > end1[2] && end2[2] > e[2]){
		return true;
	}

	return false;
}

public bool:TraceEntityFilterPlayer(entity, contentsMask, any:data){
	return entity > MaxClients;
}

stock ShowZone(client, zone){
	Effect_DrawBeamBoxToClient(client, zoneBottom[zone], zoneTop[zone], g_BeamSprite, g_HaloSprite, 0, 30);
}

//From SMLIB
stock Effect_DrawBeamBoxToClient(
	client,
	const Float:bottomCorner[3],
	const Float:upperCorner[3],
	modelIndex,
	haloIndex,
	startFrame=0,
	frameRate=30,
	Float:life=5.0,
	Float:width=5.0,
	Float:endWidth=5.0,
	fadeLength=2,
	Float:amplitude=1.0,
	const color[4]={ 255, 0, 0, 255 },
	speed=0
) {
    new clients[1];
    clients[0] = client;
    Effect_DrawBeamBox(clients, 1, bottomCorner, upperCorner, modelIndex, haloIndex, startFrame, frameRate, life, width, endWidth, fadeLength, amplitude, color, speed);
}

stock Effect_DrawBeamBox(
	clients[],
	numClients,
	const Float:bottomCorner[3],
	const Float:upperCorner[3],
	modelIndex,
	haloIndex,
	startFrame=0,
	frameRate=30,
	Float:life=5.0,
	Float:width=5.0,
	Float:endWidth=5.0,
	fadeLength=2,
	Float:amplitude=1.0,
	const color[4]={ 255, 0, 0, 255 },
	speed=0
) {
	// Create the additional corners of the box
	decl Float:corners[8][3];

	for (new i=0; i < 4; i++) {
		Array_Copy(bottomCorner,	corners[i],		3);
		Array_Copy(upperCorner,		corners[i+4],	3);
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
	for (new i=0; i < 4; i++) {
		new j = ( i == 3 ? 0 : i+1 );
		TE_SetupBeamPoints(corners[i], corners[j], modelIndex, haloIndex, startFrame, frameRate, life, width, endWidth, fadeLength, amplitude, color, speed);
		TE_Send(clients, numClients);
	}

	// Top
	for (new i=4; i < 8; i++) {
		new j = ( i == 7 ? 4 : i+1 );
		TE_SetupBeamPoints(corners[i], corners[j], modelIndex, haloIndex, startFrame, frameRate, life, width, endWidth, fadeLength, amplitude, color, speed);
		TE_Send(clients, numClients);
	}

	// All Vertical Lines
	for (new i=0; i < 4; i++) {
		TE_SetupBeamPoints(corners[i], corners[i+4], modelIndex, haloIndex, startFrame, frameRate, life, width, endWidth, fadeLength, amplitude, color, speed);
		TE_Send(clients, numClients);
	}
}

stock Array_Copy(const any:array[], any:newArray[], size)
{
	for (new i=0; i < size; i++) {
		newArray[i] = array[i];
	}
}
