# Whisper: Watch [![Build Status](https://travis-ci.org/killdream/whisper-watch.png)](https://travis-ci.org/killdream/whisper-watch)

Watches for certain events and runs tasks based on them!


### Example

Define watch scripts in your `.whisper` file:

```js
module.exports = function(whisper) {
  whisper.configure({
    watch: {
      js: { type: 'file'
          , files: ['src/src/']
          , tasks: ['coffee-script']
          }
    }
  })
  
  require('whisper-watch')(whisper)
}
```

And invoke the `whisper watch` task on your project to watch for events:

```bash
$ whisper watch
```

### Installing

Just grab it from NPM:

    $ npm install whisper-watch


### Documentation

Just invoke `whisper help watch` to show the manual page for the `watch` task.


### Licence

MIT/X11. ie.: do whatever you want.

[Calliope]: https://github.com/killdream/calliope
[es5-shim]: https://github.com/kriskowal/es5-shim
