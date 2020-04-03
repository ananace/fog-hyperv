# Fog Hyper-V

[![Build Status](https://travis-ci.org/ananace/fog-hyperv.svg?branch=master)](https://travis-ci.org/ananace/fog-hyperv) [![Gem Version](https://badge.fury.io/rb/fog-hyperv.svg)](https://badge.fury.io/rb/fog-hyperv)

Manage your Hyper-V instance with the help of the Fog cloud service abstractions.

## Installation

Add this line to your application's Gemfile:

```ruby
gem 'fog-hyperv'
```

And then execute:

    $ bundle

Or install it yourself as:

    $ gem install fog-hyperv

## Usage

To remotely manage your Hyper-V instance;

```ruby
require 'fog/hyperv'

compute = Fog::Compute.new(
  provider: :hyperv,
  hyperv_host: 'hyperv.example.com',
  hyperv_username: 'domain\\user',
  hyperv_password: 'password'
)

compute.servers.all
#=> [<Fog::Compute::Hyperv::Server
#=>   id='',
#=>   name='example',
#=>   computer_name='HYPERV',
#=>   dynamic_memory_enabled=false,
#=>   ...
```

## Troubleshooting

If you're getting `WinRM::AuthorizationErrors` from the negotiate transport
even when using a valid user, make sure that the WinRM service is configured
for Negotiate auth.

If you're using a local (non-domain) user, you may also need to set the DWORD
registry value `LocalAccountTokenFilterPolicy` at `HKLM\software\Microsoft\Windows\CurrentVersion\Policies\system`
to `1`.

## Development

After checking out the repo, run `bundle install` to install dependencies. Then, run `rake test` to run the tests. You can also run `bundle exec irb` for an interactive prompt that will allow you to experiment.

## Contributing

Bug reports and pull requests are welcome on GitHub at https://github.com/ananace/fog-hyperv

