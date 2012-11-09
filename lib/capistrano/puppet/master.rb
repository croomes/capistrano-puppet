module Capistrano
  class PuppetMaster

    # =========================================================================
    # These are the tasks that are available to help with managing a Puppet,
    # Master. You can have cap give you a summary of them with `cap -T'.
    # =========================================================================

    namespace :master do
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
        case $web_server in
          'webrick'   then run "service restart puppetmasterd"
          'passenger' then run "touch #{current_path}/tmp/restart.txt"
        else
          abort "Unknown Web server"
        end
      end
    end
  end
end