type t [@@deriving of_yojson, show]

val of_string : string -> t
val to_string : t -> string
