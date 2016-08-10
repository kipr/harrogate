var AppCatalog, TargetApp, create_terminal_emulator, events, spawn, terminal_emulator, terminal_on_connection;

spawn = require('child_process').spawn;

AppCatalog = require_harrogate_module('/shared/scripts/app-catalog.js');

TargetApp = AppCatalog.catalog['Target information'].get_instance();

events = AppCatalog.catalog['Terminal'].event_groups.terminal_events.events;

terminal_emulator = void 0;

if (TargetApp.platform === TargetApp.supported_platforms.WINDOWS_PC) {
  terminal_emulator = 'cmd';
} else {
  terminal_emulator = 'sh';
}

create_terminal_emulator = function(socket) {
  var process;
  if (terminal_emulator != null) {
    process = spawn(terminal_emulator);
    process.stdout.on('data', function(data) {
      socket.emit(events.stdout.id, data.toString('utf8'));
    });
    process.stderr.on('data', function(data) {
      socket.emit(events.stderr.id, data.toString('utf8'));
    });
    process.on('exit', function(code) {
      socket.disconnect();
    });
    return process;
  }
  return void 0;
};

terminal_on_connection = function(socket) {
  var process;
  process = create_terminal_emulator(socket);
  socket.on(events.stdin.id, function(data) {
    process.stdin.write(data + '\n');
  });
  socket.on(events.restart.id, function(data) {
    process = create_terminal_emulator(socket);
  });
};

module.exports = {
  event_init: function(event_group_name, namespace) {
    namespace.on('connection', terminal_on_connection);
  },
  exec: function() {}
};
