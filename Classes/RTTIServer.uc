/*
 * 8/26/2022 Jaypeezy
 * Based on TcpLink example classes: https://docs.unrealengine.com/udk/Three/TcpLink.html
 * Original by Michiel 'elmuerte' Hendriks for Epic Games, Inc.
 */
class RTTIServer extends TcpLink config(RTTIUnreal);

var() config int ListenPort;
var() config int MaxClients;
var int NumClients;

event PreBeginPlay()
{
	// write the config file
	SaveConfig();
}

event PostBeginPlay()
{
    super.PostBeginPlay();
    
    if ( BindPort(ListenPort, false))
	{
        // start listening for connections
        if (Listen())
        {
            log("[RTTIServer] Listening on port "$ListenPort$" for incoming connections");
        }
        else {
            log("[RTTIServer] Failed listening on port "$ListenPort);
        }
	}
	else
	{
		log( "[RTTIServer] Failed to bind port "$ListenPort );
	}
}

event GainedChild( Actor C )
{
    Log("[RTTIServer] GainedChild");
	super.GainedChild(C);
	++NumClients;
	
	// if too many clients, stop accepting new connections
	if(MaxClients > 0 && NumClients >= MaxClients && LinkState == STATE_Listening)
	{
		log("[RTTIServer] Maximum  number of clients connected, rejecting new clients");
 		Close();
	}
}

event LostChild( Actor C )
{
    Log("[RTTIServer] LostChild");
	Super.LostChild(C);
	--NumClients;
	
	// Check if there is room for accepting new clients
	if(NumClients < MaxClients && LinkState != STATE_Listening)
	{
		log("[RTTIServer] Listening for incoming connections");
 		Listen();
	}
}

defaultproperties
{
	bHidden=true
    ListenPort=5900
    MaxClients=2    
    AcceptClass=Class'RTTIUnreal.RTTIServerAcceptor'
}