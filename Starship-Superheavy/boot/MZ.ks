// Put this in boot folder, and make the tower run this at launch

//--Variables--\\
// set sh to Vessel("Starship").
set sh to Vessel("Heavy Booster"). // Change the name to your superheavy vessel name

set Mechazilla to ship:partsnamed("SLE.SS.OLIT.MZ")[0].
set MZ to Mechazilla:getmodule("ModuleSLEController").

set geolat to ship:geoposition:lat.
set geolng to ship:geoposition:lng.

set northVector TO SHIP:NORTH:VECTOR.
set upVector TO SHIP:UP:VECTOR.
set eastVector TO VCRS(upVector, northVector).
set shipvec TO VXCL(ship:facing:forevector,ship:facing:starvector).
set northComponent TO -ROUND(VDOT(shipvec, northVector)).
set eastComponent TO ROUND(VDOT(shipvec, eastVector)).

set angleoffset to 8.  
set maxarmangle to 56.8.  
set epsilon to 0.00001.  
set catch to false.
set endflight to false.

set dt to 0.04. 

wait until sh:verticalspeed <=-10.

//--Main--\\

until endflight {

    local mess is "".
    if not ship:messages:empty {
        set mess to ship:messages:pop:content.
    }

    if mess = "CATCH" {
      set catch to true.
    } else if mess = "ENDFLIGHT" {
        set endflight to true.
    }


  if not catch {
      local vspos is sh:geoPosition.
      local v1 is VXCL(vspos:position-Mechazilla:position,ship:up:vector):normalized.
      local v0 is ship:facing:starvector.

      local dlat is vspos:lat-geolat.
      local dlng is vspos:lng-geolng.
      local orientdelta is round(eastComponent*dlat + northComponent*dlng,6). 

      local ang is angleoffset.
      local clampang is angleoffset.

      if orientdelta > epsilon  {
        set ang to -vang(v1,v0).
        set clampang to max(ang+angleoffset,-maxarmangle).
      } else if orientdelta < -epsilon {
        set ang to vang(v1,v0).
        set clampang to min(ang,maxarmangle).
      }
  
    MZ:setfield("target angle", clampang).

  } else {
    MZ:doevent("close arms").
  }

 wait dt.
}
toggle ag1.
