# encoding: utf-8
# frozen_string_literal: true

require_relative 'ec2_net_utils_helpers/secondary_eni'

class EC2NetUtilsHelpers
  class << self
    attr_reader :inspec

    def configure!(params)
      @inspec = params.fetch(:inspec)
    end

    def set_up!
      ::EC2NetUtilsHelpers::SecondaryEni.set_up!
    end

    def tear_down!
      ::EC2NetUtilsHelpers::SecondaryEni.tear_down!
    end
  end
end
