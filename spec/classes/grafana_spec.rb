require 'spec_helper'

describe 'grafana' do
  context 'supported operating systems' do
    ['Debian', 'RedHat'].each do |osfamily|
      describe "grafana class without any parameters on #{osfamily}" do
        let(:params) {{ }}
        let(:facts) {{
          :osfamily => osfamily,
        }}

        it { should compile.with_all_deps }

        it { should contain_class('grafana::params') }
        it { should contain_class('grafana::install').that_comes_before('grafana::config') }
        it { should contain_class('grafana::config') }
        it { should contain_class('grafana::service').that_subscribes_to('grafana::config') }

        it { should contain_service('grafana-server') }
        it { should contain_package('grafana').with_ensure('present') }
      end
    end
  end

  context 'unsupported operating system' do
    describe 'grafana class without any parameters on Solaris/Nexenta' do
      let(:facts) {{
        :osfamily        => 'Solaris',
        :operatingsystem => 'Nexenta',
      }}

      it { expect { should contain_package('grafana') }.to raise_error(Puppet::Error, /Nexenta not supported/) }
    end
  end

  context 'package install method' do
    context 'debian' do
      let(:facts) {{
        :osfamily => 'Debian'
      }}
      
      download_location = '/tmp/grafana.deb'

      describe 'use wget to fetch the package to a temporary location' do
        it { should contain_wget__fetch('grafana').with_destination(download_location) }
        it { should contain_wget__fetch('grafana').that_comes_before('Package[grafana]') }
      end

      describe 'install dependencies first' do
        it { should contain_package('libfontconfig').with_ensure('present').that_comes_before('Package[grafana]') }
      end

      describe 'install the package' do
        it { should contain_package('grafana').with_provider('dpkg') }
        it { should contain_package('grafana').with_source(download_location) }
      end
    end

    context 'redhat' do
      let(:facts) {{
        :osfamily => 'RedHat'
      }}

      describe 'install the package' do
        it { should contain_package('grafana').with_provider('rpm') }
      end
    end
  end

  context 'invalid parameters' do
    context 'cfg' do
      let(:facts) {{
        :osfamily => 'Debian',
      }}

      describe 'should raise an error when cfg parameter is not a hash' do
        let(:params) {{
          :cfg => [],
        }}

        it { expect { should contain_package('grafana') }.to raise_error(Puppet::Error, /cfg parameter must be a hash/) }
      end

      describe 'should not raise an error when cfg parameter is a hash' do
        let(:params) {{
          :cfg => {},
        }}

        it { should contain_package('grafana') }
      end
    end
  end

  context 'configuration file' do
    let(:facts) {{
      :osfamily => 'Debian',
    }}

    describe 'should not contain any configuration when cfg param is empty' do
      it { should contain_file('/etc/grafana/grafana.ini').with_content("# This file is managed by Puppet, any changes will be overwritten\n\n") }
    end

    describe 'should correctly transform cfg param entries to Grafana configuration' do
      let(:params) {{
        :cfg => {
          'app_mode' => 'production',
          'section' => {
            'string' => 'production',
            'number' => 8080,
            'boolean' => false,
            'empty' => '',
          },
        },
      }}

      expected = "# This file is managed by Puppet, any changes will be overwritten\n\n"\
                 "app_mode = production\n\n"\
                 "[section]\n"\
                 "string = production\n"\
                 "number = 8080\n"\
                 "boolean = false\n"\
                 "empty = \n"

      it { should contain_file('/etc/grafana/grafana.ini').with_content(expected) }
    end
  end
end
