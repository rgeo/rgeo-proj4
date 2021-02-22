/*
  Main initializer for Proj4 wrapper
*/
#ifdef HAVE_PROJ_H
#ifdef HAVE_PROJ_CREATE
#ifdef HAVE_PROJ_CREATE_CRS_TO_CRS_FROM_PJ
#ifdef HAVE_PROJ_NORMALIZE_FOR_VISUALIZATION
#define RGEO_PROJ4_SUPPORTED
#endif
#endif
#endif
#endif

#ifdef __cplusplus
#define RGEO_BEGIN_C extern "C" {
#define RGEO_END_C }
#else
#define RGEO_BEGIN_C
#define RGEO_END_C
#endif


#ifdef RGEO_PROJ4_SUPPORTED

#include <ruby.h>
#include <proj.h>

#endif


RGEO_BEGIN_C


#ifdef RGEO_PROJ4_SUPPORTED


typedef struct {
  PJ *pj;
  VALUE original_str;
  char uses_radians;
} RGeo_Proj4Data;


#define RGEO_PROJ4_DATA_PTR(obj) ((RGeo_Proj4Data*)DATA_PTR(obj))


// Destroy function for proj data.

static void destroy_proj4_func(RGeo_Proj4Data* data)
{
  if (data->pj) {
    proj_destroy(data->pj);
  }
  free(data);
}


static void mark_proj4_func(RGeo_Proj4Data* data)
{
  if (!NIL_P(data->original_str)) {
    rb_gc_mark(data->original_str);
  }
}


static VALUE alloc_proj4(VALUE klass)
{
  VALUE result;
  RGeo_Proj4Data *data;

  result = Qnil;
  data = ALLOC(RGeo_Proj4Data);
  if (data) {
    data->pj = NULL;
    data->original_str = Qnil;
    data->uses_radians = 0;
    result = Data_Wrap_Struct(klass, mark_proj4_func, destroy_proj4_func, data);
  }
  return result;
}


static VALUE method_proj4_initialize_copy(VALUE self, VALUE orig)
{
  RGeo_Proj4Data *self_data;
  PJ *pj;
  RGeo_Proj4Data *orig_data;
  const char* str;

  // Clear out any existing value
  self_data = RGEO_PROJ4_DATA_PTR(self);
  pj = self_data->pj;
  if (pj) {
    proj_destroy(pj);
    self_data->pj = NULL;
    self_data->original_str = Qnil;
  }

  // Copy value from orig
  orig_data = RGEO_PROJ4_DATA_PTR(orig);
  if (!NIL_P(orig_data->original_str)) {
    self_data->pj = proj_create(0, RSTRING_PTR(orig_data->original_str));
  }
  else {
    str = proj_as_proj_string(0, orig_data->pj, PJ_PROJ_4, NULL);
    self_data->pj = proj_create(0, str);
    // pj_dalloc(str);
  }
  self_data->original_str = orig_data->original_str;
  self_data->uses_radians = orig_data->uses_radians;

  return self;
}


static VALUE method_proj4_set_value(VALUE self, VALUE str, VALUE uses_radians)
{
  RGeo_Proj4Data *self_data;
  PJ *pj;

  Check_Type(str, T_STRING);

  // Clear out any existing value
  self_data = RGEO_PROJ4_DATA_PTR(self);
  pj = self_data->pj;
  if (pj) {
    proj_destroy(pj);
    self_data->pj = NULL;
    self_data->original_str = Qnil;
  }

  // Set new data
  self_data->pj = proj_create(0, RSTRING_PTR(str));
  self_data->original_str = str;
  self_data->uses_radians = RTEST(uses_radians) ? 1 : 0;

  return self;
}


static VALUE method_proj4_get_geographic(VALUE self)
{
  VALUE result;
  RGeo_Proj4Data *new_data;
  RGeo_Proj4Data *self_data;

  result = Qnil;
  new_data = ALLOC(RGeo_Proj4Data);
  if (new_data) {
    self_data = RGEO_PROJ4_DATA_PTR(self);

    new_data->pj = proj_crs_get_geodetic_crs(0, self_data->pj);
    new_data->original_str = Qnil;
    new_data->uses_radians = self_data->uses_radians;
    result = Data_Wrap_Struct(CLASS_OF(self), mark_proj4_func, destroy_proj4_func, new_data);
  }
  return result;
}


static VALUE method_proj4_original_str(VALUE self)
{
  return RGEO_PROJ4_DATA_PTR(self)->original_str;
}


static VALUE method_proj4_uses_radians(VALUE self)
{
  return RGEO_PROJ4_DATA_PTR(self)->uses_radians ? Qtrue : Qfalse;
}


static VALUE method_proj4_canonical_str(VALUE self)
{
  VALUE result;
  PJ *pj;
  const char *str;

  result = Qnil;
  pj = RGEO_PROJ4_DATA_PTR(self)->pj;
  if (pj) {
    str = proj_as_proj_string(0, pj, PJ_PROJ_4, NULL);
    if (str) {
      result = rb_str_new2(str);
      // pj_dalloc(str);
    }
  }
  return result;
}


