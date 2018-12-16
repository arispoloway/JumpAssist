/*
             *     ,MMM8&&&.            *
                  MMMM88&&&&&    .
                 MMMM88&&&&&&&
     *           MMM88&&&&&&&&
                 MMM88&&&&&&&&
                 'MMM88&&&&&&'
                   'MMM8&&&'      *
          |\___/|
          )     (             .              '
         =\     /=
           )===(       *
          /     \
          |     |
         /       \
         \       /
  _/\_/\_/\__  _/_/\_/\_/\_/\_/\_/\_/\_/\_/\_
  |  |  |  |( (  |  |  |  |  |  |  |  |  |  |
  |  |  |  | ) ) |  |  |  |  |  |  |  |  |  |
  |  |  |  |(_(  |  |  |  |  |  |  |  |  |  |
  |  |  |  |  |  |  |  |  |  |  |  |  |  |  |
  |  |  |  |  |  |  |  |  |  |  |  |  |  |  |
  -----------SHOUTOUT TO MEOWMEOW------------
	**********************************************************************************************************************************
	*	CHANGE LOG
	*
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
	* UNOFFICIAL UPDATES BY TALKINGMELON
	* 0.7.1 - Regen is working better and skeys has less delay. Control points should work properly.
	*       - JA can now be used without a database configured.
	*       - Restart works properly.
	*       - The system for saving locations for admins is now working properly
	*       - Also general bugfixes
	*
	* 0.7.2 - Moved skeys and added m1/m2 support
	*       - Changed how commands are recognized to the way that is normally supported
	*       - General bugfixes
	*
	* 0.7.3 - Added support for updater plugin
	*
	* 0.7.4 - Added race functionality
	*
	* 0.7.5 - Fixed a number of racing bugs
	*
	* 0.7.6 - Racing now displays time in HH:MM:SS:MS or just MM:SS:MS if the time is short enough
	*       - Reorganized code to make it more readable and understandable
	*       - Spectators now get race alerts if they are spectating someone in a race
	*       - r_inv now works with argument targeting - ex !r_inv talkingmelon works now
	*       - restart no longer displays twice
	*       - When a player loads into a map, their previous caps will no longer be remembered - should fix the notification issue
	*       - Sounds should play properly
	*       - r_info added
	*       - r_spec added
	*       - r_set added
	*
	* 0.7.7 - Can invite multiple people at once with the r_inv command
	*       - Fixed server_race bug
	*       - Tried to fix sounds (pls)
	*       - r_list command added
	*
	* 0.7.8 - Ammo regen after plugin reload working
	*       - skeys_loc now allows you to set the location of skeys on the screen
	*       - Actually fixed no alert on cp problem
	*       - r_list and r_info now work for spectators of a race
	*
	* 0.7.9 - Fixed undo bug that let you change classes and teams and still have your old teleport
	*       - Timer sould work in all time zones properly now
	*       - Fixed calling for medic giving regen during race
	*
	* 0.7.10 - Added !spec command
	*        - Fixed potential for tele notification spam
	*        - Improved the usability of the help menu
	*
	* 0.7.11 - Fixed timer team bug
	*        - Fixed SQL ReloadPlayerData bug (maybe?)
	*
	* 0.8.0 - Moved upater to github repository
	*	  - imported jumptracer
	*	  - added cvar ja_update_branch for server operators to select updating from
	*	  - from dev or master.  Must be set in server.cfg.
	*
	* 0.8.0+ - See GitHub logs for future changes
	*
	**********************************************************************************************************************************
	* TODO:
	* give race a better UI
	* R_LIST TIMES AFTER PLAYER DC
	*LOG TO SERVER WHEN THE MAPSET COMMAND IS USED
	* STARTING A SECOND RACE WITH THE FIRST ONE STILL IN PROGRESS OFTEN GIVES - YOU ARE NOT THE RACE LOBBY LEADER if everyone types !r_leave it works
	*
	* maybe leave race when not leader of old race to start new one not work?
	* Plugin cvar enabled for all functions
	* ADD CVAR TO TOGGLE FINISH ALERT TO SERVER / FIX SPAM POSSIBLITY - SPEC POINTS REACHED BUG THING
	* PLAYER GOT TO CP IN TIME NOT JUST PLAYER GOT TO CP - WOULD MAKE THE TIME PART GOODOODOOODOD
	* TEST RACE SPEC AND ADD FUNCTIONALITY FOR ONLY SHOWING PEOPLE IN A RACE WHEN ATTACK1 AND 2 ARE USED
	* rematch typa thing
	* save pos before start of race then restore after
	* Polish for release.
	* Support for jtele with one argument
	* Support for sequence of cps
	**********************************************************************************************************************************
	* BUGS:
	* I'm sure there are plenty
	*   eventPlayerChangeTeam throws error on dc
	*   Dropped <name> from server (Disconnect by user.)
	*   L 12/02/2014 - 23:07:57: [SM] Native "ChangeClientTeam" reported: Client 2 is not in game
	*   L 12/02/2014 - 23:07:57: [SM] Displaying call stack trace for plugin "jumpassist.smx":
	*   L 12/02/2014 - 23 07:57: [SM]   [0]  Line 1590, scripting\jumpassist.sp::timerTeam()
	* Change to spec during race
	*
	* Race with 3 people - 2 finish - leader is one of them and starts new race inviting the other finisher and starts
	* Race keeps other person in it - may not have transfered leadership/may not leave race on !race if you are in one    --- I think i fixed this bug but is is difficult to test
	*
	* TESTERS
	* - Froyo
	* - Zigzati
	* - Elie
	* - Fossiil
	* - Melon
	* - AI
	* - Jondy
	* - Fractal
	* - Torch
	* - Velks
	* - Jondy
	* - Pizza Butt 8)
	* - 0beezy
	* - JoinedSenses
	**********************************************************************************************************************************
	*NOTES
	*
	* You must have a mysql or sqlite database named jumpassist and configure it in /addons/sourcemod/configs/databases.cfg
	* Once the database is set up, an example configuration would look like:
	*
	* "jumpassist"
	*     {
	*             "driver"				"default"
	*             "host"				"127.0.0.1"
	*             "database"			"jumpassist"
	*             "user"				"tf2server"
	*             "pass"				"tf2serverpassword"
	*             //"timeout"			"0"
	*             //"port"				"0"
	*     }
	*
	**********************************************************************************************************************************
*/
#pragma semicolon 1

#undef REQUIRE_PLUGIN
#include <updater>
#define REQUIRE_PLUGIN

#pragma newdecls required
#include <sourcemod>
#include <tf2_stocks>
#include <sdkhooks>

#if !defined REQUIRE_PLUGIN
#define REQUIRE_PLUGIN
#endif

#if !defined AUTOLOAD_EXTENSIONS
#define AUTOLOAD_EXTENSIONS
#endif

#if defined DEBUG
bool g_bUpdateRegistered;
#endif

#define UPDATE_URL_BASE "http://raw.github.com/arispoloway/JumpAssist"
//#define UPDATE_URL_BASE   "http://raw.github.com/pliesveld/JumpAssist"
#define UPDATE_URL_BRANCH "master"
#define UPDATE_URL_FILE "updatefile.txt"
#define PLUGIN_VERSION "0.9.5"
#define PLUGIN_NAME "[TF2] Jump Assist"
#define PLUGIN_AUTHOR "rush, nolem, happs, joinedsenses"
#define cDefault 0x01
#define cLightGreen 0x03

enum {
	  STATUS_NONE
	, STATUS_INVITING
	, STATUS_COUNTDOWN
	, STATUS_RACING
	, STATUS_WAITING
	, STATUS_COMPLETE
}

float
	  g_fRaceStartTime[MAXPLAYERS+1]
	, g_fRaceTime[MAXPLAYERS+1]
	, g_fRaceTimes[MAXPLAYERS+1][MAXPLAYERS]
	, g_fRaceFirstTime[MAXPLAYERS+1];
int
	  g_iRace[MAXPLAYERS+1]
	, g_iRaceStatus[MAXPLAYERS+1]
	, g_iRaceFinishedPlayers[MAXPLAYERS+1][MAXPLAYERS]
	, g_iRaceEndPoint[MAXPLAYERS+1]
	, g_iRaceInvitedTo[MAXPLAYERS+1]
	, g_bRaceSpec[MAXPLAYERS+1]
	, g_iSpeedrunStatus[32]
	, g_iLastTeleport[MAXPLAYERS+1];
bool
	  g_bRaceLocked[MAXPLAYERS+1]
	, g_bRaceAmmoRegen[MAXPLAYERS+1]
	, g_bRaceHealthRegen[MAXPLAYERS+1]
	, g_bRaceClassForce[MAXPLAYERS+1];
char
	  g_sWebsite[128] = "http://www.jump.tf/"
	, g_sForum[128] = "http://tf2rj.com/forum/"
	, g_sJumpAssist[128] = "http://tf2rj.com/forum/index.php?topic=854.0"
	, g_sURLMap[256];
ConVar
	  cvarWelcomeMsg
	, cvarCriticals
	, cvarSuperman
	, cvarSentryLevel
	, cvarCheapObjects
	, cvarAmmoCheat
	, cvarBranch
	, cvarWaitingForPlayers;
Handle 
	  g_hSDKStartBuilding
	, g_hSDKFinishBuilding
	, g_hSDKStartUpgrading
	, g_hSDKFinishUpgrading;
ArrayList
	  hArray_NoFuncRegen;
Database
	  g_hDatabase;

#include "jumpassist/skeys.sp"
#include "jumpassist/database.sp"
#include "jumpassist/sound.sp"
#include "jumpassist/speedrun.sp"

public Plugin myinfo = {
	name = PLUGIN_NAME,
	author = PLUGIN_AUTHOR,
	description = "Tools to run a jump server with ease.",
	version = PLUGIN_VERSION,
	url = "https://github.com/arispoloway/JumpAssist"
}

