# encoding: utf-8
# frozen_string_literal: true

require_relative 'ec2_net_utils_helpers/ec2'
require_relative 'ec2_net_utils_helpers/inspec'
require_relative 'ec2_net_utils_helpers/instance'
require_relative 'ec2_net_utils_helpers/interface'

class EC2NetUtilsHelpers
  class << self
    attr_reader :inspec

    #
    # Configure our child helper classes.
    #
    # @param params [Hash] a params hash
    #
    def configure!(params)
      ::EC2NetUtilsHelpers::Inspec.configure!(params)
    end

    #
    # Set up the secondary interface on the test instance.
    #
    def set_up!
      ::EC2NetUtilsHelpers::Interface.create!
      ::EC2NetUtilsHelpers::Interface.attach!
      ::EC2NetUtilsHelpers::Interface.ifup!
    end

    #
    # Bring down, detach, and delete the secondary interface.
    #
    def tear_down!
      ::EC2NetUtilsHelpers::Interface.ifdown!
      ::EC2NetUtilsHelpers::Interface.detach!
      ::EC2NetUtilsHelpers::Interface.destroy!
    end
  end
end
