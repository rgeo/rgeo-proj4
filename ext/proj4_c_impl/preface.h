#ifdef HAVE_PROJ_H
#ifdef HAVE_PROJ_CREATE
#ifdef HAVE_PROJ_CREATE_CRS_TO_CRS_FROM_PJ
#ifdef HAVE_PROJ_NORMALIZE_FOR_VISUALIZATION
#define RGEO_PROJ4_SUPPORTED
#endif
#endif
#endif
#endif

#ifdef HAVE_RB_GC_MARK_MOVABLE
#define mark rb_gc_mark_movable
#else
#define mark rb_gc_mark
#endif

// When using ruby ALLOC* macros, we are using ruby_xmalloc, which counterpart
// is ruby_xfree. This macro helps enforcing that by showing us the way.
#define FREE ruby_xfree

#ifdef __cplusplus
#define RGEO_BEGIN_C extern "C" {
#define RGEO_END_C }
#else
#define RGEO_BEGIN_C
#define RGEO_END_C
#endif
