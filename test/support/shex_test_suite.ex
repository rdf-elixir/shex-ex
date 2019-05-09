defmodule ShEx.TestSuite do

  defmodule NS do
    use RDF.Vocabulary.Namespace

    defvocab MF,
      base_iri: "http://www.w3.org/2001/sw/DataAccess/tests/test-manifest#",
      terms: [], strict: false

    defvocab SX,
      base_iri: "https://shexspec.github.io/shexTest/ns#",
      terms: [], strict: false


    defvocab SHT,
      base_iri: "http://www.w3.org/ns/shacl/test-suite#",
      terms: [], strict: false

  end

  alias NS.{MF, SX, SHT}
  alias RDF.{Turtle, Graph, Description}

  @base "https://raw.githubusercontent.com/shexSpec/shexTest/master/"
  @types ~w[schemas validation negativeSyntax negativeStructure]

  @dir Path.join(File.cwd!, "test/data/shexTest")
  def dir(), do: @dir
  def dir(type) when type in @types, do: @dir |> Path.join(type)

  def file(filename), do: dir() |> Path.join(filename)
  def file(type, filename), do: type |> dir() |> Path.join(filename)

  def manifest_path(type), do: type |> file("manifest.ttl")

  def manifest_document_url(type), do: @base <> type <> "/manifest"

  def manifest_description(manifest_graph, type) do
    Graph.description(manifest_graph, manifest_document_url(type))
  end

  def manifest_graph(type, opts \\ []) do
    opts = Keyword.put_new(opts, :base, manifest_document_url(type))
    type
    |> manifest_path()
    |> Turtle.read_file!(opts)
  end

  def test_cases(suite_type, test_type \\ nil, opts \\ []) do
    manifest_graph = manifest_graph(suite_type, opts)

    manifest_entries =
      manifest_graph
      |> manifest_description(suite_type)
      |> Description.first(MF.entries)
      |> RDF.List.new(manifest_graph)
      |> RDF.List.values()
      |> MapSet.new

    manifest_graph
    |> Graph.descriptions
    |> Enum.filter(fn description ->
      description.subject in manifest_entries and
        (is_nil(test_type) or
         RDF.iri(test_type) in Description.get(description, RDF.type, []))
    end)
  end

  def test_case_name(test_case), do: value(test_case, MF.name)
  def test_case_trait(test_case), do: value(test_case, SHT.trait)
  def test_case_title(test_case), do: test_case_name(test_case)

  def test_case_file(test_case, format) when is_atom(format),
    do: test_case_file(test_case, apply(SX, format, []))

  def test_case_file(test_case, property) do
    test_case
    |> value(property)
    |> String.replace_prefix(@base, "")
  end

  defp value(description, property),
    do: Description.first(description, property) |> to_string
end
