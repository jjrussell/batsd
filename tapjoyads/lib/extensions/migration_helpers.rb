module MigrationHelpers
  def add_guid_column(*args)
    options = args.extract_options!
    add_column(args.first, args.second, 'char(36) binary', options)
  end
end

class ActiveRecord::Migration
  extend MigrationHelpers
end
