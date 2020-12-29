# Description:
#   None
#
# Dependencies:
#   "clark": "0.0.5"
#
# Configuration:
#   None
#
# Commands:
#   hubot clark <data> - build sparklines out of data
#
# Author:
#   ajacksified
#
# Category: social

clark = require 'clark'

module.exports = (robot) ->
  robot.respond /(?:clark|sparkline) (.*)/i, (msg) ->
    data = msg.match[1].trim().split(' ')
    msg.send(clark(data))

  robot.hear /sparkline (.*)/i, (msg) ->
    data = msg.match[1].trim().split(' ')
    msg.send(clark(data))
