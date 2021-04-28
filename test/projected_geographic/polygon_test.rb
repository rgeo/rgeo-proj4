# frozen_string_literal: true

require "test_helper"
require "common/polygon_tests"

class TestPolygon < Minitest::Test # :nodoc:
  include RGeo::Tests::Common::PolygonTests

  def setup
    @factory = RGeo::Geographic.projected_factory(projection_proj4: "+proj=merc +a=6378137 +b=6378137 +lat_ts=0.0 +lon_0=0.0 +x_0=0.0 +y_0=0 +k=1.0 +units=m +nadgrids=@null +wktext +no_defs +type=crs", projection_srid: 3857)
  end
end

# Test that the projected_factory will still work with EPGS:3857 as crs input
class TestPolygonEPSG < Minitest::Test
  include RGeo::Tests::Common::PolygonTests

  def setup
    @factory = RGeo::Geographic.projected_factory(projection_proj4: "EPSG:3857", projection_srid: 3857)
  end
end
