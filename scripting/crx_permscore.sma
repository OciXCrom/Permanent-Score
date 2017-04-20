#include <amxmodx>
#include <amxmisc>
#include <colorchat>
#include <cstrike>
#include <fun>
#include <nvault>

#define PLUGIN_VERSION "1.1"
#define FLAG_ADMIN ADMIN_RCON
#define nvault_clear(%1) nvault_prune(%1, 0, get_systime() + 1)

new const g_szPrefix[] = "^1[^4PermScore^1]"
new g_iFrags[33], g_iDeaths[33], g_iVault

public plugin_init()
{
	register_plugin("Permanent Score", PLUGIN_VERSION, "OciXCrom")
	register_cvar("PermanentScore", PLUGIN_VERSION, FCVAR_SERVER|FCVAR_SPONLY|FCVAR_UNLOGGED)
	register_concmd("permscore_reset", "cmdReset", FLAG_ADMIN, "<nick|#userid>")
	register_concmd("permscore_resetall", "cmdResetAll", FLAG_ADMIN, "resets stats for everyone")
	register_event("DeathMsg", "eventDeath", "a") 
	register_event("ScoreInfo", "eventScoreboard", "a")
	g_iVault = nvault_open("PermanentScore")
}

public client_connect(id)
	LoadData(id)
	
public client_disconnect(id)
	SaveData(id)

public SaveData(id)
{
	new szName[32], szVaultKey[128], szVaultData[256]
	get_user_name(id, szName, charsmax(szName))
	format(szVaultKey, charsmax(szVaultKey), "%s", szName)
	format(szVaultData, charsmax(szVaultData), "%i#%i", g_iFrags[id], g_iDeaths[id])
	nvault_set(g_iVault, szVaultKey, szVaultData)
	return PLUGIN_CONTINUE
}

LoadData(id)
{
	new szName[32], szVaultKey[128], szVaultData[256]
	get_user_name(id, szName, charsmax(szName))
	format(szVaultKey, charsmax(szVaultKey), "%s", szName)
	format(szVaultData, charsmax(szVaultData), "%i#%i", g_iFrags[id], g_iDeaths[id])
	nvault_get(g_iVault, szVaultKey, szVaultData, charsmax(szVaultData))
	replace_all(szVaultData, charsmax(szVaultData), "#", " ")
	
	new szFrags[10], szDeaths[10]
	parse(szVaultData, szFrags, charsmax(szFrags), szDeaths, charsmax(szDeaths))
	g_iFrags[id] = str_to_num(szFrags)
	g_iDeaths[id] = str_to_num(szDeaths)
	return PLUGIN_CONTINUE
}

public cmdReset(id, level, cid)
{
	if(!cmd_access(id, level, cid, 2))
		return PLUGIN_HANDLED

	new szArg[32], szName[32], iPlayer
	read_argv(1, szArg, charsmax(szArg))
	get_user_name(id, szName, charsmax(szName))
	iPlayer = cmd_target(id, szArg, 4)
	if(!iPlayer) return PLUGIN_HANDLED
		
	new szName2[32]
	get_user_name(iPlayer, szName2, charsmax(szName2))
	resetStats(iPlayer)
	ColorChat(0, TEAM_COLOR, "%s ADMIN ^3%s ^1has reset ^4%s^1's stats", g_szPrefix, szName, szName2)
	client_print(id, print_console, "%s You have reset %s's stats", g_szPrefix, szName2)
	log_amx("ADMIN %s has reset %s's stats", szName, szName2)
	return PLUGIN_HANDLED
}

public cmdResetAll(id, level, cid)
{
	if(!cmd_access(id, level, cid, 1))
		return PLUGIN_HANDLED
	
	new szName[32], iPlayers[32], iPnum
	get_user_name(id, szName, charsmax(szName))
	get_players(iPlayers, iPnum)
	nvault_clear(g_iVault)
	
	for(new i = 0; i < iPnum; i++)
		resetStats(iPlayers[i])
		
	ColorChat(0, TEAM_COLOR, "%s ADMIN ^3%s ^1has reset everyone's stats", g_szPrefix, szName)
	client_print(id, print_console, "%s You have reset everyone's stats", g_szPrefix)
	log_amx("ADMIN %s reset everyone's stats", szName)
	return PLUGIN_HANDLED
}

public eventDeath()
{
	new iAttacker = read_data(1), iVictim = read_data(2)
	if(iAttacker != iVictim) g_iFrags[iAttacker]++
	g_iDeaths[iVictim]++
}

public eventScoreboard()
{
	static id
	id = read_data(1)
	set_task(0.1, "updateScoreboard", id)
}

public updateScoreboard(id)
{
	if(is_user_connected(id))
	{
		set_user_frags(id, g_iFrags[id])
		cs_set_user_deaths(id, g_iDeaths[id])
	}
}

stock resetStats(id)
{
	g_iFrags[id] = 0
	g_iDeaths[id] = 0
	SaveData(id)
	updateScoreboard(id)
}