public void OnPluginStart() {
	char sDesc[128];

	JA_CreateForward();

	// Skillsrank uses me!
	RegPluginLibrary("jumpassist");

	// ConVars
	CreateConVar("jumpassist_version", PLUGIN_VERSION, "Jump assist version", FCVAR_SPONLY|FCVAR_REPLICATED|FCVAR_NOTIFY|FCVAR_DONTRECORD).SetString(PLUGIN_VERSION);
	cvarPluginEnabled = CreateConVar("ja_enable", "1", "Turns JumpAssist on/off.", FCVAR_NOTIFY);
	cvarWelcomeMsg = CreateConVar("ja_welcomemsg", "1", "Show clients the welcome message when they join?", FCVAR_NOTIFY);
	cvarAmmoCheat = CreateConVar("ja_ammocheat", "1", "Allows engineers infinite sentrygun ammo.", FCVAR_NOTIFY);
	cvarCheapObjects = CreateConVar("ja_cheapobjects", "1", "No metal cost on buildings.", FCVAR_NOTIFY);
	cvarCriticals = CreateConVar("ja_crits", "0", "Allow critical hits.", FCVAR_NOTIFY);
	cvarSuperman = CreateConVar("ja_superman", "0", "Allows everyone to be invincible.", FCVAR_NOTIFY);
	cvarSoundBlock = CreateConVar("ja_sounds", "1", "Block pain, regenerate, and ammo pickup sounds?", FCVAR_NOTIFY);
	cvarSentryLevel = CreateConVar("ja_sglevel", "1", "Sets the default sentry level (1-3)", FCVAR_NOTIFY);
	Format(sDesc, sizeof(sDesc),"Select a branch folder from %s to update from.", UPDATE_URL_BASE);
	cvarBranch = CreateConVar("ja_update_branch", UPDATE_URL_BRANCH, sDesc, FCVAR_NOTIFY);
	cvarSpeedrunEnabled = CreateConVar("ja_speedrun_enabled", "1", "Turns speedrunning on/off", FCVAR_NOTIFY);

	// Jump Assist console commands
	RegConsoleCmd("ja_help", cmdJAHelp, "Shows JA's commands.");
	RegConsoleCmd("sm_hardcore", cmdToggleHardcore, "Sends you back to the beginning without deleting your save..");
	RegConsoleCmd("sm_r", cmdReset, "Sends you back to the beginning without deleting your save..");
	RegConsoleCmd("sm_reset", cmdReset, "Sends you back to the beginning without deleting your save..");
	RegConsoleCmd("sm_restart", cmdRestart, "Deletes your save, and sends you back to the beginning.");
	RegConsoleCmd("sm_setmy", cmdSetMy, "Saves player settings.");
	RegConsoleCmd("sm_goto", cmdGotoClient, "Goto <target>");
	RegConsoleCmd("sm_s", cmdSave, "Saves your current position.");
	RegConsoleCmd("sm_save", cmdSave, "Saves your current position.");
	RegConsoleCmd("sm_regen", cmdDoRegen, "Changes regeneration settings.");
	RegConsoleCmd("sm_undo", cmdUndo, "Restores your last saved position.");
	RegConsoleCmd("sm_t", cmdTele, "Teleports you to your current saved location.");
	RegConsoleCmd("sm_ammo", cmdToggleAmmo, "Teleports you to your current saved location.");
	RegConsoleCmd("sm_health", cmdToggleHealth, "Teleports you to your current saved location.");
	RegConsoleCmd("sm_tele", cmdTele, "Teleports you to your current saved location.");
	RegConsoleCmd("sm_skeys", cmdGetClientKeys, "Toggle showing a clients key's.");
	//cannot whether the database is configured or not
	RegConsoleCmd("sm_skeys_color", cmdChangeSkeysColor, "Changes the color of the text for skeys.");
	RegConsoleCmd("sm_skeys_loc", cmdChangeSkeysLoc, "Changes the color of the text for skeys.");
	RegConsoleCmd("sm_superman", cmdUnkillable, "Makes you strong like superman.");
	RegConsoleCmd("sm_jumptf", cmdJumpTF, "Shows the jump.tf website.");
	RegConsoleCmd("sm_forums", cmdJumpForums, "Shows the jump.tf forums.");
	RegConsoleCmd("sm_jumpassist", cmdJumpAssist, "Shows the forum page for JumpAssist.");

	RegConsoleCmd("sm_race_list", cmdRaceList, "Lists players and their times in a race.");
	RegConsoleCmd("sm_r_list", cmdRaceList, "Lists players and their times in a race.");
	RegConsoleCmd("sm_race", cmdRaceInitialize, "Initializes a new race.");
	RegConsoleCmd("sm_r_inv", cmdRaceInvite, "Invites players to a new race.");
	RegConsoleCmd("sm_race_invite", cmdRaceInvite, "Invites players to a new race.");
	RegConsoleCmd("sm_r_start", cmdRaceStart, "Starts a race if you have invited people");
	RegConsoleCmd("sm_race_start", cmdRaceStart, "Starts a race if you have invited people");
	RegConsoleCmd("sm_r_leave", cmdRaceLeave, "Leave the current race.");
	RegConsoleCmd("sm_race_leave", cmdRaceLeave, "Leave the current race.");
	RegConsoleCmd("sm_r_spec", cmdRaceSpec, "Spectate a race.");
	RegConsoleCmd("sm_race_spec", cmdRaceSpec, "Spectate a race.");
	RegConsoleCmd("sm_r_set", cmdRaceSet, "Change a race's settings.");
	RegConsoleCmd("sm_race_set", cmdRaceSet, "Change a race's settings.");
	RegConsoleCmd("sm_r_info", cmdRaceInfo, "Display information about the race you are in.");
	RegConsoleCmd("sm_race_info", cmdRaceInfo, "Display information about the race you are in.");
	RegAdminCmd("sm_server_race", cmdRaceInitializeServer, ADMFLAG_GENERIC, "Invite everyone to a server wide race");
	RegAdminCmd("sm_s_race", cmdRaceInitializeServer, ADMFLAG_GENERIC, "Invite everyone to a server wide race");

	// Admin Commands
	RegAdminCmd("sm_mapset", cmdMapSet, ADMFLAG_GENERIC, "Change map settings");
	RegAdminCmd("sm_send", cmdSendPlayer, ADMFLAG_GENERIC, "Send target to another target.");
	RegAdminCmd("sm_jatele", SendToLocation, ADMFLAG_GENERIC, "Sends a player to the spcified jump.");
	RegAdminCmd("sm_addtele", cmdAddTele, ADMFLAG_GENERIC, "Adds a teleport location for the current map");
	//RegAdminCmd("sm_removetele", cmdRemoveTele, ADMFLAG_GENERIC, "Removes a teleport location for the current map");

	RegAdminCmd("sm_setstart", cmdSetStart, ADMFLAG_GENERIC, "Sets the map start location for speedrunning");
	RegAdminCmd("sm_addzone", cmdAddZone, ADMFLAG_GENERIC, "Adds a checkpoint or end zone for speedrunning");
	RegAdminCmd("sm_clearzones", cmdClearZones, ADMFLAG_GENERIC, "Deletes all zones on the current map");
	RegAdminCmd("sm_cleartimes", cmdClearTimes, ADMFLAG_GENERIC, "Deletes all times on the current map");
	RegAdminCmd("sm_sr_force_reload", cmdSpeedrunForceReload, ADMFLAG_GENERIC, "Deletes all times on the current map");
	RegConsoleCmd("sm_showzones", cmdShowZones, "Shows all zones of the map");
	RegConsoleCmd("sm_rmtime", cmdRemoveTime, "Removes your time on the map");
	RegConsoleCmd("sm_showzone", cmdShowZone, "Shows the current zone and says what zone it is");
	RegConsoleCmd("sm_sz", cmdShowZone, "Shows the current zone and says what zone it is");
	RegConsoleCmd("sm_speedrun", cmdToggleSpeedrun, "Enables/disables speedrunning");
	RegConsoleCmd("sm_sr", cmdToggleSpeedrun, "Enables/disables speedrunning");
	RegConsoleCmd("sm_stopspeedrun", cmdDisableSpeedrun, "Disables speedrunning");
	RegConsoleCmd("sm_pr", cmdShowPR, "Shows your personal record");
	RegConsoleCmd("sm_wr", cmdShowWR, "Shows the map record");
	RegConsoleCmd("sm_top", cmdShowTop, "Shows the map record");
	RegConsoleCmd("sm_pi", cmdShowPlayerInfo, "Shows the player's runs");
	//RegConsoleCmd("sm_stest", cmdTest, "Shows the map record");
	//RegConsoleCmd("sm_top", cmdShowTop, "Shows the top speedruns of the map");

	// ROOT COMMANDS, they're set to root users for a reason.
	RegAdminCmd("sm_ja_query", RunQuery, ADMFLAG_ROOT, "Runs a SQL query on the JA database. (FOR TESTING)");
#if defined DEBUG
	RegAdminCmd("sm_ja_update_force", Command_Update, ADMFLAG_RCON, "Forces update check of plugin");
#endif

	// Hooks
	HookEvent("player_team", eventPlayerChangeTeam);
	HookEvent("player_changeclass", eventPlayerChangeClass);
	HookEvent("player_spawn", eventPlayerSpawn);
	HookEvent("player_death", eventPlayerDeath);
	HookEvent("controlpoint_starttouch", eventTouchCP);
	HookEvent("player_builtobject", eventPlayerBuiltObj);
	HookEvent("player_upgradedobject", eventPlayerUpgradedObj);
	HookEvent("teamplay_round_start", eventRoundStart);
	HookEvent("post_inventory_application", eventInventoryUpdate);

	// ConVar Hooks
	cvarCheapObjects.AddChangeHook(cvarCheapObjectsChanged);
	cvarAmmoCheat.AddChangeHook(cvarAmmoCheatChanged);
	cvarWelcomeMsg.AddChangeHook(cvarWelcomeMsgChanged);
	cvarSuperman.AddChangeHook(cvarSupermanChanged);
	cvarSoundBlock.AddChangeHook(cvarSoundsChanged);
	cvarSentryLevel.AddChangeHook(cvarSentryLevelChanged);
	cvarSpeedrunEnabled.AddChangeHook(cvarSpeedrunEnabledChanged);

	HookUserMessage(GetUserMessageId("VoiceSubtitle"), HookVoice, true);
	AddNormalSoundHook(sound_hook);

	LoadTranslations("jumpassist.phrases");
	LoadTranslations("common.phrases");

	g_hHostname = FindConVar("hostname");
	HudDisplayForward = CreateHudSynchronizer();
	HudDisplayASD = CreateHudSynchronizer();
	HudDisplayDuck = CreateHudSynchronizer();
	HudDisplayJump = CreateHudSynchronizer();
	HudDisplayM1 = CreateHudSynchronizer();
	HudDisplayM2 = CreateHudSynchronizer();
	cvarWaitingForPlayers = FindConVar("mp_waitingforplayers_time");

	char sFilePath[PLATFORM_MAX_PATH];
	BuildPath(Path_SM, sFilePath, sizeof(sFilePath), "gamedata/buildings.txt");
	if (FileExists(sFilePath)) {
		Handle hGameConf = LoadGameConfigFile("buildings");
		if (hGameConf != null) {
			StartPrepSDKCall(SDKCall_Entity);
			PrepSDKCall_SetFromConf(hGameConf, SDKConf_Virtual, "CBaseObject::StartBuilding");
			g_hSDKStartBuilding = EndPrepSDKCall();

			StartPrepSDKCall(SDKCall_Entity);
			PrepSDKCall_SetFromConf(hGameConf, SDKConf_Virtual, "CBaseObject::FinishedBuilding");
			g_hSDKFinishBuilding = EndPrepSDKCall();

			StartPrepSDKCall(SDKCall_Entity);
			PrepSDKCall_SetFromConf(hGameConf, SDKConf_Virtual, "CBaseObject::StartUpgrading");
			g_hSDKStartUpgrading = EndPrepSDKCall();

			StartPrepSDKCall(SDKCall_Entity);
			PrepSDKCall_SetFromConf(hGameConf, SDKConf_Virtual, "CBaseObject::FinishUpgrading");
			g_hSDKFinishUpgrading = EndPrepSDKCall();

			delete hGameConf;
		}
		if (g_hSDKStartBuilding == null || g_hSDKFinishBuilding == null || g_hSDKStartUpgrading == null || g_hSDKFinishUpgrading == null) {
			LogError("Failed to load buildings gamedata.  Instant building and upgrades will not be available.");
		}
	}

	hArray_NoFuncRegen = new ArrayList();

	for (int i = 0; i <= MaxClients; i++) {
		if (IsValidClient(i)) {
			for (int j = 0; j < 3; j++) {
				g_iClientWeapons[i][j] = GetPlayerWeaponSlot(i, j);
			}
		}
		g_iLastTeleport[i] = 0;
	}
	SetAllSkeysDefaults();
	char branch[32];

	cvarBranch.GetString(branch, sizeof(branch));
	//if (!VerifyBranch(branch, sizeof(branch))) {
	if (!VerifyBranch(branch)) {
		cvarBranch.SetString(UPDATE_URL_BRANCH);
#if defined DEBUG
		LogMessage("Resetting branch to %s", UPDATE_URL_BRANCH);
#endif
	}
	Format(g_sURLMap, sizeof(g_sURLMap),"%s/%s/%s", UPDATE_URL_BASE, branch, UPDATE_URL_FILE);

	if (LibraryExists("updater")) {
		Updater_AddPlugin(g_sURLMap);
#if defined DEBUG
		g_bUpdateRegistered = true;
#endif
	}
	else {
		LogMessage("Updater plugin not found.");
	}
	ConnectToDatabase();
}

bool VerifyBranch(char[] branch) {
	return (!strcmp(branch,"master") || !strcmp(branch,"dev"));
}

public void OnLibraryAdded(const char[] name) {
	if (StrEqual(name, "updater")) {
		Updater_AddPlugin(g_sURLMap);
	}
}

public APLRes AskPluginLoad2(Handle myself, bool late, char[] error, int err_max) {
	CreateNative("JA_ClearSave", Native_JA_ClearSave);
	CreateNative("JA_GetSettings", Native_JA_GetSettings);
	CreateNative("JA_PrepSpeedRun", Native_JA_PrepSpeedRun);
	CreateNative("JA_ReloadPlayerSettings", Native_JA_ReloadPlayerSettings);

	g_bLateLoad = late;

	return APLRes_Success;
}

void TF2_SetGameType() {
	GameRules_SetProp("m_nGameType", 2);
}

#if defined DEBUG
public Action Command_Update(int client, int args) {
	if (!LibraryExists("updater")) {
		ReplyToCommand(client,"updater plugin not found.");
	}
	else if (!g_bUpdateRegistered) {
		ReplyToCommand(client,"Updater not registered.");
	}
	else {
		ReplyToCommand(client,"Force update returned %s", Updater_ForceUpdate() ? "true" : "false");
	}
	return Plugin_Handled;
}

public Action Updater_OnPluginChecking() {
	LogMessage("Checking for updates.");
	return Plugin_Continue;
}

public Action Updater_OnPluginDownloading() {
	LogMessage("Downloading updates.");
	return Plugin_Continue;
}
#endif

public void Updater_OnPluginUpdated() {
	LogMessage("Update complete.");
	ReloadPlugin();
}

public void OnGameFrame() {
	SkeysOnGameFrame();
	if (cvarSpeedrunEnabled.BoolValue) {
		SpeedrunOnGameFrame();
	}
}
// Support for beggers bazooka
void Hook_Func_regenerate() {
	int entity = -1;
	while ((entity = FindEntityByClassname(entity, "func_regenerate")) != INVALID_ENT_REFERENCE) {
		// Support for concmap*, and quad* maps that are imported from TFC.
		HookFunc(entity);
	}
}
void HookFunc(int entity) {
#if defined DEBUG
	LogMessage("Hooked entity %d", entity);
#endif
	SDKUnhook(entity, SDKHook_StartTouch, OnPlayerStartTouchFuncRegenerate);
	SDKUnhook(entity, SDKHook_Touch, OnPlayerStartTouchFuncRegenerate);
	SDKUnhook(entity, SDKHook_EndTouch, OnPlayerStartTouchFuncRegenerate);
	SDKHook(entity, SDKHook_StartTouch, OnPlayerStartTouchFuncRegenerate);
	SDKHook(entity, SDKHook_Touch, OnPlayerStartTouchFuncRegenerate);
	SDKHook(entity, SDKHook_EndTouch, OnPlayerStartTouchFuncRegenerate);
}

public void OnMapStart() {
	if (cvarPluginEnabled.BoolValue) {
		for (int i = 0; i <= MaxClients ; i++) {
			ResetRace(i);
			g_iLastTeleport[i] = 0;
		}
		if (g_hDatabase != null) {
			LoadMapCFG();
		}
		cvarWaitingForPlayers.SetInt(0);

		// Precache cap sounds
		PrecacheSound("misc/tf_nemesis.wav");
		PrecacheSound("misc/freeze_cam.wav");
		PrecacheSound("misc/killstreak.wav");

		g_iBeamSprite = PrecacheModel("materials/sprites/laser.vmt");
		g_iHaloSprite = PrecacheModel("materials/sprites/halo01.vmt");

		// Change game rules to CP.
		TF2_SetGameType();

		// Find caps, and store the number of them in g_iCPs.
		int iCP = -1;
		g_iCPs = 0;
		while ((iCP = FindEntityByClassname(iCP, "trigger_capture_area")) != -1) {
			g_iCPs++;
		}

		if (g_hDatabase != null) {
			LoadMapSpeedrunInfo();
		}

		Hook_Func_regenerate();
	}
}

public void OnClientDisconnect(int client) {
	if (!cvarPluginEnabled.BoolValue) {
		return;
	}
	g_bHardcore[client] = false;
	g_bHPRegen[client] = false;
	g_bLoadedPlayerSettings[client] = false;
	g_bBeatTheMap[client] = false;
	g_bGetClientKeys[client] = false;
	g_bSpeedRun[client] = false;
	g_bUnkillable[client] = false;
	Format(g_sCaps[client], sizeof(g_sCaps), "\0");

	EraseLocs(client);
	if (g_iRace[client] !=0) {
		LeaveRace(client);
	}
	g_iSpeedrunStatus[client] = 0;
	for (int i = 0; i < 32; i++) {
		g_fZoneTimes[client][i] = 0.0;
	}
	g_iLastFrameInStartZone[client] = 0;
	SetSkeysDefaults(client);

	int idx;
	if ((idx = hArray_NoFuncRegen.FindValue(client)) != -1) {
		hArray_NoFuncRegen.Erase(idx);
	}
}

