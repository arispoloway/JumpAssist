#include <sourcemod>
#define AUTOLOAD_EXTENSIONS
#define REQUIRE_PLUGIN
#define REQUIRE_EXTENSIONS
#include <sdkhooks>
#include <smlib>

#include <tf2>
#include <tf2_stocks>
#include <morecolors>

#include <sdktools_tempents_stocks>

//#define DEBUG
#define PLUGIN_VERSION "1.1"
#define PLUGIN_NAME "JumpTracer"

public Plugin:myinfo = {
  name = PLUGIN_NAME,
  author = "happs",
  description = "Traces flight path of jumps.",
  version = PLUGIN_VERSION,
  url = "http:///"
}


static mdlindex;

enum FlightInfo
{
  Float:g_origin[3],
  Float:g_angle[3],
  Float:g_vel[3],
}

new g_Initial[MAXPLAYERS][FlightInfo];
new t_Flight[FlightInfo];
const FLIGHT_BLOCK_SIZE = sizeof(t_Flight);

enum TraceProp
{
  Float:g_timestamp,
  Handle:g_flighttimer,     // Timer used to record flight info while inflight
  Handle:g_flightHistory,   // Array for storing flight info
  Float:g_flight_time,
  bool:bInFlight,        // Is the player in flight
  bool:bThinkHook,       // ThinkHook is used to check if the player has landed
  Handle:g_subscribers,  // Array of subscribers
}

new g_Effect[MAXPLAYERS][TraceProp];

enum DisplayInfo
{
  Float:g_lifetime,
  Float:g_delaytime,
  g_max_nodes,
  bool:bDefault,
}

new g_Display[DisplayInfo];

stock OriginNearTraj(const Float:ori[3], const Float:ang[3], Float:dest[3], range = 100)
{
  new Float:temp = ang[0];
  dest[0] = (ori[0]+(range*((Cosine(DegToRad(ang[1]))) * (Cosine(DegToRad(ang[0]))))));    
  dest[1] = (ori[1]+(range*((Sine(DegToRad(ang[1]))) * (Cosine(DegToRad(ang[0]))))));      
  temp -= (2*temp);                                                                 
  dest[2] = (ori[2]+(range*(Sine(DegToRad(temp)))));                                     
}


stock TF2_GetCurrentWeaponClass(client, String:name[], maxlength)
{
  if( client > 0 )
  {
    new index = GetEntPropEnt(client, Prop_Send, "m_hActiveWeapon");
    if (index > 0)
      GetEntityNetClass(index, name, maxlength);
  }
}

stock TF2_GetHealingTarget(client)
{
  new String:classname[64];
  TF2_GetCurrentWeaponClass(client, classname, sizeof(classname));

  if(StrEqual(classname, "CWeaponMedigun"))
  {
    new index = GetEntPropEnt(client, Prop_Send, "m_hActiveWeapon");
    if( GetEntProp(index, Prop_Send, "m_bHealing") == 1 )
    {
      return GetEntPropEnt(index, Prop_Send, "m_hHealingTarget");
    }
  }
  return -1;
}



stock CacheModels()
{
  mdlindex = PrecacheModel("materials/sprites/dot.vmt");
}


RecordClientFlight(client, a_Node[FlightInfo])
{
  new Float:temp[3];
  GetClientAbsOrigin(client,temp);
  a_Node[g_origin][0] = temp[0]
  a_Node[g_origin][1] = temp[1]
  a_Node[g_origin][2] = temp[2]
  GetClientEyeAngles(client,temp);
  a_Node[g_angle][0] = temp[0]
  a_Node[g_angle][1] = temp[1]
  a_Node[g_angle][2] = temp[2]
  Entity_GetAbsVelocity(client,temp);
  a_Node[g_vel][0] = temp[0]
  a_Node[g_vel][1] = temp[1]
  a_Node[g_vel][2] = temp[2]
}


