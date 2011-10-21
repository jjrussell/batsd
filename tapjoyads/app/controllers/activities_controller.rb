class ActivitiesController < WebsiteController
  layout 'tabbed'
  current_tab :tools

  filter_access_to :all

  def index
    where_clause = '`updated-at` is not null';
    where_clause += " and object_id = '#{params[:object_id]}'" unless params[:object_id].blank?
    where_clause += " and user = '#{params[:user]}'" unless params[:user].blank?
    where_clause += " and request_id = '#{params[:request_id]}'" unless params[:request_id].blank?
    where_clause += " and partner_id = '#{params[:partner_id]}'" unless params[:partner_id].blank?

    response = ActivityLog.select(:where => where_clause, :order_by => '`updated-at` desc', :next_token => params[:next_token])
    @activities = response[:items]
    @next_token = response[:next_token]
  end
end