public void OnClientPutInServer(int client) {
	if (cvarPluginEnabled.BoolValue) {
		if (cvarSpeedrunEnabled) {
			UpdateSteamID(client);
		}
		// Hook the client
		if (IsValidClient(client)) {
			SDKHook(client, SDKHook_WeaponEquipPost, SDKHook_OnWeaponEquipPost);
		}
		// Load the player profile.
		char sSteamID[64]; GetClientAuthId(client, AuthId_Steam2, sSteamID, sizeof(sSteamID));

		LoadPlayerProfile(client, sSteamID);

		// Welcome message. 15 seconds seems to be a good number.
		if (cvarWelcomeMsg.BoolValue) {
			CreateTimer(15.0, WelcomePlayer, client);
		}
		g_bHardcore[client] = false, g_bHPRegen[client] = false, g_bLoadedPlayerSettings[client] = false, g_bBeatTheMap[client] = false;
		g_bGetClientKeys[client] = false, g_bSpeedRun[client] = false, g_bUnkillable[client] = false, Format(g_sCaps[client], sizeof(g_sCaps), "\0");
	}
}
/*****************************************************************************************************************
												Functions
*****************************************************************************************************************/

//I SHOULD MAKE THIS DO A PAGED MENU IF IT DOESNT ALREADY IDK ANY MAPS WITH THAT MANY CPS ANYWAY
public Action cmdRaceInitialize(int client, int args) {
	if (!IsValidClient(client)) {
		return;
	}
	if (cvarSpeedrunEnabled.BoolValue && IsSpeedrunMap()&& g_iSpeedrunStatus[client]) {
		PrintToChat(client, "\x01[\x03JA\x01] You may not race while speedrunning");
		return;
	}
	if (g_bSpeedRun[client]) {
		PrintToChat(client, "\x01[\x03JA\x01] %t", "Speedrun_Active");
		return;
	}
	if (g_iCPs == 0) {
		PrintToChat(client, "\x01[\x03JA\x01] You may only race on maps with control points.");
		return;
	}
	if (IsPlayerFinishedRacing(client)) {
		LeaveRace(client);
	}
	if (IsClientRacing(client)) {
		PrintToChat(client, "\x01[\x03JA\x01] You are already in a race.");
		return;
	}
	g_iRace[client] = client;
	g_iRaceStatus[client] = STATUS_INVITING;
	g_bRaceClassForce[client] = true;

	char cpName[32], buffer[32];
	Menu menu = new Menu(ControlPointSelector);
	int entity;
	menu.SetTitle("Select End Control Point");

	while ((entity = FindEntityByClassname(entity, "team_control_point")) != -1) {
		int pIndex = GetEntProp(entity, Prop_Data, "m_iPointIndex");
		GetEntPropString(entity, Prop_Data, "m_iszPrintName", cpName, sizeof(cpName));
		IntToString(pIndex, buffer, sizeof(buffer));
		menu.AddItem(buffer, cpName);
	}
	menu.Display(client, 300);
	return;
}

int ControlPointSelector(Menu menu, MenuAction action, int param1, int param2) {
	switch (action) {
		case MenuAction_Select: {
			char info[32];
			menu.GetItem(param2, info, sizeof(info));
			g_iRaceEndPoint[param1] = StringToInt(info);
		}
		case MenuAction_Cancel: {
			g_iRace[param1] = 0;
			PrintToChat(param1, "\x01[\x03JA\x01] The race has been cancelled.");
		}
		case MenuAction_End: {
			delete menu;
		}
	}
}

public Action cmdRaceInvite(int client, int args) {
	if (!IsValidClient(client)) {
		return Plugin_Handled;
	}
	if (!IsClientRacing(client)) {
		PrintToChat(client, "\x01[\x03JA\x01] You have not started a race.");
		return Plugin_Handled;
	}
	if (!IsRaceLeader(client, g_iRace[client])) {
		PrintToChat(client, "\x01[\x03JA\x01] You are not the race lobby leader.");
		return Plugin_Handled;
	}
	if (HasRaceStarted(client)) {
		PrintToChat(client, "\x01[\x03JA\x01] The race has already started.");
		return Plugin_Handled;
	}
	if (args == 0) {
		Menu g_PlayerMenu = PlayerMenu();
		g_PlayerMenu.Display(client, MENU_TIME_FOREVER);
	}
	else {
		char arg1[32], clientName[128], client2Name[128], buffer[128];
		int target;
		Panel panel;
		GetClientName(client, clientName, sizeof(clientName));

		for (int i = 1; i < args+1; i++) {
			GetCmdArg(i, arg1, sizeof(arg1));
			target = FindTarget(client, arg1, true, false);
			GetClientName(target, client2Name, sizeof(client2Name));
			if (target != -1 && !g_iSpeedrunStatus[target]) {
				PrintToChat(client, "\x01[\x03JA\x01] You have invited %s to race.", client2Name);
				Format(buffer, sizeof(buffer), "You have been invited to race to %s by %s", GetCPNameByIndex(g_iRaceEndPoint[client]), clientName);

				panel = new Panel();
				panel.SetTitle(buffer);
				panel.DrawItem("Accept");
				panel.DrawItem("Decline");

				g_iRaceInvitedTo[target] = client;
				panel.Send(target, InviteHandler, 15);

				delete panel;
			}
			else if (g_iSpeedrunStatus[target]) {
				PrintToChat(client, "\x01[\x03JA\x01] %s is currently in a speedrun", client2Name);
			}
		}
	}
	return Plugin_Continue;
}

char GetCPNameByIndex(int index) {
	int entity;
	char cpName[32];
	while ((entity = FindEntityByClassname(entity, "team_control_point")) != -1) {
		if (GetEntProp(entity, Prop_Data, "m_iPointIndex") == index) {
			GetEntPropString(entity, Prop_Data, "m_iszPrintName", cpName, sizeof(cpName));
		}
	}
	return cpName;
}

Menu PlayerMenu() {
	Menu menu = new Menu(Menu_InvitePlayers);
	char buffer[128], clientName[128];

	//SHOULDNT SHOW CURRENT PLAYER AND ALSO PLAYERS ALREADY IN A RACE BUT I NEED THAT FOR TESTING FOR NOW
	for (int i = 1; i <= MaxClients; i++) {
		if (IsValidClient(i) && !g_iSpeedrunStatus[i]) {
			IntToString(i, buffer, sizeof(buffer));
			GetClientName(i, clientName, sizeof(clientName));
			menu.AddItem(buffer, clientName);
		}
		menu.SetTitle("Select Players to Invite:");
	}
	return menu;
}

int Menu_InvitePlayers(Menu menu, MenuAction action, int param1, int param2) {
	switch (action) {
		case MenuAction_Select: {
			char clientName[128], client2Name[128], buffer[128], info[32];

			GetClientName(param1, clientName, sizeof(clientName));
			menu.GetItem(param2, info, sizeof(info));
			GetClientName(StringToInt(info), client2Name, sizeof(client2Name));
			PrintToChat(param1, "\x01[\x03JA\x01] You have invited %s to race.", client2Name);
			menu.GetItem(param2, info, sizeof(info));
			Format(buffer, sizeof(buffer), "You have been invited to race to %s by %s", GetCPNameByIndex(g_iRaceEndPoint[param1]), clientName);

			Panel panel = new Panel();
			panel.SetTitle(buffer);
			panel.DrawItem("Accept");
			panel.DrawItem("Decline");

			g_iRaceInvitedTo[StringToInt(info)] = param1;
			panel.Send(StringToInt(info), InviteHandler, 15);

			delete panel;
		}
		case MenuAction_End: {
			delete menu;
		}
	}
}

int InviteHandler(Menu menu, MenuAction action, int param1, int param2) {
	// if (action == MenuAction_Select)
	// {
		// PrintToConsole(param1, "You selected item: %d", param2);
		// g_iRaceInvitedTo[param1] = 0;
	// }
	// else if (action == MenuAction_Cancel) {
		// PrintToServer("Client %d's menu was cancelled.  Reason: %d", param1, param2);
		// g_iRaceInvitedTo[param1] = 0;
	// }
	AlertInviteAcceptOrDeny(g_iRaceInvitedTo[param1], param1, param2);
}

void AlertInviteAcceptOrDeny(int client, int client2, int choice) {
	char clientName[128];
	GetClientName(client2, clientName, sizeof(clientName));
	if (choice == 1) {
		if (HasRaceStarted(client)) {
			PrintToChat(client, "\x01[\x03JA\x01] This race has already started.");
			return;
		}
		LeaveRace(client2);
		g_iRace[client2] = client;
		PrintToChat(client, "\x01[\x03JA\x01] %s has accepted your request to race", clientName);
	}
	else if (choice < 1) {
		PrintToChat(client, "\x01[\x03JA\x01] %s failed to respond to your invitation", clientName);
	}
	else {
		PrintToChat(client, "\x01[\x03JA\x01] %s has declined your request to race", clientName);
	}
}
//THE WORST WORKAROUND YOU'VE EVER SEEN
Action RaceCountdown(Handle timer, any raceID) {
	PrintToRace(raceID, "****************************");
	PrintToRace(raceID, "             Starting race in: 3");
	PrintToRace(raceID, "****************************");
	CreateTimer(1.0, RaceCountdown2, raceID);
}

Action RaceCountdown2(Handle timer, any raceID) {
	PrintToRace(raceID, "****************************");
	PrintToRace(raceID, "                         2");
	PrintToRace(raceID, "****************************");
	CreateTimer(1.0, RaceCountdown1, raceID);
}

Action RaceCountdown1(Handle timer, any raceID) {
	PrintToRace(raceID, "****************************");
	PrintToRace(raceID, "                         1");
	PrintToRace(raceID, "****************************");
	CreateTimer(1.0, RaceCountdownGo, raceID);
}

Action RaceCountdownGo(Handle timer, any raceID) {
	UnlockRacePlayers(raceID);
	PrintToRace(raceID, "****************************");
	PrintToRace(raceID, "                        GO!");
	PrintToRace(raceID, "****************************");
	float time = GetEngineTime();
	g_fRaceStartTime[raceID] = time;
	g_iRaceStatus[raceID] = STATUS_RACING;
}

public Action cmdRaceList(int client, int args) {
	if (!IsValidClient(client)) {
		return;
	}
	//WILL NEED TO ADD && !ISCLINETOBSERVER(CLIENT) WHEN I ADD SPEC SUPPORT FOR THIS
	int clientToShow, iObserverMode;
	if (!IsClientRacing(client)) {
		if (IsClientObserver(client)) {
			iObserverMode = GetEntPropEnt(client, Prop_Send, "m_iObserverMode");
			clientToShow = GetEntPropEnt(client, Prop_Send, "m_hObserverTarget");
			if (!IsClientRacing(clientToShow)) {
				PrintToChat(client, "\x01[\x03JA\x01] This client is not in a race!");
				return;
			}
			if (!IsValidClient(client) || !IsValidClient(clientToShow) || iObserverMode == 6) {
				return;
			}
		}
		else {
			PrintToChat(client, "\x01[\x03JA\x01] You are not in a race!");
			return;
		}
	}
	else {
		clientToShow = client;
	}
	int race = g_iRace[clientToShow];
	char leader[32], leaderFormatted[32], racerNames[32], racerEntryFormatted[255], racerTimes[128], racerDiff[128];
	Panel panel = new Panel();
	bool space;

	GetClientName(g_iRace[clientToShow], leader, sizeof(leader));
	Format(leaderFormatted, sizeof(leaderFormatted), "%s's Race", leader);
	panel.DrawText(leaderFormatted);
	panel.DrawText(" ");

	for (int i = 0; i <= MaxClients; i++) {
		if (g_iRaceFinishedPlayers[race][i] == 0) {
			break;
		}
		space = true;
		GetClientName(g_iRaceFinishedPlayers[race][i], racerNames, sizeof(racerNames));
		racerTimes = TimeFormat(g_fRaceTimes[race][i] - g_fRaceStartTime[race]);
		if (g_fRaceFirstTime[race] != g_fRaceTimes[race][i]) {
			racerDiff = TimeFormat(g_fRaceTimes[race][i] - g_fRaceFirstTime[race]);
		}
		else {
			racerDiff = "00:00:000";
		}
		Format(racerEntryFormatted, sizeof(racerEntryFormatted), "%d. %s - %s[-%s]", (i+1), racerNames, racerTimes, racerDiff);
		panel.DrawText(racerEntryFormatted);

	}
	if (space) {
		panel.DrawText(" ");
	}
	char name[32];

	for (int i = 0; i <= MaxClients; i++) {
		if (IsClientInRace(i, race) && !IsPlayerFinishedRacing(i)) {
			GetClientName(i, name, sizeof(name));
			panel.DrawText(name);
		}
	}
	panel.DrawText(" ");
	panel.DrawItem("Exit");
	panel.Send(client, InfoHandler, 30);
	delete panel;
}

//public void ListHandler(Menu menu, MenuAction action, int param1, int param2) {
	// if (action == MenuAction_Select)
	// {
		// PrintToConsole(param1, "You selected item: %d", param2);
		// g_iRaceInvitedTo[param1] = 0;
	// }
	// else if (action == MenuAction_Cancel) {
		// PrintToServer("Client %d's menu was cancelled.  Reason: %d", param1, param2);
		// g_iRaceInvitedTo[param1] = 0;
	// }
//}

public Action cmdRaceInfo(int client, int args) {
	if (!IsValidClient(client)) {
		return;
	}

	//WILL NEED TO ADD && !ISCLINETOBSERVER(CLIENT) WHEN I ADD SPEC SUPPORT FOR THIS
	int clientToShow, iObserverMode;
	if (!IsClientRacing(client)) {
		if (IsClientObserver(client)) {
			iObserverMode = GetEntPropEnt(client, Prop_Send, "m_iObserverMode");
			clientToShow = GetEntPropEnt(client, Prop_Send, "m_hObserverTarget");

			if (!IsClientRacing(clientToShow)) {
				PrintToChat(client, "\x01[\x03JA\x01] This client is not in a race!");
				return;
			}
			if (!IsValidClient(client) || !IsValidClient(clientToShow) || iObserverMode == 6) {
				return;
			}
		}
		else {
			PrintToChat(client, "\x01[\x03JA\x01] You are not in a race!");
			return;
		}
	}
	else {
		clientToShow = client;
	}

	char leader[32];
	char leaderFormatted[64];
	char status[64];
	char healthRegen[32];
	char ammoRegen[32];
	char classForce[32];

	GetClientName(g_iRace[clientToShow], leader, sizeof(leader));
	Format(leaderFormatted, sizeof(leaderFormatted), "Race Host: %s", leader);

	healthRegen = (g_bRaceHealthRegen[g_iRace[clientToShow]]) ? "HP Regen: Enabled" : "HP Regen: Disabled";
	ammoRegen = (g_bRaceHealthRegen[g_iRace[clientToShow]]) ? "Ammo Regen: Enabled" : "Ammo Regen: Disabled";

	switch (GetRaceStatus(clientToShow)) {
		case STATUS_NONE: {
			status = "Race Status: Not racing";
		}
		case STATUS_INVITING: {
			status = "Race Status: Waiting for start";
		}
		case STATUS_COUNTDOWN: {
			status = "Race Status: Starting";
		}
		case STATUS_RACING: {
			status = "Race Status: Racing";
		}
		case STATUS_WAITING: {
			status = "Race Status: Waiting for finshers";
		}
		case STATUS_COMPLETE: {
			status = "Race Status: Complete";
		}
	}
	classForce = (g_bRaceClassForce[g_iRace[clientToShow]]) ? "Class Force: Enabled" : "Class Force: Disabled";

	Panel panel = new Panel();
	panel.DrawText(leaderFormatted);
	panel.DrawText(status);
	panel.DrawText("---------------");
	panel.DrawText(healthRegen);
	panel.DrawText(ammoRegen);
	panel.DrawText("---------------");
	panel.DrawText(classForce);
	panel.DrawText(" ");
	panel.DrawItem("Exit");
	panel.Send(client, InfoHandler, 30);
	delete panel;
}

