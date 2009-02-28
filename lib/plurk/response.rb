module Plurk
  class Response
    include EasyClassMaker
    attributes :lang, :content_raw, :user_id , :qualifier, :plurk_id, :content, :id, :posted, :last_ts
    def initialize(attributes)
      attributes.each do |attr, val|  
        instance_variable_set("@#{attr}", val)
      end
    end 
  end
end

