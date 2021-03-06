defmodule ShEx.NodeConstraint.NumericFacets do
  @moduledoc false

  defstruct ~w[mininclusive minexclusive maxinclusive maxexclusive totaldigits fractiondigits]a

  alias RDF.{Literal, XSD}

  def new(xs_facets) do
    xs_facets_with_literals =
      Map.new(xs_facets, fn
        {key, value} when key in ~w[mininclusive minexclusive maxinclusive maxexclusive]a ->
          {key, value |> XSD.Decimal.new() |> Literal.canonical()}

        {key, value} ->
          {key, value}
      end)

    numeric_facets = struct(__MODULE__, xs_facets_with_literals)

    if %__MODULE__{} != numeric_facets do
      numeric_facets
    end
  end

  # TODO: instead of checking on every application to a node which constraints are there and must be applied, this could be compiled into minimal constraint checker
  def satisfies(nil, _), do: :ok

  def satisfies(numeric_facets, %Literal{} = node) do
    with true <- XSD.Numeric.datatype?(node) and Literal.valid?(node),
         true <- satisfies_numeric_mininclusive(numeric_facets.mininclusive, node),
         true <- satisfies_numeric_minexclusive(numeric_facets.minexclusive, node),
         true <- satisfies_numeric_maxinclusive(numeric_facets.maxinclusive, node),
         true <- satisfies_numeric_maxexclusive(numeric_facets.maxexclusive, node),
         true <- satisfies_numeric_totaldigits(numeric_facets.totaldigits, node),
         true <- satisfies_numeric_fractiondigits(numeric_facets.fractiondigits, node) do
      :ok
    else
      false ->
        %ShEx.Violation.NumericFacetConstraint{
          facet_type: :invalid_numeric,
          node: node
        }

      {:violates, type, value} ->
        %ShEx.Violation.NumericFacetConstraint{
          facet_type: type,
          facet_value: value,
          node: node
        }
    end
  end

  def satisfies(_, node) do
    %ShEx.Violation.NumericFacetConstraint{
      facet_type: :invalid_numeric,
      node: node
    }
  end

  defp satisfies_numeric_mininclusive(nil, _), do: true

  defp satisfies_numeric_mininclusive(mininclusive, literal) do
    RDF.Literal.compare(literal, mininclusive) in [:gt, :eq] ||
      {:violates, :mininclusive, mininclusive}
  end

  defp satisfies_numeric_minexclusive(nil, _), do: true

  defp satisfies_numeric_minexclusive(minexclusive, literal) do
    RDF.Literal.compare(literal, minexclusive) == :gt ||
      {:violates, :minexclusive, minexclusive}
  end

  defp satisfies_numeric_maxinclusive(nil, _), do: true

  defp satisfies_numeric_maxinclusive(maxinclusive, literal) do
    RDF.Literal.compare(literal, maxinclusive) in [:lt, :eq] ||
      {:violates, :maxinclusive, maxinclusive}
  end

  defp satisfies_numeric_maxexclusive(nil, _), do: true

  defp satisfies_numeric_maxexclusive(maxexclusive, literal) do
    RDF.Literal.compare(literal, maxexclusive) == :lt ||
      {:violates, :maxexclusive, maxexclusive}
  end

  defp satisfies_numeric_totaldigits(nil, _), do: true

  defp satisfies_numeric_totaldigits(totaldigits, literal) do
    (decimal?(literal) && XSD.Decimal.digit_count(literal) <= totaldigits) ||
      {:violates, :totaldigits, totaldigits}
  end

  defp satisfies_numeric_fractiondigits(nil, _), do: true

  defp satisfies_numeric_fractiondigits(fractiondigits, literal) do
    (decimal?(literal) && XSD.Decimal.fraction_digit_count(literal) <= fractiondigits) ||
      {:violates, :fractiondigits, fractiondigits}
  end

  defp decimal?(%Literal{} = literal) do
    # We also have to check for XSD.Integer since RDF.ex implements it as a primitive
    XSD.Integer.datatype?(literal) or XSD.Decimal.datatype?(literal)
  end
end
