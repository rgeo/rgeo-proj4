# frozen_string_literal: true

module RGeo
  # All RGeo errors are members of this namespace.

  module Error
    # Base class for all RGeo-related exceptions
    class RGeoError < RuntimeError
    end

    # RGeo error specific to the PROJ library
    class InvalidProjection < RGeoError
    end
  end
end
