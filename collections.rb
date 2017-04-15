# coding: utf-8
#
# Collectionのナビゲーション
# @author 在望もむ
# @date 2015/11/22

# Jekyllプラグイン
module Jekyll
  class Misc
    # 対象のURLを持つパスを探索する。
    # パスは出力するパス(_sites)からの絶対パスで指定する。
    # ex. "_sites/index.html" => "/index.html"
    def self.search_page(site, url)
      result = site.pages.find {|item| item.url == url}
      if !result.nil?
        return result
      end
      result = site.posts.docs.find {|item| item.url == url}
      if !result.nil?
        return result
      end
      for collection in site.collections
        result = collection[1].docs.find {|item| item.url == url}
        if result
          return result
        end
      end
      return nil
    end
  end

  # コレクションページをLiquildで出力できるようにする
  class CollectionPageNest < Liquid::Drop
    attr_accessor :level, :page
    # コンストラクタ
    def initialize(level, page)
      @level = level
      @page = page
    end
  end

  # コレクション名取得クラス
  class CollectionList
    # コレクション名取得
    def create(context)
      list = Array.new([])
      site = context.registers[:site]
      site.collections.each do |tag, pages|
        # Jekyll 3.x以降はpostsもcollectionsとなったため、これを除外する
        if tag == 'posts'
          next
        end
        title = (site.config['collections'][tag]['name'] == nil) ? tag : site.config['collections'][tag]['name']
        list << {'title' => title, 'url' => '/' + site.baseurl + tag + '/index.html'}
      end

      return list
    end
  end

  # 指定したコレクション名の一覧を生成
  class CollectionItems
    def initialize(site, name)
      @site = site
      @name = name
    end

    # 初期化処理
    def create()
      @base_path = '/' + @name + '/index.html'
      @tag_name = (@site.config['collections'][@name]['name'] == nil) ? tag : @site.config['collections'][@name]['name']

      @h = Array.new([])
      @index = 0
      @level = 0
      # indexを探索
      result = Misc.search_page(@site, @base_path)
      if result
        @h << CollectionPageNest.new(@level, result)
        # 以降を追加
        next_exist()
      end
      return @h
    end

    def next_exist()
      endflag = true
      page = @h[@index].page
      while endflag == true
        if page.nil? || page.data.nil? || page.data['link_next'].nil?
          # 次の下層ページを確認する。
          next_down_exist()
          return
        end
        @base_path = File.dirname(@base_path) + '/' + page.data['link_next'] + '.html'
        result = Misc.search_page(@site, @base_path)
        if result
          @h << CollectionPageNest.new(@level, result)
          @index += 1
          page = @h[@index].page
          save = @index
          # 次の下層ページを確認する。
          next_down_exist()
          page = @h[save].page
          endflag = true
        else
          endflag = false
        end
      end
    end

    def next_down_exist()
      @level += 1
      page = @h[@index].page
      if page.nil? || page.data['link_down'].nil?
        @level -= 1
        return
      end
      @base_path = File.dirname(@base_path) + '/' + page.data['link_down'] + '.html'
      result = Misc.search_page(@site, @base_path)
      if result
        @index += 1
        @h << CollectionPageNest.new(@level, result)
        next_exist()
        @base_path = File.dirname(@base_path)
      end
      @level -= 1
    end
  end

  class CollectionNavi < Liquid::Tag
    # 初期化する
    def initialize(tag_name, text, tokens)
      super
      @text = text
    end

    # レンダリングする
    def render(context)
      @site = context.registers[:site]
      @page = context.registers[:page]
      pages = {
        'previous' => {:object => @page['link_previous'], :function => 'exist'},
        'down' => {:object => @page['link_down'], :function => 'exist'},
        'up' => {:object => @page['link_up'], :function => 'exist_up'},
        'next' => {:object => @page['link_next'], :function => 'exist'}
      }
      output = '<ul class="collection-navigation">'
      pages.each do |idx, value|
        output += "<li class=\"#{idx}\">"
        if !value[:object].nil?
          if self.method(value[:function]).call(value[:object])
            output += "<a href=\"#{@rr.url}\">#{@rr.data['title']}</a></li>"
          end
        end
        output += "</li>"
      end
      output += '</ul>'
      "#{output}"
    end

    # ページが存在するかチェックする
    def exist(page)
      if page == '' || page == nil || @site.collections[@page['collection']] == nil
        return false
      end
      result = Misc.search_page(@site, File.dirname(@page['url']) + '/' + page + ".html")
      if result
        @rr = result
        return true
      end
      return false
    end

    # ページが存在するかチェックする
    def exist_up(page)
      if page == '' || page == nil || @site.collections[@page['collection']] == nil
        return false
      end
      result = Misc.search_page(@site, File.dirname(File.dirname(@page['url']))  + '/' + page + ".html")
      if result
        @rr = result
        return true
      end
      return false
    end
  end

  # コレクションページ生成クラス
  class CollectionPage < Page
    # 初期化処理
    def initialize(site, base, dir, tag)
      @site = site
      @base = base
      @dir  = dir
      @name = 'index.html'
      @tag = tag
      @tag_name = (site.config['collections'][tag]['name'] == nil) ? tag : site.config['collections'][tag]['name']
      @base_path = '/' + @tag + '/index.html'
      self.process(name)
      self.read_yaml(File.join(base, '_layouts'), 'collection.html')
      self.data['title'] = "#{@tag_name}"
      self.data['posts'] = site.collections[tag].docs
      self.data['tag'] = tag
      self.data['title_detail'] = @tag_name + 'の記事一覧'

      @h = Array.new([])
      @index = 0
      @level = 0
      # indexを探索
      result = Misc.search_page(@site, @base_path)
      if result
        @h << CollectionPageNest.new(@level, result)
        # 以降を追加
        next_exist()
      end
      self.data['info'] = @h
    end

    def next_exist()
      endflag = true
      page = @h[@index].page
      while endflag == true
        if page.nil? || page.data.nil? || page.data['link_next'].nil?
          # 次の下層ページを確認する。
          next_down_exist()
          return
        end
        @base_path = File.dirname(@base_path) + '/' + page.data['link_next'] + '.html'
        result = Misc.search_page(@site, @base_path)
        if result
          @h << CollectionPageNest.new(@level, result)
          @index += 1
          page = @h[@index].page
          save = @index
          # 次の下層ページを確認する。
          next_down_exist()
          page = @h[save].page
          endflag = true
        else
          endflag = false
        end
      end
    end

    def next_down_exist()
      @level += 1
      page = @h[@index].page
      if page.nil? || page.data['link_down'].nil?
        @level -= 1
        return
      end
      @base_path = File.dirname(@base_path) + '/' + page.data['link_down'] + '.html'
      result = Misc.search_page(@site, @base_path)
      if result
        @index += 1
        @h << CollectionPageNest.new(@level, result)
        next_exist()
        @base_path = File.dirname(@base_path)
      end
      @level -= 1
    end
  end

  class CollectionPageGenerator < Generator
    safe true

    def generate(site)
      site.collections.each_key do |tag|
        site.pages << CollectionPage.new(site, site.source, File.join('collections', tag), tag)
      end
    end
  end

  # パンくずリスト出力ブロック
  class CollectionListBlock < Liquid::Block
    # 初期化フック処理
    # @param  [String]  name  名前
    # @param  [String]  text  テキスト
    # @param  [String]  tokens  トークン
    def initialize(name, text, tokens)
      super
    end

    # ページ毎実施処理
    # @param  [Misc]  context コンテキスト
    def render(context)
      collection_list = CollectionList.new()
      list = collection_list.create(context)
      context.stack do
        context['entries'] = list
        return super
      end
    end
  end

  class CollectionListTag < Liquid::Tag
    def initialize(tag_name, text, tokens)
      super
    end

    def render(context)
      collection_list = CollectionList.new()
      list = collection_list.create(context)
      tagcloud = '<ul class="collection-list">'
      list.each do |item|
        tagcloud << "<li><a href=\"#{item['url']}\">#{item['title']}</a></li>"
      end
      tagcloud << "</ul>"
      "#{tagcloud}"
    end
  end

  class CollectionItemsTag < Liquid::Tag
    def initialize(tag_name, text, tokens)
      @text = text.strip!
      super
    end

    def render(context)
      items = CollectionItems.new(context.registers[:site], @text)
      list = items.create()
      output = '<ul>'
      list.each do |item|
        output << "<li class=\"nest#{item.level}\"><a href=\"#{item.page.url}\">#{item.page['title']}</a></li>"
      end
      output << "</ul>"
      "#{output}"
    end
  end

  class CollectionListPage < Page
    def initialize(site, base, dir)
      @site = site
      @base = base
      @dir  = dir
      @name = 'index.html'
      self.process(name)
      self.read_yaml(File.join(base, '_layouts'), 'collection_list.html')
      self.data['title'] = (site.config['collection-list'] == nil || site.config['collection-list']['name'] == nil) ? "コレクション一覧" : site.config['collection-list']['name']
      self.data['posts'] = site.documents
    end
  end

  class CollectionListGenerator < Generator
    safe true
    def generate(site)
      site.pages << CollectionListPage.new(site, site.source, 'collection_list')
    end
  end
end

Liquid::Template.register_tag('collection_navi', Jekyll::CollectionNavi)
Liquid::Template.register_tag('collection_list', Jekyll::CollectionListTag)
Liquid::Template.register_tag('collection_items', Jekyll::CollectionItemsTag)
Liquid::Template.register_tag('collection_name_list', Jekyll::CollectionListBlock)
