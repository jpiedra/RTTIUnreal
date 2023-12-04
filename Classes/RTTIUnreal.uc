class RTTIUnreal expands Mutator config(RTTIUnreal);

var() config int MaxAttempts;

var RTTIServer rttiServer;
var RTTIActQueue rttiActQueue;
var NavigationPoint spawnPointCandidates[32];
var int spawnPoints;

// Gameloop and timer
function PreBeginPlay() {
	Super.PreBeginPlay();
	Level.Game.bHumansOnly = false;
	Level.Game.bNoMonsters = false;
	SetTimer(5, True);

	// write the config file
	SaveConfig();
}

function PostBeginPlay() {
	local NavigationPoint N;

	spawnPoints = 0;
	
	Super.PostBeginPlay();
	rttiActQueue = Spawn(class'RTTIUnreal.RTTIActQueue', Self);
	rttiServer = Spawn(class'RTTIUnreal.RTTIServer', Self);

    if (rttiActQueue != None && rttiServer != None) {
		log('[RTTIUnreal] Successfully spawned Server and ActQueue instances');
	}
	
	for (N=Level.NavigationPointList; N!=None; N=N.NextNavigationPoint) {
		if(N!=None && !N.Region.Zone.bWaterZone) {
			if (spawnPoints<32) spawnPointCandidates[spawnPoints] = N;
			else if (Rand(spawnPoints) < 32) spawnPointCandidates[Rand(32)] = N;
			spawnPoints++;
		}
	}

	bAlwaysRelevant = true;
	if(Level.Netmode == NM_DedicatedServer)
		return;
}

function Timer() {
	HandleAct();
}

// Methods for handling actions, or 'acts'
function HandleAct() {
	local int actNum;
	local string actString;

	local string actName,actOwner,actArgs;

	actNum = 0;
	actString = "";

	actNum = rttiActQueue.GetQueueSize();
	if (actNum != 0) {
		actString = rttiActQueue.PopAct();

		actOwner = ParseDelimited(actString,"?",1);
		actName = ParseDelimited(actString,"?",2);
		actArgs = ParseDelimited(actString,"?",3);

		log("[RTTIUnreal] Handling act '"$actName$"' started by '"$actOwner$"' (args: '"$actArgs$"')");
		RunAct(actOwner, actName, actArgs);
		// BroadcastMessage(actString, true, 'CriticalEvent');
	}
}

function RunAct(string actOwner, string actName, string actArgs) {
	local bool isActSuccessful;
	
	log("[RTTIUnreal] Running act '"$actName$"' started by '"$actOwner$"' (args: '"$actArgs$"')");
	
	// running list of available actions that can be initiated
	switch( actName )
	{
		case "spawn_monster":		
			isActSuccessful = (SpawnMonster(actOwner, actArgs));
			break;
		case "spawn_item":
			isActSuccessful = (SpawnItem(actOwner, actArgs));
			break;
		default:
			log("[RTTIUnreal] No act named '"$actName$"' exists!");
			break;
	}

	if (isActSuccessful) {
		log("[RTTIUnreal] Successfully ran act '"$actName$"' started by '"$actOwner$"' (args: '"$actArgs$"')");
	} else {
		log("[RTTIUnreal] Failed to run act '"$actName$"' started by '"$actOwner$"' (args: '"$actArgs$"')");
	}
}

// Actions
function bool SpawnMonster(string actOwner, string actArgs) {
	local int i;
	local ScriptedPawn NewMonster;
	local PawnTeleportEffect SpawnEffect;
	local bool isMonsterSpawned;
	local vector SpawnPoint;
	local class<ScriptedPawn> MonsterClass;

	isMonsterSpawned = false;

	MonsterClass = class<ScriptedPawn>(DynamicLoadObject(actArgs,class'Class'));
	if (MonsterClass == None) {
		Log("[RTTIUnreal] Invalid class: '"$actArgs$"'!");
		return isMonsterSpawned;
	}

	for (i = 0; i < MaxAttempts; i++) {	
		log("[RTTIUnreal] Trying to spawn "$MonsterClass$ " - attempt "$i+1$" (max attempts: "$MaxAttempts$")");
		SpawnPoint = GetSpawnPoint();
		NewMonster = Spawn(MonsterClass,self,,SpawnPoint);
		if (NewMonster != None) {
			Log("[RTTIUnreal] Successfully spawned for '"$actOwner$"' - '"$actArgs$"'!");
			isMonsterSpawned = true;
			// try to spawn special effect
			SpawnEffect = Spawn(class'UnrealShare.PawnTeleportEffect');
			NewMonster.NameArticle = actOwner$"'s"$" ";
			NewMonster.GotoState('Wandering');
			break;			
		}
	}

	return isMonsterSpawned;
}

function bool SpawnItem(string actOwner, string actArgs) {
	local class<Inventory> InventoryClass;
	local Inventory NewInventory;
	local Pawn randomPlayer;
	local bool isItemSpawned;
	local bool bActivate;

	isItemSpawned = false;
	bActivate = false;
	
	randomPlayer = GetRandomPlayer();
	log("[RTTIUnreal] Trying to find random player for act 'spawn_item'...");
	if (randomPlayer != None) {
		log("[RTTIUnreal] Found player "$randomPlayer.GetHumanName()$", trying to load Inventory class of type '"$actArgs$"'");
		InventoryClass = class<Inventory>(DynamicLoadObject(actArgs,class'Class'));
		if (InventoryClass == none)
			return isItemSpawned;

		log("[RTTIUnreal] Loaded Inventory class "$InventoryClass$", now trying to spawn it...");

		NewInventory = Spawn(InventoryClass,,, randomPlayer.Location);
		
		if (NewInventory != None) {
			log("[RTTIUnreal] Spawned item "$NewInventory$ " and trying to assign to player...");

			NewInventory.LifeSpan = NewInventory.default.LifeSpan; // prevents destruction when spawning in destructive zones			
			NewInventory.RespawnTime=0; // never respawn, to prevent it getting left in the map as a pickup
			NewInventory.Touch(randomPlayer); // make the item register a touch immediately with the randomly selected player
			
			isItemSpawned = true;
		}
	}

	return isItemSpawned;
}

// Helper methods
function vector GetSpawnPoint() {
	return spawnPointCandidates[Rand(Min(32,spawnPoints))].Location;
}

function Pawn GetRandomPlayer() {
	local Pawn curr,winner;
	local int Score,highScore;

	//choose candidates
	ForEach AllActors(Class'Pawn', curr ) {
		if ( curr.bIsPlayer && curr.Health > 0 && !curr.bHidden && curr.Mesh != None ){
			Score = Rand(100); // Randomize base scoring.
			//if( curr.health <= 0 ) {
			//	Score-=10000;
			//}
			if( winner==None || Score>highScore ) {
				winner = curr;
				highScore = Score;
			}
		}
	}	

	return winner;
}

// shamelessly yanked from UBrowserBufferedTcpLink
function string ParseDelimited(string Text, string Delimiter, int Count, optional bool bToEndOfLine)
{
	local string Result;
	local int Found, i;
	local string s;

	Result = "";
	Found = 1;

	for (i=0; i<Len(Text); i++)
	{
		s = Mid(Text, i, 1);
		if (InStr(Delimiter, s) != -1)
		{
			if (Found == Count)
			{
				if (bToEndOfLine)
					return Result$Mid(Text, i);
				else
					return Result;
			}

			Found++;
		}
		else
		{
			if (Found >= Count)
				Result = Result $ s;
		}
	}

	return Result;
}

defaultproperties 
{
	MaxAttempts=5
}