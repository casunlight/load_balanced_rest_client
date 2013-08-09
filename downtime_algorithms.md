# Downtime Algorithms

A downtime algorithm is an object that is responsible for determining how much time a server should be marked down for. Its interface is very simple. It should:

* Be initialized with all of the parameters the algorithm will need.
* Have a #call instance method, which takes a single argument that is an integer and returns an integer.

The integer that #call takes is a counter of consecutive downtimes that a server has. If a server was previously up and is now being marked down, this counter would be at 1, the next time 2, and so on. This counter resets the next time the server is marked back up.

The integer that #call returns is the amount of downtime, in seconds, that will be issued to the server.

## Examples

See files in [lib/algorithms/](lib/algorithms/) for examples.
