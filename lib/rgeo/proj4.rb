# frozen_string_literal: true

require "rgeo"
require "rgeo/proj4/version"
require "rgeo/coord_sys/proj4_c_impl"
require "rgeo/coord_sys/crs_to_crs"
require "rgeo/coord_sys/proj4"
require "rgeo/coord_sys/srs_database/proj4_data"
require_relative "./errors"

module RGeo
  module CoordSys
    # PROJ uses enums for types, some methods require us to return
    # the name of the type. We will use this as a lookup.
    PROJ_TYPES = %w[
      PJ_TYPE_UNKNOWN
      PJ_TYPE_ELLIPSOID
      PJ_TYPE_PRIME_MERIDIAN
      PJ_TYPE_GEODETIC_REFERENCE_FRAME
      PJ_TYPE_DYNAMIC_GEODETIC_REFERENCE_FRAME
      PJ_TYPE_VERTICAL_REFERENCE_FRAME
      PJ_TYPE_DYNAMIC_VERTICAL_REFERENCE_FRAME
      PJ_TYPE_DATUM_ENSEMBLE
      PJ_TYPE_CRS
      PJ_TYPE_GEODETIC_CRS
      PJ_TYPE_GEOCENTRIC_CRS
      PJ_TYPE_GEOGRAPHIC_CRS
      PJ_TYPE_GEOGRAPHIC_2D_CRS
      PJ_TYPE_GEOGRAPHIC_3D_CRS
      PJ_TYPE_VERTICAL_CRS
      PJ_TYPE_PROJECTED_CRS
      PJ_TYPE_COMPOUND_CRS
      PJ_TYPE_TEMPORAL_CRS
      PJ_TYPE_ENGINEERING_CRS
      PJ_TYPE_BOUND_CRS
      PJ_TYPE_OTHER_CRS
      PJ_TYPE_CONVERSION
      PJ_TYPE_TRANSFORMATION
      PJ_TYPE_CONCATENATED_OPERATION
      PJ_TYPE_OTHER_COORDINATE_OPERATION
      PJ_TYPE_TEMPORAL_DATUM
      PJ_TYPE_ENGINEERING_DATUM
      PJ_TYPE_PARAMETRIC_DATUM
    ].freeze
  end
end

RGeo::CoordSys::CONFIG.default_coord_sys_class = RGeo::CoordSys::Proj4 if RGeo::CoordSys::Proj4.supported?
