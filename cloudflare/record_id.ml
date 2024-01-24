type t = string [@@deriving of_yojson, show]

let of_string str = str
let to_string t = t
