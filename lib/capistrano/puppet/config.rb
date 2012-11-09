module Capistrano
  class PuppetConfig
   
    # Taken from the capistrano code.
    def _cset(name, *args, &block)
      unless exists?(name)
        set(name, *args, &block)
      end
    end

    # =========================================================================
    # These variables MUST be set in the client capfiles. If they are not set,
    # the deploy will fail with an error.
    # =========================================================================

    _cset(:application) { abort "Please specify the name of your application, set :application, 'foo'" }
    _cset(:repository)  { abort "Please specify the repository that houses your application's code, set :repository, 'foo'" }

    # =========================================================================
    # These variables may be set in the client capfile if their default values
    # are not sufficient.
    # =========================================================================

    _cset(:scm) { scm_default }
    _cset :deploy_via, :checkout

    _cset(:deploy_to) { "/u/apps/#{application}" }
    _cset(:revision)  { source.head }

    # =========================================================================
    # These variables should NOT be changed unless you are very confident in
    # what you are doing. Make sure you understand all the implications of your
    # changes if you do decide to muck with these!
    # =========================================================================

    _cset(:source)            { Capistrano::Deploy::SCM.new(scm, self) }
    _cset(:real_revision)     { source.local.query_revision(revision) { |cmd| with_env("LC_ALL", "C") { run_locally(cmd) } } }

    _cset(:strategy)          { Capistrano::Deploy::Strategy.new(deploy_via, self) }

    # If overriding release name, please also select an appropriate setting for :releases below.
    _cset(:release_name)      { set :deploy_timestamped, true; Time.now.utc.strftime("%Y%m%d%H%M%S") }

    _cset :version_dir,       "releases"
    _cset :shared_dir,        "shared"
    # _cset :shared_children,   %w(public/system log tmp/pids)
    _cset :shared_children,   %w()
    _cset :current_dir,       "current"

    _cset(:releases_path)     { File.join(deploy_to, version_dir) }
    _cset(:shared_path)       { File.join(deploy_to, shared_dir) }
    _cset(:current_path)      { File.join(deploy_to, current_dir) }
    _cset(:release_path)      { File.join(releases_path, release_name) }

    _cset(:releases)          { capture("ls -x #{releases_path}", :except => { :no_release => true }).split.sort }
    _cset(:current_release)   { releases.length > 0 ? File.join(releases_path, releases.last) : nil }
    _cset(:previous_release)  { releases.length > 1 ? File.join(releases_path, releases[-2]) : nil }

    _cset(:current_revision)  { capture("cat #{current_path}/REVISION",     :except => { :no_release => true }).chomp }
    _cset(:latest_revision)   { capture("cat #{current_release}/REVISION",  :except => { :no_release => true }).chomp }
    _cset(:previous_revision) { capture("cat #{previous_release}/REVISION", :except => { :no_release => true }).chomp if previous_release }

    _cset(:run_method)        { fetch(:use_sudo, true) ? :sudo : :run }
    
    _cset :web_server,        "webrick" # 'passenger' also supported

    # some tasks, like symlink, need to always point at the latest release, but
    # they can also (occassionally) be called standalone. In the standalone case,
    # the timestamped release_path will be inaccurate, since the directory won't
    # actually exist. This variable lets tasks like symlink work either in the
    # standalone case, or during deployment.
    _cset(:latest_release) { exists?(:deploy_timestamped) ? release_path : current_release }

    # =========================================================================
    # These are helper methods that will be available to your recipes.
    # =========================================================================

    # Checks known version control directories to intelligently set the version 
    # control in-use. For example, if a .svn directory exists in the project, 
    # it will set the :scm variable to :subversion, if a .git directory exists 
    # in the project, it will set the :scm variable to :git and so on. If no 
    # directory is found, it will default to :git.
    def scm_default
      if File.exist? '.git'
        :git
      elsif File.exist? '.accurev'
        :accurev
      elsif File.exist? '.bzr'
        :bzr
      elsif File.exist? '.cvs'
        :cvs
      elsif File.exist? '_darcs'
        :darcs
      elsif File.exist? '.hg'
        :mercurial
      elsif File.exist? '.perforce'
        :perforce
      elsif File.exist? '.svn'
        :subversion
      else
        :none
      end
    end   
  end
end
