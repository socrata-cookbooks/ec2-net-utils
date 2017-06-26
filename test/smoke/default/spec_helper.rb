# encoding: utf-8
# frozen_string_literal: true

require 'inspec'
require_relative 'ec2_net_utils_helpers'

#
# Configure the helper class so it knows about our inspec instance and is able
# to execute commands on the remote instance. Then call its set_up! method to
# ensure a secondary ENI is created and attached to the instance as eth1.
#
RSpec.configure do |c|
  c.before do
    @helpers = EC2NetUtilsHelpers.new(inspec: inspec)
    @helpers.set_up!
  end
end

#
# Wait until Kitchen is exiting to detach and tear down the secondary ENI.
# If done in an RSpec `after` block, the block seems to run multiple times, so
# put it here to ensure it only runs once.
#
at_exit do
  if defined?(inspec)
    @helpers = EC2NetUtilsHelpers.new(inspec: inspec)
    @helpers.tear_down!
  end
end
