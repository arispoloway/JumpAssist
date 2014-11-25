/*																	TODO
	**********************************************************************************************************************************
	* Done:
	* 0.6.1b - Minor performance improvement. (Constantly checking if the map had regen on every player profile loaded. Changed to check once per map.)
	* 
	* 0.6.2b - JumpAssist NOW REQUIRES SDKHOOKS to be installed.
	* 0.6.2b - Fixed !superman not displaying the correct text/action after a team/class change.
	* 0.6.2b - Re-did the ammo resupply. Correctly supports both jumper weapons now, and other unlocks (Not all weapons added yet).
	* 0.6.2b - Fixed a typo in CreatePlayerProfile where it defaulted the FOV to 90 instead of 70.
	* 0.6.2b - Fixed a couple bugs in LoadPlayerProfile. Everything should load correctly now.
	* 0.6.2b - Fixed a few missing pieces of text in the jumpassist translations file.
	* 0.6.2b - Removed "battle protection" (server admins should make use of !mapset team <red|blu>)
	*
	* 0.6.3b - Re-worked the cap message stuff. Should be 99% better.
	* 0.6.3b - Removed some unreleased stuff I was working on in JA.
	*
	* 0.6.4b - Players using the jumper weapons can no longer use !hardcore.
	* 0.6.4b - Added more to the translations file.
	*
	* 0.6.5b - Added SteamTools
	* 0.6.5b - Added ja_url make your own custom help file.
	*
	* 0.6.6b - Random bug fix
	*
	* 0.6.7b - Better error checking
	*
	* 0.6.8 - Added auto updating to jumpassist. Which makes SteamTools a solid requirement.
	*
	* 0.6.9 - Changed the code around to be more easily maintained.
	*
	* 0.7.0 - Added both options for sqlite and mysql data storage.
	*
	*
	* UNOFICIAL UPDATES
	* 0.7.1 - Regen is working better and skeys has less delay. Also general bugfixes - Author - talkingmelon
	*
	*
	*
	* TODO:
	* Polish for release.
	*
	* BUGS:
	* None reported.
	**********************************************************************************************************************************
	
	
																	NOTES	
	**********************************************************************************************************************************
	*
	* You must have a mysql or sqlite database named jumpassist and configure configured in /addons/sourcemod/configs/databases.cfg
	*
	* Once the database is set up, an example configuration would look like:
	*
	* "jumpassist"
    *     {
    *             "driver"                        "default"
    *             "host"                          "127.0.0.1"
    *             "database"                      "jumpassist"
    *             "user"                          "tf2server"
    *             "pass"                          "tf2serverpassword"
    *             //"timeout"                     "0"
    *             //"port"                        "0"
    *     }
	*
	*
	**********************************************************************************************************************************
	
	
*/
#pragma semicolon 1

#include <sourcemod>
#include <sdktools>
#include <tf2>
#include <tf2_stocks>
#include <sdkhooks>
#include <steamtools>

#undef REQUIRE_PLUGIN
#define REQUIRE_PLUGIN


#define PLUGIN_VERSION "0.7.1"
#define PLUGIN_NAME "[TF2] Jump Assist"
#define PLUGIN_AUTHOR "rush"

#define cDefault    0x01
#define cLightGreen 0x03

/*
	Core Includes
*/
#include "jumpassist/skeys.sp"
#include "jumpassist/skillsrank.sp"
#include "jumpassist/database.sp"
#include "jumpassist/sound.sp"

new Handle:g_hWelcomeMsg;
new Handle:g_hCriticals; 
new Handle:g_hSuperman;
new Handle:g_hSentryLevel;
new Handle:g_hCheapObjects;
new Handle:g_hAmmoCheat;
new Handle:g_hFastBuild;

new String:szWebsite[128] = "http://www.jump.tf/";

public Plugin:myinfo = 
{
	name = PLUGIN_NAME,
	author = PLUGIN_AUTHOR,
	description = "Tools to run a jump server with ease.",
	version = PLUGIN_VERSION,
	url = "http://www.pure-gamers.com"
}
public OnPluginStart()
{
	JA_CreateForward();

	// Skillsrank uses me!
	RegPluginLibrary("jumpassist");

	// ConVars
	CreateConVar("jumpassist_version", PLUGIN_VERSION, "Jump assist version", FCVAR_PLUGIN|FCVAR_SPONLY|FCVAR_REPLICATED|FCVAR_NOTIFY|FCVAR_DONTRECORD);
	g_hPluginEnabled = CreateConVar("ja_enable", "1", "Turns JumpAssist on/off.", FCVAR_PLUGIN|FCVAR_NOTIFY);
	g_hWelcomeMsg = CreateConVar("ja_welcomemsg", "1", "Show clients the welcome message when they join?", FCVAR_PLUGIN|FCVAR_NOTIFY);
	g_hFastBuild = CreateConVar("ja_fastbuild", "1", "Allows engineers near instant buildings.", FCVAR_PLUGIN|FCVAR_NOTIFY);
	g_hAmmoCheat = CreateConVar("ja_ammocheat", "1", "Allows engineers infinite sentrygun ammo.", FCVAR_PLUGIN|FCVAR_NOTIFY);
	g_hCheapObjects = CreateConVar("ja_cheapobjects", "0", "No metal cost on buildings.", FCVAR_PLUGIN|FCVAR_NOTIFY);
	g_hCriticals = CreateConVar("ja_crits", "0", "Allow critical hits.", FCVAR_PLUGIN|FCVAR_NOTIFY);
	g_hSuperman = CreateConVar("ja_superman", "0", "Allows everyone to be invincible.", FCVAR_PLUGIN|FCVAR_NOTIFY);
	g_hSoundBlock = CreateConVar("ja_sounds", "0", "Block pain, regenerate, and ammo pickup sounds?", FCVAR_PLUGIN|FCVAR_NOTIFY);
	g_hSentryLevel = CreateConVar("ja_sglevel", "3", "Sets the default sentry level (1-3)", FCVAR_PLUGIN|FCVAR_NOTIFY);
	
	// Jump Assist console commands
	RegConsoleCmd("ja_save", cmdSave, "Saves your current location.");
	RegConsoleCmd("ja_tele", cmdTele, "Teleports you to your current saved location.");
	RegConsoleCmd("ja_reset", cmdReset, "Sends you back to the beginning without deleting your save..");
	RegConsoleCmd("ja_restart", cmdRestart, "Deletes your save, and sends you back to the beginning.");
	RegConsoleCmd("sm_setmy", cmdSetMy, "Saves player settings.");
	RegConsoleCmd("sm_goto", cmdGotoClient, "Goto <target>");
	RegConsoleCmd("sm_s", cmdSave, "Saves your current position.");
	RegConsoleCmd("sm_regen", cmdDoRegen, "Changes regeneration settings.");
	RegConsoleCmd("sm_undo", cmdUndo, "Restores your last saved position.");
	RegConsoleCmd("sm_t", cmdTele, "Teleports you to your current saved location.");
	RegConsoleCmd("sm_skeys", cmdGetClientKeys, "Toggle showing a clients key's.");
	RegConsoleCmd("sm_skeys_color", cmdChangeSkeysColor, "Changes the color of the text for skeys.");
	RegConsoleCmd("sm_superman", cmdUnkillable, "Makes you strong like superman.");

	// Admin Commands
	RegAdminCmd("sm_mapset", cmdMapSet, ADMFLAG_GENERIC, "Change map settings");
	RegAdminCmd("sm_send", cmdSendPlayer, ADMFLAG_GENERIC, "Send target to another target.");
	RegAdminCmd("sm_jtele", SendToLocation, ADMFLAG_GENERIC, "Sends a player to the spcified jump.");
	RegAdminCmd("sm_addtele", cmdAddTele, ADMFLAG_GENERIC, "Adds a teleport location for the current map");

	// ROOT COMMANDS, they're set to root users for a reason.
	RegAdminCmd("ja_query", RunQuery, ADMFLAG_ROOT, "Runs a SQL query on the JA database. (FOR TESTING)");

	// JM Support
	RegConsoleCmd("jm_saveloc", cmdSave, "Legacy: Saves your current location.");
	RegConsoleCmd("jm_teleport", cmdTele, "Legacy: Teleports you to your current saved location.");
	
	// Hooks
	HookEvent("player_team", eventPlayerChangeTeam);
	HookEvent("player_changeclass", eventPlayerChangeClass);
	HookEvent("player_spawn", eventPlayerSpawn);
	HookEvent("player_death", eventPlayerDeath);
	HookEvent("player_hurt", eventPlayerHurt);
	HookEvent("controlpoint_starttouch", eventTouchCP);
	HookEvent("player_builtobject", eventPlayerBuiltObj);
	HookEvent("player_upgradedobject", eventPlayerUpgradedObj);
	HookEvent("teamplay_round_start", eventRoundStart);

	AddCommandListener(cmdSay, "say");
	AddCommandListener(cmdSay, "say_team");

	// ConVar Hooks
	HookConVarChange(g_hFastBuild, cvarFastBuildChanged);
	HookConVarChange(g_hCheapObjects, cvarCheapObjectsChanged);
	HookConVarChange(g_hAmmoCheat, cvarAmmoCheatChanged);
	HookConVarChange(g_hWelcomeMsg, cvarWelcomeMsgChanged);
	HookConVarChange(g_hSuperman, cvarSupermanChanged);
	HookConVarChange(g_hSoundBlock, cvarSoundsChanged);
	HookConVarChange(g_hSentryLevel, cvarSentryLevelChanged);

	HookUserMessage(GetUserMessageId("VoiceSubtitle"), HookVoice, true);
	AddNormalSoundHook(NormalSHook:sound_hook);

	LoadTranslations("jumpassist.phrases");
	LoadTranslations("common.phrases");

	g_hHostname = FindConVar("hostname");
	HudDisplayForward = CreateHudSynchronizer();
	HudDisplayASD = CreateHudSynchronizer();
	HudDisplayDuck = CreateHudSynchronizer();
	HudDisplayJump = CreateHudSynchronizer();

	ConnectToDatabase();
	SetDesc();
}

