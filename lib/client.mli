module Make (C : Cohttp_lwt.S.Client) : Client_intf.S with type ctx = C.ctx
