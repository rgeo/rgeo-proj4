require "rake/testtask"
require "rake/extensiontask"
# require "rdoc/task"

# Gemspec

# gemspec = eval(::File.read(::Dir.glob("*.gemspec").first))
# release_gemspec = eval(::File.read(::Dir.glob("*.gemspec").first))
# release_gemspec.version = gemspec.version.to_s.sub(/\.nonrelease$/, "")

require "bundler/gem_tasks"

# Directories
pkg_directory = "pkg"
tmp_directory = "tmp"

# Build tasks

if ::RUBY_DESCRIPTION.match /^jruby/
  task :compile
else
  Rake::ExtensionTask.new "proj4_c_impl" do |ext|
    ext.lib_dir = "lib/rgeo/coord_sys"
  end
end

# Clean task

clean_files = [pkg_directory, tmp_directory] +
  ::Dir.glob("ext/**/Makefile*") +
  ::Dir.glob("ext/**/*.{o,class,log,dSYM}") +
  ::Dir.glob("**/*.{bundle,so,dll,rbc,jar}") +
  ::Dir.glob("**/.rbx")

task :clean do
  clean_files.each { |path| rm_rf path }
end

# Unit test task

Rake::TestTask.new(:test) do |t|
  t.libs << "test"
  t.libs << "lib"
  t.test_files = FileList["test/**/*_test.rb"]
end

task test: :compile

task default: %i[clean test]
