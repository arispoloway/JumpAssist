
new Float:startLoc[3];
new Float:startAng[3];

new Float:zoneBottom[32][3];
new Float:zoneTop[32][3];
new numZones = 0;

new g_BeamSprite;
new g_HaloSprite;

new Handle:hSpeedrunEnabled;



//ON MAP START IT WILL NEED TO LOAD ALL THIS IN
public Action:LoadMapSpeedrunInfo(){

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
		ReplyToCommand(client, "[SM] Cannot setup corners as spectator");
		return Plugin_Handled;
	}

	decl Float:start[3], Float:angle[3], Float:loc[3], Float:bottomLoc[3], Float:topLoc[3];

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
		if(topLoc[2] != 0.0){
			bottomLoc[0] = 0.0;
			bottomLoc[1] = 0.0;
			bottomLoc[2] = 0.0;

			topLoc[0] = 0.0;
			topLoc[1] = 0.0;
			topLoc[2] = 0.0;

			bottomLoc[0] = loc[0];
			bottomLoc[1] = loc[1];
			bottomLoc[2] = loc[2];
		}else{
			if(loc[2] < topLoc[2]){
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
			
			
			new String:query[1024], String:cmap[64];

			Format(query, sizeof(query), "INSERT INTO zones (MapName, number, x1, y1, z1, x2, y2, z2) VALUES (%s, %d, %f, %f, %f, %f, %f, %f)", cmap, numZones, bottomLoc[0], bottomLoc[1], bottomLoc[2], topLoc[0], topLoc[1], topLoc[2]);

			SQL_TQuery(g_hDatabase, SQL_OnCheckpointAdded, query, client);

		}
	}


	ReplyToCommand(client, "\x01[\x04JT\x01] Corner successfully selected");
	return Plugin_Continue;


}

ShowZone(client, Float:bLoc[3], Float:tLoc[3]){
	Effect_DrawBeamBoxToClient(client, bLoc, tLoc, g_BeamSprite, g_HaloSprite, 0, 30);
}

public SQL_OnCheckpointAdded(Handle:owner, Handle:hndl, const String:error[], any:data){

	new client = data;
	
	if (hndl == INVALID_HANDLE) 
	{ 
		LogError("OnCheckPointAdded() - Query failed! %s", error); 
	} 
	else if (SQL_GetRowCount(hndl)) 
	{
		PrintToChat(client, "\x01[\x03JA\x01] Zone creation was successful");
		ShowZone(client, zoneTop[numZones], zoneBottom[numZones]);
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

	new Float:x = l[0]; 
	new Float:y = l[1]; 
	new Float:z = l[2]; 

	new Float:xang = a[0]; 
	new Float:yang = a[1]; 
	new Float:zang = a[2]; 

	startLoc = l;
	startAng = a;

	new String:query[1024], String:cmap[64];
	GetCurrentMap(cmap, sizeof(cmap));

	Format(query, sizeof(query), "INSERT INTO startlocs (MapName, x, y, z, xang, yang, zang) VALUES('%s', '%f', '%f', '%f', '%f', '%f', '%f') ON DUPLICATE KEY UPDATE x='%f',y='%f',z='%f',xang='%f',yang='%f',zang='%f'", cmap, x, y, z, xang, yang, zang, x, y, z, xang, yang, zang);
	PrintToServer(query);
	
	SQL_TQuery(g_hDatabase, SQL_OnStartLocationSet, query, client);
	return Plugin_Continue;


}

public SQL_OnStartLocationSet(Handle:owner, Handle:hndl, const String:error[], any:data){
	
	new client = data;
	
	if (hndl == INVALID_HANDLE) 
	{ 
		LogError("OnStartLocationSet() - Query failed! %s", error); 
	} 
	else if (SQL_GetRowCount(hndl)) 
	{
		
		PrintToChat(client, "\x01[\x03JA\x01] Start location successfully set");
	} 
	else 
	{
		PrintToServer(error);
		PrintToChat(client, "\x01[\x03JA\x01] Start location failed to be set");
		startLoc[0] = 0.0;
		startLoc[1] = 0.0;
		startLoc[2] = 0.0;

		startAng[0] = 0.0;
		startAng[1] = 0.0;
		startAng[2] = 0.0;
		
	} 
}

public bool:TraceEntityFilterPlayer(entity, contentsMask, any:data){
	return entity > MaxClients;
}  


//COPIED FROM SMLIB
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