int InfoHandler(Menu menu, MenuAction action, int param1, int param2) {
	// if (action == MenuAction_Select)
	// {
		// PrintToConsole(param1, "You selected item: %d", param2);
		// g_iRaceInvitedTo[param1] = 0;
	// }
// else if (action == MenuAction_Cancel) {
		// PrintToServer("Client %d's menu was cancelled.  Reason: %d", param1, param2);
		// g_iRaceInvitedTo[param1] = 0;
	// }
}

public Action cmdRaceStart(int client, int args) {
	if (!IsValidClient(client)) {
		return;
	}
	if (g_iRace[client] == 0) {
		PrintToChat(client, "\x01[\x03JA\x01] You are not hosting a race!");
		return;
	}
	if (!IsRaceLeader(client, g_iRace[client])) {
		PrintToChat(client, "\x01[\x03JA\x01] You are not the race lobby leader.");
		return;
	}
	//RIGHT HERE I SHOULD CHECK TO MAKE SURE THERE ARE TWO OR MORE PEOPLE
	if (HasRaceStarted(client)) {
		PrintToChat(client, "\x01[\x03JA\x01] The race has already started.");
		return;
	}
	LockRacePlayers(client);
	ApplyRaceSettings(client);
	TFClassType class = TF2_GetPlayerClass(client);
	int team = GetClientTeam(client);

	g_iRaceStatus[client] = STATUS_COUNTDOWN;
	CreateTimer(1.0, RaceCountdown, client);

	SendRaceToStart(client, class, team);
	PrintToRace(client, "Teleporting to race start!");


}

void PrintToRace(int raceID, char[] message) {
	char buffer[128];
	Format(buffer, sizeof(buffer), "\x01[\x03JA\x01] %s", message);
	for (int i = 1; i <= MaxClients; i++) {
		if (IsClientInRace(i, raceID) || IsClientSpectatingRace(i, raceID)) {
			PrintToChat(i, buffer);
		}
	}
}

void SendRaceToStart(int raceID, TFClassType class, int team) {
	for (int i = 1; i <= MaxClients; i++) {
		if (IsClientInRace(i, raceID)) {
			if (g_bRaceClassForce[raceID]) {
				TF2_SetPlayerClass(i, class);
			}
			ChangeClientTeam(i, team);
			SendToStart(i);
		}
	}
}

void LockRacePlayers(int raceID) {
	for (int i = 1; i <= MaxClients; i++) {
		if (IsClientInRace(i, raceID)) {
			g_bRaceLocked[i] = true;
		}
	}
}

void UnlockRacePlayers(int raceID) {
	for (int i = 1; i <= MaxClients; i++) {
		if (IsClientInRace(i, raceID)) {
			g_bRaceLocked[i] = false;
		}
	}
}

public Action cmdRaceLeave(int client, int args) {
	if (!IsClientRacing(client)) {
		PrintToChat(client, "\x01[\x03JA\x01] You are not in a race.");
		return;
	}
	LeaveRace(client);
	PrintToChat(client, "\x01[\x03JA\x01] You have left the race.");
}

// public Action cmdServerRace(int client, int args) {
	// cmdRaceInitializeServer(int client, int args);
// }

public Action cmdRaceInitializeServer(int client, int args) {
	if (!IsValidClient(client)) {
		return Plugin_Handled;
	}
	if (g_bSpeedRun[client]) {
		PrintToChat(client, "\x01[\x03JA\x01] %t", "Speedrun_Active");
		return Plugin_Handled;
	}
	if (g_iCPs == 0) {
		PrintToChat(client, "\x01[\x03JA\x01] You may only race on maps with control points.");
		return Plugin_Handled;
	}
	if (IsPlayerFinishedRacing(client)) {
		LeaveRace(client);
	}
	if (IsClientRacing(client)) {
		PrintToChat(client, "\x01[\x03JA\x01] You are already in a race.");
		return Plugin_Handled;
	}
	g_iRace[client] = client;
	g_iRaceStatus[client] = STATUS_INVITING;
	g_bRaceClassForce[client] = true;

	char cpName[32],  buffer[32];
	Menu menu = new Menu(ControlPointSelectorServer);
	int entity;
	menu.SetTitle("Select End Control Point");

	while ((entity = FindEntityByClassname(entity, "team_control_point")) != -1) {
		int pIndex = GetEntProp(entity, Prop_Data, "m_iPointIndex");
		GetEntPropString(entity, Prop_Data, "m_iszPrintName", cpName, sizeof(cpName));
		IntToString(pIndex, buffer, sizeof(buffer));
		menu.AddItem(buffer, cpName);
	}
	menu.Display(client, 300);
	return Plugin_Handled;
}

int ControlPointSelectorServer(Menu menu, MenuAction action, int param1, int param2) {
	if (action == MenuAction_Select) {
		char info[32], buffer[128], clientName[128];
		menu.GetItem(param2, info, sizeof(info));
		g_iRaceEndPoint[param1] = StringToInt(info);

		GetClientName(param1, clientName, sizeof(clientName));
		for (int i = 1; i <= MaxClients; i++) {
			if (IsValidClient(i) && param1 != i) {
				Format(buffer, sizeof(buffer), "You have been invited to race to %s by %s", GetCPNameByIndex(g_iRaceEndPoint[param1]), clientName);

				Panel panel = new Panel();
				panel.SetTitle(buffer);
				panel.DrawItem("Accept");
				panel.DrawItem("Decline");

				g_iRaceInvitedTo[i] = param1;
				panel.Send(i, InviteHandler, 15);

				delete panel;
			}
		}
	}
	else if (action == MenuAction_Cancel) {
		g_iRace[param1] = 0;
		PrintToChat(param1, "\x01[\x03JA\x01] The race has been cancelled.");
	}
	else if (action == MenuAction_End) {
		delete menu;
	}
}

public Action cmdRaceSpec(int client, int args) {
	if (!IsValidClient(client)) {
		return Plugin_Handled;
	}
	if (args == 0) {
		PrintToChat(client, "\x01[\x03JA\x01] No target race selected.");
		return Plugin_Handled;
	}
	char arg1[32];
	GetCmdArg(1, arg1, sizeof(arg1));
	int target = FindTarget(client, arg1, true, false);
	if (target == -1) {
		return Plugin_Handled;
	}
	else {
		if (target == client) {
			PrintToChat(client, "\x01[\x03JA\x01] You may not spectate yourself.");
			return Plugin_Handled;
		}
		if (!IsClientRacing(target)) {
			PrintToChat(client, "\x01[\x03JA\x01] Target client is not in a race.");
			return Plugin_Handled;
		}
		if (IsClientObserver(target)) {
			PrintToChat(client, "\x01[\x03JA\x01] You may not spectate a spectator.");
			return Plugin_Handled;
		}
		if (IsClientRacing(client)) {
			LeaveRace(client);
		}
		if (!IsClientObserver(client)) {
			ChangeClientTeam(client, 1);
			ForcePlayerSuicide(client);
		}
		g_bRaceSpec[client] = g_iRace[target];
		SetEntPropEnt(client, Prop_Send, "m_hObserverTarget", g_iRace[target]);
		SetEntProp(client, Prop_Send, "m_iObserverMode", 4);
	}
	return Plugin_Continue;
}

public Action cmdRaceSet(int client, int args) {
	if (!IsValidClient(client)) {
		return Plugin_Handled;
	}
	if (!IsClientRacing(client)) {
		PrintToChat(client, "\x01[\x03JA\x01] You are not in a race.");
		return Plugin_Handled;
	}
	if (!IsRaceLeader(client, g_iRace[client])) {
		PrintToChat(client, "\x01[\x03JA\x01] You are not the leader of this race.");
		return Plugin_Handled;
	}
	if (HasRaceStarted(client)) {
		PrintToChat(client, "\x01[\x03JA\x01] The race has already started.");
		return Plugin_Handled;
	}
	if (args != 2) {
		PrintToChat(client, "\x01[\x03JA\x01] This number of arguments is not supported.");
		return Plugin_Handled;
	}
	char arg1[32], arg2[32];
	bool toSet;

	GetCmdArg(1, arg1, sizeof(arg1));
	GetCmdArg(2, arg2, sizeof(arg2));
	PrintToServer(arg2);
	if (!(StrEqual(arg2, "on", false) || StrEqual(arg2, "off", false))) {
		PrintToChat(client, "\x01[\x03JA\x01] Your second argument is not valid.");
		return Plugin_Handled;
	}
	else {
		toSet = (StrEqual(arg2, "on", false));
	}
	if (StrEqual(arg1, "ammo", false)) {
		g_bRaceAmmoRegen[client] = toSet;
		PrintToChat(client, "\x01[\x03JA\x01] Ammo regen has been set.");
	}
	else if (StrEqual(arg1, "health", false)) {
		g_bRaceHealthRegen[client] = toSet;
		PrintToChat(client, "\x01[\x03JA\x01] Health regen has been set.");
	}
	else if (StrEqual(arg1, "regen", false)) {
		g_bRaceAmmoRegen[client] = toSet;
		g_bRaceHealthRegen[client] = toSet;
		PrintToChat(client, "\x01[\x03JA\x01] Regen has been set.");
	}
	else if (StrEqual(arg1, "cf", false) || StrEqual(arg1, "classforce", false)) {
		g_bRaceClassForce[client] = toSet;
		PrintToChat(client, "\x01[\x03JA\x01] Class force has been set.");
	}
	else {
		PrintToChat(client, "\x01[\x03JA\x01] Invalid setting.");
		return Plugin_Handled;
	}
	return Plugin_Continue;
}

void ApplyRaceSettings(int race) {
	for (int i = 1; i <= MaxClients; i++) {
		if (IsClientInRace(i, race)) {
			g_bAmmoRegen[i] = g_bRaceAmmoRegen[g_iRace[i]];
			g_bHPRegen[i] = g_bRaceHealthRegen[g_iRace[i]];
		}
	}
}

//int GetSpecRace(int client) {
//	return g_bRaceSpec[client];
//}

int GetPlayersInRace(int raceID) {
	int players;
	for (int i = 1; i <= MaxClients; i++) {
		if (IsClientInRace(i, raceID)) {
			players++;
		}
	}
	return players;
}

int GetPlayersStillRacing(int raceID) {
	int players;
	for (int i = 1; i <= MaxClients; i++) {
		if (IsClientInRace(i, raceID) && !IsPlayerFinishedRacing(i)) {
			players++;
		}
	}
	return players;
}

void LeaveRace(int client) {
	int race = g_iRace[client];
	if (race == 0) {
		return;
	}
	if (GetPlayersInRace(race) == 0) {
		ResetRace(race);
	}
	if (client == race) {
		if (GetPlayersInRace(race) == 1) {
			ResetRace(race);
		}
		else {
			if (HasRaceStarted(race)) {
					for (int i = 1; i <= MaxClients; i++) {
						if (IsClientInRace(i, race) && IsClientRacing(i) && !IsRaceLeader(i, race)) {
							int newRace = i, a[32];
							float b[32];
							g_iRaceStatus[i] = g_iRaceStatus[race];
							g_iRaceEndPoint[i] = g_iRaceEndPoint[race];
							g_fRaceStartTime[i] = g_fRaceStartTime[race];
							g_fRaceFirstTime[i] = g_fRaceFirstTime[race];
							g_bRaceAmmoRegen[i] = g_bRaceAmmoRegen[race];
							g_bRaceHealthRegen[i] = g_bRaceHealthRegen[race];
							g_bRaceClassForce[i] = g_bRaceClassForce[race];
							g_fRaceTimes[i] = g_fRaceTimes[race];
							g_iRaceFinishedPlayers[i] = g_iRaceFinishedPlayers[race];
							g_iRace[client] = 0;
							g_fRaceTime[client] = 0.0;
							g_bRaceLocked[client] = false;
							g_fRaceFirstTime[client] = 0.0;
							g_iRaceEndPoint[client] = 0;
							g_fRaceStartTime[client] = 0.0;
							g_iRaceFinishedPlayers[client] = a;
							g_fRaceTimes[client] = b;

							for (int j = 1; j <= MaxClients; j++) {
								if (IsClientRacing(j) && !IsRaceLeader(j, race)) {
									g_iRace[j] = newRace;
								}
							}
							return;
						}
					}
			}
			else {
				PrintToRace(race, "The race has been cancelled.");
				ResetRace(race);
			}
		}
	}
	else {
		g_iRace[client] = 0;
		g_fRaceTime[client] = 0.0;
		g_bRaceLocked[client] = false;
		g_fRaceFirstTime[client] = 0.0;
		g_iRaceEndPoint[client] = 0;
		g_fRaceStartTime[client] = 0.0;
	}
	char clientName[128], buffer[128];
	GetClientName(client, clientName, sizeof(clientName));
	Format(buffer, sizeof(buffer), "%s has left the race.", clientName);
	PrintToRace(race, buffer);
}

void ResetRace(int raceID) {
	for (int i = 0; i <= MaxClients; i++) {
		if (IsClientInRace(i, raceID)) {
			g_iRace[i] = 0;
			g_iRaceStatus[i] = STATUS_NONE;
			g_fRaceTime[i] = 0.0;
			g_bRaceLocked[i] = false;
			g_fRaceFirstTime[i] = 0.0;
			g_iRaceEndPoint[i] = 0;
			g_fRaceStartTime[i] = 0.0;
			g_bRaceAmmoRegen[i] = false;
			g_bRaceHealthRegen[i] = false;
			g_bRaceClassForce[i] = true;
		}
		g_fRaceTimes[raceID][i] = 0.0;
		g_iRaceFinishedPlayers[raceID][i] = 0;
	}
}

