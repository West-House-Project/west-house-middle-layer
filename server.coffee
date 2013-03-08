express = require 'express'
http    = require 'http'
path    = require 'path'

settings = require './settings.json'

MCONTROL_API_PATH = '/mControl/api'

#app = express()
#server = http.createServer app

app = express()

PORT = process.argv[2]||3000
PUBLIC_DIR = path.join __dirname, 'public'

# ## `getDevices`
#
# TODO: put this in a new module.
#
# Gets the list of all devices from an instance of mControl.
getDevices = (callback) ->
  request = http.request {
    host: settings.host
    path: "#{MCONTROL_API_PATH}/devices"
    headers:
      'Content-Type': 'text/json'
  }, (res) ->
    res.setEncoding 'utf8'

    data = ''

    res.on 'data', (chunk) ->
      data += chunk

    res.on 'end', ->
      callback null, JSON.parse data

  request.end()

# TODO: put this in a new module.
getDevice = (id, callback) ->
  request = http.request {
    host: settings.host
    path: "#{MCONTROL_API_PATH}/devices/#{id}"
    headers:
      'Content-Type': 'text/json'
  }, (res) ->
    res.setEncoding 'utf8'

    data = ''

    res.on 'data', (chunk) ->
      data += chunk

    res.on 'end', ->
      callback null, JSON.parse data

  request.end()

# TODO: put this in a new module.
sendCommand = (id, data, callback) ->
  request = http.request {
    host: settings.host
    path: "#{MCONTROL_API_PATH}/devices/#{id}/send_command"
    method: 'PUT'
    headers:
      'Content-Type': 'text/json'
  }, (res) ->
    res.setEncoding 'utf8'

    data = ''

    res.on 'data', (chunk) ->
      data += chunk

    res.on 'end', ->
      callback null, data

  request.write JSON.stringify data
  request.end()

app.use express.bodyParser()
app.use express.methodOverride()
app.use app.router
app.use express.static PUBLIC_DIR

# TODO: put this in a new module.
rest =
  get: (route, desc, cb) ->
    cb = desc unless cb?
    app.get route, cb

  post: (route, desc, cb) ->
    cb = desc unless cb?
    app.post route, cb

  put: (route, desc, cb) ->
    cb = desc unless cb?
    app.put route, cb

  'delete': (route, desc, cb) ->
    cb = desc unless cb?
    app.put route, cb

rest.get '/', (req, res) ->
  res.json 400, { message: "Please head over to /devices." }

rest.get '/devices', (req, res) ->
  getDevices (err, data) ->
    res.jsonp data

rest.get '/devices/:id', (req, res) ->
  getDevice req.params.id, (err, data) ->
    res.jsonp data

rest.put '/devices/:id/send_command', (req, res) ->
  sendCommand req.params.id, req.body, ->
    res.send "Success"

rest.get '/send_command', (req, res) ->
  res.sendfile path.join __dirname, 'public', 'index.html'

#server.listen PORT
app.listen PORT
console.log "Server listening on port #{PORT}"