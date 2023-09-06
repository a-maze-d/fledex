defmodule Fledex.Test do
defmacro __using__(_opts) do
    quote do
      import Fledex.Test
    end
  end
  defmacro live_loop(name, clauses) do
    build_live_loop(name, clauses)
  end
  defp build_live_loop(name, do: do_clause) do
    # {configs, expression} = extract_configs(do_cause)
    # build_live_loop(name, expression: expression, configs: configs)
  end
  defp build_live_loop(name, do: do_clause, config: with_clause) do
    quote do
      name = unquote(name)
      config = Macro.to_string(unquote(with_clause))
      expression = Macro.to_string(unquote(do_clause))
      IO.puts("#{name}\n\tParameters #{config}\n\tExpression: #{expression}")
    end
  end
end

defmodule T2 do
  use Fledex.Test
  def run1a() do
    live_loop :name, do: :this
  end
  def run1b() do
    live_loop :name do
      true
    end
  end
  def run2a() do
    live_loop :name, do: :this, config: :that
  end
end
