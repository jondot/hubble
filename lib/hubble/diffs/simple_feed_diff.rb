require 'nokogiri'

module Hubble
  class SimpleFeedDiff
    # old needs to be
    #  { 
    #     :meta => { :latest_id => '<latest post id>' }
    #  }
    #
    # new is new feed XML
    def diff(old_meta, new_content, content_type=nil)
      doc = Nokogiri.parse(new_content)

      # nokogiri CSS query allows a robust functionality - we don't care about
      # original XML format (rss, atom) or namespaces (no need for remove_namespaces! with xpath)
      ids = doc.css('entry > id')

      return [old_meta, nil] if ids.empty?

      lastest_meta = {
        :meta => 
        {
          :latest_id => ids.first.content
        }
      }

      # first hit, no previous history
      return [lastest_meta, new_content] if old_meta.nil?

      # no new entries
      return [old_meta, nil] if lastest_meta[:meta][:latest_id] == old_meta[:meta][:latest_id]

      # fetch entry corresponding to our old id
      latest_id = doc.css('entry > id').find{ |e| e.content == old_meta[:meta][:latest_id] }

      if(latest_id)
        # chop off this entry and everything below it.
        latest_entry  = latest_id.parent
        while(latest_entry)
          next_entry = latest_entry.next
          latest_entry.remove
          latest_entry = next_entry
        end
      end

      [lastest_meta, doc.to_xml]
    end
  end
end
