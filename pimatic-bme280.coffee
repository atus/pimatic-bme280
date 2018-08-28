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

  plugin = new BME280Plugin

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
    _data: null

    constructor: (@config, lastState) ->
      @id = @config.id
      @name = @config.name
      
      @_data = {
        pressure: lastState?.pressure?.value,
        temperature: lastState?.temperature?.value,
        humidity: lastState?.humidity?.value
      }

      BME280 = require 'i2c-bme280'
      @sensor = new BME280({
        address: parseInt @config.address
      });

      Promise.promisifyAll(@sensor)

      super()

      calibrateAndEmitValue = (attributeName, calibrationExpression, value) =>
        variableManager = plugin.framework.variableManager
        info = variableManager.parseVariableExpression(calibrationExpression.replace(/\$value\b/g, value))
        calibratedValue = variableManager.evaluateNumericExpression(info.tokens)
        Promise.resolve(calibratedValue).then((result) =>
          @_data[attributeName] = result
          @emit attributeName, result
        )

      requestValue = () =>
        try
          @sensor.begin((err) =>
            @sensor.readPressureAndTemparature((err, pressure, temperature, humidity) =>
              calibrateAndEmitValue('pressure', @config.pressureCalibration, pressure/100)
              calibrateAndEmitValue('temperature', @config.temperatureCalibration, temperature)
              calibrateAndEmitValue('humidity', @config.humidityCalibration, humidity)
            )
          )
        catch err
          env.logger.error("Error processing sensor data: #{error}")

      requestValue()
      @requestValueIntervalId = setInterval( ( => requestValue() ), @config.interval)
    
    getPressure: -> Promise.resolve(@_data['pressure'])
    getTemperature: -> Promise.resolve(@_data['temperature'])
    getHumidity: -> Promise.resolve(@_data['humidity'])

    destroy: () ->
      clearInterval @requestValueIntervalId if @requestValueIntervalId?
      super()
    
  return plugin
