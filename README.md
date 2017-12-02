# `rgeo-proj4`

[![Gem Version](https://badge.fury.io/rb/rgeo-proj4.svg)](http://badge.fury.io/rb/rgeo-proj4)
[![Build Status](https://travis-ci.org/rgeo/rgeo-proj4.svg?branch=master)](https://travis-ci.org/rgeo/rgeo-proj4)

This project contains proj.4 extensions to the [rgeo gem](https://github.com/rgeo/rgeo).

Documentation about `proj.4` is available at [http://proj4.org/](http://proj4.org/).

## Installation

Add this line to your Gemfile:

```ruby
gem "rgeo-proj4"
```

And then execute:

    $ bundle

Or install it yourself as:

    $ gem install rgeo-proj4

## Usage

Install `proj.4` using your package manager:

### Homebrew
```sh
brew install proj
```

### Apt

```sh
apt-get install libproj-dev
```

Or download binaries at http://proj4.org/

By default, the gem looks for the Proj4 library in the following paths: 

```
/usr/local
/usr/local/proj
/usr/local/proj4
/opt/local
/opt/proj
/opt/proj4
/opt
/usr
/Library/Frameworks/PROJ.framework/unix
```

If Proj4 is installed in a different location, you must provide its
installation prefix directory using the `--with-proj-dir` option.

## Development

After checking out the repo, run `bin/setup` to install dependencies. Then, run `rake test` to run 
the tests. You can also run `bin/console` for an interactive prompt that will allow you to experiment.

To install this gem onto your local machine, run `bundle exec rake install`. To release a new version, 
update the version number in `version.rb`, and then run `bundle exec rake release`, which will create 
a git tag for the version, push git commits and tags, and push the `.gem` file to 
[rubygems.org](https://rubygems.org).

## Contributing

Bug reports and pull requests are welcome on GitHub at https://github.com/rgeo/rgeo-proj4. 
This project is intended to be a safe, welcoming space for collaboration, and contributors are 
expected to adhere to the [Contributor Covenant](http://contributor-covenant.org) code of conduct.

## License

The gem is available as open source under the terms of the 
[MIT License](https://opensource.org/licenses/MIT).

## Code of Conduct

Everyone interacting in the `rgeo-proj4` project’s codebases, issue trackers, chat rooms and mailing 
lists is expected to follow the 
[code of conduct](https://github.com/rgeo/rgeo-proj4/blob/master/CODE_OF_CONDUCT.md).
