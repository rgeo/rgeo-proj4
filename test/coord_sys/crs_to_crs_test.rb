# frozen_string_literal: true

require "test_helper"

class TestCrsToCrs < Minitest::Test # :nodoc:
  def from
    RGeo::CoordSys::Proj4.create("+proj=lcc +lat_1=49 +lat_2=44 +lat_0=46.5 +lon_0=3 +x_0=700000 +y_0=6600000 +ellps=GRS80 +towgs84=0,0,0,0,0,0,0 +units=m +no_defs +type=crs")
  end

  def to
    RGeo::CoordSys::Proj4.create("+proj=longlat +ellps=WGS84 +datum=WGS84 +no_defs +type=crs")
  end

  def test_inheritance
    crs_to_crs = RGeo::CoordSys::CRSToCRS.create(from, to)
    assert(crs_to_crs.is_a?(RGeo::CoordSys::CRSToCRS))
    assert(crs_to_crs.is_a?(RGeo::CoordSys::CS::CoordinateTransform))
  end

  def test_to_wkt
    crs_to_crs = RGeo::CoordSys::CRSToCRS.create(from, to)
    assert(crs_to_crs.to_wkt.include?("CONCATENATEDOPERATION"))
  end

  def test_wkt_typename
    crs_to_crs = RGeo::CoordSys::CRSToCRS.create(from, to)
    assert_equal("CONCATENATEDOPERATION", crs_to_crs.wkt_typename)
  end

  def test_transform_type
    crs_to_crs = RGeo::CoordSys::CRSToCRS.create(from, to)
    assert_equal("PJ_TYPE_CONCATENATED_OPERATION", crs_to_crs.transform_type)
  end

  def test_area_of_use
    crs_to_crs = RGeo::CoordSys::CRSToCRS.create(from, to)
    assert_equal("World", crs_to_crs.area_of_use)
  end

  def test_identity
    crs_to_crs1 = RGeo::CoordSys::CRSToCRS.create(from, to)
    refute(crs_to_crs1.identity?)

    crs_to_crs2 = RGeo::CoordSys::CRSToCRS.create(from, from)
    assert(crs_to_crs2.identity?)

    # test same crs, but defined differently
    merc_proj_str = "+proj=merc +a=6378137 +b=6378137 +lat_ts=0 +lon_0=0 +x_0=0 +y_0=0 +k=1 +units=m +nadgrids=@null +wktext +no_defs +type=crs"
    merc_auth_code = "EPSG:3857"
    from_proj = RGeo::CoordSys::Proj4.create(merc_proj_str)
    to_proj = RGeo::CoordSys::Proj4.create(merc_auth_code)
    crs_to_crs3 = RGeo::CoordSys::CRSToCRS.create(from_proj, to_proj)
    assert(crs_to_crs3.identity?)
  end

  def test_inverse
    crs_to_crs = RGeo::CoordSys::CRSToCRS.create(from, to)
    inverse_crs_to_crs = crs_to_crs.inverse

    assert_equal(crs_to_crs.source_cs, inverse_crs_to_crs.target_cs)
    assert_equal(crs_to_crs.target_cs, inverse_crs_to_crs.source_cs)
  end

  def test_transform_coords
    crs_to_crs = RGeo::CoordSys::CRSToCRS.create(from, to)
    a, b = crs_to_crs.transform_coords(733_345.6496818807, 6_750_247.713332973, nil)
    assert_close_enough(a, 3.4458703379573348)
    assert_close_enough(b, 47.85177684510492)
  end

  def test_transform_invalid
    # https://github.com/rgeo/rgeo-proj4/issues/25
    non_crs_proj_str = "+proj=merc +lat_ts=56.5 +ellps=GRS80"
    proj1 = RGeo::CoordSys::Proj4.create(non_crs_proj_str)
    proj2 = RGeo::CoordSys::Proj4.create("EPSG:3857")

    assert_raises(RGeo::Error::InvalidProjection) do
      RGeo::CoordSys::Proj4.transform_coords(proj1, proj2, 1, 2, nil)
    end

    assert_raises(RGeo::Error::InvalidProjection) do
      RGeo::CoordSys::Proj4.transform_coords(proj2, proj1, 1, 2, nil)
    end

    assert_raises(RGeo::Error::InvalidProjection) do
      RGeo::CoordSys::CRSToCRS.create(proj1, proj2)
    end

    assert_raises(RGeo::Error::InvalidProjection) do
      RGeo::CoordSys::CRSToCRS.create(proj2, proj1)
    end
  end

  def test_transform_lsit
    crs_to_crs = RGeo::CoordSys::CRSToCRS.create(from, to)
    points = [[733_345.6496818807, 6_750_247.713332973]]

    proj_points = crs_to_crs.transform_list(points)
    a, b = proj_points[0]
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
