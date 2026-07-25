//----------------------------------------------------------------------------------BOOSTBACK SCRIPT-------------------------------------------------------------------------------\\

runOncePath("lib").

//--Variables--\\

set doneprev to false.
set donenext to false.
set meco to 60000. // Boostback start altitude.
set x to 0.// lngoff you want, in a real flight this would be set to have ~100 meter error
set cluster to ship:partsnamed("SEP.25.BOOSTER.CLUSTER")[0]:getmodule("ModuleSEPEngineSwitch").
set dt to 0.2.
set landingsite to targetland().

LIST RESOURCES IN RESLIST.
FOR RES IN RESLIST {
    if RES:name = "LqdMethane" {    // Change lqdmethane to liquidfuel if you don't have methane
      set maxlqdfuel to res:capacity.
    }
}

//----------------------------------------------------------------------------------MAIN-------------------------------------------------------------------------------\\

// lock steering to R(ship:facing:pitch,ship:facing:yaw,270).
//--MECO SEQUENCE--\\

when alt:radar >=meco-1000 then {
  cluster:doevent("next engine mode").
  wait 0.5.
  cluster:doevent("next engine mode").
  stage. // Starship engines
  stage.
  lock throttle to 0.1.
}

//--Activator--\\

wait until alt:radar >= meco.

//--Other variables--\\
set t1 to landingsite:position - getImpact():position. // Landingsite - your impact pos, needed for my throttle ratio formula
set tin to abs(errorvector(landingsite):mag/ship:velocity:surface:mag/2).

//--longitude and latitude offset in meters--\\

lock lngoff to (landingsite:LNG - ADDONS:TR:IMPACTPOS:LNG)*10472. 
lock latoff to (landingsite:LAT - ADDONS:TR:IMPACTPOS:LAT)*10472. 
brakes on. // Gridfins

set deltaLng to landingsite:lng - ship:geoposition:lng.

if deltaLng > 180 {
    set deltaLng to deltaLng - 360.
}
if deltaLng < -180 {
    set deltaLng to deltaLng + 360.
}

if deltaLng > 0 {
    set k to -1.
} else {
    set k to 1.
}
// flip after separation your roll needs to be QD facing up (if you using mechjeb2 uncheck the parameter that forces the roll to a certain degree)
until vang(heading(k*landingsite:heading,0):vector,ship:facing:forevector) <= 20 {
    unlock steering.
    set ship:control:top to 1.
    set ship:control:starboard to (ship:up:pitch - ship:facing:pitch)/abs((ship:up:pitch - ship:facing:pitch)).
    lock throttle to 0.5.
    LOCK STEERING TO LOOKDIRUP(heading(k*landingsite:heading,0):vector, SHIP:FACING:TOPVECTOR).
    if doneprev = false and vang(heading(k*landingsite:heading,0):vector,ship:facing:forevector) <= 45 {
        cluster:doevent("previous engine mode").
        set doneprev to true.
    }
}

until lngoff > x or AG10 {

    lock bbt to errorvector(landingsite):mag/t1:mag.
    set corr to VXCL(ship:sensors:grav,landingsite:position-ship:position). // straight vec from you to landingpos, on the same plan as errorvec.
    set tsvl to VXCL(ship:sensors:grav,(ship:direction:STARVECTOR)*latoff).

    //--Engines--\\

    if abs(lngoff) <=50 and donenext = false {
        cluster:doevent("next engine mode").
        set dt to 0.05.
        toggle ag8.
        set donenext to true.    
    }

    //--Steering--\\
    
    set nv to corr + 15* tsvl. // 15 works well, feel free to change

    if abs(getimpact():lat) - abs(landingsite:lat) < 0 { // Vessel orientation 
        set ang to vang(corr, nv).
    } else {
        set ang to -vang(corr, nv).
    }

    set fdir to heading(k*landingsite:heading+ang,0).

    //--RCS AND FUEL CONTROL--\\

    if vang(heading(k*landingsite:heading+ang, 0):vector,ship:facing:forevector) <= 10 {
        local lat_error is getimpact():lat-landingsite:lat. 
        local rcsthrust is (lat_error/abs(lat_error)).
        local str is round(cos(ship:facing:roll)).
        local tp is round(sin(ship:facing:roll)). 
        local t is abs(errorvector(landingsite):mag/ship:velocity:surface:mag).
        local fcalc is (ship:lqdmethane-(0.02*maxlqdfuel))/16192.5. // your fuel - 2% of the max / (drain speed). Change ship:lqdmethane to ship:liquidfuel if you don't have methane

        // Fuel drain
        if round(fcalc) <= abs(round(tin)-round(t)) {
            if ship:lqdmethane >=0.02*maxlqdfuel {
                ag7 on.
            } else {
                ag8 on.
            }
        }
        // Rcs corrections
        if str = 1 or tp = -1{
            set ship:control:starboard to rcsthrust.
        } else {
            set ship:control:starboard to -rcsthrust.
        }
    }

    //--Main Control--\\
    lock steering to lookdirup(fdir:vector, ship:up:vector)*R(0,0,180).
    lock throttle to abs(min(max(bbt,0.01),1)).
    print("lngoff  " + lngoff ) AT (0,1).
    print("latoff  "+ latoff ) AT (0,2).
wait dt.
}

lock throttle to 0.
set ship:control:starboard to 0.
set ship:control:top to 0.
clearscreen.

stage. // HSR
