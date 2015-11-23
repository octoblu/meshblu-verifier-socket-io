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
    @parseOptions()
    meshbluConfig = new MeshbluConfig().toJSON()
    onError = @die
    verifier = new Verifier {meshbluConfig, onError}
    verifier.verify (error) =>
      @die error if error?
      console.log 'meshblu-verifier-socket.io successful'

  die: (error) =>
    return process.exit(0) unless error?
    console.log 'meshblu-verifier-socket.io error'
    console.error error.stack
    process.exit 1

commandWork = new Command()
commandWork.run()
