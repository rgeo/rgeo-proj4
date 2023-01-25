FROM ruby:latest

ARG work_dir=/ bundle_dir=/usr/local/bundle

WORKDIR ${work_dir}
# RUN bundle config set --local path ${bundle_dir}

RUN apt update && apt install -yqq libgeos-dev libproj-dev proj-bin valgrind

COPY Gemfile rgeo-proj4.gemspec ./
COPY ./lib/rgeo/proj4/version.rb ./lib/rgeo/proj4/
RUN echo $(ls ./lib/rgeo/proj4)
RUN bundle install

COPY . .
RUN rake compile


CMD ["rake", "test:valgrind"]
