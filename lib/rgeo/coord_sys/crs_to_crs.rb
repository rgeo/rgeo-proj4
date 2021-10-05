# frozen_string_literal: true

require "singleton"
module RGeo
  module CoordSys
    # This is a Ruby wrapper around a proj crs_to_crs
    # A crs_to_crs transformation object is a pipeline between two known coordinate reference systems.
    # https://proj.org/development/reference/functions.html#c.proj_create_crs_to_crs
    class CRSToCRS
      # transform the coordinates from the initial CRS to the destination CRS
      def transform_coords(x, y, z)
        _transform_coords(x, y, z)
      end

      class << self
        def create(from, to)
          _create(from, to)
        end
      end
    end

    # Store of all the created CRSToCRS
    class CRSStore
      include Singleton
      class << self
        def get(from, to)
          instance.get(from, to)
        end
      end

      Key = Struct.new(:from, :to)

      def initialize
        @store = Hash.new { |h, k| h[k] = CRSToCRS.create(k.from, k.to) }
        @semaphore = Mutex.new
      end

      def get(from, to)
        @semaphore.synchronize do
          @store[Key.new(from, to)]
        end
      end
    end
  end
end
