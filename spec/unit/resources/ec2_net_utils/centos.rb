# encoding: utf-8
# frozen_string_literal: true

require_relative 'rhel'

shared_context 'resources::ec2_net_utils::centos' do
  include_context 'resources::ec2_net_utils::rhel'

  let(:platform) { 'centos' }

  shared_examples_for 'any CentOS platform' do
    it_behaves_like 'any RHEL platform'
  end
end
