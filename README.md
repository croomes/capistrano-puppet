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

- Checkout Puppet config from git into /vagrant/puppet-conf
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
    require 'capistrano/puppet'

    load 'config/deploy'

Example config/deploy.rb:

    set :application, "Puppet Master Config"
    set :deploy_to, "/vagrant/puppet-conf"
    set :puppet_service, :apache_passenger    
    set :current_path, "/etc/puppet"
    set :deploy_via, :export
    set :use_sudo, false    
    set :user, "vagrant"
    set :password, "vagrant"
    set :scm, :git
    set :repository,  "git://github.com/croomes/puppet-conf.git"

    require 'capistrano/puppet/service/#{puppet_service}'
    
    role :master, "localhost"

Initial run:

    $ cap deploy:check
    $ cap deploy:setup
    $ cap deploy

## Tasks

```bash
$ cap -T
cap deploy                  # Deploys your Puppet configuration.
cap deploy:check            # Test deployment dependencies.
cap deploy:cleanup          # Clean up old releases.
cap deploy:cold             # Deploys and starts a `cold' application.
cap deploy:create_symlink   # Updates the symlink to the most recently deploy...
cap deploy:pending          # Displays the commits since your last deploy.
cap deploy:pending:diff     # Displays the `diff' since your last deploy.
cap deploy:prep_environment # Prepares the environment for installing modules...
cap deploy:rollback         # Rolls back to a previous version and restarts.
cap deploy:rollback:code    # Rolls back to the previously deployed version.
cap deploy:setup            # Prepares one or more servers for deployment.
cap deploy:update           # Copies your project and updates the symlink.
cap deploy:update_code      # Copies your project to the remote servers.
cap deploy:update_modules   # Updates the Puppet modules.
cap invoke                  # Invoke a single command on the remote servers.
cap puppet:condrestart      # Restarts if already running
cap puppet:enable           # Disables Puppet Master daemon from starting at ...
cap puppet:once             # Exits after running the configuration once
cap puppet:reload           # Reload Puppet
cap puppet:restart          # Restart Puppet
cap puppet:shutdown         # Immediately shutdown Puppet
cap puppet:start            # Start Puppet master process
cap puppet:status           # Shows current status
cap puppet:stop             # Stop Puppet
cap shell                   # Begin an interactive Capistrano session.
```

## See also

- https://github.com/croomes/puppet-conf.  Configuration example.
- https://github.com/croomes/puppet-multimaster.  Vagrant sandbox.
- https://github.com/wayneeseguin/rvm-capistrano.  Deploy Ruby and Puppet.
 
## Development

    $ rake spec