public APLRes:AskPluginLoad2(Handle:myself, bool:late, String:error[], err_max)
{
	CreateNative("JA_ClearSave", Native_JA_ClearSave);
	CreateNative("JA_GetSettings", Native_JA_GetSettings);
	CreateNative("JA_PrepSpeedRun", Native_JA_PrepSpeedRun);
	CreateNative("JA_ReloadPlayerSettings", Native_JA_ReloadPlayerSettings);

	g_bLateLoad = late;

	return APLRes_Success;
}
public OnAllPluginsLoaded()
{
	skillsrank = LibraryExists("skillsrank");
}
enum TFGameType {
	TFGame_Unknown,
	TFGame_CaptureTheFlag,
	TFGame_CapturePoint,
	TFGame_Payload,
	TFGame_Arena,
};
TF2_SetGameType()
{
	GameRules_SetProp("m_nGameType", 2);
}
public OnMapStart()
{
	if (GetConVarBool(g_hPluginEnabled))
	{
		SetDesc();
		if (g_hDatabase == INVALID_HANDLE)
		{
			CreateTimer(1.0, timerMapSettings);
		} else {
			LoadMapCFG();
		}

		// Precache cap sounds
		PrecacheSound("misc/tf_nemesis.wav");
		PrecacheSound("misc/freeze_cam.wav");
		
		// Change game rules to CP.
		TF2_SetGameType();
	
		// Find caps, and store the number of them in g_iCPs.
		new iCP = -1; g_iCPs = 0;
		while ((iCP = FindEntityByClassname(iCP, "trigger_capture_area")) != -1)
		{
			g_iCPs++;
		}
		
		// Support for concmap*, and quad* maps that are imported from TFC.
		new entity;
		while ((entity = FindEntityByClassname(entity, "func_regenerate")) != -1)
		{
			g_bRegen = true;
		}
	}
}
public OnClientDisconnect(client)
{
	if (GetConVarBool(g_hPluginEnabled))
	{
		g_bHardcore[client] = false, g_bHPRegen[client] = false, g_bLoadedPlayerSettings[client] = false, g_bBeatTheMap[client] = false;
		g_bGetClientKeys[client] = false, g_bSpeedRun[client] = false, g_bUnkillable[client] = false, Format(g_sCaps[client], sizeof(g_sCaps), "\0");
		
		EraseLocs(client);
	}
}
public OnClientPutInServer(client)
{
	if (GetConVarBool(g_hPluginEnabled))
	{
		// Hook the client
		if(IsValidClient(client)) 
		{
			SDKHook(client, SDKHook_WeaponEquipPost, SDKHook_OnWeaponEquipPost);
		}
		// Load the player profile.
		decl String:sSteamID[64]; GetClientAuthString(client, sSteamID, sizeof(sSteamID));
		LoadPlayerProfile(client, sSteamID);

		// Welcome message. 15 seconds seems to be a good number.
		if (GetConVarBool(g_hWelcomeMsg))
		{
			CreateTimer(15.0, WelcomePlayer, client);
		}
		g_bHardcore[client] = false, g_bHPRegen[client] = false, g_bLoadedPlayerSettings[client] = false, g_bBeatTheMap[client] = false;
		g_bGetClientKeys[client] = false, g_bSpeedRun[client] = false, g_bUnkillable[client] = false, Format(g_sCaps[client], sizeof(g_sCaps), "\0");
	}
}
/*****************************************************************************************************************
												Functions
*****************************************************************************************************************/
stock bool:IsUsingJumper(client)
{
	if (!IsValidClient(client)) { return false; }

	if (TF2_GetPlayerClass(client) == TFClass_Soldier)
	{
		if (!IsValidWeapon(g_iClientWeapons[client][0])) { return false; }
		new sol_weap = GetEntProp(g_iClientWeapons[client][0], Prop_Send, "m_iItemDefinitionIndex");
		switch (sol_weap)
		{
			case 237:
				return true;
		}
		return false;
	}

	if (TF2_GetPlayerClass(client) == TFClass_DemoMan)
	{
		if (!IsValidWeapon(g_iClientWeapons[client][1])) { return false; }
		new dem_weap = GetEntProp(g_iClientWeapons[client][1], Prop_Send, "m_iItemDefinitionIndex");
		switch (dem_weap)
		{
			case 265:
				return true;
		}
		return false;
	}
	return false;
}


