#ifndef RGEO_PROJ4_ERRORS_INCLUDED
#define RGEO_PROJ4_ERRORS_INCLUDED

#include <ruby.h>

#ifdef RGEO_PROJ4_SUPPORTED

RGEO_BEGIN_C

extern VALUE error_module;
// Main rgeo error type
extern VALUE rgeo_error;
// RGeo::Error::InvalidProjection
extern VALUE rgeo_invalid_projection_error;

void rgeo_init_proj_errors();

RGEO_END_C

#endif // RGEO_PROJ4_SUPPORTED

#endif // RGEO_PROJ4_ERRORS_INCLUDED
