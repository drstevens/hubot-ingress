# Description
#   Ingress helper commands for Hubot
#
# Dependencies:
#   None
#
# Configuration:
#   HUBOT_GOOGLE_GEOCODE_KEY (optional, may be needed if no results are returned)
#
# Commands:
#   hubot intelmap for <search>

module.exports = (robot) ->
  # Setting this on robot so that it can be overridden in test. Is there a better way?
  robot.googleGeocodeKey = process.env.HUBOT_GOOGLE_GEOCODE_KEY
  googleGeocodeUrl = 'https://maps.googleapis.com/maps/api/geocode/json'

  lookupLatLong = (msg, location, cb) ->
    params =
      address: location
    params.key = robot.googleGeocodeKey if robot.googleGeocodeKey?

    msg.http(googleGeocodeUrl).query(params)
      .get() (err, res, body) ->
        try
          body = JSON.parse body
          results = body.results.slice(0,2).map (r) -> 
            name: r.formatted_address
            coords: r.geometry.location
          if results.length < 1
            err = "Could not find #{location}"
            return cb(err, msg, null)
          else 
            cb(err, msg, results)
        catch err
          err = "Could not find #{location}"
          return cb(err, msg, null)
        

  intelmapUrl = (result) ->
    return result.name + "\nhttps://www.ingress.com/intel?ll=" + encodeURIComponent(result.coords.lat) + "," + encodeURIComponent(result.coords.lng) + "&z=16"
  sendIntelLinks = (err, msg, results) ->
    return msg.send err if err or results.length < 1
    urls = (intelmapUrl c for c in results).reduce (l, r) -> l + "\n" + r
    msg.send urls

  robot.respond /(intelmap|intel map)(?: for)?\s(.*)/i, (msg) ->
    location = msg.match[2]
    lookupLatLong msg, location, sendIntelLinks