stock IsStringNumeric(const String:MyString[])
{
	new n=0;
	while (MyString[n] != '\0') 
	{
		if (!IsCharNumeric(MyString[n]))
		{
			return false;
		}
		n++;
	}
	return true;
}
public Action:RunQuery(client, args)
{
	if (args < 1)
	{
		ReplyToCommand(client, "\x01[\x03JA\x01] More parameters are required for this command.");
		return Plugin_Handled;
	}
	decl String:query[1024];
	GetCmdArgString(query, sizeof(query));
	
	SQL_TQuery(g_hDatabase, SQL_OnPlayerRanSQL, query, client);
	return Plugin_Handled;
}
public Action:cmdUnkillable(client, args)
{
	if (!GetConVarBool(g_hPluginEnabled)) { return Plugin_Handled; }
	if (!GetConVarBool(g_hSuperman) && !IsUserAdmin(client))
	{
		PrintToChat(client, "\x01[\x03JA\x01] %t", "Command_Locked");
		return Plugin_Handled;
	}

	if (g_bSpeedRun[client]) 
	{
		PrintToChat(client, "\x01[\x03JA\x01] %t", "Speedrun_Active");
		return Plugin_Handled;
	}

	if (!g_bUnkillable[client])
	{
		SetEntProp(client, Prop_Data, "m_takedamage", 1, 1);
		PrintToChat(client, "\x01[\x03JA\x01] %t", "Regen_UnkillableOn");
		g_bUnkillable[client] = true;
	} else {
		SetEntProp(client, Prop_Data, "m_takedamage", 2, 1);
		PrintToChat(client, "\x01[\x03JA\x01] %t", "Regen_UnkillableOff");
		g_bUnkillable[client] = false;
	}
	return Plugin_Handled;
}
public Action:cmdUndo(client, args)
{
	if (g_bSpeedRun[client])
	{
		PrintToChat(client, "\x01[\x03JA\x01] %t", "Save_UndoSpeedRun");
		return Plugin_Handled;
	}
	if (g_fLastSavePos[client][0] == 0.0) 
	{
		PrintToChat(client, "\x01[\x03JA\x01] %t", "Save_UndoCant");
		return Plugin_Handled;
	} else {
		g_fOrigin[client][0] = g_fLastSavePos[client][0]; g_fAngles[client][0] = g_fLastSaveAngles[client][0];
		g_fOrigin[client][1] = g_fLastSavePos[client][1]; g_fAngles[client][1] = g_fLastSaveAngles[client][1];
		g_fOrigin[client][2] = g_fLastSavePos[client][2]; g_fAngles[client][2] = g_fLastSaveAngles[client][2];
		
		g_fLastSavePos[client][0] = 0.0; g_fLastSavePos[client][1] = 0.0; g_fLastSavePos[client][2] = 0.0;

		PrintToChat(client, "\x01[\x03JA\x01] %t", "Save_Undo");
		return Plugin_Handled;
	}
}
public Action:cmdDoRegen(client, args)
{
	decl String:arg1[MAX_NAME_LENGTH];
	GetCmdArg(1, arg1, sizeof(arg1));

	if (StrEqual(arg1, "on", false))
	{
		SetRegen(client, "regen", "on");
		return Plugin_Handled;
	} else if (StrEqual(arg1, "off", false)) 
	{
		SetRegen(client, "regen", "off");
		return Plugin_Handled;
	} else {
		SetRegen(client, "Regen", "Display");
	}
	return Plugin_Handled;
}
public Action:cmdClearSave(client, args)
{
	if (GetConVarBool(g_hPluginEnabled))
	{
		EraseLocs(client);
		PrintToChat(client, "\x01[\x03JA\x01] %t", "Player_ClearedSave");
	}
	return Plugin_Handled;
}
public Action:cmdSendPlayer(client, args)
{
	if (GetConVarBool(g_hPluginEnabled))
	{
		if (args < 2)
		{
			ReplyToCommand(client, "\x01[\x03JA\x01] %t", "SendPlayer_Help", LANG_SERVER);
			return Plugin_Handled;
		}
		new String:arg1[MAX_NAME_LENGTH];
		new String:arg2[MAX_NAME_LENGTH];
		GetCmdArg(1, arg1, sizeof(arg1));
		GetCmdArg(2, arg2, sizeof(arg2));

		new target1 = FindTarget2(client, arg1, true, false);
		new target2 = FindTarget2(client, arg2, true, false);
		
		if (target1 == client)
		{
			ReplyToCommand(client, "\x01[\x03JA\x01] %t", "SendPlayer_Self", cLightGreen, cDefault);
			return Plugin_Handled;
		}
		if (!target1 || !target2)
		{
			return Plugin_Handled;	
		}
		new Float:TargetOrigin[3];
		new Float:pAngle[3];
		new Float:pVec[3];
		GetClientAbsOrigin(target2, TargetOrigin);
		GetClientAbsAngles(target2, pAngle);

		pVec[0] = 0.0;
		pVec[1] = 0.0;
		pVec[2] = 0.0;

		TeleportEntity(target1, TargetOrigin, pAngle, pVec);
		
		new String:target1_name[MAX_NAME_LENGTH];
		new String:target2_name[MAX_NAME_LENGTH];

		GetClientName(target1, target1_name, sizeof(target1_name));
		GetClientName(target2, target2_name, sizeof(target2_name));

		ShowActivity2(client, "\x01[\x03JA\x01] ", "%t", "Send_Player", target1_name, target2_name);
	}
	return Plugin_Handled;
}
public Action:cmdGotoClient(client, args)
{
	if (GetConVarBool(g_hPluginEnabled))
	{
		//can use this too g_bBeatTheMap[client] && !g_bSpeedRun[client]
		if (IsUserAdmin(client))
		{
			if (args < 1)
			{
				ReplyToCommand(client, "\x01[\x03JA\x01] %t", "Goto_Help", LANG_SERVER);
				return Plugin_Handled;
			}
			if (IsClientObserver(client))
			{
				ReplyToCommand(client, "\x01[\x03JA\x01] %t", "Goto_Spectate", LANG_SERVER);
				return Plugin_Handled;
			}

			new String:arg1[MAX_NAME_LENGTH];
			GetCmdArg(1, arg1, sizeof(arg1));

			new String:target_name[MAX_TARGET_LENGTH], target_list[MAXPLAYERS], target_count, bool:tn_is_ml;

			new Float:TeleportOrigin[3], Float:PlayerOrigin[3], Float:pAngle[3], Float:PlayerOrigin2[3], Float:g_fPosVec[3];
			if ((target_count = ProcessTargetString(arg1, client, target_list, MAXPLAYERS, COMMAND_FILTER_NO_IMMUNITY, target_name, sizeof(target_name), tn_is_ml)) <= 0)
			{
				ReplyToCommand(client, "\x01[\x03JA\x01] %t", "No matching client", LANG_SERVER);
				return Plugin_Handled;
			}
			if (target_count > 1)
			{
				ReplyToCommand(client, "\x01[\x03JA\x01] %t", "More than one client matched", LANG_SERVER);
				return Plugin_Handled;
			}
			for (new i = 0; i < target_count; i++)
			{
				if (IsClientObserver(target_list[i]) || !IsValidClient(target_list[i]))
				{
					ReplyToCommand(client, "\x01[\x03JA\x01] %t", "Goto_Cant", LANG_SERVER, target_name);
					return Plugin_Handled;
				}
				if (target_list[i] == client)
				{
					ReplyToCommand(client, "\x01[\x03JA\x01] %t", "Goto_Self", LANG_SERVER);
					return Plugin_Handled;
				}
				GetClientAbsOrigin(target_list[i], PlayerOrigin);
				GetClientAbsAngles(target_list[i], PlayerOrigin2);

				TeleportOrigin[0] = PlayerOrigin[0];
				TeleportOrigin[1] = PlayerOrigin[1];
				TeleportOrigin[2] = PlayerOrigin[2];

				pAngle[0] = PlayerOrigin2[0];
				pAngle[1] = PlayerOrigin2[1];
				pAngle[2] = PlayerOrigin2[2];

				g_fPosVec[0] = 0.0;
				g_fPosVec[1] = 0.0;
				g_fPosVec[2] = 0.0;

				TeleportEntity(client, TeleportOrigin, pAngle, g_fPosVec);
				PrintToChat(client, "\x01[\x03JA\x01] %t", "Goto_Success", target_name);
			}
		} else {
			ReplyToCommand(client, "\x01[\x03JA\x01] %t", "No Access", LANG_SERVER);
			return Plugin_Handled;
		}
	}
	return Plugin_Handled;
}
public Action:cmdReset(client, args)
{
	if (GetConVarBool(g_hPluginEnabled))
	{
		if (skillsrank)
		{
			if (IsPlayerBusy(client))
			{
				PrintToChat(client, "\x01[\x03JA\x01] %t", "General_Busy");
				return Plugin_Handled;
			}
		}
		if (!IsClientObserver(client))
		{
			return Plugin_Handled;
		}
		g_fOrigin[client][0] = 0.0;
		g_fOrigin[client][1] = 0.0;
		g_fOrigin[client][2] = 0.0;
		g_fAngles[client][0] = 0.0;
		g_fAngles[client][1] = 0.0;
		g_fAngles[client][2] = 0.0;
		
		EraseLocs(client);
		g_bUsedReset[client] = true;

		TF2_RespawnPlayer(client);
		PrintToChat(client, "\x01[\x03JA\x01] %t", "Player_SentToStart");
	}
	return Plugin_Handled;
}
public Action:cmdSay(client, const String:command[], args)
{
	new String:text[192];
	GetCmdArgString(text, sizeof(text));
	
	new startidx = 0;
	if (text[0] == '"')
	{
		startidx = 1;
		new len = strlen(text);
		if (text[len-1] == '"')
		{
			text[len-1] = '\0';
		}
	}
	if (StrEqual(text[startidx], "!s", false))
	{
		return Plugin_Handled;
	}
	if (StrEqual(text[startidx], "!t", false))
	{
		return Plugin_Handled;
	}
	if (StrEqual(text[startidx], "!r", false))
	{
		SendToStart(client);
	}
	if (StrEqual(text[startidx], "!reset", false))
	{
		SendToStart(client);
	}
	if (StrEqual(text[startidx], "!restart", false))
	{
		ResetPlayerPos(client);
		EraseLocs(client);
	}
	if (StrEqual(text[startidx], "!ja_tele", false))
	{
		return Plugin_Handled;
	}
	if (StrEqual(text[startidx], "!ja_save", false))
	{
		return Plugin_Handled;
	}
	if (StrEqual(text[startidx], "!ja_reset", false))
	{
		return Plugin_Handled;
	}
	if (StrEqual(text[startidx], "!jm_teleport", false))
	{
		return Plugin_Handled;
	}
	if (StrEqual(text[startidx], "!jm_saveloc", false))
	{
		return Plugin_Handled;
	}
	if (StrEqual(text[startidx], "!ammo", false))
	{
		SetRegen(client, "Ammo", "z");
	}
	if (StrEqual(text[startidx], "!health", false))
	{
		SetRegen(client, "Health", "z");
	}
	if (StrEqual(text[startidx], "!hardcore", false))
	{
		if (IsUsingJumper(client))
		{
			PrintToChat(client, "\x01[\x03JA\x01] %t", "Jumper_Command_Disabled");
			return Plugin_Handled;
		}
		Hardcore(client);
	}
	if (StrEqual(text[startidx], "!ja_help", false))
	{
		JumpHelp(client);
	}
	if (StrEqual(text[startidx], "/s", false))
	{
		return Plugin_Handled;
	}
	if (StrEqual(text[startidx], "/t", false))
	{
		return Plugin_Handled;
	}
	if (StrEqual(text[startidx], "/r", false))
	{
		SendToStart(client);
		return Plugin_Handled;
	}
	if (StrEqual(text[startidx], "/reset", false))
	{
		SendToStart(client);
		return Plugin_Handled;
	}
	if (StrEqual(text[startidx], "/restart", false))
	{
		ResetPlayerPos(client);
		EraseLocs(client);
		return Plugin_Handled;
	}
	if (StrEqual(text[startidx], "/ja_tele", false))
	{
		return Plugin_Handled;
	}
	if (StrEqual(text[startidx], "/ja_save", false))
	{
		return Plugin_Handled;
	}
	if (StrEqual(text[startidx], "/ja_reset", false))
	{
		return Plugin_Handled;
	}
	if (StrEqual(text[startidx], "/jm_teleport", false))
	{
		return Plugin_Handled;
	}
	if (StrEqual(text[startidx], "/jm_saveloc", false))
	{
		return Plugin_Handled;
	}
	if (StrEqual(text[startidx], "/ammo", false))
	{
		SetRegen(client, "Ammo", "z");
		return Plugin_Handled;
	}
	if (StrEqual(text[startidx], "/health", false))
	{
		SetRegen(client, "Health", "z");
		return Plugin_Handled;
	}
	if (StrEqual(text[startidx], "/hardcore", false))
	{
		if (IsUsingJumper(client))
		{
			PrintToChat(client, "\x01[\x03JA\x01] %t", "Jumper_Command_Disabled");
			return Plugin_Handled;
		}
		Hardcore(client);
		return Plugin_Handled;
	}
	if (StrEqual(text[startidx], "/ja_help", false))
	{
		JumpHelp(client);
		return Plugin_Handled;
	}
	return Plugin_Continue;
}
public Action:cmdTele(client, args)
{
	if (!GetConVarBool(g_hPluginEnabled)) { return Plugin_Handled; }
	Teleport(client);
	return Plugin_Handled;
}
public Action:cmdSave(client, args)
{
	if (!GetConVarBool(g_hPluginEnabled)) { return Plugin_Handled; }
	SaveLoc(client);
	return Plugin_Handled;
}
Teleport(client)
{
	if (!GetConVarBool(g_hPluginEnabled)) { return; }
	if (!IsValidClient(client)) { return; }

	if (g_bSpeedRun[client]) 
	{
		PrintToChat(client, "\x01[\x03JA\x01] %t", "Speedrun_Active");
		return;
	}
	new g_iClass = int:TF2_GetPlayerClass(client);
	new g_iTeam = GetClientTeam(client);
	decl String:g_sClass[32], String:g_sTeam[32];
	new Float:g_vVelocity[3];
	g_vVelocity[0] = 0.0; g_vVelocity[1] = 0.0; g_vVelocity[2] = 0.0;

	Format(g_sClass, sizeof(g_sClass), "%s", GetClassname(g_iClass));

	if (g_iTeam == 2)
	{
		Format(g_sTeam, sizeof(g_sTeam), "%T", "Red_Team", LANG_SERVER);
	} else if (g_iTeam == 3)
	{
		Format(g_sTeam, sizeof(g_sTeam), "%T", "Blu_Team", LANG_SERVER);
	}
	if (g_bHardcore[client])
		PrintToChat(client, "\x01[\x03JA\x01] %t", "Teleports_Disabled");
	else if(!IsPlayerAlive(client))
		PrintToChat(client, "\x01[\x03JA\x01] %t", "Teleport_Dead");
	else if(g_fOrigin[client][0] == 0.0)
		PrintToChat(client, "\x01[\x03JA\x01] %t", "Teleport_NoSave", g_sClass, g_sTeam, cLightGreen, cDefault, cLightGreen, cDefault);
	else
	{
		TeleportEntity(client, g_fOrigin[client], g_fAngles[client], g_vVelocity);
		PrintToChat(client, "\x01[\x03JA\x01] %t", "Teleported_Self");
	}
}
SaveLoc(client)
{
	if (!GetConVarBool(g_hPluginEnabled)) { return; }
	if (g_bSpeedRun[client]) 
	{
		PrintToChat(client, "\x01[\x03JA\x01] %t", "Speedrun_Active");
		return;
	}
	if (g_bHardcore[client])
		PrintToChat(client, "\x01[\x03JA\x01] %t", "Saves_Disabled");
	else if(!IsPlayerAlive(client))
		PrintToChat(client, "\x01[\x03JA\x01] %t", "Saves_Dead");	
	else if(!(GetEntityFlags(client) & FL_ONGROUND))
		PrintToChat(client, "\x01[\x03JA\x01] %t", "Saves_InAir");
	else if(GetEntProp(client, Prop_Send, "m_bDucked") == 1)
		PrintToChat(client, "\x01[\x03JA\x01] %t", "Saves_Ducked");
	else
	{
		g_fLastSavePos[client][0] = g_fOrigin[client][0]; g_fLastSaveAngles[client][0] = g_fAngles[client][0];
		g_fLastSavePos[client][1] = g_fOrigin[client][1]; g_fLastSaveAngles[client][1] = g_fAngles[client][1];
		g_fLastSavePos[client][2] = g_fOrigin[client][2]; g_fLastSaveAngles[client][2] = g_fAngles[client][2];

		GetClientAbsOrigin(client, g_fOrigin[client]);
		GetClientAbsAngles(client, g_fAngles[client]);
		GetPlayerData(client);
		PrintToChat(client, "\x01[\x03JA\x01] %t", "Saves_Location");
	}
}
ResetPlayerPos(client)
{
	if (!GetConVarBool(g_hPluginEnabled)) { return; }
	if (!IsClientInGame(client) || IsClientObserver(client))
	{
		return;
	}
	DeletePlayerData(client);
	return;
}
Hardcore(client)
{
	if (!GetConVarBool(g_hPluginEnabled)) { return; }

	if (skillsrank)
	{
		if (IsPlayerBusy(client))
		{
			PrintToChat(client, "\x01[\x03JA\x01] %t", "Hardcore_SettingsBusy");
			return;
		}
	}

	new String:steamid[32];
	GetClientAuthString(client, steamid, sizeof(steamid));

	if (!IsClientInGame(client))
	{
		return;
	}
	else if (IsClientObserver(client))
	{
		return;
	}
	if (!g_bHardcore[client]) 
	{
		g_bHardcore[client] = true;
		g_bHPRegen[client] = false;
		EraseLocs(client);
		TF2_RespawnPlayer(client);
		PrintToChat(client, "\x01[\x03JA\x01] %t", "Hardcore_On", cLightGreen, cDefault);
	} else {
		g_bHardcore[client] = false;
		LoadPlayerData(client);
		PrintToChat(client, "\x01[\x03JA\x01] %t", "Hardcore_Off");
	}
}
SetDesc()
{
	decl String:desc[128];
	Format(desc, sizeof(desc), "Jump Assist (%s)", PLUGIN_VERSION);
	Steam_SetGameDescription(desc);
}
SetRegen(client, String:RegenType[], String:RegenToggle[])
{
	if (!GetConVarBool(g_hPluginEnabled)) { return; }

	if (skillsrank)
	{
		if (IsPlayerBusy(client))
		{
			PrintToChat(client, "\x01[\x03JA\x01] %t", "Regen_SettingsBusy");
			return;
		}
	}

	if (StrEqual(RegenType, "Ammo", false))
	{
		if (g_bHardcore[client]) { g_bHardcore[client] = false; }
		if (!g_bAmmoRegen[client])
		{
			g_bAmmoRegen[client] = true;
			PrintToChat(client, "\x01[\x03JA\x01] %t", "Regen_AmmoOnlyOn");
			return;
		} else {
			g_bAmmoRegen[client] = false;
			PrintToChat(client, "\x01[\x03JA\x01] %t", "Regen_AmmoOnlyOff");
			return;
		}
	}
	if (StrEqual(RegenType, "Health", false))
	{
		if (g_bHardcore[client]) { g_bHardcore[client] = false; }
		if (!g_bHPRegen[client])
		{
			g_bHPRegen[client] = true;
			PrintToChat(client, "\x01[\x03JA\x01] %t", "Regen_HealthOnlyOn");
			return;
		} else {
			g_bHPRegen[client] = false;
			PrintToChat(client, "\x01[\x03JA\x01] %t", "Regen_HealthOnlyOff");
			return;
		}
	}
	if (StrEqual(RegenType, "Regen", false) && StrEqual(RegenToggle, "display", false))
	{
		if (!g_bAmmoRegen[client])
		{
			PrintToChat(client, "\x01[\x03JA\x01] %t", "Regen_DisplayAmmoOff");
		} else {
			PrintToChat(client, "\x01[\x03JA\x01] %t", "Regen_DisplayAmmoOn");
		}
		if (!g_bHPRegen[client])
		{
			PrintToChat(client, "\x01[\x03JA\x01] %t", "Regen_DisplayHealthOff");
		} else {
			PrintToChat(client, "\x01[\x03JA\x01] %t", "Regen_DisplayHealthOn");
		}
		PrintToChat(client, "\x01[\x03JA\x01] %t", "Regen_ShowHelp");
		return;
	} else if (StrEqual(RegenType, "Regen", false) && StrEqual(RegenToggle, "on", false))
	{
		g_bAmmoRegen[client] = true;
		g_bHPRegen[client] = true;
		
		if (g_bHardcore[client]) { g_bHardcore[client] = false; }
		PrintToChat(client, "\x01[\x03JA\x01] %t", "Regen_On");
	} else if (StrEqual(RegenType, "Regen", false) && StrEqual(RegenToggle, "off", false))
	{
		g_bAmmoRegen[client] = false;
		g_bHPRegen[client] = false;
		
		if (g_bHardcore[client]) { g_bHardcore[client] = false; }
		PrintToChat(client, "\x01[\x03JA\x01] %t", "Regen_Off");
	} else {
		LogError("Unknown regen settings.");
	}
	return;
}
stock JumpHelp(client)
{
	if (!GetConVarBool(g_hPluginEnabled)) { return; }
	ShowMOTDPanel(client, "Jump Assist Help", szWebsite, MOTDPANEL_TYPE_URL);
	return;
}
public Action:OnPlayerRunCmd(client, &buttons, &impulse, Float:vel[3], Float:angles[3], &weapon){

	g_iButtons[client] = buttons; //FOR SKEYS AS WELL AS REGEN
	if ((g_iButtons[client] & IN_ATTACK) == IN_ATTACK)
	{
		if (g_bAmmoRegen[client])
		{
			ReSupply(client, g_iClientWeapons[client][0]);
			ReSupply(client, g_iClientWeapons[client][1]);
			ReSupply(client, g_iClientWeapons[client][2]);
		}
		if (g_bHPRegen[client]){
			new iMaxHealth = TF2_GetPlayerResourceData(client, TFResource_MaxHealth);
			SetEntityHealth(client, iMaxHealth);
		}
	}

}

