defmodule ShEx.ShapeMap do

  defmodule Association do
    defstruct [
      :node,
      :shape,
      :status,
      :reason,
      :app_info
    ]

    @type status :: :conformant | :nonconformant | nil

    def new({node, shape}), do: new(node, shape)

    def new(%ShEx.ShapeMap.Association{} = association), do: association

    def new(%{node: node, shape: shape}), do: new(node, shape)

    def new(node, shape) do
      %__MODULE__{
        node: coerce_node(node),
        shape: coerce_shape(shape),
      }
    end

    defp coerce_node({subject, predicate, object}) do
      {
        (if subject in [:focus, :_], do: subject, else: RDF.Statement.coerce_subject(subject)),
        RDF.Statement.coerce_predicate(predicate),
        (if object in [:focus, :_], do: object, else: RDF.Statement.coerce_object(object)),
      }
    end

    defp coerce_node(node) do
      cond do
        not is_atom(node) and RDF.term?(node) ->
          node

        is_atom(node) or (is_binary(node) and String.contains?(node, ":")) ->
          RDF.iri(node)

        true ->
          RDF.Term.coerce(node)
      end
    end

    defp coerce_shape(shape) do
      cond do
        # we allow maps to pass unchanged because we create intermediary associations containing shapes directly
        is_map(shape) or (not is_atom(shape) and RDF.term?(shape)) ->
          shape

        shape in [:start, "START"] ->
          :start

        true ->
          RDF.iri(shape)
      end
    end

    def query?(%__MODULE__{} = association),
      do: is_tuple(association.node) and not result?(association)

    def fixed?(%__MODULE__{} = association),
      do: not (result?(association) or query?(association))

    def result?(%__MODULE__{status: status}), do: not is_nil(status)


    def conform(%__MODULE__{status: nil} = association),
      do: %__MODULE__{association | status: :conformant}
    def conform(%__MODULE__{} = association),
      do: association

    def violation(%__MODULE__{} = association, reasons, app_infos \\ nil) do
      %__MODULE__{association |
        status: :nonconformant,
        reason:
          if is_list(reasons) do
            reasons ++ List.wrap(association.reason)
          else
            [reasons | List.wrap(association.reason)]
          end
        # TODO: save app_infos
      }
    end
  end

  defstruct [:type, :conformant, :nonconformant]

  @type type :: :fixed | :query | :result

  def new() do
    %__MODULE__{type: :fixed}
  end

  def new(associations, opts \\ []) do
     Enum.reduce(associations, new(), &(add(&2, &1)))
  end

  def add(shape_map, association) do
    with association = Association.new(association) do
      shape_map
      |> Map.update!(association.status || :conformant, fn
           nil  -> [association]
           list -> [association | list]
         end)
      |> update_type(association)
    end
  end

  defp update_type((%__MODULE__{type: :fixed, nonconformant: nonconformant}) = shape_map, _)
    when is_list(nonconformant) and length(nonconformant) > 0,
    do: %__MODULE__{shape_map | type: :result}

  defp update_type((%__MODULE__{type: :query, nonconformant: nonconformant}) = shape_map, _)
    when is_list(nonconformant) and length(nonconformant) > 0,
    do: raise "a result shape map can not contain triple patterns"

  defp update_type((%__MODULE__{type: :fixed}) = shape_map,
                   %Association{node: node} = association) when is_tuple(node),
    do: %__MODULE__{shape_map | type: :query} |> update_type(association)

  defp update_type(shape_map, _), do: shape_map

  def associations(shape_map) do
    List.wrap(shape_map.conformant) ++ List.wrap(shape_map.nonconformant)
  end

  def conformant?(%__MODULE__{nonconformant: nil}), do: true
  def conformant?(%__MODULE__{nonconformant: []}), do: true
  def conformant?(%__MODULE__{}), do: false

  def fixed?(%__MODULE__{type: :fixed}), do: true
  def fixed?(%__MODULE__{type: type}) when type in ~w[query result]a, do: false
  def fixed?(_), do: nil

  def query?(%__MODULE__{type: type}) when type in ~w[fixed query]a, do: true
  def query?(%__MODULE__{type: :result}), do: false
  def query?(_), do: nil

  def result?(%__MODULE__{type: :result}), do: true
  def result?(%__MODULE__{type: type}) when type in ~w[fixed query]a, do: false
  def result?(_), do: nil


  def to_fixed(%__MODULE__{type: :query} = shape_map, graph) do
    {:ok,
      shape_map
      |> Stream.flat_map(&(resolve_triple_pattern(&1, graph)))
      |> MapSet.new()
      |> new()
    }
  end

  def to_fixed(%__MODULE__{type: :fixed} = shape_map, _),
    do: {:ok, shape_map}

  def to_fixed(%__MODULE__{type: :result}, _),
    do: {:error, "a result shape map is not convertible to a fixed shape map"}

  defp resolve_triple_pattern(%ShEx.ShapeMap.Association{node: triple_pattern, shape: shape}, graph)
       when is_tuple(triple_pattern) do
    triple_pattern
    |> do_resolve_triple_pattern(graph)
    |> Enum.map(fn node -> ShEx.ShapeMap.Association.new(node, shape) end)
  end

  defp resolve_triple_pattern(%ShEx.ShapeMap.Association{} = association, _),
    do: {:ok, association}

  defp do_resolve_triple_pattern({:focus, predicate, :_}, graph) do
    graph
    |> Stream.map(fn
         {subject, ^predicate, _} -> subject
         _ -> nil
       end)
    |> post_process_query()
  end

  defp do_resolve_triple_pattern({:_, predicate, :focus}, graph) do
    graph
    |> Stream.map(fn
         {_, ^predicate, object} -> object
         _ -> nil
       end)
    |> post_process_query()
  end

  defp do_resolve_triple_pattern({subject, predicate, :focus}, graph) do
    graph
    |> RDF.Graph.description(subject)
    |> RDF.Description.get(predicate, [])
  end

  defp do_resolve_triple_pattern({:focus, predicate, object}, graph) do
    graph
    |> Stream.map(fn
      {subject, ^predicate, ^object} -> subject
      _ -> nil
    end)
    |> post_process_query()
  end

  defp post_process_query(nodes) do
    nodes
    |> MapSet.new()
    |> MapSet.delete(nil)
    |> MapSet.to_list()
  end

  defimpl Enumerable do
    def reduce(shape_map, acc, fun),
      do: shape_map |> ShEx.ShapeMap.associations() |> Enumerable.reduce(acc, fun)

    def member?(shape_map, association),
      do: {:ok, association in ShEx.ShapeMap.associations(shape_map)}

    def count(shape_map),
      do: {:ok, shape_map |> ShEx.ShapeMap.associations() |> length()}

    def slice(_shape_map), do: {:error, __MODULE__}
  end
end
