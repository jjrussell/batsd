module WebsiteHelper
  def include_tapjoy_graph
    content_for :page_head, stylesheet_link_tag('tapjoy_graph', 'reporting')
    # TODO: try putting the following javascripts in included_javascripts instead of page_head
    content_for :page_head, javascript_include_tag('rgraph/RGraph.common.core', 'rgraph/RGraph.common.tooltips', 'rgraph/RGraph.line', 'tapjoy/graph')
    content_for :included_javascripts, javascript_include_tag('tapjoy/reporting')
  end

  def is_mobile?
    (request.headers['User-Agent'] || '')[/mobile/i]
  end

  def is_msie?
    (request.headers['User-Agent'] || '')[/msie/i]
  end

  def platform_icon_url(object)
    platform =
      if object.is_a?(Offer)
        if %w(App RatingOffer ActionOffer).include?(object.item_type)
          object.item.platform
        else
          'multi_platform'
        end
      else
        object.platform
      end

    "#{platform}_flat.png"
  end

  def set_tapjoy_timezone_skew
    offset = Time.zone.now.utc_offset / 3600.0
    "Tapjoy.timezoneSkew = #{offset} + new Date().getTimezoneOffset() / 60;"
  end

  def clippy(text, bgcolor = '#FFFFFF')
    @clippy_id = 0 unless defined?(@clippy_id)
    @clippy_id += 1

    html = <<-EOF
      <object classid="clsid:d27cdb6e-ae6d-11cf-96b8-444553540000" width="110" height="14" id="clippy_#{@clippy_id}">
        <param name="movie" value="/clippy.swf" />
        <param name="allowScriptAccess" value="always" />
        <param name="quality" value="high" />
        <param name="scale" value="noscale" />
        <param NAME="FlashVars" value="text=#{text}" />
        <param name="bgcolor" value="#{bgcolor}" />
        <embed src="/clippy.swf"
            width="110"
            height="14"
            name="clippy_#{@clippy_id}"
            quality="high"
            allowScriptAccess="always"
            type="application/x-shockwave-flash"
            pluginspage="http://www.macromedia.com/go/getflashplayer"
            FlashVars="text=#{text}"
            bgcolor="#{bgcolor}"
        />
      </object>
    EOF
  end

  def link_to_offer(offer)
    if permitted_to?(:show, :statz)
      link_to(offer.name_with_suffix, statz_path(offer.id))
    else
      offer.name_with_suffix
    end
  end

  def simple_paragraphs(text)
    text = '' if text.nil?
    start_tag = tag('p', {}, true)
    text = sanitize(text)
    text.gsub!(/\r\n?/, "\n")
    text.gsub!(/\n\n+/, "</p>\n\n#{start_tag}")
    text.gsub!(/([^\n]\n)(?=[^\n])/, '\1</p><p>')
    text.insert 0, start_tag
    text + "</p>"
  end

  def link_to_generated_actions_header(app, name = nil)
    name ||= app.default_actions_file_name
    link =
      case app.platform
      when 'android'
        TapjoyPPA_app_action_offers_path(app, :format => "java")
      when 'iphone'
        TJCPPA_app_action_offers_path(app, :format => "h")
      when 'windows'
        #TODO fill this out
        ''
      end

    link_to(name, link)
  end

  def url_to_offer_item(offer)
    if offer.item.is_a? ActionOffer
      edit_app_action_offer_url(offer.item.app, offer.item)
    else
      edit_app_offer_url(offer.item, offer)
    end
  end

  def link_to_statz(body, object, options={})
    if permitted_to?(:show, :statz)
      link_to(body, statz_path(object), options)
    else
      body
    end
  end

  def has_permissions_for_one_of?(*roles)
    roles.each { |role| return true if has_role_with_hierarchy?(role) }
    false
  end

  def content_for_exists?(content_name)
    instance_variable_get("@content_for_#{content_name}").present?
  end

  def offer_event_changes(offer_event, join_with = "<br/>")
    OfferEvent::CHANGEABLE_ATTRIBUTES.reject { |attribute| offer_event.send(attribute).nil? }.collect { |attribute|
      if attribute == :daily_budget
        daily_budget = offer_event.send(attribute)
        "#{attribute.to_s.titleize}: " + (daily_budget == 0 ? 'Unlimited' : daily_budget.to_s)
      elsif attribute == :user_enabled
        "Enable Installs: #{offer_event.user_enabled? ? 'Enabled' : 'Disabled'}"
      else
        "#{attribute.to_s.titleize}: #{offer_event.send(attribute)}"
      end
    }.join(join_with)
  end

  def decrypt_if_permitted(object, field_name, decrypt=false)
    if decrypt || permitted_to?(:payout_info, :tools)
      field_name = "decrypt_#{field_name}"
    end
    object.send(field_name)
  end

  def encrypted_field(form, object, field_name)
    value = decrypt_if_permitted(object, field_name, object.changed.include?(field_name.to_s))
    form.text_field(field_name, :value => value)
  end
end

