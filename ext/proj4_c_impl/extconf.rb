# -----------------------------------------------------------------------------
#
# Makefile builder for Proj4 wrapper
#
# -----------------------------------------------------------------------------

if ::RUBY_DESCRIPTION =~ /^jruby\s/

  ::File.open("Makefile", "w") { |f_| f_.write(".PHONY: install\ninstall:\n") }

else

  require "mkmf"

  header_dirs =
    [
      ::RbConfig::CONFIG["includedir"],
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
    ]
  lib_dirs =
    [
      ::RbConfig::CONFIG["libdir"],
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
    ]
  header_dirs.delete_if { |path| !::File.directory?(path) }
  lib_dirs.delete_if { |path| !::File.directory?(path) }

  found_proj = false
  found_valid_proj_version = false
  header_dirs, lib_dirs = dir_config("proj", header_dirs, lib_dirs)
  if have_header("proj.h")
    $libs << " -lproj"
    found_proj = true

    required_proj_funcs = %w[
      proj_create
      proj_create_crs_to_crs_from_pj
      proj_normalize_for_visualization
    ]
    found_valid_proj_version = required_proj_funcs.map do |func|
      have_func(func, "proj.h")
    end.all?(true)
  end
  have_func("rb_gc_mark_movable")

  unless found_proj

    install_text = case RUBY_PLATFORM
                   when /linux/
                     %(
  Please install proj like so:
    apt-get install libproj-dev proj-bin
                     )
                   when /darwin/
                     %(
  Please install proj like so:
    brew install proj
                     )
                   else
                     %(
  Please install proj.
                     )
                   end
    error_msg = %(
**** WARNING: Unable to find Proj headers. Ensure that Proj is properly installed.

#{install_text}

or set the path manually using:
 --with-proj-dir or with the --with-proj-include and --with-proj-lib options
    )
    warn error_msg
    raise
  end

  unless found_valid_proj_version
    error_msg = %(
**** WARNING: The found Proj version is not new enough to be used for this version of rgeo-proj4.
**** Proj 6.2+ is required.
    )
    warn error_msg
    raise
  end

  create_makefile("rgeo/coord_sys/proj4_c_impl")
end
