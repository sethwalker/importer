
require File.dirname(__FILE__) + '/test_helper'

require 'uri'
require 'active_resource/connection'
require 'action_controller/integration'                       
                                    
ShopifyAPI::Session.secret = 'secret'               
ActiveResource::Base.site = "http://apple:token@apple.myshopify.com/admin"    

class Test::Unit::TestCase
          
  def freeze(name, item)                                                                                                    
    method_name = name.split('.').last
    assert = "assert_equal %s, %s"
  
    return if ['created_at', 'updated_at', 'id'].include?(method_name)
    raise "Dangerous export #{method_name} at #{name}" if ['password', 'credit_card', 'shop_id'].include?(method_name)
  
    if item.respond_to?(:attributes)                                
      keys = item.attributes.keys.sort
      puts assert % [keys.inspect, "#{name}.attributes.keys.sort"]
      keys.each do |key|                                 
        freeze("#{name}.#{key}", item.attributes[key]) 
      end
    elsif item.is_a?(Array)                                  
      puts assert % [item.size, "#{name}.size"]
      item.each_with_index do |array_item, index|                   
        freeze("#{name}[#{index}]", array_item) 
      end
    elsif item.is_a?(BigDecimal)
      puts assert % ["BigDecimal.new('#{item.to_s}')", name]
    elsif item.class.respond_to?(:parse)
      puts assert % ["#{item.class}.parse('#{item.to_s}')", name]
    else
      puts assert % ["#{item.inspect}", name]
    end  
  end
end

module ActiveResource
  class LoopbackRequest          
    
    attr_accessor :session

    for method in [ :post, :put ]
      module_eval <<-EOE
        def #{method}(path, body, headers)
          @session.#{method}(path, body, headers)
          Response.new(@session.response.body, @session.response.code, @session.response.headers)
        end
      EOE
    end

    for method in [ :get, :delete ]
      module_eval <<-EOE
        def #{method}(path, headers)                 
          @session.#{method}(path, nil, headers)     
          Response.new(@session.response.body, @session.response.code, @session.response.headers)
        end
      EOE
    end

    def initialize(site)                                   
      @session = ActionController::Integration::Session.new
      @session.host = site.host      
      @site = site
    end
  end

  class Response
    attr_accessor :body, :message, :code, :headers

    def initialize(body, message = 200, headers = {})
      @body, @message, @headers = body, message.to_s, headers
      @code = @message[0,3].to_i

      resp_cls = Net::HTTPResponse::CODE_TO_OBJ[@code.to_s]
      if resp_cls && !resp_cls.body_permitted?
        @body = nil
      end

      if @body.nil?
        self['Content-Length'] = "0"
      else
        self['Content-Length'] = body.size.to_s
      end
    end

    def success?
      (200..299).include?(code)
    end

    def [](key)
      headers[key]
    end

    def []=(key, value)
      headers[key] = value
    end

    def ==(other)
      if (other.is_a?(Response))
        other.body == body && other.message == message && other.headers == headers
      else
        false
      end
    end
  end

  class Connection
    silence_warnings do
      def http
        @http ||= LoopbackRequest.new(@site)
      end
    end
  end
end
