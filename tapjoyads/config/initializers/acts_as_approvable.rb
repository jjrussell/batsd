require 'approvable_sources'

ActsAsApprovable.view_language = 'haml'
ActsAsApprovable::Ownership.configure(:source => ApprovableSources)
Approval.send(:include, UuidPrimaryKey)
