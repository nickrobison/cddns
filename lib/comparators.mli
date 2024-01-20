(*Theoretically, we should be able to use ppx_import to derive these, but it's doesn't seem to be working for some reason*)
val ipv6_eq : Ipaddr.V6.t option -> Ipaddr.V6.t option -> bool
val ipv4_eq : Ipaddr.V4.t -> Ipaddr.V4.t -> bool
