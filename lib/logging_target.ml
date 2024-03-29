let src = Logs.Src.create "targets.logging" ~doc:"Logging Target"

module Log = (val Logs.src_log src : Logs.LOG)

let info fmt msg = Log.info (fun m -> m fmt msg)

type t = { name : string; stream : Event.t Lwt_stream.t }
type config = unit
type ctx = unit

let config_of_yojson _json = Ok ()
let create _config name stream = { name; stream }
let id = "logging"
let name t = t.name
let log event = Log.info (fun m -> m "Received event: %a" Event.pp event)

let run ?ctx:_ t =
  info "Starting target: %s" t.name;
  Lwt_stream.iter log t.stream
