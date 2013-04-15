express    = require 'express'
http       = require 'http'
path       = require 'path'
commander  = require 'commander'
settings   = require './settings.json'
pkg        = require './package.json'

commander
  .version(pkg.version)
  .option('-p, --port <n>', 'The port number to broadcast and listen to.', parseInt)
  .option('-s, --silent', "Don't poll the database.")
  .parse(process.argv)

bcpmHelper = require './bcpm-helper.coffee' unless commander.silent

MCONTROL_API_PATH = '/mControl/api'

app = express()
server = http.createServer app

PORT = commander.process or process.env.PORT or 3000
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
      try
        callback null, JSON.parse data
      catch e
        callback e

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
      try
        callback null, JSON.parse data
      catch e
        callback e

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

rest.get '/nothing', (req, res) ->
  res.json { message: "There is nothing here." }

rest.get '/devices', (req, res) ->
  getDevices (err, data) ->
    console.log data
    if data?
      res.json data
    else
      res.json { messag: "Nothing." }

rest.get '/devices/:id', (req, res) ->
  getDevice req.params.id, (err, data) ->
    res.json data

rest.get '/data/bcpm', (req, res) ->
  getDevices (err, data) ->
    res.json 501, { message: "Not yet implemented." }

rest.put '/devices/:id/send_command', (req, res) ->
  console.log req.params.id
  console.log req.body
  sendCommand req.params.id, req.body, ->
    res.send "Success"

rest.get '/send_command', (req, res) ->
  res.sendfile path.join __dirname, 'public', 'index.html'

# TODO: due to time-constraint rendering our inability to test at the moment,
#   we decided to poll for data from within *this* project.
#
#   this is insanely bad, since the polling is tightly coupled with being only
#   a middle-layer.
#
#   Eventually, we would need to refactor this so that the polling is done from
#   another server instead.

unless commander.silent
  setInterval ->
    getDevices (err, data) ->
      console.log err if err
      bcpmHelper.parse data
  , 1000 * 10

server.listen PORT
console.log "Server listening on port #{PORT}"