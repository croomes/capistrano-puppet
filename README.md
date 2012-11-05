# capistrano-puppet

## Description

Opinionated Puppet Master deployment with Capistrano, intended for managing 
multiple Masters across many environments.

## Status

In development.  Example config at https://github.com/croomes/puppet-conf, 
with Vagrant sandbox at https://github.com/croomes/puppet-multimaster.

## Installation

    $ gem install capistrano-puppet

## Basic Example

The following code will:

- Checkout Puppet config from SCM into /vagrant/puppet-conf
- Symlink to /etc/puppet
- Restart Puppet daemon if running

Convert existing Puppet configuration:

    $ cd /etc/puppet
    $ capify
    $ git commit
    $ git push

Example Capfile:

    require 'capistrano'
    require 'rubygems'
    load 'config/deploy'

Example config/deploy.rb:

    set :application, "Puppet Master Config"
    set :deploy_to, "/vagrant/puppet-conf"
    set :current_path, "/etc/puppet"
    set :deploy_via, :export
    set :scm, :git
    set :repository,  "git://github.com/croomes/puppet-conf.git"

    require 'capistrano/ext/multistage'
    require 'rvm/capistrano'
    require 'puppet/capistrano'

Initial run:

    $ cap deploy:check
    $ cap deploy:setup
    $ cap deploy

## Tasks

```bash
$ cap -T rvm
cap deploy                # Deploys your project.
cap deploy:check          # Test deployment dependencies.
cap deploy:cleanup        # Clean up old releases.
cap deploy:cold           # Deploys and starts a `cold' application.
cap deploy:create_symlink # Updates the symlink to the most recently deployed...
cap deploy:pending        # Displays the commits since your last deploy.
cap deploy:pending:diff   # Displays the `diff' since your last deploy.
cap deploy:restart        # Blank task exists as a hook into which to install...
cap deploy:rollback       # Rolls back to a previous version and restarts.
cap deploy:rollback:code  # Rolls back to the previously deployed version.
cap deploy:setup          # Prepares one or more servers for deployment.
cap deploy:start          # Blank task exists as a hook into which to install...
cap deploy:stop           # Blank task exists as a hook into which to install...
cap deploy:update         # Copies your project and updates the symlink.
cap deploy:update_code    # Copies your project to the remote servers.
cap deploy:upload         # Copy files to the currently deployed version.
```

## See also

- https://github.com/croomes/puppet-conf.  Configuration example.
- https://github.com/croomes/puppet-multimaster.  Vagrant sandbox.
- https://github.com/wayneeseguin/rvm-capistrano.  Deploy Ruby and Puppet.
 
## Development

    $ rake spec
