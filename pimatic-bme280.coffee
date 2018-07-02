module.exports = (env) ->
  Promise = env.require 'bluebird'

  declapi = env.require 'decl-api'
  t = declapi.types

  class BME280Plugin extends env.plugins.Plugin
    init: (app, @framework, @config) =>
      deviceConfigDef = require("./device-config-schema")

      @framework.deviceManager.registerDeviceClass("BME280Sensor", {
        configDef: deviceConfigDef.BME280Sensor,
        createCallback:(config, lastState) =>
          device = new BME280Sensor(config, lastState)
          return device
      })


  class PressureSensor extends env.devices.Sensor
    attributes:
      pressure:
        description: "Barometric pressure"
        type: t.number
        unit: 'hPa'
        acronym: 'ATM'
      temperature:
        description: "Temperature"
        type: t.number
        unit: '°C'
        acronym: 'T'
      humidity:
        description: "Humidity"
        type: t.number
        unit: '%'
        acronym: 'RH'

    template: "temperature"   


  class BME280Sensor extends PressureSensor
    _pressure: null
    _temperature: null
    _humidity: null

    constructor: (@config, lastState) ->
      @id = @config.id
      @name = @config.name
      @_pressure = lastState?.pressure?.value
      @_temperature = lastState?.temperature?.value
      @_humidity = lastState?.humidity?.value

      BME280 = require 'i2c-bme280'
      @sensor = new BME280({
        address: parseInt @config.address
      });

      Promise.promisifyAll(@sensor)

      super()

      @requestValue()
      @requestValueIntervalId = setInterval( ( => @requestValue() ), @config.interval)
    
    destroy: () ->
      clearInterval @requestValueIntervalId if @requestValueIntervalId?
      super()

    requestValue: ->
      @sensor.begin((err) =>
        @sensor.readPressureAndTemparature( (err, pressure, temperature, humidity) =>
          @_pressure = pressure/100
          @emit 'pressure', pressure/100
      
          @_temperature = temperature
          @emit 'temperature', temperature

          @_humidity = humidity
          @emit 'humidity', humidity
        )
    )
    getPressure: -> Promise.resolve(@_pressure)
    getTemperature: -> Promise.resolve(@_temperature)
    getHumidity: -> Promise.resolve(@_humidity)

  myPlugin = new BME280Plugin
  return myPlugin
