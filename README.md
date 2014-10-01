# knife-wip

## Overview
Chef should be the authoritative source of how your infrastructure looks like.
Ideally what's in Chef is also what's running on the servers. However
sometimes you have to go into a server, stop Chef and debug something by hand.
This has all sorts of implications - depending on the length of the work - the
server won't get updates, drifts out of sync with app configuration and worst
of all nobody might know. This is why knife-wip provides a tag based way to
track work in progress in your infrastructure. Knife-wip uses Chef [node
tags][tags] to track who is working on which servers. This way it supports all
the great ways of searching for tags and testing for them in Chef recipe and
doesn't rely on any external setup.

## Usage

```
knife node wip web01.example.com php

knife node unwip web01.example.com

```



## Installation

```
gem install knife-wip
```


## Bugs
Probably. Please file a ticket [here][issues]



[tags]: https://docs.getchef.com/knife_tag.html
[issues]: https://github.com/mrtazz/knife-wip/issues

