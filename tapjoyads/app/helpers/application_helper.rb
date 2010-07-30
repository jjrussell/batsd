# Methods added to this helper will be available to all templates in the application.
module ApplicationHelper
  def include_tapjoy_graph
    content_for :page_head, stylesheet_link_tag('tapjoy_graph')
    content_for :page_head, javascript_include_tag('rgraph/RGraph.common.core', 'rgraph/RGraph.common.tooltips', 'rgraph/RGraph.line', 'tapjoy_graph')
    content_for :page_head do
      '<!--[if IE]><script src="/javascripts/excanvas.js"></script><![endif]-->'
    end
  end
end
