clearscreen.

runOncePath("lib").

//------------------------Variables------------------------\\


set landingsite to targetland().
set cluster to ship:partsnamed("SEP.25.BOOSTER.CLUSTER")[0]:getmodule("ModuleSEPEngineSwitch").
set boosterheight to 69. // catchpins height
set braking to false. // 13 engines phase
set threengines to false. // final corrections
set shipbox to ship:bounds.
lock h to shipbox:bottomaltradar+boosterheight. // altitude of the catchpins
set armsheight to 115+max(landingsite:terrainheight,0). // 115 works well but it's hard to know the height of the arms in ksp

//------------------------Functions------------------------\\

function aoa { 

    if braking {
        return vang(-ship:velocity:surface, ship:up:vector). // Angle between retrograde and up (angle to be like ship:up) 
    } else {
        return -clamp(round(vang(-ship:velocity:surface,-ship:velocity:surface+0.5*errorvector(landingsite))),0,10). // if it doesn't work for you try ang, change 0.5 to have more or less corrections but 0.5 works well
    }
}
    
function atmSteer { // from edwin roberts

    local velVector is -ship:velocity:surface.
    local correctionVector is errorvector(landingsite).
    set result to velVector + correctionVector.
    local angle is aoa(). 
    if vang(result, velVector) > angle {
        set result to velVector:normalized + tan(angle) * correctionVector:normalized.
    }

    local val is lookdirup(result, facing:topvector).
    local p is val:pitch.
    local y is val:yaw.

    lock steering to R(p,y,270). // QD facing tower

}

function landSteer { // tilt towards the landingsite to land precisely

    local aTot is ship:availablethrust / ship:mass.
    lock aVreq to ship:verticalspeed^2 / (2 * max(0.1, h-armsheight)) + ship:sensors:grav:mag.
    local aHmax is sqrt(max(0, aTot^2 - aVreq^2)).
    local tgo is max(0.1, 2 * (h-armsheight) / max(0.1, abs(ship:verticalspeed))).
    local zem is vxcl(ship:up:vector, landingsite:position) - vxcl(ship:up:vector, ship:velocity:surface) * tgo.
    local aH_vec is (6 * zem / tgo^2) + (2 * vxcl(ship:up:vector, ship:velocity:surface) / tgo).
    local aHmag is min(aH_vec:mag, aHmax).
    
    local straightenrange is 50. // at what altitude prior to armsheight you want to start not correcting anymore to just point ship:up 
    local minStraighten is 0.15. // What % of correction you want to keep anyways
    local straightenfactor is minStraighten + (1 - minStraighten) * clamp((h - armsheight) / straightenrange, 0, 1)^2.
    set aHmag to aHmag * straightenfactor.

    if aH_vec:mag > 0.001 {
        set aH_vec to aH_vec:normalized * aHmag.
    }
    
    lock aVavail to sqrt(max(0.0001, aTot^2 - aHmag^2)).
    lock result to aH_vec + ship:up:vector * aVavail.

    lock steering to lookdirup(result, facing:topvector). 

}

function landingburn {

    // lock throttle to clamp(aVreq / max(0.0001, aVavail), 0, 1).

    if threengines or braking {
        lock throttle to clamp(((ship:velocity:surface:mag^2)/(2*ship:sensors:grav:mag*(h-armsheight))),0,1).
    } else {
        lock throttle to 0.
    }

}

function mechazilla { // Mechazilla signal
    set message to "Close chopsticks".
    SET C TO VESSEL("superheavy Base"):CONNECTION.
    IF C:SENDMESSAGE(MESSAGE) {
        PRINT "" AT (0,9).
    }
}


function burnAltitude { // Burn altitude calculation, it's the simplified calcul of (burnalt 13 engines + burnalt 3 engines)/2
    local aMax is ship:maxThrust / ship:mass.
    local gx is ship:sensors:grav:mag.
    return max((13 * ship:velocity:surface:mag^2) / (2 * (8 * aMax - 13 * gx)),800).
}

function main {
    // Autamtically set you to 13 engines
     if ship:maxthrust > 30000 {
      cluster:doevent("next engine mode").
      } else if ship:maxthrust < 7000 {
      cluster:doevent("previous engine mode").
      }

    lock steering to srfRetrograde.
    wait until alt:radar <= 80000. // Correction debuts

    until h <= armsheight or ag10 {
        debug(landingsite).

        if (braking=false and alt:radar <= burnAltitude() and alt:radar <=1000){
            set braking to true.
        }

        if braking and threengines=false and ship:verticalSpeed >=-150 {
            set threengines to true.
            cluster:doevent("next engine mode").
        }

        if h <= 200 {
            mechazilla().
        }

        if threengines {
            landSteer().
            landingburn().
        } else if braking {
            atmSteer().
            landingburn().
        } else {
            atmSteer().
        }

        wait 0.05.
    }
}

main().

clearscreen.
