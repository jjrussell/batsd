object false
node :schema do
    { :campaign => {
    	:active => { :name => :Active, :field => :active, :format => :boolean },
    	:id => {:name => :Id, :field => :id, :format => :text },
      :bid => {:name => :Bid, :field => :id, :format => :money },
    	:name => {:name => :Name, :field => :name, :format => :text }}}
end
