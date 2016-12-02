defmodule DayOne do
  defmodule Vector do
    def rotate({x,y}, :right), do: {y, -x}
    def rotate({x,y}, :left), do: {-y, x}

    def scale({x, y}, scalar), do: {scalar*x, scalar*y}

    def sum({x,y}, {a,b}), do: {x+a, y+b}

    def manhattan_distance({x,y}), do: :erlang.abs(x) + :erlang.abs(y)
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

  defmodule State do
    defstruct position: {0,0}, heading: {0,1}, visited_locations: MapSet.new([{0,0}]), duplicate_location: :no_duplicate_location
  end

  def find_second_visit(understood_steps) do
    Enum.reduce_while(understood_steps, %State{}, &step_until/2)
  end

  def follow_steps(understood_steps) do
    Enum.reduce(understood_steps, %State{}, &step/2)
  end

  def calculate_distance(%State{position: position}) do
    Vector.manhattan_distance(position)
  end

  def step_until(instruction, state = %State{duplicate_location: :no_duplicate_location, visited_locations: visited_locations}) do
    %State{position: new_position, heading: new_direction} = step(instruction, state)
    location_match = Enum.find([new_position], :no_duplicate_location, &MapSet.member?(visited_locations, &1))
    new_visited_locations = MapSet.put(visited_locations, new_position)

    new_state = %State{state |
      position: new_position,
      heading: new_direction,
      visited_locations: new_visited_locations,
      duplicate_location: location_match
    }

    {:cont, new_state}
  end

  def step_until(instruction, state = %State{duplicate_location: location}) do
    new_state = %State{state | position: location }
    {:halt, state}
  end

  def step({rotation, move}, state = %State{position: current_position, heading: current_heading}) do
    changed_direction = Vector.rotate(current_heading, rotation)

    %State{state |
      position: changed_direction |> new_position(move, current_position),
      heading: changed_direction
    }
  end

  def new_position(direction, move, position) do
    direction
    |> Vector.scale(move)
    |> Vector.sum(position)
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
end
