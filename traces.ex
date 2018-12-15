defmodule Traces do
  def example() do
    alphabet = ["a", "b", "c", "d"]
    commutation_set = [{"a", "d"}, {"d", "a"}, {"b", "c"}, {"c", "b"}]
    trace = "baadcb"

    {d, {s, f}} =
      {dependency_set(alphabet, commutation_set),
       foata_normal_form(alphabet, commutation_set, trace)}

    hasse = min_graph(trace, d)
    IO.puts("dependency set:")
    IO.inspect(d)
    IO.puts("stacks:")
    IO.inspect(s)
    IO.puts("foata:")
    IO.inspect(f)
    IO.puts("hasse:")
    Enum.each(hasse, &IO.puts(&1))
    trace = String.graphemes(trace)

    for i <- 1..length(trace) do
      {l, _} = List.pop_at(trace, i - 1)
      IO.puts("#{i}[label=#{l}]")
    end

    :ok
  end

  def example2() do
    alphabet = ["a", "b", "c", "d", "e"]

    commutation_set = [
      {"a", "d"},
      {"d", "a"},
      {"a", "c"},
      {"c", "a"},
      {"b", "d"},
      {"d", "b"},
      {"e", "b"},
      {"b", "e"}
    ]

    trace = "acebdac"

    {d, {s, f}} =
      {dependency_set(alphabet, commutation_set),
       foata_normal_form(alphabet, commutation_set, trace)}

    hasse = min_graph(trace, d)
    IO.puts("dependency set:")
    IO.inspect(d)
    IO.puts("stacks:")
    IO.inspect(s)
    IO.puts("foata:")
    IO.inspect(f)
    IO.puts("hasse:")
    Enum.each(hasse, &IO.puts(&1))
    trace = String.graphemes(trace)

    for i <- 1..length(trace) do
      {l, _} = List.pop_at(trace, i - 1)
      IO.puts("#{i}[label=#{l}]")
    end

    :ok
  end

  def example3() do
    alphabet = ["a", "b", "c", "d", "e", "f"]
    commutation_set = [{"a", "d"}, {"d", "a"}, {"b", "c"}, {"c", "a"}]
    trace = "abcadef"

    {d, {s, f}} =
      {dependency_set(alphabet, commutation_set),
       foata_normal_form(alphabet, commutation_set, trace)}

    hasse = min_graph(trace, d)
    IO.puts("dependency set:")
    IO.inspect(d)
    IO.puts("stacks:")
    IO.inspect(s)
    IO.puts("foata:")
    IO.inspect(f)
    IO.puts("hasse:")
    Enum.each(hasse, &IO.puts(&1))
    trace = String.graphemes(trace)

    for i <- 1..length(trace) do
      {l, _} = List.pop_at(trace, i - 1)
      IO.puts("#{i}[label=#{l}]")
    end

    :ok
  end

  # wykonujemy generacje zbioru (E x E) / I, za pomocą redukcji, na koncu splaszczamy zbior list w liste
  def dependency_set(alphabet, commutation_set) do
    set = for e1 <- alphabet, e2 <- alphabet, do: {e1, e2}

    Enum.filter(set, fn elem ->
      Enum.find(commutation_set, :none, fn elem2 -> elem === elem2 end) === :none
    end)
  end

  def foata_normal_form(alphabet, commutation_set, trace) do
    # utworzenie stosów
    stacks = Enum.reduce(alphabet, %{}, fn elem, map -> Map.put(map, elem, []) end)

    # odwrocenie sladu
    trace = trace |> String.reverse() |> String.graphemes()

    # przeprocesowanie sladu - uzupelnienie stosow markerami
    stacks =
      Enum.reduce(trace, stacks, fn elem, stacks ->
        # wrzucamy litere na stos
        stacks = Map.update!(stacks, elem, &[elem | &1])
        # wrzucamy markery dla liter ktore nie "komutuja" z ta wrzucona na stos
        Enum.reduce(alphabet, stacks, fn elem2, stacks ->
          # szukamy czy litera nalezy do jakiejkolwiek relacji z commutation_set
          case Enum.find(commutation_set, :none, fn {a, b} ->
                 (a === elem2 && b === elem) || (a === elem && b === elem2)
               end) do
            # jesli nie to wrzucamy marker
            :none when elem !== elem2 ->
              Map.update!(stacks, elem2, &["*" | &1])

            _ ->
              stacks
          end
        end)
      end)

    # drugi etap - generujemy foate ze stosow
    foata = gen_foata(stacks, []) |> Enum.reverse()

    {stacks, foata}
  end

  # functions pattern matching
  def gen_foata(map, acc) when map === %{} do
    acc
  end

  def gen_foata(map, acc) do
    # sprawdzamy czy jakis stos jest pusty, jesli tak to go usuwamy z mapy
    map =
      Enum.reduce(map, map, fn {k, v}, map ->
        case v do
          [] -> Map.delete(map, k)
          _ -> map
        end
      end)

    # szukamy slowa na wierzcholkach stosu
    {map, res} =
      Enum.reduce(map, {map, []}, fn {k, [h | t]}, {map, acc} ->
        case h do
          "*" ->
            {map, acc}

          _ ->
            {Map.update!(map, k, &(&1 = t)), [h | acc]}
        end
      end)

    # jesli slowo jest puste, to usuwamy jedna warstwe markerów
    case res do
      [] ->
        map = Enum.reduce(map, map, fn {k, [_ | t]}, map -> Map.update!(map, k, &(&1 = t)) end)
        gen_foata(map, acc)

      _ ->
        gen_foata(map, [res | acc])
    end
  end

  def min_graph(trace, dependency_graph) do
    trace = trace |> String.reverse() |> String.graphemes()

    {hasse, _, _} =
      Enum.reduce(trace, {[], [], length(trace)}, fn e, {hasse, min, n} ->
        {hasse, min} =
          Enum.reduce(min, {hasse, min}, fn {i, a}, {hasse, min} ->
            case Enum.find(dependency_graph, :none, fn elem ->
                   elem === {e, a} || elem === {a, e}
                 end) do
              :none ->
                {hasse, min}

              {_, a} ->
                min = Enum.filter(min, fn elem -> elem !== {i, a} end)
                {["#{n} -> #{i}" | hasse], min}
            end
          end)

        {hasse, [{n, e} | min], n - 1}
      end)

    hasse
  end
end
