require 'rubygems'
require File.join(File.dirname(__FILE__), '..', 'lib', 'plurk')
username = "plurk"
password = "12345"
a = Plurk::Base.new(username,password)
a.login
