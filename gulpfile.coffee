fs = require('fs')

tasks = fs.readdirSync('./gulp/')
tasks.forEach (task) ->
  if task.slice(-7) != '.coffee' then return
  require './gulp/' + task