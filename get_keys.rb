require 'rest-client'
require 'nokogiri'
require 'active_support'
require 'active_support/core_ext'

class GenerateKey

  def initialize
    url         = "http://localhost:8989/LiveDrmService/LiveDrmService.asmx"
    auth = "bGl2ZWRybTpsaXZlZHJt"
    body = '<?xml version="1.0" encoding="utf-8"?><soap:Envelope xmlns:soap="http://www.w3.org/2003/05/soap-envelope" xmlns:liv="http://man.entriq.net/livedrmservice/"><soap:Header><liv:LiveDrmServiceHeader m_sUsername="admin@unifieds.com" m_sPassword="unifieds" KMSUsername="livedrm" KMSPassword="livedrm"/></soap:Header><soap:Body><liv:GenerateKeys><liv:accountId>default</liv:accountId><liv:contentId>1007</liv:contentId><liv:protectionSystem><liv:string>IrdetoProtection</liv:string></liv:protectionSystem></liv:GenerateKeys></soap:Body></soap:Envelope>'


    response = RestClient::Request.new({
      method: :post,
      url: url,
      payload: body,
      headers: { :Authentication => "Basic #{auth}", :content_type => "text/xml; charset=UTF-8" },
    }).execute do |response|
      case response.code
      when 500
        puts "WARNING: -- Local error"
          puts response.to_str
      when 400
        [ :error, response.to_str ]
        when 200
        [ :success, response.to_str ]
          # puts "SUCCESS -- " + response
          convert_to_xml(response)
      else
        fail "Invalid response #{response.to_str} received."
      end
    end

    # response = RestClient::Request.execute(method: :post, url: url,
    #                                        payload: body, headers: {:Authentication => "Basic #{auth}", :content_type => "text/xml; charset=UTF-8" })
    # puts response

  end

  def convert_to_xml(response)
    doc = Nokogiri::XML.parse response
    get_key(doc)

  end

  def get_key(doc)
    hash = Hash.from_xml(doc)
    aes_key = hash["Keys"]["Key"]["ContentKey"]
    puts aes_key
  end

end

key = GenerateKey.new
puts key