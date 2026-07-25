// Put this in boot folder, and make the tower run this at launch

//--Variables--\\
// set sh to Vessel("Starship").
set sh to Vessel("superheavy").

set Mechazilla to ship:partsnamed("SLE.SS.OLIT.MZ")[0].
set MZ to Mechazilla:getmodule("ModuleSLEController").

set angleoffset to 8.
set geolat to ship:geoposition:lat.
set geolng to ship:geoposition:lng.

set northVector TO SHIP:NORTH:VECTOR.
set upVector TO SHIP:UP:VECTOR.
set eastVector TO VCRS(upVector, northVector).
set shipvec TO VXCL(ship:facing:forevector,ship:facing:starvector).
set northComponent TO -ROUND(VDOT(shipvec, northVector)).
set eastComponent TO ROUND(VDOT(shipvec, eastVector)).

set dt to 0.04.

wait until sh:verticalspeed <=-10.
//--Main--\\

until false {
  local v1 is VXCL(sh:geoposition:position-Mechazilla:position,ship:up:vector):normalized.
  local v0 is ship:facing:starvector.
  local dlat is sh:geoposition:lat-geolat.
  local dlng is sh:geoposition:lng-geolng.

  local orientdelta is round(eastComponent*dlat + northComponent*dlng,5). // 5 ==> meter precision, 4 ==> 10m precision

  if orientdelta > 0.00001  {
    set ang to -vang(v1,v0).
    set clampang to max(ang+angleoffset,-56.8).
  } else if orientdelta < 0.00001 {
    set ang to vang(v1,v0).
    set clampang to min(vang(v1,v0),56.8).
  } else {
    set ang to angleoffset.
  }
  
  set endflight to false.
  if NOT SHIP:MESSAGES:EMPTY {
    set mess to SHIP:MESSAGES:POP:CONTENT.
    if mess="CATCH"{
        MZ:doevent("close arms").
    } else if mess ="ENDFLIGHT" {
      set endflight to true.
    } else {
      print "waiting for signal".
    }
  }
  if endflight {
    break.
  }
  MZ:setfield("target angle",clampang). // Where does the arms need to point

 wait dt.
}
