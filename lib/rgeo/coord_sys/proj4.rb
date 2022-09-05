# frozen_string_literal: true

# -----------------------------------------------------------------------------
#
# Proj4 wrapper for RGeo
#
# -----------------------------------------------------------------------------

module RGeo
  module CoordSys
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

    class Proj4 < CS::CoordinateSystem
      attr_accessor :dimension

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

      def eql?(other)
        other.class == self.class && other.canonical_hash == canonical_hash && other._radians? == _radians?
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

      # Returns the WKT representation of the CRS.

      def as_text
        _as_text
      end
      alias to_wkt as_text

      # Returns the string representing the authority and code of the
      # CRS if it exists, nil otherwise.
      #
      # Ex. EPSG:4326

      def auth_name
        _auth_name
      end

      # Gets axis details for dimension within coordinate system. Each
      # dimension in the coordinate system has a corresponding axis.
      def get_axis(dimension)
        _axis_and_unit_info(dimension).split(":")[0]
      end

      # Gets units for dimension within coordinate system. Each
      # dimension in the coordinate system has corresponding units.
      def get_units(dimension)
        _axis_and_unit_info(dimension).split(":")[1]
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

      # Returns true if this Proj4 object represents a CRS.

      def crs?
        _crs?
      end

      class << self
        # Returns true if Proj4 is supported in this installation.
        # If this returns false, the other methods such as create
        # will not work.

        def supported?
          respond_to?(:_create)
        end

        # Returns the Proj library version as an integer (example: 493).
        # TODO: return as string of the format "x.y.z".
        def version
          _proj_version
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

            result_ = _create(defn_, opts_[:radians])
            raise RGeo::Error::InvalidProjection unless result_._valid?

            result_.dimension = result_._axis_count
          end
          result_
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
        def transform_coords(from_proj, to_proj, x, y, z = nil)
          crs_to_crs = CRSStore.get(from_proj, to_proj)
          crs_to_crs.transform_coords(x, y, z)
        end

        # Low-level geometry transform method.
        # Transforms the given geometry between the given two projections.
        # The resulting geometry is constructed using the to_factory.
        # Any projections associated with the factories themselves are
        # ignored.
        def transform(from_proj, from_geometry, to_proj, to_factory)
          crs_to_crs = CRSStore.get(from_proj, to_proj)
          crs_to_crs.transform(from_geometry, to_factory)
        end
      end
    end
  end
end
