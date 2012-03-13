module WfhsHelper
  def desk_classes(employee, wfh, column)
    classes = []
    if employee.nil?
      classes << 'nodesk'
    else
      classes << 'long' if employee.first_name.length > 10
      classes << 'me'   if employee.is_user?(current_user)
    end
    classes << 'space'    if column % 3 == 2
    classes << 'not-here' if wfh
    classes.join(' ')
  end

  def link_to_employee(employee)
    name = employee.first_name
    if employee.is_user?(current_user)
      path = new_tools_wfh_path
    else
      name += " #{employee.last_name[0, 2]}." if @repeated_names.include?(name)
      path = wfhs_tools_employee_path(employee)
    end
    link_to(name, path, :title => employee.full_name)
  end

  def wfh_li(wfh, with_date = false)
    text = []
    text << "#{formatted_wfh_dates(wfh)}: " if with_date
    text << wfh.employee.full_name
    text << " (#{wfh_span(wfh)}"
    text << ": #{wfh.description}" unless wfh.description.blank?
    text << ")"
    text.join('')
  end

  def formatted_wfh_dates(wfh)
    text = [ wfh.start_date.to_s(:amd) ]
    if wfh.multi_day?
      text << "&ndash;"
      text << wfh.end_date.to_s(:amd)
    end
    text.join(' ')
  end

  def wfh_span(wfh)
    "<span class='#{wfh_classes(wfh)}'>#{wfh.category.upcase}</span>"
  end
end
