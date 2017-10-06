# A Pager.

![A Pi Zero W with three glowing lights](/img/finished.jpg)

So recently a few projects have aligned, and an old idea has come back off the shelf.  A Thing that connects
to the Internet and lets me know when a support ticket comes in.  Many people would call this a pager, and indeed
it is, with a bit of extra sentiment analysis magic.  In the example picture taken above I had set it up with a couple
of messages, one `doom! gloom! disaster!` and one `great, much love!`, and the LEDs lit up as expected. Then an actual
support ticket came in, that as you'd expect sat somewhere between those two extremes. One light per active thread,
with only a brief moment of "why's that just lit?".

This is a fairly simple project that connects to our chat service, listens for activity, and then lights or dims a LED
depending on whether it's a comment or us closing a ticket.

## Building the Pager

You will need:

* [Pi Zero W starter kit.](https://shop.pimoroni.com/products/pi-zero-w-starter-kit), although it will work with any Pi.
* [The SupportBlinkt codebase](https://github.com/resin-io-playground/SupportBlinkt)

1) Create an application within [resin.io](http://resin.io), [etch](http://etcher.io) the microSD card, clone and push
the repo.
2) Build the PiBow case, this is done after (1) because the case encloses the microSD
3) Set up your environment variables with FLOWDOCK_TOKEN from their
[API tokens page](https://www.flowdock.com/account/tokens).
    1) I've set this up on the Resin dashboard for the *application*, under environment variables, so a swarm of these
    could all share the same default token.
4) When the device boots, it will log the flows that the token gives visibility to.
5) Set up your environment variables with FLOWDOCK_FLOW_IDS, a JSON encoded array. eg `["01234567-89ab-cdef-0123-456789abcdef"]`
    1) I've set this up on the Resin dashboard for the *device*, under environment variables, so a swarm of these could
    monitor different parts of our communications.
6) Done, when it boots it should show all blue LEDs, and once connected to Flowdock all green LEDs.
7) When a comment comes in the LEDs should update.

## Pager++ (what's next)

* Make the reset criteria less likely to get triggered by a member of the public.
* Have it trigger a Pavlovian reward mechanism whenever a ticket is closed.
    * Perhaps drop a chocolate - contributions welcome!

## Implementation Details.

### [Flowdock](https://www.flowdock.com)

Flowdock is a service we use for much of our communication, and this includes transcripts of our support conversations.
These are organised thematically (which it calls 'flows'), and per conversation (which it calls 'threads'), which makes
it really easy to know where to watch, and what relates together.

They provide a good API and SDK that uses web streams to provide a continual sequence of events to a registered handler
function, in my code this is `stream.on('message', (message) ->` and this forms the entry point for the bulk of
the code.

### [Sentiment](https://www.npmjs.com/package/sentiment)

Since I had three-colour LEDs I decided to use them, and went for sentiment analysis. There's a nifty npm library
called [sentiment](https://www.npmjs.com/package/sentiment) that takes a guess at the tone of a block of text. It 
reports a couple of statistics (total and mean, but it calls them score and comparative), calculated using a stock word
list. My code then converts this to a percentile from among all of the sentiments seen this boot, and simply expresses
this as a hue (as in HSV) within the 0-120 (red-green) spectrum.

### Busy times

The Blinkt PHAT has 8 LEDs, and sometimes there are more than 8 support requests live. I decided to make this into a
feature. So, every time a light should be lit it decides randomly where along the strip glow. Every tenth of a second
it checks to see if two have chosen the same dot, and asks the newest to move in a random direction.

As the number of issues increases towards the number of LEDs the bouncing around before settling increases. When
the number of tickets gets above the number of LEDs this never settles down and is quite attention grabbing.

### Ticket closed

Once we've sorted the issue and gleaned what improvements we can this then dims the LED, as this issue has now entered
its rest state. For my part I've settled into the habit of my final notes always beginning with "status:", "handover:"
or "teardown:", and this is a habit that a computer can recognise.
(somewhere there's an excellent blog post on how we treat support requests as an indicator of a problem in our code or 
docs, and so are a main source of direction for our development efforts) 
