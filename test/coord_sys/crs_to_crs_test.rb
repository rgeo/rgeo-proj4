# frozen_string_literal: true

require "test_helper"

class TestCrsToCrs < Minitest::Test # :nodoc:
  def from
    RGeo::CoordSys::Proj4.create("+proj=lcc +lat_1=49 +lat_2=44 +lat_0=46.5 +lon_0=3 +x_0=700000 +y_0=6600000 +ellps=GRS80 +towgs84=0,0,0,0,0,0,0 +units=m +no_defs +type=crs")
  end

  def to
    RGeo::CoordSys::Proj4.create("+proj=longlat +ellps=WGS84 +datum=WGS84 +no_defs +type=crs")
  end

  def test_transform_coords
    crs_to_crs = RGeo::CoordSys::CRSToCRS.create(from, to)
    a, b = crs_to_crs.transform_coords(733_345.6496818807, 6_750_247.713332973, nil)
    assert_close_enough(a, 3.4458703379573348)
    assert_close_enough(b, 47.85177684510492)
  end

  def test_store
    crs_to_crs1 = RGeo::CoordSys::CRSStore.get(from, to)
    crs_to_crs2 = RGeo::CoordSys::CRSStore.get(from, RGeo::CoordSys::Proj4.create("+proj=longlat +ellps=WGS84 +datum=WGS84 +no_defs +type=crs"))
    crs_to_crs3 = RGeo::CoordSys::CRSStore.get(to, from)
    assert(crs_to_crs1, "crs_to_crs must not be nil")
    assert_equal(crs_to_crs1, crs_to_crs2)
    refute_equal(crs_to_crs1, crs_to_crs3)
  end
end
