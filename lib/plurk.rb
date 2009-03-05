%w(uri cgi net/http yaml rubygems active_support mechanize json).each { |f| require f }

$:.unshift(File.join(File.dirname(__FILE__)))
require 'plurk/easy_class_maker'
require 'plurk/base'
require 'plurk/status'
require 'plurk/user'
require 'plurk/response'

module Plurk
    class Unavailable < StandardError; end
end