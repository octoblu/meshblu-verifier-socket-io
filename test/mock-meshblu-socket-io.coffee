http = require 'http'
SocketIO = require 'socket.io'

class MockMeshbluSocketIO
  constructor: (options) ->
    {@onConnection, @port} = options

  start: (callback) =>
    @server = http.createServer()
    @io = SocketIO @server
    @io.on 'connection', @onConnection
    @server.listen @port, callback

  when: (event, data) =>
    @io.on event, => return data

  stop: (callback) =>
    @server.close callback
    
module.exports = MockMeshbluSocketIO
