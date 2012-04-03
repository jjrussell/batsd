module Hominid
  module List
   
    # Find a list by name
    def find_list_by_name(list_name)
      lists['data'].find {|l| l["name"] == list_name}
    end
    
    # Find a list ID by name, returns nil if no list found
    def find_list_id_by_name(list_name)
      list = find_list_by_name(list_name)
      list && list["id"]
    end
    
    # Find a list by ID
    def find_list_by_id(list_id)
      lists['data'].find {|l| l["id"] == list_id}
    end
    
    # Find a list by web_id
    def find_list_by_web_id(list_web_id)
      lists['data'].find {|l| l["web_id"] == list_web_id}
    end
    
    # Find a list ID by web_id, returns nil if no list found
    def find_list_id_by_web_id(list_web_id)
      list = find_list_by_web_id(list_web_id)
      list && list["id"]
    end
    
  end
end