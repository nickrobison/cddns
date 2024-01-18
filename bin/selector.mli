open Lib

val source_of_id : string -> (module Source_intf.S)
val target_of_id : string -> (module Target_intf.S)
