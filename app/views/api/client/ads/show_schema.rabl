object false
node :schema do
    { :ad => {
      :id => {:name => :Id, :field => :id, :format => :text },
      :bid => {:name => :Bid, :field => :id, :format => :money },
      :name => {:name => :Name, :field => :name, :format => :text }}}
end
