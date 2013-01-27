# mixi-community

Access to Mixi community.

## Installation

Add this line to your application's Gemfile:

    gem 'mixi-community'

And then execute:

    $ bundle

Or install it yourself as:

    $ gem install mixi-community

## Usage

    require 'mixi/community'

    fetcher = Mixi::Community::Fetcher.new('your_email', 'password')

    community = Mixi::Community.new('community id') # http://mixi.jp/view_community.pl?id={community id}

    community.fetch(fetcher)

    community.recent_bbses.each do|bbs|
      bbs.fetch(fetcher)

      bbs.recent_comments.each do|comment|
        puts "#{thread.title} #{comment.user_name} #{comment.body_text}"
      end
    end

See source for details.

## Contributing

1. Fork it
2. Create your feature branch (`git checkout -b my-new-feature`)
3. Commit your changes (`git commit -am 'Added some feature'`)
4. Push to the branch (`git push origin my-new-feature`)
5. Create new Pull Request

## Changes

### 0.0.2

* Add readme
* Add license
* Fix error when Encoding.default_internal is ASCII_8BIT

### 0.0.1

* Initial release.
