open Lib
open Lwt.Syntax

let src =
  Logs.Src.create "targets.cloudflare_dns"
    ~doc:"Target for updating Cloudflare DNS records"

module Log = (val Logs.src_log src : Logs.LOG)

module Make (C : Client_intf.S) = struct
  let error fmt msg = Log.err (fun m -> m fmt msg)
  let debug fmt msg = Log.debug (fun m -> m fmt msg)
  let base_url = Uri.of_string "https://api.cloudflare.com/client/v4"

  type config = {
    api_key : string; [@opaque]
    zone_name : string;
    account_id : Account_id.t;
    record_name : string;
  }
  [@@deriving show, of_yojson]

  type t = {
    name : string;
    stream : Event.t Lwt_stream.t;
    config : config;
    headers : Cohttp.Header.t;
  }

  type ctx = C.ctx

  let do_get ?ctx ?headers uri parser =
    Log.debug (fun m -> m "Performing get: %a" Uri.pp uri);
    let* r' = C.get ?ctx ?headers uri parser in
    match r' with
    | Ok resp -> Lwt.return_ok resp
    | Error e -> Lwt.return_error e

  let find_zone ?ctx t =
    let zone_api = Uri.with_path base_url "/client/v4/zones" in
    let with_name =
      Uri.add_query_param' zone_api ("name", t.config.zone_name)
    in
    let* r' =
      do_get ?ctx ~headers:t.headers with_name Zone_response.of_string
    in
    match r' with
    | Ok resp ->
        let rcd = List.hd resp.result in
        Log.debug (fun m ->
            m "Received response: %a" Zone_response.pp_zone_record rcd);
        Lwt.return_some rcd.id
    | Error e ->
        error "Failed to retrieve zone: %s" (C.show_error e);
        Lwt.return_none

  let get_record ?ctx t zone =
    let record_api =
      Uri.with_path base_url
        (Fmt.str "/client/v4/zones/%s/dns_records" (Zone_id.to_string zone))
    in
    let with_name =
      Uri.add_query_param' record_api ("name", t.config.record_name)
    in
    let* r' =
      do_get ?ctx ~headers:t.headers with_name Record_response.of_string
    in
    match r' with
    | Ok resp ->
        let rcd = List.hd resp.result in
        debug "Received zone record: %s" (Record_response.show_dns_record rcd);
        Lwt.return_some rcd
    | Error _e ->
        error "Failed to retrieve zone: %s" "baaad";
        Lwt.return_none

  let do_update ?ctx t dns update =
    let req = Record_update.of_dns dns update in
    let uri =
      Uri.with_path base_url
        (Fmt.str "/client/v4/zones/%s/dns_records/%s"
           (Zone_id.to_string dns.zone_id)
           (Record_id.to_string dns.id))
    in
    let* updated =
      C.patch ?ctx ~headers:t.headers uri Record_update.to_string req
    in
    match updated with
    | Ok _ ->
        Log.info (fun m ->
            m "Successfully updated DNS record `%s` in zone `%s`" dns.name
              dns.zone_name);
        Lwt.return_unit
    | Error _ -> failwith "I received an error"

  let id = "cloudflare.dns"
  let name t = t.name

  let create config name stream =
    Log.info (fun m ->
        m "Creating target %s with config: %s" name (show_config config));
    let headers =
      Cohttp.Header.init_with "Authorization" ("Bearer " ^ config.api_key)
    in
    { name; stream; config; headers }

  let log event =
    Log.debug (fun m -> m "Received update event: %a" Event.pp event)

  let existing_record = ref None

  let rec handle_update ?ctx t update =
    log update;
    match !existing_record with
    | Some r -> (
        match update with
        | Update (_old, new') -> do_update ?ctx t r new'
        | Init rr -> do_update ?ctx t r rr
        | Failure msg ->
            error "Source update failed with: %s. Ignoring." msg;
            Lwt.return_unit)
    | None -> (
        debug "Looking up zone: %s" t.config.zone_name;
        let* zone = find_zone ?ctx t in
        match zone with
        | None -> failwith "Cannot find zone"
        | Some z ->
            debug "Retrieving DNS records for zone: %s" (Zone_id.to_string z);
            let* record' = get_record ?ctx t z in
            existing_record := record';
            handle_update ?ctx t update)

  let run ?ctx t = Lwt_stream.iter_s (handle_update ?ctx t) t.stream
end
