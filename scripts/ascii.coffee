# Description:
#   ASCII art
#
# Commands:
#   hubot ascii me <text>                     - Show text in ascii art
#   hubot ascii me in <font> <text>           - Specify a font
#   hubot ascii me fonts                      - Big list of fonts

base_url = "http://artii.herokuapp.com"

module.exports = (robot) ->

  robot.respond /ascii( me)?( in)? (.+)/i, (msg) ->
    font_present = msg.match[2]
    sentence = msg.match[3]
    if (font_present)
      font = sentence.substr(0, sentence.indexOf(" "))
      sentence = sentence.substr(sentence.indexOf(" ") + 1)
      msg
        .http("#{base_url}/make")
        .query(text: sentence, font: font)
        .get() (err, res, body) =>
          msg.send "``` #{body}```"
    else if (sentence == "fonts")
      msg
        .http("#{base_url}/fonts_list")
        .get() (err, res, body) ->
          msg.send "```#{body}```"
    else
      msg
        .http("#{base_url}/make")
        .query(text: sentence)
        .get() (err, res, body) =>
          msg.send "``` #{body}```"
