#ifndef RGEO_PROJ4_ERRORS_INCLUDED
#define RGEO_PROJ4_ERRORS_INCLUDED

#include <ruby.h>

#include "preface.h"

#ifdef RGEO_PROJ4_SUPPORTED

#include "errors.h"

RGEO_BEGIN_C

VALUE error_module;
VALUE rb_eRGeoError;
VALUE rb_eRGeoInvalidProjectionError;

void rgeo_init_proj_errors() {
  VALUE rgeo_module;

  rgeo_module = rb_define_module("RGeo");
  error_module = rb_define_module_under(rgeo_module, "Error");
  rb_eRGeoError = rb_define_class_under(error_module, "RGeoError", rb_eRuntimeError);
  rb_eRGeoInvalidProjectionError = rb_define_class_under(error_module, "InvalidProjection", rb_eRGeoError);
}

RGEO_END_C

#endif // RGEO_PROJ4_SUPPORTED

#endif // RGEO_GEOS_ERROS_INCLUDED
