type t = Init of Record.t | Update of (Record.t * Record.t) [@@deriving show]