void EmitSoundToRace (int raceID, char[] sound) {
	for (int i = 1; i <= MaxClients; i++) {
		if (IsClientInRace(i, raceID) || IsClientSpectatingRace(i, raceID)) {
			EmitSoundToClient(i, sound);
		}
	}
}
void EmitSoundToNotRace (int raceID, char[] sound) {
	for (int i = 1; i <= MaxClients; i++) {
		if (!IsClientInRace(i, raceID) && !IsClientSpectatingRace(i, raceID) && IsValidClient(i)) {
			EmitSoundToClient(i, sound);
		}
	}
}

bool IsClientRacing(int client) {
	return (g_iRace[client] != 0);
}

bool IsClientInRace(int client, int race) {
	return (g_iRace[client] == race);
}

int GetRaceStatus(int client) {
	return g_iRaceStatus[g_iRace[client]];
}

bool IsRaceLeader(int client, int race) {
	return (client == race);
}

bool HasRaceStarted(int client) {
	return (g_iRaceStatus[g_iRace[client]] > 1);
}

bool IsPlayerFinishedRacing(int client) {
	return (g_fRaceTime[client] != 0.0);
}

bool IsClientSpectatingRace(int client, int race) {
	if (!IsValidClient(client) || !IsClientObserver(client)) {
		return false;
	}

	int clientToShow, iObserverMode;
	iObserverMode = GetEntPropEnt(client, Prop_Send, "m_iObserverMode");
	clientToShow = GetEntPropEnt(client, Prop_Send, "m_hObserverTarget");
	if (!IsValidClient(client) || !IsValidClient(clientToShow) || iObserverMode == 6) {
		return false;
	}
	if (IsClientInRace(clientToShow, race)) {
		return true;
	}
	return false;
}

char TimeFormat(float timeTaken) {
	int intTimeTaken;
	int seconds;
	int minutes;
	int hours;
	float ms;
	char msFormat[128];
	char msFormatFinal[128];
	char final[128];
	char secondsString[128];
	char minutesString[128];
	char hoursString[128];

	ms = timeTaken-RoundToZero(timeTaken);
	Format(msFormat, sizeof(msFormat), "%.3f", ms);
	strcopy(msFormatFinal, sizeof(msFormatFinal), msFormat[2]);
	intTimeTaken = RoundToZero(timeTaken);
	seconds = intTimeTaken % 60;
	minutes = (intTimeTaken-seconds)/60;
	hours = (intTimeTaken-seconds - minutes * 60)/60;
	secondsString = FormatTimeComponent(seconds);
	minutesString = FormatTimeComponent(minutes);
	hoursString = FormatTimeComponent(hours);

	if (hours != 0) {
		Format(final, sizeof(final), "%s:%s:%s:%s", hoursString, minutesString, secondsString, msFormatFinal);
	}
	else {
		Format(final, sizeof(final), "%s:%s:%s", minutesString, secondsString, msFormatFinal);
	}
	return final;
}

char FormatTimeComponent(int time) {
	char final[8];
	if (time > 9) {
		Format(final, sizeof(final), "%d", time);
	}
	else {
		Format(final, sizeof(final), "0%d", time);
	}
	return final;
}

//bool IsRaceOver(int client) {
//	return (g_iRaceStatus[client] == STATUS_COMPLETE);
//}

public Action cmdToggleAmmo(int client, int args) {
	if (!IsValidClient(client)) {
		return;
	}
	if (cvarSpeedrunEnabled.BoolValue && IsSpeedrunMap()&& g_iSpeedrunStatus[client]) {
		PrintToChat(client, "\x01[\x03JA\x01] You may not change regen during a speedrun");
		return;
	}
	if (IsClientRacing(client) && !IsPlayerFinishedRacing(client) && HasRaceStarted(client)) {
		ReplyToCommand(client, "\x01[\x03JA\x01] You may not change regen during a race");
		return;
	}
	SetRegen(client, "Ammo", "z");
}

public Action cmdToggleHealth(int client, int args) {
	if (!IsValidClient(client)) {
		return;
	}
	if (cvarSpeedrunEnabled.BoolValue && IsSpeedrunMap()&& g_iSpeedrunStatus[client]) {
		PrintToChat(client, "\x01[\x03JA\x01] You may not change regen during a speedrun");
		return;
	}
	if (IsClientRacing(client) && !IsPlayerFinishedRacing(client) && HasRaceStarted(client)) {
		ReplyToCommand(client, "\x01[\x03JA\x01] You may not change regen during a race");
		return;
	}
	SetRegen(client, "Health", "z");
}

public Action cmdToggleHardcore(int client, int args) {
	if (!IsValidClient(client)) {
		return;
	}
	if (IsUsingJumper(client)) {
		PrintToChat(client, "\x01[\x03JA\x01] %t", "Jumper_Command_Disabled");
		return;
	}
	Hardcore(client);
}

public Action cmdJAHelp(int client, int args) {
	if (IsUserAdmin(client)) {
		ReplyToCommand(client, "**********ADMIN COMMANDS**********");
		ReplyToCommand(client, "mapset - Change map settings");
		ReplyToCommand(client, "addtele - Add a teleport location");
		ReplyToCommand(client, "jatele - Teleport a user to a location");
	}
	Panel panel = new Panel();
	panel.SetTitle("Help Menu:");
	panel.DrawItem("Saving and Teleporting");
	panel.DrawItem("Regen");
	panel.DrawItem("Skeys");
	panel.DrawItem("Racing");
	panel.DrawItem("Miscellaneous");
	panel.DrawText(" ");
	panel.DrawItem("Exit");
	panel.Send(client, JAHelpHandler, 15);
	delete panel;

	return;
}

int JAHelpHandler(Menu menu, MenuAction action, int client, int choice) {
	if (choice < 1 || choice == 6) {
		return;
	}

	Panel panel = new Panel();
	switch (choice) {
		case 1: {
			panel.SetTitle("Save Help");
			panel.DrawText("!save or !s - Saves your position");
			panel.DrawText("!tele or !t - Teleports you to your saved position");
			panel.DrawText("!undo - Reverts your last save");
			panel.DrawText("!reset or !r - Restarts you on the map");
			panel.DrawText("!restart - Deletes your save and restarts you");
		}
		case 2: {
			panel.SetTitle("Regen Help");
			panel.DrawText("!regen <on|off> - Sets ammo & health regen");
			panel.DrawText("!ammo - Toggles ammo regen");
			panel.DrawText("!health - Toggles health regen");
		}
		case 3: {
			panel.SetTitle("Skeys Help");
			panel.DrawText("!skeys - Shows key presses on the screen");
			panel.DrawText("!skeys_color <R> <G> <B> - Skeys color");
			panel.DrawText("!skeys_loc <X> <Y> - Sets skeys location with x and y values from 0 to 1");
		}
		case 4: {
			panel.SetTitle("Racing Help");
			panel.DrawText("!race - Initialize a race and select final CP.");
			panel.DrawText("!r_info - Provides info about the current race.");
			panel.DrawText("!r_inv - Invite players to the race.");
			panel.DrawText("!r_set - Change settings of a race.");
			panel.DrawText("     <classforce|cf|ammo|health|regen>");
			panel.DrawText("     <on|off>");
			panel.DrawText("!r_list - Lists race players and their times");
			panel.DrawText("!r_spec - Spectates a race.");
			panel.DrawText("!r_start - Start the race.");
			panel.DrawText("!r_leave - Leave a race.");
		}
		case 5: {
			panel.DrawText("!jumpassist - Shows the JumpAssist forum page.");
			panel.DrawText("!jumptf - Shows the Jump.tf website.");
			panel.DrawText("!forums - Shows the Jump.tf forums.");			
		}
	}
	panel.DrawText(" ");
	panel.DrawItem("Back");
	panel.DrawItem("Exit");
	panel.Send(client, HelpMenuHandler, 15);
	delete panel;
}

int HelpMenuHandler(Menu menu, MenuAction action, int param1, int param2) {
	if (param2 == 1) {
		cmdJAHelp(param1, 0);
	}
}
bool IsUsingJumper(int client) {
	if (!IsValidClient(client)) {
		return false;
	}
	switch (TF2_GetPlayerClass(client)) {
		case TFClass_Soldier: {
			if (!IsValidWeapon(g_iClientWeapons[client][0])) {
				return false;
			}
			int sol_weap = GetEntProp(g_iClientWeapons[client][0], Prop_Send, "m_iItemDefinitionIndex");
			switch (sol_weap) {
				case 237: {
					return true;
				}
			}
		}
		case TFClass_DemoMan: {
			if (!IsValidWeapon(g_iClientWeapons[client][1])) {
				return false;
			}
			int dem_weap = GetEntProp(g_iClientWeapons[client][1], Prop_Send, "m_iItemDefinitionIndex");
			switch (dem_weap) {
				case 265: {
					return true;
				}
			}
		}
	}
	return false;
}
void CheckBeggers(int client) {
	int iWeapon = GetPlayerWeaponSlot(client, 0), index = hArray_NoFuncRegen.FindValue(client);

	if (IsValidEntity(iWeapon) && GetEntProp(iWeapon, Prop_Send, "m_iItemDefinitionIndex") == 730) {
		if (index == -1) {
			hArray_NoFuncRegen.Push(client);
#if defined DEBUG
			LogMessage("Preventing player %d from touching func_regenerate");
#endif
		}
	}
	else if (index != -1) {
		hArray_NoFuncRegen.Erase(index);
#if defined DEBUG
	LogMessage("Allowing player %d to touch func_regenerate");
#endif
	}
}
bool IsStringNumeric(const char[] MyString) {
	int n = 0;
	while (MyString[n] != '\0') {
		if (!IsCharNumeric(MyString[n])) {
			return false;
		}
		n++;
	}
	return true;
}

public Action RunQuery(int client, int args) {
	if (args < 1) {
		ReplyToCommand(client, "\x01[\x03JA\x01] More parameters are required for this command.");
		return Plugin_Handled;
	}
	char query[1024];

	GetCmdArgString(query, sizeof(query));
	g_hDatabase.Query(SQL_OnPlayerRanSQL, query, client);
	return Plugin_Handled;
}

public Action cmdUnkillable(int client, int args) {
	if (!cvarPluginEnabled.BoolValue) {
		return Plugin_Handled;
	}
	if (cvarSpeedrunEnabled.BoolValue && IsSpeedrunMap()&& g_iSpeedrunStatus[client]) {
		ReplyToCommand(client, "\x01[\x03JA\x01] You may not use superman during a speedrun");
		return Plugin_Handled;
	}
	if (!cvarSuperman.BoolValue && !IsUserAdmin(client)) {
		PrintToChat(client, "\x01[\x03JA\x01] %t", "Command_Locked");
		return Plugin_Handled;
	}
	if (g_bSpeedRun[client]) {
		PrintToChat(client, "\x01[\x03JA\x01] %t", "Speedrun_Active");
		return Plugin_Handled;
	}
	if (!g_bUnkillable[client]) {
		SetEntProp(client, Prop_Data, "m_takedamage", 1, 1);
		PrintToChat(client, "\x01[\x03JA\x01] %t", "Regen_UnkillableOn");
		g_bUnkillable[client] = true;
	}
	else {
		SetEntProp(client, Prop_Data, "m_takedamage", 2, 1);
		PrintToChat(client, "\x01[\x03JA\x01] %t", "Regen_UnkillableOff");
		g_bUnkillable[client] = false;
	}
	return Plugin_Handled;
}

public Action cmdUndo(int client, int args) {
	if (g_bSpeedRun[client]) {
		PrintToChat(client, "\x01[\x03JA\x01] %t", "Save_UndoSpeedRun");
		return Plugin_Handled;
	}
	if (g_fLastSavePos[client][0] == 0.0) {
		PrintToChat(client, "\x01[\x03JA\x01] %t", "Save_UndoCant");
		return Plugin_Handled;
	}
	else {
		g_fOrigin[client] = g_fLastSavePos[client];
		g_fAngles[client] = g_fLastSaveAngles[client];
		g_fLastSavePos[client] = NULL_VECTOR;
		PrintToChat(client, "\x01[\x03JA\x01] %t", "Save_Undo");

		return Plugin_Handled;
	}
}

public Action cmdDoRegen(int client, int args) {
	if (cvarSpeedrunEnabled.BoolValue && IsSpeedrunMap()&& g_iSpeedrunStatus[client]) {
		ReplyToCommand(client, "\x01[\x03JA\x01] You may not change regen during a speedrun");
		return Plugin_Handled;
	}
	if (IsClientRacing(client) && !IsPlayerFinishedRacing(client) && HasRaceStarted(client)) {
		ReplyToCommand(client, "\x01[\x03JA\x01] You may not change regen during a race");
		return Plugin_Handled;
	}
	char arg1[MAX_NAME_LENGTH];

	GetCmdArg(1, arg1, sizeof(arg1));
	if (StrEqual(arg1, "on", false)) {
		SetRegen(client, "regen", "on");
		return Plugin_Handled;
	}
	else if (StrEqual(arg1, "off", false)) {
		SetRegen(client, "regen", "off");
		return Plugin_Handled;
	}
	else {
		SetRegen(client, "Regen", "Display");
	}
	return Plugin_Handled;
}
//public Action cmdClearSave(int client, int args)
//{
//  if (cvarPluginEnabled.BoolValue)
//  {
//      EraseLocs(client);
//      PrintToChat(client, "\x01[\x03JA\x01] %t", "Player_ClearedSave");
//  }
//  return Plugin_Handled;
//}

