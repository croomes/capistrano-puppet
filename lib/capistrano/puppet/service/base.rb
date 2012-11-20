require 'capistrano/recipes/deploy/dependencies'

module Capistrano
  module Puppet
    module Service

      # The ancestor class for all Puppet Service implementations. It provides
      # minimal infrastructure for subclasses to build upon and override.
      class Base
        
        # The options available for this service instance to reference. Should be
        # treated like a hash.
        attr_reader :configuration

        # Creates a new service instance with the given configuration options.
        def initialize(configuration={})
          @configuration = configuration
          
          # Create method stubs for the base tasks that all services should 
          # implement, plus any others that are specific to the service.
          (TASKS << self.class::ADDITIONAL_TASKS).flatten.each { |name| Base.define_task(name.gsub(/puppet:/, '')) }
        end

        # Defines a method stub for a task.
        def self.define_task(name)
          define_method(name) {
            raise NotImplementedError, "`#{name}' is not implemented by #{self.class.name}"
          }
        end

        # Stubs for implmenting in services (optional)
        def symlink(source = nil, dest = nil)
        end

        def rollback_symlink(source = nil, dest = nil)
        end

        def set_user(user = nil, group = nil)
        end

        def deploy!
        end
        
        # Performs a check on the remote hosts to determine whether everything
        # is setup such that a deploy could succeed.
        def check!
          Capistrano::Deploy::Dependencies.new(configuration) do |d|
            puts "XXX"
            # d.remote.directory(configuration[:releases_path]).or("`#{configuration[:releases_path]}' does not exist. Please run `cap deploy:setup'.")
            # d.remote.writable(configuration[:deploy_to]).or("You do not have permissions to write to `#{configuration[:deploy_to]}'.")
            # d.remote.writable(configuration[:releases_path]).or("You do not have permissions to write to `#{configuration[:releases_path]}'.")
          end
        end        

        protected

          # This is to allow helper methods like "run" and "put" to be more
          # easily accessible to strategy implementations.
          def method_missing(sym, *args, &block)
            if configuration.respond_to?(sym)
              configuration.send(sym, *args, &block)
            else
              super
            end
          end
          
        private

          # A reference to a Logger instance that the service can use to log
          # activity.
          def logger
            @logger ||= variable(:logger) || Capistrano::Logger.new(:output => STDOUT)
          end
      end
    end
  end
end
