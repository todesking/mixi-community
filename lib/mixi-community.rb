# -*- coding:utf-8 -*-
require 'mechanize'

module Mixi
  class Community
    def self.read_href(elm)
      URI.parse(
         elm.attr('data-url') || elm.attr(:href)
      )
    end

    def initialize(id)
      @id = id
    end

    attr_reader :id
    attr_reader :title

    def uri
      URI.parse("http://mixi.jp/view_community.pl?id=#{id}")
    end

    def fetch(fetcher)
      page = fetcher.get(uri)
      @recent_bbses = page.search('#newCommunityTopic .contents dl dd a').map {|a|
        bbs_uri = Mixi::Community.read_href(a)
        bbs_title = a.text
        bbs_id = Hash[bbs_uri.query.split('&').map{|kv|kv.split('=')}]['id']

        BBS.new(self.id, bbs_id, title: bbs_title)
      }
    end

    def recent_bbses
      @recent_bbses
    end

    class BBS
      def initialize(community_id, id, params)
        @community_id = community_id
        @id = id
        @title = params[:title]
      end

      attr_reader :community_id
      attr_reader :id
      attr_reader :title

      attr_reader :recent_comments

      def uri
        URI.parse("http://mixi.jp/view_bbs.pl?id=#{id}&comm_id=#{community_id}")
      end

      def fetch(fetcher)
        page = fetcher.get(uri)
        @title = page.at('.bbsTitle .title').text
        @recent_comments = page.at('#bbsComment').at('dl.commentList01').children.select{|e|%w(dt dd).include? e.name}.each_slice(2).map {|dt,dd|
          user_uri = Mixi::Community.read_href(dd.at('dl.commentContent01 dt a'))
          user_id = Hash[user_uri.query.split('&').map{|kv|kv.split('=')}]['content_id']
          user_name = dd.at('dl.commentContent01 dt a[last()]').text.strip
          body_text = resolve_encoding(read_bbs_text(dd.at('dl.commentContent01 dd'))){|t|t}
          comment_id = dt.at('.senderId a').attr(:name).gsub(/^comment_id_(\d+)$/, '\1')
          comment_num = dt.at('.senderId a').text.gsub(/^\[(\d+)\]$/, '\1')
          time = resolve_encoding(dt.at('.date').text) {|t| parse_comment_time(t) }

          Comment.new(
            comment_id,
            user_id: user_id,
            user_name: user_name,
            body_text: body_text,
            num: comment_num,
            time: time,
          )
        }
      end

      def resolve_encoding(text, &block)
        # Nokogiriの返す文字列のエンコーディングはEncoding.default_internalに影響される｡
        # これがUTF-8以外だと正規表現によるマッチに失敗するため対策する必要がある｡
        # 当面必要ないのでASCII_8BITの場合以外は対処してない
        if text.encoding == Encoding::UTF_8
          block.call(text)
        elsif text.encoding == Encoding::ASCII_8BIT
          ret = block.call(text.force_encoding(Encoding::UTF_8))
          if String === ret
            ret.force_encoding(Encoding::ASCII_8BIT)
          else
            ret
          end
        else
          raise "Unsupported encoding: #{text.encoding}"
        end
      end

      def parse_comment_time(time_str)
        time_str = time_str.strip
        formats = ['%Y年%m月%d日 %H:%M', '%m月%d日 %H:%M']
        formats.each do|format|
          time = try_strptime(format, time_str)
          return time if time
        end
        raise ArgumentError, "Time format not matched: formats=#{formats.join(', ')}, input=#{time_str}"
      end

      def try_strptime(format, str)
        begin
          Time.strptime(str, format)
        rescue ArgumentError
          nil
        end
      end

      def read_bbs_text(elm)
        text = elm.children.select {|c| c.name == 'text' }.map(&:text).join
        text.strip.gsub(/\r/,"\n")
      end

      class Comment
        def initialize(id, params)
          @id = id
          @user_id = params[:user_id]
          @user_name = params[:user_name]
          @body_text = params[:body_text]
          @num = params[:num]
          @time = params[:time]
        end
        attr_reader :id
        attr_reader :user_id
        attr_reader :user_name
        attr_reader :body_text
        attr_reader :time
        attr_reader :num
      end
    end

    class Fetcher
      DEFAULT_USER_AGENT = 'Mozilla/5.0 (Windows NT 6.1; WOW64) AppleWebKit/537.1 (KHTML, like Gecko) Chrome/22.0.1207.1 Safari/537.1'
      def initialize user_id, password, user_agent = DEFAULT_USER_AGENT
        @user_id = user_id
        @password = password
        @agent = Mechanize.new
        @agent.user_agent = user_agent
        @agent.follow_meta_refresh = true
      end
      def get(uri)
        raise "invalid arg" unless uri.host == 'mixi.jp'
        page_encoding = 'euc-jp'

        page = @agent.get(uri)
        page.encoding = page_encoding

        if page.at("body").attr("class") == "logout"
          login_page = Mechanize.new.get("https://mixi.jp")
          login_form = login_page.form_with(name: "login_form")
          raise "login form not found" unless login_form

          login_form.email = @user_id
          login_form.password = @password
          login_form.next_url = uri.to_s

          @agent.submit(login_form)
          page = @agent.page
          page.encoding = page_encoding
        end
        page
      end
    end
  end
end
