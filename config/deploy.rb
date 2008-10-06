set :application, "importer"
set :repository,  "git://github.com/Shopify/importer.git"
 
 
set :scm, :git
set :user, 'deploy'
set :deploy_via, :remote_cache
set :scm_verbose, true
set :use_sudo, false
 
role :app, "apps.shopifyapps.com"
role :web, "apps.shopifyapps.com"
role :db,  "apps.shopifyapps.com", :primary => true
 
namespace :deploy do
  desc "Restart Application"
  task :restart do
    run "touch #{current_path}/tmp/restart.txt"
  end
  task :start do
    puts '!! Start Apache'
  end
  
  task :stop do
    puts '!! Stop Apache'
  end
end
                                  
before 'deploy:symlink', 'deploy:migrate'