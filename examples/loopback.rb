require 'sinatra'
require 'httparty'
require 'pp'
require 'atom'
require 'uri'

# 
# instructions:
# - hub running at:             localhost:3000
# - hub resque workers running: rake resque:work QUEUE=job_runner
#
# publish a topic - GET http://localhost:9292/publish?hub=http://localhost:3000
# subscribe       - GET http://localhost:9292/subscribe?hub=http://localhost:3000
# (notice hub verifies in the background)
#
# now publish again - GET http://localhost:9292/publish?hub=http://localhost:3000
# (notice we get a ping from hub with diff)
#
class Loopback < Sinatra::Base
  @@entries = []

  def base_url
    "#{request.env['rack.url_scheme']}://#{request.env['HTTP_HOST']}"
  end

  #
  # http://localhost:9292/publish?hub=http://www.postbin.org/1au8sfh
  #
  get '/publish' do
    hub = params[:hub]
    @@entries << [Time.now, (params[:text] || "Test. #{ Time.now.to_s }")]
   
    res = HTTParty.post(hub, 
                  :query => { 'hub.mode' => 'publish', 'hub.url' => base_url + "/feed" },
                  :headers => { 'content-type' => 'application/atom+xml' },
                  :body=> "published")
    res.inspect.to_s
  end

  get '/feed' do
    content_type "application/atom+xml"
    feed = Atom::Feed.new do |f|
      f.title = "Loopback Feed"
      f.links << Atom::Link.new(:href => "http://127.0.0.1/")
      f.updated = Time.now.to_s
      f.authors << Atom::Person.new(:name => 'Lou Beck')
      f.id = "127.0.0.1"
      @@entries.reverse.each do |entry_tuple|
        time, text = entry_tuple
        f.entries << Atom::Entry.new do |e|
          e.title = text
          e.links << Atom::Link.new(:href => "http://127.0.0.1/entry/"+URI.encode(text))
          e.id = time
          e.updated = time
          e.summary = text
        end
      end
    end
    feed.to_xml
  end

  #
  # http://localhost:9292/subscribe?hub=http://www.postbin.org/1au8sfh
  #
  get '/subscribe' do
    hub = params[:hub]
   
    res = HTTParty.post(hub, 
                  :query => {
                    'hub.mode' => 'subscribe',
                    'hub.callback' => base_url + "/callback",
                    'hub.topic' => base_url + "/feed",
                    'hub.verify' => 'sync',
                  },
                  :body=> "subscribe")
    res.inspect.to_s
  end

  get '/callback' do
    params['hub.challenge']
  end

  post '/callback' do
    puts "*** got update from hub! ***"
    puts request.body.read
  end

  
end
