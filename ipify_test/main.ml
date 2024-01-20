open! Lwt.Syntax
open Alcotest
module I = Ipify.Source.Make (Cohttp_mock.Client) (Time)

let test_ip = Ipaddr.V4.of_string_exn "10.11.12.13"

let get_success ?headers ?body meth =
  ignore headers;
  match (meth, body) with
  | `GET, _ -> Lwt.return (`OK, Ipaddr.V4.to_string test_ip)
  | _, _ -> Lwt.return (`Method_not_allowed, "bad")

let get_failure ?headers ?body meth =
  ignore headers;
  match (meth, body) with _, _ -> Lwt.return (`Method_not_allowed, "bad")

let success _switch () =
  let router = Routes.(one_of [ nil @--> get_success ]) in
  let ctx = Cohttp_mock.Client.ctx_of_router router in
  let stream, push = Lwt_stream.create () in
  let ipify =
    I.create "test" { refresh = Duration.of_min 10; ipv4_only = true } push
  in
  let _ = I.start ~ctx ipify in
  let* result = Lwt_stream.find (fun _ -> true) stream in
  match result with
  | Some (Init record) ->
      check string "IPv4"
        (Ipaddr.V4.to_string test_ip)
        (Ipaddr.V4.to_string record.ipv4addr);
      Lwt.return_unit
  | _ -> Lwt.return (failwith "Nope")

let failure _switch () =
  let router = Routes.(one_of [ nil @--> get_failure ]) in
  let ctx = Cohttp_mock.Client.ctx_of_router router in
  let stream, push = Lwt_stream.create () in
  let ipify =
    I.create "test" { refresh = Duration.of_min 10; ipv4_only = false } push
  in
  let _ = I.start ~ctx ipify in
  let* result = Lwt_stream.find (fun _ -> true) stream in
  match result with
  | Some (Init record) ->
      check string "IPv4"
        (Ipaddr.V4.to_string test_ip)
        (Ipaddr.V4.to_string record.ipv4addr);
      Lwt.return_unit
  | _ -> Lwt.return (failwith "Nope")

let () =
  Lwt_main.run
  @@ Alcotest_lwt.run ~argv:[| "test"; "--verbose" |] "Ipify Tests"
       [
         ( "API Tests",
           [
             Alcotest_lwt.test_case "Simple" `Quick success;
             Alcotest_lwt.test_case "Failure" `Quick failure;
           ] );
       ]
