open Lwt.Infix

type t = {
  pool : Current.Pool.t option;
}

let id = "docker-run"

module Key = struct
  type t = {
    image : Image.t;
    args : string list;
    docker_context : string option;
  }

  let pp_args = Fmt.(list ~sep:sp (quote string))

  let cmd { image; args; docker_context } =
    Cmd.docker ~docker_context @@ ["run"; "--rm"; "-i"; Image.hash image] @ args

  let pp f t = Cmd.pp f (cmd t)

  let digest { image; args; docker_context } =
    Yojson.Safe.to_string @@ `Assoc [
      "image", `String (Image.hash image);
      "args", [%derive.to_yojson:string list] args;
      "docker_context", [%derive.to_yojson:string option] docker_context;
    ]
end

module Value = Current.Unit

let build { pool } job key =
  Current.Job.start job ?pool ~level:Current.Level.Average >>= fun () ->
  Current.Process.exec ~cancellable:true ~job (Key.cmd key)

let pp = Key.pp

let auto_cancel = true
