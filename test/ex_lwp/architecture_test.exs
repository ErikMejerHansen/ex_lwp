defmodule ExLWP.ArchitectureTest do
  use ExUnit.Case, async: true

  @lib_files Path.wildcard("lib/**/*")

  describe "Given the package" do
    @tag spec: "ARCH-1"
    test "when its config is read, then it is named ex_lwp" do
      config = Mix.Project.config()

      assert config[:app] == :ex_lwp
      assert config[:package][:name] in [nil, "ex_lwp"]
    end

    @tag spec: "ARCH-2"
    test "when its modules are listed, then all are in the ExLWP namespace" do
      {:ok, modules} = :application.get_key(:ex_lwp, :modules)

      for module <- modules do
        # Protocol implementations are named after the protocol
        name = if protocol_impl?(module), do: module.__impl__(:for), else: module

        assert name == ExLWP or String.starts_with?(inspect(name), "ExLWP.")
      end
    end

    @tag spec: "ARCH-3"
    test "when its sources are listed, then they are all Elixir" do
      files = Enum.reject(@lib_files, &File.dir?/1)

      assert files != []
      assert Enum.all?(files, &(Path.extname(&1) == ".ex"))
      refute File.exists?("priv"), "expected no NIFs, ports or other native code"
    end

    @tag spec: "ARCH-9"
    test "when its dependencies are listed, then none are needed at runtime" do
      runtime_deps =
        for {_app, _requirement, opts} <- Mix.Project.config()[:deps],
            Keyword.get(opts, :runtime, true),
            Keyword.get(opts, :only) in [nil, :prod] or :prod in List.wrap(opts[:only]),
            do: opts

      assert runtime_deps == []

      assert Application.spec(:ex_lwp, :applications) -- [:kernel, :stdlib, :elixir, :logger] ==
               []
    end
  end

  describe "Given the library code" do
    @tag spec: "ARCH-4"
    test "when the application starts, then it starts no processes" do
      assert Application.spec(:ex_lwp, :mod) in [nil, []]
    end

    @tag spec: "ARCH-4"
    test "when its sources are searched, then they use no process or global state" do
      stateful = ~r/GenServer|Agent|:ets\.|Process\.(put|get)|spawn|:persistent_term|put_env/

      for file <- @lib_files, Path.extname(file) == ".ex" do
        refute File.read!(file) =~ stateful, "#{file} keeps state"
      end
    end

    @tag spec: "ARCH-4"
    test "when a stream is decoded, then the unfinished bytes are handed back to the caller" do
      assert {[], <<0x05, 0x00>>} = ExLWP.decode_stream(<<0x05, 0x00>>)
    end
  end

  describe "Given the documentation" do
    test "when read, then every public module and function is documented" do
      {:ok, modules} = :application.get_key(:ex_lwp, :modules)
      # Protocol implementations are not documented on their own, and only
      # Elixir 1.18+ hides their docs
      library =
        Enum.reject(modules, &(&1 in [ExLWP.Spec, ExLWP.SpecFormatter] or protocol_impl?(&1)))

      for module <- library do
        {:docs_v1, _, :elixir, _, moduledoc, _, docs} = Code.fetch_docs(module)

        # Internal modules are hidden with @moduledoc false
        if moduledoc != :hidden do
          assert %{"en" => _} = moduledoc, "#{inspect(module)} has no @moduledoc"

          for {{kind, name, arity}, _, _, doc, _} <- docs, kind in [:function, :macro] do
            assert doc != :none, "#{inspect(module)}.#{name}/#{arity} has no @doc"
          end
        end
      end
    end
  end

  defp protocol_impl?(module) do
    Code.ensure_loaded!(module)
    function_exported?(module, :__impl__, 1)
  end
end
