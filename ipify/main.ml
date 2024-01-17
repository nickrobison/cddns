let src = Logs.Src.create "sources.ipify" ~doc:"Ipify IP Address Source"

module Log = (val Logs.src_log src : Logs.LOG)

module Ipify_source = struct
  type t = { name : string }

  let id = "ipify"
  let name t = t.name
  let start _t _stream = Lwt.return_unit
  let create name = { name }
end

let () =
  print_endline "Register!";
  Lib.Source.register (module Ipify_source) Ipify_source.id
