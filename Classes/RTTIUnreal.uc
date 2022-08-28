class RTTIUnreal expands Mutator config(RTTIUnreal);

var RTTIServer rttiServer;
var RTTIActQueue rttiActQueue;

function PreBeginPlay() {
	SetTimer(5, True);
}

function PostBeginPlay() {
	rttiActQueue = Spawn(class'RTTIUnreal.RTTIActQueue', Self);
	rttiServer = Spawn(class'RTTIUnreal.RTTIServer', Self);
    if (rttiActQueue != None && rttiServer != None) {
		log('[RTTIUnreal] Successfully spawned Server and ActQueue instances');
	}
}


simulated function Timer() {
	HandleAct();
}

function HandleAct() {
	local int actNum;
	local string actString;

	local string actName,actOwner,actType;

	actNum = 0;
	actString = "";

	actNum = rttiActQueue.GetQueueSize();
	if (actNum != 0) {
		actString = rttiActQueue.PopAct();

		actOwner = ParseDelimited(actString,"?",1);
		actName = ParseDelimited(actString,"?",2);
		actType = ParseDelimited(actString,"?",3);

		log("[RTTIUnreal] Processing act '"$actName$"' started by '"$actOwner$"' (type: '"$actType$"')");
		BroadcastMessage(actString, true, 'CriticalEvent');

	}
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