open Lwt.Syntax
open Cohttp

let src = Logs.Src.create "http_client" ~doc:"Shared HTTP Client"

module Log = (val Logs.src_log src : Logs.LOG)

module Make (C : Cohttp_lwt.S.Client) = struct
  type ctx = C.ctx
  type t = unit

  type error =
    [ `Network_error of int * string
    | `Parse_error of string
    | `Other_error of string ]

  type 'a parser = string -> ('a, string) result
  type 'a encoder = 'a -> string

  let get ?ctx ?headers url parser =
    let* resp, body' = C.get ?ctx ?headers (Uri.of_string url) in
    let response_code = resp |> Response.status |> Code.code_of_status in
    let* body = body' |> Cohttp_lwt.Body.to_string in
    Log.info (fun m -> m "Status: %d body: %s" response_code body);
    match Code.is_success response_code with
    | false -> Lwt.return_error (`Network_error (response_code, "Bad"))
    | true -> (
        let parsed = parser body in
        match parsed with
        | Ok p -> Lwt.return_ok p
        | Error e -> Lwt.return_error (`Parse_error e))

  let put ?ctx ?headers url encoder p =
    let body = encoder p in
    let* resp, body' = C.put ?headers ?ctx ~body:(`String body) url in
    let response_code = resp |> Response.status |> Code.code_of_status in
    let* body = body' |> Cohttp_lwt.Body.to_string in
    Log.info (fun m -> m "Status: %d body: %s" response_code body);
    match Code.is_success response_code with
    | true -> Lwt.return_ok ()
    | false -> Lwt.return_error (`Network_error (response_code, "Put failed"))
end
