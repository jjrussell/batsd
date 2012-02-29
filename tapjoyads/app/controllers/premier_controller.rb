class PremierController < WebsiteController
  layout 'tabbed'
  current_tab :premier

  filter_access_to :all

  before_filter :set_partner
  before_filter :nag_user_about_payout_info
  after_filter :save_activity_logs, :only => [ :update ]

  def edit
    @is_new = !@partner.is_premier?

    if @is_new || @partner.exclusivity_level.nil?
      @levels = ExclusivityLevel::TYPES
      @default_level = @levels.last
    else
      @levels = ExclusivityLevel::TYPES.reject{|t| t.constantize.new.months < @partner.exclusivity_level.months}
      @default_level = @levels.first
    end
    @levels = @levels.map{|t|[t.underscore.humanize.pluralize, t]}
  end

private

  def set_partner
    @partner = current_partner
  end
end
