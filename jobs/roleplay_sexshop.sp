/*
 * Cette oeuvre, création, site ou texte est sous licence Creative Commons Attribution
 * - Pas d’Utilisation Commerciale
 * - Partage dans les Mêmes Conditions 4.0 International. 
 * Pour accéder à une copie de cette licence, merci de vous rendre à l'adresse suivante
 * http://creativecommons.org/licenses/by-nc-sa/4.0/ .
 *
 * Merci de respecter le travail fourni par le ou les auteurs 
 * https://www.ts-x.eu/ - kossolax@ts-x.eu
 */
#pragma semicolon 1

#include <sourcemod>
#include <sdkhooks>
#include <colors_csgo>	// https://forums.alliedmods.net/showthread.php?p=2205447#post2205447
#include <smlib>		// https://github.com/bcserv/smlib

#define __LAST_REV__ 		"v:0.2.0"

#pragma newdecls required
#include <roleplay.inc>	// https://www.ts-x.eu

//#define DEBUG
#define MAX_AREA_DIST		500.0

public Plugin myinfo = {
	name = "Jobs: Sexshop", author = "KoSSoLaX",
	description = "RolePlay - Jobs: Sexshop",
	version = __LAST_REV__, url = "https://www.ts-x.eu"
};

int g_cBeam, g_cGlow, g_cExplode;
// ----------------------------------------------------------------------------
public void OnPluginStart() {
	RegServerCmd("rp_item_preserv",		Cmd_ItemPreserv,		"RP-ITEM",	FCVAR_UNREGISTERED);
	RegServerCmd("rp_item_poupee",		Cmd_ItemPoupee,			"RP-ITEM",	FCVAR_UNREGISTERED);
	RegServerCmd("rp_item_menottes",	Cmd_ItemMenottes,		"RP-ITEM",	FCVAR_UNREGISTERED);
	RegServerCmd("rp_item_sucette",		Cmd_ItemSucette,		"RP-ITEM",	FCVAR_UNREGISTERED);
	RegServerCmd("rp_item_sucetteduo",	Cmd_ItemSucette2,		"RP-ITEM",	FCVAR_UNREGISTERED);
	RegServerCmd("rp_item_fouet",		Cmd_ItemFouet,			"RP-ITEM",	FCVAR_UNREGISTERED);
	RegServerCmd("rp_item_alcool",		Cmd_ItemAlcool,			"RP-ITEM",	FCVAR_UNREGISTERED);
}
public void OnMapStart() {
	g_cBeam = PrecacheModel("materials/sprites/laserbeam.vmt", true);
	g_cGlow = PrecacheModel("materials/sprites/glow01.vmt", true);
	g_cExplode = PrecacheModel("materials/sprites/muzzleflash4.vmt", true);
}
// ----------------------------------------------------------------------------
public Action Cmd_ItemPreserv(int args) {
	#if defined DEBUG
	PrintToServer("Cmd_ItemPreserv");
	#endif
	int client = GetCmdArgInt(1);
	int item_id = GetCmdArgInt(args);
	
	int kevlar = rp_GetClientInt(client, i_Kevlar);
	if( kevlar >= 250 ) {
		ITEM_CANCEL(client, item_id);
		return Plugin_Handled;
	}
	
	kevlar += 5;
	if( kevlar > 250 )
		kevlar = 250;
	
	rp_SetClientInt(client, i_Kevlar, kevlar);
	return Plugin_Handled;
}
public Action fwdInvincible(int client, int attacker, float& damage) {
	damage = 0.0;
	return Plugin_Stop;
}
public Action fwdFrozen(int client, float& speed, float& gravity) {
	speed = 0.0;
	return Plugin_Stop;
}
public Action fwdSlowTime(int client, float& speed, float& gravity) {
	speed -= 5.0;
	return Plugin_Changed;
}
public Action Cmd_ItemPoupee(int args) {
	#if defined DEBUG
	PrintToServer("Cmd_ItemPoupee");
	#endif
	
	int client = GetCmdArgInt(1);
	int item_id = GetCmdArgInt(args);
	
	if( !rp_GetClientBool(client, b_MaySteal) ) {
		ITEM_CANCEL(client, item_id);
		CPrintToChat(client, "{lightblue}[TSX-RP]{default} Vous ne pouvez pas utiliser cet item pour le moment.");
		return Plugin_Handled;
	}
	
	rp_HookEvent(client, RP_PreTakeDamage, fwdInvincible, 5.0);
	rp_HookEvent(client, RP_PrePlayerPhysic, fwdFrozen, 5.0);
	rp_SetClientFloat(client, fl_Invincible, GetGameTime() + 5.0);
	
	int heal = GetClientHealth(client) + 100;
	int kevlar = rp_GetClientInt(client, i_Kevlar) + 25;
	
	if( kevlar > 250 )
		kevlar = 250;
	if( heal > 500 )
		heal = 500;
		
	SetEntityHealth(client, heal);
	rp_SetClientInt(client, i_Kevlar, kevlar);	
	
	float vecTarget[3];
	GetClientAbsOrigin(client, vecTarget);
	vecTarget[2] += 10.0;
	
	TE_SetupBeamRingPoint(vecTarget, 30.0, 40.0, g_cBeam, g_cGlow, 0, 0, 5.0, 80.0, 0.0, {250, 250, 50, 250}, 0, 0);
	TE_SendToAll();
	
	rp_SetClientBool(client, b_MaySteal, false);
	
	CreateTimer(30.0, AllowStealing, client);	
	return Plugin_Handled;
}
public Action AllowStealing(Handle timer, any client) {
	#if defined DEBUG
	PrintToServer("AllowStealing");
	#endif
	
	rp_SetClientBool(client, b_MaySteal, true);
}
public Action fwdTazerRose(int client, int color[4]) {
	#if defined DEBUG
	PrintToServer("fwdTazerRose");
	#endif
	color[0] += 255;
	color[1] -= 50;
	color[2] += 50;
	color[3] += 50;
	return Plugin_Changed;
}
public Action Cmd_ItemMenottes(int args){
	#if defined DEBUG
	PrintToServer("Cmd_ItemMenottes");
	#endif
	
	int client = GetCmdArgInt(1);
	int item_id = GetCmdArgInt(args);
	
	if( rp_GetZoneBit( rp_GetPlayerZone(client) ) & BITZONE_PEACEFULL ) {
		ITEM_CANCEL(client, item_id);
		CPrintToChat(client, "{lightblue}[TSX-RP]{default} Cet objet est interdit où vous êtes.");
		return;
	}
	if(rp_GetClientJobID(client) == 1 || rp_GetClientJobID(client) == 101){
		CPrintToChat(client, "{lightblue}[TSX-RP]{default} Cet objet est interdit aux forces de l'ordre.");
		ITEM_CANCEL(client, item_id);
		return;
	}
	
	int target = GetClientTarget(client);
	if( !IsValidClient(target) || !rp_IsTutorialOver(target) ) {
		ITEM_CANCEL(client, item_id);
		return;
	}
	if( rp_GetZoneBit( rp_GetPlayerZone(target) ) & BITZONE_PEACEFULL ) {
		ITEM_CANCEL(client, item_id);
		return;
	}
	
	
	rp_IncrementSuccess(client, success_list_menotte);
	rp_Effect_Tazer(client, target);
	rp_ClientColorize(target, { 255, 175, 200, 255 } );
	
	rp_HookEvent(target, RP_PrePlayerPhysic, fwdFrozen, 5.0);
	rp_HookEvent(target, RP_PreHUDColorize, fwdTazerRose, 5.0);
	
	CreateTimer(5.0, Cmd_ItemMenottes_Over, target); // TODO: Laisser rose après 5 secondes.
}
public Action Cmd_ItemMenottes_Over(Handle timer, any client) {
	#if defined DEBUG
	PrintToServer("Cmd_ItemMenottes_Over");
	#endif
	
	rp_ClientColorize(client);
}
public Action Cmd_ItemSucette(int args) {
	#if defined DEBUG
	PrintToServer("Cmd_ItemSucette");
	#endif
	
	int client = GetCmdArgInt(1);
	if( Client_IsInVehicle(client) || rp_GetClientVehiclePassager(client) ) {
		CPrintToChat(client, "{lightblue}[TSX-RP]{default} Impossible d'utiliser cet item dans une voiture.");
		int item_id = GetCmdArgInt(args);
		ITEM_CANCEL(client, item_id);
		return Plugin_Handled;
	}
	
	
	float Origin[3];	
	GetClientAbsOrigin(client, Origin);
	
	TE_SetupExplosion(Origin, g_cExplode, GetRandomFloat(0.5, 2.0), 2, 1, Math_GetRandomInt(25, 100) , Math_GetRandomInt(25, 100) );
	TE_SendToAll();
	
	SDKHooks_TakeDamage(client, client, client, 5000.0);
	return Plugin_Handled;
}
public Action Cmd_ItemSucette2(int args) {
	#if defined DEBUG
	PrintToServer("Cmd_ItemSucette2");
	#endif
	
	int client = GetCmdArgInt(1);
	
	if( Client_IsInVehicle(client) || rp_GetClientVehiclePassager(client) ) {
		CPrintToChat(client, "{lightblue}[TSX-RP]{default} Impossible d'utiliser cet item dans une voiture.");
		int item_id = GetCmdArgInt(args);
		ITEM_CANCEL(client, item_id);
		return Plugin_Handled;
	}
	
	float duration = 1.0;
	if( rp_IsInPVP(client) ) {
		rp_SetClientFloat(client, fl_CoolDown, rp_GetClientFloat(client, fl_CoolDown) + 15.0);
		duration += 0.66;
	}
	
	EmitSoundToAll("UI/arm_bomb.wav", client);
	
	CreateTimer((duration / 4.0) * 1.0, Beep, client);
	CreateTimer((duration / 4.0) * 2.0, Beep, client);
	CreateTimer((duration / 4.0) * 3.0, Beep, client);
	CreateTimer(duration, 				Cmd_ItemSucette2_task, client);
	
	return Plugin_Handled;
}
public Action Beep(Handle timer, any client) {
	#if defined DEBUG
	PrintToServer("Beep");
	#endif
	
	EmitSoundToAll("UI/arm_bomb.wav", client);
}
public Action Cmd_ItemSucette2_task(Handle timer, any client) {
	#if defined DEBUG
	PrintToServer("Cmd_ItemSucette2_task");
	#endif
	
	if( !IsValidClient(client) )
		return Plugin_Handled;
	if( !IsPlayerAlive(client) )
		return Plugin_Handled;
	
	int lenght = (GetClientHealth(client)*2);
	
	if( lenght > 1000 )
		lenght = 1000;
	
	if( rp_IsInPVP(client) )
		lenght = RoundToFloor(float(lenght) / 2.0);
	
	float Origin[3];
	GetClientAbsOrigin(client, Origin);
	TE_SetupExplosion(Origin, g_cExplode, GetRandomFloat(0.5, 2.0), 2, 1, Math_GetRandomInt(25, 100) , Math_GetRandomInt(25, 100) );
	TE_SendToAll();
	
	int amount = rp_Effect_Explode(Origin, float(lenght)*2.0, float(lenght), client, "weapon_sucetteduo");
	rp_Effect_Push(Origin, float(lenght), float(lenght));
	
	SDKHooks_TakeDamage(client, client, client, 5000.0);
	
	if( amount >= 10 )
		rp_IncrementSuccess(client, success_list_sexshop, 10);
	
	return Plugin_Handled;
}


