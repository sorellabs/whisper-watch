## Module whisper-watch
#
# Watches for certain events and runs tasks based on them!
#
# 
# Copyright (c) 2013 Quildreen "Sorella" Motta <quildreen@gmail.com>
# 
# Permission is hereby granted, free of charge, to any person
# obtaining a copy of this software and associated documentation files
# (the "Software"), to deal in the Software without restriction,
# including without limitation the rights to use, copy, modify, merge,
# publish, distribute, sublicense, and/or sell copies of the Software,
# and to permit persons to whom the Software is furnished to do so,
# subject to the following conditions:
# 
# The above copyright notice and this permission notice shall be
# included in all copies or substantial portions of the Software.
# 
# THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND,
# EXPRESS OR IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF
# MERCHANTABILITY, FITNESS FOR A PARTICULAR PURPOSE AND
# NONINFRINGEMENT. IN NO EVENT SHALL THE AUTHORS OR COPYRIGHT HOLDERS BE
# LIABLE FOR ANY CLAIM, DAMAGES OR OTHER LIABILITY, WHETHER IN AN ACTION
# OF CONTRACT, TORT OR OTHERWISE, ARISING FROM, OUT OF OR IN CONNECTION
# WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE SOFTWARE.

module.exports = (whisper) ->

  ### -- Dependencies --------------------------------------------------
  fs       = require 'fs'
  path     = require 'path'
  glob     = (require 'glob').sync
  chokidar = require 'chokidar'
  
  {each, unique, concat-map} = require 'prelude-ls'
  

  ### -- Helpers -------------------------------------------------------

  #### λ expand
  # Returns a list of files that match a list of glob patterns.
  #
  # :: [String] -> [String]
  expand = (xs or []) -> (unique . (concat-map glob)) xs
  
  ### -- Notifications -------------------------------------------------
  notify-addition = -> whisper.log.info "#it was added."
  notify-deletion = -> whisper.log.info "#it was deleted."
  notify-change   = -> whisper.log.info "#it was modified."


  ### -- File events ---------------------------------------------------

  #### λ file-event-p
  # Checks if an event is a file event.
  #
  # :: Event -> Bool
  file-event-p = (event) ->
    /^file($|:(?:added|deleted|changed)+)/.test event.type
  

  #### λ setup-file-event
  # Setups the file watchers for invoking tasks for file events.
  #
  # :: Environment -> Event -> ()
  setup-file-event = (env, event) -->
    invoke = -> event.tasks.for-each (invoke-task env)

    whisper.log.info "Watching for #{event.type} events on #{event.files}."

    watcher = chokidar.watch (expand event.files), do
                                                   persistent     : true
                                                   ignore-initial : true

    switch event.type
    | \file 'file:added'   => watcher.on 'add' (invoke . notify-addition)
    | \file 'file:deleted' => watcher.on 'unlink' (invoke . notify-deletion)
    | \file 'file:changed' => watcher.on 'change' (invoke . notify-change)

    watcher.on 'error' -> whisper.log.error "Error: #it"


  ### -- Task resolution and running -----------------------------------

  #### λ resolve
  # Resolves the task from a name to a Task object.
  #
  # :: String -> Task  
  resolve = (name) ->
    try
      whisper.resolve name
    catch e
      switch e.name
      | '<inexistent-task-e>' => whisper.log.fatal "The task \"#name\" is not registered."


  #### λ invoke-task
  # Invokes a task by its name.
  #
  # :: Environment -> String -> ()
  invoke-task = (env, name) -->
    whisper.log.info "Running task #name."
    task = (resolve name)
    task._executed = false
    task.execute env    
      

  ### -- Regular events ------------------------------------------------
  
  #### λ setup-regular-event
  # Setups a watcher for a regular Ekho event.
  #
  # :: Environment -> Event -> ()
  setup-regular-event = (env, event) ->
    whisper.log.info "Watching for #{event.type} events."
    whisper.on event.type, (ev) -> do
                                   event.tasks.for-each (invoke-task env)


  ### -- Dispatchers ---------------------------------------------------

  #### λ watch-event
  # Setups watchers for the given event.
  #
  # :: Environment -> Event -> ()
  watch-event = (env, event) -->
    switch
    | file-event-p event => setup-file-event env, event
    | otherwise          => setup-regular-event env, event
    

  #### λ start-watching
  # Setups watchers for all events.
  #
  # :: Environment -> [Event] -> ()
  start-watching = (env, events) --> each (watch-event env), events
    



  ### -- Tasks ---------------------------------------------------------
  whisper.task 'watch'
             , []
             , """Runs tasks in response to system events.

               This task allows you to run other tasks in response to
               some system event. These can be some change on the file
               system, or some event published by another Whisper task.

               You specify which kinds of events you're interested on,
               and what tasks should be ran when they happen. The
               configuration should conform to the following structure:

               
                   type Watch : { String -> WatchEvent }

                   type WatchEvent {
                     type  : String
                     tasks : [Task]
                   }

                   type WatchEvent <| FileEvent {
                     files : [Pattern]
                   }


               File events can be any of:

                - `file:added`: A new file has been created.
                - `file:deleted`: Some file has been deleted.
                - `file:changed`: The contents of some file changed.
                - `file`: Any of the above.

               ## Example
              
               Recompiling your files with Browserify everytime the
               source changes:
              
              
                   module.exports = function(whisper) {
                     whisper.configure({
                       watch: {
                         bundle: { type : 'file'
                                 , files: ['src/*.js']
                                 , tasks: ['browserify']
                                 }
                       }
                     })
                   }
               """
             , (env) -> start-watching env, env.watch
