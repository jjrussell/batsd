class Dashboard::Tools::PayoutsController < Dashboard::DashboardController
  layout 'tabbed'
  current_tab :tools
  filter_access_to :all
  before_filter :load_payouts_list, :only => [ :index, :export ]
  after_filter :save_activity_logs, :only => [ :create, :confirm_payouts ]


  def index
    #TODO Plan to DRY this code with the similar functionality in PartnerValidationsController in the next feature implmentation(PDF export) around this code
    @filter_options = [['All',''], ['Unconfirmed - Actionable', '1'], ['Unconfirmed - No Payout Info','2'], ['Unconfirmed - All', '3'], ['Confirmed', '4']]
    if params[:confirm_filter].present?
      if params[:confirm_filter] == '1'
        @partners = @partners.where("#{Partner.quoted_table_name}.payout_threshold_confirmation = 0 OR #{Partner.quoted_table_name}.payout_info_confirmation = 0")
      elsif params[:confirm_filter] == '2'
        @partners = @partners.where("#{PayoutInfo.quoted_table_name}.id is null")
      elsif params[:confirm_filter] == '3'
        @partners = @partners.where("#{Partner.quoted_table_name}.payout_threshold_confirmation = 0 OR #{Partner.quoted_table_name}.payout_info_confirmation = 0 OR #{PayoutInfo.quoted_table_name}.id is null") #should be unconfirmed
      else
        @partners = @partners.where(:payout_threshold_confirmation => 1, :payout_info_confirmation => 1).where("#{PayoutInfo.quoted_table_name}.id is not null")
      end
    end

    @partners = @partners.paginate(:page => params[:page]) unless params[:print].present?
    @freeze_enabled = PayoutFreeze.enabled?
  end

  def create
    begin
      partner = Partner.find(params[:partner_id])
      payout = partner.make_payout(params[:amount])
      log_activity(payout)
      log_activity(partner)
    rescue ActiveRecord::RecordInvalid => e
      ::Rails.logger.error "Could not create payout: #{e.message}"
    end

    # We use #try(:persisted?) because it will be false-y, meaning we don't need to track the status with an extra variable.
    render :json => { :success => !!payout.try(:persisted?) }
  end

  def confirm_payouts
    partner = Partner.find(params[:partner_id])
    log_activity(partner)
    partner.confirm_for_payout(current_user)
    render :json => { :success => partner.save, :was_confirmed =>  partner.confirmation_notes.blank?, :notes => partner.confirmation_notes, :can_confirm => partner.can_be_confirmed?(current_user) }
  end

  def export
    data = [
      'Partner_Name,Partner_id,Pending_Earnings,Cutoff_Date,Payout_Amount,' <<
      'Current_Payout_Created,Payout_Method,Account_Manager_Email,' <<
      'Confirmed,Notes,Legal_Name,Tax_ID'
     ]
    managers = {}
    User.account_managers.each do |user|
      managers[user.id] = user.email
    end
    @partners.all.each do |partner|
      confirmation_notes = partner.confirmation_notes
      account_manager_email = ''

      partner.users.each do |user|
        account_manager_email = managers[user.id] if managers[user.id]
      end
      line = [
          partner.name.gsub(/[,]/,' '),
          partner.id.gsub(/[,]/,' '),
          NumberHelper.number_to_currency((partner.pending_earnings / 100.0), :delimiter => ''),
          (partner.payout_cutoff_date - 1.day).to_s(:yyyy_mm_dd),
          NumberHelper.number_to_currency((partner.pending_earnings / 100.0 - partner.next_payout_amount / 100.0), :delimiter => ''),
          NumberHelper.number_to_currency((partner.next_payout_amount / 100.0), :delimiter => ''),
          partner.completed_payout_info? ? partner.payout_info.payout_method : '',
          account_manager_email,
          partner.confirmed_for_payout? ? 'Confirmed' : 'Unconfirmed',
          confirmation_notes.present? ? confirmation_notes.join(';').gsub(/[,]/, '_') : '',
          (partner.payout_info.try(:billing_name) || ''),
          (partner.payout_info.try(:decrypt_tax_id) || '')
        ]
      data << line.join(',')
    end
    send_data(data.join("\n"), :type => 'text/csv', :filename => 'Payouts.csv')
  end

  private
  def load_payouts_list
    if params[:year] && params[:month]
      @start_date = Time.zone.parse("#{params[:year]}-#{params[:month]}-01")
      @end_date = @start_date + 1.month
      @partners = Partner.to_payout.payout_info_changed(@start_date, @end_date)
    else
      @partners = Partner.to_payout
    end

    @partners = @partners.includes([:payout_info, :users ])
    @partners = @partners.where('id = ?', params[:partners_filter]) if params[:partners_filter].present?

    if params[:reseller_id]
      @partners = @partners.where(:reseller_id => params[:reseller_id])
    end
  end
end