public Action Cmd_ItemFouet(int args) {
	#if defined DEBUG
	PrintToServer("Cmd_ItemFouet");
	#endif
	
	int client = GetCmdArgInt(1);
	int item_id = GetCmdArgInt(args);
	int target = GetClientTarget(client);
	
	if( !IsValidClient(target) ) {
		ITEM_CANCEL(client, item_id);
		return Plugin_Handled;
	}
	if( Entity_GetDistance(client, target) > MAX_AREA_DIST ) {
		ITEM_CANCEL(client, item_id);
		return Plugin_Handled;
	}
	if( !rp_IsTutorialOver(target) ) {
		ITEM_CANCEL(client, item_id);
		return Plugin_Handled;
	}
	if( rp_GetZoneBit( rp_GetPlayerZone(target) ) & BITZONE_PEACEFULL ) {
		ITEM_CANCEL(client, item_id);
		return Plugin_Handled;
	}
	
	rp_Effect_Tazer(client, target);
	rp_ClientDamage(target, rp_GetClientInt(client, i_KnifeTrain), client);
	
	SlapPlayer(target, 0, true);
	SlapPlayer(target, 0, true);
	EmitSoundToAll("tsx/roleplay/fouet.mp3", target);

	
	rp_HookEvent(target, RP_PreHUDColorize, fwdSlowTime, 5.0);
	
	return Plugin_Handled;
}
public Action Cmd_ItemAlcool(int args) {
	#if defined DEBUG
	PrintToServer("Cmd_ItemAlcool");
	#endif
	
	int client = GetCmdArgInt(2);
	float level = rp_GetClientFloat(client, fl_Alcool) + GetCmdArgFloat(1);
	
	rp_SetClientFloat(client, fl_Alcool, level);
	rp_IncrementSuccess(client, success_list_alcool_abuse);
	
	if( level > 6.0 ) {
		SDKHooks_TakeDamage(client, client, client, (25 + GetClientHealth(client))/2.0);
	}
}
