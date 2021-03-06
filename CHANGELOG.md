# 0.4.0
  * Changed configuration style:
    * Removed RSpec.configure interface
    * Added OO interface to Fizzgig to allow storing configuration in
      the Fizzgig instance
  * Removed RSpec matchers; you can use the matchers from rspec-puppet
    instead:

```ruby
  require 'rspec-puppet/matchers'
  RSpec.configure do |c|
    c.include RSpec::Puppet::ManifestMatchers
  end
```

# 0.3.0

  * Changed API for #instantiate to take ruby Hash of params rather
    than String containing puppet code

# 0.2.1

  * Added support for evaluating nodes using Fizzgig.node(hostname)

# 0.2.0

  * Changed function stubs to allow multi-arg functions. This broke
existing code, since single args need to be wrapped in an Array.

# 0.1.1

  * fixed bug to allow multiple conditions on a matcher, eg:
```ruby
  it {should contain_file('foo').with_content(/asdf/).with_content(/jkl;/)}
```


# 0.1.0

  * Initial release
