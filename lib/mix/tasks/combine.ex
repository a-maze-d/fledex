defmodule Mix.Tasks.Livebook do
  @moduledoc "creates a livebook file from all the project modules"
  use Mix.Task
  @lib_dir Path.expand("#{__DIR__}/../..")
  def run([filename]) do
    {:ok, io} = File.open(Path.expand("#{@lib_dir}/../#{filename}.livebook.md"), [:read, :write])
    config = %{filters: ["mix", "color/256-colors.json"], root_path: @lib_dir, io: io}
    write_header(config)
    add_directory("./", config)
    write_footer(config)
    :ok = File.close(io)
  end

  defp write_header(config) do
    IO.puts(config.io, "```elixir\n\n")
  end
  defp write_footer(config) do
    IO.puts(config.io, "\n\n```")
  end
  defp add_directory(path_from_root, config) do
    IO.puts("Processing: #{path_from_root}")
    path = Path.expand(path_from_root, config.root_path)
    {:ok, files} = File.ls(path)
    # filters = Enum.filter(config.filters, fn filter -> String.starts_with?(filter, path_from_root) end)

    # IO.puts("Before: #{inspect filters}")
    # filters = Enum.flat_map(filters, fn filter ->
    #   String.split(filter, path_from_root, [trim: true, parts: 1])
    # end)
    # IO.puts("After: #{inspect filters}")

    # files = Enum.filter(files, fn name -> name not in filters end)
    sub_dirs = Enum.filter(files, fn name ->
      full_path = Path.expand(name, path)
      relative_path = Path.relative_to(full_path, config.root_path)
      File.dir?(full_path) and relative_path not in config.filters
    end)
    files = Enum.filter(files, fn name ->
      full_path = Path.expand(name, path)
      relative_path = Path.relative_to(full_path, config.root_path)
      not File.dir?(full_path) and relative_path not in config.filters
    end)
    for sub_dir <- sub_dirs do
      add_directory(Path.relative_to(Path.expand(sub_dir, path), config.root_path), config)
    end
    for file <- files do
      add_file(Path.relative_to(Path.expand(file, path), config.root_path), config)
    end
    IO.puts("Processing done: #{path_from_root}")
  end

  defp add_file(path_from_root, config) do
    absolute_path = Path.expand(path_from_root, config.root_path)
    IO.puts("Adding file: #{absolute_path}")
    file_content = File.read!(absolute_path)
    IO.puts(config.io, file_content)
  end
end
