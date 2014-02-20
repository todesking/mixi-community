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

### 0.0.7

* Support new version HTML

### 0.0.6

* Support new version HTML

### 0.0.5

* Support new version HTML('jp.mixi.community.widget.deferedlink').
* Remove trashes from BBS comment text.
* Remove forwarding/trailing white spaces from users name.

### 0.0.4

* Support new date format(again!)

### 0.0.3

* Support new date format

### 0.0.2

* Add readme
* Add license
* Fix error when Encoding.default_internal is ASCII_8BIT

### 0.0.1

* Initial release.
