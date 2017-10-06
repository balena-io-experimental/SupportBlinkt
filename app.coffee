Blinkt = require('node-blinkt')
Flowdock = require('flowdock').Session
_ = require('lodash')
convertColour = require('color-convert')
analyseSentiment = require('sentiment')

# If in the same place as another dot move in a random direction
# If in much more space to one side then move into it

class Dot
  constructor: (@blinkt = undefined, @hue = undefined, @position = undefined, @direction = undefined) ->
    @position ?= Math.floor(Math.random() * 8)
    @hue ?= Math.floor(Math.random() * 256)
    if not @blinkt?
      @blinkt = new Blinkt()
      @blinkt.setup()
      @blinkt.setAllPixels(0, 0, 0, 0)

  setColour: (hue) ->
    @hue = hue

  move: ->
    if Math.random() < 0.5
      @position++
    else
      @position--
    @position = _.clamp(@position, 0, 7)

  show: ->
    rgb = convertColour.hsv.rgb(@hue, 100, 100)
    @blinkt.setPixel(@position, rgb[0], rgb[1], rgb[2], 0.04)

class Line
  constructor: ->
    @dots = {}
    @bgHue = 0
    @bgVal = 0
    @blinkt = new Blinkt()
    @blinkt.setup()
    setInterval(=>
      occupied = {}
      _.forEach(@dots, (dot) ->
        if occupied[dot.position]
          dot.move()
        occupied[dot.position] = true
      )
      rgb = convertColour.hsv.rgb(@bgHue, 100, @bgVal)
      @blinkt.setAllPixels(rgb[0], rgb[1], rgb[2], 0.04)
      _.forEach(@dots, (dot) ->
        dot.show()
      )
      @blinkt.sendUpdate()
      @blinkt.sendUpdate()
    , 100)

  dot: (id, colour = undefined) ->
    if colour? and @dots[id]?
      @dots[id].setColour(colour)
    else if colour?
      @dots[id] = new Dot(@blinkt, colour)
    else
      delete @dots[id]

  background: (hue = undefined) ->
    if hue?
      @bgHue = hue
      @bgVal = 100
    else
      @bgVal = 0

sentimentsSeen = []

console.log('Connecting to Blinkt.')
line = new Line()
line.background(240)
console.log('Connecting to Flowdock.')
flowdock = new Flowdock(process.env.FLOWDOCK_TOKEN)
flowdock.on('error', ->
  line.background(0)
)
flowdock.flows((err, flows) ->
  line.background(120)
  if not process.env.FLOWDOCK_FLOW_IDS?
    console.log('Listing Flowdock flows.')
    _.forEach(flows, (flow) -> console.log("#{flow.name} #{flow.id}"))
)
console.log('Connecting to Flowdock stream.')
stream = flowdock.stream(JSON.parse(process.env.FLOWDOCK_FLOW_IDS ? '[]'))
stream.on('message', (message) ->
  if message.event == 'message'
    line.background()
    console.log(message.content.split(/[\r\n]/g)[0])
    if /^[\w-_]+:/i.test(message.content)
      line.dot(message.thread_id)
    else
      sentiment = analyseSentiment(message.content).comparative
      position = _.sortedIndex(sentimentsSeen, sentiment)
      percentile = if sentimentsSeen.length == 0 then 0.5 else position / sentimentsSeen.length
      sentimentsSeen.splice(position, 0, sentiment)
      line.dot(message.thread_id, percentile * 120)
)