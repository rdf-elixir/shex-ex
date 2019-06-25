defmodule ShEx.Violation.Shared do
  def message(violation) do
    "#{ShEx.Violation.label(violation)}: #{ShEx.Violation.reason(violation)}"
  end
end

defprotocol ShEx.Violation do
  def label(violation)

  def reason(violation)

  defdelegate message(violation), to: ShEx.Violation.Shared
end

defmodule ShEx.Violation.NodeKindConstraint do
  defstruct [:node_kind, :node]

  defimpl ShEx.Violation do
    def label(_), do: "Node Kind Constraint Violation"

    def reason(violation) do
      "#{inspect violation.node} is not a #{inspect violation.node_kind}"
    end
  end
end

defmodule ShEx.Violation.DatatypeConstraint do
  defstruct [:datatype, :node]

  defimpl ShEx.Violation do
    def label(_), do: "Datatype Constraint Violation"

    def reason(violation) do
      "#{inspect violation.node} has not datatype #{inspect violation.datatype}"
    end
  end
end

defmodule ShEx.Violation.StringFacetConstraint do
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
  end
end

defmodule ShEx.Violation.NumericFacetConstraint do
  defstruct [:facet_type, :facet_value, :node]

  defimpl ShEx.Violation do
    def label(_), do: "Numeric Facet Constraint Violation"

    def reason(%{facet_type: :numeric} = violation) do
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
  end
end

defmodule ShEx.Violation.ValuesConstraint do
  defstruct [:constraint_type, :constraint_value, :node]

  defimpl ShEx.Violation do
    def label(_), do: "Values Constraint Violation"

    def reason(%{onstraint_type: :object_value} = violation) do
      "#{inspect violation.node} is not #{inspect violation.object_value}"
    end

    def reason(%{onstraint_type: :language, object_value: :any} = violation) do
      "language #{inspect violation.node} is not language-tagged"
    end

    def reason(%{onstraint_type: :language} = violation) do
      "language #{inspect violation.node} is not #{inspect violation.object_value}"
    end

    def reason(%{onstraint_type: type} = violation)
        when type in ~w[IriStem LiteralStem LanguageStem IriStemRange LiteralStemRange LanguageStemRange] do
      "stem of #{inspect violation.node} is not #{inspect violation.object_value}"
    end

    def reason(%{onstraint_type: :exclusion} = violation) do
      "#{inspect violation.node} is an excluded value"
    end
  end
end

defmodule ShEx.Violation.MinCardinality do
  defstruct [:triple_expression, :cardinality]

  defimpl ShEx.Violation do
    def label(_), do: "Minimum Cardinality Violation"

    def reason(violation) do
      "matched #{inspect violation.triple_expression} triple expression #{violation.cardinality} times, but has min cardinality of #{violation.triple_expression.min}"
    end
  end
end

defmodule ShEx.Violation.MaxCardinality do
  defstruct [:triple_expression]

  defimpl ShEx.Violation do
    def label(_), do: "Maximum Cardinality Violation"

    def reason(violation) do
      "matched more than #{violation.triple_expression.max} triple expressions of #{inspect violation.triple_expression}"
    end
  end
end

defmodule ShEx.Violation.NegationMatch do
  defstruct [:shape_not]

  defimpl ShEx.Violation do
    def label(_), do: "Negation Violation"

    def reason(violation) do
      "negation expression #{inspect violation.shape_not} matched"
    end
  end
end

defmodule ShEx.Violation.UnknownReference do
  defstruct [:expr_ref]

  defimpl ShEx.Violation do
    def label(_), do: "Unknown Reference"

    def reason(violation) do
      "couldn't resolve #{inspect violation.expr_ref}"
    end
  end
end