public Action cmdSendPlayer(int client, int args) {
	if (g_hDatabase == null) {
		PrintToChat(client, "This feature is not supported without a database configuration");
		return Plugin_Handled;
	}
	if (cvarPluginEnabled.BoolValue) {
		if (args < 2) {
			ReplyToCommand(client, "\x01[\x03JA\x01] %t", "SendPlayer_Help", LANG_SERVER);
			return Plugin_Handled;
		}
		char arg1[MAX_NAME_LENGTH], arg2[MAX_NAME_LENGTH];
		GetCmdArg(1, arg1, sizeof(arg1));
		GetCmdArg(2, arg2, sizeof(arg2));

		int target1 = FindTarget2(client, arg1, true, false);
		int target2 = FindTarget2(client, arg2, true, false);

		if (target1 < 1 || target2 < 1) {
			return Plugin_Handled;
		}

		if (g_iSpeedrunStatus[target1]) {
			ReplyToCommand(client, "\x01[\x03JA\x01] You cannot send a player in a speedrun");
			return Plugin_Handled;
		}
		if (target1 == client) {
			ReplyToCommand(client, "\x01[\x03JA\x01] %t", "SendPlayer_Self", cLightGreen, cDefault);
			return Plugin_Handled;
		}
		if (!target1 || !target2) {
			return Plugin_Handled;
		}
		char target1_name[MAX_NAME_LENGTH];
		char target2_name[MAX_NAME_LENGTH];
		float TargetOrigin[3];
		float pAngle[3];
		float pVec[3];

		GetClientAbsOrigin(target2, TargetOrigin);
		GetClientAbsAngles(target2, pAngle);

		pVec = NULL_VECTOR;

		TeleportEntity(target1, TargetOrigin, pAngle, pVec);
		GetClientName(target1, target1_name, sizeof(target1_name));
		GetClientName(target2, target2_name, sizeof(target2_name));

		ShowActivity2(client, "\x01[\x03JA\x01] ", "%t", "Send_Player", target1_name, target2_name);
	}
	return Plugin_Handled;
}

public Action cmdGotoClient(int client, int args) {
	if (cvarPluginEnabled.BoolValue) {
		//can use this too g_bBeatTheMap[client] && !g_bSpeedRun[client]
		if (IsUserAdmin(client)) {
			if (args < 1) {
				ReplyToCommand(client, "\x01[\x03JA\x01] %t", "Goto_Help", LANG_SERVER);
				return Plugin_Handled;
			}
			if (IsClientObserver(client)) {
				ReplyToCommand(client, "\x01[\x03JA\x01] %t", "Goto_Spectate", LANG_SERVER);
				return Plugin_Handled;
			}
			if (cvarSpeedrunEnabled.BoolValue && IsSpeedrunMap()&& g_iSpeedrunStatus[client]) {
				ReplyToCommand(client, "\x01[\x03JA\x01] Cannot use goto while in a speedrun");
				return Plugin_Handled;
			}
			else {
				char arg1[MAX_NAME_LENGTH];
				char target_name[MAX_TARGET_LENGTH];
				int target_list[MAXPLAYERS];
				int target_count;
				bool tn_is_ml;
				float TeleportOrigin[3];
				float PlayerOrigin[3];
				float pAngle[3];
				float PlayerOrigin2[3];
				float g_fPosVec[3];

				GetCmdArg(1, arg1, sizeof(arg1));
				if ((target_count = ProcessTargetString(
					arg1
					, client
					, target_list
					, MAXPLAYERS
					, COMMAND_FILTER_NO_IMMUNITY
					, target_name
					, sizeof(target_name)
					, tn_is_ml)
				) <= 0) {
					ReplyToCommand(client, "\x01[\x03JA\x01] %t", "No matching client", LANG_SERVER);
					return Plugin_Handled;
				}
				if (target_count > 1) {
					ReplyToCommand(client, "\x01[\x03JA\x01] %t", "More than one client matched", LANG_SERVER);
					return Plugin_Handled;
				}
				for (int i = 0; i < target_count; i++) {
					if (IsClientObserver(target_list[i]) || !IsValidClient(target_list[i])) {
						ReplyToCommand(client, "\x01[\x03JA\x01] %t", "Goto_Cant", LANG_SERVER, target_name);
						return Plugin_Handled;
					}
					if (target_list[i] == client) {
						ReplyToCommand(client, "\x01[\x03JA\x01] %t", "Goto_Self", LANG_SERVER);
						return Plugin_Handled;
					}
					GetClientAbsOrigin(target_list[i], PlayerOrigin);
					GetClientAbsAngles(target_list[i], PlayerOrigin2);

					TeleportOrigin = PlayerOrigin;
					pAngle = PlayerOrigin2;

					g_fPosVec = NULL_VECTOR;

					TeleportEntity(client, TeleportOrigin, pAngle, g_fPosVec);
					PrintToChat(client, "\x01[\x03JA\x01] %t", "Goto_Success", target_name);
				}
			}
		}
		else {
			ReplyToCommand(client, "\x01[\x03JA\x01] %t", "No Access", LANG_SERVER);
			return Plugin_Handled;
		}
	}
	return Plugin_Handled;
}

public Action cmdReset(int client, int args) {
	if (cvarPluginEnabled.BoolValue) {
		if (IsClientObserver(client)) {
			return Plugin_Handled;
		}
		g_iLastTeleport[client] = 0;
		SendToStart(client);
		g_bUsedReset[client] = true;
	}
	return Plugin_Handled;
}

public Action cmdTele(int client, int args) {
	if (!cvarPluginEnabled.BoolValue) {
		return Plugin_Handled;
	}
	if (cvarSpeedrunEnabled.BoolValue && IsSpeedrunMap()&& g_iSpeedrunStatus[client]) {
		PrintToChat(client, "\x01[\x03JA\x01] You may not teleport while speedrunning");
		return Plugin_Handled;
	}
	Teleport(client);
	g_iLastTeleport[client] = RoundFloat(GetEngineTime());
	return Plugin_Handled;
}

public Action cmdSave(int client, int args) {
	if (!cvarPluginEnabled.BoolValue) {
		return Plugin_Handled;
	}
	SaveLoc(client);
	return Plugin_Handled;
}

void Teleport(int client) {
	if (!cvarPluginEnabled.BoolValue) {
		return;
	}
	if (!IsValidClient(client)) {
		return;
	}
	if (g_iRace[client] && (g_iRaceStatus[g_iRace[client]] == STATUS_COUNTDOWN || g_iRaceStatus[g_iRace[client]] == STATUS_RACING)) {
		PrintToChat(client, "\x01[\x03JA\x01] Cannot teleport while racing.");
		return;
	}
	if (g_bSpeedRun[client]) {
		PrintToChat(client, "\x01[\x03JA\x01] %t", "Speedrun_Active");
		return;
	}
	int g_iClass = view_as<int>(TF2_GetPlayerClass(client));
	int g_iTeam = GetClientTeam(client);
	char g_sClass[32], g_sTeam[32];
	float g_vVelocity[3];

	g_vVelocity = NULL_VECTOR;

	Format(g_sClass, sizeof(g_sClass), "%s", GetClassname(g_iClass));

	if (g_iTeam == 2) {
		Format(g_sTeam, sizeof(g_sTeam), "%T", "Red_Team", LANG_SERVER);
	}
	else if (g_iTeam == 3) {
		Format(g_sTeam, sizeof(g_sTeam), "%T", "Blu_Team", LANG_SERVER);
	}
	if (g_bHardcore[client]) {
		PrintToChat(client, "\x01[\x03JA\x01] %t", "Teleports_Disabled");
	}
	else if (!IsPlayerAlive(client)) {
		PrintToChat(client, "\x01[\x03JA\x01] %t", "Teleport_Dead");
	}
	else if (g_fOrigin[client][0] == 0.0) {
		PrintToChat(client, "\x01[\x03JA\x01] %t", "Teleport_NoSave", g_sClass, g_sTeam, cLightGreen, cDefault, cLightGreen, cDefault);
	}
	else {
		TeleportEntity(client, g_fOrigin[client], g_fAngles[client], g_vVelocity);
		PrintToChat(client, "\x01[\x03JA\x01] %t", "Teleported_Self");
	}
}

void SaveLoc(int client) {
	if (!cvarPluginEnabled.BoolValue) {
		return;
	}
	if (g_bSpeedRun[client]) {
		PrintToChat(client, "\x01[\x03JA\x01] %t", "Speedrun_Active");
		return;
	}
	if (g_bHardcore[client]) {
		PrintToChat(client, "\x01[\x03JA\x01] %t", "Saves_Disabled");
	}
	else if (!IsPlayerAlive(client)) {
		PrintToChat(client, "\x01[\x03JA\x01] %t", "Saves_Dead");
	}
	else if (!(GetEntityFlags(client) & FL_ONGROUND)) {
		PrintToChat(client, "\x01[\x03JA\x01] %t", "Saves_InAir");
	}
	else if (GetEntProp(client, Prop_Send, "m_bDucked") == 1) {
		PrintToChat(client, "\x01[\x03JA\x01] %t", "Saves_Ducked");
	}
	else {
		g_fLastSavePos[client] = g_fOrigin[client];
		g_fLastSaveAngles[client] = g_fAngles[client];

		GetClientAbsOrigin(client, g_fOrigin[client]);
		GetClientAbsAngles(client, g_fAngles[client]);
		if (g_hDatabase != null) {
			GetPlayerData(client);
		}

		PrintToChat(client, "\x01[\x03JA\x01] %t", "Saves_Location");
	}
}

void ResetPlayerPos(int client) {
	if (!cvarPluginEnabled.BoolValue) {
		return;
	}
	if (!IsClientInGame(client) || IsClientObserver(client)) {
		return;
	}
	DeletePlayerData(client);
	return;
}

void Hardcore(int client) {
	if (!cvarPluginEnabled.BoolValue) {
		return;
	}
	char steamid[32];

	GetClientAuthId(client, AuthId_Steam2, steamid, sizeof(steamid));
	if (!IsClientInGame(client) || IsClientObserver(client)) {
		return;
	}

	if (!g_bHardcore[client]) {
		g_bHardcore[client] = true;
		g_bHPRegen[client] = false;
		EraseLocs(client);
		if (cvarSpeedrunEnabled.BoolValue && IsSpeedrunMap()&& g_iSpeedrunStatus[client]) {
			RestartSpeedrun(client);
		}
		else {
			TF2_RespawnPlayer(client);
		}
		PrintToChat(client, "\x01[\x03JA\x01] %t", "Hardcore_On", cLightGreen, cDefault);
	}
	else {
		g_bHardcore[client] = false;
		LoadPlayerData(client);
		PrintToChat(client, "\x01[\x03JA\x01] %t", "Hardcore_Off");
	}
}

void SetRegen(int client, char[] RegenType, char[] RegenToggle) {
	if (!cvarPluginEnabled.BoolValue) {
		return;
	}
	if (StrEqual(RegenType, "Ammo", false)) {
		g_bHardcore[client] = false;
		g_bAmmoRegen[client] = !g_bAmmoRegen[client];
		PrintToChat(client, "\x01[\x03JA\x01] %t", g_bAmmoRegen[client] ? "Regen_AmmoOnlyOn" : "Regen_AmmoOnlyOff");
		return;
	}
	else if (StrEqual(RegenType, "Health", false)) {
		g_bHardcore[client] = false;
		g_bHPRegen[client] = !g_bHPRegen[client];
		PrintToChat(client, "\x01[\x03JA\x01] %t", g_bHPRegen[client] ? "Regen_HealthOnlyOn" : "Regen_HealthOnlyOff");
		return;
	}
	else if (StrEqual(RegenType, "Regen", false) && StrEqual(RegenToggle, "display", false)) {
		PrintToChat(client, "\x01[\x03JA\x01] %t", g_bAmmoRegen[client] ? "Regen_DisplayAmmoOn" : "Regen_DisplayAmmoOff");
		PrintToChat(client, "\x01[\x03JA\x01] %t", g_bHPRegen[client] ? "Regen_DisplayHealthOn" : "Regen_DisplayHealthOff");
		PrintToChat(client, "\x01[\x03JA\x01] %t", "Regen_ShowHelp");
		return;
	}
	else if (StrEqual(RegenType, "Regen", false) && StrEqual(RegenToggle, "on", false)) {
		g_bAmmoRegen[client] = true;
		g_bHPRegen[client] = true;
		g_bHardcore[client] = false;
		PrintToChat(client, "\x01[\x03JA\x01] %t", "Regen_On");
	}
	else if (StrEqual(RegenType, "Regen", false) && StrEqual(RegenToggle, "off", false)) {
		g_bAmmoRegen[client] = false;
		g_bHPRegen[client] = false;
		g_bHardcore[client] = false;
		PrintToChat(client, "\x01[\x03JA\x01] %t", "Regen_Off");
	}
	else {
		LogError("Unknown regen settings.");
	}
	return;
}

public Action cmdJumpTF(int client, int args) {
	if (!cvarPluginEnabled.BoolValue) {
		return;
	}
	ShowMOTDPanel(client, "Jump Assist Help", g_sWebsite, MOTDPANEL_TYPE_URL);
	return;
}

public Action cmdJumpAssist(int client, int args) {
	if (!cvarPluginEnabled.BoolValue) {
		return;
	}
	ShowMOTDPanel(client, "Jump Assist Help", g_sJumpAssist, MOTDPANEL_TYPE_URL);
	return;
}

public Action cmdJumpForums(int client, int args) {
	if (!cvarPluginEnabled.BoolValue) {
		return;
	}
	ShowMOTDPanel(client, "Jump Assist Help", g_sForum, MOTDPANEL_TYPE_URL);
	return;
}

public Action OnPlayerRunCmd(int client, int& buttons, int& impulse, float vel[3], float angles[3], int& weapon) {
	//FOR SKEYS AS WELL AS REGEN
	g_iButtons[client] = buttons;
	if ((g_iButtons[client] & IN_ATTACK)) {
		if (g_bAmmoRegen[client]) {
			for (int i = 0; i < 3; i++ ) {
				ReSupply(client, g_iClientWeapons[client][i]);
			}
		}
		if (g_bHPRegen[client]) {
			int iMaxHealth = GetEntProp(GetPlayerResourceEntity(), Prop_Send, "m_iMaxHealth", _, client);
			SetEntityHealth(client, iMaxHealth);
		}
	}
	if (g_bRaceLocked[client]) {
		vel = NULL_VECTOR;
	}
	return Plugin_Continue;
}

public void SDKHook_OnWeaponEquipPost(int client, int weapon) {
	if (IsValidClient(client)) {
		for (int i = 0; i < 3; i++) {
			g_iClientWeapons[client][i] = GetPlayerWeaponSlot(client, i);
		}
	}
}

bool IsValidWeapon(int entity) {
	char strClassname[128];
	return (IsValidEntity(entity)
		&& GetEntityClassname(entity, strClassname, sizeof(strClassname))
		&& StrContains(strClassname, "tf_weapon", false) != -1);
}

