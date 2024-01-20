open Lwt.Syntax
open Cohttp

module Make (C : Cohttp_lwt.S.Client) = struct
  type ctx = C.ctx
  type t = { name : string; pusher : Lib.Event.t option -> unit }

  let id = "ipify"
  let name t = t.name

  let create name _refresh pusher =
    print_endline "Do start";
    { name; pusher }

  let start ?ctx t =
    print_endline "Starting!!";
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
    Lwt.return_unit
end
