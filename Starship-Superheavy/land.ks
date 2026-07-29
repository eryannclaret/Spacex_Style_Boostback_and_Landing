clearscreen.

runOncePath("lib").

//------------------------Variables------------------------\\


set landingsite to targetland().
set cluster to ship:partsnamed("SEP.25.BOOSTER.CLUSTER")[0]:getmodule("ModuleSEPEngineSwitch").
set boosterheight to 69. // catchpins height
set braking to false. // 13 engines phase
set threengines to false. // final three engines corrections
set shipbox to ship:bounds.
lock h to shipbox:bottomaltradar+boosterheight. // altitude of the catchpins
set armsheight to 115+max(landingsite:terrainheight,0). // 115 works well but it's hard to know the height of the arms in ksp but it's should be ~130
set marge3 to 1.

set test to false.
set test2 to false.

//------------------------Functions------------------------\\

function aoa { 
    if braking {
        return vang(-ship:velocity:surface, ship:up:vector). // Angle between retrograde and up (angle to be like ship:up) 
    } else {
        return -clamp(round(vang(-ship:velocity:surface,-ship:velocity:surface+0.5*errorvector(landingsite))),0,10). // if it doesn't work for you try ang, change 0.5 to have more or less corrections but 0.5 works well
    }
}

function atmSteer { // modified from edwin roberts

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

function timeToGo {

    local x0 is h - armsheight.
    local v0 is ship:verticalspeed.                                
    local aUp is vdot(ship:up:vector, ship:sensors:acc).

    if abs(aUp) < 0.05 {
        return max(0.1, x0 / max(0.1, abs(v0))).             
    }

    local disc is v0^2 - 2*aUp*x0.
    if disc < 0 {
        return max(0.1, x0 / max(0.1, abs(v0))).
    }

    local sq is sqrt(disc).
    local t1 is (-v0 - sq) / aUp.
    local t2 is (-v0 + sq) / aUp.

    local best is 9999.
    if t1 > 0 and t1 < best { set best to t1. }
    if t2 > 0 and t2 < best { set best to t2. }

    if best = 9999 { return max(0.1, x0 / max(0.1, abs(v0))). }
    return max(0.1, best).
}

function landSteer { // tilt towards the landingsite to land precisely

    local aTot is ship:availablethrust / ship:mass.
    lock aVreq to ship:verticalspeed^2 / (2 * max(0.1, h-armsheight)) + ship:sensors:grav:mag.
    local aHmax is sqrt(max(0, aTot^2 - aVreq^2)).
    local tgo is max(0.1, 2 * (h-armsheight) / max(0.1, abs(ship:verticalspeed))).
    local zem is vxcl(ship:up:vector, landingsite:position) - vxcl(ship:up:vector, ship:velocity:surface) * tgo.
    local aH_vec is (6 * zem / tgo^2) + (2 * vxcl(ship:up:vector, ship:velocity:surface) / tgo).
    local aHmag is min(aH_vec:mag, aHmax).
    
    local straightenrange is 50. // at what altitude prior to armsheight you want to start not correcting anymore and just point ship:up 
    local minStraighten is 0.2. // What % of correction you want to keep anyways
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

    local tgo is timeToGo().
    SET C TO VESSEL("Mechazilla"):CONNECTION.

    if (ag10 or abs(ship:verticalspeed) <=5 )and test = false{ // Flight end

        IF C:SENDMESSAGE("ENDFLIGHT") {
            set test to true.
        }
        
    } else if tgo <= 3.2 and test2 = false and h <=200{
        
        IF C:SENDMESSAGE("CATCH") {
            set test2 to true.
        }

    } else{
        print tgo + " s till catch" AT (0,10).
    }

}

function burnAltitude {

    local d3target is 200. // What meters of three engines correction you want before catch

    local gx is ship:sensors:grav:mag.
    local a13 is max(0.1, ship:maxThrust / ship:mass - gx).
    local a3raw is max(0.1, (ship:maxThrust * 3/13) / ship:mass - gx).
    local a3eff is a3raw / marge3. // le VRAI seuil utilisé par eswitch(), marge3 inclus

    local vx is ship:velocity:surface:mag.

    local d is vx^2 / (2*a13) + d3target * (a13 - a3eff) / a13.

    return d + armsheight.
}

function eswitch { // 3 engines switch 
    local aMax3 is (ship:maxthrust * 3/13) / ship:mass.
    local a3 is aMax3 - ship:sensors:grav:mag. // décélération nette possible avec 3 moteurs
    return -sqrt(2 * a3 * max(0.1, h - armsheight) / marge3).

}

function main {
    // set you to 13 engines
     if ship:maxthrust > 30000 {
      cluster:doevent("next engine mode").
      } else if ship:maxthrust < 7000 {
      cluster:doevent("previous engine mode").
      }

    lock steering to srfRetrograde.
    wait until alt:radar <= 80000. // Correction debuts

    until h <= armsheight or ABORT {
        debug(landingsite).

        if (braking=false and alt:radar <= burnAltitude() and alt:radar <=2000){
            set braking to true.
        }

        if braking and threengines=false and ship:verticalSpeed >= eswitch() {
            set threengines to true.
            cluster:doevent("next engine mode").
        }

        if threengines {
            landSteer().
            landingburn().
            mechazilla().
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
