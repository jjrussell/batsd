# Methods added to this helper will be available to all templates in the application.
module ApplicationHelper
  def include_tapjoy_graph
    content_for :page_head, stylesheet_link_tag('tapjoy_graph')
    content_for :page_head, javascript_include_tag('rgraph/RGraph.common.core', 'rgraph/RGraph.common.tooltips', 'rgraph/RGraph.line', 'tapjoy/graph')
    content_for :page_head do
      '<!--[if IE]><script src="/javascripts/excanvas.js"></script><![endif]-->'
    end
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
end
