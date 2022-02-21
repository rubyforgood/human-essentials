desc "This task is called by the Heroku scheduler add-on to sync up NDBNMember records"
task :sync_ndbn_members => :environment do
  SyncNDBNMembers.sync
end

