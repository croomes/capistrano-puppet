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
          'puppet:build_passenger',
          'puppet:symlink_apache',
          'puppet:set_user',
        ]
        
        # Enables the service for starting on boot.
        def enable
          run "#{try_sudo} /sbin/chkconfig httpd on"
        end
        
        # Disables the service from starting at boot.
        def disable
          run "#{try_sudo} /sbin/chkconfig httpd off"
        end        
        
        # Reloads the configuration and restarts the service if required.
        def reload
          run "touch #{current_path}/rack/tmp/restart.txt"
        end

        # Restarts the service.
        def restart
          run "#{try_sudo} /sbin/service httpd restart"
        end

        # Shuts down the service.
        def shutdown
          run "#{try_sudo} /sbin/service httpd stop"
        end
        
        # Starts the service.
        def start
          run "#{try_sudo} /sbin/service httpd start"
        end

        # Current status.
        def status
          run "/sbin/service httpd status"
        end        
        
        # Stops the service.
        def stop
          run "#{try_sudo} /sbin/service httpd stop"
        end

        # Symlink tasks
        def create_symlink(source = "#{release_path}/rack/apache2.conf", dest = "/etc/httpd/conf.d/puppet.conf")
          run "(test -L #{dest} &&  [ `readlink #{dest}` == #{source} ]) || (test -L #{dest} && #{try_sudo} rm #{dest} || true)"
          run "test -L #{dest} || #{try_sudo} ln -s #{source} #{dest}"
        end

        def rollback_symlink(source = "#{previous_release}/rack/apache2.conf", dest = "/etc/httpd/conf.d/puppet.conf")
          if previous_release
            run "(test -L #{dest} &&  [ `readlink #{dest}` == #{source} ]) || #{try_sudo} rm #{dest}"
            run "test -L #{dest} || #{try_sudo} ln -s #{source} #{dest}"
          else
            logger.important "no previous release to rollback to, rollback of symlink skipped"
          end
        end

        # Deployment tasks
        def update_code!
        end

        def finalize_update
          build_passenger
          set_user(puppet_user, puppet_group)
        end

        def set_user(user, group)
          run "#{try_sudo} sudo chown #{user}:#{group} #{release_path}/rack/config.ru"
        end

        def build_passenger
          run "test -f ${GEM_HOME}/gems/passenger-*/ext/apache2/mod_passenger.so || (cd #{release_path} && passenger-install-apache2-module -a)"
        end  

        def self.load_into(capistrano_config)
          capistrano_config.load do
            before(Capistrano::Puppet::Service::ApachePassenger::ADDITIONAL_TASKS) do

              # Vars used by service must be copied here
              _cset(:service)             { Capistrano::Puppet::Service.new(self)}
              _cset(:release_name)        { set :deploy_timestamped, true; Time.now.utc.strftime("%Y%m%d%H%M%S") }
              _cset(:version_dir)         { "releases" }
              _cset(:current_dir)         { "current" }
              _cset(:releases_path)       { File.join(deploy_to, version_dir) }
              _cset(:current_path)        { File.join(deploy_to, current_dir) }
              _cset(:release_path)        { File.join(releases_path, release_name) }

              _cset(:apache_conf)         { "/etc/httpd/conf.d/puppet.conf" }
              _cset(:apache_conf_source)  { "#{release_path}/rack/apache2.conf" }

              _cset(:puppet_user)         { "puppet" }
              _cset(:puppet_group)        { "puppet" }

            end

            namespace :puppet do

              desc 'Builds Passenger Apache extensions'
              task :build_passenger, :roles => :master, :except => {:no_release => true} do
                 service.build_passenger
              end

              desc '[internal] Symlinks Apache config'
              task :symlink_apache, :roles => :master, :except => {:no_release => true} do
                service.create_symlink(apache_conf_source, apache_conf)
              end

              desc '[internal] Sets the user to run Puppet as'
              task :set_user, :roles => :master, :except => {:no_release => true} do
                service.set_user(puppet_user, puppet_group)
              end
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
