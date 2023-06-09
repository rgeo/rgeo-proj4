# frozen_string_literal: true

require_relative "test_helper"
require "timeout"

class NonRegressionTest < Minitest::Test
  # When this test fail, you should end up with a segv or this test will
  # hang forever. In both cases, you'll see that there is an issue. Note
  # that it does not fail systematically, so running it ~10 times will
  # help you be sure that you are not regressing on that topic again.
  #
  # See https://github.com/rgeo/rgeo-proj4/issues/39.
  def test_forking_issue39
    RGeo::CoordSys::Proj4.create("EPSG:4326")
    pid = Process.fork {}
    Process.wait pid
  ensure
    begin
      Process.kill(9, pid)
    rescue Errno::ESRCH # rubocop:disable Lint/SuppressedException
    end
  end
end
