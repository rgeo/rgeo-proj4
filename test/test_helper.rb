# frozen_string_literal: true

require "minitest/autorun"
require "rgeo/proj4"
require "common/factory_tests"
require "psych"
require "pry-byebug"

# Only here for Psych 4.0.0 breaking change.
# See https://github.com/ruby/psych/pull/487
def psych_load(*args)
  if Psych.respond_to?(:unsafe_load)
    Psych.unsafe_load(*args)
  else
    Psych.load(*args)
  end
end
