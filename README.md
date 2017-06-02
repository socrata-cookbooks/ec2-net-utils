EC2 Net Utils Cookbook
======================
[![Cookbook Version](https://img.shields.io/cookbook/v/ec2-net-utils.svg)][cookbook]
[![Build Status](https://img.shields.io/travis/socrata-cookbooks/ec2-net-utils.svg)][travis]
[![Code Climate](https://img.shields.io/codeclimate/github/socrata-cookbooks/ec2-net-utils.svg)][codeclimate]
[![Coverage Status](https://img.shields.io/coveralls/socrata-cookbooks/ec2-net-utils.svg)][coveralls]

[cookbook]: https://supermarket.chef.io/cookbooks/ec2-net-utils
[travis]: https://travis-ci.org/socrata-cookbooks/ec2-net-utils
[codeclimate]: https://codeclimate.com/github/socrata-cookbooks/ec2-net-utils
[coveralls]: https://coveralls.io/r/socrata-cookbooks/ec2-net-utils

A Chef cookbook for installing a multi-platform fork of Amazon Linux's
ec2-net-utils package.

The included files were vendored from the most recent version of ec2-net-utils
as of 2017-06-01. They are patched to support Debian and RHEL platforms.

Requirements
============

This cookbook currently supports both Debian-based and RHEL-based platforms.

It requires Chef 12.10+, or Chef 12.1+ and the compat_resource cookbook.

Usage
=====

Set the attributes you wish and add the default recipe to your run list, or
create a recipe of your own that implements the included Chef resources.

Recipes
=======

***default***


Attributes
==========

***default***

Resources
=========

***ec2_net_utils***

TODO

Syntax:

    ec2_net_utils do
      action :install
    end

Actions:

| Action     | Description   |
|------------|---------------|
| `:install` | Do some stuff |

Properties:

| Property    | Default   | Description                           |
|-------------|-----------|---------------------------------------|
| action      | `:create` | Action(s) to perform                  |

Contributing
============

1. Fork it
2. Create your feature branch (`git checkout -b my-new-feature`)
3. Add tests for the new feature; ensure they pass (`rake`)
4. Commit your changes (`git commit -am 'Add some feature'`)
5. Push to the branch (`git push origin my-new-feature`)
6. Create a new Pull Request

License & Authors
=================
- Author: Jonathan Hartman <jonathan.hartman@socrata.com>

Copyright 2017, Socrata, Inc.

Licensed under the Apache License, Version 2.0 (the "License");
you may not use this file except in compliance with the License.
You may obtain a copy of the License at

    http://www.apache.org/licenses/LICENSE-2.0

Unless required by applicable law or agreed to in writing, software
distributed under the License is distributed on an "AS IS" BASIS,
WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
See the License for the specific language governing permissions and
limitations under the License.
