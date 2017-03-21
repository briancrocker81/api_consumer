require 'rest-client'
require 'nokogiri'
require 'active_support'
require 'active_support/core_ext'
require 'base64'

module AesKey
  class GenerateKey

    def initialize;  end

    def get_config(content_id)
      content_id  = content_id
      generate_body(content_id)
    end

    def generate_body(content_id)
      rescue Exception => e
        puts "Could not load configuration options"
      else
        namespaces  = {"xmlns:soap" => "http://www.w3.org/2003/05/soap-envelope", "xmlns:liv" => "http://man.entriq.net/livedrmservice/"}
        header = {"m_sUsername" => "#{ENV['M_S_USERNAME']}", "m_sPassword" => "#{ENV['M_S_PASSWORD']}", "KMSUsername" => "#{ENV['KMS_USERNAME']}", "KMSPassword" => "#{ENV['KMS_PASSWORD']}"}
        b = Nokogiri::XML::Builder.new
        b[:soap].Envelope(namespaces) {
          b[:soap].Header() {
            b[:liv].LiveDrmServiceHeader(header)
          }
          b[:soap].Body {
            b[:liv].GenerateKeys() {
              b[:liv].accountId(ENV['ACCOUNT_ID'])
              b[:liv].contentId(content_id)
              b[:liv].protectionSystem(){b[:liv].string(ENV['IRDETO_PROTECTION'])}
            }
          }
        }
        body = b.to_xml(:save_with => Nokogiri::XML::Node::SaveOptions::AS_XML | Nokogiri::XML::Node::SaveOptions::NO_DECLARATION).strip.to_s
        make_request(body)
    end

    def make_request(body)
      response = RestClient::Request.execute(
          method: :post,
          url: ENV['IRDETO_URL'],
          payload: body,
          headers: { :Authentication => "Basic #{ENV['AUTHENTICATION']}", :content_type => "text/xml; charset=UTF-8" }
      )
      unless response.code == 200
        raise "an error"
      end
      convert_key(response)
    end

    def convert_key(response)
      hash = Hash.from_xml(Nokogiri::XML.parse response)
      hash_key_id = hash["Keys"]["Key"]["KeyId"]
      hash_content_key = hash["Keys"]["Key"]["ContentKey"]
      aes_key = hash_content_key.unpack("m0").first.unpack("H*").first
      details = { contentKey: aes_key, laurl: "http://drm2.tv.delta.nl/keyfile/#{hash_key_id}" }
    end
  end
end

key = AesKey::GenerateKey.new.get_config(1007)
# request = key.get_config(1007)
puts key