public SDKHook_OnWeaponEquipPost(client, weapon)
{
	if (IsValidClient(client))
	{
		g_iClientWeapons[client][0] = GetPlayerWeaponSlot(client, TFWeaponSlot_Primary);
		g_iClientWeapons[client][1] = GetPlayerWeaponSlot(client, TFWeaponSlot_Secondary);
		g_iClientWeapons[client][2] = GetPlayerWeaponSlot(client, TFWeaponSlot_Melee);
	}
}
stock bool:IsValidWeapon(iEntity)
{
	decl String:strClassname[128];
	if (IsValidEntity(iEntity) && GetEntityClassname(iEntity, strClassname, sizeof(strClassname)) && StrContains(strClassname, "tf_weapon", false) != -1) return true;
	return false;
}
stock ReSupply(client, iWeapon)
{
	if (!GetConVarBool(g_hPluginEnabled)) { return; }
	if (!IsValidWeapon(iWeapon))
	{
		return;
	}

	// Primary Weapons
	switch(GetEntProp(iWeapon, Prop_Send, "m_iItemDefinitionIndex"))
	{
		// Rocket Launchers
		case 18,205,127,513,800,809,658:
		{
			SetEntProp(iWeapon, Prop_Data, "m_iClip1", 4);
			SetAmmo(client, iWeapon, 20);
		}
		// Black box, Liberty launcher.
		case 228, 414:
		{
			SetEntProp(iWeapon, Prop_Data, "m_iClip1", 3);
			SetAmmo(client, iWeapon, 20);
		}
		// Rocket Jumper
		case 237:
		{
			SetEntProp(iWeapon, Prop_Data, "m_iClip1", 4);
			SetAmmo(client, iWeapon, 60);
		}
		
		// Ullapool caber
		/* Removed
		case 307:
		{
			if (GetConVarBool(g_hReloadUC))
			{
				SetEntProp(iWeapon, Prop_Send, "m_bBroken", 0);
				SetEntProp(iWeapon, Prop_Send, "m_iDetonated", 0);
			}
		}
		*/
		
		// Stickybomb Launchers
		case 20, 207:
		{
			SetEntProp(iWeapon, Prop_Data, "m_iClip1", 8);
			SetAmmo(client, iWeapon, 24);
		}
		// Sticky jumper
		case 265:
		{
			SetEntProp(iWeapon, Prop_Data, "m_iClip1", 8);
			SetAmmo(client, iWeapon, 72);
		}
		// Scottish Resistance
		case 130:
		{
			SetEntProp(iWeapon, Prop_Data, "m_iClip1", 8);
			SetAmmo(client, iWeapon, 36);
		}
		// Heavy, soldier, pyro, and engineer shotgun
		case 9, 10, 11, 12, 199:
		{
			SetEntProp(iWeapon, Prop_Data, "m_iClip1", 6);
			SetAmmo(client, iWeapon, 32);
		}
	}
}
stock SetAmmo(client, iWeapon, iAmmo)
{
	new iAmmoType = GetEntProp(iWeapon, Prop_Send, "m_iPrimaryAmmoType");
	if(iAmmoType != -1) SetEntProp(client, Prop_Data, "m_iAmmo", iAmmo, _, iAmmoType);
}
EraseLocs(client)
{
	if (!GetConVarBool(g_hPluginEnabled)) { return; }

	g_fOrigin[client][0] = 0.0; g_fOrigin[client][1] = 0.0; g_fOrigin[client][2] = 0.0;
	g_fAngles[client][0] = 0.0; g_fAngles[client][1] = 0.0; g_fAngles[client][2] = 0.0;
	
	for(new j = 0; j < 8; j++)
	{
		g_bCPTouched[client][j] = false;
		g_iCPsTouched[client] = 0;
	}
	g_bBeatTheMap[client] = false;
	Format(g_sCaps[client], sizeof(g_sCaps), "\0");
}
CheckTeams()
{
	if (!GetConVarBool(g_hPluginEnabled)) { return; }
	new maxplayers = GetMaxClients();
	for (new i=1; i<=maxplayers; i++)
	{
		if (!IsClientInGame(i) || IsClientObserver(i))
		{
			continue;
		} else if (GetClientTeam(i) == g_iForceTeam)
		{
			continue;
		}
		else {
			ChangeClientTeam(i, g_iForceTeam);
			PrintToChat(i, "\x01[\x03JA\x01] %t", "Switched_Teams");
		}
	}
}
LockCPs()
{
	if (!GetConVarBool(g_hPluginEnabled)) { return; }
	new iCP = -1;
	g_iCPs = 0;
	while ((iCP = FindEntityByClassname(iCP, "trigger_capture_area")) != -1)
	{
		SetVariantString("2 0");
		AcceptEntityInput(iCP, "SetTeamCanCap");
		SetVariantString("3 0");
		AcceptEntityInput(iCP, "SetTeamCanCap");
		g_iCPs++;
	}
}
public Action:cmdRestart(client, args)
{
	if (!IsValidClient(client) || IsClientObserver(client) || !GetConVarBool(g_hPluginEnabled))
	{		
		return Plugin_Handled;
	}
	if (skillsrank)
	{	
		if (IsPlayerBusy(client))
		{
			PrintToChat(client, "\x01[\x03JA\x01] %t", "General_Busy");
			return Plugin_Handled;
		}
	}
	
	EraseLocs(client);
	ResetPlayerPos(client);
	return Plugin_Handled;
}
SendToStart(client)
{
	if (!IsValidClient(client) || IsClientObserver(client) || !GetConVarBool(g_hPluginEnabled))
	{
		return;
	}

	EraseLocs(client);
	g_bUsedReset[client] = true;

	TF2_RespawnPlayer(client);
	PrintToChat(client, "\x01[\x03JA\x01] %t", "Player_SentToStart");
}
stock String:GetClassname(class)
{
	new String:buffer[128];
	switch(class)
	{
		case 1:	{ Format(buffer, sizeof(buffer), "%T", "Class_Scout", LANG_SERVER); }
		case 2: { Format(buffer, sizeof(buffer), "%T", "Class_Sniper", LANG_SERVER); }
		case 3: { Format(buffer, sizeof(buffer), "%T", "Class_Soldier", LANG_SERVER); }
		case 4: { Format(buffer, sizeof(buffer), "%T", "Class_Demoman", LANG_SERVER); }
		case 5: { Format(buffer, sizeof(buffer), "%T", "Class_Medic", LANG_SERVER); }
		case 6: { Format(buffer, sizeof(buffer), "%T", "Class_Heavy", LANG_SERVER); }
		case 7: { Format(buffer, sizeof(buffer), "%T", "Class_Pyro", LANG_SERVER); }
		case 8: { Format(buffer, sizeof(buffer), "%T", "Class_Spy", LANG_SERVER); }
		case 9: { Format(buffer, sizeof(buffer), "%T", "Class_Engineer", LANG_SERVER); }
	}
	return buffer;
}
bool:IsValidClient( client )
{
    if ( !( 1 <= client <= MaxClients ) || !IsClientInGame(client) )
        return false;
    
    return true;
}
public jteleHandler(Handle:menu, MenuAction:action, client, item)
{
	//decl String:MenuInfo[64];
	if (action == MenuAction_Select)
	{
		GetMenuItem(menu, item, Jtele, sizeof(Jtele));
		JumpList(client);
	} else if (action == MenuAction_End) {
		CloseHandle(menu);
	}
	return;
}
stock FindTarget2(client, const String:target[], bool:nobots = false, bool:immunity = true)
{
	decl String:target_name[MAX_TARGET_LENGTH];
	decl target_list[1], target_count, bool:tn_is_ml;

	new flags = COMMAND_FILTER_NO_MULTI;
	if (nobots)
	{
		flags |= COMMAND_FILTER_NO_BOTS;
	}
	if (!immunity)
	{
		flags |= COMMAND_FILTER_NO_IMMUNITY;
	}
	
	if ((target_count = ProcessTargetString(
			target,
			client, 
			target_list, 
			1, 
			flags,
			target_name,
			sizeof(target_name),
			tn_is_ml)) > 0)
	{
		return target_list[0];
	}
	else
	{
		if (target_count == 0) { return -1; }
		ReplyToCommand(client, "\x01[\x03JA\x01] %t", "No matching client");
		return -1;
	}
}
// Ugly wtf was I thinking?
stock GetValidClassNum(String:class[])
{
	new iClass = -1;
	if(StrEqual(class,"scout", false))
	{
		iClass = 1;
		return iClass;
	}
	if(StrEqual(class,"sniper", false))
	{
		iClass = 2;
		return iClass;
	}
	if(StrEqual(class,"soldier", false))
	{
		iClass = 3;
		return iClass;
	}
	if(StrEqual(class,"demoman", false))
	{
		iClass = 4;
		return iClass;
	}
	if(StrEqual(class,"medic", false))
	{
		iClass = 5;
		return iClass;
	}
	if(StrEqual(class,"heavy", false))
	{
		iClass = 6;
		return iClass;
	}
	if(StrEqual(class,"pyro", false))
	{
		iClass = 7;
		return iClass;
	}
	if(StrEqual(class,"spy", false))
	{
		iClass = 8;
		return iClass;
	}
	if(StrEqual(class,"engineer", false))
	{
		iClass = 9;
		return iClass;
	}
	return iClass;
}
public JumpListHandler(Handle:menu, MenuAction:action, client, item)
{
	decl String:MenuInfo[64];
	if (action == MenuAction_Select)
	{
		GetMenuItem(menu, item, MenuInfo, sizeof(MenuInfo));
		MenuSendToLocation(client, Jtele, MenuInfo);
	} else if (action == MenuAction_End) {
		CloseHandle(menu);
	}
	return;
}
stock bool:IsUserAdmin(client)
{
	new bool:IsAdmin = GetAdminFlag(GetUserAdmin(client), Admin_Generic);

	if (IsAdmin)
		return true;
	else
		return false;
}
stock SetCvarValues()
{
	if (!GetConVarBool(g_hPluginEnabled)) { return; }
	if (!GetConVarBool(g_hCriticals))
		SetConVarInt(FindConVar("tf_weapon_criticals"), 0, true, false);
	if (GetConVarBool(g_hFastBuild))
		SetConVarInt(FindConVar("tf_fastbuild"), 1, false, false);
	if (GetConVarBool(g_hCheapObjects))
		SetConVarInt(FindConVar("tf_cheapobjects"), 1, false, false);
	if (GetConVarBool(g_hAmmoCheat))
		SetConVarInt(FindConVar("tf_sentrygun_ammocheat"), 1, false, false); 
}
/*****************************************************************************************************************
													Natives
*****************************************************************************************************************/
public Native_JA_GetSettings(Handle:plugin, numParams)
{
	new setting = GetNativeCell(1);
	new client = GetNativeCell(2);
	
	if (client != -1)
	{
		// Client is only needed for all but 1 setting so far.
		if (client < 1 || client > GetMaxClients())
		{
			return ThrowNativeError(SP_ERROR_NATIVE, "Invalid client index (%d)", client);
		}
		if (!IsClientConnected(client))
		{
			return ThrowNativeError(SP_ERROR_NATIVE, "Client %d is not connected", client);
		}
	}
	
	switch (setting)
	{
		case 1: { return g_iMapClass; }
		case 2: { return g_bAmmoRegen[client]; }
		case 3: { return g_bHPRegen[client]; }
	}
	return ThrowNativeError(SP_ERROR_NATIVE, "Invalid setting param.");
}
public Native_JA_ClearSave(Handle:plugin, numParams)
{
	new client = GetNativeCell(1);

	if (client < 1 || client > GetMaxClients())
	{
		return ThrowNativeError(SP_ERROR_NATIVE, "Invalid client index (%d)", client);
	}
	if (!IsClientConnected(client))
	{
		return ThrowNativeError(SP_ERROR_NATIVE, "Client %d is not connected", client);
	}
	
	EraseLocs(client);
	PrintToChat(client, "\x01[\x03JA\x01] %t", "Native_ClearSave");
	return true;
}
public Native_JA_PrepSpeedRun(Handle:plugin, numParams)
{
	new client = GetNativeCell(1);

	if (client < 1 || client > GetMaxClients())
	{
		return ThrowNativeError(SP_ERROR_NATIVE, "Invalid client index (%d)", client);
	}
	if (!IsClientConnected(client))
	{
		return ThrowNativeError(SP_ERROR_NATIVE, "Client %d is not connected", client);
	}

	EraseLocs(client);

	if (g_bUnkillable[client]) { g_bUnkillable[client] = false; SetEntProp(client, Prop_Data, "m_takedamage", 2, 1); }
	
	g_bSpeedRun[client] = true;
	PrintToChat(client, "\x01[\x03JA\x01] %t", "Native_ClearSave");

	return true;
}
public Native_JA_ReloadPlayerSettings(Handle:plugin, numParams)
{
	new client = GetNativeCell(1);

	if (client < 1 || client > GetMaxClients())
	{
		return ThrowNativeError(SP_ERROR_NATIVE, "Invalid client index (%d)", client);
	}
	if (!IsClientConnected(client))
	{
		return ThrowNativeError(SP_ERROR_NATIVE, "Client %d is not connected", client);
	}

	g_bSpeedRun[client] = false;
	ReloadPlayerData(client);
	return true;
}
/*****************************************************************************************************************
												Player Events
*****************************************************************************************************************/
public Action:eventPlayerBuiltObj(Handle:event, const String:name[], bool:dontBroadcast)
{
	if (!GetConVarBool(g_hPluginEnabled)) { return; }
	new client = GetClientOfUserId(GetEventInt(event, "userid")), object = GetEventInt(event, "object"), index = GetEventInt(event, "index");
	
	if (object == 2)
	{
		if (GetConVarInt(g_hSentryLevel) == 3)
		{
			SetEntData(index, FindSendPropOffs("CObjectSentrygun", "m_iUpgradeLevel"), 3, 4);
			SetEntData(index, FindSendPropOffs("CObjectSentrygun", "m_iUpgradeMetal"), 200);
		}
	}
	if (!g_bHardcore[client])
	{
		SetEntData(client, FindDataMapOffs(client, "m_iAmmo") + (3 * 4), 199, 4);
	}
}
public Action:eventPlayerUpgradedObj(Handle:event, const String:name[], bool:dontBroadcast)
{
	if (!GetConVarBool(g_hPluginEnabled)) { return; }
	new client = GetClientOfUserId(GetEventInt(event, "userid")); //object = GetEventInt(event, "object"), index = GetEventInt(event, "index");

	if (!g_bHardcore[client])
	{
		SetEntData(client, FindDataMapOffs(client, "m_iAmmo") + (3 * 4), 199, 4);
	}
}
public Action:eventRoundStart(Handle:event, const String:name[], bool:dontBroadcast)
{
	decl String:currentMap[32]; GetCurrentMap(currentMap, sizeof(currentMap));
	if (!GetConVarBool(g_hPluginEnabled)) { return; }

	if (g_iLockCPs == 1) { LockCPs(); }

	SetCvarValues();
}
public Action:eventTouchCP(Handle:event, const String:name[], bool:dontBroadcast)
{
	if (!GetConVarBool(g_hPluginEnabled)) { return; }

	new client = GetEventInt(event, "player"), area = GetEventInt(event, "area"), class = int:TF2_GetPlayerClass(client), entity;
	decl String:g_sClass[33], String:playerName[64], String:cpName[32], String:s_area[32];
	
	if (!g_bCPTouched[client][area])
	{
		g_bCPTouched[client][area] = true; g_iCPsTouched[client]++; IntToString(area, s_area, sizeof(s_area));
		if (g_sCaps[client] != -1) { Format(g_sCaps[client], sizeof(g_sCaps), "%s%s", g_sCaps[client], s_area); } else { Format(g_sCaps[client], sizeof(g_sCaps), "%s", s_area); }

		Format(g_sClass, sizeof(g_sClass), "%s", GetClassname(class));
		GetClientName(client, playerName, 64);
		
		while ((entity = FindEntityByClassname(entity, "team_control_point")) != -1)
		{
			new pIndex = GetEntProp(entity, Prop_Data, "m_iPointIndex");
			if (pIndex == area)
			{
				GetEntPropString(entity, Prop_Data, "m_iszPrintName", cpName, sizeof(cpName));

				if (g_bHardcore[client])
				{
					// "Hardcore" mode
					PrintToChatAll("\x01[\x03JA\x01] %t", "Player_Capped_BOSS", playerName, cpName, g_sClass, cLightGreen, cDefault, cLightGreen, cDefault, cLightGreen, cDefault);
					EmitSoundToAll("misc/tf_nemesis.wav");
				} else {
					// Normal mode
					PrintToChatAll("\x01[\x03JA\x01] %t", "Player_Capped", playerName, cpName, g_sClass, cLightGreen, cDefault, cLightGreen, cDefault, cLightGreen, cDefault);
					EmitSoundToAll("misc/freeze_cam.wav");
				}

				if (g_iCPsTouched[client] == g_iCPs)
				{
					g_bBeatTheMap[client] = true;
					//PrintToChat(client, "\x01[\x03JA\x01] %t", "Goto_Avail");
				}
			}
			//SaveCapData(client);
		}
	}
}
public Action:eventPlayerChangeClass(Handle:event, const String:name[], bool:dontBroadcast)
{
	if (!GetConVarBool(g_hPluginEnabled)) { return; }
	new client = GetClientOfUserId(GetEventInt(event, "userid"));
	decl String:g_sClass[MAX_NAME_LENGTH], String:steamid[32];

	EraseLocs(client);
	TF2_RespawnPlayer(client);
	
	g_bUnkillable[client] = false;
	
	GetClientAuthString(client, steamid, sizeof(steamid));

	new class = int:TF2_GetPlayerClass(client);
	Format(g_sClass, sizeof(g_sClass), "%s", GetClassname(g_iMapClass));

	if (g_iMapClass != -1)
	{
		if (class != g_iMapClass)
		{
			g_bHPRegen[client] = true;
			g_bAmmoRegen[client] = true;
			g_bHardcore[client] = false;

			PrintToChat(client, "\x01[\x03JA\x01] %t", "Designed_For", cLightGreen, g_sClass, cDefault);
		}
	}
}
public Action:eventPlayerChangeTeam(Handle:event, const String:name[], bool:dontBroadcast)
{
	if (!GetConVarBool(g_hPluginEnabled)) { return; }
	new client = GetClientOfUserId(GetEventInt(event, "userid")), team = GetEventInt(event, "team");

	g_bUnkillable[client] = false;

	if (team == 1 || g_iForceTeam == 1 || team == g_iForceTeam)
	{
		EraseLocs(client);
		return;
	} else {
		CreateTimer(0.1, timerTeam, client);
		return;
	}
}
public Action:eventPlayerDeath(Handle:event, const String:name[], bool:dontBroadcast)
{
	if (!GetConVarBool(g_hPluginEnabled)) { return; }
	new client = GetClientOfUserId(GetEventInt(event, "userid"));
	CreateTimer(0.1, timerRespawn, client);
}
public Action:eventPlayerHurt(Handle:event, const String:name[], bool:dontBroadcast)
{
	if (!GetConVarBool(g_hPluginEnabled)) { return; }
	new client = GetClientOfUserId(GetEventInt(event, "userid"));
	
	if (g_bHPRegen[client])
	{
		CreateTimer(0.1, timerRegen, client);
	}
	if (g_bAmmoRegen[client])
	{
		ReSupply(client, g_iClientWeapons[client][0]);
		ReSupply(client, g_iClientWeapons[client][1]);
		ReSupply(client, g_iClientWeapons[client][2]);
	}
}
public Action:eventPlayerSpawn(Handle:event, const String:name[], bool:dontBroadcast)
{
	if (!GetConVarBool(g_hPluginEnabled)) { return; }
	new client = GetClientOfUserId(GetEventInt(event, "userid"));
	
	// Check if they have the jumper equipped, and hardcore is on for some reason.
	if (IsUsingJumper(client) && g_bHardcore[client])
	{
		g_bHardcore[client] = false;
	}
	
	if (g_bUsedReset[client])
	{
		ReloadPlayerData(client);
		g_bUsedReset[client] = false;
		return;
	}
	LoadPlayerData(client);
}
/*****************************************************************************************************************
												Timers
*****************************************************************************************************************/
public Action:timerMapSettings(Handle:timer, any:client)
{
	if (g_hDatabase == INVALID_HANDLE)
	{
		LogError("Can't load map settings database error.");
		return Plugin_Handled;
	}
	
	LoadMapCFG();
	return Plugin_Handled;
}
public Action:timerTeam(Handle:timer, any:client)
{
	if (client == 0)
	{
		return;
	}
	EraseLocs(client);
	ChangeClientTeam(client, g_iForceTeam);
}
public Action:timerRegen(Handle:timer, any:client)
{
	if (client == 0 || !IsValidEntity(client))
	{
		return;
	}
	new iMaxHealth = TF2_GetPlayerResourceData(client, TFResource_MaxHealth);
	SetEntityHealth(client, iMaxHealth);
}
public Action:timerRespawn(Handle:timer, any:client)
{
	if (IsValidClient(client))
	{
		TF2_RespawnPlayer(client);
	}
}
public Action:WelcomePlayer(Handle:timer, any:client)
{
	decl String:sHostname[64];
	GetConVarString(g_hHostname, sHostname, sizeof(sHostname));
	if (!IsClientInGame(client))
		return;

	PrintToChat(client, "\x01[\x03JA\x01] Welcome to \x03%s\x01. This server is running \x03%s\x01 by \x03%s\x01.", sHostname, PLUGIN_NAME, PLUGIN_AUTHOR);
	PrintToChat(client, "\x01[\x03JA\x01] %t", "Welcome_2", PLUGIN_NAME, cLightGreen, cDefault, cLightGreen, cDefault);
}
/*****************************************************************************************************************
											ConVars Hooks
*****************************************************************************************************************/
public cvarFastBuildChanged(Handle:convar, const String:oldValue[], const String:newValue[])
{
	if (StringToInt(newValue) == 0)
	{
		SetConVarInt(FindConVar("tf_fastbuild"), 0);
	}
	else
	{
		SetConVarInt(FindConVar("tf_fastbuild"), 1);
	}
}
public cvarCheapObjectsChanged(Handle:convar, const String:oldValue[], const String:newValue[])
{
	if (StringToInt(newValue) == 0)
	{
		SetConVarInt(FindConVar("tf_cheapobjects"), 0);
	}
	else
	{
		SetConVarInt(FindConVar("tf_cheapobjects"), 1);
	}
}
public cvarAmmoCheatChanged(Handle:convar, const String:oldValue[], const String:newValue[])
{
	if (StringToInt(newValue) == 0)
	{
		SetConVarInt(FindConVar("tf_sentrygun_ammocheat"), 0);
	}
	else
	{
		SetConVarInt(FindConVar("tf_sentrygun_ammocheat"), 1);
	}
}
public cvarWelcomeMsgChanged(Handle:convar, const String:oldValue[], const String:newValue[])
{
	if (StringToInt(newValue) == 0)
		SetConVarBool(g_hWelcomeMsg, false);
	else
		SetConVarBool(g_hWelcomeMsg, true);
}
public cvarSentryLevelChanged(Handle:convar, const String:oldValue[], const String:newValue[])
{
	if (StringToInt(newValue) == 0)
		SetConVarBool(g_hSentryLevel, false);
	else
		SetConVarBool(g_hSentryLevel, true);
}
public cvarSupermanChanged(Handle:convar, const String:oldValue[], const String:newValue[])
{
	if (StringToInt(newValue) == 0)
		SetConVarBool(g_hSuperman, false);
	else
		SetConVarBool(g_hSuperman, true);
}
public cvarSoundsChanged(Handle:convar, const String:oldValue[], const String:newValue[])
{
	if (StringToInt(newValue) == 0)
		SetConVarBool(g_hSoundBlock, false);
	else
		SetConVarBool(g_hSoundBlock, true);
}