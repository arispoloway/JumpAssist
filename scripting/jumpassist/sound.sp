new Handle:g_hSoundBlock;

new g_iClientWeapons[MAXPLAYERS+1][3];

new String:g_sSoundHook[][] = 
{
	"regenerate",
	"ammo_pickup",
	"pain",
	"fall_damage", 
	"grenade_jump", 
	"fleshbreak"
};

public Action:sound_hook(clients[64], &numClients, String:sample[PLATFORM_MAX_PATH], &entity, &channel, &Float:volume, &level, &pitch, &flags)
{
	if (!GetConVarBool(g_hPluginEnabled)  || GetConVarBool(g_hSoundBlock)) { return Plugin_Continue; }
	for (new i = 0; i<=sizeof(g_sSoundHook)-1; i++)
	{
		if (StrContains(sample, g_sSoundHook[i], false) != -1)
		{
			//PrintToServer("STOPPING SOUND: %s - %i", sample, entity);
			return Plugin_Handled;
		}
	}
	//PrintToServer("ALLOWING SOUND: %s - %i", sample, entity);
	return Plugin_Continue;
}
public Action:HookVoice(UserMsg:msg_id, Handle:bf, const players[], playersNum, bool:reliable, bool:init)
{
	if (!GetConVarBool(g_hPluginEnabled)) { return Plugin_Continue; }
	new client = BfReadByte(bf), vMenu1 = BfReadByte(bf), vMenu2 = BfReadByte(bf);
	
	if(IsPlayerAlive(client) && IsValidClient(client) && GetConVarBool(g_hPluginEnabled))
	{
		if((vMenu1 == 0) && (vMenu2 == 0) && !g_bHardcore[client] && !g_bSpeedRun[client] && (!g_bRace[client] || g_bRaceTime[client] != 0.0))
		{
			ReSupply(client, g_iClientWeapons[client][0]);
			ReSupply(client, g_iClientWeapons[client][1]);
			ReSupply(client, g_iClientWeapons[client][2]);
			CreateTimer(0.1, timerRegen, client);
			return Plugin_Continue;
		}
	}
	return Plugin_Continue;
}
