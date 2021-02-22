# frozen_string_literal: true

require "test_helper"
require "common/multi_point_tests"

class TestMultiPoint < Minitest::Test # :nodoc:
  include RGeo::Tests::Common::MultiPointTests

  def create_factory(opts = {})
    RGeo::Geographic.projected_factory opts.merge \
      projection_proj4: "+proj=merc +a=6378137 +b=6378137 +lat_ts=0.0 +lon_0=0.0 "\
                        "+x_0=0.0 +y_0=0 +k=1.0 +units=m +nadgrids=@null +wktext +no_defs +type=crs",
      projection_srid: 3857
  end

  # These tests suffer from floating point issues
  undef_method :test_union
  undef_method :test_difference
  undef_method :test_intersection
end
