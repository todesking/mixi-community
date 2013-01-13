# -*- coding:utf-8 -*-
require 'mechanize'

module Mixi
  class Community
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
        bbs_uri = URI.parse(a.attr(:href))
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
          puts dt.at('a').attr(:href)
          user_uri = URI.parse(dd.at('dl.commentContent01 dt a').attr(:href))
          user_id = Hash[user_uri.query.split('&').map{|kv|kv.split('=')}]['content_id']
          user_name = dd.at('dl.commentContent01 dt a').text
          body_text = dd.at('dl.commentContent01 dd').text.strip.gsub(/\n\n返信$/, '').gsub(/\r/,"\n")
          comment_id = dt.at('.senderId a').attr(:name).gsub(/^comment_id_(\d+)$/, '\1')
          comment_num = dt.at('.senderId a').text.gsub(/^\[(\d+)\]$/, '\1')
          time = Time.strptime(dt.at('.date').text, '%Y年%m月%d日 %H:%M')

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
        login_form = page.form_with(name: 'login_form')
        if login_form
          login_form.email = @user_id
          login_form.password = @password
          login_form.submit

          page = @agent.page
          page.encoding = page_encoding
        end
        page
      end
    end
  end
end
