class DiotribeExtension < Radiant::Extension
  version "0.1"
  description "A variety of useful tags for DioTribe sites created."
  url "http://www.fn-group.com"
  
  def activate
    Page.send :include, DiotribeTags
  end

  def deactivate
  end
end