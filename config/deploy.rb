set :application, "auctioneer"
set :repository,  "git@fortress.jadedpixel.com:ebay.git"
 
 
set :scm, :git
set :user, 'deploy'
set :deploy_via, :remote_cache
set :scm_verbose, true
set :use_sudo, false
 
role :app, "tobi1.jadedpixel.com"
role :web, "tobi1.jadedpixel.com"
role :db,  "tobi1.jadedpixel.com", :primary => true
 
namespace :deploy do
  desc "Restart Application"
  task :restart do
    run "touch #{current_path}/tmp/restart.txt"
  end
  task :start do
  end
  task :stop do
  end
end
                                  
before 'deploy:symlink', 'deploy:migrate'