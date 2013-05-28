require 'spec_helper'

describe 'network' do
  context 'debian' do
    let(:facts) {{ :osfamily => 'Debian' }}
    it do
      should contain_service('network').
        with_name('networking')
    end
  end
  context 'redhat' do
    let(:facts) {{ :osfamily => 'Redhat' }}
    it do
      should contain_service('network').
        with_name('network')
    end
  end
end
