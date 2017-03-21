require 'rest-client'
require 'nokogiri'
require 'active_support'
require 'active_support/core_ext'
require 'base64'
require 'json'

class GenerateKey

  def initialize;  end

  def get_config(content_id)
    content_id  = content_id
    config = File.read('config.json')       # --TODO-- move to central config
    generate_body(content_id, config)
  end

  def generate_body(content_id, config)
    begin
      data_hash = JSON.parse(config)
    rescue JSON::ParserError => e
      puts "Could not load configuration options"
    else
      namespaces  = {"xmlns:soap" => "http://www.w3.org/2003/05/soap-envelope", "xmlns:liv" => "http://man.entriq.net/livedrmservice/"}
      header = {"m_sUsername" => "#{data_hash['irdeto']['m_sUsername']}", "m_sPassword" => "#{data_hash['irdeto']['m_sPassword']}", "KMSUsername" => "#{data_hash['irdeto']['kmsUsername']}", "KMSPassword" => "#{data_hash['irdeto']['kmsUsername']}"}
      b = Nokogiri::XML::Builder.new
      b[:soap].Envelope(namespaces) {
        b[:soap].Header() {
          b[:liv].LiveDrmServiceHeader(header)
        }
        b[:soap].Body {
          b[:liv].GenerateKeys() {
            b[:liv].accountId(data_hash['irdeto']['account_id'])
            b[:liv].contentId(content_id)
            b[:liv].protectionSystem(){b[:liv].string(data_hash['irdeto']['protection'])}
          }
        }
      }
      body = b.to_xml(:save_with => Nokogiri::XML::Node::SaveOptions::AS_XML | Nokogiri::XML::Node::SaveOptions::NO_DECLARATION).strip.to_s
      make_request(body, data_hash)
    end
  end

  def make_request(body, data_hash)
    response = RestClient::Request.new({
      method: :post,
      url: data_hash['irdeto']['url'],
      payload: body,
      headers: { :Authentication => "Basic #{data_hash['irdeto']['auth']}", :content_type => "text/xml; charset=UTF-8" }
    }).execute do |response|
      case response.code
        when 500
          puts "WARNING: -- Local error"
          puts response.to_str
        when 400
          [ :error, response.to_str ]
        when 200
          [ :success, response.to_str ]
          convert_key(response)
        else
          fail "Invalid response #{response.to_str} received."
      end
    end
  end

  def convert_key(response)
    hash = Hash.from_xml(Nokogiri::XML.parse response)
    hash_key_id = hash["Keys"]["Key"]["KeyId"]
    hash_content_key = hash["Keys"]["Key"]["ContentKey"]
    aes_key = hash_content_key.unpack("m0").first.unpack("H*").first
    details = { contentKey: aes_key, laurl: "http://drm2.tv.delta.nl/keyfile/#{hash_key_id}" }
  end

end

key = GenerateKey.new.get_config(1007)
# request = key.get_config(1007)
puts key