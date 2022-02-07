open Ast_types

module type WRITER = sig
  type t

  val eval : Preprocess.metadata -> doc -> t list
end

module type CUSTOM_WRITER = sig
  type t

  val eval : ?alias:Context.t -> doc -> t list
end

module Make (Writer : WRITER) : CUSTOM_WRITER with type t := Writer.t = struct
  let eval ?(alias = Context.empty) doc =
    let metadata, elist = Preprocess.pp_doc alias doc in
    Writer.eval metadata elist
end