public OnClientPutInServer(client)
{
  g_Effect[client][g_flighttimer] = INVALID_HANDLE;
  g_Effect[client][g_flightHistory] = INVALID_HANDLE;
  g_Effect[client][bInFlight] = false;
  g_Effect[client][bThinkHook] = false;
  g_Effect[client][g_timestamp] = GetGameTime();
  g_Effect[client][g_subscribers] = INVALID_HANDLE;
  SDKHook(client,SDKHook_OnTakeDamage,GR_OnRocketJump);
}

SubscribeToTrace(player, viewer)
{
  if( g_Effect[player][g_subscribers] == INVALID_HANDLE )
    g_Effect[player][g_subscribers] = CreateArray()


  if(FindValueInArray(g_Effect[player][g_subscribers],viewer) == -1)
  {
    PushArrayCell(g_Effect[player][g_subscribers],viewer)
#if defined DEBUG
    decl String:pname[64]="";
    GetClientName(viewer,pname,sizeof(pname));
    PrintToConsole(player,"%s is now tracing your jumps.",pname);

    GetClientName(player,pname,sizeof(pname));
    PrintToConsole(viewer,"Now tracing %s's jumps.",pname);
#endif 
  }
    
}


UnsubscribeFromAll(client)
{
  for(new iClient=1;iClient <=MaxClients;iClient++)
  {
    new Handle:hArray = INVALID_HANDLE
    if(!IsClientInGame(iClient))
	continue;

    if((hArray = g_Effect[iClient][g_subscribers]) == INVALID_HANDLE)
	continue;

    if(GetArraySize(hArray) > 0)
    {

      new pIndex = -1;
      if( (pIndex = FindValueInArray(hArray,client)) != -1)
      {
        RemoveFromArray(hArray,pIndex)
      }
    }
  }
}

public OnCientDisconnect(client)
{
  ClearFlightInfo(client);
  SDKUnhook(client,SDKHook_OnTakeDamagePost,GR_OnRocketJump);

  if( g_Effect[client][g_subscribers] != INVALID_HANDLE)
  {
    CloseHandle(g_Effect[client][g_subscribers])
    g_Effect[client][g_subscribers] = INVALID_HANDLE;
  }

  UnsubscribeFromAll(client)
}

public OnPluginStart()
{
  LoadTranslations("common.phrases")
  HookEvent("rocket_jump",event_jump);
  HookEvent("sticky_jump",event_jump);
  HookEvent("rocket_jump_landed",event_jump_end);
  HookEvent("sticky_jump_landed",event_jump_end);
  HookEvent("player_death",event_death);
  HookEvent("teamplay_round_win",event_round_win);

#if defined DEBUG
  RegAdminCmd("sm_sprite", OnChangeSpriteCmd,ADMFLAG_CONFIG,"Changes the sprite used to display tracker.");
#endif
  RegConsoleCmd("trace", OnTraceCmd, "Trace a player who has performed an explosive jump.");
  RegConsoleCmd("untrace", OnStopTraceCmd, "Stop tracing a player's explosive jumps.  With no arguements, stop tracing all players.");

  CreateConVar("jump_tracer_version", PLUGIN_VERSION, PLUGIN_NAME, FCVAR_SPONLY|FCVAR_REPLICATED|FCVAR_NOTIFY);

  new Handle:hCvar = CreateConVar("jump_tracer_lifetime","15.0","lifetime of temp entities",FCVAR_SPONLY|FCVAR_REPLICATED|FCVAR_NOTIFY,true,2.0,true,600.0);
  HookConVarChange(hCvar,CVarChanged);
  g_Display[g_lifetime] = GetConVarFloat(hCvar);


  hCvar = CreateConVar("jump_tracer_interval","0.01","interval of position polling",FCVAR_SPONLY|FCVAR_REPLICATED|FCVAR_NOTIFY,true,0.01,true,10.0);
  HookConVarChange(hCvar,CVarChanged);

  g_Display[g_delaytime] = GetConVarFloat(hCvar);
  hCvar = CreateConVar("jump_tracer_max","50","maximum number of positions to track",FCVAR_SPONLY|FCVAR_REPLICATED|FCVAR_NOTIFY,true,4.0,true,256.0);
  HookConVarChange(hCvar,CVarChanged);
  g_Display[g_max_nodes] = GetConVarInt(hCvar);

}

