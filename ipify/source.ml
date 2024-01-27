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
  let error fmt msg = Log.err (fun m -> m fmt msg)
  let id = "ipify"
  let name t = t.name

  let create name config pusher =
    Log.info (fun m ->
        m "Creating source %s with config: %s" name (show_config config));
    { name; pusher; refresh = config.refresh }

  let request ?ctx () =
    let* resp, body' = C.get ?ctx (Uri.of_string "https://api.ipify.org") in
    let response_code = resp |> Response.status |> Code.code_of_status in
    match Code.is_success response_code with
    | false -> Lwt.return_error (`Source_failure "Failed!")
    | true ->
        Fmt.pr "Response: %d\n" (resp |> Response.status |> Code.code_of_status);
        let* body = body' |> Cohttp_lwt.Body.to_string in
        Fmt.pr "Body: %s\n" body;
        Lwt.return (Ipaddr.V4.of_string body)

  let rec repeat ?ctx push delay previous =
    let* _ = T.sleep_ns delay in
    let* ipv4 = request ?ctx () in
    match (ipv4, previous) with
    | Ok ipv4addr, None ->
        let (r : Lib.Record.t) = { ipv4addr; ipv6addr = None } in
        push (Some (Lib.Event.Init r));
        repeat ?ctx push delay (Some r)
    | Ok ipv4addr, Some prev ->
        let (r : Lib.Record.t) = { ipv4addr; ipv6addr = None } in
        if not (Lib.Record.equal prev r) then
          push (Some (Lib.Event.Update (prev, r)))
        else info "%s" "IP address unchanged, ignoring";
        repeat ?ctx push delay (Some r)
    | Error (`Msg m), _ ->
        error "Source request failed with: %s. Retrying" m;
        repeat ?ctx push delay None
    | Error (`Source_failure m), _ ->
        error "Source request failed with: %s. Retrying" m;
        repeat ?ctx push delay None

  let start ?ctx t =
    (* Do an initial fetch on startup*)
    let* _resp, body' = C.get ?ctx (Uri.of_string "https://api.ipify.org") in
    let* body = body' |> Cohttp_lwt.Body.to_string in
    let ipv4 = Ipaddr.V4.of_string body in
    let prev =
      match ipv4 with
      | Ok ipv4addr ->
          let (r : Lib.Record.t) = { ipv4addr; ipv6addr = None } in
          t.pusher (Some (Lib.Event.Init r));
          Some r
      | Error (`Msg m) ->
          t.pusher (Some (Lib.Event.Failure m));
          None
    in
    info "Starting scheduled fetch every %d seconds" (Duration.to_sec t.refresh);
    repeat ?ctx t.pusher t.refresh prev
end
