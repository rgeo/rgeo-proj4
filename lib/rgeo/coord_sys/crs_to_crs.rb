# frozen_string_literal: true

require "singleton"
module RGeo
  module CoordSys
    # This is a Ruby wrapper around a proj crs_to_crs
    # A crs_to_crs transformation object is a pipeline between two known coordinate reference systems.
    # https://proj.org/development/reference/functions.html#c.proj_create_crs_to_crs
    #
    # It also inherits from the RGeo::CoordSys::CoordinateTransform abstract class.
    class CRSToCRS < CS::CoordinateTransform
      attr_accessor :source_cs, :target_cs

      class << self
        def create(from, to)
          crs_to_crs = _create(from, to)
          crs_to_crs.source_cs = from
          crs_to_crs.target_cs = to
          crs_to_crs
        end
      end

      alias from source_cs
      alias to target_cs
      alias to_wkt _as_text

      # transform the coordinates from the initial CRS to the destination CRS
      def transform_coords(x, y, z)
        if from._radians? && from._geographic?
          x *= ImplHelper::Math::DEGREES_PER_RADIAN
          y *= ImplHelper::Math::DEGREES_PER_RADIAN
        end
        result = _transform_coords(x, y, z)
        if result && to._radians? && to._geographic?
          result[0] *= ImplHelper::Math::RADIANS_PER_DEGREE
          result[1] *= ImplHelper::Math::RADIANS_PER_DEGREE
        end
        result
      end

      def transform(from_geometry, to_factory)
        case from_geometry
        when Feature::Point
          transform_point(from_geometry, to_factory)
        when Feature::Line
          to_factory.line(from_geometry.points.map { |p| transform_point(p, to_factory) })
        when Feature::LinearRing
          transform_linear_ring(from_geometry, to_factory)
        when Feature::LineString
          to_factory.line_string(from_geometry.points.map { |p_| transform_point(p_, to_factory) })
        when Feature::Polygon
          transform_polygon(from_geometry, to_factory)
        when Feature::MultiPoint
          to_factory.multi_point(from_geometry.map { |p| transform_point(p, to_factory) })
        when Feature::MultiLineString
          to_factory.multi_line_string(from_geometry.map { |g| transform(g, to_factory) })
        when Feature::MultiPolygon
          to_factory.multi_polygon(from_geometry.map { |p| transform_polygon(p, to_factory) })
        when Feature::GeometryCollection
          to_factory.collection(from_geometry.map { |g| transform(g, to_factory) })
        end
      end

      def transform_point(from_point, to_factory)
        from_factory_ = from_point.factory
        from_has_z_ = from_factory_.property(:has_z_coordinate)
        from_has_m_ = from_factory_.property(:has_m_coordinate)
        to_has_z_ = to_factory.property(:has_z_coordinate)
        to_has_m_ = to_factory.property(:has_m_coordinate)
        coords_ = transform_coords(from_point.x, from_point.y, from_has_z_ ? from_point.z : nil)
        return unless coords_
        extras_ = []
        extras_ << coords_[2].to_f if to_has_z_
        if to_has_m_
          extras_ << from_has_m_ ? from_point.m : 0.0
        end
        to_factory.point(coords_[0], coords_[1], *extras_)
      end

      def transform_linear_ring(from_ring_, to_factory_)
        to_factory_.linear_ring(from_ring_.points[0..-2].map { |p_| transform_point(p_, to_factory_) })
      end

      def transform_polygon(from_polygon_, to_factory_)
        ext_ = transform_linear_ring(from_polygon_.exterior_ring, to_factory_)
        int_ = from_polygon_.interior_rings.map { |r_| transform_linear_ring(r_, to_factory_) }
        to_factory_.polygon(ext_, int_)
      end

      def inspect
        "#<#{self.class}:0x#{object_id.to_s(16)} @source_cs=#{source_cs.original_str} @target_cs=#{target_cs.original_str}>"
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
