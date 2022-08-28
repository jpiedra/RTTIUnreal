class RTTIUnreal expands Mutator config(RTTIUnreal);

var RTTIServer rttiServer;
var RTTIActQueue rttiActQueue;

var NavigationPoint spawnPointCandidates[32];
var int spawnPoints;
var int spawnAttempts;

// Gameloop and timer
function PreBeginPlay() {
	SetTimer(5, True);
	Level.Game.bHumansOnly = false;
	Level.Game.bNoMonsters = false;
}

function PostBeginPlay() {
	local NavigationPoint N;

	spawnPoints = 0;
	
	rttiActQueue = Spawn(class'RTTIUnreal.RTTIActQueue', Self);
	rttiServer = Spawn(class'RTTIUnreal.RTTIServer', Self);
	spawnAttempts = 5; // configure via .ini
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
}

simulated function Timer() {
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
		RunAct(actString, actOwner, actName, actArgs);
		// BroadcastMessage(actString, true, 'CriticalEvent');
	}
}

function RunAct(string actString, string actOwner, string actName, string actArgs) {
	// running list of available actions that can be initiated
	switch( actName )
	{
		case "spawn_monster":
			log("[RTTIUnreal] Running act '"$actName$"' started by '"$actOwner$"' (args: '"$actArgs$"')");
			if (SpawnMonster(actOwner, actArgs)) {
				log("[RTTIUnreal] Successfully ran act '"$actName$"' started by '"$actOwner$"' (args: '"$actArgs$"')");
			} else {
				log("[RTTIUnreal] Failed to run act '"$actName$"' started by '"$actOwner$"' (args: '"$actArgs$"')");
			}
			break;
		case "spawn_earthquake":
			log("[RTTIUnreal] Running act '"$actName$"' started by '"$actOwner$"' (args: '"$actArgs$"')");
			break;
		case "kill_monsters":
			log("[RTTIUnreal] Running act '"$actName$"' started by '"$actOwner$"' (args: '"$actArgs$"')");
			break;
		case "kill_all":
			log("[RTTIUnreal] Running act '"$actName$"' started by '"$actOwner$"' (args: '"$actArgs$"')");
			break;
		default:
			log("[RTTIUnreal] Could not find act '"$actName$"' requested by '"$actOwner$"'");
			break;
	}
}

// Actions
function bool SpawnMonster(string actOwner, string actArgs) {
	local int i;
	local ScriptedPawn NewMonster;
	local bool isMonsterSpawned;
	local vector SpawnPoint;
	local class<ScriptedPawn> MonsterClass;

	isMonsterSpawned = false;

	MonsterClass = class<ScriptedPawn>(DynamicLoadObject(actArgs,class'Class'));
	if (MonsterClass == None) {
		Log("[RTTIUnreal] Invalid class: '"$actArgs$"'!");
		return isMonsterSpawned;
	}

	for (i = 0; i < spawnAttempts; i++) {	
		SpawnPoint = GetSpawnPoint();
		NewMonster = Spawn(MonsterClass,self,,SpawnPoint);
		if (NewMonster != None) {
			Log("[RTTIUnreal] Successfully spawned for '"$actOwner$"' - '"$actArgs$"'!");
			isMonsterSpawned = true;
			Spawn(class'ReSpawn', self, , SpawnPoint);
			// modify pawn props here
			// NewMonster.Health = NewMonster.default.Health * class'MonsterCycle'.default.HealthMultiplier;
			NewMonster.GotoState('Wandering');
			break;			
		}
	}

	return isMonsterSpawned;
}

// Helper methods
function vector GetSpawnPoint() {
	return spawnPointCandidates[Rand(Min(32,spawnPoints))].Location;
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