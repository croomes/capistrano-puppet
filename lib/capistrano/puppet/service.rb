require 'capistrano/puppet/deploy'

module Capistrano
  module Puppet
    module Service
      TASKS = [
        'puppet:enable',
        'puppet:disable',
        'puppet:reload',
        'puppet:restart',
        'puppet:shutdown',
        'puppet:start',
        'puppet:stop',
      ]
      
      def self.new(config={})

        # Determine the service type if not specified.
        config[:puppet_service] ||= Service.default_service

        service_file = "capistrano/puppet/service/#{config[:puppet_service]}"
        require(service_file)

        service_const = config[:puppet_service].to_s.capitalize.gsub(/_(.)/) { $1.upcase }
        if const_defined?(service_const)
          const_get(service_const).new(config)
        else
          raise Capistrano::Error, "could not find `#{name}::#{service_const}' in `#{service_file}'"
        end
      rescue LoadError
        raise Capistrano::Error, "could not find any service named `#{config[:puppet_service]}', consider setting `puppet_service'"
      end

      # Checks known files to try to intelligently guess the service in
      # use.  This needs a lot of work to be of any use, specifying 
      # :default_service manually in config/deploy.rb is probably the only sane
      # method for now.
      def self.default_service
        if File.exist? '/etc/init.d/httpd'
          :apache_passenger
        else
          :webrick
        end
      end
      
      def self.load_into(capistrano_config)
        capistrano_config.load do
          before(Capistrano::Puppet::Service::TASKS) do
            # =========================================================================
            # These variables MUST be set in the client capfiles. If they are not set,
            # the deploy will fail with an error.
            # =========================================================================
            _cset(:puppet_service)    { Capistrano::Puppet::Service.default_service }

            # =========================================================================
            # These variables may be set in the client capfile if their default values
            # are not sufficient.
            # =========================================================================

            # =========================================================================
            # These variables should NOT be changed unless you are very confident in
            # what you are doing. Make sure you understand all the implications of your
            # changes if you do decide to muck with these!
            # =========================================================================
            _cset(:service)           { Capistrano::Puppet::Service.new(self) }

            # puts variables.to_yaml
          end

          # =========================================================================
          # These are helper methods that will be available to your recipes.
          # =========================================================================


          
          # =========================================================================
          # These are the base tasks that are available for managing the Puppet 
          # service.  Additional tasks may be defined by services, though the
          # services must be loaded explicitly in your Capfile to be available.  If 
          # the base tasks are adequate this is not required.
          # You can have cap give you a summary of them with `cap -T'.
          # =========================================================================
          
          namespace :puppet do
            desc 'Start Puppet master process'
            task :start, :roles => :master, :except => {:no_release => true} do
              service.start
            end

            desc 'Stop Puppet'
            task :stop, :roles => :master, :except => {:no_release => true} do
              service.stop
            end

            desc 'Immediately shutdown Puppet'
            task :shutdown, :roles => :master, :except => {:no_release => true} do
              service.shutdown
            end

            desc 'Restart Puppet'
            task :restart, :roles => :master, :except => {:no_release => true} do
              service.restart
            end

            desc 'Reload Puppet'
            task :reload, :roles => :master, :except => {:no_release => true} do
              service.reload
            end
          end
        end
      end
    end
  end
end

if Capistrano::Configuration.instance
  Capistrano::Puppet::Service.load_into(Capistrano::Configuration.instance)
end