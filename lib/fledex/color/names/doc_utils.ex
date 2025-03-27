# Copyright 2023, Matthias Reik <fledex@reik.org>
#
# SPDX-License-Identifier: Apache-2.0

defmodule Fledex.Color.Names.DocUtils do
  @doc """
  Extracts the docs from a function
  """
  def extract_doc(module, function, arity) do
    # IO.puts("extract_doc" <> inspect {module, function, arity})
    case get_docs(module, [:function]) do
      {nil, nil, nil} ->
        nil

      {_language, _format, docs} ->
        extract_function_doc(docs, function, arity)
    end
  end

  def extract_function_doc(docs, function, arity) do
    case Enum.find(docs, nil, fn {{_type, func_name, func_arity}, _info, _types, _doc, _opts} ->
           func_name === function && func_arity === arity
         end) do
      nil ->
        nil

      {_def, _info, _types, doc, _opts} ->
        %{"en" => doc} = doc
        doc
    end
  end

  @doc """
  Extract docs from a module, filtered by the kinds (list of :function, :type, ...)
  """
  def get_docs(module, kinds) do
    case Code.fetch_docs(module) do
      {:docs_v1, _number, language, format, _module_doc, _donno, docs} ->
        docs =
          for {{kind, _name, _arity}, _info, _type, _txt, _donno} = doc <- docs,
              kind in kinds,
              do: doc

        {language, format, docs}

      {:error, _msg} ->
        # IO.puts("error: " <> inspect {msg, module})
        {nil, nil, nil}
    end
  end
end
