# encoding: utf-8
# frozen_string_literal: true

require 'thread'
require_relative 'ec2_net_utils_helpers/ec2'
require_relative 'ec2_net_utils_helpers/inspec'
require_relative 'ec2_net_utils_helpers/instance'
require_relative 'ec2_net_utils_helpers/interface'

class EC2NetUtilsHelpers
  attr_reader :inspec, :instance, :interface

  class << self
    #
    # Iterate over every object in the instances index and tear it down.
    #
    def tear_down!
      instances.shift[1].interface.tear_down! while !instances.empty?
    end

    #
    # Keep a class-level index of all current test instances.
    #
    # @return [Hash] a hash of name => helper objects
    #
    def instances
      @instances ||= {}
    end

    #
    # Keep a class-level lock so interface constructions/destructions don't
    # tread on each other.
    #
    # @return [Mutex] a class-level mutex
    #
    def mutex
      @mutex ||= Mutex.new
    end
  end

  #
  # Configure our child helper classes.
  #
  # @param params [Hash] a params hash
  #
  def initialize(params)
    @inspec = ::EC2NetUtilsHelpers::Inspec.new(params)
    @instance = ::EC2NetUtilsHelpers::Instance.new(inspec: @inspec)
    @interface = ::EC2NetUtilsHelpers::Interface.new(instance: @instance)
  end

  #
  # Set up the secondary interface on the test instance.
  #
  def set_up!
    self.class.mutex.synchronize do
      interface.set_up!
      self.class.instances[instance.id] = self
    end
  end

  #
  # Bring down, detach, and delete the secondary interface.
  #
  def tear_down!
    self.class.mutex.synchronize do
      interface.tear_down!
    end
  end
end
