open Utils

module Repl = struct
  let launch eval =
    let input = ref [] in
    try
      while true do
        input := read_line () :: !input
      done
    with End_of_file -> (
      print_newline ();
      match List.rev !input |> String.concat "\n" |> eval with
      | Ok output ->
          print_endline output;
          exit 0
      | Error msg ->
          prerr_endline msg;
          exit 1)
end

let prerr_with_exit err =
  prerr_endline err;
  exit 1

let load_unit name =
  match Ehandler.load_res Expansion.Known.expansions name with
  | Ok expsn -> expsn
  | Error (msg, hint) -> prerr_with_exit @@ Error.of_string msg ~hint

module Parser = struct
  let parse lexbuf =
    let open Parsing in
    try Ok (Parser.document Lexer.read lexbuf) with
    | Lexer.Syntax_error { lex_curr_p; _ } ->
        Result.error
        @@ Error.of_position lex_curr_p
             ~msg:"character not allowed in source text"
             ~hint:"non-ascii characters must be placed in a unformat block."
    | Parser.Error -> Result.error @@ Error.of_lexbuf lexbuf ~msg:"syntax error"
end

let compile () =
  let args = Args.parse () in
  let module Expsn = (val load_unit args#expsn) in
  let module Eval = struct
    type t = string

    let eval ast =
      let module AEval = Ast.Eval_expsn.MakeWithExpsn (Expsn) in
      try AEval.eval ast
      with Ast.Eval_expsn.Missing_metamark ({ startpos; endpos }, name) ->
        let msg = Printf.sprintf "missing metamark \"%s\"" name
        and hint =
          "try to define your metamark in the used expansion and reinstall \
           Postem."
        and cursor_length = endpos.pos_cnum - endpos.pos_bol in
        prerr_with_exit @@ Error.of_position startpos ~msg ~hint ~cursor_length
  end in
  let module Compiler = Compil_impl.Make (Parser) (Eval) in
  if args#direct_input = "" && args#inputf = "" then
    Repl.launch @@ Compiler.from_string ~filename:"REPL"
  else
    let from_src =
      if args#direct_input = "" then
        if Sys.file_exists args#inputf then
          Compiler.from_channel ~filename:args#inputf @@ open_in args#inputf
        else
          Printf.sprintf "\"%s\": no such file" args#inputf
          |> Error.of_string |> prerr_with_exit
      else Compiler.from_string ~filename:args#inputf args#inputf
    in
    match from_src with
    | Ok r ->
        if args#output_on_stdout then print_endline r
        else File.write args#outputf r
    | Error msg -> prerr_with_exit msg
