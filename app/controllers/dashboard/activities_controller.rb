class Dashboard::ActivitiesController < Dashboard::DashboardController
  layout 'tabbed'
  current_tab :tools

  filter_access_to :all

  def index
    start_date = params[:start_date]
    end_date = params[:end_date]

    Time.zone = current_user.time_zone
    start_time, end_time = nil, nil

    if start_date.present?
      t = Time.parse(start_date + " 00:00:00")
      start_time = Time.zone.local_to_utc(t).to_f
    end

    if end_date.present?
      t = Time.parse(end_date + " 23:59:59")
      end_time = Time.zone.local_to_utc(t).to_f
    end

    where_clause = '`updated-at` is not null'
    where_clause += " and object_id = '#{params[:object_id]}'" unless params[:object_id].blank?
    where_clause += " and user = '#{params[:user]}'" unless params[:user].blank?
    where_clause += " and request_id = '#{params[:request_id]}'" unless params[:request_id].blank?
    where_clause += " and partner_id = '#{params[:partner_id]}'" unless params[:partner_id].blank?
    where_clause += " and object_type = '#{params[:object_type].capitalize}'" unless params[:object_type].blank?
    where_clause += " and `updated-at` >= '#{start_time}'" if start_time
    where_clause += " and `updated-at` <= '#{end_time}'" if end_time
    where_clause += " and after_state like '%\"#{params[:field].downcase}\":%' and after_state not like '%#{params[:field].downcase}\":null%' and after_state not like '%#{params[:field].downcase}\":\"\"%'" if params[:field].present?

    response = ActivityLog.select(:where => where_clause, :order_by => '`updated-at` desc', :next_token => params[:next_token])
    @activities = response[:items]
    @next_token = response[:next_token]
  end
end
