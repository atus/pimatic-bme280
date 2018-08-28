#pimatic-bme280 configuration options
module.exports = {
  title: "pimatic-bme280 config"
  BME280Sensor: {
    title: "BME280Sensor config options"
    type: "object"
    extensions: ["xLink","xAttributeOptions"]
    properties: {
      device:
        description: "Device file to use; default /dev/i2c-1"
        type: "string"
        default: "i2c-1"
      address:
        description: "Address to use; default 0x76"
        type: "string"
        default: "0x76"
      interval:
        description: "Interval in ms"
        type: "integer"
        default: "10000"
      pressureCalibration:
        description: "Expression for calibrating the sensor value; $value is a placeholder for the value itself."
        type: "string"
        default: "$value"
      temperatureCalibration:
        description: "Expression for calibrating the sensor value; $value is a placeholder for the value itself."
        type: "string"
        default: "$value"
      humidityCalibration:
        description: "Expression for calibrating the sensor value; $value is a placeholder for the value itself."
        type: "string"
        default: "$value"
    }
  }
}
