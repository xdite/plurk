module Plurk
  class Base
    attr_reader :logged_in, :uid, :nickname, :friend_ids, :fan_ids, :cookies , :info
    def initialize(nickname, password, options={})
      @info , @info[:nickname], @info[:password] = {}, nickname, password
      @api_host = 'http://www.plurk.com'
    end

    def login
      agent = WWW::Mechanize.new
      begin
      agent.get(@api_host) do |login_page|
        timeline = login_page.form_with(:action => '/Users/login') do |form|
          form.nick_name = @info[:nickname]
          form.password = @info[:password]
        end.submit
        /var GLOBAL = \{.*"uid": ([\d]+),.*\}/imu =~ timeline.body
        @uid = Regexp.last_match[1]
        /var FRIENDS = (.*);/ =~ timeline.body
        @friend_ids = plurk_to_json($1).keys if Regexp.last_match[1]
        /var FANS = (.*);/ =~ timeline.body
        @fan_ids = plurk_to_json($1).keys if Regexp.last_match[1]
        /var SETTINGS = (.*);/ =~ timeline.body
        @info[:settings] = plurk_to_json($1) if Regexp.last_match[1]
      end
    
      @cookies = agent.cookie_jar
      @logged_in = true
      rescue
        false
      end
    end

    
    def add_plurk(content="", qualifier="says", limited_to=[], no_comments=false, lang="en")
      return false unless @logged_in
      no_comments = no_comments ? 1 : 0
        
      params = {
        :posted => Time.now.getgm.strftime("%Y-%m-%dT%H:%M:%S"),
        :qualifier => qualifier,
        :content => content[0...140],
        :lang => lang,
        :uid => @uid,
        :no_comments => no_comments
      }

      params[:limited_to] = "[#{limited_to.join(",")}]" unless limited_to.empty?    
      #data = plurk_to_json(request("/TimeLine/addPlurk", :method => :post , :params => params))["plurk"]
      data = plurk_to_json(request("/TimeLine/addPlurk", :method => :post , :params => params))
      #return data
      return Status.new(data)
      # if data =~ /anti-flood/ # ???
    end

    def get_permalink(plurk_id)
      return "http://www.plurk.com/p/#{plurk_id.to_s(36)}"
    end
    
    
    def permalink_to_plurk_id(permalink)
      /http:\/\/www.plurk.com\/p\/([a-zA-Z0-9]*)/ =~ permalink
      return $1.to_i(36)
    end
    def delete_plurk(plurk_id)
      return false unless @logged_in
      params = {
        :plurk_id => plurk_id
      }
      data = request("/TimeLine/deletePlurk", :method => :post , :params => params )
      (data == "ok")? true : false

    end    

    def respond_to_plurk(plurk_id, lang, qualifier, content)
      return false unless @logged_in
      params = {
        :plurk_id => plurk_id,
        :uid => @uid,
        :p_uid => @uid,
        :lang => "en",
        :content => content[0...140],
        :qualifier => qualifier,
        :posted => Time.now.strftime("%Y-%m-%dT%H:%M:%S")
      }

      data = plurk_to_json(request("/Responses/add", :method => :post , :params => params ))["object"]
      return Response.new(data)

    end

    
    def nickname_to_uid(nickname)
      data = request("/user/#{nickname}", :method => :get )
      /\{"page_user": \{.*"page_title": null, "uid": ([0-9]+),.+\}\}/imu =~ data
      return uid = ($1)? $1 : -1
    end


    def get_responses(plurk_id)
      return false unless @logged_in
      params = {
        :plurk_id => plurk_id
      }      
      data = responses(plurk_to_json(request("/Responses/get2", :method => :post , :params => params ))["responses"])
      return data
    end
    
    def uid_to_userinfo(uid)
      params = {
        :user_id => uid
      }
      data = plurk_to_json(request("/Users/fetchUserInfo", :method => :get , :params => params ))
      user = User.new(data)
      return user
    end

    
    def block_user(uid)
      return false unless @logged_in
      params = {
        :block_uid => uid
      } 
      data = request("/Friends/blockUser", :method => :post , :params => params )
      (data =="ok") ? true : false

    end

    def unblock_user(uid)
      return false unless @logged_in    
      params = {
        :friend_id => uid
      } 
      data = request("/Friends/removeBlock", :method => :post , :params => params )
      (data =="ok") ? true : false
    end
    
    def make_fan(uid)
      return false unless @logged_in
      params = {
        :friend_id => uid
      }
      data = request("/Notifications/allowDontFollow", :method => :post, :params =>  params)
      (data =="ok") ? true : false
    end

    def allow_friend(uid)
      return false unless @logged_in
      params = {
        :friend_id => uid
      }
      data = request("/Notifications/allow", :method => :post, :params =>  params)
      (data =="ok") ? true : false
    end

    def get_blocked_users(offset = 0)
      return false unless @logged_in
      params = {
        :offset => offset,
        :user_id => @uid
      } 
      data = users(plurk_to_json(request("/Friends/getBlockedByOffset", :method => :post, :params => params )))
      return data
    end

    def mute_plurk(plurk_id, setmute)
      return false unless @logged_in
      params = {
        :plurk_id => plurk_id,
        :value => setmute
      } 
      data = request("/TimeLine/setMutePlurk", :method => :post, :params => params )
      (data.body.to_i == setmute) ? true :false 
    end

    def get_unread_plurks(fetch_responses=false)
      return false unless @logged_in
      params = {
        :fetch_responses => fetch_responses
      }
      data = statuses(plurk_to_json(request("/TimeLine/getUnreadPlurks", :method => :get, :params => params )))
      return data
    end

    def get_plurks(uid=nil, date_from=Time.now, date_offset=Time.now, fetch_responses=false)
      return false unless @logged_in
      uid ||= @uid
      params = {
        :user_id => uid,
        :from_date => date_from.getgm.strftime("%Y-%m-%dT%H:%M:%S"),
        :date_offset => date_offset.getgm.strftime("%Y-%m-%dT%H:%M:%S"),
        :fetch_responses => fetch_responses,
      }
      data = statuses(plurk_to_json(request("/TimeLine/getPlurks", :method => :post, :params => params )))
      return data
    end

    def deny_friend(uid)
      return false unless @logged_in
      params = {
        :friend_id => uid
      }
      data = request("/Notifications/deny", :method => :post, :params =>  params)
      if data == "ok"
        return true
      else
        return false
      end
    end

    def get_alerts
      return false unless @logged_in

      data = request("/Notifications", :method => :get)
      @result = []
      data.scan(/DI\s*\(\s*Notifications\.render\(\s*(\d+),\s*0\)\s*\);/) { |matched|
        @result << matched 
      } 
      return @result
    end
    
    private
    
      def statuses(doc)
        doc.inject([]) { |statuses, status| statuses << Status.new(status); statuses }
      end

      def users(doc)
        doc.inject([]) { |users, user| users << User.new(user); users }
      end
    
      def responses(doc)
        doc.inject([]) { |responses, response| responses << Response.new(response); responses }
      end
    
      def request(path, options = {})
        begin
          agent = WWW::Mechanize.new
          agent.cookie_jar = @cookies
          case options[:method].to_s
            when "get"
              agent.get(@api_host+path, options[:params])
            when "post"
              agent.post(@api_host+path, options[:params])
          end
          return agent.current_page.body
        rescue WWW::Mechanize::ResponseCodeError => ex
          raise Unavailable, ex.response_code
        end
      end
      
      def plurk_to_json(json)
        /new Date\((\".+?\")\)/.match(json)
        json = json.gsub(/new Date\((\".+?\")\)/, Regexp.last_match[1]) if Regexp.last_match
        return JSON.parse(json)
      end
  end  
end
