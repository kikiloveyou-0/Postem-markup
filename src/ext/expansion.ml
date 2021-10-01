open Utils

module type S = sig
  val definition : string -> string list -> string

  val heading : int -> string -> string

  val quotation : string list -> string

  val listing : string list -> string

  val postprocess : Document.t -> string
end

module Default : S = struct
  let definition name values = name ^ String.concat_first "\n  | " values

  let heading level str =
    let underline =
      Array.get [| '#'; '*'; '='; '-'; '^'; '"' |] level
      |> String.(length str |> make)
    in
    Printf.sprintf "%s\n%s" str underline

  let quotation = String.concat_first " 0 "

  let listing = String.concat_first "\n - "

  let postprocess { Document.content; _ } = content
end
