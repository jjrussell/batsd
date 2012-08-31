def file_for(field)
  case field
  when "Icon"
    "./features/support/fixtures/icon.png"
  else
    raise "no file for field \"#{field}\""
  end
end

