# `rgeo-proj4`

[![Gem Version](https://badge.fury.io/rb/rgeo-proj4.svg)](http://badge.fury.io/rb/rgeo-proj4)
[![Build Status](https://travis-ci.org/rgeo/rgeo-proj4.svg?branch=master)](https://travis-ci.org/rgeo/rgeo-proj4)

This project contains proj.4 extensions to the [rgeo gem](https://github.com/rgeo/rgeo).

Documentation about `proj.4` is available at [http://proj4.org/](http://proj4.org/).

## Installation

### Install PROJ

Install `proj` using your package manager:

#### Homebrew

```sh
brew install proj
```

#### Ubuntu/Debian

```sh
apt-get install libproj-dev proj-bin
```

Or download binaries at https://proj.org/

Note that version 3.x requires PROJ 6.2+. This should be the default on most systems, but in some cases, specific repositories will need to be added to the package manager.

Add this line to your Gemfile:

```ruby
gem "rgeo-proj4"
```

And then execute:

    $ bundle

Or install it yourself as:

    $ gem install rgeo-proj4

By default, the gem looks for the Proj4 library in the following paths:

```
/usr/local
/usr/local/proj
/usr/local/proj4
/opt/local
/opt/proj
/opt/proj4
/opt
/usr
/Library/Frameworks/PROJ.framework/unix
```

If Proj4 is installed in a different location, you must provide its
installation prefix directory using the `--with-proj-dir` option.

## Usage

The `rgeo-proj4` gem can be used by defining `CoordSys::Proj4` objects, as a part of an `RGeo::Geographic.projected_factory`, or as an attribute of other factories.

### RGeo::CoordSys::Proj4

This is the lowest level module to transform between coordinate systems and all of the other methods ultimately rely on this object. The object is created with a [valid PROJ definition](https://proj.org/development/reference/functions.html#c.proj_create) which is used to define a coordinate reference system (CRS). Note that 2 `Proj4` objects need to be defined to transform between CRS's.

In addition to allowing transformations, this object can return information about the CRS.

```ruby
require 'rgeo'
require 'rgeo/proj4'

# define CRS's
geography = RGeo::CoordSys::Proj4.create("EPSG:4326")
projection = RGeo::CoordSys::Proj4.create("EPSG:3857")

x,y = RGeo::CoordSys::Proj4.transform_coords(projection, geography, -8367354.015764384, 4859054.160863457, nil)

p x
# => -75.16522
p y
# => 39.95258299
```

Other information can be shown from the `Proj4` object:

```ruby
require 'rgeo'
require 'rgeo/proj4'

projection = RGeo::CoordSys::Proj4.create("EPSG:3857")
p projection.canconical_str
# => "+proj=merc +a=6378137 +b=6378137 +lat_ts=0 +lon_0=0 +x_0=0 +y_0=0 +k=1 +units=m +nadgrids=@null +wktext +no_defs +type=crs"

p projection.auth_name
# => "EPSG:3857"

p projection.as_text
# => PROJCRS[\"WGS 84 / Pseudo-Mercator\",BASEGEOGCRS[\"WGS 84\",DATUM[\"World Geodetic System 1984\",ELLIPSOID[\"WGS 84\",6378137,298.257223563,LENGTHUNIT[\"metre\",1]]],PRIMEM[\"Greenwich\",0,ANGLEUNIT[\"degree\",0.0174532925199433]],ID[\"EPSG\",4326]],CONVERSION[\"Popular Visualisation Pseudo-Mercator\",METHOD[\"Popular Visualisation Pseudo Mercator\",ID[\"EPSG\",1024]],PARAMETER[\"Latitude of natural origin\",0,ANGLEUNIT[\"degree\",0.0174532925199433],ID[\"EPSG\",8801]],PARAMETER[\"Longitude of natural origin\",0,ANGLEUNIT[\"degree\",0.0174532925199433],ID[\"EPSG\",8802]],PARAMETER[\"False easting\",0,LENGTHUNIT[\"metre\",1],ID[\"EPSG\",8806]],PARAMETER[\"False northing\",0,LENGTHUNIT[\"metre\",1],ID[\"EPSG\",8807]]],CS[Cartesian,2],AXIS[\"easting (X)\",east,ORDER[1],LENGTHUNIT[\"metre\",1]],AXIS[\"northing (Y)\",north,ORDER[2],LENGTHUNIT[\"metre\",1]],USAGE[SCOPE[\"unknown\"],AREA[\"World - 85\xC2\xB0S to 85\xC2\xB0N\"],BBOX[-85.06,-180,85.06,180]],ID[\"EPSG\",3857]]
```

### Projected Factory

The projected factory is a compound geographic factory that is useful for converting from lon/lat to the specified CRS.

```ruby
require 'rgeo'
require 'rgeo/proj4'

factory = RGeo::Geographic.projected_factory(projection_proj4: "EPSG:3857", projection_srid: 3857)

p factory.projection_factory
# => #<RGeo::Geos::CAPIFactory srid=3857 bufres=1 flags=8>

p factory.projection_factory.proj4
# => #<RGeo::CoordSys::Proj4 "+proj=merc +a=6378137 +b=6378137 +lat_ts=0 +lon_0=0 +x_0=0 +y_0=0 +k=1 +units=m +nadgrids=@null +wktext +no_defs +type=crs">

p factory.projection_factory.proj4.auth_name
# => "EPSG:3857"

pt = factory.point(-75.16522, 39.95258299)
p pt.projection
# => #<RGeo::Geos::CAPIPointImpl "POINT (-8367354.015764384 4859054.159411294)">

p factory.unproject(pt.projection)
# => #<RGeo::Geographic::ProjectedPointImpl "POINT (-75.16522 39.952582989999996)">
```

### Feature::Cast

This method allows you to perform projections between more than just a lon/lat system. As long as 2 factories with valid Proj4 CRS's are defined, it can project between the CRS's.

```ruby
require 'rgeo'
require 'rgeo/proj4'

geography = RGeo::Geos.factory(proj4: "EPSG:4326", srid: 4326)
projection = RGeo::Geos.factory(proj4: "EPSG:3857", srid: 3857)

p geography.proj4.auth_name
# => "EPSG:4326"
p projection.proj4.auth_name
# => "EPSG:3857"

proj_point = projection.parse_wkt("POINT (-8367354.015764384 4859054.159411294)")

geo_point = RGeo::Feature.cast(proj_point, project: true, factory: geography)
p geo_point
# => #<RGeo::Geos::CAPIPointImpl "POINT (-75.16522 39.952582989999996)">

proj_point2 = RGeo::Feature.cast(geo_point, project: true, factory: projection)

p proj_point == proj_point2
# => true
```

## Development

After checking out the repo, run `bin/setup` to install dependencies. Then, run `rake test` to run
the tests. You can also run `bin/console` for an interactive prompt that will allow you to experiment.

To install this gem onto your local machine, run `bundle exec rake install`. To release a new version,
update the version number in `version.rb`, and then run `bundle exec rake release`, which will create
a git tag for the version, push git commits and tags, and push the `.gem` file to
[rubygems.org](https://rubygems.org).

## Contributing

Bug reports and pull requests are welcome on GitHub at https://github.com/rgeo/rgeo-proj4.
This project is intended to be a safe, welcoming space for collaboration, and contributors are
expected to adhere to the [Contributor Covenant](http://contributor-covenant.org) code of conduct.

## License

The gem is available as open source under the terms of the
[MIT License](https://opensource.org/licenses/MIT).

## Code of Conduct

Everyone interacting in the `rgeo-proj4` project’s codebases, issue trackers, chat rooms and mailing
lists is expected to follow the
[code of conduct](https://github.com/rgeo/rgeo-proj4/blob/master/CODE_OF_CONDUCT.md).
