require 'capistrano/puppet/service/base'

module Capistrano
  module Puppet
    module Service
      # A service module for using the default Webrick as the Puppet Master Web
      # and Rack Servers.
      #
      # CONFIGURATION
      # -------------
      #
      # Use this plugin by adding the following line in your config/deploy.rb:
      #
      #   set :puppet_service, :webrick
      #
      class Webrick < Base

        ADDITIONAL_TASKS = [
          'puppet:condrestart',
          'puppet:once',
        ]
        SERVICE_INIT = "/etc/init.d/puppet"

        # Enables the service for starting on boot.
        def enable
          run "#{try_sudo} /sbin/chkconfig puppet on"
        end

        # Disables the service from starting at boot.
        def disable
          run "#{try_sudo} /sbin/chkconfig puppet off"
        end

        # Reloads the configuration and restarts the service if required.
        def reload
          run "#{try_sudo} /sbin/service puppet reload"
        end

        # Restarts the service.
        def restart
          run "#{try_sudo} /sbin/service puppet restart"
        end

        # Immediately shuts down the service.
        def shutdown
          run "#{try_sudo} /sbin/service puppet stop"
        end

        # Starts the service.
        def start
          run "#{try_sudo} /sbin/service puppet start"
        end

        # Current status.
        def status
          run "#{try_sudo} /sbin/service puppet status"
        end        

        # Stops the service.
        def stop
          run "#{try_sudo} /sbin/service puppet stop"
        end

        # Force reloads the service.
        def forcereload
          run "#{try_sudo} /sbin/service puppet force-reload"
        end

        def self.load_into(capistrano_config)
          capistrano_config.load do
            
            _cset(:puppet_init)    { Capistrano::Puppet::Service.default_service }
            
            namespace :puppet do

              desc 'Restarts if already running'
              task :condrestart, :roles => :master, :except => {:no_release => true} do
                run "#{try_sudo}/sbin/service puppet condrestart"
              end
              
              desc 'Exits after running the configuration once'
              task :once, :roles => :master, :except => {:no_release => true} do
                run "#{try_sudo}/sbin/service puppet once"
              end
            end
          end
        end

        # Performs a check on the remote hosts to determine whether everything
        # is setup such that a deploy could succeed.
        def check!
          Capistrano::Deploy::Dependencies.new(configuration) do |d|
            d.remote.file(Capistrano::Puppet::Service::Webrick::SERVICE_INIT).or("`#{Capistrano::Puppet::Service::Webrick::SERVICE_INIT}' does not exist. Please run `cap deploy:setup'.")
          end
        end        
      end
    end
  end
end

if Capistrano::Configuration.instance
  Capistrano::Puppet::Service::Webrick.load_into(Capistrano::Configuration.instance)
end