public APLRes:AskPluginLoad2(Handle:myself, bool:late, String:error[], err_max) { 
    MarkNativeAsOptional("GetUserMessageType"); 
    return APLRes_Success; 
}  

public CVarChanged(Handle:cvar, const String:oldValue[], const String:newValue[])
{
  decl String:s_cvar[32]="";
  GetConVarName(cvar,s_cvar,sizeof(s_cvar));

  if(StrEqual(s_cvar,"jump_tracer_lifetime")) {
    new Float:value;
    if(StringToFloatEx(newValue,value) > 0)
    {
      g_Display[g_lifetime] = value;
      return;
    }
    
  } else if(StrEqual(s_cvar,"jump_tracer_interval")) {
    new Float:value;
    if(StringToFloatEx(newValue,value) > 0)
    {
      g_Display[g_delaytime] = value;
      return;
    }
  } else if(StrEqual(s_cvar,"jump_tracer_max")) {
    new value;
    if(StringToIntEx(newValue,value) > 0)
    {
      g_Display[g_max_nodes] = value
      return;
    }
  } else {
    LogError("Unknown cvar %s", s_cvar);
    return;
  }

  LogError("Invalid cvar %s value %s", s_cvar,newValue);
}



public OnMapStart()
{

  CacheModels()
/*
  new Handle:gameConfig = LoadGameConfigFile("jumptracer.games");
  if(gameConfig == null)
  {
    LogMessage("Unable to load game config jumptracer.games");
    return;
  }

  new String:buffer[PLATFORM_MAX_PATH];
  if (GameConfGetKeyValue(gameConfig, "SpriteTracer", buffer, sizeof(buffer)) && buffer[0])
  {
    // mdlindex = PrecacheModel(buffer)
  }

  delete gameConfig;
*/
}


stock ClearFlightInfo(client)
{
  if(g_Initial[client][bThinkHook])
  {
    SDKUnhook(client,SDKHook_PostThink,OnPostThinkAir);
    g_Initial[client][bThinkHook] = false;
  }
  if( g_Effect[client][g_flighttimer] != INVALID_HANDLE )
  {
    KillTimer( g_Effect[client][g_flighttimer]);
  }

  g_Effect[client][bInFlight] = false;

  if( g_Effect[client][g_flightHistory] != INVALID_HANDLE)
  {
    CloseHandle(g_Effect[client][g_flightHistory])
    g_Effect[client][g_flightHistory] = INVALID_HANDLE;
  }

}

public event_round_win(Handle:event, const String:name[], bool:dontBroadcast)
{
  new iClient;
  for(iClient = 1; iClient <= GetMaxClients();++iClient)
  {
    if(IsValidEntity(iClient))
    {
      ClearFlightInfo(iClient);
    }
  }
}


public event_death(Handle:event, const String:name[], bool:dontBroadcast)
{
  new client = GetClientOfUserId(GetEventInt(event, "userid"));
  ClearFlightInfo(client);
}

