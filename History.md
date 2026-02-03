### Ongoing

*** Breaking Changes**
* Minimum required Ruby version is now 3.1. #44

*** Minor Changes
* Add support for ruby 4.0 #44

**Bug Fixes**
* Avoid a segfault when forking (`Process.fork`). #40

### 4.0.0 / 2023-01-25

**Minor Changes**
* Change from malloc free to ruby_xfree in c extension. #38
* Add `MAINTAINER_MODE` and `DEBUG` flags for compilation. #37

### 4.0.0-rc.1 / 2022-10-11

**Breaking Changes**
* Raise `RGeo::Error::InvalidProjection` if PROJ cannot parse the input string when creating a projection. #26
* Raise `InvalidProjection` when a non-crs projection is attempting to create a `CRSToCRS` object. #26
* Remove `Proj4Data` module. #32
* Interface with RGeo V3 `coord_sys` handling. #33
* Compilation will fail if Proj is not found or too old of a version is found. #35

**Minor Changes**
* Add the `crs?` method to `Proj4` instances. #26
* `Proj4` implements `CoordSys::CS::CoordinateSystem` #32
* `CRSToCRS` implements `CoordSys::CS::CoordinateTransform` #32
* Integer SRIDs can be used to create `Proj4`s #32.

**Bug Fixes**
* Invalid PROJ definitions will no longer cause segfaults. #26

### 3.1.1 / 2021-11-08

* Move transform methods to `CRSToCRS` #23 (x4d3)

### 3.1.0 / 2021-10-12

* Introduce `CRSToCRS` class and `CRSStore` #20 (x4d3)
* Add Homebrew M1 installation directories to `extconf.rb` #22
* Fix `Psych.load` issue #21

### 3.0.1 / 2021-05-07

* Set `WKT_TYPE` macro based on PROJ version #14

### 3.0.0 / 2021-04-28

* Support Proj 6.2+ #10
* Add support for various projection representations #10
