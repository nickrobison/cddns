open Lwt.Syntax
open Cohttp

let src = Logs.Src.create "source.ipify" ~doc:"IPIfy source"

module Log = (val Logs.src_log src : Logs.LOG)

module Make (C : Cohttp_lwt.S.Client) (T : Mirage_time.S) = struct
  type ctx = C.ctx

  type t = {
    name : string;
    pusher : Lib.Event.t option -> unit;
    refresh : Duration.t;
  }

  type config = {
    refresh : Duration.t; [@of_yojson Lib.Converters.duration_of_yojson]
    ipv4_only : (bool[@default true]); [@name "IPV4only"]
  }
  [@@deriving of_yojson, show]

  let info fmt msg = Log.info (fun m -> m fmt msg)
  let id = "ipify"
  let name t = t.name

  let create name config pusher =
    Log.info (fun m ->
        m "Creating source %s with config: %s" name (show_config config));
    { name; pusher; refresh = config.refresh }

  let request ?ctx () =
    let* resp, body' = C.get ?ctx (Uri.of_string "https://api.ipify.org") in
    Fmt.pr "Response: %d\n" (resp |> Response.status |> Code.code_of_status);
    let* body = body' |> Cohttp_lwt.Body.to_string in
    Fmt.pr "Body: %s\n" body;
    Lwt.return (Ipaddr.V4.of_string body)

  let rec repeat ?ctx push delay =
    let* _ = T.sleep_ns delay in
    let* ipv4 = request ?ctx () in
    match ipv4 with
    | Ok ipv4addr ->
        print_endline "Pushing";
        push (Some (Lib.Event.Init { ipv4addr; ipv6addr = None }));
        repeat ?ctx push delay
    | Error (`Msg m) -> raise (Invalid_argument m)

  let start ?ctx t =
    (* Do an initial fetch on startup*)
    let* resp, body' = C.get ?ctx (Uri.of_string "https://api.ipify.org") in
    Fmt.pr "Response: %d\n" (resp |> Response.status |> Code.code_of_status);
    let* body = body' |> Cohttp_lwt.Body.to_string in
    Fmt.pr "Body: %s\n" body;
    let ipv4 = Ipaddr.V4.of_string body in
    let _ =
      match ipv4 with
      | Ok ipv4addr ->
          print_endline "Pushing";
          t.pusher (Some (Lib.Event.Init { ipv4addr; ipv6addr = None }))
      | Error (`Msg m) -> raise (Invalid_argument m)
    in
    info "Starting scheduled fetch every %d seconds" (Duration.to_sec t.refresh);
    repeat ?ctx t.pusher t.refresh
end
