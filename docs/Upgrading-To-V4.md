# Upgrading to RGeo-Proj4 V4

The following is a checklist of things that you may need to change in your application to upgrade from rgeo-proj4 V3 to V4.

* EPSG:XXXX definitions can be replaced with just the auth code number.

```ruby
require 'rgeo'
require 'rgeo/proj4'

RGeo::CoordSys::Proj4.create("EPSG:4326") == RGeo::CoordSys::Proj4.create(4326)
# => true
```

* Since V4 requires newer versions of Proj, the `+type=crs` string will need to be added to proj string definitions to ensure that proj properly interprets it as a coordinate system.
* Creating `Proj4` objects may raise an `RGeo::Error::InvalidProjection` error, so any place where a possibly invalid proj definition is being used should handle this error.

```ruby
require 'rgeo'
require 'rgeo/proj4'

RGeo::CoordSys::Proj4.create("")
# => raises RGeo::Error::InvalidProjection
```

* Transforming coordinates may raise an `RGeo::Error::InvalidProjection` error if one of the proj object's underlying data is something other than a coordinate system. You should handle this error when you are transforming with potentially invalid proj objects. You can also use the new `crs?` method on a `Proj4` object to check if the underlying proj data is a crs.

```ruby
require 'rgeo'
require 'rgeo/proj4'

non_crs_proj_str = "+proj=merc +lat_ts=56.5 +ellps=GRS80"
proj1 = RGeo::CoordSys::Proj4.create(non_crs_proj_str)
proj2 = RGeo::CoordSys::Proj4.create(3857)

RGeo::CoordSys::Proj4.transform_coords(proj1, proj2, 1, 2, nil)
# => raises RGeo::Error::InvalidProjection

proj1.crs?
# => false
proj2.crs?
# => true
```

* The `Proj4Data` module has been removed.
* When creating coordinate systems in RGeo factories, no longer use `proj4` option, instead use the `srid` option if an integer auth code works, or the `coord_sys` option if you want to use a string definition or `Proj4` object. This also applies to factories that used to use the `projection_proj4` option.

```ruby
require 'rgeo'
require 'rgeo/proj4'

cs = RGeo::CoordSys::Proj4.create(3857)
merc_fac = RGeo::Geos.factory(coord_sys: cs)
p merc_fac.srid
# => 3857
p merc_fac.coord_sys
# => #<RGeo::CoordSys::Proj4 "+proj=merc +a=6378137 +b=6378137 +lat_ts=0 +lon_0=0 +x_0=0 +y_0=0 +k=1 +units=m +nadgrids=@null +wktext +no_defs +type=crs">
p merc_fac.coord_sys.auth_name
# => "EPSG:3857"

merc_fac = RGeo::Geos.factory(srid: 3857)
p merc_fac.srid
# => 3857
p merc_fac.coord_sys
# => #<RGeo::CoordSys::Proj4 "+proj=merc +a=6378137 +b=6378137 +lat_ts=0 +lon_0=0 +x_0=0 +y_0=0 +k=1 +units=m +nadgrids=@null +wktext +no_defs +type=crs">
p merc_fac.coord_sys.auth_name
# => "EPSG:3857"

RGeo::Geos.factory(coord_sys: cs) == RGeo::Geos.factory(coord_sys: "EPSG:3857")
# => true
```