public event_jump(Handle:event, const String:name[], bool:dontBroadcast)
{
  new client = GetClientOfUserId(GetEventInt(event, "userid"));
#if defined DEBUG
  decl String:ename[24]="";
  decl String:pname[64]="";
#endif

  if (client > 0  && IsPlayerAlive(client) && !IsClientObserver(client) )
  {
#if defined DEBUG
    GetEventName(event,ename,sizeof(ename));
    GetClientName(client,pname,sizeof(pname));
#endif

    if(!g_Effect[client][bInFlight])
    {
      RecordClientFlight(client, g_Initial[client]);
      g_Effect[client][g_flighttimer] = CreateTimer(g_Display[g_delaytime], TimerRecordFlight, client, TIMER_REPEAT | TIMER_FLAG_NO_MAPCHANGE);
      g_Effect[client][g_flight_time] = GetGameTime();
      g_Effect[client][bInFlight] = true;
    }


    //new bool:bMedicFollow = false;
    for(new iClient = 1;iClient <= GetMaxClients();++iClient)
    {
      if(IsValidEntity(iClient) && IsPlayerAlive(iClient) && !IsClientObserver(iClient) && 
        TF2_GetPlayerClass(iClient) == TFClass_Medic && TF2_GetHealingTarget(iClient) == client)
      {
        //new entityIndex = GetPlayerWeaponSlot(client, 1);
        // Need to make sure entityIndex has the item index for quickfix
        if(!g_Effect[iClient][bInFlight])
        {
          if(GetEntPropEnt(iClient,Prop_Send,"m_hGroundEntity") == -1)
          {
            g_Effect[iClient][g_flighttimer] = CreateTimer(g_Display[g_delaytime], TimerRecordFlight, iClient, TIMER_REPEAT | TIMER_FLAG_NO_MAPCHANGE);
            g_Effect[iClient][g_flight_time] = GetGameTime();
            SDKHook(iClient,SDKHook_PostThink,OnPostThinkAir);
            g_Effect[iClient][bThinkHook] = true;
#if defined DEBUG
            PrintToConsole(iClient,"medic qf jump");
#endif
          } else { // not in air
            CreateTimer(0.01, DelayedTimerRecordFlight, iClient, TIMER_FLAG_NO_MAPCHANGE);
          }
          g_Effect[iClient][bInFlight] = true;
        }
        
      }
    }

#if defined DEBUG
    CPrintToChatAll("{olive} %s %s", pname, ename);
#endif

  }
}

public event_jump_end(Handle:event, const String:name[], bool:dontBroadcast)
{
  new client = GetClientOfUserId(GetEventInt(event, "userid"));
#if defined DEBUG
  decl String:ename[24]="";
  decl String:pname[64]="";
#endif

  if (client > 0  && IsPlayerAlive(client) && !IsClientObserver(client) )
  {
#if defined DEBUG
    GetEventName(event,ename,sizeof(ename));
    GetClientName(client,pname,sizeof(pname));
#endif

    g_Effect[client][bInFlight] = false;
    if( g_Effect[client][g_flighttimer] != INVALID_HANDLE)
    {
      TriggerTimer( g_Effect[client][g_flighttimer]);
    }
  
    for(new iClient = 1;iClient <= GetMaxClients();++iClient)
    {
      if(IsValidEntity(iClient) && IsPlayerAlive(iClient) && !IsClientObserver(iClient) && 
        TF2_GetPlayerClass(iClient) == TFClass_Medic && TF2_GetHealingTarget(iClient) == client)
      {
        //new entityIndex = GetPlayerWeaponSlot(client, 1);
        // Need to make sure entityIndex has the item index for quickfix
      }
    }

#if defined DEBUG
    CPrintToChatAll("{olive} %s %s", pname, ename)
#endif
  }
}


public Action:DelayedTimerRecordFlight(Handle:timer, any:client)
{

  if(!IsValidEntity(client) || !IsPlayerAlive(client) || IsClientObserver(client) || GetEntPropEnt(client,Prop_Send,"m_hGroundEntity") != -1)
  {
    g_Effect[client][bInFlight] = false;
    return Plugin_Handled;
  }  

  if(g_Effect[client][bInFlight])
  {
    g_Effect[client][g_flighttimer] = CreateTimer(g_Display[g_delaytime], TimerRecordFlight, client, TIMER_REPEAT | TIMER_FLAG_NO_MAPCHANGE);
    g_Effect[client][g_flight_time] = GetGameTime();
  }

  if(!g_Effect[client][bThinkHook])
  {
    SDKHook(client,SDKHook_PostThink,OnPostThinkAir);
    g_Effect[client][bThinkHook] = true;
  }

  
  return Plugin_Handled;
}

public OnPostThinkAir(client)
{
  if(!IsValidEntity(client) || !IsPlayerAlive(client) || IsClientObserver(client) || GetEntPropEnt(client, Prop_Send, "m_hGroundEntity") != -1)
  {
    g_Effect[client][bInFlight] = false;
    g_Effect[client][bThinkHook] = false;
    if( g_Effect[client][g_flighttimer] != INVALID_HANDLE)
    {
      TriggerTimer( g_Effect[client][g_flighttimer]);
    }
    SDKUnhook(client,SDKHook_PostThink,OnPostThinkAir);
#if defined DEBUG
    PrintToConsole(client, "medic landed; unhook %f -> %f",g_Effect[client][g_flight_time],GetGameTime());
#endif
  
  }

}
  
