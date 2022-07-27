# Description:
#   Track arbitrary karma
#
# Dependencies:
#   None
#
# Configuration:
#   None
#
# Commands:
#   <thing>++ - give thing some karma
#   <thing>-- - take away some of thing's karma
#   hubot karma <thing> - check thing's karma (if <thing> is omitted, show the top 5)
#   hubot karma empty <thing> - empty a thing's karma
#   hubot karma best - show the top 5
#   hubot karma worst - show the bottom 5
#
# Author:
#   stuartf, branan, nlew, samwoods, stahnma
#
# Category: social

blacklist = [
  /^(lib)?stdc$/
  /-{2,}/
  /^[rwx-]+$/
]

class Karma

  constructor: (@robot) ->
    @cache = {}

    @increment_responses = [
      "+1!", "gained a level!", "is on the rise!", "leveled up!"
    ]

    @decrement_responses = [
      "took a hit! Ouch.", "took a dive.", "lost a life.", "lost a level."
    ]

    @self_responses = [
      "Nice try %name.", "I don't think so, %name.", "Hey everyone! Did you see what %name tried to do?"
    ]


    @userForMentionName = (name) ->
      name = normalizeSubject(name)
      lowerName = name.toLowerCase()

      for k of (@robot.brain.data.users or { })
        mentionName = @robot.brain.data.users[k].slack.profile.display_name
        if mentionName? and mentionName.toLowerCase() is lowerName
          result = @robot.brain.data.users[k]
          return result
      return null

    @mentionName = (subject) ->

    @robot.brain.on 'loaded', =>
      if @robot.brain.data.karma
        @cache = @robot.brain.data.karma

  kill: (thing) ->
    delete @cache[thing]
    @robot.brain.data.karma = @cache

  increment: (thing) ->
    @cache[thing] ?= 0
    @cache[thing] += 1
    @robot.brain.data.karma = @cache

  decrement: (thing) ->
    @cache[thing] ?= 0
    @cache[thing] -= 1
    @robot.brain.data.karma = @cache

  incrementResponse: ->
     @increment_responses[Math.floor(Math.random() * @increment_responses.length)]

  decrementResponse: ->
     @decrement_responses[Math.floor(Math.random() * @decrement_responses.length)]

  selfResponse: ->
     @self_responses[Math.floor(Math.random() * @self_responses.length)]



  get: (thing) ->
    k = if @cache[thing] then @cache[thing] else 0
    if thing == "e"
      k = k + 2.71828
    return k

  sort: ->
    s = []
    for key, val of @cache
      s.push({ name: key, karma: val })
    s.sort (a, b) -> b.karma - a.karma

  top: (n = 5) ->
    sorted = @sort()
    sorted.slice(0, n)

  bottom: (n = 5) ->
    sorted = @sort()
    sorted.slice(-n).reverse()

mention_name = (robot, user) ->
  robot.brain.data.users[user.id].slack.profile.display_name

filtered = (subject) ->
    blacklist.some (re) ->
      subject.match re

normalizeSubject = (subject) ->
  if subject.indexOf('@') == 0
    normalizeSubject subject[1..-1]
  else
    subject.trim()

self_karma = (msg, subject) ->
  if msg.robot.adapterName == "slack"
    # demeter I apologize
    user = mention_name(msg.robot, msg.message.user).toLowerCase()
  else
    user = "shell"
  if user == subject
    true

sub_response = (text, msg) ->
  text.replace('%name', mention_name(msg.robot, msg.message.user)).replace('%room', msg.message.room)

increment_or_decrement_karma = (msg, karma, matches, increment_bool) ->
  unique_matches = new Set
  messages = []
  for match in matches
    m = match[4] || match[5] || match[6] || match[7] || match[11] || match[12] || match[13] || match[14]
    subject = normalizeSubject m.toLowerCase()
    if unique_matches.has(subject)
      continue
    unique_matches.add(subject)
    if !filtered(subject)
      if !self_karma(msg, subject)
        if increment_bool
          karma.increment subject
          messages.push "#{subject} #{karma.incrementResponse()} (Karma: #{karma.get(subject)})"
        else
          karma.decrement subject
          messages.push "#{subject} #{karma.decrementResponse()} (Karma: #{karma.get(subject)})"
      else
        messages.push(sub_response(karma.selfResponse(), msg))
  msg.send messages.join("\n")

