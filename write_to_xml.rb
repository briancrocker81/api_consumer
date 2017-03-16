require 'nokogiri'

module WriteXML

  def update_file(details)
    filename = 'src/channel1_aes.ism'
    if File.exist?(filename)
      doc = Nokogiri::XML(File.open(filename))
      puts 'Add node'
      meta    = doc.css("meta")
      paramGroup  = doc.css("paramGroup")
      new_meta = Nokogiri::XML::Node.new('meta content="true" name="aes_playout"',doc)
      doc.root.add_child(new_meta)

      File.write(filename, doc.to_xml(:save_with => Nokogiri::XML::Node::SaveOptions::AS_XML | Nokogiri::XML::Node::SaveOptions::NO_DECLARATION).strip.to_s)
      new_paramGroup = Nokogiri::XML::Node.new("paramGroup",doc)
      doc.root.add_child(new_paramGroup)
      new_paramGroup.content = ('content="true" name="aes_playout"')
      # node[name_node].set_attribute('content, "true"')
      File.write(filename, doc.to_xml)
    else
      Puts "ERROR reading file. File not found"
    end
  end

end