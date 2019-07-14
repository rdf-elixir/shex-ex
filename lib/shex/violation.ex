defmodule ShEx.Violation.Shared do
  @moduledoc false

  def message(violation) do
    ShEx.Violation.reason(violation)
  end

  def reason_from_doc(reason_doc) do
    import Inspect.Algebra

    reason_doc
    |> format(80)
    |> Enum.join()
  end
end

defprotocol ShEx.Violation do
  @moduledoc """
  A violation of a shape during validation.
  """

  @doc """
  The label of the violation type.
  """
  def label(violation)

  @doc """
  A human representation of the reason for the violation.
  """
  def reason(violation)

  @doc false
  def reason_doc(violation)

  @doc """
  A human representation of the violation.

  Currently it's the same as the reason, but might contain additional
  information in the future.
  """
  defdelegate message(violation), to: ShEx.Violation.Shared
end

defmodule ShEx.Violation.NodeKindConstraint do
  @moduledoc """
  `ShEx.Violation` produced on a nonconformant node constraint.
  """

  defstruct [:node_kind, :node]

  defimpl ShEx.Violation do
    def label(_), do: "Node Kind Constraint Violation"

    def reason(violation) do
      "#{inspect violation.node} is not a #{violation.node_kind}"
    end

    defdelegate reason_doc(violation), to: ShEx.Violation, as: :reason
  end
end

defmodule ShEx.Violation.DatatypeConstraint do
  @moduledoc """
  `ShEx.Violation` produced on a nonconformant datatype constraint.
  """

  defstruct [:datatype, :node]

  defimpl ShEx.Violation do
    def label(_), do: "Datatype Constraint Violation"

    def reason(violation) do
      "#{inspect violation.node} has not datatype #{inspect violation.datatype}"
    end

    defdelegate reason_doc(violation), to: ShEx.Violation, as: :reason
  end
end

defmodule ShEx.Violation.StringFacetConstraint do
  @moduledoc """
  `ShEx.Violation` produced on a nonconformant string facet constraint.
  """

  defstruct [:facet_type, :facet_value, :node]

  defimpl ShEx.Violation do
    def label(_), do: "String Facet Constraint Violation"

    def reason(%{facet_type: :length} = violation) do
      "length of #{inspect violation.node} is not #{violation.facet_value}"
    end

    def reason(%{facet_type: :minlength} = violation) do
      "length of #{inspect violation.node} is less than #{violation.facet_value}"
    end

    def reason(%{facet_type: :maxlength} = violation) do
      "length of #{inspect violation.node} is greater than #{violation.facet_value}"
    end

    def reason(%{facet_type: :pattern, facet_value: %{flags: nil}} = violation) do
      "#{inspect violation.node} does not match pattern #{inspect violation.facet_value.pattern}"
    end

    def reason(%{facet_type: :pattern} = violation) do
      "#{inspect violation.node} does not match pattern #{inspect violation.facet_value.pattern} with flags #{inspect violation.facet_value.flags}"
    end

    defdelegate reason_doc(violation), to: ShEx.Violation, as: :reason
  end
end

defmodule ShEx.Violation.NumericFacetConstraint do
  @moduledoc """
  `ShEx.Violation` produced on a nonconformant numeric facet constraint.
  """

  defstruct [:facet_type, :facet_value, :node]

  defimpl ShEx.Violation do
    def label(_), do: "Numeric Facet Constraint Violation"

    def reason(%{facet_type: :invalid_numeric} = violation) do
      "#{inspect violation.node} is not numeric"
    end

    def reason(%{facet_type: :mininclusive} = violation) do
      "#{inspect violation.node} is less than #{violation.facet_value}"
    end

    def reason(%{facet_type: :minexclusive} = violation) do
      "#{inspect violation.node} is less than or equal to #{violation.facet_value}"
    end

    def reason(%{facet_type: :maxinclusive} = violation) do
      "#{inspect violation.node} is greater than #{violation.facet_value}"
    end

    def reason(%{facet_type: :maxexclusive} = violation) do
      "#{inspect violation.node} is greater than or equal to #{violation.facet_value}"
    end

    def reason(%{facet_type: :totaldigits} = violation) do
      "number of digits of #{inspect violation.node} is greater than #{violation.facet_value}"
    end

    def reason(%{facet_type: :fractiondigits} = violation) do
      "number of fractional digits of #{inspect violation.node} is greater than #{violation.facet_value}"
    end

    defdelegate reason_doc(violation), to: ShEx.Violation, as: :reason
  end
end

defmodule ShEx.Violation.ValuesConstraint do
  @moduledoc """
  `ShEx.Violation` produced on a nonconformant values constraint.
  """

  defstruct [:constraint_type, :constraint_value, :node]

  defimpl ShEx.Violation do
    def label(_), do: "Values Constraint Violation"

    def reason(%{constraint_type: :object_value} = violation) do
      "#{inspect violation.node} is not #{inspect violation.constraint_value}"
    end

    def reason(%{constraint_type: :language, constraint_value: ""} = violation) do
      "#{inspect violation.node} is not language-tagged"
    end

    def reason(%{constraint_type: :language} = violation) do
      "language of #{inspect violation.node} is not #{inspect violation.constraint_value}"
    end

    def reason(%{constraint_type: type} = violation)
        when type in ~w[IriStem LiteralStem LanguageStem IriStemRange LiteralStemRange LanguageStemRange] do
      "#{type} of #{inspect violation.node} is not #{inspect violation.constraint_value}"
    end

    def reason(%{constraint_type: :exclusion} = violation) do
      "#{inspect violation.node} is an excluded value"
    end

    defdelegate reason_doc(violation), to: ShEx.Violation, as: :reason
  end
