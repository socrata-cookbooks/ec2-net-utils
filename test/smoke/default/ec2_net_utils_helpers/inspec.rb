# encoding: utf-8
# frozen_string_literal: true

class EC2NetUtilsHelpers
  class Inspec
    #
    # Configure the class with an inspec object.
    #
    # @param params [Hash] a hash containing an inspec object
    #
    def initialize(params)
      @inspec = params.fetch(:inspec)
    end

    #
    # Use Inspec to run a command against the instance under test and return
    # the resulting command object.
    #
    # @param cmd [String] the command to run
    #
    # @return [Inspec::Resources::Cmd] the resulting inspec command object
    #
    def command(cmd)
      inspec.command(cmd)
    end

    private

    attr_reader :inspec
  end
end
