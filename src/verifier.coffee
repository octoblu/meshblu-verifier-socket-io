async = require 'async'
Meshblu = require 'meshblu'

class Verifier
  constructor: ({@meshbluConfig, @onError, @nonce}) ->
    @nonce ?= Date.now()

  verify: (callback) =>
    async.series [
      @_register
      @_whoami
      @_message
      @_update
      @_unregister
    ], (error) =>
      @meshblu.close()
      callback error

  _connect: =>
    @meshblu = new Meshblu @meshbluConfig
    @meshblu.on 'notReady', (error) =>
      error = new Error "Meshblu Error: #{error.status}"
      error.code = error.status
      @onError error
    @meshblu.connect (error) =>
      return @onError error if error?

  _message: (callback) =>
    @meshblu.once 'message', (data) =>
      return callback new Error 'wrong message received' unless data?.payload == @nonce
      callback()

    message =
      devices: [@meshbluConfig.uuid]
      payload: @nonce

    @meshblu.message message

  _register: (callback) =>
    @_connect()
    @meshblu.once 'ready', =>
      @meshblu.register type: 'meshblu:verifier', (@device) =>
        if @device?.error?
          error = new Error @device.error
          error.code = @device.code
          return callback error

        @meshbluConfig.uuid = @device.uuid
        @meshbluConfig.token = @device.token
        @meshblu.close()
        @_connect()
        @meshblu.once 'ready', =>
          callback()

  _update: (callback) =>
    return callback() unless @device?

    params =
      uuid: @meshbluConfig.uuid
      nonce: @nonce

    @meshblu.update params, (data) =>
      return callback new Error data.error if data?.error?
      @meshblu.whoami (data) =>
        return callback new Error 'update failed' unless data?.nonce == @nonce
        callback()

  _unregister: (callback) =>
    return callback() unless @device?
    @meshblu.unregister @device, (data) =>
      return callback new Error data.error if data?.error?
      callback()

  _whoami: (callback) =>
    @meshblu.whoami (data) =>
      return callback new Error data.error if data?.error?
      callback()

module.exports = Verifier
