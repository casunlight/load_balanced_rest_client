Load Balanced Rest Client
======================

Automatically load balances a [Rest Client](https://github.com/rest-client/rest-client), allowing you to enjoy the benefits of redundancy without any additional points of failure.

Usage
-----

Simply create an instance of LoadBalancedRestClient and use it exactly as you would use a RestClient resource object.

```ruby
@client = LoadBalancedRestClient.new(["app1:8080", "app2:8080", "ap3:8080"])
@client["articles"].post {:article => {:name => "Test 1" }}
@client["articles/1"].get
@client["articles"].post {:article => {:name => "Test 2" }}
@client["articles/2"].get
```

How it Works
------------

The job of the load balancer is to distribute the requests made from RestClient to a cluster of servers as evenly as possible, respecting the fact that servers may go down and come back up at any given moment.

```log
I, [2013-08-08T12:09:05.301004 #55848]  INFO -- : Request 1/4: Trying app1:8080
I, [2013-08-08T12:09:05.303109 #55848]  INFO -- : Request 1/4: app1:8080 successful
I, [2013-08-08T12:09:05.305210 #55848]  INFO -- : Request 1/4: Trying app2:8080
I, [2013-08-08T12:09:05.307206 #55848]  INFO -- : Request 1/4: app2:8080 successful
I, [2013-08-08T12:09:05.307329 #55848]  INFO -- : Request 1/4: Trying app3:8080
I, [2013-08-08T12:09:05.309276 #55848]  INFO -- : Request 1/4: app3:8080 successful
I, [2013-08-08T12:09:05.309449 #55848]  INFO -- : Request 1/4: Trying app1:8080
I, [2013-08-08T12:09:05.309972 #55848]  INFO -- : Request 1/4: app1:8080 successful
```

What happens if a server goes down? The load balancer will mark it down for a certain amount of time and try it again later.
It will then go back to doing its business, skipping that host until its downtime expires. If its still down on its next try, it will receive additional downtime.

```log
I, [2013-08-08T12:27:31.244429 #56233]  INFO -- : Request 1/4: Trying app1:8080
I, [2013-08-08T12:27:31.246830 #56233]  INFO -- : Request 1/4: app1:8080 successful
I, [2013-08-08T12:27:31.246922 #56233]  INFO -- : Request 2/4: Trying app2:8081
I, [2013-08-08T12:27:31.248705 #56233]  INFO -- : Request 2/4: app2:8080 threw "Connection refused - connect(2)"
W, [2013-08-08T12:27:31.248773 #56233]  WARN -- : Marking server down: app2:8080 for 60 seconds
I, [2013-08-08T12:27:31.248872 #56233]  INFO -- : Request 3/4: Trying app3:8080
I, [2013-08-08T12:27:31.251256 #56233]  INFO -- : Request 3/4: app3:8080 successful
```

As you may have guessed, the load balancer limits the number of attempts it will make. This can be configured, but what happens when your servers go down and all of your attempts are exhausted?
The load balancer will throw a MaxTriesReached exception. You can catch this exception in your app and handle actual failure however way you want.

```log
I, [2013-08-08T12:27:31.251392 #56233]  INFO -- : Request 1/4: Trying app1:8080
I, [2013-08-08T12:27:31.253610 #56233]  INFO -- : Request 1/4: app1:8080 threw "Connection refused - connect(2)"
W, [2013-08-08T12:27:31.253723 #56233]  WARN -- : Marking server down: app1:8080 for 60 seconds
I, [2013-08-08T12:27:31.253830 #56233]  INFO -- : Request 2/4: Trying app2:8080
I, [2013-08-08T12:27:31.255725 #56233]  INFO -- : Request 2/4: app2:8080 threw "Connection refused - connect(2)"
W, [2013-08-08T12:27:31.255793 #56233]  WARN -- : Marking server down: app2:8080 for 60 seconds
I, [2013-08-08T12:27:31.255939 #56233]  INFO -- : Request 3/4: Trying app3:8080
I, [2013-08-08T12:27:31.257668 #56233]  INFO -- : Request 3/4: app3:8080 threw "Connection refused - connect(2)"
W, [2013-08-08T12:27:31.257703 #56233]  WARN -- : Marking server down: app3:8080 for 60 seconds
I, [2013-08-08T12:27:31.257961 #56233]  INFO -- : Request 4/4: Trying app1:8080
I, [2013-08-08T12:27:31.259669 #56233]  INFO -- : Request 4/4: app1:8080 threw "Connection refused - connect(2)"
E, [2013-08-08T12:27:31.259782 #56233] ERROR -- : Max tries reached
```

Finally, if all servers are marked down the load balancer will also include servers marked down as last resort. If one works its downtime will automatically expire, but during this time its downtime will never accumulate.

```log
I, [2013-08-08T12:27:31.251392 #56233]  INFO -- : Request 1/4: Trying app1:8080
I, [2013-08-08T12:27:31.253610 #56233]  INFO -- : Request 1/4: app1:8080 threw "Connection refused - connect(2)"
I, [2013-08-08T12:27:31.253830 #56233]  INFO -- : Request 2/4: Trying app2:8080
I, [2013-08-08T12:27:31.255725 #56233]  INFO -- : Request 2/4: app2:8080 threw "Connection refused - connect(2)"
I, [2013-08-08T12:27:31.255939 #56233]  INFO -- : Request 3/4: Trying app3:8080
I, [2013-08-08T12:27:31.251256 #56233]  INFO -- : Request 3/4: app3:8080 successful
```

Configuration
-------------

LoadBalancedRestClient accepts the same options that RestClient does. However, there are a few added options you should know about.

* `:catch` - An array of exceptions to catch. The default is: Errno::ECONNREFUSED, Errno::EHOSTUNREACH, RestClient::ServerBrokeConnection, and RestClient::RequestTimeout.
* `:max_tries` - The maximum number of tries the load balancer has to establish a connection before throwing MaxTriesReached. The default is 4.
* `:logger` - If you'd like to use a custom logger, you can pass one in here. Otherwise, the standard Ruby Logger is used.
* `:max_downtime` - The maximum amount of time, in seconds, a server should ever be marked as down. The default is 3600 (1 hour).
* `:downtime_algorithm` - An object responsible for determining how much time a server should be marked down for. The default is to use ExponentialDowntime.

Test Suite
----------

Aside from the usual unit tests, this library comes with several acceptance tests. The acceptance tests use a binary called "dying_web_server" that helps simulate a real web server going down. The original source code for the binary is provided.

Credits
-------

Written by Eric Rafaloff, BitLove, Inc.
