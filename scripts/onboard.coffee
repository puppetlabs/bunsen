# Description
#    Onboard new users by presenting them with a welcome message and rooms according to their interests.
#
# Commands:
#    welcome - Starts the welcome wizard.
#
# Author:
#   binford2k
#
# Category: workflow

module.exports = (robot) ->

  robot.respond /welcome/i, (msg) ->
    msg.send "Hello there"
    msg.send({
      "text": "Would you like to play a game?",
      "attachments": [
        {
          "text": "Choose a game to play",
          "fallback": "You are unable to choose a game",
          "callback_id": "welcome_wizard",
          "color": "#3AA3E3",
          "attachment_type": "default",
          "actions": [
            {
              "name": "game",
              "text": "Chess",
              "type": "button",
              "value": "chess"
            },
            {
              "name": "game",
              "text": "Falken's Maze",
              "type": "button",
              "value": "maze"
            },
            {
              "name": "game",
              "text": "Thermonuclear War",
              "style": "danger",
              "type": "button",
              "value": "war",
              "confirm": {
                "title": "Are you sure?",
                "text": "Wouldn't you prefer a good game of chess?",
                "ok_text": "Yes",
                "dismiss_text": "No"
              }
            }
          ]
        }
      ]
    })

  robot.setActionHandler 'welcome_wizard', (payload, respond) =>
    robot.logger payload

    return 'Glad you could join us.'
