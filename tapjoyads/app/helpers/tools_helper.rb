module ToolsHelper
  def breadcrumb(*links)
    first = true
    content_tag :ul, :class => 'breadcrumb' do
      links.collect do |link|
        if first
          # don't show the divider
          first = false
          link
        else
          "<span class='divider'> / </span> #{link}"
        end
      end
    end
  end

  def location_str(employee)
    employee.location.nil? ? '' : employee.location.inspect
  end

  def click_info_ul(click, reward)
    safe_concat("<ul class='nobr hidden'>")
    concat_li_timestamp("Viewed at", click.viewed_at)
    concat_li_timestamp("Clicked at", click.clicked_at)
    concat_li_timestamp("Installed at", click.installed_at)
    concat_li_timestamp("Manually Resolved at", click.manually_resolved_at)
    if reward.try :sent_currency?
      concat_li_timestamp("Send Currency at", reward.sent_currency)
      concat_li("Award Status", reward.send_currency_status)
    end
    concat_li("Currency", click.currency_reward)
    concat_li_currency('Adv', click.advertiser_amount)
    concat_li_currency('Pub', click.publisher_amount)
    concat_li_currency('Tj', click.tapjoy_amount)
    concat_li("Pub user ID", click.publisher_user_id) if click.publisher_user_id != click.udid
    concat_li("Source", click.source)
    concat_li("UDID's for blocking", click.publisher_user_udids.join('<BR/>')) if click.block_reason =~ /TooManyUdidsForPublisherUserId/
    if click.last_clicked_at?
      safe_concat("<ul>")
      click.last_clicked_at.each_with_index do |last_click_time, idx|
        concat_li_timestamp("Previous click #{idx + 1}", last_click_time)
      end
      safe_concat("</ul>")
    end
    if click.last_installed_at?
      safe_concat("<ul>")
      click.last_installed_at.each_with_index do |last_install_time, idx|
        concat_li_timestamp("Previous install #{idx + 1}", last_install_time)
      end
      safe_concat("</ul>")
    end
    safe_concat("</ul>")
  end

  def click_tr_class(click, reward)
    classes = []
    if click.installed_at?
      if click.force_convert
        classes << 'forced'
      elsif (reward && reward.successful?)
        classes << 'rewarded'
      elsif click.currency_reward_zero?
        classes << 'non-rewarded'
      else
        classes << 'rewarded-failed'
      end
    end
    classes << 'jailbroken'      if click.type =~ /install_jailbroken/
    classes << 'click-key-match' if click.key == params[:click_key]
    if click.block_reason =~ /TooManyUdidsForPublisherUserId|Banned/
      classes << 'blocked'
    elsif click.block_reason?
      classes << 'not-rewarded'
    end
    classes.join(' ')
  end

  def install_td_class(click)
    (click.block_reason? || click.resolved_too_fast?) ? 'small bad' : 'small'
  end

  def link_app_to_statz(app)
    app.nil? ? '-'  : link_to_statz(app.name, app)
  end

  def click_timestamp(click, action)
    time = click.send(action)
    time.nil? ? '-' : time.to_s(:pub_abbr_ampm_sec)
  end

  def link_install_to_attempt(click)
    if click.block_reason?
      display = click.block_reason
    elsif click.installed_at?
      display = click_timestamp(click, :installed_at)
    end

    if display
      attempt = ConversionAttempt.new(:key => click.reward_key)
      if attempt.is_new
        display
      else
        link_to(display, view_conversion_attempt_tools_path(:conversion_attempt_key => attempt.key))
      end
    end
  end

  def wfh_classes(wfh)
    [ 'wfh', wfh.category.downcase ].uniq.join(' ')
  end

  def formatted_offers_for_tracking(offers)
    offers.map do |offer|
      type = offer.item.class.name.to_s.gsub(/Offer$/, '')
      platform = if offer.item.respond_to?(:platform_name)
                   offer.item.platform_name
                 elsif offer.item.respond_to?(:get_platform)
                   offer.item.get_platform
                 elsif offer.item.respond_to?(:primary_offer)
                   offer.item.primary_offer.get_platform
                 else
                   'N/A'
                 end
      ["#{type} - #{offer.rewarded? ? 'Rewarded' : 'Non-Rewarded'} - #{offer.name_with_suffix}  - #{platform}#{ ' - ' + offer.app_metadata.store_name if offer.app_metadata.present?}" , "#{offer.id}" ]
    end
  end

  def award_dropdown_options(click)
    award_options = []
    award_options << [click.publisher_app.name, click.publisher_app_id]
    click.previous_publisher_ids.each do |item|
      pub_app = App.find_by_id(item['publisher_app_id'])
      award_options << [ pub_app.name, pub_app.id ]
    end
    award_options.uniq!
    options_for_select(award_options)
  end

  private

  def concat_li(name, value)
    safe_concat("<li>#{name}: <nobr>#{value}</nobr></li>")
  end

  def concat_li_timestamp(name, time)
    concat_li(name, time.to_s(:pub_abbr_ampm_sec)) if time
  end

  def concat_li_currency(name, amount)
    concat_li(name, number_to_currency(amount.to_f / 100.0))
  end
end
