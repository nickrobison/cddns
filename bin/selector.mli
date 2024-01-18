open Lib

val source_of_id : string -> (module Source.S)
val target_of_id : string -> (module Target.S)
