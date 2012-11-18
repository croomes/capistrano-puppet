require 'capistrano/puppet/version'
require 'capistrano/puppet/service'
require 'capistrano/puppet/deploy'

# module Capistrano
#   class Puppet
#     def self.load_into(capistrano_configuration)
#       Configuration.instance(true).load do
# 
#         require 'benchmark'
#         require 'yaml'
#         require 'shellwords'
#         require 'capistrano/recipes/deploy/scm'
#         require 'capistrano/recipes/deploy/strategy'
#         require 'capistrano/puppet/config'
#         # require 'capistrano/puppet/helpers'       
#         # require 'capistrano/puppet/deploy'
#         # require 'capistrano/puppet/service'
#         # require 'capistrano/puppet/master'
#         
#         # Taken from the capistrano code.
#         def _cset(name, *args, &block)
#           unless exists?(name)
#             set(name, *args, &block)
#           end
#         end        
#     
#         namespace :deploy do
#           desc <<-DESC
#             Deploys your project. This calls both `update' and `restart'. Note that \
#             this will generally only work for applications that have already been deployed \
#             once. For a "cold" deploy, you'll want to take a look at the `deploy:cold' \
#             task, which handles the cold start specifically.
#           DESC
#           task :default do
#             update
#             restart
#           end
#       
#           desc <<-DESC
#             Restarts the Puppet Master
#           DESC
#           task :restart, :roles => :master do
#             # Empty Task to overload with your platform specifics
#           end      
#         end 
#       end  
#     end
#   end
# end
# if Capistrano::Configuration.instance
#   Capistrano::Puppet.load_into(Capistrano::Configuration.instance)
# end