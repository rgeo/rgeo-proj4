# -----------------------------------------------------------------------------
#
# Makefile builder for Proj4 wrapper
#
# -----------------------------------------------------------------------------

if ::RUBY_DESCRIPTION =~ /^jruby\s/

  ::File.open("Makefile", "w") { |f_| f_.write(".PHONY: install\ninstall:\n") }

else

  require "mkmf"

  with_default_header_paths = with_config("default-header-paths", true)
  with_default_lib_paths = with_config("default-lib-paths", true)

  header_dirs_ = [ ::RbConfig::CONFIG["includedir"] ]
  if with_default_header_paths
    header_dirs_.push(
      "/usr/local/include",
      "/usr/local/proj/include",
      "/usr/local/proj4/include",
      "/opt/local/include",
      "/opt/proj/include",
      "/opt/proj4/include",
      "/opt/include",
      "/opt/homebrew/include",
      "/Library/Frameworks/PROJ.framework/unix/include",
      "/usr/include"
    )
  end

  lib_dirs_ = [ ::RbConfig::CONFIG["libdir"] ]
  if with_default_lib_paths
    lib_dirs_.push(
      "/usr/local/lib",
      "/usr/local/lib64",
      "/usr/local/proj/lib",
      "/usr/local/proj4/lib",
      "/opt/local/lib",
      "/opt/proj/lib",
      "/opt/proj4/lib",
      "/opt/lib",
      "/opt/homebrew/lib",
      "/Library/Frameworks/PROJ.framework/unix/lib",
      "/usr/lib",
      "/usr/lib64"
    )
  end

  header_dirs_.delete_if { |path_| !::File.directory?(path_) }
  lib_dirs_.delete_if { |path_| !::File.directory?(path_) }

  found_proj_ = false
  header_dirs_, lib_dirs_ = dir_config("proj", header_dirs_, lib_dirs_)
  if have_header("proj.h")
    $libs << " -lproj"

    if have_func("proj_create", "proj.h")
      found_proj_ = true
      have_func("proj_create_crs_to_crs_from_pj", "proj.h")
      have_func("proj_normalize_for_visualization", "proj.h")
    else
      $libs.gsub!(" -lproj", "")
    end
  end
  have_func("rb_gc_mark_movable")

  unless found_proj_
    puts "**** WARNING: Unable to find Proj headers or Proj version is too old."
    puts "**** Compiling without Proj support."
  end
  create_makefile("rgeo/coord_sys/proj4_c_impl")

end
