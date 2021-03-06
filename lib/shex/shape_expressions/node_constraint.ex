defmodule ShEx.NodeConstraint do
  @moduledoc false

  defstruct [
    # shapeExprLabel?
    :id,
    # ("iri" | "bnode" | "nonliteral" | "literal")?
    :node_kind,
    # IRIREF?
    :datatype,
    #
    :string_facets,
    #
    :numeric_facets,
    # [valueSetValue+]?
    :values
  ]

  alias RDF.{IRI, BlankNode, Literal, XSD, NS}

  @node_kinds ~w[iri bnode nonliteral literal]

  def node_kinds(), do: @node_kinds

  def satisfies(node_constraint, association) do
    node = association.node

    with :ok <- node_satisfies_node_kind_constraint(node_constraint.node_kind, node),
         :ok <- node_satisfies_datatype_constraint(node_constraint.datatype, node),
         :ok <- ShEx.NodeConstraint.StringFacets.satisfies(node_constraint.string_facets, node),
         :ok <- ShEx.NodeConstraint.NumericFacets.satisfies(node_constraint.numeric_facets, node),
         :ok <- ShEx.NodeConstraint.Values.satisfies(node_constraint.values, node) do
      ShEx.ShapeMap.Association.conform(association)
    else
      violation ->
        ShEx.ShapeMap.Association.violation(association, violation)
    end
  end

  defp node_satisfies_node_kind_constraint(node_kind, node)
  defp node_satisfies_node_kind_constraint(nil, _), do: :ok
  defp node_satisfies_node_kind_constraint("iri", %IRI{}), do: :ok
  defp node_satisfies_node_kind_constraint("bnode", %BlankNode{}), do: :ok
  defp node_satisfies_node_kind_constraint("literal", %Literal{}), do: :ok
  defp node_satisfies_node_kind_constraint("nonliteral", %IRI{}), do: :ok
  defp node_satisfies_node_kind_constraint("nonliteral", %BlankNode{}), do: :ok

  defp node_satisfies_node_kind_constraint(node_kind, node),
    do: %ShEx.Violation.NodeKindConstraint{node_kind: node_kind, node: node}

  defp node_satisfies_datatype_constraint(datatype, node)
  defp node_satisfies_datatype_constraint(nil, _), do: :ok

  defp node_satisfies_datatype_constraint(datatype, %Literal{literal: %XSD.String{}} = node) do
    rdf_datatype = Literal.Datatype.get(datatype)

    if rdf_datatype && !is_nil(rdf_datatype.cast(node)) do
      :ok
    else
      %ShEx.Violation.DatatypeConstraint{datatype: datatype, node: node}
    end
  end

  defp node_satisfies_datatype_constraint(expected_datatype, %Literal{} = literal) do
    actual_datatype = Literal.datatype_id(literal)

    if expected_datatype == actual_datatype and Literal.valid?(literal) do
      :ok
    else
      %ShEx.Violation.DatatypeConstraint{
        datatype: expected_datatype,
        node: literal
      }
    end
  end

  defp node_satisfies_datatype_constraint(datatype, node) do
    %ShEx.Violation.DatatypeConstraint{datatype: datatype, node: node}
  end

  defimpl ShEx.ShapeExpression do
    def satisfies(node_constraint, _, _, association, _) do
      ShEx.NodeConstraint.satisfies(node_constraint, association)
    end
  end

  defimpl ShEx.Operator do
    def children(_), do: []

    def triple_expression_label_and_operands(_), do: {nil, []}
  end
end
