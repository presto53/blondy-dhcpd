[![Gem Version](https://badge.fury.io/rb/blondy-dhcpd.png)](http://badge.fury.io/rb/net-dhcp) [![Build Status](https://travis-ci.org/presto53/blondy-dhcpd.png)](https://travis-ci.org/presto53/blondy-dhcpd) [![Code Climate](https://codeclimate.com/repos/52eb8ff6e30ba06ec2002a03/badges/132cfa29229385341bee/gpa.png)](https://codeclimate.com/repos/52eb8ff6e30ba06ec2002a03/feed)

blondy-dhcpd
============
DHCPd with remote pools

Installation
---------------
    gem install blondy-dhcpd

Configuration
---------------
Default config path is /etc/blondy

You can change it by set BLONDY_CONFIGPATH environment variable.

**Example config /etc/blondy/dhcpd.yml**:

    log_path: '/var/log/blondy'
    pid_path: '/var/run/blondy'
    server_ip: '192.168.1.1'
    client_key: 'AAAbbbCcC'
    master: 'https://192.168.1.10'

Usage
---------------

Contributing
---------------

1. Fork it
2. Create your feature branch (`git checkout -b my-new-feature`)
3. Commit your changes (`git commit -am 'Add some feature'`)
4. Push to the branch (`git push origin my-new-feature`)
5. Create new Pull Request

Licensing
---------------
The MIT License (MIT)

Copyright (c) 2013 Pavel Novitskiy

Permission is hereby granted, free of charge, to any person obtaining a copy
of this software and associated documentation files (the "Software"), to deal
in the Software without restriction, including without limitation the rights
to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
copies of the Software, and to permit persons to whom the Software is
furnished to do so, subject to the following conditions:

The above copyright notice and this permission notice shall be included in all
copies or substantial portions of the Software.

THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE
SOFTWARE.
