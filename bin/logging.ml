open Cmdliner

let setup_log style_renderer level =
  Fmt_tty.setup_std_outputs ?style_renderer ();
  Logs.set_level level;
  Logs.set_reporter (Logs_fmt.reporter ());
  ()

let setup () =
  Term.(const setup_log $ Fmt_cli.style_renderer () $ Logs_cli.level ())
