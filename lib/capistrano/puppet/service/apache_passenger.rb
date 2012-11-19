require 'capistrano/puppet/service/base'

module Capistrano
  module Puppet
    module Service
      # A service module for using Apache/Passenger as the Puppet Master Web
      # and Rack Servers.
      #
      # CONFIGURATION
      # -------------
      #
      # Use this plugin by adding the following line in your config/deploy.rb:
      #
      #   set :puppet_service, :apache_passenger
      #
      class ApachePassenger < Base
        
        ADDITIONAL_TASKS = [
        ]
        
        # Enables the service for starting on boot.
        def enable
          raise NotImplementedError, "`enable' is not implemented by #{self.class.name}"
        end
        
        # Disables the service from starting at boot.
        def disable
          raise NotImplementedError, "`disable' is not implemented by #{self.class.name}"
        end        
        
        # Reloads the configuration and restarts the service if required.
        def reload
          raise NotImplementedError, "`reload' is not implemented by #{self.class.name}"
        end

        # Restarts the service.
        def restart
          run "service status httpd"
        end

        # Shuts down the service.
        def shutdown
          raise NotImplementedError, "`shutdown' is not implemented by #{self.class.name}"
        end
        
        # Starts the service.
        def start
          raise NotImplementedError, "`start' is not implemented by #{self.class.name}"
        end

        # Current status.
        def status
          raise NotImplementedError, "`status' is not implemented by #{self.class.name}"
        end        
        
        # Stops the service.
        def stop
          raise NotImplementedError, "`stop' is not implemented by #{self.class.name}"
        end   

        def self.load_into(capistrano_config)
          capistrano_config.load do
            namespace :puppet do
              # TODO: add additional tasks
            end
          end
        end             
      end
    end
  end
end

if Capistrano::Configuration.instance
  Capistrano::Puppet::Service::ApachePassenger.load_into(Capistrano::Configuration.instance)
end