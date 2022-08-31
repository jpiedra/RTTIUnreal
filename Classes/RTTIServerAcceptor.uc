/*
 * 8/26/2022 Jaypeezy
 * Based on TcpLink example classes: https://docs.unrealengine.com/udk/Three/TcpLink.html
 * Original by Michiel 'elmuerte' Hendriks for Epic Games, Inc.
 */ 
class RTTIServerAcceptor extends TcpLink;

var RTTIActQueue aq; // a reference to the first (and hopefully only) RTTIActQueue instance found, spawned by the mutator RTTIUnreal

function bool AddQueueAct( RTTIActQueue actQueue, string actString) {
    local bool result;
    
    result = actQueue.AddAct(actString);

    return result;
}

event Spawned()
{
    local Mutator mut;

    log('[RTTIServerAcceptor] Spawned a ServerAcceptor');

    for(mut=level.game.basemutator; mut!=none; mut=mut.nextmutator) {
        if ( mut.IsA('RTTIUnreal') ) {
            aq = RTTIUnreal(mut).rttiActQueue;

            if (aq != None) {
                log('[RTTIServerAcceptor] Found an RTTIActQueue instance');
                aq.PrintSelf();
            } else {
                log('[RTTIServerAcceptor] Could not find an RTTIActQueue instance');
            }
            return;
        }
    }
}

event Accepted()
{
    log("[RTTIServerAcceptor] New client connected");
    // make sure the proper mode is set
    LinkMode=MODE_Line;
}

event ReceivedLine( string Line )
{   
    log("[RTTIServerAcceptor] Received line: "$line);
    log("[RTTIServerAcceptor] Processing line via action queue...");

    if(aq != None) {
        aq.PrintSelf();
        aq.AddAct(Line);
    }

    Close();
    return;
}

event Closed()
{
    aq = None;
    Log("[RTTIServerAcceptor] Connection closed");
 	Destroy();
}

defaultproperties
{
    bHidden=true
}
