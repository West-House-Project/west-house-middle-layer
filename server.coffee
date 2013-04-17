express    = require 'express'
http       = require 'http'
path       = require 'path'
commander  = require 'commander'
settings   = require './settings.json'
pkg        = require './package.json'
mysql      = require 'mysql'

commander
  .version(pkg.version)
  .option('-p, --port <n>', 'The port number to broadcast and listen to.', parseInt)
  .option('-s, --silent', "Don't poll the database.")
  .parse(process.argv)

connection = mysql.createConnection settings.database
connection.connect()

query = "select a.Date, a.Hour, coalesce(a.total_kwh - 
    (select b.total_kwh from (select @curRow := @curRow + 1 AS 'row', DATE(timestamp) as 'Date', HOUR(timestamp) as 'Hour', `bcpm_01_kwh`+`bcpm_02_kwh`+`bcpm_03_kwh`+`bcpm_03_kwh`+`bcpm_04_kwh`+`bcpm_05_kwh`+`bcpm_06_kwh`+`bcpm_07_kwh`+`bcpm_08_kwh`+`bcpm_09_kwh`+`bcpm_10_kwh`+`bcpm_11_kwh`+`bcpm_12_kwh`+`bcpm_13_kwh`+`bcpm_14_kwh`+`bcpm_15_kwh`+`bcpm_16_kwh`+`bcpm_17_kwh`+`bcpm_18_kwh`+`bcpm_19_kwh`+`bcpm_20_kwh`+`bcpm_21_kwh`+`bcpm_22_kwh`+`bcpm_23_kwh`+`bcpm_24_kwh`+`bcpm_25_kwh`+`bcpm_26_kwh`+`bcpm_27_kwh`+`bcpm_28_kwh`+`bcpm_29_kwh`+`bcpm_30_kwh`+`bcpm_31_kwh`+`bcpm_32_kwh`+`bcpm_33_kwh`+`bcpm_34_kwh`+`bcpm_35_kwh`+`bcpm_36_kwh`+`bcpm_37_kwh`+`bcpm_38_kwh`+`bcpm_39_kwh`+`bcpm_40_kwh`+`bcpm_41_kwh`+`bcpm_42_kwh` as 'total_kwh' from bcpm JOIN (SELECT @curRow := 0) r where (DATE(timestamp)=subdate(current_date, 1) and HOUR(timestamp)='23' and MINUTE(timestamp)='59' and SECOND(timestamp)>='50') or (DATE(timestamp)=CURDATE() and MINUTE(timestamp)='59' and SECOND(timestamp)>='50')) b where a.row = b.row + 1), a.total_kwh) as energyConsumedToday
from (select @rownum := @rownum + 1 AS 'row', DATE(timestamp) as 'Date', HOUR(timestamp) as 'Hour', `bcpm_01_kwh`+`bcpm_02_kwh`+`bcpm_03_kwh`+`bcpm_03_kwh`+`bcpm_04_kwh`+`bcpm_05_kwh`+`bcpm_06_kwh`+`bcpm_07_kwh`+`bcpm_08_kwh`+`bcpm_09_kwh`+`bcpm_10_kwh`+`bcpm_11_kwh`+`bcpm_12_kwh`+`bcpm_13_kwh`+`bcpm_14_kwh`+`bcpm_15_kwh`+`bcpm_16_kwh`+`bcpm_17_kwh`+`bcpm_18_kwh`+`bcpm_19_kwh`+`bcpm_20_kwh`+`bcpm_21_kwh`+`bcpm_22_kwh`+`bcpm_23_kwh`+`bcpm_24_kwh`+`bcpm_25_kwh`+`bcpm_26_kwh`+`bcpm_27_kwh`+`bcpm_28_kwh`+`bcpm_29_kwh`+`bcpm_30_kwh`+`bcpm_31_kwh`+`bcpm_32_kwh`+`bcpm_33_kwh`+`bcpm_34_kwh`+`bcpm_35_kwh`+`bcpm_36_kwh`+`bcpm_37_kwh`+`bcpm_38_kwh`+`bcpm_39_kwh`+`bcpm_40_kwh`+`bcpm_41_kwh`+`bcpm_42_kwh` as 'total_kwh' from bcpm JOIN (SELECT @rownum := 0) r where (DATE(timestamp)=subdate(current_date, 1) and HOUR(timestamp)='23' and MINUTE(timestamp)='59' and SECOND(timestamp)>='50') or (DATE(timestamp)=CURDATE() and MINUTE(timestamp)='59' and SECOND(timestamp)>='50')) a
Where a.row > 1"

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

rest.get '/dash-board.json', (req, res, next) ->
  connection.query query, (err, results) ->
    return next err if err
    console.log "Requested database."
    console.log results
    res.json results

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