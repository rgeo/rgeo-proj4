# frozen_string_literal: true

require "test_helper"

class Proj4Test < Minitest::Test
  def test_gem_version
    assert_match(/^\d+\.\d+(\.\d+)(-rc.\d+)?$/, RGeo::Proj4::VERSION)
  end

  if RGeo::CoordSys::Proj4.supported?
    def test_default_coord_sys_class_override
      assert_equal(RGeo::CoordSys::CONFIG.default_coord_sys_class, RGeo::CoordSys::Proj4)
    end
  end
end
