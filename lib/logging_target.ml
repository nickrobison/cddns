let src = Logs.Src.create "targets.logging" ~doc:"Logging Target"

module Log = (val Logs.src_log src : Logs.LOG)

let info fmt msg = Log.info (fun m -> m fmt msg)

type t = { name : string; stream : Event.t Lwt_stream.t }
type config = unit

let config_of_yojson _ = ()

let create _config name stream =
  print_endline "Creating";
  { name; stream }

let id = "logging"
let name t = t.name

let log _event =
  print_endline "Event!";
  info "Received event %s" "hello"

let run t =
  print_endline "Running Target";
  Lwt_stream.iter log t.stream