end

defmodule ShEx.Violation.MinCardinality do
  @moduledoc """
  `ShEx.Violation` produced on a nonconformant minimum cardinality constraint.
  """

  defstruct [:triple_expression, :triple_expression_violations, :cardinality]

  defimpl ShEx.Violation do
    import Inspect.Algebra

    def label(_), do: "Minimum Cardinality Violation"

    def reason(violation) do
      reason_doc(violation)
      |> ShEx.Violation.Shared.reason_from_doc()
    end

    def reason_doc(violation) do
      triple_expression_violation_reasons =
        triple_expression_violation_reasons(violation.triple_expression_violations)

      if skip_triple_expression?(violation.triple_expression, violation.cardinality,
           triple_expression_violation_reasons) do
        triple_expression_violation_reasons
      else
        main_reason(violation)
        |> line(triple_expression_violation_reasons)
      end
    end

    defp main_reason(violation) do
      "matched #{cardinality(violation.cardinality)} of at least #{
        ShEx.TripleExpression.min_cardinality(violation.triple_expression)
      } #{triple_expression_label(violation.triple_expression)}"
    end

    defp cardinality(0),   do: "none"
    defp cardinality(num), do: "just #{num}"

    defp triple_expression_label(%ShEx.TripleConstraint{} = triple_constraint) do
      "#{if triple_constraint.inverse, do: "inverse "}#{
        inspect triple_constraint.predicate} triples"
    end

    defp triple_expression_label(%ShEx.EachOf{}), do: "eachOf expressions"
    defp triple_expression_label(%ShEx.OneOf{}), do: "oneOf expressions"

    defp triple_expression_violation_reasons(nil), do: empty()
    defp triple_expression_violation_reasons([]),  do: empty()

    defp triple_expression_violation_reasons(triple_expression_violations) do
      triple_expression_violations
      |> Enum.map(&ShEx.Violation.reason_doc/1)
      |> Enum.map(fn reason ->
          "- "
          |> concat(nest(group(reason), 2))
          |> concat(collapse_lines(1))
         end)
      |> concat()
    end

    defp skip_triple_expression?(_, _, nil), do: false
    defp skip_triple_expression?(%type{}, 0, _) when type in [ShEx.OneOf, ShEx.EachOf], do: true
    defp skip_triple_expression?(_, _, _), do: false
  end
end

defmodule ShEx.Violation.MaxCardinality do
  @moduledoc """
  `ShEx.Violation` produced on a nonconformant maximum cardinality constraint.
  """

  defstruct [:triple_expression]

  defimpl ShEx.Violation do
    def label(_), do: "Maximum Cardinality Violation"

    def reason(violation) do
      "Max cardinality (#{
        ShEx.TripleExpression.max_cardinality(violation.triple_expression)}) of #{
        triple_expression_label(violation.triple_expression)} exceeded"
    end

    defp triple_expression_label(%ShEx.TripleConstraint{} = triple_constraint) do
      "#{if triple_constraint.inverse, do: "inverse "}#{
        inspect triple_constraint.predicate} triples"
    end

    defp triple_expression_label(%ShEx.EachOf{}), do: "eachOf expressions"
    defp triple_expression_label(%ShEx.OneOf{}), do: "oneOf expressions"

    defdelegate reason_doc(violation), to: ShEx.Violation, as: :reason
  end
end

defmodule ShEx.Violation.ClosedShape do
  @moduledoc """
  `ShEx.Violation` produced when unmatched triples where found on a closed shape.
  """

  defstruct [:shape, :unmatchables]

  defimpl ShEx.Violation do
    import Inspect.Algebra

    def label(_), do: "Closed Shape Violation"

    def reason(violation) do
      reason_doc(violation)
      |> ShEx.Violation.Shared.reason_from_doc()
    end

    def reason_doc(violation) do
      "remaining unmatchables found for closed shape:"
      |> line(unmatchables(violation.unmatchables))
    end

    defp unmatchables(triples) do
      triples
      |> Enum.map(&inspect/1)
      |> Enum.map(fn triple ->
        "- "
        |> concat(triple)
        |> concat(collapse_lines(1))
      end)
      |> concat()
    end
  end
end

defmodule ShEx.Violation.NegationMatch do
  @moduledoc """
  `ShEx.Violation` produced when a negated shape expression matched.
  """

  defstruct [:shape_not]

  defimpl ShEx.Violation do
    def label(_), do: "Negation Violation"

    def reason(violation) do
      # TODO: improve this
      "negation expression #{inspect violation.shape_not} matched"
    end

    defdelegate reason_doc(violation), to: ShEx.Violation, as: :reason
  end
end

# TODO: Remove this when this structural error is detected during schema creation.
defmodule ShEx.Violation.UnknownReference do
  @moduledoc """
  `ShEx.Violation` produced on unresolvable expression references.

  Note: This violation will soon be removed, as this will be detected during the creation of the schema.
  """

  defstruct [:expr_ref]

  defimpl ShEx.Violation do
    def label(_), do: "Unknown Reference"

    def reason(violation) do
      "couldn't resolve #{inspect violation.expr_ref}"
    end

    defdelegate reason_doc(violation), to: ShEx.Violation, as: :reason
  end
end
