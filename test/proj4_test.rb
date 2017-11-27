require "test_helper"

class Proj4Test < Test::Unit::TestCase
  def test_gem_version
    assert_match(/^\d+\.\d+(\.\d+)(\.rc\d+)?$/, ::RGeo::Proj4::VERSION)
  end
end
