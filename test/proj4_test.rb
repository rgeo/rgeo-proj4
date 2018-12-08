# frozen_string_literal: true

require "test_helper"

class Proj4Test < Minitest::Test
  def test_gem_version
    assert_match(/^\d+\.\d+(\.\d+)(\.rc\d+)?$/, RGeo::Proj4::VERSION)
  end
end
