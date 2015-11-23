shmock = require 'shmock'
Verifier = require '../src/verifier'
MockMeshbluSocketIO = require './mock-meshblu-socket-io'

describe 'Verifier', ->
  beforeEach (done) ->
    @registerHandler = sinon.stub()
    @whoamiHandler = sinon.stub()
    @unregisterHandler = sinon.stub()
    @identityHandler = sinon.spy ->
      @emit 'ready', uuid: 'some-device', token: 'some-token'

    onConnection = (socket) =>
      socket.on 'register', @registerHandler
      socket.on 'whoami', @whoamiHandler
      socket.on 'unregister', @unregisterHandler
      socket.on 'error', (error) ->
        throw error

      socket.on 'identity', @identityHandler
      socket.emit 'identify'

    @meshblu = new MockMeshbluSocketIO port: 0xd00d, onConnection: onConnection
    @meshblu.start done

  afterEach (done) ->
    @meshblu.stop => done()

  describe '-> verify', ->
    context 'when everything works', ->
      beforeEach ->
        meshbluConfig = server: 'localhost', port: 0xd00d

        @registerHandler.yields uuid: 'some-device'
        @whoamiHandler.yields uuid: 'some-device', type: 'meshblu:verifier'
        @unregisterHandler.yields null

        @sut = new Verifier {meshbluConfig}

      beforeEach (done) ->
        @sut.verify (@error) =>
          done @error

      it 'should not error', ->
        expect(@error).not.to.exist
        expect(@registerHandler).to.be.called
        expect(@whoamiHandler).to.be.called
        expect(@unregisterHandler).to.be.called

    context 'when register fails', ->
      beforeEach ->
        meshbluConfig = server: 'localhost', port: 0xd00d
        @sut = new Verifier {meshbluConfig}

      beforeEach (done) ->
        @registerHandler.yields error: 'something wrong'

        @sut.verify (@error) =>
          done()

      it 'should error', ->
        expect(@error).to.exist
        expect(@registerHandler).to.be.called

    context 'when whoami fails', ->
      beforeEach ->
        meshbluConfig = server: 'localhost', port: 0xd00d
        @sut = new Verifier {meshbluConfig}

      beforeEach (done) ->
        @registerHandler.yields uuid: 'some-device'
        @whoamiHandler.yields error: 'something wrong'

        @sut.verify (@error) =>
          done()

      it 'should error', ->
        expect(@error).to.exist
        expect(@registerHandler).to.be.called
        expect(@whoamiHandler).to.be.called

    context 'when unregister fails', ->
      beforeEach ->
        meshbluConfig = server: 'localhost', port: 0xd00d
        @sut = new Verifier {meshbluConfig}

      beforeEach (done) ->
        @registerHandler.yields uuid: 'some-device'
        @whoamiHandler.yields uuid: 'some-device', type: 'meshblu:verifier'
        @unregisterHandler.yields error: 'something wrong'

        @sut.verify (@error) =>
          done()

      it 'should error', ->
        expect(@error).to.exist
        expect(@registerHandler).to.be.called
        expect(@whoamiHandler).to.be.called
        expect(@unregisterHandler).to.be.called
