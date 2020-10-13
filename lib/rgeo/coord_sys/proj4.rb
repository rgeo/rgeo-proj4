# frozen_string_literal: true

# -----------------------------------------------------------------------------
#
# Proj4 wrapper for RGeo
#
# -----------------------------------------------------------------------------

module RGeo
  module CoordSys
    module Proj
      module Api
        extend FFI::Library
        ffi_lib '/usr/local/lib/libproj.19.dylib'

        typedef :pointer, :PJ
        typedef :pointer, :PJ_CONTEXT
        typedef :pointer, :PJ_AREA

        # enum :PJ_TYPE,
        #   %i[
        #     PJ_TYPE_UNKNOWN
        #     PJ_TYPE_ELLIPSOID
        #     PJ_TYPE_PRIME_MERIDIAN
        #     PJ_TYPE_GEODETIC_REFERENCE_FRAME
        #     PJ_TYPE_DYNAMIC_GEODETIC_REFERENCE_FRAME
        #     PJ_TYPE_VERTICAL_REFERENCE_FRAME
        #     PJ_TYPE_DYNAMIC_VERTICAL_REFERENCE_FRAME
        #     PJ_TYPE_DATUM_ENSEMBLE
        #     PJ_TYPE_CRS
        #     PJ_TYPE_GEODETIC_CRS
        #     PJ_TYPE_GEOCENTRIC_CRS
        #     PJ_TYPE_GEOGRAPHIC_CRS
        #     PJ_TYPE_GEOGRAPHIC_2D_CRS
        #     PJ_TYPE_GEOGRAPHIC_3D_CRS
        #     PJ_TYPE_VERTICAL_CRS
        #     PJ_TYPE_PROJECTED_CRS
        #     PJ_TYPE_COMPOUND_CRS
        #     PJ_TYPE_TEMPORAL_CRS
        #     PJ_TYPE_ENGINEERING_CRS
        #     PJ_TYPE_BOUND_CRS
        #     PJ_TYPE_OTHER_CRS
        #     PJ_TYPE_CONVERSION
        #     PJ_TYPE_TRANSFORMATION
        #     PJ_TYPE_CONCATENATED_OPERATION
        #     PJ_TYPE_OTHER_COORDINATE_OPERATION
        #   ]
        enum :PJ_DIRECTION, [:PJ_FWD, 1, :PJ_IDENT, 0, :PJ_INV, -1]

        class PJ_XYZT < FFI::Struct
          layout :x, :double, :y, :double, :z, :double, :t, :double
        end

        class PJ_UVWT < FFI::Struct
          layout :u, :double, :v, :double, :w, :double, :t, :double
        end

        class PJ_LPZT < FFI::Struct
          layout :lam, :double, :phi, :double, :z, :double, :t, :double
        end

        # Rotations: omega, phi, kappa
        class PJ_OPK < FFI::Struct
          layout :o, :double, :p, :double, :k, :double
        end

        # East, North, Up
        class PJ_ENU < FFI::Struct
          layout :e, :double, :n, :double, :u, :double
        end

        # Geodesic length, fwd azi, rev azi
        class PJ_GEOD < FFI::Struct
          layout :s, :double, :a1, :double, :a2, :double
        end

        class PJ_UV < FFI::Struct
          layout :u, :double, :v, :double
        end

        class PJ_XY < FFI::Struct
          layout :x, :double, :y, :double
        end

        class PJ_LP < FFI::Struct
          layout :lam, :double, :phi, :double
        end

        class PJ_XYZ < FFI::Struct
          layout :x, :double, :y, :double, :z, :double
        end

        class PJ_UVW < FFI::Struct
          layout :u, :double, :v, :double, :w, :double
        end

        class PJ_LPZ < FFI::Struct
          layout :lam, :double, :phi, :double, :z, :double
        end

        class PJ_COORD < FFI::Union
          layout :v,
                 [:double, 4],
                 :xyzt, PJ_XYZT,
                 :uvwt, PJ_UVWT,
                 :lpzt, PJ_LPZT,
                 :geod, PJ_GEOD,
                 :opk, PJ_OPK,
                 :enu, PJ_ENU,
                 :xyz, PJ_XYZ,
                 :uvw, PJ_UVW,
                 :lpz, PJ_LPZ,
                 :xy, PJ_XY,
                 :uv, PJ_UV,
                 :lp, PJ_LP
        end

        class PJ_INFO < FFI::Struct
          layout :major, :int, # Major release number
                 :minor, :int,  # Minor release number
                 :patch, :int,  # Patch level
                 :release, :string,  # Release info. Version + date
                 :version, :string,   # Full version number
                 :searchpath, :string,  # Paths where init and grid files are looked for. Paths are separated by
                                        # semi-colons on Windows, and colons on non-Windows platforms.
                 :paths, :pointer,
                 :path_count, :size_t
        end

        class PJ_PROJ_INFO < FFI::Struct
          layout :id, :string, # Name of the projection in question
            :description, :string, # Description of the projection
            :definition, :string, # Projection definition
            :has_inverse, :bool, # 1 if an inverse mapping exists, 0 otherwise
            :accuracy, :double # Expected accuracy of the transformation. -1 if unknown.

          def to_s
            "<#{self.class.name} id: #{self[:id]},  description: #{self[:description]}, definition: #{self[:definition]}, has_inverse: #{self[:has_inverse]} accuracy: #{self[:accuracy]}"
          end
        end

        attach_function :proj_info, [], PJ_INFO.by_value
        attach_function :proj_create, %i[PJ_CONTEXT string], :PJ
        attach_function :proj_destroy, %i[PJ], :PJ
        attach_function :proj_pj_info, %i[PJ], PJ_PROJ_INFO.by_value
        attach_function :proj_angular_output, %i[PJ PJ_DIRECTION], :bool
        attach_function :proj_create_crs_to_crs, %i[PJ_CONTEXT string string PJ_AREA], :PJ
        attach_function :proj_trans, [:PJ, :PJ_DIRECTION, PJ_COORD.by_value], PJ_COORD.by_value
      end

      class Pj
        def self.finalize(pointer)
          # TODO: why we need a proc here?
          proc { Api.proj_destroy(pointer) }
        end

        attr_reader :original_str

        def initialize(definition, radians = false)
          @radians = radians
          @original_str = definition
          @pointer = Api.proj_create(nil, definition)
          ObjectSpace.define_finalizer(self, self.class.finalize(@pointer))
        end

        def radians?
          @radians
        end

        def geographic?
          angular?
        end

        def to_ptr
          pointer
        end

        def canonical_str
          info[:definition].force_encoding('UTF-8')
        end

        def ==(other)
          self.class == other.class && canonical_hash == other.canonical_hash &&
            radians? == other.radians? &&
            id == other.id
        end

        def id
          info[:id]
        end

        def canonical_hash
          unless defined?(@canonical_hash)
            @canonical_hash = {}
            canonical_str.strip.split(/\s+/).each do |elem_|
              @canonical_hash[Regexp.last_match(1)] = Regexp.last_match(3) if elem_ =~ /^\+(\w+)(=(\S+))?$/
            end
          end
          @canonical_hash
        end

        def hash
          canonical_hash.hash
        end

        alias eql? ==

        private

        def info
          Api.proj_pj_info(self)
        end

        def angular?
          # Inverting this fixed the x value.
          Api.proj_angular_output(self, :PJ_INV)
        end

        attr_reader :pointer
      end

      class Coordinate
        # TODO: rename coord to struct
        def self.from_coord(pj_coord)
          result = self.allocate
          result.instance_variable_set(:@coord, pj_coord)
          result
        end

        def initialize(x:, y:, z: nil)
          @coord = Api::PJ_COORD.new
          @coord[:v][0] = x
          @coord[:v][1] = y
          @coord[:v][2] = z if z
        end

        def to_ptr
          coord.to_ptr
        end

        def x
          coord[:v][0]
        end

        def x=(x)
          coord[:v][0] = x
        end

        def y
          coord[:v][1]
        end

        def y=(y)
          coord[:v][1] = y
        end

        def z
          coord[:v][2]
        end

        private

        attr_reader :coord
      end

      class Transform
        def self.finalize(pointer)
          # TODO: why we need a proc here?
          proc { Api.proj_destroy(pointer) }
        end

        def initialize(source, target)
          @pointer =
            Api.proj_create_crs_to_crs(
              nil,
              source.canonical_str,
              target.canonical_str,
              nil
            )
          ObjectSpace.define_finalizer(self, self.class.finalize(pointer))
        end

        def to_ptr
          pointer
        end

        def forward(coord)
          Coordinate.from_coord(Api.proj_trans(self, :PJ_FWD, coord))
        end

        private

        attr_reader :pointer
      end
    end

    # This is a Ruby wrapper around a Proj4 coordinate system.
    # It represents a single geographic coordinate system, which may be
    # a flat projection, a geocentric (3-dimensional) coordinate system,
    # or a geographic (latitude-longitude) coordinate system.
    #
    # Generally, these are used to define the projection for a
    # Feature::Factory. You can then convert between coordinate systems
    # by casting geometries between such factories using the :project
    # option. You may also use this object directly to perform low-level
    # coordinate transformations.

    class Proj4
      def inspect # :nodoc:
        "#<#{self.class}:0x#{object_id.to_s(16)} #{canonical_str.inspect}>"
      end

      def to_s  # :nodoc:
        canonical_str
      end

      def hash  # :nodoc:
        @hash ||= canonical_hash.hash
      end

      # Returns true if this Proj4 is equivalent to the given Proj4.
      #
      # Note: this tests for equivalence by comparing only the hash
      # definitions of the Proj4 objects, and returning true if those
      # definitions are equivalent. In some cases, this may still return
      # false even if the actual coordinate systems are identical, since
      # there are sometimes multiple ways to express a given coordinate
      # system.

      def eql?(rhs_)
        rhs_.class == self.class && rhs_.canonical_hash == canonical_hash && rhs_._radians? == _radians?
      end
      alias == eql?

      # Marshal support

      def marshal_dump # :nodoc:
        { "rad" => radians?, "str" => original_str || canonical_str }
      end

      def marshal_load(data_) # :nodoc:
        _set_value(data_["str"], data_["rad"])
      end

      # Psych support

      def encode_with(coder_) # :nodoc:
        coder_["proj4"] = original_str || canonical_str
        coder_["radians"] = radians?
      end

      def init_with(coder_) # :nodoc:
        if coder_.type == :scalar
          _set_value(coder_.scalar, false)
        else
          _set_value(coder_["proj4"], coder_["radians"])
        end
      end

      # Returns the "canonical" string definition for this coordinate
      # system, as reported by Proj4. This may be slightly different
      # from the definition used to construct this object.

      def canonical_str
        unless defined?(@canonical_str)
          @canonical_str = _canonical_str
          @canonical_str.force_encoding("US-ASCII") if @canonical_str.respond_to?(:force_encoding)
        end
        @canonical_str
      end

      # Returns the "canonical" hash definition for this coordinate
      # system, as reported by Proj4. This may be slightly different
      # from the definition used to construct this object.

      def canonical_hash
        unless defined?(@canonical_hash)
          @canonical_hash = {}
          canonical_str.strip.split(/\s+/).each do |elem_|
            @canonical_hash[Regexp.last_match(1)] = Regexp.last_match(3) if elem_ =~ /^\+(\w+)(=(\S+))?$/
          end
        end
        @canonical_hash
      end

      # Returns the string definition originally used to construct this
      # object. Returns nil if this object wasn't created by a string
      # definition; i.e. if it was created using get_geographic.

      def original_str
        _original_str
      end

      # Returns true if this Proj4 object is a geographic (lat-long)
      # coordinate system.

      def geographic?
        _geographic?
      end

      # Returns true if this Proj4 object is a geocentric (3dz)
      # coordinate system.

      def geocentric?
        _geocentric?
      end

      # Returns true if this Proj4 object uses radians rather than degrees
      # if it is a geographic coordinate system.

      def radians?
        _radians?
      end

      # Get the geographic (unprojected lat-long) coordinate system
      # corresponding to this coordinate system; i.e. the one that uses
      # the same ellipsoid and datum.

      def get_geographic
        _get_geographic
      end

      class << self
        # Returns true if Proj4 is supported in this installation.
        # If this returns false, the other methods such as create
        # will not work.

        def supported?
          respond_to?(:_create)
        end

        # Returns the Proj library version as an integer (example: 7.1.1).
        def version
          Proj::Api.proj_info[:version]
        end

        # Create a new Proj4 object, given a definition, which may be
        # either a string or a hash. Returns nil if the given definition
        # is invalid or Proj4 is not supported.
        #
        # Recognized options include:
        #
        # [<tt>:radians</tt>]
        #   If set to true, then this proj4 will represent geographic
        #   (latitude/longitude) coordinates in radians rather than
        #   degrees. If this is a geographic coordinate system, then its
        #   units will be in radians. If this is a projected coordinate
        #   system, then its units will be unchanged, but any geographic
        #   coordinate system obtained using get_geographic will use
        #   radians as its units. If this is a geocentric or other type of
        #   coordinate system, this has no effect. Default is false.
        #   (That is all coordinates are in degrees by default.)

        def create(defn_, opts_ = {})
          result_ = nil
          if supported?
            if defn_.is_a?(::Hash)
              defn_ = defn_.map { |k_, v_| v_ ? "+#{k_}=#{v_}" : "+#{k_}" }.join(" ")
            end
            defn_ = defn_.sub(/^(\s*)/, '\1+').gsub(/(\s+)([^+\s])/, '\1+\2') unless defn_ =~ /^\s*\+/

            Proj::Pj.new(defn_, opts_[:radians])

            # result_ = _create(defn_, opts_[:radians])
            # result_ = nil unless result_._valid?
          end
          # result_
        end

        # Create a new Proj4 object, given a definition, which may be
        # either a string or a hash. Raises Error::UnsupportedOperation
        # if the given definition is invalid or Proj4 is not supported.
        #
        # Recognized options include:
        #
        # [<tt>:radians</tt>]
        #   If set to true, then this proj4 will represent geographic
        #   (latitude/longitude) coordinates in radians rather than
        #   degrees. If this is a geographic coordinate system, then its
        #   units will be in radians. If this is a projected coordinate
        #   system, then its units will be unchanged, but any geographic
        #   coordinate system obtained using get_geographic will use
        #   radians as its units. If this is a geocentric or other type of
        #   coordinate system, this has no effect. Default is false.
        #   (That is all coordinates are in degrees by default.)

        def new(defn_, opts_ = {})
          result_ = create(defn_, opts_)
          raise Error::UnsupportedOperation, "Proj4 not supported in this installation" unless result_
          result_
        end

        # Low-level coordinate transform method.
        # Transforms the given coordinate (x, y, [z]) from one proj4
        # coordinate system to another. Returns an array with either two
        # or three elements.

        def transform_coords(from_proj_, to_proj_, x_, y_, z_ = nil)
          if !from_proj_.radians? && from_proj_.geographic?
            x_ *= ImplHelper::Math::RADIANS_PER_DEGREE
            y_ *= ImplHelper::Math::RADIANS_PER_DEGREE
          end

          transform = Proj::Transform.new(from_proj_, to_proj_)
          coord = Proj::Coordinate.new(x: x_, y: y_, z: z_)
          transformed_coord = transform.forward(coord)

          if transformed_coord && !to_proj_.radians? && to_proj_.geographic?
            transformed_coord.x = transformed_coord.x * ImplHelper::Math::DEGREES_PER_RADIAN
            transformed_coord.y = transformed_coord.y * ImplHelper::Math::DEGREES_PER_RADIAN
          end
          result = [transformed_coord.x, transformed_coord.y]
          result << transformed_coord.z if z_
          result
        end

        # Low-level geometry transform method.
        # Transforms the given geometry between the given two projections.
        # The resulting geometry is constructed using the to_factory.
        # Any projections associated with the factories themselves are
        # ignored.

        def transform(from_proj_, from_geometry_, to_proj_, to_factory_)
          case from_geometry_
          when Feature::Point
            transform_point(from_proj_, from_geometry_, to_proj_, to_factory_)
          when Feature::Line
            to_factory_.line(from_geometry_.points.map { |p_| transform_point(from_proj_, p_, to_proj_, to_factory_) })
          when Feature::LinearRing
            transform_linear_ring(from_proj_, from_geometry_, to_proj_, to_factory_)
          when Feature::LineString
            to_factory_.line_string(from_geometry_.points.map { |p_| transform_point(from_proj_, p_, to_proj_, to_factory_) })
          when Feature::Polygon
            transform_polygon(from_proj_, from_geometry_, to_proj_, to_factory_)
          when Feature::MultiPoint
            to_factory_.multi_point(from_geometry_.map { |p_| transform_point(from_proj_, p_, to_proj_, to_factory_) })
          when Feature::MultiLineString
            to_factory_.multi_line_string(from_geometry_.map { |g_| transform(from_proj_, g_, to_proj_, to_factory_) })
          when Feature::MultiPolygon
            to_factory_.multi_polygon(from_geometry_.map { |p_| transform_polygon(from_proj_, p_, to_proj_, to_factory_) })
          when Feature::GeometryCollection
            to_factory_.collection(from_geometry_.map { |g_| transform(from_proj_, g_, to_proj_, to_factory_) })
          end
        end

        private

        def transform_point(from_proj_, from_point_, to_proj_, to_factory_)
          from_factory_ = from_point_.factory
          from_has_z_ = from_factory_.property(:has_z_coordinate)
          from_has_m_ = from_factory_.property(:has_m_coordinate)
          to_has_z_ = to_factory_.property(:has_z_coordinate)
          to_has_m_ = to_factory_.property(:has_m_coordinate)
          x_ = from_point_.x
          y_ = from_point_.y
          if !from_proj_._radians? && from_proj_._geographic?
            x_ *= ImplHelper::Math::RADIANS_PER_DEGREE
            y_ *= ImplHelper::Math::RADIANS_PER_DEGREE
          end
          coords_ = _transform_coords(from_proj_, to_proj_, x_, y_, from_has_z_ ? from_point_.z : nil)
          return unless coords_
          if !to_proj_._radians? && to_proj_._geographic?
            coords_[0] *= ImplHelper::Math::DEGREES_PER_RADIAN
            coords_[1] *= ImplHelper::Math::DEGREES_PER_RADIAN
          end
          extras_ = []
          extras_ << coords_[2].to_f if to_has_z_
          if to_has_m_
            extras_ << from_has_m_ ? from_point_.m : 0.0
          end
          to_factory_.point(coords_[0], coords_[1], *extras_)
        end

        def transform_linear_ring(from_proj_, from_ring_, to_proj_, to_factory_)
          to_factory_.linear_ring(from_ring_.points[0..-2].map { |p_| transform_point(from_proj_, p_, to_proj_, to_factory_) })
        end

        def transform_polygon(from_proj_, from_polygon_, to_proj_, to_factory_)
          ext_ = transform_linear_ring(from_proj_, from_polygon_.exterior_ring, to_proj_, to_factory_)
          int_ = from_polygon_.interior_rings.map { |r_| transform_linear_ring(from_proj_, r_, to_proj_, to_factory_) }
          to_factory_.polygon(ext_, int_)
        end
      end
    end
  end
end