module.exports = (robot) ->
  karma = new Karma robot

  # match on any message including (inc item), (dec item), item++ or item--
  robot.hear /(\((inc|dec)\s+\S.*\)(\s|$)|(\S|\s)(--|\+\+)(\s|$))/, (msg) ->
    # Positive karma
    pos_matches = []
    pos_grouped_regex = ///
      (                               # Group 1.
        (                             # Group 2.
          (                           # Group 3.
            @(\S+[^+:\s])\s           # Group 4. Someone's name followed by a space
            |(\S+[^+:\s])             # Group 5. A single word not followed by a space, :, or +
            |\(([^\(\)]+\W[^\(\)]+)\) # Group 6. A parenthetic multi-word phrase
            |(:[^:\s]+:)\s?           # Group 7. A single word between colons, optionally followed by a space
          )                           #
          \+\+                        # ++ for karma
          (\s|[!-~]|$)                # Group 8. A space or punctuation or end of line
        )|                            #
        (\(inc\s+                     # Group 9. inc for karma
          (                           # Group 10.
            @(\S+[^+:\s])\s           # Group 11. Someone's name followed by a space
            |(\S+[^+:\s])             # Group 12. A single word not followed by a space, :, or +
            |\(([^\(\)]+\W[^\(\)]+)\) # Group 13. A parenthetic multi-word phrase
            |(:[^:\s]+:)\s?           # Group 14. A single word between colons, optionally followed by a space
          )                           #
          (\s*\))                     # Group 15. Closing paren
        )
      )
    ///g

    while (pos_match = pos_grouped_regex.exec(msg.message))
      pos_matches.push(pos_match)

    increment_or_decrement_karma(msg, karma, pos_matches, true)

    # Negative karma
    neg_matches = []
    neg_grouped_regex = ///
      (                               # Group 1.
        (                             # Group 2.
          \w                          # Don't match a name on the previous line (fixes code blocks)
          (                           # Group 3.
            @(\S+[^+:\s])\s           # Group 4. Someone's name followed by a space
            |(\S+[^+:\s])             # Group 5. A single word not followed by a space, :, or +
            |\(([^\(\)]+\W[^\(\)]+)\) # Group 6. A parenthetic multi-word phrase
            |(:[^:\s]+:)\s?           # Group 7. A single word between colons, optionally followed by a space
          )                           #
          --                          # -- for karma
          (\s|[!-~]|$)                # Group 8. A space or punctuation, or end of line
        )|                            #
        (\(dec\s+                     # Group 9. dec for karma
          (                           # Group 10.
            @(\S+[^+:\s])\s           # Group 11. Someone's name followed by a space
            |(\S+[^+:\s])             # Group 12. A single word not followed by a space, :, or +
            |\(([^\(\)]+\W[^\(\)]+)\) # Group 13. A parenthetic multi-word phrase
            |(:[^:\s]+:)\s?           # Group 14. A single word between colons, optionally followed by a space
          )                           #
          (\s*\))                     # Group 15. Closing paren
        )
      )
    ///g

    while (neg_match = neg_grouped_regex.exec(msg.message))
      neg_matches.push(neg_match)

    increment_or_decrement_karma(msg, karma, neg_matches, false)

  robot.respond /karma empty ([\s\S]+)$/i, (msg) ->
    subject = msg.match[1].toLowerCase()
    # Don't kill karma if 'empty *' has karma. Use 'empty empty *'
    if karma.get("empty #{subject}") == 0
      # If you're attempting to nuke somebody's karma, hell to pay.
      # This only works when the user who attempted the action is known
      if karma.userForMentionName(subject) and msg.envelope.room.toLowerCase() != "shell"
        # find karma for subject.
        current_karma = karma.get(subject)
        # find karma for requestor.
        requester = normalizeSubject mention_name(msg.robot, msg.message.user).toLowerCase()
        # Append requester's karma to subject.
        robot.brain.data.karma[subject] += karma.get(requester)
        # Emtpry requesters karma.
        robot.brain.data.karma[requester] = 1
        msg.reply "Instant karma. Now #{subject} has all of your karma and your karma is reset."
        robot.brain.save();
      else
        current_karma = karma.get(subject)
        karma.kill subject
        msg.send "#{subject} has had all #{current_karma} of its karma scattered to the winds."

  robot.respond /karma( best)?$/i, (msg) ->
    verbiage = ["The Best"]
    for item, rank in karma.top()
      verbiage.push "#{rank + 1}. #{item.name} - #{item.karma}"
    msg.send verbiage.join("\n")

  robot.respond /karma worst$/i, (msg) ->
    verbiage = ["The Worst"]
    for item, rank in karma.bottom()
      verbiage.push "#{rank + 1}. #{item.name} - #{item.karma}"
    msg.send verbiage.join("\n")

  robot.respond /karma (.+)$/i, (msg) ->
    match = msg.match[1].toLowerCase()
    if match != "best" && match != "worst" && !  /empty/.test(match)
      msg.send "\"#{match}\" has #{karma.get(match)} karma."
