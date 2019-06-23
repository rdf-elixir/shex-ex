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

    def new(node, shape) do
      # TODO: support for triple patterns
      %__MODULE__{node: node, shape: shape}
    end

    def query?(%__MODULE__{} = association),
        do: not (result?(association) or fixed?(association))

    def fixed?(%__MODULE__{status: nil, node: node} = association) do
      # TODO
    end

    def fixed?(%__MODULE__{}), do: false

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

  def new(shape_map)

  def new(%{} = shape_map) do
    %__MODULE__{
      type: :fixed, # TODO: support for query shape maps
      conformant: Enum.map(shape_map, &Association.new/1)
    }
  end

  def associations(shape_map) do
    List.wrap(shape_map.conformant) ++ List.wrap(shape_map.nonconformant)
  end

  def add(shape_map, %Association{} = association) do
    Map.update(shape_map, association.status || :conformant, [association],
      fn list -> [association | list] end)
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


  def to_fixed(%__MODULE__{type: :query} = shape_map) do
    # TODO
  end

  def to_fixed(%__MODULE__{type: :fixed} = shape_map),
    do: {:ok, shape_map}

  def to_fixed(%__MODULE__{type: :result} = shape_map),
    do: {:error, "a result shape map is not convertible to a fixed shape map"}
end
