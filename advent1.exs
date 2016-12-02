defmodule DayOne do
  defmodule State do
    defstruct position: {0,0}, heading: {0,1}, visited_locations: MapSet.new([{0,0}]), duplicate_location: :no_duplicate_location
    alias DayOne.Vector

    def been_there(%State{visited_locations: visited_locations, duplicate_location: :no_duplicate_location}, positions) do
      Enum.find(positions, :no_duplicate_location, &MapSet.member?(visited_locations, &1))
    end

    def change_heading(state = %State{heading: current_heading}, rotation) do
      %State{ state |
        heading: Vector.rotate(current_heading, rotation)
      }
    end

    def go_one_block(next_block, state = %State{visited_locations: visited_locations, duplicate_location: :no_duplicate_location}) do
      new_visited_locations = MapSet.put(visited_locations, next_block)

      %State{state |
        position: next_block,
        duplicate_location: been_there(state, [next_block]),
        visited_locations: new_visited_locations
      }
    end

    def go_one_block(_, state = %State{}), do: state

    def walk_path(state = %State{position: current_position, heading: heading}, move) do
      final_position = heading |> Vector.scale(move) |> Vector.sum(current_position)
      blocks_path = Vector.path(current_position , final_position)
      Enum.reduce(blocks_path, state, &go_one_block/2)
    end

    def step( state = %State{}, {rotation, move}) do
      state
      |> change_heading(rotation)
      |> walk_path(move)
    end
  end

  defmodule Vector do
    def rotate({x,y}, :right), do: {y, -x}
    def rotate({x,y}, :left), do: {-y, x}

    def scale({x, y}, scalar), do: {scalar*x, scalar*y}

    def sum({x,y}, {a,b}), do: {x+a, y+b}

    def manhattan_distance({x,y}), do: :erlang.abs(x) + :erlang.abs(y)

    def path({x, y}, {a, y}) do
      [_start | path_followed] = Stream.map(x..a, fn(p) -> {p,y} end) |> Enum.to_list
      path_followed
    end

    def path({x, y}, {x, b}) do
      [_start | path_followed] = Stream.map(y..b, fn(p) -> {x,p} end) |> Enum.to_list
      path_followed
    end
  end

  def walk(directions) do
    directions
    |> separate_steps
    |> comprehend
    |> follow_steps
    |> calculate_distance
  end

  def second_visit_distance(directions) do
    directions
    |> separate_steps
    |> comprehend
    |> find_second_visit
    |> calculate_distance
  end

  def separate_steps(path) do
    String.split(path, ", ")
  end

  def comprehend(steps) do
    Stream.map(steps, &comprehend_direction/1)
  end

  def comprehend_direction("R" <> distance), do: {:right, String.to_integer(distance)}
  def comprehend_direction("L" <> distance), do: {:left, String.to_integer(distance)}

  def find_second_visit(understood_steps) do
    Enum.reduce_while(understood_steps, %State{}, &step_until/2)
  end

  def follow_steps(understood_steps) do
    Enum.reduce(understood_steps, %State{}, &step/2)
  end

  def calculate_distance(%State{position: position}) do
    Vector.manhattan_distance(position)
  end

  def step_until(instruction, state = %State{duplicate_location: :no_duplicate_location}) do
    {:cont, step(instruction, state)}
  end

  def step_until(_, state = %State{}) do
    {:halt, state}
  end

  def step(instruction, state = %State{}) do
    state |> State.step(instruction)
  end
end

ExUnit.start

defmodule DayOneTest do
  use ExUnit.Case

  test "one step" do
    assert DayOne.walk("R2") == 2
  end

  test "short walk" do
    assert DayOne.walk("R2, L3") == 5
  end

  test "around the square" do
    assert DayOne.walk("R2, R2, R2") == 2
  end

  test "back to origin" do
    assert DayOne.walk("R2, R2, R2, R2") == 0
  end

  test "back to origin second visit" do
    assert DayOne.second_visit_distance("R2, R2, R2, R2, R3") == 0
  end

  test "crossed path" do
    assert DayOne.second_visit_distance("R8, R4, R4, R8") == 4
  end

  test "vectro path between adjacent x positions" do
    assert DayOne.Vector.path({0,0}, {1,0}) == [{1,0}]
  end

  test "vectro path between adjacent y positions" do
    assert DayOne.Vector.path({0,0}, {0,1}) == [{0,1}]
  end

  test "vectro path between nonadjacent x positions" do
    assert DayOne.Vector.path({0,0}, {2,0}) == [{1,0}, {2, 0}]
  end

  test "vectro path between nonadjacent x positions going negative" do
    assert DayOne.Vector.path({2,0}, {0,0}) == [{1,0}, {0, 0}]
  end

  test "vectro path between nonadjacent y positions" do
    assert DayOne.Vector.path({0,0}, {0,2}) == [{0,1}, {0, 2}]
  end

  test "non-matching visited paths" do
    assert DayOne.State.been_there(%DayOne.State{}, [{0,1}]) == :no_duplicate_location
  end

  test "matching visited paths" do
    assert DayOne.State.been_there(%DayOne.State{}, [{0,1}, {0,0}]) == {0,0}
  end
end
