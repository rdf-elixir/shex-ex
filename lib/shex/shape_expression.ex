defprotocol ShEx.ShapeExpression do
  @moduledoc """
  A shape expression is a logical combination of node constraints and shapes.
  """

  def satisfies(shape_expression, graph, schema, association, shape_map)
end