public OnPluginEnd()
{
}

public Action:OnTraceCmd(int client, int args)
{
  if( args < 1 )
  {
    ReplyToCommand(client, "Usage: trace <#userid|name|self>");
    return Plugin_Handled;
  }

  char arg[65];
  GetCmdArg(1,arg,sizeof(arg))


  if(strcmp(arg,"self",false) == 0)
  {
    SubscribeToTrace(client,client)
    return Plugin_Handled;
  }


  char target_name[MAX_TARGET_LENGTH];
  int target_list[MAXPLAYERS], target_count;
  bool tn_is_ml;

  if((target_count = ProcessTargetString(
    arg,
    client,
    target_list,
    MAXPLAYERS,
    COMMAND_FILTER_NO_IMMUNITY, /* flags */
    target_name,
    sizeof(target_name),
    tn_is_ml)) <= 0)
  {
    ReplyToTargetError(client,target_count)
    return Plugin_Handled;
  }

#if defined DEBUG
    PrintToServer("targetname: %s",target_name);
#endif

 
  for (new i = 0;i < target_count;i++)
  {
    SubscribeToTrace(target_list[i],client)
  }
  return Plugin_Handled;
}

public Action:OnStopTraceCmd(int client, int args)
{
  UnsubscribeFromAll(client);
  return Plugin_Handled;
}


public Action:GR_OnRocketJump(victim, &attacker, &inflictor, &Float:damage, &damagetype, &weapon, const Float:damageForce[3], const Float:damagePosition[3])
{

  if(victim != attacker)
    return Plugin_Continue;

  if(!g_Effect[victim][bInFlight])
  {
    RecordClientFlight(victim, g_Initial[victim]);
  }

  new iClient;
  new TFTeam:vTeam = TFTeam:GetClientTeam(victim)
  for(iClient = 1; iClient <= GetMaxClients();++iClient)
  {
    if(iClient == victim)
      continue;

    if(!IsValidEntity(iClient) || 
      !IsClientInGame(iClient) ||
      !IsPlayerAlive(iClient) ||
      IsClientObserver(iClient))
      continue;

    if(TFTeam:GetClientTeam(iClient) != vTeam
      || TF2_GetPlayerClass(iClient) != TFClass_Medic
         || TF2_GetHealingTarget(iClient) != victim)
      continue;

  //  new med_wpn = GetPlayerWeaponSlot(iClient,1);
    if(!g_Effect[iClient][bInFlight])
      RecordClientFlight(iClient, g_Initial[iClient]);
  }

  return Plugin_Continue;
}
  
  

public Action:TimerRecordFlight(Handle:timer, any:client)
{
  new a_Node[FlightInfo];

  if(!IsValidEntity(client || !IsPlayerAlive(client) || IsClientObserver(client)))
  {
    g_Effect[client][g_flighttimer] = INVALID_HANDLE;
    return Plugin_Stop;
  }
  
  new Handle:pArray;

  if( (pArray = g_Effect[client][g_flightHistory]) == INVALID_HANDLE)
  {
    g_Effect[client][g_flightHistory] = CreateArray(FLIGHT_BLOCK_SIZE);
    pArray = g_Effect[client][g_flightHistory];
  }

  RecordClientFlight(client, a_Node);
  PushArrayArray(pArray, a_Node[0], FLIGHT_BLOCK_SIZE);

  if( GetArraySize(pArray) > g_Display[g_max_nodes]  || !g_Effect[client][bInFlight] )
  {
    DisplayFlightHistory(client);
    g_Effect[client][g_flighttimer] = INVALID_HANDLE;
    return Plugin_Stop;
  }

  return Plugin_Continue;
}



