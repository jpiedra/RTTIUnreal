class RTTIActQueue expands Actor;

var string Queue[255];
var int ActNum;

function PreBeginPlay() {
    bHidden = true;
    ActNum = 0;
}

// debugging method to ensure we don't get more than one object somehow
function PrintSelf() {
    log('[RTTIActQueue] This is: '$Self.GetPointerName());
}

function bool AddAct( String actString ) {
    // get rid of newline characters and carriage returns
    actString = ReplaceStr(actString,"\n","");
    actString = ReplaceStr(actString,"\r","");

    if (ActNum >= 255) {
        log('[RTTIActQueue] Queue is full, could not add pending action');
        // respond somehow?
        return false;
    } else {
        Queue[ActNum] = actString;
        log("[RTTIActQueue] Successfully added '"$actString$"' at position '"$ActNum$"'");
        ++ActNum;
    }
    return true;
}

function string PopAct() {
    local string actString;
    local int i;

    actString = "";
    i = ActNum - 1;

    if (i < 0) {
        log("[RTTIActQueue] Failed to get an action as the queue is empty");
    } else {
        actString = Queue[i];
        Queue[i] = "";
        log("[RTTIActQueue] Successfully got '"$actString$"' from position '"$i$"'");
        --ActNum;
    }

    return actString;
}

function int GetQueueSize() {
    return ActNum;
}