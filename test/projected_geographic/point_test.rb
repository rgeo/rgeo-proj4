# frozen_string_literal: true

require "test_helper"
require "common/point_tests"

class TestPoint < Minitest::Test # :nodoc:
  include RGeo::Tests::Common::PointTests

  def setup
    @factory = RGeo::Geographic.projected_factory(buffer_resolution: 8, projection_proj4: "+proj=merc +a=6378137 +b=6378137 +lat_ts=0.0 +lon_0=0.0 +x_0=0.0 +y_0=0 +k=1.0 +units=m +nadgrids=@null +wktext +no_defs +type=crs", projection_srid: 3857)
    @zfactory = RGeo::Geographic.projected_factory(has_z_coordinate: true, projection_proj4: "+proj=merc +a=6378137 +b=6378137 +lat_ts=0.0 +lon_0=0.0 +x_0=0.0 +y_0=0 +k=1.0 +units=m +nadgrids=@null +wktext +no_defs +type=crs", projection_srid: 3857)
    @mfactory = RGeo::Geographic.projected_factory(has_m_coordinate: true, projection_proj4: "+proj=merc +a=6378137 +b=6378137 +lat_ts=0.0 +lon_0=0.0 +x_0=0.0 +y_0=0 +k=1.0 +units=m +nadgrids=@null +wktext +no_defs +type=crs", projection_srid: 3857)
    @zmfactory = RGeo::Geographic.projected_factory(has_z_coordinate: true, has_m_coordinate: true, projection_proj4: "+proj=merc +a=6378137 +b=6378137 +lat_ts=0.0 +lon_0=0.0 +x_0=0.0 +y_0=0 +k=1.0 +units=m +nadgrids=@null +wktext +no_defs +type=crs",
                                                    projection_srid: 3857)
  end

  def test_has_projection
    point = @factory.point(21, -22)
    assert(point.respond_to?(:projection))
  end

  def test_latlon
    point = @factory.point(21, -22)
    assert_equal(21, point.longitude)
    assert_equal(-22, point.latitude)
  end

  def test_srid
    point = @factory.point(11, 12)
    assert_equal(4326, point.srid)
  end

  def test_distance
    point1 = @factory.point(11, 12)
    point2 = @factory.point(11, 12)
    point3 = @factory.point(13, 12)
    assert_in_delta(0, point1.distance(point2), 0.0001)
    assert_in_delta(222_638, point1.distance(point3), 1)
  end
end