void ReSupply(int client, int weapon) {
	if (!cvarPluginEnabled.BoolValue) {
		return;
	}
	if (!IsValidWeapon(weapon)) {
		return;
	}
	if (!IsValidClient(client) || !IsPlayerAlive(client)) {
		return;
	}

	//Grab the weapon index
	int weapIndex = GetEntProp(weapon, Prop_Send, "m_iItemDefinitionIndex");

	char className[128];
	//Grab the weapon's classname
	GetEntityClassname(weapon, className, sizeof(className));

	//Rocket Launchers
	if (StrEqual(className, "tf_weapon_rocketlauncher") || StrEqual(className, "tf_weapon_particle_cannon")) {
		switch (weapIndex) {
			//The Cow Mangler 5000
			case 441: {
				//Cow Mangler uses Energy instead of ammo.
				SetEntPropFloat(weapon, Prop_Send, "m_flEnergy", 100.0);
			}
			//Black Box
			case 228, 1085: {
				SetEntProp(weapon, Prop_Send, "m_iClip1", 3);
			}
			//Liberty Launcher
			case 414: {
				SetEntProp(weapon, Prop_Send, "m_iClip1", 5);
			}
			//Beggar's Bazooka - This is here so we don't keep refilling its clip infinitely.
			case 730: {}
			default: {
				SetEntProp(weapon, Prop_Send, "m_iClip1", 4);
			}
		}
		//Refill the player's ammo supply to whatever the weapon's max is.
		GivePlayerAmmo(client, 100, view_as<int>(TFWeaponSlot_Primary)+1, false);
	}
	//Stickybomb Launchers
	else if (StrEqual(className, "tf_weapon_pipebomblauncher")) {
		switch (weapIndex) {
			//Quickiebomb Launcher
			case 1150: {
				SetEntProp(weapon, Prop_Send, "m_iClip1", 4);
			}
			//The default action for Stickybomb Launchers
			default: {
				SetEntProp(weapon, Prop_Send, "m_iClip1", 8);
			}
		}
		//Refill the player's ammo supply to whatever the weapon's max is.
		GivePlayerAmmo(client, 100, view_as<int>(TFWeaponSlot_Secondary)+1, false);
	}
	//Shotguns
	else if (StrEqual(className, "tf_weapon_shotgun") || StrEqual(className, "tf_weapon_sentry_revenge")) {
		switch (weapIndex) {
			//Family Business
			case 425: {
				SetEntProp(weapon, Prop_Send, "m_iClip1", 8);
			}
			//Rescue Ranger, Reserve Shooter
			case 997, 415: {
				SetEntProp(weapon, Prop_Send, "m_iClip1", 4);
			}
			//Frontier Justice
			case 141, 1004: {
				SetEntProp(weapon, Prop_Send, "m_iClip1", 3);
			}
			//Widowmaker
			case 527: {
				//Sets Metal count to 200
				SetEntProp(client, Prop_Data, "m_iAmmo", 200, _, 3);
			}
			//The default action for Shotguns
			default: {
				SetEntProp(weapon, Prop_Send, "m_iClip1", 6);
			}
		}
		int ammoSlot = (TF2_GetPlayerClass(client) == TFClass_Engineer) ? TFWeaponSlot_Primary : TFWeaponSlot_Secondary;
		//Refill the player's ammo supply to whatever the weapon's max is.
		GivePlayerAmmo(client, 100, ammoSlot+1, false);
	}
	// Ullapool caber
	/* Removed
	if (!StrContains(szClassname, "tf_weapon_stickbomb")) {
		if (g_hReloadUC.BoolValue) {
			SetEntProp(weapon, Prop_Send, "m_bBroken", 0);
			SetEntProp(weapon, Prop_Send, "m_iDetonated", 0);
		}
	}
	*/
}

//void SetAmmo(int client, int weapon, int ammo) {
//	if (GetEntProp(weapon, Prop_Send, "m_iPrimaryAmmoType"); != -1) {
//		SetEntProp(client, Prop_Data, "m_iAmmo", ammo, _, iAmmoType);
//	}
//}

void EraseLocs(int client) {
	if (!cvarPluginEnabled.BoolValue) {
		return;
	}
	g_fOrigin[client] = NULL_VECTOR;
	g_fAngles[client] = NULL_VECTOR;

	for (int j = 0; j < 8; j++) {
		g_bCPTouched[client][j] = false;
		g_iCPsTouched[client] = 0;
	}
	g_bBeatTheMap[client] = false;

	Format(g_sCaps[client], sizeof(g_sCaps), "\0");
}

void CheckTeams() {
	if (!cvarPluginEnabled.BoolValue) {
		return;
	}
	for (int i = 1; i <= MaxClients; i++) {
		if (!IsClientInGame(i) || IsClientObserver(i) || (GetClientTeam(i) == g_iForceTeam)) {
			continue;
		}
		else {
			ChangeClientTeam(i, g_iForceTeam);
			PrintToChat(i, "\x01[\x03JA\x01] %t", "Switched_Teams");
		}
	}
}

void LockCPs() {
	if (!cvarPluginEnabled.BoolValue) {
		return;
	}
	int iCP = -1;
	g_iCPs = 0;
	while ((iCP = FindEntityByClassname(iCP, "trigger_capture_area")) != -1) {
		SetVariantString("2 0");
		AcceptEntityInput(iCP, "SetTeamCanCap");
		SetVariantString("3 0");
		AcceptEntityInput(iCP, "SetTeamCanCap");
		g_iCPs++;
	}
}

public Action cmdRestart(int client, int args) {
	if (!IsValidClient(client) || IsClientObserver(client) || !cvarPluginEnabled.BoolValue) {
		return Plugin_Handled;
	}
	EraseLocs(client);
	if (g_hDatabase != null) {
		ResetPlayerPos(client);
	}
	if (cvarSpeedrunEnabled.BoolValue && IsSpeedrunMap() && g_iSpeedrunStatus[client]) {
		RestartSpeedrun(client);
	}
	else {
		TF2_RespawnPlayer(client);
	}
	PrintToChat(client, "\x01[\x03JA\x01] %t", "Player_Restarted");
	g_iLastTeleport[client] = 0;
	return Plugin_Handled;
}

void SendToStart(int client) {
	if (!IsValidClient(client) || IsClientObserver(client) || !cvarPluginEnabled.BoolValue) {
		return;
	}
	g_bUsedReset[client] = true;
	if (cvarSpeedrunEnabled.BoolValue && IsSpeedrunMap()&& g_iSpeedrunStatus[client]) {
		RestartSpeedrun(client);
	}
	else {
		TF2_RespawnPlayer(client);
	}
	PrintToChat(client, "\x01[\x03JA\x01] %t", "Player_SentToStart");
}

char GetClassname(int class) {
	char buffer[128];
	switch(class) {
		case 1: {
			Format(buffer, sizeof(buffer), "%T", "Class_Scout", LANG_SERVER);
		}
		case 2: {
			Format(buffer, sizeof(buffer), "%T", "Class_Sniper", LANG_SERVER);
		}
		case 3: {
			Format(buffer, sizeof(buffer), "%T", "Class_Soldier", LANG_SERVER);
		}
		case 4: {
			Format(buffer, sizeof(buffer), "%T", "Class_Demoman", LANG_SERVER);
		}
		case 5: {
			Format(buffer, sizeof(buffer), "%T", "Class_Medic", LANG_SERVER);
		}
		case 6: {
			Format(buffer, sizeof(buffer), "%T", "Class_Heavy", LANG_SERVER);
		}
		case 7: {
			Format(buffer, sizeof(buffer), "%T", "Class_Pyro", LANG_SERVER);
		}
		case 8: {
			Format(buffer, sizeof(buffer), "%T", "Class_Spy", LANG_SERVER);
		}
		case 9: {
			Format(buffer, sizeof(buffer), "%T", "Class_Engineer", LANG_SERVER);
		}
	}
	return buffer;
}

bool IsValidClient(int client) {
	return ((0 < client <= MaxClients) && IsClientInGame(client) && !IsFakeClient(client));
}

int jteleHandler(Menu menu, MenuAction action, int client, int item) {
	switch (action) {
		case MenuAction_Select: {
			menu.GetItem(item, g_sJtele, sizeof(g_sJtele));
			JumpList(client);
		}
		case MenuAction_End: {
			delete menu;
		}
	}
}

int FindTarget2(int client, const char[] target, bool nobots = false, bool immunity = true) {
	char target_name[MAX_TARGET_LENGTH];
	int target_list[1];
	int flags = COMMAND_FILTER_NO_MULTI;
	bool tn_is_ml;

	if (nobots) {
		flags |= COMMAND_FILTER_NO_BOTS;
	}
	if (!immunity) {
		flags |= COMMAND_FILTER_NO_IMMUNITY;
	}
	if ((ProcessTargetString(target, client, target_list, 1, flags, target_name, sizeof(target_name), tn_is_ml)) > 0) {
		return target_list[0];
	}
	else {
		return -1;
	}
}

int JumpListHandler(Menu menu, MenuAction action, int client, int item) {
	if (g_hDatabase == null) {
		PrintToChat(client, "This feature is not supported without a database configuration");
		return;
	}
	char MenuInfo[64];
	switch (action) {
		case MenuAction_Select: {
			menu.GetItem(item, MenuInfo, sizeof(MenuInfo));
			MenuSendToLocation(client, g_sJtele, MenuInfo);
		}
		case MenuAction_End: {
			delete menu;
		}
	}
	return;
}

bool IsUserAdmin(int client) {
	return GetUserAdmin(client).HasFlag(Admin_Generic);
}

void SetCvarValues() {
	if (!cvarPluginEnabled.BoolValue) {
		return;
	}
	if (!cvarCriticals.BoolValue) {
		FindConVar("tf_weapon_criticals").SetInt(0, true, false);
	}
	if (cvarCheapObjects.BoolValue) {
		FindConVar("tf_cheapobjects").SetInt(1, false, false);
	}
	if (cvarAmmoCheat.BoolValue) {
		FindConVar("tf_sentrygun_ammocheat").SetInt(1, false, false);
	}
}
/*****************************************************************************************************************
													Natives
*****************************************************************************************************************/
public int Native_JA_GetSettings(Handle plugin, int numParams) {
	int setting = GetNativeCell(1), client = GetNativeCell(2);

	if (client != -1) {
		// Client is only needed for all but 1 setting so far.
		if (client < 1 || client > MaxClients) {
			return ThrowNativeError(SP_ERROR_NATIVE, "Invalid client index (%d)", client);
		}
		if (!IsClientConnected(client)) {
			return ThrowNativeError(SP_ERROR_NATIVE, "Client %d is not connected", client);
		}
	}
	switch (setting) {
		case 1: {
			return g_iMapClass;
		}
		case 2: {
			return g_bAmmoRegen[client];
		}
		case 3: {
			return g_bHPRegen[client];
		}
	}
	return ThrowNativeError(SP_ERROR_NATIVE, "Invalid setting param.");
}

public int Native_JA_ClearSave(Handle plugin, int numParams) {
	int client = GetNativeCell(1);

	if (client < 1 || client > MaxClients) {
		return ThrowNativeError(SP_ERROR_NATIVE, "Invalid client index (%d)", client);
	}
	if (!IsClientConnected(client)) {
		return ThrowNativeError(SP_ERROR_NATIVE, "Client %d is not connected", client);
	}
	EraseLocs(client);
	PrintToChat(client, "\x01[\x03JA\x01] %t", "Native_ClearSave");
	return true;
}

public int Native_JA_PrepSpeedRun(Handle plugin, int numParams) {
	int client = GetNativeCell(1);

	if (client < 1 || client > MaxClients) {
		return ThrowNativeError(SP_ERROR_NATIVE, "Invalid client index (%d)", client);
	}
	if (!IsClientConnected(client)) {
		return ThrowNativeError(SP_ERROR_NATIVE, "Client %d is not connected", client);
	}
	EraseLocs(client);

	if (g_bUnkillable[client]) {
		g_bUnkillable[client] = false;
		SetEntProp(client, Prop_Data, "m_takedamage", 2, 1);
	}
	g_bSpeedRun[client] = true;
	PrintToChat(client, "\x01[\x03JA\x01] %t", "Native_ClearSave");

	return true;
}

public int Native_JA_ReloadPlayerSettings(Handle plugin, int numParams) {
	int client = GetNativeCell(1);

	if (client < 1 || client > MaxClients) {
		return ThrowNativeError(SP_ERROR_NATIVE, "Invalid client index (%d)", client);
	}
	if (!IsClientConnected(client)) {
		return ThrowNativeError(SP_ERROR_NATIVE, "Client %d is not connected", client);
	}
	g_bSpeedRun[client] = false;
	if (g_hDatabase != null) {
		ReloadPlayerData(client);
	}
	return true;
}
/*****************************************************************************************************************
												Player Events
*****************************************************************************************************************/
public Action OnPlayerStartTouchFuncRegenerate(int entity, int other) {
	if (other <= MaxClients && hArray_NoFuncRegen.Length > 0 && hArray_NoFuncRegen.FindValue(other) != -1) {
#if defined DEBUG_FUNC_REGEN
		LogMessage("Entity %d touch %d Prevented", entity, other);
#endif
		return Plugin_Handled;
	}
#if defined DEBUG_FUNC_REGEN
	LogMessage("Entity %d touch %d Allowed", entity, other);
#endif
	return Plugin_Continue;
}

public Action eventPlayerBuiltObj(Event event, const char[] name, bool dontBroadcast) {
	if (!cvarPluginEnabled.BoolValue) {
		return Plugin_Continue;
	}

	int obj = event.GetInt("object"), index = event.GetInt("index");

	if (g_hSDKStartBuilding == null ||g_hSDKFinishBuilding == null || g_hSDKStartUpgrading == null || g_hSDKFinishUpgrading == null) {
		return Plugin_Continue;
	}

	RequestFrame(FrameCallback_StartBuilding, index);
	RequestFrame(FrameCallback_FinishBuilding, index);

	int maxupgradelevel = GetEntProp(index, Prop_Send, "m_iHighestUpgradeLevel");

	if (obj == 2) {
		int mini = GetEntProp(index, Prop_Send, "m_bMiniBuilding");
		if (mini == 1) {
			return Plugin_Continue;
		}
		if (maxupgradelevel >  cvarSentryLevel.IntValue) {
			SetEntProp(index, Prop_Send, "m_iUpgradeLevel", maxupgradelevel);
			RequestFrame(FrameCallback_FinishUpgrading, index);
		}
		else if (cvarSentryLevel.IntValue != 1) {
			SetEntProp(index, Prop_Send, "m_iUpgradeLevel", cvarSentryLevel.IntValue-1);
			SetEntProp(index, Prop_Send, "m_iHighestUpgradeLevel", cvarSentryLevel.IntValue-1);
			RequestFrame(FrameCallback_StartUpgrading, index);
			RequestFrame(FrameCallback_FinishUpgrading, index);
		}
	}
	else {
		SetEntProp(index, Prop_Send, "m_iUpgradeLevel", 2);
		SetEntProp(index, Prop_Send, "m_iHighestUpgradeLevel", 2);
		RequestFrame(FrameCallback_StartUpgrading, index);
		RequestFrame(FrameCallback_FinishUpgrading, index);
	}
	SetEntProp(index, Prop_Send, "m_CollisionGroup", 2);
	SetEntProp(index, Prop_Send, "m_iUpgradeMetalRequired", 0);
	SetVariantInt(GetEntProp(index, Prop_Data, "m_iMaxHealth"));
	AcceptEntityInput(index, "SetHealth");
	return Plugin_Continue;
}

