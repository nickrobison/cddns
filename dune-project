(lang dune 3.11)

(name cddns)

(generate_opam_files true)

(source
 (github nickrobison/cddns))

(authors "Nick Robison")

(maintainers "Nick Robison")

(license MIT)

(documentation https://url/to/documentation)

(package
 (name cddns)
 (synopsis "A short synopsis")
 (description "A longer description")
 (depends (ocaml (>= 5)) lwt_ssl ipaddr yojson ppx_import cohttp-lwt-unix duration logs cmdliner ppx_deriving_yojson (alcotest :with-test) (alcotest-lwt :with-test) (routes :with-test) (lwt_ppx :with-test) mirage-time-unix)
 (tags
  (topics "to describe" your project)))

; See the complete stanza docs at https://dune.readthedocs.io/en/stable/dune-files.html#dune-project
