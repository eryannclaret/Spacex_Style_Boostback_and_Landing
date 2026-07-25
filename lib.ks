//----------------------------------------------------------------------------LIBRARY----------------------------------------------------------------------------\\
clearscreen.
//------Maths------\\

function clamp {
    parameter val, min_val, max_val.
    return min(max(val, min_val), max_val).
}

function sign {
    parameter val.
    if val = 0 return 1.
    return val / abs(val).
}

//------Target------\\
// Change the latlng to your landingsites locations, you can change the name too
function targetland {
    local sites is lexicon(
        "a", list(latlng(28.5320769649256,-80.6559318988256), "OLT-A"),
        "b", list(latlng(25.9967515622019, -97.1579564069524), "OLT-B"),
        "c", list(latlng(28.6081826102928, -80.601304446744), "OLT-C"),
        "w", list(latlng(25.9962480647979, -96), "Water Test"),
        "3", list(latlng(34.63310839876, -120.615155971947), "LZ-3"),
        "2", list(latlng(28.4877484442497, -80.5449202044373), "LZ-2"),
        "1", list(latlng(28.4857625502468, -80.5429426267221), "LZ-1"),
        "e", list(latlng(28.5322014174306, -80.8922118636237), "Exodus Sound"),
        "j", list(latlng(28.4213006585212,-78.4614638010635), "Jacklyn"),
        "x", list(getimpact(),"Anywhere")
    ).

    clearscreen.
    print "Select Landing Site :" AT (0,0).
    print "Corresponding letters :" AT (0,1).
    clearscreen.
    for key in sites:keys {
        print key + " : " + sites[key][1].
    }

    until false {
        local choice is terminal:input:getchar().
        local selection is list().

        if choice = "t" and hastarget {
            set selection to list(target:geoposition, "Target: " + target:name).
        } else if choice = "o" {
            set selection to list(Vessel("ASOG"):geoposition, "ASOG").
        } else if sites:haskey(choice) {
            set selection to sites[choice].
        }

        if selection:length > 0 {
            clearscreen.
            print "Landingsite : " + selection[1] AT (0,0).
            addons:tr:settarget(selection[0]).
            return selection[0].
        }
    }
}

//------Steering------\\

function getImpact {

    if addons:tr:hasimpact { 
    return addons:tr:impactpos. 
    }
return ship:geoposition.
}

function errorVector {
    parameter pos.
    return pos:position - getImpact():position.
}

function rcscorrections {
    parameter activation, pos.
    if alt:radar <= activation{

        set lngerr to ship:geoposition:lng - pos:lng.
        set laterr to ship:geoposition:lat - pos:lat.

        local ro is ship:facing:roll.
        local top_cmd is (-laterr * COS(ro)) - (lngerr * SIN(ro)).
        local starboard_cmd is (-laterr * SIN(ro)) + (lngerr * COS(ro)).

        if top_cmd > 0 {
            set SHIP:CONTROL:TOP to 1.
        } else if top_cmd < 0 {
            set SHIP:CONTROL:TOP to -1.
        } else {
            set SHIP:CONTROL:TOP to 0.
        }

        if starboard_cmd > 0 {
            set SHIP:CONTROL:STARBOARD to 1.
        } else if starboard_cmd < 0 {
            set SHIP:CONTROL:STARBOARD to -1.
        } else {
            set SHIP:CONTROL:STARBOARD to 0.
        }
    }
}








//------Misc------\\

function debug {
    parameter pos.
    PRINT "Speed           : " + ROUND(SHIP:VELOCITY:SURFACE:MAG)*3.6 + " km/h   " AT (0,1).
    PRINT "Max Thrust      : " + ROUND(SHIP:MAXTHRUST, 2) + " kN      " AT (0,2).
    PRINT "Mass            : " + ROUND(SHIP:MASS, 3) + " t       " AT (0,3).
    print "Error vector    : " + errorVector(pos):mag + " m       " AT (0,4).
    print "AoA             : " + vang(ship:facing:vector,ship:velocity:surface) + " °   " AT (0,5).
    print "Burn alt        : " + (ship:velocity:surface:mag^2)/(2*((ship:maxThrust/ship:mass)-9.81)) + " m " AT (0,6).
    print "Throttle        : " + throttle AT (0,7).
    print "Gs              : " + (SHIP:SENSORS:ACC:MAG / CONSTANT:g0) AT (0,8).
}