static VALUE method_proj4_is_geographic(VALUE self)
{
  VALUE result;
  PJ *pj;
  PJ_TYPE proj_type;

  result = Qnil;
  pj = RGEO_PROJ4_DATA_PTR(self)->pj;
  if (pj) {
    proj_type = proj_get_type(pj);
    if(proj_type == PJ_TYPE_GEOGRAPHIC_2D_CRS || proj_type == PJ_TYPE_GEOGRAPHIC_3D_CRS){
      result = Qtrue;
    } else {
      result = Qfalse;
    }
  }
  return result;
}


static VALUE method_proj4_is_geocentric(VALUE self)
{
  VALUE result;
  PJ *pj;
  PJ_TYPE proj_type;

  result = Qnil;
  pj = RGEO_PROJ4_DATA_PTR(self)->pj;
  if (pj) {
    proj_type = proj_get_type(pj);
    result = proj_type == PJ_TYPE_GEOCENTRIC_CRS ? Qtrue : Qfalse;
  }
  return result;
}


static VALUE method_proj4_is_valid(VALUE self)
{
  return RGEO_PROJ4_DATA_PTR(self)->pj ? Qtrue : Qfalse;
}


static VALUE cmethod_proj4_version(VALUE module)
{
  return rb_sprintf("%d.%d.%d", PROJ_VERSION_MAJOR, PROJ_VERSION_MINOR, PROJ_VERSION_PATCH);
}


static VALUE cmethod_proj4_transform(VALUE module, VALUE from, VALUE to, VALUE x, VALUE y, VALUE z)
{
  VALUE result;
  PJ *from_pj;
  PJ *to_pj;
  PJ *crs_to_crs;
  PJ *gis_pj;
  double xval, yval, zval;
  PJ_COORD input;
  PJ_COORD output;

  result = Qnil;
  from_pj = RGEO_PROJ4_DATA_PTR(from)->pj;
  to_pj = RGEO_PROJ4_DATA_PTR(to)->pj;
  if (from_pj && to_pj) {
    crs_to_crs = proj_create_crs_to_crs_from_pj(0, from_pj, to_pj, 0, NULL);
    if(crs_to_crs){
      // necessary to use proj_normalize_for_visualization so that we
      // do not have to worry about the order of coordinates in every
      // coord system.
      gis_pj = proj_normalize_for_visualization(0, crs_to_crs);
      if(gis_pj){
        proj_destroy(crs_to_crs);
        crs_to_crs = gis_pj;

        xval = rb_num2dbl(x);
        yval = rb_num2dbl(y);
        zval = 0.0;
        if (!NIL_P(z)) {
          zval = rb_num2dbl(z);
        }
        input = proj_coord(xval, yval, zval, HUGE_VAL);
        output = proj_trans(crs_to_crs, PJ_FWD, input);

        result = rb_ary_new2(NIL_P(z) ? 2 : 3);
        rb_ary_push(result, DBL2NUM(output.xyz.x));
        rb_ary_push(result, DBL2NUM(output.xyz.y));
        if(!NIL_P(z)){
          rb_ary_push(result, DBL2NUM(output.xyz.z));
        }
      }
      proj_destroy(crs_to_crs);
    }
  }
  return result;
}


static VALUE cmethod_proj4_create(VALUE klass, VALUE str, VALUE uses_radians)
{
  VALUE result;
  RGeo_Proj4Data* data;

  result = Qnil;
  Check_Type(str, T_STRING);
  data = ALLOC(RGeo_Proj4Data);
  if (data) {
    data->pj = proj_create(0, RSTRING_PTR(str));
    data->original_str = str;
    data->uses_radians = RTEST(uses_radians) ? 1 : 0;
    result = Data_Wrap_Struct(klass, mark_proj4_func, destroy_proj4_func, data);
  }
  return result;
}


static void rgeo_init_proj4()
{
  VALUE rgeo_module;
  VALUE coordsys_module;
  VALUE proj4_class;

  rgeo_module = rb_define_module("RGeo");
  coordsys_module = rb_define_module_under(rgeo_module, "CoordSys");
  proj4_class = rb_define_class_under(coordsys_module, "Proj4", rb_cObject);

  rb_define_alloc_func(proj4_class, alloc_proj4);
  rb_define_module_function(proj4_class, "_create", cmethod_proj4_create, 2);
  rb_define_method(proj4_class, "initialize_copy", method_proj4_initialize_copy, 1);
  rb_define_method(proj4_class, "_set_value", method_proj4_set_value, 2);
  rb_define_method(proj4_class, "_original_str", method_proj4_original_str, 0);
  rb_define_method(proj4_class, "_canonical_str", method_proj4_canonical_str, 0);
  rb_define_method(proj4_class, "_valid?", method_proj4_is_valid, 0);
  rb_define_method(proj4_class, "_geographic?", method_proj4_is_geographic, 0);
  rb_define_method(proj4_class, "_geocentric?", method_proj4_is_geocentric, 0);
  rb_define_method(proj4_class, "_radians?", method_proj4_uses_radians, 0);
  rb_define_method(proj4_class, "_get_geographic", method_proj4_get_geographic, 0);
  rb_define_module_function(proj4_class, "_transform_coords", cmethod_proj4_transform, 5);
  rb_define_module_function(proj4_class, "_proj_version", cmethod_proj4_version, 0);
}


#endif


void Init_proj4_c_impl()
{
#ifdef RGEO_PROJ4_SUPPORTED
  rgeo_init_proj4();
#endif
}


RGEO_END_C
