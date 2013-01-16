express = require 'express'
http = require 'http'
path = require 'path'

settings = require './settings.json'

MCONTROL_API_PATH = '/mControl/api'

app = express()
server = http.createServer app

port = process.argv[2]||3000


# ## `getDevices`
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

sendCommand = (id, data, callback) ->
  request = http.request {
    host: settings.host
    path: "#{MCONTROL_API_PATH}/devices/#{id}/send_command"
    method: 'PUT'
    headers:
      'Content-Type': 'text/json'
  }, ->
    callback null

  request.write JSON.stringify data

app.use express.bodyParser()
app.use express.methodOverride()
app.use express.errorHandler
  dumpException: true
  showStack: true
app.use app.router

app.get '/', (req, res) ->
  res.json 400, { message: "Please head over to /devices." }

app.get '/devices', (req, res) ->
  getDevices (err, data) ->
    res.jsonp data

app.get '/devices/:id', (req, res) ->
  getDevice req.params.id, (err, data) ->
    res.jsonp data

app.put '/devices/:id/send_command', (req, res) ->
  sendCommand req.params.id, req.body, ->
    console.log "Good to go."

server.listen port
console.log "Server listening on port #{port}"