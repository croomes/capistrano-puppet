module Capistrano
  class PuppetDeploy

    # =========================================================================
    # These are the tasks that are available to help with deploying Puppet 
    # configs.
    # =========================================================================

    namespace :deploy do
      desc <<-DESC
        Deploys your Puppet configuration. This calls both `update' and \
        `restart'. Note that this will generally only work for applications that \
        have already been deployed once. For a "cold" deploy, you'll want to \
        take a look at the `deploy:cold' task, which handles the cold start \
        specifically.
      DESC
      task :default do
        update
        restart
      end

      desc <<-DESC
        Prepares one or more servers for deployment. Before you can use any \
        of the Capistrano deployment tasks with your project, you will need to \
        make sure all of your servers have been prepared with `cap deploy:setup'. When \
        you add a new server to your cluster, you can easily run the setup task \
        on just that server by specifying the HOSTS environment variable:

          $ cap HOSTS=new.server.com deploy:setup

        It is safe to run this task on servers that have already been set up; it \
        will not destroy any deployed revisions or data.
      DESC
      task :setup, :except => { :no_release => true } do
        dirs = [deploy_to, releases_path, shared_path]
        dirs += shared_children.map { |d| File.join(shared_path, d.split('/').last) }
        run "#{try_sudo} mkdir -p #{dirs.join(' ')}"
        run "#{try_sudo} chmod g+w #{dirs.join(' ')}" if fetch(:group_writable, true)
      end

      desc <<-DESC
        Copies your project and updates the symlink. It does this in a \
        transaction, so that if either `update_code' or `symlink' fail, all \
        changes made to the remote servers will be rolled back, leaving your \
        system in the same state it was in before `update' was invoked. Usually, \
        you will want to call `deploy' instead of `update', but `update' can be \
        handy if you want to deploy, but not immediately restart your application.
      DESC
      task :update do
        transaction do
          update_code
          create_symlink
        end
      end

      desc <<-DESC
        Copies your project to the remote servers. This is the first stage \
        of any deployment; moving your updated code and assets to the deployment \
        servers. You will rarely call this task directly, however; instead, you \
        should call the `deploy' task (to do a complete deploy) or the `update' \
        task (if you want to perform the `restart' task separately).

        You will need to make sure you set the :scm variable to the source \
        control software you are using (it defaults to :subversion), and the \
        :deploy_via variable to the strategy you want to use to deploy (it \
        defaults to :checkout).
      DESC
      task :update_code, :except => { :no_release => true } do
        on_rollback { run "rm -rf #{release_path}; true" }
        strategy.deploy!
        finalize_update
      end

      desc <<-DESC
        [internal] Touches up the released code. This is called by update_code \
        after the basic deploy finishes. It assumes a Rails project was deployed, \
        so if you are deploying something else, you may want to override this \
        task with your own environment's requirements.

        This task will make the release group-writable (if the :group_writable \
        variable is set to true, which is the default). It will then set up \
        symlinks to the shared directory for the log, system, and tmp/pids \
        directories, and will lastly touch all assets in public/images, \
        public/stylesheets, and public/javascripts so that the times are \
        consistent (so that asset timestamping works).  This touch process \
        is only carried out if the :normalize_asset_timestamps variable is \
        set to true, which is the default The asset directories can be overridden \
        using the :public_children variable.
      DESC
      task :finalize_update, :except => { :no_release => true } do
        escaped_release = latest_release.to_s.shellescape
        commands = []
        commands << "chmod -R -- g+w #{escaped_release}" if fetch(:group_writable, true)

        # mkdir -p is making sure that the directories are there for some SCM's that don't
        # save empty folders
        shared_children.map do |dir|
          d = dir.shellescape
          if (dir.rindex('/')) then
            commands += ["rm -rf -- #{escaped_release}/#{d}",
                        "mkdir -p -- #{escaped_release}/#{dir.slice(0..(dir.rindex('/'))).shellescape}"]
          else
            commands << "rm -rf -- #{escaped_release}/#{d}"
          end
          commands << "ln -s -- #{shared_path}/#{dir.split('/').last.shellescape} #{escaped_release}/#{d}"
        end

        run commands.join(' && ') if commands.any?

      end

      desc <<-DESC
        Updates the symlink to the most recently deployed version. Capistrano works \
        by putting each new release of your application in its own directory. When \
        you deploy a new version, this task's job is to update the `current' symlink \
        to point at the new version. You will rarely need to call this task \
        directly; instead, use the `deploy' task (which performs a complete \
        deploy, including `restart') or the 'update' task (which does everything \
        except `restart').
      DESC
      task :create_symlink, :except => { :no_release => true } do
        on_rollback do
          if previous_release
            run "#{try_sudo} rm -f #{current_path}; #{try_sudo} ln -s #{previous_release} #{current_path}; true"
          else
            logger.important "no previous release to rollback to, rollback of symlink skipped"
          end
        end
        # run "test -d #{current_path} && #{try_sudo} mv #{current_path} #{current_path}.deploysave"
        run "#{try_sudo} rm -f #{current_path} && #{try_sudo} ln -s #{latest_release} #{current_path}"
      end

      desc <<-DESC
        Copy files to the currently deployed version. This is useful for updating \
        files piecemeal, such as when you need to quickly deploy only a single \
        file. Some files, such as updated templates, images, or stylesheets, \
        might not require a full deploy, and especially in emergency situations \
        it can be handy to just push the updates to production, quickly.

        To use this task, specify the files and directories you want to copy as a \
        comma-delimited list in the FILES environment variable. All directories \
        will be processed recursively, with all files being pushed to the \
        deployment servers.

          $ cap deploy:upload FILES=templates,controller.rb

        Dir globs are also supported:

          $ cap deploy:upload FILES='config/apache/*.conf'
      DESC
      task :upload, :except => { :no_release => true } do
        files = (ENV["FILES"] || "").split(",").map { |f| Dir[f.strip] }.flatten
        abort "Please specify at least one file or directory to update (via the FILES environment variable)" if files.empty?

        files.each { |file| top.upload(file, File.join(current_path, file)) }
      end

      desc <<-DESC
        Blank task exists as a hook into which to install your own environment \
        specific behaviour.
      DESC
      task :restart, :roles => :app, :except => { :no_release => true } do
        # Empty Task to overload with your platform specifics
      end

      namespace :rollback do
        desc <<-DESC
          [internal] Points the current symlink at the previous revision.
          This is called by the rollback sequence, and should rarely (if
          ever) need to be called directly.
        DESC
        task :revision, :except => { :no_release => true } do
          if previous_release
            run "#{sudo_try} rm #{current_path}; #{sudo_try} ln -s #{previous_release} #{current_path}"
          else
            abort "could not rollback the code because there is no prior release"
          end
        end

        desc <<-DESC
          [internal] Removes the most recently deployed release.
          This is called by the rollback sequence, and should rarely
          (if ever) need to be called directly.
        DESC
        task :cleanup, :except => { :no_release => true } do
          run "if [ `readlink #{current_path}` != #{current_release} ]; then rm -rf #{current_release}; fi"
        end

        desc <<-DESC
          Rolls back to the previously deployed version. The `current' symlink will \
          be updated to point at the previously deployed version, and then the \
          current release will be removed from the servers. You'll generally want \
          to call `rollback' instead, as it performs a `restart' as well.
        DESC
        task :code, :except => { :no_release => true } do
          revision
          cleanup
        end

        desc <<-DESC
          Rolls back to a previous version and restarts. This is handy if you ever \
          discover that you've deployed a lemon; `cap rollback' and you're right \
          back where you were, on the previously deployed version.
        DESC
        task :default do
          revision
          restart
          cleanup
        end
      end

      desc <<-DESC
        Clean up old releases. By default, the last 5 releases are kept on each \
        server (though you can change this with the keep_releases variable). All \
        other deployed revisions are removed from the servers. By default, this \
        will use sudo to clean up the old releases, but if sudo is not available \
        for your environment, set the :use_sudo variable to false instead.
      DESC
      task :cleanup, :except => { :no_release => true } do
        count = fetch(:keep_releases, 5).to_i
        local_releases = capture("ls -xt #{releases_path}").split.reverse
        if count >= local_releases.length
          logger.important "no old releases to clean up"
        else
          logger.info "keeping #{count} of #{local_releases.length} deployed releases"
          directories = (local_releases - local_releases.last(count)).map { |release|
            File.join(releases_path, release) }.join(" ")

          try_sudo "rm -rf #{directories}"
        end
      end

      desc <<-DESC
        Test deployment dependencies. Checks things like directory permissions, \
        necessary utilities, and so forth, reporting on the things that appear to \
        be incorrect or missing. This is good for making sure a deploy has a \
        chance of working before you actually run `cap deploy'.

        You can define your own dependencies, as well, using the `depend' method:

          depend :remote, :gem, "tzinfo", ">=0.3.3"
          depend :local, :command, "svn"
          depend :remote, :directory, "/u/depot/files"
      DESC
      task :check, :except => { :no_release => true } do
        dependencies = strategy.check!

        other = fetch(:dependencies, {})
        other.each do |location, types|
          types.each do |type, calls|
            if type == :gem
              dependencies.send(location).command(fetch(:gem_command, "gem")).or("`gem' command could not be found. Try setting :gem_command")
            end

            calls.each do |args|
              dependencies.send(location).send(type, *args)
            end
          end
        end

        if dependencies.pass?
          puts "You appear to have all necessary dependencies installed"
        else
          puts "The following dependencies failed. Please check them and try again:"
          dependencies.reject { |d| d.pass? }.each do |d|
            puts "--> #{d.message}"
          end
          abort
        end
      end

      desc <<-DESC
        Deploys and starts a `cold' application. This is useful if you have not \
        deployed your application before, or if your application is (for some \
        other reason) not currently running. It will deploy the code, run any \
        pending migrations, and then instead of invoking `deploy:restart', it will \
        invoke `deploy:start' to fire up the application servers.
      DESC
      task :cold do
        update
        migrate
        start
      end

      desc <<-DESC
        Blank task exists as a hook into which to install your own environment \
        specific behaviour.
      DESC
      task :start, :roles => :app do
        # Empty Task to overload with your platform specifics
      end

      desc <<-DESC
        Blank task exists as a hook into which to install your own environment \
        specific behaviour.
      DESC
      task :stop, :roles => :app do
        # Empty Task to overload with your platform specifics
      end

      namespace :pending do
        desc <<-DESC
          Displays the `diff' since your last deploy. This is useful if you want \
          to examine what changes are about to be deployed. Note that this might \
          not be supported on all SCM's.
        DESC
        task :diff, :except => { :no_release => true } do
          system(source.local.diff(current_revision))
        end

        desc <<-DESC
          Displays the commits since your last deploy. This is good for a summary \
          of the changes that have occurred since the last deploy. Note that this \
          might not be supported on all SCM's.
        DESC
        task :default, :except => { :no_release => true } do
          from = source.next_revision(current_revision)
          system(source.local.log(from))
        end
      end
    end
  end
end
