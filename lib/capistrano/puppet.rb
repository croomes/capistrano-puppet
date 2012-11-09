require 'capistrano'
require 'capistrano/puppet/version'

module Capistrano
  Class Puppet
    Configuration.instance(true).load do

      require 'benchmark'
      require 'yaml'
      require 'shellwords'
      require 'capistrano/recipes/deploy/scm'
      require 'capistrano/recipes/deploy/strategy'
      require 'capistrano/puppet/config'
      # require 'capistrano/puppet/helpers'       
      # require 'capistrano/puppet/deploy'
      # require 'capistrano/puppet/service'
      # require 'capistrano/puppet/master'
    
      namespace :deploy do
        desc <<-DESC
          Deploys your project. This calls both `update' and `restart'. Note that \
          this will generally only work for applications that have already been deployed \
          once. For a "cold" deploy, you'll want to take a look at the `deploy:cold' \
          task, which handles the cold start specifically.
        DESC
        task :default do
          update
          restart
        end
      
        desc <<-DESC
          Restarts the Puppet Master
        DESC
        task :restart, :roles => :master do
          # Empty Task to overload with your platform specifics
        end      
      end    
    end
  end
end
