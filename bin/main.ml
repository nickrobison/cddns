open Lib
open Cmdliner

let src = Logs.Src.create "cddns"

module Log = (val Logs.src_log src : Logs.LOG)

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

let create_target stream (target_json : Config.target) =
  Log.info (fun m ->
      m "Creating target type: %s with name: %s" target_json.id target_json.name);
  let module T = (val Selector.target_of_id target_json.id) in
  let config = T.config_of_yojson target_json.config in
  match config with
  | Ok c ->
      let target = T.create c target_json.name stream in
      T.run target
  | Error e -> failwith e

let run cfg_file _logs =
  let config = load_cfg cfg_file in
  (* Create the event stream*)
  let stream, push = Lwt_stream.create () in
  let module S = (val Selector.source_of_id config.source.id) in
  let src_config =
    match S.config_of_yojson config.source.config with
    | Ok c -> c
    | Error e -> raise (Invalid_argument e)
  in
  (* Create the source *)
  let s = S.create config.source.name src_config push in
  let create_target' = create_target stream in
  (* Create the targets *)
  let running_targets = List.map create_target' config.targets in
  (* Await for everything*)
  let d = Lwt.all (running_targets @ [ S.start s ]) in
  let _ = Lwt_main.run d in
  ()

let logs = Logging.setup ()
let cddns_t = Term.(const run $ config_path $ logs)

let cmd =
  let doc = "Dynamic IP Address Update Utility" in
  let man = [ `S Manpage.s_bugs ] in
  let info = Cmd.info "cddns" ~version:"%%VERSION%%" ~doc ~man in
  Cmd.v info cddns_t

let main () = exit (Cmd.eval cmd)
let () = main ()
