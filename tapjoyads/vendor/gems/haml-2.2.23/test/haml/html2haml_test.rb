#!/usr/bin/env ruby
require File.dirname(__FILE__) + '/../test_helper'
require 'haml/html'

class Html2HamlTest < Test::Unit::TestCase

  def test_empty_render_should_remain_empty
    assert_equal '', render('')
  end

  def test_doctype
    assert_equal '!!!', render("<!DOCTYPE html>")
    assert_equal '!!! 1.1', render('<!DOCTYPE html PUBLIC "-//W3C//DTD XHTML 1.1//EN" "http://www.w3.org/TR/xhtml11/DTD/xhtml11.dtd">')
    assert_equal '!!! Strict', render('<!DOCTYPE html PUBLIC "-//W3C//DTD XHTML 1.0 Strict//EN" "http://www.w3.org/TR/xhtml1/DTD/xhtml1-strict.dtd">')
    assert_equal '!!! Frameset', render('<!DOCTYPE html PUBLIC "-//W3C//DTD XHTML 1.0 Frameset//EN" "http://www.w3.org/TR/xhtml1/DTD/xhtml1-frameset.dtd">')
    assert_equal '!!! Mobile 1.2', render('<!DOCTYPE html PUBLIC "-//WAPFORUM//DTD XHTML Mobile 1.2//EN" "http://www.openmobilealliance.org/tech/DTD/xhtml-mobile12.dtd">')
    assert_equal '!!! Basic 1.1', render('<!DOCTYPE html PUBLIC "-//W3C//DTD XHTML Basic 1.1//EN" "http://www.w3.org/TR/xhtml-basic/xhtml-basic11.dtd">')
    assert_equal '!!!', render('<!DOCTYPE html PUBLIC "-//W3C//DTD XHTML 1.0 Transitional//EN" "http://www.w3.org/TR/xhtml1/DTD/xhtml1-transitional.dtd">')
    assert_equal '!!! Strict', render('<!DOCTYPE html PUBLIC "-//W3C//DTD HTML 4.01//EN" "http://www.w3.org/TR/html4/strict.dtd">')
    assert_equal '!!! Frameset', render('<!DOCTYPE html PUBLIC "-//W3C//DTD HTML 4.01 Frameset//EN" "http://www.w3.org/TR/html4/frameset.dtd">')
    assert_equal '!!!', render('<!DOCTYPE html PUBLIC "-//W3C//DTD HTML 4.01 Transitional//EN" "http://www.w3.org/TR/html4/loose.dtd">')
  end

  def test_id_and_class_should_be_removed_from_hash
    assert_equal '%span#foo.bar', render('<span id="foo" class="bar"> </span>')
  end

  def test_no_tag_name_for_div_if_class_or_id_is_present
    assert_equal '#foo', render('<div id="foo"> </div>')
    assert_equal '.foo', render('<div class="foo"> </div>')
  end

  def test_multiple_class_names
    assert_equal '.foo.bar.baz', render('<div class=" foo  bar  baz "> </div>')
  end

  def test_should_have_pretty_attributes
    assert_equal_attributes('%input{ :type => "text", :name => "login" }',
      render('<input type="text" name="login" />'))
    assert_equal_attributes('%meta{ "http-equiv" => "Content-Type", :content => "text/html" }',
      render('<meta http-equiv="Content-Type" content="text/html" />'))
  end

  def test_sqml_comment
    assert_equal "/\n  IE sucks", render('<!-- IE sucks -->')
  end

  def test_interpolation
    assert_equal('Foo \#{bar} baz', render('Foo #{bar} baz'))
  end

  def test_interpolation_in_attrs
    assert_equal('%p{ :foo => "\#{bar} baz" }', render('<p foo="#{bar} baz"></p>'))
  end

  def test_rhtml
    assert_equal '- foo = bar', render_rhtml('<% foo = bar %>')
    assert_equal '- foo = bar', render_rhtml('<% foo = bar -%>')
    assert_equal '= h @item.title', render_rhtml('<%=h @item.title %>')
    assert_equal '= h @item.title', render_rhtml('<%=h @item.title -%>')
  end
  
  def test_rhtml_with_html_special_chars
    assert_equal '= 3 < 5 ? "OK" : "Your computer is b0rken"',
      render_rhtml(%Q{<%= 3 < 5 ? "OK" : "Your computer is b0rken" %>})
  end
  
  def test_rhtml_in_class_attribute
    assert_equal "%div{ :class => dyna_class }\n  I have a dynamic attribute",
      render_rhtml(%Q{<div class="<%= dyna_class %>">I have a dynamic attribute</div>})
  end
  
  def test_rhtml_in_id_attribute
    assert_equal "%div{ :id => dyna_id }\n  I have a dynamic attribute",
      render_rhtml(%Q{<div id="<%= dyna_id %>">I have a dynamic attribute</div>})
  end
  
  def test_rhtml_in_attribute_results_in_string_interpolation
    assert_equal %(%div{ :id => "item_\#{i}" }\n  Ruby string interpolation FTW),
      render_rhtml(%Q{<div id="item_<%= i %>">Ruby string interpolation FTW</div>})
  end
  
  def test_rhtml_in_attribute_with_trailing_content
    assert_equal %(%div{ :class => "\#{12}!" }\n  Bang!),
      render_rhtml(%Q{<div class="<%= 12 %>!">Bang!</div>})
  end
  
  def test_rhtml_in_html_escaped_attribute
    assert_equal %(%div{ :class => "foo" }\n  Bang!),
      render_rhtml(%Q{<div class="<%= "foo" %>">Bang!</div>})
  end
  
  def test_rhtml_in_attribute_to_multiple_interpolations
    assert_equal %(%div{ :class => "\#{12} + \#{13}" }\n  Math is super),
      render_rhtml(%Q{<div class="<%= 12 %> + <%= 13 %>">Math is super</div>})
  end
  
  def test_whitespace_eating_erb_tags
    assert_equal %(- form_for),
      render_rhtml(%Q{<%- form_for -%>})
  end

  def test_cdata
    assert_equal(<<HAML.strip, render(<<HTML))
%p
  :cdata
    <a foo="bar" baz="bang">
    <div id="foo">flop</div>
    </a>
HAML
<p><![CDATA[
  <a foo="bar" baz="bang">
    <div id="foo">flop</div>
  </a>
]]></p>
HTML
  end

  def test_interpolation_in_rhtml
    assert_equal('= "Foo #{bar} baz"', render_rhtml('<%= "Foo #{bar} baz" %>'))
  end

  def test_interpolation_in_rhtml_attrs
    assert_equal('%p{ :foo => "#{bar} baz" }',
      render_rhtml('<p foo="<%= "#{bar} baz" %>"></p>'))
  end

  # Regression Tests

  def test_xhtml_strict_doctype
    assert_equal('!!! Strict', render(<<HTML))
<!DOCTYPE html PUBLIC "-//W3C//DTD XHTML 1.0 Strict//EN"
  "http://www.w3.org/TR/xhtml1/DTD/xhtml1-strict.dtd">
HTML
  end

  protected

  def render(text, options = {})
    Haml::HTML.new(text, options).render.rstrip
  end

  def render_rhtml(text)
    render(text, :rhtml => true)
  end

  def assert_equal_attributes(expected, result)
    expected_attr, result_attr = [expected, result].map { |s| s.gsub!(/\{ (.+) \}/, ''); $1.split(', ').sort }
    assert_equal expected_attr, result_attr
    assert_equal expected, result
  end
end
