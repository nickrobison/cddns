open Lib
open Lwt.Syntax

let src =
  Logs.Src.create "targets.cloudflare_dns"
    ~doc:"Target for updating Cloudflare DNS records"

module Log = (val Logs.src_log src : Logs.LOG)

module Make (C : Client_intf.S) = struct
  let info fmt msg = Log.info (fun m -> m fmt msg)
  let error fmt msg = Log.err (fun m -> m fmt msg)

  type config = { api_key : string; zone_name : string }
  [@@deriving show, of_yojson]

  type t = { name : string; stream : Event.t Lwt_stream.t; config : config }
  type ctx = C.ctx

  let do_get ?ctx uri parser =
    let* r' = C.get ?ctx uri parser in
    match r' with
    | Ok resp -> Lwt.return_ok resp
    | Error e -> Lwt.return_error e

  let get_zone ?ctx () =
    let* r' = do_get ?ctx "" Zone_response.of_string in
    match r' with
    | Ok resp ->
        let rcd = List.hd resp.result in
        info "Received zone record: %s" (Zone_response.show_zone_record rcd);
        Lwt.return_some rcd.id
    | Error _e ->
        error "Failed to retrieve zone: %s" "Badddd";
        Lwt.return_none

  let get_record ?ctx () =
    let* r' = do_get ?ctx "" Record_response.of_string in
    match r' with
    | Ok resp ->
        let rcd = List.hd resp.result in
        info "Received zone record: %s" (Record_response.show_dns_record rcd);
        Lwt.return_some rcd.id
    | Error _e ->
        error "Failed to retrieve zone: %s" "baaad";
        Lwt.return_none

  let id = "cloudflare_dns"
  let name t = t.name
  let create config name stream = { name; stream; config }
  let log event = info "%s" (Event.show event)
  let record = ref None

  let do_update ?ctx update =
    let req = Record_update.of_record "Test" update in
    let* updated =
      C.put ?ctx (Uri.of_string "http://test.com") Record_update.to_string req
    in
    match updated with
    | Ok _ -> Lwt.return_unit
    | Error _ -> failwith "I received an error"

  let handle_update ?ctx update =
    log update;
    match !record with
    | Some _r -> (
        match update with
        | Update (_old, new') -> do_update ?ctx new'
        | _ -> Lwt.return_unit)
    | None -> (
        info "Looking up zone: %s" "";
        let* zone = get_zone ?ctx () in
        match zone with
        | None -> failwith "Cannont find zone"
        | Some z ->
            info "Retrieving DNS records for zone: %s" (Zone_id.to_string z);
            let* record' = get_record ?ctx () in
            record := record';
            Lwt.return_unit)

  let run ?ctx t =
    Log.info (fun m ->
        m "Starting target %s with config: %s" t.name (show_config t.config));
    Lwt_stream.iter_s (handle_update ?ctx) t.stream
end
