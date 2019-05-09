defmodule ShEx.NodeConstraint.NumericFacets do
  defstruct ~w[mininclusive minexclusive maxinclusive maxexclusive totaldigits fractiondigits]a

  alias RDF.Literal

  @numeric_datatypes RDF.Numeric.types()

  def new(xs_facets) do
    xs_facets_with_literals =
      Map.new(xs_facets, fn
        {key, value} when key in ~w[mininclusive minexclusive maxinclusive maxexclusive]a ->
          {key, RDF.Literal.new(value)}
        {key, value} ->
          {key, value}
      end)
    numeric_facets = struct(__MODULE__, xs_facets_with_literals)
    if %__MODULE__{} != numeric_facets do
      numeric_facets
    end
  end


  # TODO: instead of checking on every application to a node which constraints are there and must be applied, this could be compiled into minimal constraint checker
  def satisfies?(nil, _), do: true

  def satisfies?(numeric_facets, %Literal{datatype: datatype} = node)
       when datatype in @numeric_datatypes do
    satisfies_numeric_mininclusive?(numeric_facets.mininclusive, node) &&
      satisfies_numeric_minexclusive?(numeric_facets.minexclusive, node) &&
      satisfies_numeric_maxinclusive?(numeric_facets.maxinclusive, node) &&
      satisfies_numeric_maxexclusive?(numeric_facets.maxexclusive, node) &&
      satisfies_numeric_totaldigits?(numeric_facets.totaldigits, node) &&
      satisfies_numeric_fractiondigits?(numeric_facets.fractiondigits, node)
  end

  def satisfies?(_, _), do: nil


  defp satisfies_numeric_mininclusive?(nil, _), do: true
  defp satisfies_numeric_mininclusive?(mininclusive, literal),
    do: RDF.Numeric.compare(literal, mininclusive) in [:gt, :eq]

  defp satisfies_numeric_minexclusive?(nil, _), do: true
  defp satisfies_numeric_minexclusive?(minexclusive, literal),
    do: RDF.Numeric.compare(literal, minexclusive) == :gt

  defp satisfies_numeric_maxinclusive?(nil, _), do: true
  defp satisfies_numeric_maxinclusive?(maxinclusive, literal),
    do: RDF.Numeric.compare(literal, maxinclusive) in [:lt, :eq]

  defp satisfies_numeric_maxexclusive?(nil, _), do: true
  defp satisfies_numeric_maxexclusive?(maxexclusive, literal),
    do: RDF.Numeric.compare(literal, maxexclusive) == :lt

  defp satisfies_numeric_totaldigits?(nil, _), do: true
  defp satisfies_numeric_totaldigits?(totaldigits, literal),
    do: RDF.Decimal.digit_count(literal) >= totaldigits

  defp satisfies_numeric_fractiondigits?(nil, _), do: true
  defp satisfies_numeric_fractiondigits?(fractiondigits, literal),
       do: RDF.Decimal.fraction_digit_count(literal) >= fractiondigits
end
