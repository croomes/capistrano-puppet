# -*- encoding: utf-8 -*-
require File.expand_path("../lib/puppet/capistrano/version", __FILE__)

Gem::Specification.new do |gem|
  gem.name        = "capistrano-puppet"
  gem.version     = Puppet::Capistrano::VERSION.dup
  gem.platform    = Gem::Platform::RUBY
  gem.author      = "Simon Croome"
  gem.email       = "simon@croome.org"
  gem.homepage    = "http://github.com/croomes/capistrano-puppet"
  gem.summary     = "Puppet configuration deployment"
  gem.description = "Use Capistrano to deploy your Puppet Master configuration from git or other SCM repository."

  gem.files        = Dir["{lib}/**/*.rb", "LICENSE", "*.md"]
  gem.require_path = 'lib'

  gem.add_runtime_dependency 'capistrano'
end