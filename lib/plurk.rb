require 'hpricot'
require 'mechanize'

class Plurk
  attr_reader :logged_in, :uid, :nickname, :friends, :cookies
  def initialize
    @plurk_paths = {
      :http_base            => "http://www.plurk.com",
      :login                => "/Users/login",
      :get_completion       => "/Users/getCompletion",
      :plurk_add            => "http://www.plurk.com/TimeLine/addPlurk",
      :plurk_respond        => "/Responses/add",
      :plurk_get            => "/TimeLine/getPlurks",
      :plurk_get_responses  => "/Responses/get2",
      :plurk_get_unread     => "/TimeLine/getUnreadPlurks",
      :plurk_mute           => "/TimeLine/setMutePlurk",
      :plurk_delete         => "/TimeLine/deletePlurk",
      :notification         => "/Notifications",
      :notification_accept  => "/Notifications/allow",
      :notification_makefan => "/Notifications/allowDontFollow",
      :notification_deny    => "/Notifications/deny",
      :friends_get          => "/Users/friends_get",
      :friends_block        => "/Friends/blockUser",
      :friends_remove_block => "/Friends/removeBlock",
      :friends_get_blocked  => "/Friends/getBlockedByOffset",
      :user_get_info        => "/Users/fetchUserInfo"
    }
  end

  def login(nickname, password)
    agent = WWW::Mechanize.new
    agent.get(@plurk_paths[:http_base]) do |login_page|
      timeline = login_page.form_with(:action => '/Users/login') do |form|
        form.nick_name = nickname
        form.password = password
      end.submit
      
      /var GLOBAL = \{.*"uid": ([\d]+),.*\}/imu =~ timeline.body
      @uid = Regexp.last_match[1]
    end
    
    @cookies = agent.cookie_jar
    @nickname = nickname
    @logged_in = true
  end

  def add_plurk(content="", qualifier="says", limited_to=[], no_comments=false, lang="en")
    if @logged_in
      agent = WWW::Mechanize.new
      agent.cookie_jar = @cookies
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

      agent.post(@plurk_paths[:plurk_add], params)

      data = agent.current_page.body
      return data if data =~ /anti-flood/
      puts data
      true
    else
      false
    end
  end

  def get_alerts
    # if not login return false
    # get [:notification]
    # re.compile('DI\s*\(\s*Notifications\.render\(\s*(\d+),\s*0\)\s*\);')
    # re.match, return match
  end

  def befriend(uids, friend)
    # if not login return false
    # path = friend ? [:notification_accept] : [:notification_deny]
    # for each uids
    # post path ? friend_id=uid
    # puts "something"
    # return true
  end

  def deny_friend_make_fan(uids)
    # if not login return false
    # if uids not array return false
    # for each uids
    # post [:notofication_makefan] ? friend_id=uid
    # puts "added fan"
    # return true
  end

  def block_user(uids)
    # if not login return false
    # for each uids
    # post [:friends_block] ? block_uid=uid
    # puts "blocked" uid
    # return true
  end

  def unblock_user(uids)
    # if not login return false
    # for each uids
    # post [:friends_remove_block] ? friend_id = uid
    # puts "unblocked"+ uid
    # return true
  end

  def get_blocked_users
    # if not login return false
    # post [:friends_get_blocked] ? offset=0 & user_id=@uid
    # return body | json_to_hash
  end

  def mute_plurk(plurk_id, setmute)
    # if not login return false
    # convert setmute to integer
    # post [:plurk_mute] ? plurk_id=plurk_id & value=setmute
    # if body == setmute return true else false
  end

  def delete_plurk(plurk_id)
    # if not login return false
    # post [:plurk_delete] ? plurk_id=plurk_id
    # if response.body ok, return true else false
  end

  def get_plurks(uid=nil, date_from=nil, date_offset=nil, fetch_responses=false)
    uid ||= @uid
    # TODO date_offset? fetch_responses?
    # post [:plurk_get] ? user_id=uid & from_date=date_from(if not nil)
    # return json_to_hash response
  end

  def get_unread_plurks(fetch_responses=false)
    # if not login return []
    # get [:plurk_get_unread], json_to_hash
    # for each hash item,
    # item["nick_name"] = uid_to_nickname ["owner_id"]
    # item["responses_fetched"] = null
    # plurk["permalink"] = get_permalink(item["plurk_id"])
    # if fetch_responses == true
    # item["responses_fetched"] = plurk_get_responses(item["plurk_id"])
    # return hash
  end

  def uid_to_nickname(uid)
    nickname ||= -1
    if uid == @uid
      nickname = @nickname
    else
      for friend in @friends
        nickname = friend[1]["nick_name"] if uid.to_s == friend[0]
      end
    end
    return nickname
    # if uid = @uid return @nickname
    # if uid = friends.@uid, return friends.@nickname
    # return Unknown User uid
  end

  def respond_to_plurk(plurk_id, lang, qualifier, content)
    # if not log in return false
    # post [:plurk_respond] ? plurk_id=plurk_id & uid=@uid & p_uid=@uid & lang=lang & content=content[0:140]
    # qualifier=qualifier & posted = Time.now
  end

  def get_responses(plurk_id)
    if @logged_in
      http = Net::HTTP.start(@plurk_paths[:http_base])
      params = { "plurk_id" => plurk_id }
      resp, data = http.request_post(@plurk_paths[:plurk_get_responses],
                 hash_to_querystring(params),{"Cookie" => @cookie})
      return data
    end
    # post [:plurk_get_responses] ? plurk_id=plurk_id
  end

  def nickname_to_uid(nickname)
    http = Net::HTTP.start(@plurk_paths[:http_base])
    resp = http.request_get("/user/#{nickname}")
    /var GLOBAL = \{.*"uid": ([0-9]+),.*\}/imu =~resp.body    
    unless uid
      return -1
    else
      return uid
    end
    # get [:http_base]/user/nickname
    # if didn't match regexp match var GLOBAL "uid": xxx return -1
    # return match[1]
  end

  def uid_to_userinfo(uid)
    http = Net::HTTP.start(@plurk_paths[:http_base])
    params = { "user_id" => uid }
    resp = http.request_get(@plurk_paths[:user_get_info]+"?"+hash_to_querystring(params),{"Cookie" => @cookie})
    if resp.code == "500"
      return []
    else
      return resp.body
    end
    # array_profile = get [:user_get_info] ? user_id=uid
    # if respond code = 500 return []
    # return array_profile["body"]
  end

  def get_permalink(plurk_id)
    return "http://www.plurk.com/p/#{plurk_id.to_s(36)}"
    # return "http://www.plurk.com/p/" + plurk_id to base36
  end

  def permalink_to_plurk_id(permalink)
    /http:\/\/www.plurk.com\/p\/([a-zA-Z0-9]*)/ =~ permalink
    return $1.to_i(36)
    # base36 = gsub "http://www.plurk.com/p/" ""
    # convert base36 to decimal
  end

  private
    def json_to_ruby(json)
      /new Date\((.*)\)/.match(json)
      json = json.gsub(/new Date\(.*\)/, Regexp.last_match[1]) if Regexp.last_match
      null = nil
      return eval(json.gsub(/(["'])\s*:\s*(['"\-?0-9tfn\[{])/){"#{$1}=>#{$2}"})
    end

    def hash_to_querystring(hash)
      qstr = ""
      hash.each do |key,val|
        qstr += "#{key}=#{CGI.escape(val.to_s)}&" unless val.nil?
      end
      qstr
    end

    alias :plurk :add_plurk

end

if __FILE__ == $0
  if ARGV.length != 2
    $stderr.puts "Usage: ruby #{$0} [nickname] [password]"
  else
    plurker = Plurk.new
    puts "Login: " + plurker.login(ARGV.shift, ARGV.shift).inspect
    puts "Sent: " + plurker.add_plurk("testing Plurk API http://tinyurl.com/6r4nfv", "is").inspect
  end
end
