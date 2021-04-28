# frozen_string_literal: true

require "test_helper"

class TestProj4SRSData < Minitest::Test # :nodoc:
  def test_nad83_4601 # rubocop:disable Naming/VariableNumber
    db_ = RGeo::CoordSys::SRSDatabase::Proj4Data.new("nad83")
    entry_ = db_.get(4601)
    assert_equal("proj=lcc  datum=NAD83 lon_0=-120d50 lat_1=48d44 lat_2=47d30 lat_0=47 x_0=500000 y_0=0 no_defs", entry_.proj4.original_str)
    assert_equal("4601: washington north: nad83", entry_.name)
  end
end
