defmodule ShEx.TripleConstraint do
  defstruct [
    :id,          #	tripleExprLabel?
    :value_expr,  # shapeExpr?
    :predicate,   #	IRIREF
    :inverse,     #	BOOL?
    :min,         # INTEGER?
    :max,         # INTEGER?
    :sem_acts,    # [SemAct+]?
    :annotations  # [Annotation+]?
  ]
end
