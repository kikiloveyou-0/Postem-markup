open Ast

let document =
  Ast_types.Prog
    [
      Marker Misc.Text.capitalize;
      Block (Text "Hello world", Alias ("VH", "Victor Hugo"));
      Block (Text "VH est né en ", Block (Text "1885", Text "."));
    ]

let () =
  let global = Context.create () in
  Eval.eval global document |> print_string