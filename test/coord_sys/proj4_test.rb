# frozen_string_literal: true

require "test_helper"

class TestProj4 < Minitest::Test # :nodoc:
  def test_proj4_version
    assert_kind_of String, RGeo::CoordSys::Proj4.version
    # assert_match(/^\d+\.\d+(\.\d+)?$/, RGeo::CoordSys::Proj4.version)
  end

  def test_create_wgs84
    proj = RGeo::CoordSys::Proj4.create("+proj=longlat +ellps=WGS84 +datum=WGS84 +no_defs +type=crs")
    assert_equal(true, proj.geographic?)
    assert_equal("+proj=longlat +ellps=WGS84 +datum=WGS84 +no_defs +type=crs", proj.original_str)
    assert_equal("+proj=longlat +datum=WGS84 +no_defs +type=crs", proj.canonical_str)
  end

  def test_as_text
    proj = RGeo::CoordSys::Proj4.create("EPSG:3857")
    assert_equal(true, proj.as_text.include?("ID[\"EPSG\",3857]]"))
  end

  def test_auth_name
    proj = RGeo::CoordSys::Proj4.create("EPSG:4326")
    assert_equal("EPSG:4326", proj.auth_name)

    merc_wkt = <<~STR
      PROJCS["WGS 84 / Pseudo-Mercator",GEOGCS["WGS 84",DATUM["WGS_1984",SPHEROID["WGS 84",6378137,298.257223563,AUTHORITY["EPSG","7030"]],AUTHORITY["EPSG","6326"]],PRIMEM["Greenwich",0,AUTHORITY["EPSG","8901"]],UNIT["degree",0.0174532925199433,AUTHORITY["EPSG","9122"]],AUTHORITY["EPSG","4326"]],PROJECTION["Mercator_1SP"],PARAMETER["central_meridian",0],PARAMETER["scale_factor",1],PARAMETER["false_easting",0],PARAMETER["false_northing",0],UNIT["metre",1,AUTHORITY["EPSG","9001"]],AXIS["X",EAST],AXIS["Y",NORTH],EXTENSION["PROJ4","+proj=merc +a=6378137 +b=6378137 +lat_ts=0.0 +lon_0=0.0 +x_0=0.0 +y_0=0 +k=1.0 +units=m +nadgrids=@null +wktext  +no_defs"],AUTHORITY["EPSG","3857"]]
    STR
    proj = RGeo::CoordSys::Proj4.create(merc_wkt)
    assert_equal("EPSG:3857", proj.auth_name)

    proj = RGeo::CoordSys::Proj4.create("+proj=longlat +ellps=WGS84 +datum=WGS84 +lat_ts=5.0 +no_defs +type=crs")
    assert_nil(proj.auth_name)
  end

  def test_get_wgs84_geographic
    proj = RGeo::CoordSys::Proj4.create("+proj=longlat +ellps=WGS84 +datum=WGS84 +no_defs +type=crs")
    proj2 = proj.get_geographic
    assert_nil(proj2.original_str)
    assert_equal(true, proj2.geographic?)
    coords = RGeo::CoordSys::Proj4.transform_coords(proj, proj2, 1, 2, 0)
    assert_equal([1, 2, 0], coords)
  end

  def test_identity_transform
    proj = RGeo::CoordSys::Proj4.create("+proj=longlat +ellps=WGS84 +datum=WGS84 +no_defs +type=crs")
    assert_equal([1, 2, 0], RGeo::CoordSys::Proj4.transform_coords(proj, proj, 1, 2, 0))
    assert_equal([1, 2], RGeo::CoordSys::Proj4.transform_coords(proj, proj, 1, 2, nil))
  end

  def test_simple_mercator_transform
    geography = RGeo::CoordSys::Proj4.create("+proj=longlat +ellps=WGS84 +datum=WGS84 +no_defs +type=crs", radians: true)
    projection = RGeo::CoordSys::Proj4.create("+proj=merc +a=6378137 +b=6378137 +lat_ts=0.0 +lon_0=0.0 +x_0=0.0 +y_0=0 +k=1.0 +units=m +nadgrids=@null +wktext +no_defs +type=crs")
    assert_xy_close(project_merc(0, 0), RGeo::CoordSys::Proj4.transform_coords(geography, projection, 0, 0, nil))
    assert_xy_close(project_merc(0.01, 0.01), RGeo::CoordSys::Proj4.transform_coords(geography, projection, 0.01, 0.01, nil))
    assert_xy_close(project_merc(1, 1), RGeo::CoordSys::Proj4.transform_coords(geography, projection, 1, 1, nil))
    assert_xy_close(project_merc(-1, -1), RGeo::CoordSys::Proj4.transform_coords(geography, projection, -1, -1, nil))
    assert_xy_close(unproject_merc(0, 0), RGeo::CoordSys::Proj4.transform_coords(projection, geography, 0, 0, nil))
    assert_xy_close(unproject_merc(10_000, 10_000), RGeo::CoordSys::Proj4.transform_coords(projection, geography, 10_000, 10_000, nil))
    assert_xy_close(unproject_merc(-20_000_000, -20_000_000), RGeo::CoordSys::Proj4.transform_coords(projection, geography, -20_000_000, -20_000_000, nil))
  end

  def test_equivalence
    proj1 = RGeo::CoordSys::Proj4.create("+proj=longlat +ellps=WGS84 +datum=WGS84 +no_defs +type=crs")
    proj2 = RGeo::CoordSys::Proj4.create(" +proj=longlat +ellps=WGS84 +datum=WGS84 +no_defs +type=crs")
    assert_equal(proj1, proj2)
  end

  def test_hashes_equal_for_equivalent_objects
    proj1 = RGeo::CoordSys::Proj4.create("+proj=longlat +ellps=WGS84 +datum=WGS84 +no_defs +type=crs")
    proj2 = RGeo::CoordSys::Proj4.create(" +proj=longlat +ellps=WGS84 +datum=WGS84 +no_defs +type=crs")
    assert_equal(proj1.hash, proj2.hash)
  end

  def test_point_projection_cast
    geography = RGeo::Geos.factory(proj4: "+proj=longlat +ellps=WGS84 +datum=WGS84 +no_defs +type=crs", srid: 4326)
    projection = RGeo::Geos.factory(proj4: "+proj=tmerc +lat_0=49 +lon_0=-2 +k=0.9996012717 +x_0=400000 +y_0=-100000 +ellps=airy +datum=OSGB36 +units=m +no_defs +type=crs", srid: 27_700)
    proj_point = projection.parse_wkt("POINT(473600.5000000000000000 186659.7999999999883585)")
    geo_point = RGeo::Feature.cast(proj_point, project: true, factory: geography)
    assert_close_enough(-0.9393598527244420, geo_point.x)
    assert_close_enough(51.5740106527552697, geo_point.y)
  end

  def test_point_transform_lowlevel
    geography = RGeo::Geos.factory(proj4: "EPSG:4326", srid: 4326)
    projection = RGeo::Geos.factory(proj4: "EPSG:27700", srid: 27_700)
    proj_point = projection.parse_wkt("POINT(473600.5000000000000000 186659.7999999999883585)")
    geo_point = RGeo::CoordSys::Proj4.transform(projection.proj4, proj_point, geography.proj4, geography)
    assert_close_enough(-0.9393598527244420, geo_point.x)
    assert_close_enough(51.5740106527552697, geo_point.y)
  end

  def test_geocentric
    obj1 = RGeo::CoordSys::Proj4.create("+proj=geocent +ellps=WGS84 +type=crs")
    assert_equal(true, obj1.geocentric?)
  end

  def test_get_geographic
    projection = RGeo::CoordSys::Proj4.create("+proj=merc +a=6378137 +b=6378137 +lat_ts=0.0 +lon_0=0.0 +x_0=0.0 +y_0=0 +k=1.0 +units=m +nadgrids=@null +wktext +no_defs +type=crs")
    geographic = projection.get_geographic
    expected = RGeo::CoordSys::Proj4.create("+proj=longlat +datum=WGS84 +no_defs +type=crs")
    assert_equal(expected, geographic)
  end

  def test_marshal_roundtrip
    obj1 = RGeo::CoordSys::Proj4.create("+proj=longlat +ellps=WGS84 +datum=WGS84 +no_defs +type=crs")
    dump = ::Marshal.dump(obj1)
    obj2 = ::Marshal.load(dump)
    assert_equal(obj1, obj2)
  end

  def test_dup
    obj1 = RGeo::CoordSys::Proj4.create("+proj=longlat +ellps=WGS84 +datum=WGS84 +no_defs +type=crs")
    obj2 = obj1.dup
    assert_equal(obj1, obj2)
  end

  def test_dup_of_get_geographic
    obj1 = RGeo::CoordSys::Proj4.create("+proj=latlong +datum=WGS84 +ellps=WGS84 +type=crs")
    obj2 = obj1.get_geographic
    obj3 = obj2.dup
    assert_equal(obj1, obj3)
  end

  def test_yaml_roundtrip
    obj1 = RGeo::CoordSys::Proj4.create("+proj=longlat +ellps=WGS84 +datum=WGS84 +no_defs +type=crs")
    dump = Psych.dump(obj1)
    obj2 = Psych.load(dump)
    assert_equal(obj1, obj2)
  end

  private

  def project_merc(x, y)
    [x * 6_378_137.0, Math.log(Math.tan(Math::PI / 4.0 + y / 2.0)) * 6_378_137.0]
  end

  def unproject_merc(x, y)
    [x / 6_378_137.0, (2.0 * Math.atan(Math.exp(y / 6_378_137.0)) - Math::PI / 2.0)]
  end

  def assert_close_enough(a, b)
    delta = Math.sqrt(a * a + b * b) * 0.00000001
    delta = 1e-7 if delta < 1e-7
    assert_in_delta(a, b, delta)
  end

  def assert_xy_close(xy1, xy2)
    assert_close_enough(xy1[0], xy2[0])
    assert_close_enough(xy1[1], xy2[1])
  end
end
