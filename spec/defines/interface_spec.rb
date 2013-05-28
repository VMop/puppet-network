require 'spec_helper'

describe 'network::interface' do
  let(:title) { 'eth0' }

  it do
    should contain_network_config('eth0').
      with_notify('Service[network]')
  end
end