public Action eventPlayerUpgradedObj(Event event, const char[] name, bool dontBroadcast) {
	if (!cvarPluginEnabled.BoolValue) {
		return Plugin_Continue;
	}
	if (g_hSDKFinishUpgrading != null) {
		int entity = event.GetInt("index");
		RequestFrame(FrameCallback_FinishUpgrading, entity);
	}
	return Plugin_Continue;
}

public void FrameCallback_StartBuilding(any entity) {
	SDKCall(g_hSDKStartBuilding, entity);
}

public void FrameCallback_FinishBuilding(any entity) {
	SDKCall(g_hSDKFinishBuilding, entity);
}

public void FrameCallback_StartUpgrading(any entity) {
	SDKCall(g_hSDKStartUpgrading, entity);
}

public void FrameCallback_FinishUpgrading(any entity) {
	SDKCall(g_hSDKFinishUpgrading, entity);
}

public Action eventRoundStart(Event event, const char[] name, bool dontBroadcast) {
	char currentMap[32];
	GetCurrentMap(currentMap, sizeof(currentMap));

	if (!cvarPluginEnabled.BoolValue) {
		return;
	}
	if (g_iLockCPs == 1) {
		LockCPs();
	}
	Hook_Func_regenerate();
	SetCvarValues();
}

public Action eventTouchCP(Event event, const char[] name, bool dontBroadcast) {
	if (!cvarPluginEnabled.BoolValue) {
		return;
	}
	int client = event.GetInt("player"), area = event.GetInt("area"), class = view_as<int>(TF2_GetPlayerClass(client)), entity;
	char g_sClass[33], playerName[64], cpName[32], s_area[32];

	if (!g_bCPTouched[client][area] || g_iRace[client] != 0) {
		Format(g_sClass, sizeof(g_sClass), "%s", GetClassname(class));
		GetClientName(client, playerName, 64);

		while ((entity = FindEntityByClassname(entity, "team_control_point")) != -1) {
			int pIndex = GetEntProp(entity, Prop_Data, "m_iPointIndex");
			if (pIndex == area) {
				bool raceComplete;

				if (g_iRaceEndPoint[g_iRace[client]] == pIndex && !IsPlayerFinishedRacing(client) && HasRaceStarted(client)) {
					raceComplete = true;
					float time, timeTaken;
					char timeString[255];
					char clientName[128];
					char buffer[128];

					time = GetEngineTime();
					g_fRaceTime[client] = time;
					timeTaken = time - g_fRaceStartTime[g_iRace[client]];
					timeString = TimeFormat(timeTaken);

					GetClientName(client, clientName, sizeof(clientName));

					if (RoundToNearest(g_fRaceFirstTime[g_iRace[client]]) == 0) {
						Format(buffer, sizeof(buffer), "%s won the race in %s!", clientName, timeString);
						g_fRaceFirstTime[g_iRace[client]] = time;
						g_iRaceStatus[g_iRace[client]] = STATUS_WAITING;

						for (int i = 0; i < MaxClients; i++) {
							if (g_iRaceFinishedPlayers[g_iRace[client]][i] == 0) {
								g_iRaceFinishedPlayers[g_iRace[client]][i] = client;
								g_fRaceTimes[g_iRace[client]][i] = time;
								break;
							}
						}
						EmitSoundToRace(client, "misc/killstreak.wav");
					}
					else {
						char diffFormatted[255];

						float firstTime = g_fRaceFirstTime[g_iRace[client]];
						float diff = time - firstTime;
						diffFormatted = TimeFormat(diff);

						for (int i = 0; i <= MaxClients; i++) {
							if (g_iRaceFinishedPlayers[g_iRace[client]][i] == 0) {
								g_iRaceFinishedPlayers[g_iRace[client]][i] = client;
								g_fRaceTimes[g_iRace[client]][i] = time;
								break;
							}
						}
						Format(buffer, sizeof(buffer), "%s finished the race in %s[-%s]!", clientName, timeString, diffFormatted);
						EmitSoundToRace(client, "misc/freeze_cam.wav");
					}
					if (RoundToZero(g_fRaceFirstTime[g_iRace[client]]) == 0) {
						g_fRaceFirstTime[g_iRace[client]] = time;
					}

					PrintToRace(g_iRace[client], buffer);

					if (GetPlayersStillRacing(g_iRace[client]) == 0) {
						PrintToRace(g_iRace[client], "Everyone has finished the race.");
						PrintToRace(g_iRace[client], "\x01Type \x03!r_list\x01 to see all times.");
						g_iRaceStatus[g_iRace[client]] = STATUS_COMPLETE;
					}
				}
				if (!g_bCPTouched[client][area] && ((RoundFloat(GetEngineTime()) - g_iLastTeleport[client]) > 5)) {
					GetEntPropString(entity, Prop_Data, "m_iszPrintName", cpName, sizeof(cpName));

					if (g_bHardcore[client]) {
						// "Hardcore" mode
						PrintToChatAll("\x01[\x03JA\x01] %t", "Player_Capped_BOSS", playerName, cpName, g_sClass, cLightGreen, cDefault, cLightGreen, cDefault, cLightGreen, cDefault);
						if (raceComplete) {
							EmitSoundToNotRace(client, "misc/tf_nemesis.wav");
						}
						else {
							EmitSoundToAll("misc/tf_nemesis.wav");
						}
					}
					else {
						// Normal mode
						PrintToChatAll("\x01[\x03JA\x01] %t", "Player_Capped", playerName, cpName, g_sClass, cLightGreen, cDefault, cLightGreen, cDefault, cLightGreen, cDefault);
						if (raceComplete) {
							EmitSoundToNotRace(client, "misc/freeze_cam.wav");
						}
						else {
							EmitSoundToAll("misc/freeze_cam.wav");
						}
					}
					if (g_iCPsTouched[client] == g_iCPs) {
						g_bBeatTheMap[client] = true;
						//PrintToChat(client, "\x01[\x03JA\x01] %t", "Goto_Avail");
					}
				}
			}
			//SaveCapData(client);
		}
		g_bCPTouched[client][area] = true; g_iCPsTouched[client]++; IntToString(area, s_area, sizeof(s_area));
		if (g_sCaps[client] != -1) {
			Format(g_sCaps[client], sizeof(g_sCaps), "%s%s", g_sCaps[client], s_area);
		}
		else { Format(g_sCaps[client], sizeof(g_sCaps), "%s", s_area);
		}
	}
}

public Action eventPlayerChangeClass(Event event, const char[] name, bool dontBroadcast) {
	if (!cvarPluginEnabled.BoolValue) {
		return;
	}
	int client = GetClientOfUserId(event.GetInt("userid"));

	if (IsClientRacing(client) && !IsPlayerFinishedRacing(client) && HasRaceStarted(client)) {
		if (g_bRaceClassForce[g_iRace[client]]) {
			TFClassType oldclass = TF2_GetPlayerClass(client);
			TF2_SetPlayerClass(client, oldclass);
			PrintToChat(client, "\x01[\x03JA\x01] Cannot change class while racing.");
			return;
		}
	}
	char g_sClass[MAX_NAME_LENGTH], steamid[32];

	EraseLocs(client);
	TF2_RespawnPlayer(client);
	g_bUnkillable[client] = false;
	GetClientAuthId(client, AuthId_Steam2, steamid, sizeof(steamid));
	int class = view_as<int>(TF2_GetPlayerClass(client));

	Format(g_sClass, sizeof(g_sClass), "%s", GetClassname(g_iMapClass));

	g_fLastSavePos[client] = NULL_VECTOR;
	g_iClientWeapons[client][0] = GetPlayerWeaponSlot(client, TFWeaponSlot_Primary);
	g_iClientWeapons[client][1] = GetPlayerWeaponSlot(client, TFWeaponSlot_Secondary);
	g_iClientWeapons[client][2] = GetPlayerWeaponSlot(client, TFWeaponSlot_Melee);

	if (g_iMapClass != -1) {
		if (class != g_iMapClass) {
			g_bHPRegen[client] = true;
			g_bAmmoRegen[client] = true;
			g_bHardcore[client] = false;
			PrintToChat(client, "\x01[\x03JA\x01] %t", "Designed_For", cLightGreen, g_sClass, cDefault);
		}
	}
}

public Action eventPlayerChangeTeam(Event event, const char[] name, bool dontBroadcast) {
	if (!cvarPluginEnabled.BoolValue) {
		return Plugin_Handled;
	}
	int client = GetClientOfUserId(event.GetInt("userid")), team = event.GetInt("team");
	if (g_iRace[client] && (g_iRaceStatus[g_iRace[client]] == STATUS_COUNTDOWN || g_iRaceStatus[g_iRace[client]] == STATUS_RACING)) {
		PrintToChat(client, "\x01[\x03JA\x01] You may not change teams during the race.");
		return Plugin_Handled;
	}
	g_bUnkillable[client] = false;

	if (team == 1 || g_iForceTeam == 1 || team == g_iForceTeam) {
		g_fOrigin[client] = NULL_VECTOR;
		g_fAngles[client] = NULL_VECTOR;
		if (g_iSpeedrunStatus[client]) {
			PrintToChat(client, "\x01[\x03JA\x01] Speedrun cancelled");
		}
		g_iSpeedrunStatus[client] = 0;
		for (int i = 0; i < 32; i++) {
			g_fZoneTimes[client][i] = 0.0;
		}
		g_iLastFrameInStartZone[client] = 0;
	}
	else {
		CreateTimer(0.1, timerTeam, client);
	}
	g_fLastSavePos[client] = NULL_VECTOR;

	return Plugin_Handled;
}

public Action eventInventoryUpdate(Event hEvent, char[] strName, bool bDontBroadcast) {
	int client = GetClientOfUserId(hEvent.GetInt("userid"));
	if (IsValidClient(client)) {
		CheckBeggers(client);
	}
	return Plugin_Continue;
}

public Action eventPlayerDeath(Event event, const char[] name, bool dontBroadcast) {
	if (!cvarPluginEnabled.BoolValue) {
		return;
	}
	int client = GetClientOfUserId(event.GetInt("userid"));
	CreateTimer(0.1, timerRespawn, client);
}

public Action eventPlayerSpawn(Event event, const char[] name, bool dontBroadcast) {
	if (!cvarPluginEnabled.BoolValue) {
		return;
	}
	int client = GetClientOfUserId(event.GetInt("userid"));

	// Check if they have the jumper equipped, and hardcore is on for some reason.
	if (IsUsingJumper(client) && g_bHardcore[client]) {
		g_bHardcore[client] = false;
	}
	// Disable func_regenerate if player is using beggers bazooka
	CheckBeggers(client);

	if (g_bUsedReset[client]) {
		if (g_hDatabase != null) {
			ReloadPlayerData(client);
		}
		g_bUsedReset[client] = false;
		return;
	}
	if (g_hDatabase != null) {
		LoadPlayerData(client);
	}
	g_bRaceSpec[client] = 0;
}
/*****************************************************************************************************************
												Timers
*****************************************************************************************************************/

Action timerTeam(Handle timer, any client) {
	if (client == 0) {
		return;
	}
	EraseLocs(client);
	if (IsClientInGame(client)) {
		ChangeClientTeam(client, g_iForceTeam);
	}
}

Action timerRegen(Handle timer, any client) {
	if (client == 0 || !IsValidEntity(client)) {
		return;
	}
	int iMaxHealth = GetEntProp(GetPlayerResourceEntity(), Prop_Send, "m_iMaxHealth", _, client);
	SetEntityHealth(client, iMaxHealth);
}

Action timerRespawn(Handle timer, any client) {
	if (IsValidClient(client)) {
		TF2_RespawnPlayer(client);
	}
}

Action WelcomePlayer(Handle timer, any client) {
	char sHostname[64];
	g_hHostname.GetString(sHostname, sizeof(sHostname));
	if (!IsClientInGame(client)) {
		return;
	}

	PrintToChat(client, "\x01[\x03JA\x01] Welcome to \x03%s\x01. This server is running \x03%s\x01 by \x03%s\x01.", sHostname, PLUGIN_NAME, PLUGIN_AUTHOR);
	PrintToChat(client, "\x01[\x03JA\x01] %t", "Welcome_2", PLUGIN_NAME, cLightGreen, cDefault, cLightGreen, cDefault);
}
/*****************************************************************************************************************
											ConVars Hooks
*****************************************************************************************************************/
public void cvarCheapObjectsChanged(ConVar convar, const char[] oldValue, const char[] newValue) {
	FindConVar("tf_cheapobjects").SetBool(view_as<bool>(StringToInt(newValue)));
}

public void cvarAmmoCheatChanged(ConVar convar, const char[] oldValue, const char[] newValue) {
	FindConVar("tf_sentrygun_ammocheat").SetBool(view_as<bool>(StringToInt(newValue)));
}

public void cvarWelcomeMsgChanged(ConVar convar, const char[] oldValue, const char[] newValue) {
	cvarWelcomeMsg.SetBool(view_as<bool>(StringToInt(newValue)));
}

public void cvarSentryLevelChanged(ConVar convar, const char[] oldValue, const char[] newValue) {
	if (0 < StringToInt(newValue) <= 3) {
		return;
	}
	else {
		convar.SetInt(1);
	}
}

public void cvarSupermanChanged(ConVar convar, const char[] oldValue, const char[] newValue) {
	cvarSuperman.SetBool(view_as<bool>(StringToInt(newValue)));
}

public void cvarSoundsChanged(ConVar convar, const char[] oldValue, const char[] newValue) {
	cvarSoundBlock.SetBool(view_as<bool>(StringToInt(newValue)));
}

public void cvarSpeedrunEnabledChanged(ConVar convar, const char[] oldValue, const char[] newValue) {
	cvarSpeedrunEnabled.SetBool(view_as<bool>(StringToInt(newValue)));
}