function debugvisual {
    parameter pos.
    clearVecDraws().
    SET anArrow TO VECDRAW(V(0,0,0),-ship:velocity:surface,rgba(255, 0, 0, 1),"-ship:velocity:surface",1.0,TRUE,0.2,TRUE,TRUE).
    SET anArro TO VECDRAW(V(0,0,0),errorVector(pos),rgba(0, 0, 255, 1),"errorVector",1.0,TRUE,0.2,TRUE,TRUE).
    // SET anArr TO VECDRAW(V(0,0,0),pos:position-ship:position,RGB(0,1,0),"vectopad",1.0,TRUE,0.2,TRUE,TRUE).
    // SET anAr TO VECDRAW(V(0,0,0),tstvec2,RGB(0,1,0),"See the arrow?",1.0,TRUE,0.2,TRUE,TRUE).
    // SET anA TO VECDRAW(V(0,0,0),tstvec2,RGB(0,1,0),"See the arrow?",1.0,TRUE,0.2,TRUE,TRUE).
    // SET an TO VECDRAW(V(0,0,0),tstvec2,RGB(0,1,0),"See the arrow?",1.0,TRUE,0.2,TRUE,TRUE).
    // SET a TO VECDRAW(V(0,0,0),tstvec2,RGB(0,1,0),"See the arrow?",1.0,TRUE,0.2,TRUE,TRUE).
// 
}

function falconlanded {
clearScreen.
print "                                      ".
print "                                      ".
print "                 | |                  ".
print "                -|-|-                 ".
print "                 | |                  ".
print "                 | |                  ".
print "                 | |                  ".
print "                 | |                  ".
print "                 | |                  ".
print "                 | |                  ".
print "                 | |                  ".
print "                 |.|                  ".
print "                /|||\                 ".
print "               / ||| \                ".
print "              / /|||\ \               ".
print "             /_/  |  \_\              ".
print "  ____            *                   ".
print "  [  ]            *             |__   ".
print "  [__]__________________________[]/   ".
print "                                      ".
print "           BOOSTER LANDED             ".
}

function heavycatched {
clearScreen.
print "----------------------------------".
print "    ______                        ".
print "    |/|\|/                        ".
print "    |/|\|_____ -|-|-              ".
print "    |/|\|%%%%/  | |               ".
print "    |/|\|       | |               ".
print "    |/|\|       |_|               ".
print "    |/|\|       |_|               ".
print "    |/|\|       | |               ".
print "    |/|\|       | |               ".
print "    |/|\|       | |               ".
print "    |/|\|        *                ".
print "    |/|\|        *                ".
print "    |/|\|         *               ".
print "    |/|\|          *              ".
print "    |/|\|          *              ".
print "    |/|\|                         ".
print "    |/|\|     __   __             ".
print "    |/|\|     __   __             ".
print "    |/|\|     __   __             ".
print "    |/|\|     __   __             ".
print "    |/|\|    /=======\            ".
print "    |/|\|   /=========\           ".
print "----------------------------------".
print "Heavy Booster Catched Succesfully".                                             
}

function newglennlanded {
clearScreen.
print "                                      ".
print "                                      ".
print "               |[][][]|               ".
print "               |[][][]|               ".
print "              /|[]/\[]|\              ".
print "              \|[]\/[]|/              ".
print "               |      |               ".
print "               |      |               ".
print "               |      |               ".
print "               |      |               ".
print "               |      |               ".
print "               |      |               ".
print "               |      |               ".
print "               |      |               ".
print "               |      |               ".
print "               |      |               ".
print "               |      |               ".
print "               |      |               ".
print "               |      |               ".
print "               |      |               ".
print "               |      |               ".
print "               |      |               ".
print "              /|      |\              ".
print "             | |      | |             ".
print "             | |      | |             ".
print "             | |      | |             ".
print "             | |      | |             ".
print "             | |      | |             ".
print "              \|[][][]|/              ".
print "              '|[][][]|'               ".
print "             '/|[]||[]|\'              ".
print "            '/    ||    \'             ".
print "            '    ''     '            ".
print "     [][]                    [][]     ".
print "     [][]____________________[][]     ".
print "                                      ".
print "      New Glenn Landed Succesfully    ".                                             
}
