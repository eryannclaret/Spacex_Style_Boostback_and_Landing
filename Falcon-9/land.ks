clearscreen.
runOncePath("lib").

//------------------------Variables------------------------\\

set shipbox to ship:bounds.
lock h to shipbox:bottomaltradar.
set landingsite to targetland().
set phase to 0. // phase 0 : coasting phase 1 : braking phase 2 : landing

//------------------------Functions------------------------\\

function aoa { 

    if phase = 1 {
        return 0. // braking before final corrections

    } else {
        local ang is clamp(round(vang(-ship:velocity:surface,-ship:velocity:surface+errorvector(landingsite))),0,10). 
        return -ang. // if it doesn't work for you try ang
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

        lock steering to lookDirUp(result,facing:topvector).
}

function landSteer { // tilt towards the landingsite to land precisely

    local aTot is ship:availablethrust / ship:mass.
    lock aVreq to ship:verticalspeed^2 / (2 * max(0.1, h)) + ship:sensors:grav:mag.
    local aHmax is sqrt(max(0, aTot^2 - aVreq^2)).

    local vs is abs(ship:verticalspeed).
    local tgo is max(0.1, 2 * h / max(0.1, vs)).
    
    local r0 is vxcl(ship:up:vector, landingsite:position).
    local v0 is vxcl(ship:up:vector, ship:velocity:surface).
    local zem is r0 - v0 * tgo.
    local aH_vec is (6 * zem / tgo^2) + (2 * v0 / tgo).

    local aHmag is min(aH_vec:mag, aHmax).
    if aH_vec:mag > 0.001 { set aH_vec to aH_vec:normalized * aHmag. }

    lock aVavail to sqrt(max(0.0001, aTot^2 - aHmag^2)).

    lock result to aH_vec + ship:up:vector * aVavail.

    lock steering to lookDirUp(result, facing:topvector).
}

function landingburn {

    if phase=1 {
        lock throttle to clamp(((ship:velocity:surface:mag^2)/(2*ship:sensors:grav:mag*(h))),0,1).
    } else if phase=2 {
        lock throttle to clamp( aVreq / max(0.0001, aVavail), 0, 1).
    } else {
        lock throttle to 0.
    }

}

function burnAltitude {
    local aMax is ship:maxThrust / ship:mass.
    local gx is ship:sensors:grav:mag.
    return (ship:velocity:surface:mag^2 * (2*aMax - 3*gx)) / (2*(aMax - gx)*(aMax - 3*gx)). // simplified version of (burnalt one engine + burnalt three engine)/2
}

function main {

    brakes on.
    lock steering to srfRetrograde.
    wait until alt:radar <= 80000.

    until ship:verticalspeed >= 0 or ag10 or ship:status = "LANDED" {
        debug(landingsite).
        rcscorrections(80000,landingsite).

        if phase = 0 and alt:radar <= burnAltitude() and alt:radar <= 5000 {
            set phase to 1.
        }

        if phase = 2 {
            landSteer().
            landingburn().

        } else if phase = 1 {
            atmSteer().
            landingburn().

            if ship:verticalspeed >= -150 and (ship:sensors:acc:mag / constant:g0) < 3 {
                ship:partsnamed("TE.19.F9.S1.Engine")[0]:getmodule("ModuleTundraEngineSwitch"):doevent("next engine mode").
                gear on.
                set phase to 2.
            }

        } else {
            atmSteer().
        }

        wait 0.
    }

}

main().
clearscreen.
