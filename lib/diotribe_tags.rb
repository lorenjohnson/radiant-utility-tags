# require 'date'
# require 'parsedate'
# 
module DiotribeTags
  include Radiant::Taggable

  desc %{ <r:find_level level="" />  
          returns parent of level for current page context  }
  tag 'find_level' do |tag|
    if tag.attr['level']
      url_array = @request.request_uri.split("/")
      url = url_array[0..tag.attr['level'].to_i].join("/")
      tag.locals.page = Page.find_by_url(url)
      tag.expand
    else
      raise TagError.new("`find_level' tag must contain `level' attribute")
    end
  end
  
  desc %{ <r:section_name />  
          returns title of parent page }
  tag 'section_name' do |tag|
    parent = tag.locals.page.parent
    parent.title
  end
  
  desc %{ <r:if_request_url matches=""></r:if_request_url>  
          returns enclosed content only if the current uri matches the regex found in matches }
  tag 'if_request_uri' do |tag|
    ignore_case = true
    regexp = Regexp.new(tag.attr['matches'],ignore_case)
    unless @request.request_uri.match(regexp).nil?
       tag.expand
    end
    # if tag.attr['matches'] == @request.request_uri then "here" end
    # @request.request_uri << "   " << tag.attr['url']
  end

  desc %{ <r:navigation_level urls="" level=""></r:navigation_level>  
          Same as standard navigation tag with the addition of a level attribute. 
          Will trigger both here and selected options for any item under a level N section.
          The primary reason for the existence of this tab is so that we can have a selected and here
          class indicated on a parent node of the actual URL represented.   }  
  tag 'navigation_level' do |tag|
    hash = tag.locals.navigation = {}
    tag.expand
    raise TagError.new("`navigation' tag must include a `normal' tag") unless hash.has_key? :normal
    result = []
    pairs = tag.attr['urls'].to_s.split(';').collect do |pair|
      parts = pair.split(':')
      value = parts.pop
      key = parts.join(':')
      [key.strip, value.strip]
    end
    pairs.each do |title, url|
      compare_url = remove_trailing_slash(url)
      page_url = remove_trailing_slash(@request.request_uri)
      # page_url = remove_trailing_slash(self.url)
      hash[:title] = title
      hash[:url] = url

      # Cut down url in nav control to significant level according to tag.attr('level') 
      if tag.attr['level']
        url = url.split("/")[0..tag.attr['level'].to_i].join("/")
      end

      case page_url
      when compare_url
        result << (hash[:here] || hash[:selected] || hash[:normal]).call
      when Regexp.compile( '^' + Regexp.quote(url))
        result << (hash[:selected] || hash[:normal]).call

      # implement a regex option here to replace the string and array operations above
      # menu is selected if tag.attr['level'] is set 
      # and the compare_url hacked down to that depth is present in the page_url  

      else
        result << hash[:normal].call
      end
    end
    between = hash.has_key?(:between) ? hash[:between].call : ' '
    result.join(between)
  end

  [:normal, :here, :selected, :between].each do |symbol|
    tag "navigation_level:#{symbol}" do |tag|
      hash = tag.locals.navigation
      hash[symbol] = tag.block
    end
  end

  [:title, :url].each do |symbol|
    tag "navigation_level:#{symbol}" do |tag|
      hash = tag.locals.navigation
      hash[symbol]
    end
  end
  
  def remove_trailing_slash(string)
    (string =~ %r{^(.*?)/$}) ? $1 : string
  end
  
end
  
