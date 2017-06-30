# encoding: utf-8
# frozen_string_literal: true

require 'aws-sdk'
require 'timeout'

class EC2NetUtilsHelpers
  class Interface
    attr_reader :instance

    #
    # Initialize with an instance object for whom we'll be managing an ENI.
    #
    def initialize(params)
      @instance = params.fetch(:instance)
    end

    #
    # In an idempotent fashion, create the ENI, attach it to instance, and
    # bring it up.
    #
    def set_up!
      create! unless created?
      attach! unless attached?
      ifup! unless up?
    end

    #
    # In an idempotent fashion, bring down the ENI, detach it from the
    # instance, and delete it.
    #
    def tear_down!
      return unless created?

      ifdown! if up?
      detach! if attached?
      destroy!
    end

    #
    # Create and tag the secondary interface unless it already exists.
    #
    def create!
      EC2.clone_interface!(instance.eth0, description)
      tag!
      puts "Created secondary ENI (#{interface.id})"
    end

    #
    # Give the secondary interface a name tag so it's easier to find in the
    # UI.
    #
    def tag!
      interface.create_tags(tags: [{ key: 'Name', value: name }])
    end

    #
    # Destroy the secondary interface if it exists.
    #
    def destroy!
      release_eip! if eip?
      print "Deleting ENI (#{interface.id})..."
      interface.delete
      # There is ~a second or so where the API can still find the ENI even
      # though it's "deleted".
      sleep(3)
      puts 'OK'
    end

    #
    # Release the EIP associated with the secondary ENI.
    #
    def release_eip!
      e = eip
      print "Releasing EIP (#{e.allocation_id})..."
      interface.association.delete
      e.release
      puts 'OK'
    end

    #
    # If the secondary interface is not attached, send an attach call and
    # wait for its status to switch to "in-use".
    #
    def attach!
      interface.attach(instance_id: instance.id, device_index: 1)
      print "Waiting for ENI (#{interface.id}) to attach..."
      interface.wait_until(max_attempts: 10,
                           delay: 3,
                           before_wait: proc { print('.') }) do |r|
        r.status == 'in-use'
      end
      puts 'OK'
    end

    #
    # If the secondary interface is attached, send a detach call and wait for
    # its status to switch to "available".
    #
    def detach!
      interface.detach
      print "Waiting for ENI (#{interface.id}) to detach..."
      interface.wait_until(max_attempts: 40,
                           delay: 3,
                           before_wait: proc { print('.') }) do |r|
        r.status == 'available'
      end
      puts 'OK'
    end

    #
    # Wait up to 60 seconds for the instance to bring up the secondary
    # interface. Our udev rules bring it up automatically when it's attached
    # so we don't actually have to run `ifup`.
    #
    # It takes several seconds after the ENI is attached before the instance
    # recognizes it and brings it up.
    #
    def ifup!
      instance.ifup!('eth1')
    end

    #
    # Use Inspec to bring down the secondary interface on the instance if
    # it's currently up.
    #
    def ifdown!
      instance.ifdown!('eth1')
    end

    #
    # Use the EC2 API to determine whether the secondary interface has been
    # created.
    #
    # @return [TrueClass,FalseClass] whether the interface exists
    #
    def created?
      !interface.nil?
    end

    #
    # Use the EC2 API to check whether the secondary interface is attached.
    #
    # @return [TrueClass,FalseClass] whether the interface is attached
    #
    def attached?
      interface.status == 'in-use'
    end

    #
    # Check whether the interface has an EIP associated with it.
    #
    # @return [TrueClass, FalseClass]
    #
    def eip?
      !eip.nil?
    end

    #
    # Check whether the interface is up on the instane.
    #
    # @return [TrueClass,FalseClass] whether eth1 is up
    #
    def up?
      instance.up?('eth1')
    end

    private

    #
    # Fetch and return the EIP associated with the secondary interface or nil
    # if it doesn't exist.
    #
    # @return [Aws::EC2::VpcAddress,NilClass] the EIP of the secondary NIC
    #
    def eip
      EC2.find_eip(interface.id)
    end

    #
    # Fetch and return the secondary interface or nil if it doesn't exist.
    #
    # @return [Aws::EC2::NetworkInterface,NilClass] the secondary interface
    #
    def interface
      EC2.find_interface(description)
    end

    #
    # Construct a unique name for the secondary interface so we can find it
    # easily in the EC2 API.
    #
    def name
      "ec2-net-utils-kitchen-#{instance.id}-eth1"
    end

    #
    # Construct a unique description for the secondary interface so we can
    # find it easily in the EC2 API.
    #
    def description
      "Test Kitchen ec2-net-utils secondary ENI for #{instance.id}"
    end
  end
end