DisplayFlightHistory(client)
{
  new Handle:harray = g_Effect[client][g_flightHistory];
  if(harray == INVALID_HANDLE)
  {
    LogMessage("Invalid flight history array.");
    return;
  }

  new size;

  if((size = GetArraySize(harray)) <= 1)
  {
    LogMessage("No histroy to report.");  
    return;
  }

#if defined DEBUG
  PrintToConsole(client,"flight time %f to %f", g_Effect[client][g_flight_time], GetGameTime())

#endif

  new s_Node[FlightInfo];
  new d_Node[FlightInfo];
  
  new idx;
  TE_PlayerFlightStart(client);

  for(idx = 0;idx + 1< size;++idx)
  {
    GetArrayArray(harray,idx,s_Node[0],FLIGHT_BLOCK_SIZE);
    GetArrayArray(harray,idx + 1,d_Node[0],FLIGHT_BLOCK_SIZE);

#if defined DEBUG
    PrintToConsole(client,"%.2f %.2f %.2f -> %.2f %.2f %.2f",
      s_Node[g_origin][0],
      s_Node[g_origin][1],
      s_Node[g_origin][2],
      d_Node[g_origin][0],
      d_Node[g_origin][1],
      d_Node[g_origin][2]);
#endif

    TE_PlayerFlightPath(client,s_Node,d_Node);
  }

  CloseHandle(g_Effect[client][g_flightHistory])
  g_Effect[client][g_flightHistory] = INVALID_HANDLE;
}


stock TE_SendToSubscribed(client,Float:delay=0.1)
{
  new Handle:hArray = INVALID_HANDLE;
  if( (hArray = g_Effect[client][g_subscribers]) != INVALID_HANDLE)
  {
    new total = GetArraySize(hArray);
    new clients[MaxClients];
    for(new i=0;i<total;i++)
    {
      clients[i] = GetArrayCell(hArray,i)
    }
    TE_Send(clients,total,delay)
  } 
}


stock TE_PlayerFlightPath(client, Source[FlightInfo], Dest[FlightInfo])
{
  new colour[4];
  colour[0] = 0;
  colour[1] = 255;
  colour[2] = 0;
  colour[3] = 255;

  new Float:s_ori[3];
  s_ori[0] = Source[g_origin][0]
  s_ori[1] = Source[g_origin][1]
  s_ori[2] = Source[g_origin][2]
  new Float:d_ori[3];
  d_ori[0] = Dest[g_origin][0]
  d_ori[1] = Dest[g_origin][1]
  d_ori[2] = Dest[g_origin][2]

  TE_SetupBeamPoints(s_ori, d_ori, mdlindex, 0, 0, 0, g_Display[g_lifetime], 3.0, 3.0, 0, 0.0, colour, 0);
  TE_SendToSubscribed(client,0.1);
//  TE_SendToAll(0.1);
}

stock TE_PlayerFlightStart(client)
{
  new colour[4];
  colour[0] = 0;
  colour[1] = 0;
  colour[2] = 255;
  colour[3] = 255;

  new Float:s_ori[3];
  s_ori[0] = g_Initial[client][g_origin][0];
  s_ori[1] = g_Initial[client][g_origin][1];
  s_ori[2] = g_Initial[client][g_origin][2];

  new Float:s_ang[3];
  s_ang[0] = g_Initial[client][g_angle][0];
  s_ang[1] = g_Initial[client][g_angle][1];
  s_ang[2] = g_Initial[client][g_angle][2];


  new Float:d_ori[3];
  OriginNearTraj(s_ori,s_ang,d_ori,45);

  TE_SetupBeamPoints(s_ori, d_ori, mdlindex, 0, 0, 0, g_Display[g_lifetime], 7.5, 7.5, 0, 0.0, colour, 0);
  TE_SendToSubscribed(client,0.1);
//  TE_SendToAll(0.1);
}


#if defined DEBUG
public Action:OnChangeSpriteCmd(client, args)
{
  new String:buffer[80]="";
  GetCmdArgString(buffer,sizeof(buffer));
  
  new t_idx;
  if(buffer[0] == '\0')
    return Plugin_Handled;

  
  if((t_idx = PrecacheModel(buffer)) <= 0)
  {
    ReplyToCommand(client,"Invalid model %s", buffer);
    return Plugin_Handled;
  }

  mdlindex = t_idx;
  return Plugin_Handled;
}
#endif
