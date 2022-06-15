defmodule Core.MetroCdmx do
  import SweetXml
  @moduledoc """
  The following program consists of relating the lines of the city of Mexico
  with their respective stations, as well as obtaining a graph with the Graph function
  """

  defmodule Line do
    @moduledoc """
    struct of the line
    """
    defstruct [:name, :stations]
  end

  defmodule Station do
    @moduledoc """
    struct of the station
    """
    defstruct [:name, :coords]
  end

  defmodule Segment do
    @moduledoc """
    struct of the station
    """
    @derive Jason.Encoder
    defstruct line: "", init: "", last: "", len: 0

    @type t :: %__MODULE__{
            line: String.t(),
            init: String.t(),
            last: String.t(),
            len: integer()
          }
  end

  def metro_line() do
    doc = File.read!("assets/Metro_CDMX.kml")

    nombre_lineas =
      doc
      |> xpath(~x"//Document/Folder[1]/Placemark/name/text()"l)
      |> Enum.map(fn l -> List.to_string(l) end)

    nombre_lineas
    |> Enum.map(fn item ->
      estaciones =
        doc
        |> xpath(
          ~x"//Document/Folder[1]/Placemark[name=\"#{item}\"]/LineString/coordinates/text()"l
        )
        |> Enum.map(fn l -> List.to_string(l) end)
        |> List.first()
        |> String.split()
        |> Enum.map(fn coor ->
          %Station{
            name:
              doc
              |> xpath(
                ~x"//Document/Folder[2]/Placemark[contains(./Point/coordinates,\"#{coor}\")]/name/text()"l
              )
              |> List.to_string(),
            coords: coor
          }
        end)

      %Line{
        name: item,
        stations: estaciones
      }
    end)
    |> Enum.map(fn line ->
      %Line{
        name: line.name,
        stations: line.stations |> Enum.filter(fn station -> station.name != "" end)
      }
    end)
  end

  def metro_graph() do
    metro = metro_line()

    connections =
      Enum.map(metro, fn line ->
        case line.stations do
          [s1 | [s2 | ss]] ->
            Enum.reduce(ss, [{s1.name, s2.name}], fn s, l = [{_, s0} | _] ->
              [{s0, s.name} | [{s.name, s0} | l]]
            end)
            |> Enum.map(fn s -> Tuple.append(s, label: line.name) end)

          _ ->
            []
        end
      end)
      |> List.flatten()
    #IO.inspect(connections)
    Graph.new() |> Graph.add_edges(connections)

  end

  def find_way(origin, goal) do
    metro = metro_graph()
    path = Graph.get_shortest_path(metro, origin, goal)

    if not is_nil(path) do
      path
      |> Enum.zip(Enum.drop(path, 1))
      |> Enum.map(fn {s, d} -> metro |> Graph.edges(s, d) |> hd() end)
      |> Enum.group_by(fn e -> e.label end)
      |> Enum.map(fn {line, tracks} ->
        %Segment{
          line: line,
          init: tracks |> hd() |> Map.get(:v1),
          last: tracks |> List.last() |> Map.get(:v2),
          len: length(tracks)
        }
      end)
    else
      nil
    end
  end

end
