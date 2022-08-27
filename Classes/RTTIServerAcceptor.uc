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
    // local RTTIActQueue A;

    // // we only want the first instance of RTTIActQueue
    // foreach AllActors( class 'RTTIActQueue', A)
    // {
    //     if( A.IsA('RTTIActQueue') )
    //     {
    //         aq = A;
    //         break;
    //     }
    // }
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

    // make something happen inside the current game...
    // if(aq != None) {
    //     if(!AddQueueAct(aq, line)) {
    //         SendText("[RTTIServerAcceptor] Could not add to action queue: "$line);
    //     } else {
    //         SendText("[RTTIServerAcceptor] Received and added to action queue: "$line);
    //         SendText("[RTTIServerAcceptor] Closing connection...");
    //     }
    // }

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
    // It's important to destroy the object so that the parent knows
    // about it and can handle the closed connection. You can not
    // reuse acceptor instances.
 	Destroy();
}
