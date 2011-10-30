require 'nokogiri'
require 'digest/md5'

module Hubble
  class DigestFeedDiff

    def initialize(buffer_max=50)
      @buffer_max = buffer_max
    end

    def diff(old_meta, new_content, content_type=nil)
      old_meta ||= { :meta => {:entries => []}}

      doc = Nokogiri.parse(new_content)

      entries = doc.css('entry')
      return [old_meta, nil] if entries.empty?

      num_entries = entries.size
      entries.each do |entry|
        entry_digest = Digest::MD5.hexdigest(entry)

        if old_meta[:meta][:entries].include? entry_digest
          entry.remove
          num_entries = num_entries.pred
        else
          old_meta[:meta][:entries] << entry_digest
          old_meta[:meta][:entries].shift if old_meta[:meta][:entries].size > @buffer_max
        end
      end


      return [old_meta, nil] if num_entries == 0

      [old_meta, doc.to_xml]

    end
  end
end
