require 'active_record'

require 'acts_as_approvable/acts_as_approvable'
require 'acts_as_approvable/approval'

module ActsAsApprovable
  def self.enable
    @enabled = true
  end

  def self.disable
    @enabled = false
  end

  def self.enabled?
    @enabled ||= true
  end

  def self.owner_model=(model)
    Approval.owner_model = model
  end

    def self.owner_records=(meth)
    @owner_records = meth
  end

  def self.owner_records
    return [] unless @owner_records.present?

    if @owner_records.is_a?(Proc)
      @owner_records.call
    else
      Approval.owner_model.all(@owner_records)
    end
  end

  def self.owner_select=(meth)
    @owner_select = meth
  end

  def self.owner_select
    return [] unless @owner_select.present?

    if @owner_records.is_a?(Proc)
      @owner_select.call(owner_records)
    else
      @owner_select.map { |o| [o.login, o.id] }
    end
  end

  def self.view_language=(lang)
    @lang = lang
  end

  def self.view_language
    @lang || 'erb'
  end
end
