module Plurk
  class User
    include EasyClassMaker
    attributes :display_name, :uid, :is_channel, :nick_name, :has_profile_image, :are_friends, :location , :theme, :date_of_birth, :relationship, :avatar, :full_name, :gender, :page_title, :is_blocked, :recruited, :id, :karma 
    def initialize(attributes)
      attributes.each do |attr, val|  
        instance_variable_set("@#{attr}", val)
      end
    end 
  end
end

