# Fog Hyper-V

![Build Status](https://travis-ci.org/ace13/fog-hyperv.svg?branch=master)

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

## Development

After checking out the repo, run `bundle install` to install dependencies. Then, run `rake test` to run the tests. You can also run `bundle exec irb` for an interactive prompt that will allow you to experiment.

## Contributing

Bug reports and pull requests are welcome on GitHub at https://github.com/ace13/fog-hyperv.

