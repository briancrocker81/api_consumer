require 'rest-client'
require 'nokogiri'
require 'active_support'
require 'active_support/core_ext'
require 'base64'

class GenerateKey

  def initialize
  end

  def get_key(content_id)
    content_id  = content_id
    url         = "http://localhost:8989/LiveDrmService/LiveDrmService.asmx"
    auth        = "bGl2ZWRybTpsaXZlZHJt"
    account_id  = "default"
    protection  = "IrdetoProtection"
    m_sUsername = "admin@unifieds.com"
    m_sPassword = "unifieds"
    kmsUsername = "livedrm"
    kmsPassword = "livedrm"
    generate_body(content_id, url, auth, account_id, protection, m_sUsername, m_sPassword, kmsUsername, kmsPassword)
  end

  def generate_body(content_id, url, auth, account_id, protection, m_sUsername, m_sPassword, kmsUsername, kmsPassword)

    namespaces  = {"xmlns:soap" => "http://www.w3.org/2003/05/soap-envelope", "xmlns:liv" => "http://man.entriq.net/livedrmservice/"}
    header = {"m_sUsername" => "#{m_sUsername}", "m_sPassword" => "#{m_sPassword}", "KMSUsername" => "#{kmsUsername}", "KMSPassword" => "#{kmsPassword}"}
    b = Nokogiri::XML::Builder.new

    b[:soap].Envelope(namespaces) {
      b[:soap].Header() {
        b[:liv].LiveDrmServiceHeader(header)
      }
      b[:soap].Body {
        b[:liv].GenerateKeys() {
          b[:liv].accountId(account_id)
          b[:liv].contentId(content_id)
          b[:liv].protectionSystem(){b[:liv].string(protection)}
        }
      }
    }

    body = b.to_xml(:save_with => Nokogiri::XML::Node::SaveOptions::AS_XML | Nokogiri::XML::Node::SaveOptions::NO_DECLARATION).strip.to_s

    response = RestClient::Request.new({
         method: :post,
         url: url,
         payload: t_body,
         headers: { :Authentication => "Basic #{auth}", :content_type => "text/xml; charset=UTF-8" }
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
  end

  def convert_to_xml(response)
    doc = Nokogiri::XML.parse response
    convert_key(doc)
  end

  def convert_key(doc)
    hash = Hash.from_xml(doc)
    hash_key = hash["Keys"]["Key"]["ContentKey"]
    aes_key = hash_key.unpack("m0").first.unpack("H*").first
    details = { contentKey: aes_key, laurl: "drm2.tv.delta.nl" }.to_s
  end

end

key = GenerateKey.new
request = key.get_key("1007")

puts request