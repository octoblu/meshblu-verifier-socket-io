_ = require 'lodash'
async = require 'async'
Meshblu = require 'meshblu'

class Verifier
  constructor: ({@meshbluConfig, @onError}) ->

  _connect: =>
    @meshblu = Meshblu.createConnection @meshbluConfig
    @meshblu.socket.on 'connect_error', @onError
    @meshblu.socket.on 'error', @onError

  _register: (callback) =>
    @_connect()
    @meshblu.once 'ready', =>
      @meshblu.register type: 'meshblu:verifier', (@device) =>
        return callback new Error @device.error if @device?.error?

        @meshbluConfig.uuid = @device.uuid
        @meshbluConfig.token = @device.token
        @meshblu.close()
        @_connect()
        @meshblu.once 'ready', (device) =>
          callback()

  _whoami: (callback) =>
    @meshblu.whoami {}, (data) =>
      return callback new Error data.error if data?.error?
      callback()

  _unregister: (callback) =>
    return callback() unless @device?
    @meshblu.unregister @device, (data) =>
      return callback new Error data.error if data?.error?
      callback()

  verify: (callback) =>
    async.series [
      @_register
      @_whoami
      @_unregister
    ], (error) =>
      @meshblu.close()
      callback error

module.exports = Verifier
