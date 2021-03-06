require 'spec_helper'
require 'fizzgig'
require 'rspec-puppet'

describe Fizzgig do
  include RSpec::Puppet::ManifestMatchers
  let(:fizzgig) { Fizzgig.new({modulepath: MODULEPATH, manifestdir: MANIFESTDIR}) }
  describe '#include' do
    subject { fizzgig.include(classname, :stubs => stubs, :facts => facts) }
    let(:stubs) { {} }
    let(:facts) { {} }

    describe 'webapp' do
      let(:classname) {'webapp'}

      it { should contain_nginx__site('webapp') }
      it 'should check multiple matchers for a single parameter' do
        should contain_file('/etc/nginx/nginx.conf').
          with_content(/fee fie foe fum/)
        should_not contain_file('/etc/nginx/nginx.conf').
          with_content(/pattern not present in file/).
          with_content(/fee fie foe fum/)
      end
    end

    describe 'functions::class_test' do
      let(:classname) {'functions::class_test'}
      context 'with extlookup stubbed out' do
        let(:stubs) { {:extlookup => {['ssh-key-barry'] => 'the key of S'}} }
        it { should contain_ssh_authorized_key('barry').with_key('the key of S') }
      end

      context 'with extlookup stubbed with wrong key' do
        let(:stubs) { {:extlookup => {'bananas' => 'potassium'}} }
        it 'should throw an exception' do
          expect { subject }.to raise_error Puppet::Error
        end
      end
    end

    describe 'functions::recursive_extlookup_test' do
      let(:classname) {'functions::recursive_extlookup_test'}
      let(:stubs) {
        {:extlookup =>
          { ['ssh-key-barry'] => 'rsa-key-barry',
            ['rsa-key-barry'] => 'the key of S'}}
      }
      it { should contain_ssh_authorized_key('barry').with_key('the key of S') }
    end

    describe 'functions::function_with_multiple_arguments' do
      let(:classname) {'functions::function_with_multiple_arguments'}
      let(:stubs) {
        {:hiera =>
          {['hiera_key','default value'] => 'correct result'}}
      }
      it { should contain_file('/tmp/multiarg_fn_test').with_content('correct result') }
    end

    describe 'facts::class_test' do
      let(:classname) {'facts::class_test'}
      let(:facts) {
        { 'unqualified_fact'      => 'F',
          'qualified_fact'        => 'B+',
          'template_visible_fact' => 'wibble' }}
      it { should contain_notify('unqualified-fact-test').with_message('F') }
      it { should contain_notify('qualified-fact-test').with_message('B+') }
      it { should contain_file('template-test').with_content(/instance_fact:wibble/) }
      it { should contain_file('template-test').with_content(/accessor_fact:wibble/) }
      it { should contain_file('template-test').with_content(/scope_lookup_fact:wibble/) }
    end
  end

  describe '#instantiate' do
    subject { fizzgig.instantiate(type, title, params, :stubs => stubs, :facts => facts) }
    let(:stubs) { {} }
    let(:facts) { {} }
    let(:params) { {} }

    describe 'params' do
      let(:type) {'params_test'}
      let(:title) { 'foo' }
      context 'when specifying one parameter' do
        let(:params) { {:param => 'bar'} }
        it { should contain_file('foo-param').with_source('bar') }
        it { should contain_notify('foo-default').with_message('default_val') }
      end
      context 'when specifying both paramaters' do
        let(:params) { {:param => 'bar', :param_with_default => 'baz'} }
        it { should contain_file('foo-param').with_source('bar') }
        it { should contain_notify('foo-default').with_message('baz') }
      end
    end

    describe 'nginx::simple_server' do
      let(:type) {'nginx::simple_server'}
      let(:title)    {'foo'}
      context 'basic functionality' do
        it { should contain_nginx__site('foo').
          with_content(/server_name foo;/)
        }
      end
    end

    context 'functions::define_test with function stubs' do
      let(:stubs) { {:extlookup => {['ssh-key-barry'] => 'the key of S'}} }
      let(:type) {'functions::define_test'}
      let(:title) {'foo'}
      it { should contain_ssh_authorized_key('barry').with_key('the key of S') }
    end

    describe 'facts::define_test' do
      let(:type) {'facts::define_test'}
      let(:title) {'test'}
      let(:facts) {
        { 'unqualified_fact' => 'no qualifications',
          'qualified_fact'   => 'cse ungraded in metalwork'}
      }
      it { should contain_notify('unqualified-fact-test').with_message('no qualifications') }
      it { should contain_notify('qualified-fact-test').with_message('cse ungraded in metalwork') }
    end
  end

  describe '#node' do
    subject { fizzgig.node(hostname, :facts => facts) }
    let(:facts) { {} }
    context 'simple node' do
      let(:hostname) {'foo.com'}
      it { should contain_nginx__site('foo.com') }
    end
    context 'default node' do
      let(:hostname) {'foo.invalid'}
      it { should contain_notify('oops, default') }
    end
    context 'node with facts specified' do
      let(:hostname) {'fact.com'}
      let(:facts) { { 'fact_site' => 'facts.org' } }
      it { should contain_nginx__site('facts.org') }
    end
  end
end
