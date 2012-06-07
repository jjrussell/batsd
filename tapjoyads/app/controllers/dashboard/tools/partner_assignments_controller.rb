class Dashboard::Tools::PartnerAssignmentsController < Dashboard::DashboardController
  layout 'tabbed'
  current_tab :tools
  filter_access_to :all
  before_filter :find_partner_assignment
  after_filter :save_activity_logs, :only => [ :create, :destroy ]

  def create
    if @partner.users.include?(@user)
      flash[:error] = "<b>#{@user.email}</b> already has access to <b>#{@partner.name}</b>."
    elsif @user.partners << @partner
      flash[:notice] = "<b>#{@user.email}</b> now has access to <b>#{@partner.name}</b>."
    else
      flash[:error] = "could not grant access to <b>#{@partner.name}</b> to <b>#{@user.email}</b>."
    end
    redirect_to :back
  end

  def destroy
    if @user.id == User::USERLESS_PARTNER_USER_ID
      flash[:error] = "Invalid user for this action"
    elsif @partner.remove_user(@user)
      flash[:notice] = "<b>#{@user.email}</b> no longer has access to <b>#{@partner.name}</b>."
    else
      flash[:error] = "could not revoke access to <b>#{@partner.name}</b> from <b>#{@user.email}</b>."
    end
    redirect_to :back
  end

  private
  def find_partner_assignment
    @user = User.find(params[:user_id])
    if params[:id].present?
      @partner_assignment = @user.partner_assignments.find_by_id(params[:id])
    else
      @partner_assignment = @user.partner_assignments.build(:partner_id => params[:partner_id])
    end
    @partner = @partner_assignment.partner
    log_activity(@user, :included_methods => [ :partner_ids ])
  end
end

