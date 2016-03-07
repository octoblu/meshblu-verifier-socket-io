shmock = require 'shmock'
Verifier = require '../src/verifier'
MockMeshbluSocketIO = require './mock-meshblu-socket-io'

describe 'Verifier', ->
  beforeEach (done) ->
    @nonce = Date.now()
    @registerHandler = sinon.stub()
    @whoamiHandler = sinon.stub()
    @updateHandler = sinon.stub()
    @unregisterHandler = sinon.stub()
    @identityHandler = sinon.spy ->
      @emit 'ready', uuid: 'some-device', token: 'some-token'

    onConnection = (socket) =>
      socket.on 'register', @registerHandler
      socket.on 'whoami', @whoamiHandler
      socket.on 'update', @updateHandler
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
    beforeEach ->
      meshbluConfig = server: 'localhost', port: 0xd00d
      @sut = new Verifier {meshbluConfig, @nonce}

    context 'when everything works', ->
      beforeEach ->
        @registerHandler.yields uuid: 'some-device'
        @whoamiHandler.yields uuid: 'some-device', type: 'meshblu:verifier'
        @updateHandler.yields null
        @whoamiHandler.yields uuid: 'some-device', type: 'meshblu:verifier', nonce: @nonce
        @unregisterHandler.yields null

      beforeEach (done) ->
        @sut.verify (@error) =>
          done @error

      it 'should not error', ->
        expect(@error).not.to.exist
        expect(@registerHandler).to.be.called
        expect(@whoamiHandler).to.be.called
        expect(@updateHandler).to.be.called
        expect(@unregisterHandler).to.be.called

    context 'when register fails', ->
      beforeEach (done) ->
        @registerHandler.yields error: 'something wrong'

        @sut.verify (@error) =>
          done()

      it 'should error', ->
        expect(@error).to.exist
        expect(@registerHandler).to.be.called

    context 'when whoami fails', ->
      beforeEach (done) ->
        @registerHandler.yields uuid: 'some-device'
        @whoamiHandler.yields error: 'something wrong'

        @sut.verify (@error) =>
          done()

      it 'should error', ->
        expect(@error).to.exist
        expect(@registerHandler).to.be.called
        expect(@whoamiHandler).to.be.called

    context 'when update fails', ->
      beforeEach (done) ->
        @registerHandler.yields uuid: 'some-device'
        @whoamiHandler.yields uuid: 'some-device', type: 'meshblu:verifier'
        @updateHandler.yields error: 'something wrong'

        @sut.verify (@error) =>
          done()

      it 'should error', ->
        expect(@error).to.exist
        expect(@registerHandler).to.be.called
        expect(@whoamiHandler).to.be.called
        expect(@updateHandler).to.be.called

    context 'when unregister fails', ->
      beforeEach (done) ->
        @registerHandler.yields uuid: 'some-device'
        @whoamiHandler.yields uuid: 'some-device', type: 'meshblu:verifier'
        @updateHandler.yields null
        @whoamiHandler.yields uuid: 'some-device', type: 'meshblu:verifier', nonce: @nonce
        @unregisterHandler.yields error: 'something wrong'

        @sut.verify (@error) =>
          done()

      it 'should error', ->
        expect(@error).to.exist
        expect(@registerHandler).to.be.called
        expect(@whoamiHandler).to.be.called
        expect(@updateHandler).to.be.called
        expect(@unregisterHandler).to.be.called
