defmodule MaruSwagger.ConfigStruct do
  defstruct [
    :path,           # [string]  where to mount the Swagger JSON
    :module,         # [atom]    Maru API module
    :version,        # [string]  version
    :pretty,         # [boolean] should JSON output be prettified?
    :swagger_inject  # [keyword list] key-values to inject directly into root of Swagger JSON
  ]

  def from_opts(opts) do
    path           = opts |> Keyword.fetch!(:at) |> Maru.Builder.Path.split
    module         = opts |> Keyword.fetch!(:module)
    pretty         = opts |> Keyword.get(:pretty, false)
    swagger_inject = opts |> Keyword.get(:swagger_inject, []) |> Keyword.put_new_lazy(:basePath, base_path_func(module)) |> check_swagger_inject_keys

    %__MODULE__{
      path: path,
      module: module,
      pretty: pretty,
      swagger_inject: swagger_inject,
    }
  end

  defp base_path_func(module) do
    fn ->
      [ "" |
        if Code.ensure_loaded?(Phoenix) do
          phoenix_module = Module.concat(Mix.Phoenix.base(), "Router")
          phoenix_module.__routes__ |> Enum.filter(fn r ->
            match?(%{kind: :forward, plug: ^module}, r)
          end)
          |> case do
            [%{path: p}] -> p |> String.split("/", trim: true)
            _            -> []
          end
        else
          []
        end
      ] |> Enum.join("/")
    end
  end

  defp check_swagger_inject_keys(swagger_inject) do
    swagger_inject |> Enum.filter(fn {k, v} ->
      k in allowed_swagger_fields and not v in [nil, ""]
    end)
  end

  defp allowed_swagger_fields do
    [:host, :basePath, :schemes, :consumes, :produces]
  end

end
