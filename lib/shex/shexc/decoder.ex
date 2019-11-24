defmodule ShEx.ShExC.Decoder do
  @moduledoc false

  import ShEx.Utils

  alias RDF.{IRI, BlankNode, Literal}
  alias ShEx.NodeConstraint.{StringFacets, NumericFacets}

  import RDF.Serialization.ParseHelper, only: [error_description: 1]

  defmodule State do
    @moduledoc false

    defstruct base_iri: nil, namespaces: %{}, bnode_counter: 0

    def add_namespace(%State{namespaces: namespaces} = state, ns, iri) do
      %State{state | namespaces: Map.put(namespaces, ns, iri)}
    end

    def ns(%State{namespaces: namespaces}, prefix) do
      namespaces[prefix]
    end
  end

  def decode(content, opts \\ []) do
    with {:ok, tokens, _} <- tokenize(content),
         {:ok, ast} <- parse(tokens) do
      base = Keyword.get(opts, :base)
      build_schema(ast, base && RDF.iri(base))
    else
      {:error, {error_line, :shexc_lexer, error_descriptor}, _error_line_again} ->
        {:error,
         "ShExC scanner error on line #{error_line}: #{error_description(error_descriptor)}"}

      {:error, {error_line, :shexc_parser, error_descriptor}} ->
        {:error,
         "ShExC parser error on line #{error_line}: #{error_description(error_descriptor)}"}
    end
  end

  defp tokenize(content), do: content |> to_charlist |> :shexc_lexer.string()

  defp parse([]), do: {:ok, []}
  defp parse(tokens), do: tokens |> :shexc_parser.parse()

  defp build_schema({:shex_doc, directives_ast, start_acts_ast, statements_ast}, base) do
    state = %State{base_iri: base}
    all_statements = directives_ast ++ statements_ast

    with {:ok, statements, imports} <-
           extract_imports(all_statements, state),
         {:ok, statements, start} <-
           extract_start(statements, state),
         {:ok, statements, state} <-
           extract_prefixes(statements, state),
         {:ok, start_acts} <-
           if_present(start_acts_ast, &build_semantic_actions/2, state),
         {:ok, shapes, _state} <-
           Enum.reduce_while(statements, {:ok, [], state}, fn statement, {:ok, shapes, state} ->
             case build_shape(statement, state) do
               {:ok, nil, new_state} -> {:cont, {:ok, shapes, new_state}}
               {:ok, shape, new_state} -> {:cont, {:ok, [shape | shapes], new_state}}
               {:error, _} = error -> {:halt, error}
             end
           end) do
      ShEx.Schema.new(
        unless(Enum.empty?(shapes), do: Enum.reverse(shapes)),
        start,
        unless(Enum.empty?(imports), do: imports),
        start_acts
      )
    end
  end

  defp extract_prefixes(statements_ast, state) do
    {statements, _, state} =
      Enum.reduce(statements_ast, {[], :consume_directives, state}, &handle_base_and_prefixes/2)

    {:ok, statements, state}
  end

  defp handle_base_and_prefixes(
         {:prefix, {:prefix_ns, _, ns}, iri} = directive,
         {statements, value, state}
       ) do
    {
      if value == :consume_directives do
        statements
      else
        statements ++ [directive]
      end,
      value,
      if IRI.absolute?(iri) do
        State.add_namespace(state, ns, iri)
      else
        State.add_namespace(state, ns, iri |> IRI.absolute(state.base_iri) |> to_string())
      end
    }
  end

  defp handle_base_and_prefixes(
         {:base, iri} = directive,
         {statements, value, %State{base_iri: base_iri} = state}
       ) do
    {
      if value == :consume_directives do
        statements
      else
        statements ++ [directive]
      end,
      value,
      cond do
        IRI.absolute?(iri) ->
          %State{state | base_iri: RDF.iri(iri)}

        base_iri != nil ->
          %State{state | base_iri: IRI.absolute(iri, base_iri)}

        true ->
          raise "Could not resolve relative IRI '#{iri}', no base iri provided"
      end
    }
  end

  defp handle_base_and_prefixes(statement, {statements, value, state}) do
    {statements ++ [statement], value, state}
  end

  defp extract_imports(statements_ast, %State{} = state) do
    {statements, imports, _} =
      Enum.reduce(statements_ast, {[], [], state}, fn
        {:import, iri}, {statements, imports, state} ->
          {statements,
           [
             if IRI.absolute?(iri) do
               iri
             else
               iri |> IRI.absolute(state.base_iri) |> to_string()
             end
             | imports
           ], state}

        statement, acc ->
          handle_base_and_prefixes(statement, acc)
      end)

    {:ok, statements, Enum.reverse(imports)}
  end

  defp extract_start(statements_ast, %State{} = state) do
    with {statements, start, _} when statements != :error <-
           Enum.reduce_while(statements_ast, {[], nil, state}, fn
             {:start, inline_shape_expression}, {statements, nil, state} ->
               case build_shape_expression(inline_shape_expression, state) do
                 {:ok, shape} -> {:cont, {statements, shape, state}}
                 error -> {:halt, error}
               end

             {:start, _inline_shape_expression}, {_statements, _start, _state} ->
               {:halt, {:error, "multiple start shapes defined"}}

             statement, acc ->
               {:cont, handle_base_and_prefixes(statement, acc)}
           end) do
      {:ok, statements, start}
    end
  end

  defp build_shape({:shape_expr_decl, label_ast, :external}, state) do
    with {:ok, shape_expr_label} <- build_node(label_ast, state) do
      {:ok, %ShEx.ShapeExternal{id: shape_expr_label}, state}
    end
  end

  defp build_shape({:shape_expr_decl, label_ast, expression_ast}, state) do
    with {:ok, shape_expr} <- build_shape_expression(expression_ast, state),
         {:ok, shape_expr_label} <- build_node(label_ast, state) do
      {:ok, Map.put(shape_expr, :id, shape_expr_label), state}
    end
  end

  defp build_shape_expression(
         {:shape, extra_property_set_ast, triple_expression_ast, annotations_ast, sem_acts_ast},
         state
       ) do
    with {:ok, extra, closed} <-
           get_extra_properties(extra_property_set_ast, state),
         {:ok, triple_expression} <-
           if(triple_expression_ast,
             do: build_triple_expression(triple_expression_ast, state),
             else: {:ok, nil}
           ),
         {:ok, sem_acts} <-
           if_present(sem_acts_ast, &build_semantic_actions/2, state),
         {:ok, annotations} <-
           if(annotations_ast,
             do: map(annotations_ast, &build_annotation/2, state),
             else: {:ok, nil}
           ) do
      {:ok,
       %ShEx.Shape{
         expression: triple_expression,
         closed: closed,
         extra: unless(Enum.empty?(extra), do: extra),
         sem_acts: sem_acts,
         annotations: annotations
       }}
    end
  end

  defp build_shape_expression({:shape_or, shape_exprs_ast}, state) do
    with {:ok, shape_expressions} <-
           map(shape_exprs_ast, &build_shape_expression/2, state) do
      {:ok, %ShEx.ShapeOr{shape_exprs: shape_expressions}}
    end
  end

  defp build_shape_expression({:shape_and, shape_exprs_ast}, state) do
    with {:ok, shape_expressions} <-
           map(shape_exprs_ast, &build_shape_expression/2, state) do
      {:ok, %ShEx.ShapeAnd{shape_exprs: shape_expressions}}
    end
  end

  defp build_shape_expression({:shape_not, shape_expr_ast}, state) do
    with {:ok, shape_expression} <- build_shape_expression(shape_expr_ast, state) do
      {:ok, %ShEx.ShapeNot{shape_expr: shape_expression}}
    end
  end

  defp build_shape_expression(:empty_shape, _state), do: {:ok, %ShEx.Shape{}}

  defp build_shape_expression({:literal_node_constraint, _, _, _, _} = node_constraint_ast, state) do
    build_node_constraint(node_constraint_ast, state)
  end

  defp build_shape_expression({:non_literal_node_constraint, _, _} = node_constraint_ast, state) do
    build_node_constraint(node_constraint_ast, state)
  end

  defp build_shape_expression({:shape_ref, {:at_prefix_ln, line, {prefix, name}}}, state) do
    build_node({:prefix_ln, line, {prefix, name}}, state)
  end

  defp build_shape_expression({:shape_ref, {:at_prefix_ns, line, prefix}}, state) do
    build_node({:prefix_ns, line, prefix}, state)
  end

  defp build_shape_expression({:shape_ref, shape_ref_ast}, state) do
    build_node(shape_ref_ast, state)
  end

  defp get_extra_properties(nil, _state), do: {:ok, [], nil}

  defp get_extra_properties(extra_property_set_ast, state) do
    Enum.reduce_while(extra_property_set_ast, {:ok, [], nil}, fn
      {:extra, predicates}, {:ok, extra, closed} ->
        case map(predicates, &build_node/2, state) do
          {:ok, new_extra} ->
            {:cont, {:ok, extra ++ new_extra, closed}}

          {:error, error} ->
            {:halt, {:error, error}}
        end

      :closed, {:ok, extra, _} ->
        {:cont, {:ok, extra, true}}
    end)
  end

  defp build_triple_expression(
         {:bracketed_triple_expr, triple_expression_ast, cardinality_ast, annotations_ast,
          sem_acts_ast},
         state
       ) do
    with {:ok, triple_expression} <-
           build_triple_expression(triple_expression_ast, state),
         {:ok, min, max} <-
           get_cardinality(cardinality_ast, state),
         {:ok, sem_acts} <-
           if_present(sem_acts_ast, &build_semantic_actions/2, state),
         {:ok, annotations} <-
           if(annotations_ast,
             do: map(annotations_ast, &build_annotation/2, state),
             else: {:ok, nil}
           ) do
      {:ok,
       triple_expression
       |> Map.put(:min, min)
       |> Map.put(:max, max)
       |> Map.update(:sem_acts, sem_acts, fn
         nil -> sem_acts
         old -> old ++ sem_acts
       end)
       |> Map.put(:annotations, annotations)}
    end
  end

  defp build_triple_expression({:each_of, shape_exprs_ast}, state) do
    with {:ok, expressions} <-
           map(shape_exprs_ast, &build_triple_expression/2, state) do
      {:ok, %ShEx.EachOf{expressions: expressions}}
    end
  end

  defp build_triple_expression({:one_of, shape_exprs_ast}, state) do
    with {:ok, expressions} <-
           map(shape_exprs_ast, &build_triple_expression/2, state) do
      {:ok, %ShEx.OneOf{expressions: expressions}}
    end
  end

  defp build_triple_expression(
         {:triple_constraint, sense_flags, predicate_ast, inline_shape_expression_ast,
          cardinality_ast, annotations_ast, sem_acts_ast},
         state
       ) do
    with {:ok, predicate_iri} <-
           build_node(predicate_ast, state),
         {:ok, shape_expression} <-
           if(inline_shape_expression_ast == :empty_shape,
             do: {:ok, nil},
             else: build_shape_expression(inline_shape_expression_ast, state)
           ),
         {:ok, min, max} <-
           get_cardinality(cardinality_ast, state),
         {:ok, sem_acts} <-
           if_present(sem_acts_ast, &build_semantic_actions/2, state),
         {:ok, annotations} <-
           if(annotations_ast,
             do: map(annotations_ast, &build_annotation/2, state),
             else: {:ok, nil}
           ) do
      {:ok,
       %ShEx.TripleConstraint{
         value_expr: shape_expression,
         predicate: predicate_iri,
         inverse: if(sense_flags, do: sense_flags == :inverse),
         min: min,
         max: max,
         sem_acts: sem_acts,
         annotations: annotations
       }}
    end
  end

  defp build_triple_expression({:include, triple_expr_label_ast}, state) do
    build_node(triple_expr_label_ast, state)
  end

  defp build_triple_expression(
         {:named_triple_expression, triple_expr_label_ast, triple_expr_ast},
         state
       ) do
    with {:ok, triple_expression_label} <-
           build_node(triple_expr_label_ast, state),
         {:ok, triple_expression} <-
           build_triple_expression(triple_expr_ast, state) do
      {:ok, Map.put(triple_expression, :id, triple_expression_label)}
    end
  end

  defp build_node_constraint(
         {:literal_node_constraint, kind, datatype_ast, value_set_ast, xs_facets_ast},
         state
       ) do
    with {:ok, datatype} <-
           if_present(datatype_ast, &build_node/2, state),
         {:ok, xs_facets} <-
           xs_facets(xs_facets_ast, Map.put(state, :current_xs_facet_datatype, datatype)),
         string_facets <-
           StringFacets.new(xs_facets),
         {:ok, numeric_facets} <-
           xs_facets |> NumericFacets.new() |> validate_numeric_datatype(datatype),
         {:ok, values} <-
           if_present(value_set_ast, &value_set/2, state) do
      {:ok,
       %ShEx.NodeConstraint{
         node_kind: if(kind, do: to_string(kind)),
         datatype: datatype,
         string_facets: string_facets,
         numeric_facets: numeric_facets,
         values: ShEx.NodeConstraint.Values.new(values)
       }}
    end
  end

  defp build_node_constraint({:non_literal_node_constraint, kind, string_facets_ast}, state) do
    with {:ok, string_facets} <- xs_facets(string_facets_ast, state) do
      {:ok,
       %ShEx.NodeConstraint{
         node_kind: if(kind, do: to_string(kind)),
         string_facets: StringFacets.new(string_facets)
       }}
    end
  end

  defp build_annotation({:annotation, predicate_ast, object_ast}, state) do
    with {:ok, predicate} <- build_node(predicate_ast, state),
         {:ok, object} <- build_node(object_ast, state) do
      {:ok,
       %ShEx.Annotation{
         predicate: predicate,
         object: object
       }}
    end
  end

  defp build_semantic_actions({type, code_decls_ast}, state)
       when type in [:code_decls, :start_actions] do
    code_decls_ast
    |> map(&build_semantic_action/2, state)
  end

  defp build_semantic_action({:code_decl, name_ast, code_token}, state) do
    with {:ok, name} <- build_node(name_ast, state),
         {:ok, code} <- get_code(code_token) do
      {:ok,
       %ShEx.SemAct{
         name: name,
         code: unescape_code(code)
       }}
    end
  end

  defp get_code(nil), do: {:ok, nil}
  defp get_code({:code, _line, code}), do: {:ok, code}

  defp get_cardinality(nil, _), do: {:ok, nil, nil}
  defp get_cardinality(:"?", _), do: {:ok, 0, 1}
  defp get_cardinality(:+, _), do: {:ok, 1, -1}
  defp get_cardinality(:*, _), do: {:ok, 0, -1}
  defp get_cardinality({:repeat_range, _line, {min, max}}, _), do: {:ok, min, max}
  defp get_cardinality({:repeat_range, _line, exact}, _), do: {:ok, exact, exact}

  defp xs_facets(xs_facets_ast, state) do
    xs_facets_ast
    |> List.wrap()
    |> Enum.reduce_while({:ok, %{}}, fn xs_facet_ast, {:ok, xs_facets} ->
      case xs_facet(xs_facet_ast, state) do
        {:ok, xs_facet} ->
          conflicts = Map.take(xs_facets, Map.keys(xs_facet))

          if conflicts == %{} do
            {:cont, {:ok, Map.merge(xs_facets, xs_facet)}}
          else
            {:halt,
             {:error,
              "multiple occurrences of the same xsFacet: #{
                conflicts |> Map.keys() |> Enum.join(", ")
              }}"}}
          end

        {:error, _} = error ->
          {:halt, error}
      end
    end)
  end

  defp xs_facet({:string_facet, :regexp, {regexp, {:regexp_flags, _, regexp_flags}}}, state) do
    with {:ok, string_facet} <- xs_facet({:string_facet, :regexp, {regexp, nil}}, state) do
      {:ok, Map.put(string_facet, :flags, regexp_flags)}
    end
  end

  defp xs_facet({:string_facet, :regexp, {{:regexp, _line, regexp}, nil}}, _state) do
    with {:ok, regexp} <- valid_regexp_escaping(regexp) do
      {:ok, %{pattern: unescape_regex(regexp)}}
    end
  end

  defp xs_facet({:string_facet, length_type, {:integer, _line, integer}}, _state) do
    {:ok, %{length_type => integer.value}}
  end

  defp xs_facet({:numeric_length_facet, numeric_length_type, {:integer, _line, integer}}, _state) do
    {:ok, %{numeric_length_type => integer.value}}
  end

  defp xs_facet({:numeric_range_facet, numeric_range_type, numeric}, _state) do
    {:ok, %{numeric_range_type => numeric.value}}
  end

  defp validate_numeric_datatype(nil, _), do: {:ok, nil}
  defp validate_numeric_datatype(numeric_facets, nil), do: {:ok, numeric_facets}

  defp validate_numeric_datatype(numeric_facets, datatype) do
    if RDF.Numeric.type?(datatype) do
      {:ok, numeric_facets}
    else
      {:error,
       "numeric facet constraints applied to non-numeric datatype: #{to_string(datatype)}}"}
    end
  end

  defp value_set({:value_set, value_set_values_ast}, state) do
    with {:ok, values} <-
           value_set_values_ast
           |> map(&value_set_value/2, state)
           |> empty_to_nil() do
      {:ok, values}
    end
  end

  defp value_set_value({:iri_range, iri_ast, nil, nil}, state) do
    with {:ok, iri} <- build_node(iri_ast, state) do
      {:ok, iri}
    end
  end

  defp value_set_value({:iri_range, iri_ast, :stem, nil}, state) do
    with {:ok, iri} <- build_node(iri_ast, state) do
      {:ok, %{type: "IriStem", stem: iri}}
    end
  end

  defp value_set_value({:iri_range, iri_ast, :stem, exclusions_ast}, state) do
    with {:ok, iri} <- build_node(iri_ast, state),
         {:ok, exclusion_values} <- map(exclusions_ast, &exclusion_value/2, state) do
      {:ok, %{type: "IriStemRange", stem: iri, exclusions: exclusion_values}}
    end
  end

  defp value_set_value({:literal_range, literal_ast, nil, nil}, %{in_exclusion: true} = state) do
    with {:ok, literal} <- build_node(literal_ast, state) do
      {:ok, Literal.lexical(literal)}
    end
  end

  defp value_set_value({:literal_range, literal_ast, nil, nil}, state) do
    with {:ok, literal} <- build_node(literal_ast, state) do
      {:ok, literal}
    end
  end

  defp value_set_value({:literal_range, literal_ast, :stem, nil}, state) do
    with {:ok, literal} <- build_node(literal_ast, state) do
      {:ok, %{type: "LiteralStem", stem: Literal.lexical(literal)}}
    end
  end

  defp value_set_value({:literal_range, literal_ast, :stem, exclusions}, state) do
    with {:ok, literal} <- build_node(literal_ast, state),
         {:ok, exclusion_values} <- map(exclusions, &exclusion_value/2, state) do
      {:ok,
       %{type: "LiteralStemRange", stem: Literal.lexical(literal), exclusions: exclusion_values}}
    end
  end

  defp value_set_value({:language_range, langtag_token, nil, nil}, %{in_exclusion: true}) do
    with {:ok, language_tag} <- language_tag(langtag_token) do
      {:ok, language_tag}
    end
  end

  defp value_set_value({:language_range, langtag_token, nil, nil}, _state) do
    with {:ok, language_tag} <- language_tag(langtag_token) do
      {:ok, %{type: "Language", languageTag: language_tag}}
    end
  end

  defp value_set_value({:language_range, langtag_token, :stem, nil}, _state) do
    with {:ok, language_tag} <- language_tag(langtag_token) do
      {:ok, %{type: "LanguageStem", stem: language_tag}}
    end
  end

  defp value_set_value({:language_range, langtag_token, :stem, exclusions_ast}, state) do
    with {:ok, language_tag} <- language_tag(langtag_token),
         {:ok, exclusion_values} <- map(exclusions_ast, &exclusion_value/2, state) do
      {:ok, %{type: "LanguageStemRange", stem: language_tag, exclusions: exclusion_values}}
    end
  end

  defp value_set_value({:exclusions, [{exclusion_type, _, _} | _] = exclusions_ast}, state) do
    with {:ok, exclusions} <- map(exclusions_ast, &exclusion_value/2, state) do
      {:ok,
       %{
         type: exclusion_value_type(exclusion_type),
         stem: ShEx.NodeConstraint.Values.wildcard(),
         exclusions: exclusions
       }}
    end
  end

  defp exclusion_value({exclusion_type_ast, value_ast, stem_ast}, state) do
    value_set_value(
      {exclusion_value_ast_type(exclusion_type_ast), value_ast, stem_ast, nil},
      Map.put(state, :in_exclusion, true)
    )
  end

  defp exclusion_value_ast_type(:iri_exclusion), do: :iri_range
  defp exclusion_value_ast_type(:literal_exclusion), do: :literal_range
  defp exclusion_value_ast_type(:language_exclusion), do: :language_range

  defp exclusion_value_type(:iri_exclusion), do: "IriStemRange"
  defp exclusion_value_type(:literal_exclusion), do: "LiteralStemRange"
  defp exclusion_value_type(:language_exclusion), do: "LanguageStemRange"

  defp language_tag({:langtag, _line, lang_tag}), do: {:ok, lang_tag}
  defp language_tag({:@, _line}), do: {:ok, ""}

  defp build_node(%IRI{} = iri, _state), do: {:ok, iri}
  defp build_node(%BlankNode{} = bnode, _state), do: {:ok, bnode}
  defp build_node(%Literal{} = literal, _state), do: {:ok, literal}

  defp build_node(:rdf_type, _state), do: {:ok, RDF.type()}

  defp build_node({:prefix_ln, line, {prefix, name}}, state) do
    if ns = State.ns(state, prefix) do
      {:ok, RDF.iri(ns <> name)}
    else
      {:error, "unknown prefix #{inspect(prefix)} in line #{inspect(line)}"}
    end
  end

  defp build_node({:prefix_ns, line, prefix}, state) do
    if ns = State.ns(state, prefix) do
      {:ok, RDF.iri(ns)}
    else
      {:error, "unknown prefix #{inspect(prefix)} in line #{inspect(line)}"}
    end
  end

  defp build_node({{:string_literal_quote, _line, value}, {:datatype, datatype}}, state) do
    with {:ok, datatype} <- build_node(datatype, state) do
      {:ok, RDF.literal(value, datatype: datatype)}
    end
  end

  defp build_node({:relative_iri, relative_iri}, %State{base_iri: nil}) do
    {:error, "unresolvable relative IRI '#{relative_iri}', no base iri defined"}
  end

  defp build_node({:relative_iri, relative_iri}, %State{base_iri: base_iri}) do
    {:ok, IRI.absolute(relative_iri, base_iri)}
  end

  defp valid_regexp_escaping(regexp) do
    {:ok, regexp}
  end

  defp unescape_code(nil), do: nil
  defp unescape_code(string), do: Macro.unescape_string(string)

  defp unescape_regex(nil), do: nil

  defp unescape_regex(string),
    do: string |> unescape_8digit_unicode_seq() |> Macro.unescape_string(&regex_unescape_map(&1))

  defp regex_unescape_map(:unicode), do: true
  defp regex_unescape_map(?/), do: ?\/
  defp regex_unescape_map(_), do: false

  defp unescape_8digit_unicode_seq(string) do
    String.replace(
      string,
      ~r/(?<!\\)\\U([0-9]|[A-F]|[a-f]){2}(([0-9]|[A-F]|[a-f]){6})/,
      "\\u{\\2}"
    )
  end
end
