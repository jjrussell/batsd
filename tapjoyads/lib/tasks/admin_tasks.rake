namespace :admin do
  
  desc "Deletes all but the last 15 deploy branches"
  task :cleanup_deploys do
    settings = YAML::load_file("#{RAILS_ROOT}/server/configuration.yaml")
    current_version = settings['config']["api_deploy_version"].to_i
    branches = `svn ls https://tapjoy.unfuddle.com/svn/tapjoy_tapjoyads/deploy`
    branches.split("/\n").each do |version|
      next if version.to_i > current_version - 15
      puts "Deleting branch: deploy/#{version}"
      `svn delete https://tapjoy.unfuddle.com/svn/tapjoy_tapjoyads/deploy/#{version} -m 'deleteing old deploy branch'`
    end
  end
  
  desc "Restarts apache on all the webservers"
  task :restart_apache do
    system("script/cloudrun 'webserver' 'sleep 5 ; sudo /etc/init.d/apache2 restart' 'ubuntu' 'remove_from_lb'")
  end
  
  desc "Lists the contents of the tmp dirs on each job machine for *sdb* and *s3*"
  task :view_long_jobs do
    system("script/cloudrun 'jobserver' 'ls -lh tapjoyads/tmp/*sdb* tapjoyads/tmp/*s3* 2> /dev/null'")
  end
  
end
