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
  alias RDF.{Turtle, Graph, Description, IRI}

  @base "https://raw.githubusercontent.com/shexSpec/shexTest/master/"
  @types ~w[schemas validation negativeSyntax negativeStructure]

  @dir Path.join(File.cwd!, "test/data/shexTest")
  def dir(), do: @dir
  def dir(type) when type in @types, do: @dir |> Path.join(type)

  def file(nil), do: nil
  def file(%IRI{} = iri), do: dir() |> Path.join(iri |> to_string() |> String.replace_prefix(@base, ""))
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

  def test_cases(manifest_or_test_suite, opts \\ [])

  def test_cases(%RDF.Graph{} = manifest_graph, opts) do
    suite_type = Keyword.get(opts, :suite_type)
    test_type = Keyword.get(opts, :test_type)
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

  def test_cases(suite_type, opts) do
    suite_type
    |> manifest_graph(opts)
    |> test_cases(Keyword.put(opts, :suite_type, suite_type))
  end


  def test_case_type(test_case), do: Description.first(test_case, RDF.type)
  def test_case_name(test_case), do: value(test_case, MF.name)
  def test_case_traits(test_case), do: test_case |> Description.get(SHT.trait) |> List.wrap()
  def test_case_title(test_case), do: test_case_name(test_case)

  def test_case_file(test_case, format) when is_atom(format),
    do: test_case_file(test_case, apply(SX, format, []))

  def test_case_file(test_case, property) do
    test_case
    |> value(property)
    |> String.replace_prefix(@base, "")
  end

  def test_case_action(manifest_graph, test_case) do
    action = Description.first(test_case, MF.action)
    Graph.description(manifest_graph, action)
  end

  defp value(description, property),
    do: Description.first(description, property) |> to_string
end
