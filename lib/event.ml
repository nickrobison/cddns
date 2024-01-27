type t =
  | Init of Record.t
  | Update of (Record.t * Record.t)
  | Failure of string
[@@deriving show, eq]
