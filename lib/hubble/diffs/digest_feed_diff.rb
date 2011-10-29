require 'nokogiri'
require 'digest/md5'

module Hubble
  class DigestFeedDiff
    BUFFER_SIZE = 50
    
    def diff(old_meta, new_content, content_type=nil)
      old_meta ||= { :meta => {:entries => []}}

      doc = Nokogiri.parse(new_content)

      entries = doc.css('entry')
      return [old_meta, nil] if entries.empty?

      entries.each do |entry|
        entry_digest = Digest::MD5.hexdigest(entry)

        if old_meta[:meta][:entries].include? entry_digest
          entry.remove
        else
          old_meta[:meta][:entries] << entry_digest
        end
      end

      [old_meta, doc.to_xml]

    end
  end
end
