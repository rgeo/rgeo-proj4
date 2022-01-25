#ifndef RGEO_PROJ4_ERRORS_INCLUDED
#define RGEO_PROJ4_ERRORS_INCLUDED

#include <ruby.h>

#include "preface.h"

#ifdef RGEO_PROJ4_SUPPORTED

#include "errors.h"

RGEO_BEGIN_C

VALUE error_module;
VALUE rgeo_error;
VALUE rgeo_invalid_projection_error;

void rgeo_init_proj_errors() {
  VALUE rgeo_module;

  rgeo_module = rb_define_module("RGeo");
  error_module = rb_define_module_under(rgeo_module, "Error");
  rgeo_error = rb_define_class_under(error_module, "RGeoError", rb_eRuntimeError);
  rgeo_invalid_projection_error = rb_define_class_under(error_module, "InvalidProjection", rgeo_error);
}

RGEO_END_C

#endif // RGEO_PROJ4_SUPPORTED

#endif // RGEO_GEOS_ERROS_INCLUDED
