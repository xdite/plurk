module Plurk
  class Status
    include EasyClassMaker
    attributes :lang , :content_raw, :user_id, :plurk_type, :plurk_id, :response_count, :owner_id, :qualifier, :id , :content , :response_count, :posted, :limited_to, :no_comments, :is_unread, :error
    def initialize(attributes)
      attributes.each do |attr, val|  
        instance_variable_set("@#{attr}", val)
      end
    end 
  end
end

