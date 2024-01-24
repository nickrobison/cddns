module type S = sig
  type error =
    [ `Network_error of int * string
    | `Parse_error of string
    | `Other_error of string ]

  type t
  type ctx
  type 'a parser = string -> ('a, string) result
  type 'a encoder = 'a -> string

  val get :
    ?ctx:ctx ->
    ?headers:Cohttp.Header.t ->
    string ->
    'a parser ->
    ('a, [> error ]) result Lwt.t

  val put :
    ?ctx:ctx ->
    ?headers:Cohttp.Header.t ->
    Uri.t ->
    'a encoder ->
    'a ->
    (unit, [> error ]) result Lwt.t
end
