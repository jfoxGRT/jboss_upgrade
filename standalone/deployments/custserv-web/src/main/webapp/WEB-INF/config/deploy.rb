require 'mongrel_cluster/recipes'

set :application, "custserv"
set :repository,  "https://wush.net/svn/grassroots-tech/branches/production/central/custserv-web"
set :mongrel_conf, "/etc/mongrel_cluster/custserv.yml"
set :user, "root"

# If you aren't deploying to /u/apps/#{application} on the target
# servers (which is the default), you can specify the actual location
# via the :deploy_to variable:
# set :deploy_to, "/var/www/#{application}"

# If you aren't using Subversion to manage your source code, specify
# your SCM below:
# set :scm, :subversion

role :app, "app01", "app02"
role :web, "apache01"

desc "Custom restart task for mongrel cluster"
task :restart, :roles => :app, :except => { :no_release => true } do
  mongrel.cluster.restart
end