todo:
- redis instance should get host/port from config
- this includes configuring resque
- testing over redis profile


# Hubble

Hubble is a lightweight, extensible ruby based Pubsubhubbub (PuSH) hub.  

In addition to conforming to the [PuSH spec 0.3](http://pubsubhubbub.googlecode.com/svn/trunk/pubsubhubbub-core-0.2.html), a real life hub
should have in its concerns how it is going to store topics, subscribers
and meta-data about feeds.  

Additionally it should decide how it would
push notifications to subscribers, as well as diff new and old feeds.  


Therefore, in order to allow more flexibility, in its core Hubble is agnostic to: storage, async execution and feed diffing algorithms.  

But you don't get an empty box!. Hubble includes a default implementation of:
* Storage: redis
* Async execution: Resque
* Diffing: a custom simple feed diff (based on last seen entry id)

## Quick Start
Hubble works with a redis profile out of the box. You will need a
`redis-server` running.  

Running Hubble:
    
    $ git clone https://github.com/jondot/hubble.git
    $ cd hubble; bundle install
    $ rackup

Running Hubble queue worker (for more, see [Resque](https://github.com/defunkt/resque)):
  
    $ rake resque:work QUEUE=job_runner

You can now run an example loopback application. The loopback
application can subscribe to the hub - as a subscriber, publish to the
hub as a publisher, and show you what the hub pings it with.

    $ cd examples; bundle install
    $ rackup

Now try this:  

_assume hub runs at `localhost:3000`, loopback at `localhost:9292`, worker
is running as mentioned above_

1. publish a topic - GET http://localhost:9292/publish?hub=http://localhost:3000
2. subscribe       - GET http://localhost:9292/subscribe?hub=http://localhost:3000
`(notice hub verifies in the background)`

3. now publish again - GET http://localhost:9292/publish?hub=http://localhost:3000
`(notice we get a ping from hub with diff)`


## Profiles

In order to support a notion of plug-and-play backends, Hubble
introduces a 'profile'. We use a _redis profile_ by default.  

A profile is nothing more than a class which conforms to the interface
defined in the docs (see `lib/hubble/profiles/redis_profile.rb`) and
includes `Hubble::Profile`.  

A profile also includes a configurable `connection`.


## Diffs

A diff algorithm is nothing more than a class which conforms to the
following interface:

    def diff(old_meta, new_content, content_type=nil)

where `old_meta` is any old content form that can help you extract the
new content from `new_content`.  
`content_type` is there to help you toggle algorithms upon the content's type - if you decide you want to be aware of
that (i.e. parsing `rss` vs `atom`).

## Copyright

Copyright (c) 2011 [Dotan Nahum](http://gplus.to/dotan) [@jondot](http://twitter.com/jondot). See LICENSE.txt for further details.

