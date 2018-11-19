ConVar cvarSoundBlock;
int g_iClientWeapons[MAXPLAYERS+1][3];
char g_sSoundHook[][] = {
	"regenerate",
	"ammo_pickup",
	"pain",
	"fall_damage",
	"grenade_jump",
	"fleshbreak"
};

public Action sound_hook(int clients[64], int& numClients, char sample[PLATFORM_MAX_PATH], int& entity, int& channel, float& volume, int& level, int& pitch, int& flags) {
	if (!GetConVarBool(cvarPluginEnabled)  || GetConVarBool(cvarSoundBlock)) {
		return Plugin_Continue;
	}
	for (int i = 0; i<=sizeof(g_sSoundHook)-1; i++) {
		if (StrContains(sample, g_sSoundHook[i], false) != -1) {
			//PrintToServer("STOPPING SOUND: %s - %i", sample, entity);
			return Plugin_Handled;
		}
	}
	//PrintToServer("ALLOWING SOUND: %s - %i", sample, entity);
	return Plugin_Continue;
}

public Action HookVoice(UserMsg msg_id, BfRead bf, const int[] players, int playersNum, bool reliable, bool init) {
	if (!GetConVarBool(cvarPluginEnabled)) {
		return Plugin_Continue;
	}
	int client = BfReadByte(bf);
	int vMenu1 = BfReadByte(bf);
	int vMenu2 = BfReadByte(bf);
	
	if (IsPlayerAlive(client) && IsValidClient(client) && GetConVarBool(cvarPluginEnabled)) {
		if ((vMenu1 == 0) && (vMenu2 == 0) && !g_bHardcore[client] && !g_bSpeedRun[client] && (!g_iRace[client] || g_fRaceTime[client] != 0.0)) {
			for (int i = 0; i < 3 ; i++) {
				ReSupply(client, g_iClientWeapons[client][i]);
			}
			CreateTimer(0.1, timerRegen, client);
			return Plugin_Continue;
		}
	}
	return Plugin_Continue;
}