open Lib
open Cmdliner

let src = Logs.Src.create "cddns"

module Log = (val Logs.src_log src : Logs.LOG)

let _info fmt s = Log.info (fun m -> m fmt s)

let ( let* ) r f =
  match r with Error (`Msg e) -> raise (Invalid_argument e) | Ok o -> f o

let config_path =
  let env =
    let doc = "Overrides path to the config.json file" in
    Cmd.Env.info "CONFIG_FILE" ~doc
  in
  let doc = "Path to the config.json file" in
  Arg.(
    value
    & opt string "./.config.json"
    & info [ "c"; "config" ] ~env ~docv:"CONFIG" ~doc)

let load_cfg file =
  let* path = Fpath.of_string file in
  let* str = Bos.OS.File.read path in
  match Config.of_yojson (Yojson.Safe.from_string str) with
  | Ok c -> c
  | Error e -> raise (Invalid_argument e)

let run cfg_file =
  let config = load_cfg cfg_file in
  Fmt.pr "I have a config named: %s\n" config.source.name;
  let module S = (val Selector.source_of_id config.source.id) in
  let s = S.create config.source.name in
  Fmt.pr "I have named: %s\n" (S.name s)

let cddns_t = Term.(const run $ config_path)

let cmd =
  let doc = "Dynamic DHCP Update Utility" in
  let man = [ `S Manpage.s_bugs ] in
  let info = Cmd.info "cddns" ~version:"%%VERSION%%" ~doc ~man in
  Cmd.v info cddns_t

let main () = exit (Cmd.eval cmd)
let () = main ()
