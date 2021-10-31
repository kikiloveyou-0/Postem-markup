module Char = struct
  include Char

  let to_string = String.make 1
end

module String = struct
  include String

  let empty = ""

  let is_empty = ( = ) ""

  let concat_first sep = function [] -> "" | l -> sep ^ String.concat sep l

  let join = String.concat ""

  let real_split chr str =
    String.split_on_char chr str |> List.filter (( <> ) "")

  let concat_lines = String.concat "\n"

  let split_lines = String.split_on_char '\n'
end

module File = struct
  type t = string

  let read_all filename =
    let ic = open_in filename in
    let rec read_lines acc =
      try input_line ic :: acc |> read_lines
      with _ ->
        close_in_noerr ic;
        List.rev acc |> String.concat_lines
    in
    read_lines []

  let write filename str =
    let oc = open_out filename in
    Printf.fprintf oc "%s\n" str;
    close_out oc
end

module Error_msg = struct
  open Lexing

  type t = string

  let of_position { pos_fname; pos_lnum; pos_cnum; pos_bol; _ } ~msg =
    let fname = if String.is_empty pos_fname then "REPL" else pos_fname in
    Printf.sprintf "File \"%s\", line %d, character %d:\nError: %s" fname
      pos_lnum
      (pos_cnum - pos_bol + 1)
      msg

  let of_lexbuf { lex_curr_p; _ } ~msg = of_position lex_curr_p ~msg
end
