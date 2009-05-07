Plurk
=====
This is unoffical API for plurk rails plugin

Base on http://qqzhenyi.blogspot.com/2008/07/howto-create-your-own-sharedcopy-addon.html

Author: xdite (xdite@handlino.com)
Blog: http://blog.xdite.net

In order to install in rails use:

    script/plugin install git://github.com/xdite/plurk.git -r rails_plugin

Example
-------

    require 'rubygems'
    require 'plurk'
    username = "plurk"
    password = "12345"
    a = Plurk::Base.new(username,password)
    a.login

Copyright (c) 2009 xdite (xdite@handlino.com), released under the MIT license

Maintenance
-----------

In order to maintain this branch all that should be necessary is to run `git merge master` from the rails_plugin branch when an update is made.  Make sure to work in the master branch!