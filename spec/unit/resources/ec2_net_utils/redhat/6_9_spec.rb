# encoding: utf-8
# frozen_string_literal: true

require_relative '../redhat'

describe 'resources::ec2_net_utils::redhat::6_9' do
  include_context 'resources::ec2_net_utils::redhat'

  let(:platform_version) { '6.9' }

  it_behaves_like 'any Red Hat platform'
end
