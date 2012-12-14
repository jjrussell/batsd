# HACK since the localeapp gem needs to load before acts_as_approvable in order to avoid a load-time exception
require 'localeapp/rails' if defined? Localeapp
load 'approvable_sources.rb'

ActsAsApprovable.view_language = 'haml'
ActsAsApprovable.stale_check = false

ActsAsApprovable::Ownership.configure(:source => ApprovableSources)
Approval.send(:include, UuidPrimaryKey)

