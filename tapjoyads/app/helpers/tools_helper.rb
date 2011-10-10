module ToolsHelper
  def click_info_ul(click, reward)
    concat("<ul class='nobr hidden'>")
    concat_li("Click ID:", clippy(click.key))
    concat_li_timestamp("Viewed at", click.viewed_at)
    concat_li_timestamp("Clicked at", click.clicked_at)
    concat_li_timestamp("Installed at", click.installed_at)
    concat_li_timestamp("Manually Resolved at", click.manually_resolved_at)
    if reward.try :sent_currency?
      concat_li_timestamp("Send Currency at", rewards.sent_currency)
      concat_li("Award Status", rewards.send_currency_status)
    end
    concat_li("Currency", click.currency_reward)
    concat_li_currency('Adv', click.advertiser_amount)
    concat_li_currency('Pub', click.advertiser_amount)
    concat_li_currency('Tj', click.tapjoy_amount)
    concat_li("Pub user ID", click.publisher_user_id) if click.publisher_user_id != click.udid
    concat("</ul>")
  end

private
  def concat_li(name, value)
    concat("<li>#{name}: <nobr>#{value}</nobr></li>")
  end

  def concat_li_timestamp(name, time)
    concat_li(name, time.to_s(:pub_abbr_ampm_sec)) if time
  end

  def concat_li_currency(name, amount)
    concat_li(name, number_to_currency(amount/100.0))
  end
end
