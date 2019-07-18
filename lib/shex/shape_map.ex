defmodule ShEx.ShapeMap do
  @moduledoc """
  A finite set of `ShEx.ShapeMap.Association`s used to specify the nodes on which validations should be performed and for the result of validations.

  A ShapeMap can be either created with `ShEx.ShapeMap.new/1` or loaded from a
  string representation in the standard ShapeMap format with `ShEx.ShapeMap.decode/2`
  or a JSON-based format `ShEx.ShapeMap.from_json/2`.

  The set of associations can be accessed with the `associations/1` function as
  a list. `ShEx.ShapeMap` also implements the `Enumerable` protocol over this
  set of associations, so you can use it with all of Elixir's `Enum` functions.

  After the validation the associations get partitioned into two fields on the
  `ShEx.ShapeMap` struct: `conformant` and `nonconformant`.

  see <https://shexspec.github.io/shape-map/>
  """

  defmodule Association do
    @moduledoc """
    A ShapeMap association specifies the shape a node must conform to and contains the results of a validation.

    It is a structure consisting of the following fields:

    - `node`: an RDF node, or a triple pattern which is used to select RDF nodes
    - `shape`: label of a shape expression or the atom `:start` for the start shape expression

    The following fields are just filled in the case of a result ShapeMap, i.e.
    after the validation:

    - `status`: `:conformant` if `node` conforms the `shape`, otherwise `:nonconformant`
    - `reason`: a list of `ShEx.Violation` structs stating the reasons for failure or success
    - `app_info`: currently not used

    ShapeMap associations should not be created manually, but will be created
    implicitly on `ShEx.ShapeMap.new/1` or `ShEx.ShapeMap.add/2`.
    """

    defstruct [
      :node,
      :shape,
      :status,
      :reason,
      :app_info
    ]

    @type status :: :conformant | :nonconformant | nil


    @doc false
    def new(association)

    def new(association)
    # This is for the JSON-encoded ShapeMap format from the test suite
    def new({node, %{"shape" => shape, "result" => result}}) do
      %__MODULE__{new(node, shape) |
        status: if result == false do
          :nonconformant
        else
          :conformant
        end
      }
    end

    def new({node, shape}), do: new(node, shape)

    def new(%ShEx.ShapeMap.Association{} = association), do: association

    def new(%{node: node, shape: shape}), do: new(node, shape)

    # This is for the JSON-encoded ShapeMap format from the test suite
    def new(%{"node" => node, "shape" => shape}), do: new(node, shape)

    @doc false
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

    @doc """
    Return `true` if `association` is a query ShapeMap association, i.e. does not contain results.

    Note: Every fixed ShapeMap association is also a query ShapeMap association.
    """
    def query?(%__MODULE__{} = association),
      do: is_tuple(association.node) and not result?(association)

    @doc """
    Return `true` if `association` is a fixed ShapeMap association, i.e. doesn't have triple pattern as node or contains results.
    """
    def fixed?(%__MODULE__{} = association),
      do: not (result?(association) or query?(association))

    @doc """
    Return `true` if `association` is a result ShapeMap association, i.e. contains results.
    """
    def result?(%__MODULE__{status: status}), do: not is_nil(status)

    @doc false
    def conform(association)
    def conform(%__MODULE__{status: nil} = association),
      do: %__MODULE__{association | status: :conformant}
    def conform(%__MODULE__{} = association),
      do: association

    @doc false
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

  @doc """
  Creates an empty ShapeMap.
  """
  def new() do
    %__MODULE__{type: :fixed}
  end

  @doc """
  Creates an ShapeMap with the `associations` given as an enumerable.
  """
  def new(associations) do
     Enum.reduce(associations, new(), &(add(&2, &1)))
  end

  @doc """
  Loads a ShapeMap from the standard representation format.

  Returns an `ok` resp. `error` tuple.

  See <https://shexspec.github.io/shape-map/>
  """
  defdelegate decode(content, opts \\ []), to: ShEx.ShapeMap.Decoder

  @doc """
  Loads a ShapeMap from the standard representation format and fails in the error case.

  Same as `decode/2` but returns the ShapeMap directly (not in an `ok` tuple).
  """
  def decode!(content, opts \\ []) do
    case decode(content, opts) do
      {:ok, shape_map} -> shape_map
      {:error, error}  -> raise error
    end
  end

  @doc """
  Loads a ShapeMap from a JSON representation.

  This format is not clearly specified. It's currently used only to make test
  suite pass, where this format is used.
  """
  def from_json(content, options \\ []) do
    with {:ok, json_objects} <- Jason.decode(content, options) do
      {:ok, ShEx.ShapeMap.new(json_objects)}
    end
  end

  @doc """
  Adds a single or list of ShapeMap `associations` to `shape_map`.
  """
  def add(shape_map, associations)

  def add(shape_map, associations) when is_list(associations) do
    Enum.reduce(associations, shape_map, &(add(&2, &1)))
  end

  def add(shape_map, {node, associations}) when is_list(associations) do
    Enum.reduce(associations, shape_map, fn association, shape_map ->
      add(shape_map, {node, association})
    end)
  end

  def add(shape_map, association) do
    association = Association.new(association)
    shape_map
    |> Map.update!(association.status || :conformant, fn
         nil  -> [association]
         list -> [association | list]
       end)
    |> update_type(association)
  end

  defp update_type((%__MODULE__{type: :fixed, nonconformant: nonconformant}) = shape_map, _)
    when is_list(nonconformant) and length(nonconformant) > 0,
    do: %__MODULE__{shape_map | type: :result}

  defp update_type((%__MODULE__{type: :query, nonconformant: nonconformant}), _)
    when is_list(nonconformant) and length(nonconformant) > 0,
    do: raise "a result shape map can not contain triple patterns"

  defp update_type((%__MODULE__{type: :fixed}) = shape_map,
                   %Association{node: node} = association) when is_tuple(node),
    do: %__MODULE__{shape_map | type: :query} |> update_type(association)

  defp update_type(shape_map, _), do: shape_map

  @doc """
  Returns all associations in `shape_map` as a list.
  """
  def associations(shape_map) do
    List.wrap(shape_map.conformant) ++ List.wrap(shape_map.nonconformant)
  end

  @doc """
  Returns if all association in `shape_map` were conformant after a validation.

  Note: A non-result ShapeMap is always conformant.
  """
  def conformant?(shape_map)
  def conformant?(%__MODULE__{nonconformant: nil}), do: true
  def conformant?(%__MODULE__{nonconformant: []}), do: true
  def conformant?(%__MODULE__{}), do: false

  @doc """
  Return `true` if `shape_map` is a fixed ShapeMap, i.e. doesn't contain triple patterns (query ShapeMap) or results (result ShapeMap).
  """
  def fixed?(shape_map)
  def fixed?(%__MODULE__{type: :fixed}), do: true
  def fixed?(%__MODULE__{type: type}) when type in ~w[query result]a, do: false
  def fixed?(_), do: nil

  @doc """
  Return `true` if `shape_map` is a query ShapeMap, i.e. does not contain results (result ShapeMap).

  Note: Every fixed ShapeMap is also a query ShapeMap.
  """
  def query?(shape_map)
  def query?(%__MODULE__{type: type}) when type in ~w[fixed query]a, do: true
  def query?(%__MODULE__{type: :result}), do: false
  def query?(_), do: nil

  @doc """
  Return `true` if `shape_map` is a result ShapeMap.
  """
  def result?(shape_map)
  def result?(%__MODULE__{type: :result}), do: true
  def result?(%__MODULE__{type: type}) when type in ~w[fixed query]a, do: false
  def result?(_), do: nil

  @doc """
  Converts a query ShapeMap into a fixed ShapeMap by resolving all triple patterns against the given `graph`.
  """
  def to_fixed(shape_map, graph)

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
    if description = RDF.Graph.description(graph, subject) do
      RDF.Description.get(description, predicate, [])
    else
      []
    end
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
