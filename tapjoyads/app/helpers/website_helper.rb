module WebsiteHelper
  def include_tapjoy_graph
    content_for :page_head, stylesheet_link_tag('tapjoy_graph', 'reporting')
    # TODO: try putting the following javascripts in included_javascripts instead of page_head
    content_for :page_head, javascript_include_tag('rgraph/RGraph.common.core', 'rgraph/RGraph.common.tooltips', 'rgraph/RGraph.line', 'tapjoy/graph')
    content_for :included_javascripts, javascript_include_tag('tapjoy/reporting')
  end

  def include_rickshaw_libs
    @rickshaw_libs_included = true

    content_for :page_head, stylesheet_link_tag('rickshaw.min', 'rickshaw.extensions')

    # d3 is required by rickshaw for rendering
    content_for :included_javascripts, javascript_include_tag('rickshaw/d3.min', 'rickshaw/d3.layout.min')

    # minified version for production
    content_for :included_javascripts, javascript_include_tag('rickshaw/rickshaw.min')
  end

  # Render the necessary javascript to make Rickshaw work
  #
  # @param [String] json_source the json url to load
  # @param [String] element_suffix substring of elements to allow multiple graphs
  # @option opts [Boolean] :transform convert the data into a compatible object
  def include_rickshaw_js(json_source, element_suffix, opts = {})
    options = {
      :transform => true
    }.merge(opts)
    include_rickshaw_libs  unless @rickshaw_libs_included
    content_for :page_javascript do
<<-EOJS
    var palette_#{element_suffix} = new Rickshaw.Color.Palette( { scheme: 'httpStatus' } );

    var wrapper_#{element_suffix} = new Rickshaw.Graph.Ajax( {
      element: document.getElementById('chart_#{element_suffix}'),
      dataURL: '#{json_source}',
      width: 820,
      height: 250,
      renderer: 'area',
      #{"onData: function(d) { return transformData_#{element_suffix}(d) }," if options[:transform]}
      onComplete: function(w) {
        var legend = new Rickshaw.Graph.Legend( {
          element: document.querySelector('#legend_#{element_suffix}'),
          graph: w.graph
        } );

        var hoverDetail = new Rickshaw.Graph.HoverDetail( {
          graph: w.graph
        } );

        var shelving = new Rickshaw.Graph.Behavior.Series.Toggle( {
          graph: w.graph,
          legend: legend
        } );

        var highlighter = new Rickshaw.Graph.Behavior.Series.Highlight( {
          graph: w.graph,
          legend: legend
        } );

        var axes = new Rickshaw.Graph.Axis.Time( {
          graph: w.graph
        } );
        axes.render();

        var yAxis = new Rickshaw.Graph.Axis.Y( {
          graph: w.graph,
          tickFormat: Rickshaw.Fixtures.Number.formatKMBT,
        } );

        yAxis.render();

        $('#loading_#{element_suffix}').remove();
      }
    } );

    function transformData_#{element_suffix}(d) {
      var data = [];
      var statusCounts = {};

      Rickshaw.keys(d).sort().forEach( function(t) {
        Rickshaw.keys(d[t]).forEach( function(status) {
          statusCounts[status] = statusCounts[status] || [];
          statusCounts[status].push( { x: parseFloat(t), y: d[t][status] } );
        } );
      } );

      Rickshaw.keys(statusCounts).sort().forEach( function(status) {
        data.push( {
          name: status,
          data: statusCounts[status],
          color: palette_#{element_suffix}.color(status)
        } );
      } );

      Rickshaw.Series.zeroFill(data);
      return data;
    }
EOJS
    end
  end

  def active_class(path)
    current_page?(path) ? 'active' : ''
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

    html.html_safe
  end

  def link_to_offer(offer)
    if permitted_to?(:show, :dashboard_statz)
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

  def instruction_list(text)
    instructions = sanitize(text.to_s).gsub(/\r/, '').split(/\n+/)
    instructions.each_with_index.map do |instruction, index|
      li = content_tag(:li) do
        concat content_tag(:div, index + 1, :class => 'count')
        concat content_tag(:div, instruction, :class => 'step')
      end
    end.join('')
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
    if permitted_to?(:show, :dashboard_statz)
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
    if decrypt || permitted_to?(:payout_info, :dashboard_tools)
      field_name = "decrypt_#{field_name}"
    end
    object.send(field_name)
  end

  def encrypted_field(form, object, field_name)
    value = decrypt_if_permitted(object, field_name, object.changed.include?(field_name.to_s))
    form.text_field(field_name, :value => value)
  end

  def photo_for(employee)
    if permitted_to?(:edit, :dashboard_tools_employees)
      link_to edit_tools_employee_path(employee) do
        image_tag(employee.get_photo_url, :size => '78x78')
      end
    else
      image_tag(employee.get_photo_url, :size => '78x78')
    end
  end

  def name_for(employee)
    if permitted_to?(:show, :dashboard_tools_users)
      link_to employee.full_name, [:tools, employee.user]
    else
      employee.full_name
    end
  end
end

