_           = require 'lodash'
commander   = require 'commander'
debug       = require('debug')('meshblu-verifier-socket.io:command')
packageJSON = require './package.json'
Verifier    = require './src/verifier'
MeshbluConfig = require 'meshblu-config'

class Command
  parseOptions: =>
    commander
      .version packageJSON.version
      .parse process.argv

  run: =>
    process.on 'uncaughtException', @die
    @parseOptions()
    timeoutSeconds = 30
    timeoutSeconds = parseInt(process.env.TIMEOUT_SECONDS) if process.env.TIMEOUT_SECONDS
    setTimeout @timeoutAndDie, timeoutSeconds * 1000
    meshbluConfig = new MeshbluConfig().toJSON()
    onError = @die
    verifier = new Verifier {meshbluConfig, onError}
    verifier.verify (error) =>
      @die error if error?
      console.log 'meshblu-verifier-socket.io successful'
      process.exit 0

  die: (error) =>
    return process.exit(0) unless error?
    console.log 'meshblu-verifier-socket.io error'
    console.log "Code: #{error.code}"
    console.error error.stack
    process.exit 1

  timeoutAndDie: =>
    console.log 'meshblu-verifier-socket.io timeout'
    @die new Error 'Timeout Exceeded'

commandWork = new Command()
commandWork.run()
