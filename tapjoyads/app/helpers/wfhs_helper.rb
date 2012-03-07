module WfhsHelper
  def desk_classes(employee, wfh, column)
    classes = []
    if employee.nil?
      classes << 'nodesk'
    else
      classes << 'long' if employee.first_name.length > 10
      if employee.is_user?(current_user)
        classes << 'me'
      end
    end
    classes << 'space'    if column % 3 == 2
    classes << 'not-here' if wfh
    classes.join(' ')
  end

  def link_to_employee(employee)
    name = employee.first_name
    if employee == current_user.employee
      path = new_tools_wfh_path
    else
      name += " #{employee.last_name[0, 2]}." if @repeated_names.include?(name)
      path = wfhs_tools_employee_path(employee)
    end
    link_to(name, path, :title => employee.full_name)
  end

  def wfh_li(wfh, with_date = false)
    text = []
    text << "#{wfh.start_date.to_s(:amd)}: " if with_date
    text << wfh.employee.full_name
    text << "(<span class='#{wfh_classes(wfh)}'>#{wfh.category}</span>"
    text << ": #{wfh.description}" unless wfh.description.blank?
    text << ")"
    text.join('')
  end
end
