# Description
#    Bot administration utilities.
#
# Commands:
#    restart - just kills the bot process so that k8s can recycle a new one (admin only)
#
# URLS:
#    GET /status - Status check used for k8s readiness probe
#
# Author:
#   binford2k
#
# Category: workflow

module.exports = (robot) ->

  robot.respond /restart/i, (msg) ->
    if(msg.message.user.slack.is_admin != true)
      msg.send('You shall not pass! Only Slack admins can use this command. :closed_lock_with_key:')
    else
      robot.brain.save();
      robot.adapter.client.web.reactions.add('stopwatch', {channel: msg.message.room, timestamp: msg.message.id})
      robot.logger.warning "Restart triggered by #{msg.message.user.slack.real_name} (@#{msg.message.user.slack.name})"

      #Exit the process (Relies on a process monitor to restart)
      process.exit 0

  robot.router.get '/status', (req, res) ->
    robot.logger.debug "Status check"
    res.send 'Ok'
