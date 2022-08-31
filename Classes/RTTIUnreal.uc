class RTTIUnreal expands Mutator config(RTTIUnreal);

var RTTIServer rttiServer;
var RTTIActQueue rttiActQueue;

var NavigationPoint spawnPointCandidates[32];
var int spawnPoints;
var int spawnAttempts;

// Gameloop and timer
function PreBeginPlay() {
	Super.PreBeginPlay();
	Level.Game.bHumansOnly = false;
	Level.Game.bNoMonsters = false;
	SetTimer(5, True);
}

function PostBeginPlay() {
	local NavigationPoint N;

	spawnPoints = 0;
	
	Super.PostBeginPlay();
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
		case "change_music":
			isActSuccessful = (ChangeMusic(actOwner, actArgs));
			break;
		case "spawn_item":
			isActSuccessful = (SpawnItem(actOwner, actArgs));
			break;
		// case "kill_monsters":
		// 	isActSuccessful = (KillMonsters(actOwner, actArgs));
		// 	break;
		// case "kill_all":
		// 	isActSuccessful = (KillAll(actOwner, actArgs));
		// 	break;
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

	for (i = 0; i < spawnAttempts; i++) {	
		log("[RTTIUnreal] Trying to spawn "$MonsterClass$ " - attempt "$i+1);
		SpawnPoint = GetSpawnPoint();
		NewMonster = Spawn(MonsterClass,self,,SpawnPoint);
		if (NewMonster != None) {
			Log("[RTTIUnreal] Successfully spawned for '"$actOwner$"' - '"$actArgs$"'!");
			isMonsterSpawned = true;
			// try to spawn special effect
			SpawnEffect = Spawn(class'UnrealShare.PawnTeleportEffect');
			// how to spawn an effect???
			// Spawn(class'Unrealshare.TeleportEffect', self, , SpawnPoint);
			// modify pawn props here
			// NewMonster.Health = NewMonster.default.Health * class'MonsterCycle'.default.HealthMultiplier;
			NewMonster.NameArticle = actOwner$"'s"$" ";
			NewMonster.GotoState('Wandering');
			break;			
		}
	}

	return isMonsterSpawned;
}

function bool SpawnItem(string actOwner, string actArgs) {
	local int i;
	local Pickup NewPickup;
	local bool isItemSpawned;
	local bool bActivate;
	local vector SpawnPoint;
	local class<Pickup> PickupClass;

	isItemSpawned = false;
	bActivate = false;
	
	log(GetRandomPlayer());

	return false;

	//PickupClass = actArgs;

	// NewPickup = Spawn(PickupClass,,, Location);
	// if (NewPickup == none)
	// 	return isItemSpawned;
	// NewPickup.LifeSpan = NewPickup.default.LifeSpan; // prevents destruction when spawning in destructive zones
	// NewPickup.GiveTo(Player);
	// if (NewPickup.bActivatable && Player.SelectedItem == none)
	// 	Player.SelectedItem = NewPickup;
	// if (bActivate)
	// 	NewPickup.Activate();
	// NewPickup.PickupFunction(Player);
}

// doesn't work
function bool ChangeMusic(string actOwner, string actArgs) {
	local Music Song;
	local byte SongSection; 
	local byte CdTrack; // unused
	local PlayerPawn LocalPlayer;
	local bool bChangeAllLevels;

	Song = Music(DynamicLoadObject(actArgs, Class'Music'));
	SongSection = 1;
	CdTrack = 255;
	bChangeAllLevels = true;

	if (Song != None) {
		log('[RTTIUnreal] Loaded music: '$Song);		
      	ForEach AllActors(Class'PlayerPawn',LocalPlayer) {
            if( LocalPlayer != None ) {
				if(LocalPlayer.Player != None) {
					if(Song != None) {
						log('[RTTIUnreal] Setting music: '$Song);		
						LocalPlayer.ClientSetMusic( Song, 1, 255, MTRAN_Instant );
					}
				}
            }
      	}

		return true;
	} else {
		return false;
	}
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
		if (curr.IsA('Bots') || curr.IsA('PlayerPawn')) {
			Score = Rand(100); // Randomize base scoring.
			if( curr.health <= 0 ) {
				Score-=10000;
			}
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
	//RemoteRole=ROLE_SimulatedProxy
}