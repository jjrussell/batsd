def file_for(field)
  path = case field
         when "Icon"
          "./features/support/fixtures/icon.png"
         else
           raise "no file for field \"#{field}\""
         end

  File.expand_path(path)
end

