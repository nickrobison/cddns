open Lwt.Syntax
open Cohttp

module Make (C : Cohttp_lwt.S.Client) = struct
  type ctx = C.ctx
  type t = unit

  type error =
    [ `Network_error of int * string
    | `Parse_error of string
    | `Other_error of string ]

  type 'a parser = string -> ('a, string) result
  type 'a encoder = 'a -> string

  let get ?ctx url parser =
    let* resp, body' = C.get ?ctx (Uri.of_string url) in
    let response_code = resp |> Response.status |> Code.code_of_status in
    match Code.is_success response_code with
    | false -> Lwt.return_error (`Network_error (response_code, "Get failed"))
    | true -> (
        let* body = body' |> Cohttp_lwt.Body.to_string in
        let parsed = parser body in
        match parsed with
        | Ok p -> Lwt.return_ok p
        | Error e -> Lwt.return_error (`Parse_error e))

  let put ?ctx url encoder p =
    let encoded = encoder p in
    let* resp, _ = C.put ?ctx ~body:(`String encoded) url in
    let response_code = resp |> Response.status |> Code.code_of_status in
    match Code.is_success response_code with
    | false -> Lwt.return_error (`Network_error (response_code, "Put failed"))
    | true -> Lwt.return_ok ()
end
