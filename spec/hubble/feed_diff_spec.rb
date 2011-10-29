require 'helper'
require 'hubble/diffs/simple_feed_diff'
require 'hubble/diffs/digest_feed_diff'


include Hubble

NEW_ITEMS_FEED = <<EOF
<?xml version="1.0" encoding="utf-8"?>
<feed xmlns="http://www.w3.org/2005/Atom">

  <title>Example Feed</title>
  <link href="http://example.org/"/>
  <updated>2003-12-13T18:30:02Z</updated>
  <author>
    <name>John Doe</name>
  </author>
  <id>urn:uuid:60a76c80-d399-11d9-b93C-0003939e0af6</id>

  <entry>
    <title>Atom-Powered Robots Run Amok</title>
    <link href="http://example.org/2003/12/13/atom03"/>
    <id>123134s</id>
    <updated>2003-12-13T18:30:02Z</updated>
    <summary>Some text.</summary>
  </entry>

  </feed>
EOF
 
describe SimpleFeedDiff do
  it "should extract new entries given and old and newer feed" do
    d = SimpleFeedDiff.new
    d.diff({ :meta => { :latest_id => '123' }}, file_content('feed_new.xml'))[1].must_equal NEW_ITEMS_FEED
  end 

  it "should pass out nil given no id found or file structure bad" do
    d = SimpleFeedDiff.new
    d.diff({ :meta => { :latest_id => '123' }}, file_content('feed_no_id.xml'))[1].must_equal nil
  end

  it "should pass out nil given no new entry" do
    d = SimpleFeedDiff.new
    d.diff({ :meta => { :latest_id => '123134s' }}, file_content('feed_new.xml'))[1].must_equal nil
  end
end

describe DigestFeedDiff do
  it "should digest entries" do
    d = DigestFeedDiff.new
    res = d.diff({:meta => {:entries => ["c8648db207cdf8744dbcebbc3bf5331e", "4083b895476bd1cefc90072e414e728d"]}}, file_content('feed_new.xml'))
    res[0].must_equal({:meta=>{:entries=>["c8648db207cdf8744dbcebbc3bf5331e", "4083b895476bd1cefc90072e414e728d", "b57515cc3266247a1106b76018a8495d"]}})
    res[1].must_equal <<EOF
<?xml version="1.0" encoding="utf-8"?>
<feed xmlns="http://www.w3.org/2005/Atom">

  <title>Example Feed</title>
  <link href="http://example.org/"/>
  <updated>2003-12-13T18:30:02Z</updated>
  <author>
    <name>John Doe</name>
  </author>
  <id>urn:uuid:60a76c80-d399-11d9-b93C-0003939e0af6</id>

  

  

  <entry>
    <title>Atom-Powered Robots Run Amok</title>
    <link href="http://example.org/2003/12/13/atom03"/>
    <id>urn:uuid:1225c695-cfb8-4ebb-aaaa-80da344efa6a</id>
    <updated>2003-12-13T18:30:02Z</updated>
    <summary>Some text.</summary>
  </entry>

  

</feed>
EOF

  end
end
