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

  def find_second_visit(understood_steps) do
    initial_position = {0, 0}
    initial_heading = {0, 1}
    visited_locations = MapSet.new([initial_position])

    {_, _, _, revisited_location} = Enum.reduce_while(understood_steps, {initial_position, initial_heading, visited_locations, :no_duplicate_location}, &step_until/2)
    {revisited_location, {}}
  end

  def follow_steps(understood_steps) do
    initial_position = {0, 0}
    initial_heading = {0, 1}
    Enum.reduce(understood_steps, {initial_position, initial_heading}, &step/2)
  end

  def calculate_distance({position, _direction}) do
    Vector.manhattan_distance(position)
  end

  def step_until(instruction, {current_position, current_heading, visited_locations, :no_duplicate_location}) do
    {new_position, new_direction} = step(instruction, {current_position, current_heading})

    location_match = Enum.find([new_position], :no_duplicate_location, &MapSet.member?(visited_locations, &1))

    new_visited_locations = MapSet.put(visited_locations, new_position)
    {:cont, {new_position, new_direction, new_visited_locations, location_match}}
  end

  def step_until(instruction, {current_position, current_heading, visited_locations, location}) do
    {:halt, {location, {}, [], location}}
  end

  def step({rotation, move}, {current_position, current_heading}) do
    changed_direction = Vector.rotate(current_heading, rotation)

    {changed_direction |> new_position(move, current_position), changed_direction}
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
end
