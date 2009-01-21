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

Configs = ['config/importer.yml', 'config/database.yml', 'config/shopify.yml']

task :after_update_code do
  Configs.each do |y|
    run "ln -nfs #{deploy_to}/#{y} #{release_path}/#{y}"
  end
end

task :update_configs do
  run "mkdir -p #{deploy_to}/config"
  
  Configs.each do |y|
    put File.read(y), "#{deploy_to}/#{y}"
  end
end