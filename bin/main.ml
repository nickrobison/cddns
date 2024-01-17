open Lib

let src = Logs.Src.create "cddns"

module Log = (val Logs.src_log src : Logs.LOG)

let _info fmt s = Log.info (fun m -> m fmt s)

let run () =
  let sources = Hashtbl.to_seq_values Source.sources in
  let ids = Seq.map (fun (module S : Source.S) -> S.id) sources in
  Seq.iter (fun id -> print_endline id) ids

let () =
  print_endline "Hello";
  run ()
