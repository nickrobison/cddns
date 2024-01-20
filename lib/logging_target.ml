let src = Logs.Src.create "targets.logging" ~doc:"Logging Target"

module Log = (val Logs.src_log src : Logs.LOG)

let info fmt msg = Log.info (fun m -> m fmt msg)

type t = { name : string; stream : Event.t Lwt_stream.t }
type config = unit

let config_of_yojson _ = ()
let create _config name stream = { name; stream }
let id = "logging"
let name t = t.name
let log event = info "%s" (Event.show event)

let run t =
  info "Starting target: %s" t.name;
  Lwt_stream.iter log t.stream
